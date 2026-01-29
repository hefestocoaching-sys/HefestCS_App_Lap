// ignore_for_file: deprecated_member_use_from_same_package
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/exceptions/training_plan_blocked_exception.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/training_structure.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart';
import 'package:hcs_app_lap/domain/services/phase_3_volume_capacity_model_service.dart';
import 'package:hcs_app_lap/domain/services/phase_4_split_distribution_service.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_6_exercise_selection_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';
import 'package:hcs_app_lap/domain/services/phase_8_adaptation_service.dart';
import 'package:hcs_app_lap/domain/services/training_feedback_aggregator_service.dart';
import 'package:hcs_app_lap/domain/services/volume_individualization_service.dart';
import 'package:hcs_app_lap/domain/services/volume_by_muscle_derivation_service.dart';
import 'package:hcs_app_lap/domain/services/athlete_context_resolver.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';
import 'package:hcs_app_lap/domain/training/services/volume_budget_balancer.dart';
import 'package:hcs_app_lap/domain/training/services/volume_swap_service.dart';
import 'package:hcs_app_lap/domain/training/services/initial_volume_target_service.dart';
import 'package:hcs_app_lap/domain/training/models/supported_muscles.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/training_program_engine_v2_full.dart';
import 'package:hcs_app_lap/domain/training_v2/services/training_context_builder.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/domain/training_engine/phases/phase4_priority_cap_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FUNCIÓN CANÓNICA UI: Convierte mapas computados (legacy) a mapas UI divididos
/// ═══════════════════════════════════════════════════════════════════════════
/// Convierte músculos legacy (back, shoulders, calves, etc.) a músculos UI divididos
/// (dorsal_ancho, romboides, trapecio_medio, deltoides, gastrocnemio, soleo, etc.)
/// para consumo directo por Tab 3 (Prioridad/Intensidad).
///
/// Reglas:
/// - NO usar 'back/shoulders/calves' en UI
/// - Mantener suma total conservando totales del motor legacy
/// - División conservadora para músculos compuestos
Map<String, double> buildUiMuscleMap({
  required Map<String, double> computedSets,
  required ExerciseCatalog? catalog,
}) {
  double getV(String k) => computedSets[k] ?? 0.0;

  final out = <String, double>{};

  // Helper para agregar solo valores positivos con redondeo a 1 decimal
  void setIfPositive(String k, double v) {
    if (v > 0) out[k] = (v * 10).roundToDouble() / 10;
  }

  // Base directos (1:1)
  setIfPositive('pectoral', getV('chest'));
  setIfPositive('biceps', getV('biceps'));
  setIfPositive('triceps', getV('triceps'));
  setIfPositive('cuadriceps', getV('quads'));
  setIfPositive('isquiosurales', getV('hamstrings'));
  setIfPositive('gluteo', getV('glutes'));
  setIfPositive('abdomen', getV('abs'));

  // Lats -> dorsal ancho (primario real)
  setIfPositive('dorsal_ancho', getV('lats'));

  // Traps (legacy) -> trapecio_superior (para no duplicar con trapecio_medio)
  setIfPositive('trapecio_superior', getV('traps'));

  // Back (legacy) -> dividir en romboides y trapecio_medio (conservador 50/50)
  final back = getV('back');
  if (back > 0) {
    setIfPositive('romboides', back * 0.5);
    setIfPositive('trapecio_medio', back * 0.5);
  }

  // Shoulders (legacy) -> dividir en 3 deltoides (conservador)
  final sh = getV('shoulders');
  if (sh > 0) {
    setIfPositive('deltoide_anterior', sh * 0.33);
    setIfPositive('deltoide_lateral', sh * 0.34);
    setIfPositive('deltoide_posterior', sh * 0.33);
  }

  // Calves (legacy) -> gastrocnemio / soleo 50/50
  final calves = getV('calves');
  if (calves > 0) {
    setIfPositive('gastrocnemio', calves * 0.5);
    setIfPositive('soleo', calves * 0.5);
  }

  return out;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HELPERS SSOT: Expansión de grupos UI → músculos canónicos (14 keys)
/// ═══════════════════════════════════════════════════════════════════════════

/// Expande grupos legacy (back, shoulders, legs, arms) a músculos canónicos
List<String> _expandPriorityGroups(List<String> raw) {
  final out = <String>{};

  for (final item in raw) {
    final norm = normalizeMuscleKey(item);

    // Si el usuario puso grupos legacy: back/shoulders/legs/arms
    if (norm == 'back' || norm == 'back_group') {
      out.addAll(const ['lats', 'upper_back', 'traps']);
      continue;
    }
    if (norm == 'shoulders' || norm == 'shoulders_group') {
      out.addAll(const [
        'deltoide_anterior',
        'deltoide_lateral',
        'deltoide_posterior',
      ]);
      continue;
    }
    if (norm == 'legs_group') {
      out.addAll(const ['quads', 'hamstrings', 'glutes', 'calves']);
      continue;
    }
    if (norm == 'arms_group') {
      out.addAll(const ['biceps', 'triceps']);
      continue;
    }

    // Si ya viene canónico individual
    if (MuscleKeys.isCanonical(norm)) out.add(norm);
  }

  return out.toList();
}

/// Elimina keys legacy (back, shoulders) de mapas contables antes de persistir
Map<String, dynamic> _stripLegacyMuscleKeys(Map<String, dynamic> extra) {
  final out = Map<String, dynamic>.from(extra);

  void cleanMap(String key) {
    final raw = out[key];
    if (raw is Map) {
      final cleaned = <String, dynamic>{};
      raw.forEach((k, v) {
        final ks = k.toString();
        if (SupportedMuscles.isSupported(ks)) cleaned[ks] = v;
      });
      out[key] = cleaned;
    }
  }

  cleanMap('targetSetsByMuscle');
  cleanMap('mevByMuscle');
  cleanMap('mrvByMuscle');
  cleanMap('finalTargetSetsByMuscle');

  return out;
}

/// Orquestador final del Motor (Fases 1→8) - LEGACY
/// Esta clase ahora es legacy. Se mantiene para compatibilidad pero el entrypoint
/// principal es TrainingEngineV2 que incluye aprendizaje probabilístico.
class LegacyTrainingProgramEngine {
  final Phase1DataIngestionService _p1 = Phase1DataIngestionService();
  final Phase2ReadinessEvaluationService _p2 =
      Phase2ReadinessEvaluationService();
  final AthleteContextResolver _athleteResolver = AthleteContextResolver();
  final VolumeIndividualizationService _volumeIndiv =
      VolumeIndividualizationService();
  final Phase3VolumeCapacityModelService _p3 =
      Phase3VolumeCapacityModelService();
  final Phase4SplitDistributionService _p4 = Phase4SplitDistributionService();
  final Phase5PeriodizationService _p5 = Phase5PeriodizationService();
  final Phase6ExerciseSelectionService _p6 = Phase6ExerciseSelectionService();
  final Phase7PrescriptionService _p7 = Phase7PrescriptionService();
  final Phase8AdaptationService _p8 = Phase8AdaptationService();
  final Phase4PriorityCapService _priorityCapService =
      Phase4PriorityCapService();

  /// Decisiones acumuladas desde fases 1..8 de la última generación
  final List<DecisionTrace> lastDecisions = [];

  /// Punto de entrada único: genera un TrainingPlanConfig completo determinístico.
  TrainingPlanConfig generatePlan({
    required String planId,
    required String clientId,
    required String planName,
    required DateTime startDate,
    required TrainingProfile profile,
    Client? client,
    TrainingHistory? history,
    List<TrainingSessionLog> logs = const [],
    TrainingFeedback? latestFeedback,
    ExerciseCatalog? exerciseCatalog,
    List<Exercise>? exercises,
  }) {
    lastDecisions.clear();

    // Leer overrides manuales una única vez
    final manualOverridesRaw = profile.extra[TrainingExtraKeys.manualOverrides];

    // Fase 1
    final r1 = _p1.ingestAndValidate(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      manualOverridesRaw: manualOverridesRaw,
      referenceDate: startDate,
    );
    // CAMBIO A — FAIL FAST EN ENGINE: bloquear si faltan datos críticos
    if (!r1.isValid || r1.missingData.isNotEmpty) {
      lastDecisions.add(
        DecisionTrace.critical(
          phase: 'TrainingProgramEngine',
          category: 'blocked_missing_data',
          description: 'Generación bloqueada por datos faltantes',
          context: {'missingData': r1.missingData},
          action: 'Complete los datos críticos antes de continuar',
        ),
      );
      throw TrainingPlanBlockedException.missingCriticalData(
        missingFields: r1.missingData,
      );
    }
    lastDecisions.addAll(r1.decisions);
    final manualOverride =
        r1.manualOverride; // Será usado en fases 3,4,5,7 para aplicar overrides

    // Fase 2
    final r2 = _p2.evaluateReadinessWithContext(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      derivedContext: r1.derivedContext,
    );
    lastDecisions.addAll(r2.decisions);

    final readinessMode =
        (r2.readinessLevel == ReadinessLevel.low ||
            r2.readinessLevel == ReadinessLevel.moderate ||
            r2.readinessLevel == ReadinessLevel.critical)
        ? 'conservative'
        : 'normal';

    lastDecisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngine',
        category: 'readiness_mode',
        description: 'Modo readiness: $readinessMode',
        context: {
          'level': r2.readinessLevel.name,
          'factor': r2.volumeAdjustmentFactor,
        },
      ),
    );

    // PRE-FASE 3: Individualización de volumen (MEV/MRV sistémicos)
    // 1. Resolver contexto del atleta
    AthleteContext athleteContext;
    if (client != null) {
      try {
        athleteContext = _athleteResolver.resolve(client);
        lastDecisions.add(
          DecisionTrace.info(
            phase: 'VolumeIndividualization',
            category: 'athlete_context_resolved',
            description: 'Contexto del atleta resuelto desde Client',
            context: {
              'ageYears': athleteContext.ageYears,
              'sex': athleteContext.sex.name,
              'heightCm': athleteContext.heightCm,
              'weightKg': athleteContext.weightKg,
              'usesAnabolics': athleteContext.usesAnabolics,
            },
          ),
        );
      } catch (e) {
        lastDecisions.add(
          DecisionTrace.warning(
            phase: 'VolumeIndividualization',
            category: 'athlete_context_fallback',
            description:
                'No se pudo resolver contexto desde Client: $e. Usando fallback desde profile',
            context: {'error': e.toString()},
          ),
        );
        athleteContext = _volumeIndiv.buildAthleteContextFromProfile(profile);
      }
    } else {
      athleteContext = _volumeIndiv.buildAthleteContextFromProfile(profile);
      lastDecisions.add(
        DecisionTrace.info(
          phase: 'VolumeIndividualization',
          category: 'athlete_context_from_profile',
          description: 'Contexto del atleta construido desde TrainingProfile',
          context: {
            'ageYears': athleteContext.ageYears,
            'sex': athleteContext.sex.name,
            'heightCm': athleteContext.heightCm,
            'weightKg': athleteContext.weightKg,
          },
        ),
      );
    }

    // 2. Calcular bounds individualizados (MEV/MRV)
    final trainingLevel = profile.trainingLevel ?? TrainingLevel.intermediate;
    final volumeBounds = _volumeIndiv.computeBounds(
      level: trainingLevel,
      athlete: athleteContext,
      trainingExtra: profile.extra,
    );
    lastDecisions.add(
      DecisionTrace.info(
        phase: 'VolumeIndividualization',
        category: 'systemic_bounds',
        description:
            'Límites de volumen individualizados calculados: '
            'MEV base=${volumeBounds.mevBase} + ajuste=${volumeBounds.mevAdjustTotal.toStringAsFixed(1)} = ${volumeBounds.mevIndividual.toStringAsFixed(1)}, '
            'MRV base=${volumeBounds.mrvBase} + ajuste=${volumeBounds.mrvAdjustTotal.toStringAsFixed(1)} = ${volumeBounds.mrvIndividual.toStringAsFixed(1)}',
        context: {
          'mevBase': volumeBounds.mevBase,
          'mrvBase': volumeBounds.mrvBase,
          'mevAdjustTotal': volumeBounds.mevAdjustTotal,
          'mrvAdjustTotal': volumeBounds.mrvAdjustTotal,
          'mevIndividual': volumeBounds.mevIndividual,
          'mrvIndividual': volumeBounds.mrvIndividual,
          'contributionsMev': volumeBounds.contributionsMev,
          'contributionsMrv': volumeBounds.contributionsMrv,
        },
      ),
    );

    // 3. Calcular targetSets por músculo canónico
    final persistedMev =
        (profile.extra[TrainingExtraKeys.mevIndividual] as num?)?.toDouble();
    final persistedMrv =
        (profile.extra[TrainingExtraKeys.mrvIndividual] as num?)?.toDouble();
    final overrideMev = (manualOverride?.volumeOverrides?['systemic']?.mev)
        ?.toDouble();
    final overrideMrv = (manualOverride?.volumeOverrides?['systemic']?.mrv)
        ?.toDouble();
    final double mevEffective =
        persistedMev ?? overrideMev ?? volumeBounds.mevIndividual;
    final double mrvEffective =
        persistedMrv ?? overrideMrv ?? volumeBounds.mrvIndividual;

    // NUEVA LÓGICA: Derivar mevByMuscle/mrvByMuscle PRIMERO para usar en targets
    final canonicalMuscles = SupportedMuscles.keys; // 14 keys canónicas
    final volumeByMusclePreview = VolumeByMuscleDerivationService.derive(
      mevGlobal: mevEffective,
      mrvGlobal: mrvEffective,
      rawMuscleKeys: canonicalMuscles,
    );
    final mevByMuscleForTargets = _readDoubleMap(
      volumeByMusclePreview,
      'mevByMuscle',
    );
    final mrvByMuscleForTargets = _readDoubleMap(
      volumeByMusclePreview,
      'mrvByMuscle',
    );

    final persistedTargetsRaw =
        profile.extra[TrainingExtraKeys.targetSetsByMuscleUi];
    final normalizedPersistedTargets =
        persistedTargetsRaw is Map<String, dynamic>
        ? _normalizeMuscleKeys(persistedTargetsRaw)
        : <String, double>{};

    // Filtrar solo músculos soportados de los targets persistidos
    final filteredPersistedTargets = <String, double>{};
    for (final entry in normalizedPersistedTargets.entries) {
      if (SupportedMuscles.isSupported(entry.key)) {
        filteredPersistedTargets[entry.key] = entry.value;
      }
    }

    final hasPersistedTargets = filteredPersistedTargets.isNotEmpty;

    final Map<String, double> targetSetsByMuscle;

    if (hasPersistedTargets) {
      // Usar targets persistidos si existen (ya filtrados)
      targetSetsByMuscle = filteredPersistedTargets;
    } else {
      // NUEVA LÓGICA: Targets diferenciados por prioridad muscular
      targetSetsByMuscle = InitialVolumeTargetService.buildTargets(
        muscles: canonicalMuscles,
        mevByMuscle: mevByMuscleForTargets,
        mrvByMuscle: mrvByMuscleForTargets,
        primary: _expandPriorityGroups(
          _readStringList(profile.extra, 'priorityMusclesPrimary'),
        ),
        secondary: _expandPriorityGroups(
          _readStringList(profile.extra, 'priorityMusclesSecondary'),
        ),
        tertiary: _expandPriorityGroups(
          _readStringList(profile.extra, 'priorityMusclesTertiary'),
        ),
      );
    }

    // C2: Hard floor fisiológico (evita volumen 0 no intencional)
    targetSetsByMuscle.updateAll((muscle, sets) {
      const int minSetsFloor = 4; // semanal por músculo (conservador)
      return sets < minSetsFloor ? minSetsFloor.toDouble() : sets;
    });

    lastDecisions.add(
      DecisionTrace.info(
        phase: 'VolumeIndividualization',
        category: 'target_sets_per_muscle',
        description:
            'Volumen target calculado por músculo con prioridades diferenciadas',
        context: {
          'targetSetsByMuscle': targetSetsByMuscle,
          'hasPriorities': profile.extra.containsKey('priorityMusclesPrimary'),
        },
      ),
    );

    // 4. Guardar en profile.extra para UI, trazabilidad y fases posteriores
    // Filtrar targetSetsByMuscle para solo incluir músculos soportados
    final filteredTargets = <String, double>{};
    for (final entry in targetSetsByMuscle.entries) {
      final k = entry.key.toString();
      if (SupportedMuscles.isSupported(k)) {
        filteredTargets[k] = entry.value;
      }
    }

    final updatedExtra = Map<String, dynamic>.from(profile.extra)
      ..[TrainingExtraKeys.trainingExtraVersion] = 'volumeIndividualized_v1'
      // Bounds base
      ..['mevBase'] = volumeBounds.mevBase
      ..['mrvBase'] = volumeBounds.mrvBase
      // Ajustes totales
      ..['mevAdjustTotal'] = volumeBounds.mevAdjustTotal
      ..['mrvAdjustTotal'] = volumeBounds.mrvAdjustTotal
      // Valores individualizados finales
      ..['mevIndividual'] = mevEffective
      ..['mrvIndividual'] = mrvEffective
      // Targets por músculo (ahora diferenciados por prioridad, solo soportados)
      ..['targetSetsByMuscle'] = filteredTargets;

    // Agregar mevByMuscle/mrvByMuscle ya calculados
    updatedExtra.addAll(volumeByMusclePreview);

    // ═══════════════════════════════════════════════════════════════════════
    // PHASE 4 PRIORITY CAP: Calcular VMR efectivo por músculo según prioridad
    // Esto define los TECHOS fisiológicos sin modificar MEV ni targets
    // ═══════════════════════════════════════════════════════════════════════
    final primaryMuscles = _readStringList(
      profile.extra,
      'priorityMusclesPrimary',
    );
    final secondaryMuscles = _readStringList(
      profile.extra,
      'priorityMusclesSecondary',
    );
    final tertiaryMuscles = _readStringList(
      profile.extra,
      'priorityMusclesTertiary',
    );

    // Calcular VMR efectivo para cada rol por músculo
    final vmrByMuscleRole = _priorityCapService.compute(
      mevByMuscle: mevByMuscleForTargets,
      mrvByMuscle: mrvByMuscleForTargets,
      priorityMusclesPrimary: primaryMuscles,
      priorityMusclesSecondary: secondaryMuscles,
      priorityMusclesTertiary: tertiaryMuscles,
    );

    // Calcular finalTargetSetsByMuscle = min(target, vmrEffective según rol)
    final finalTargetSetsByMuscle = <String, double>{};
    for (final muscle in filteredTargets.keys) {
      final target = filteredTargets[muscle] ?? 0.0;
      final mev = mevByMuscleForTargets[muscle] ?? 0.0;

      // Determinar el rol del músculo
      final String role;
      if (primaryMuscles.contains(muscle)) {
        role = 'primary';
      } else if (secondaryMuscles.contains(muscle)) {
        role = 'secondary';
      } else if (tertiaryMuscles.contains(muscle)) {
        role = 'tertiary';
      } else {
        role = 'secondary'; // Default
      }

      // Obtener el cap efectivo para ese rol
      final vmrEffective =
          vmrByMuscleRole[muscle]?[role] ??
          mrvByMuscleForTargets[muscle] ??
          target;

      // finalTarget = min(target, vmrEffective), pero nunca menor a MEV
      final clamped = target.clamp(mev, vmrEffective);
      finalTargetSetsByMuscle[muscle] = (clamped * 10).roundToDouble() / 10;
    }

    // C2: Hard floor fisiológico (evita volumen 0 no intencional)
    finalTargetSetsByMuscle.updateAll((muscle, sets) {
      const int minSetsFloor = 4; // semanal por músculo (conservador)
      return sets < minSetsFloor ? minSetsFloor.toDouble() : sets;
    });

    lastDecisions.add(
      DecisionTrace.info(
        phase: 'Phase4PriorityCap',
        category: 'vmr_effective_computed',
        description:
            'VMR efectivo calculado por músculo según rol de prioridad',
        context: {
          'vmrByMuscleRole': vmrByMuscleRole,
          'finalTargetSetsByMuscle': finalTargetSetsByMuscle,
          'primaryCount': primaryMuscles.length,
          'secondaryCount': secondaryMuscles.length,
          'tertiaryCount': tertiaryMuscles.length,
        },
      ),
    );

    // Persistir en updatedExtra
    updatedExtra['vmrByMuscleRole'] = vmrByMuscleRole;
    updatedExtra['finalTargetSetsByMuscle'] = finalTargetSetsByMuscle;

    // ═══════════════════════════════════════════════════════════════════════
    // GENERAR MAPAS UI usando función canónica buildUiMuscleMap
    // ═══════════════════════════════════════════════════════════════════════
    final targetSetsByMuscleUi = buildUiMuscleMap(
      computedSets: filteredTargets,
      catalog: exerciseCatalog,
    );
    final finalTargetSetsByMuscleUi = buildUiMuscleMap(
      computedSets: finalTargetSetsByMuscle,
      catalog: exerciseCatalog,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // CRÍTICO: Persistir mapas UI en updatedExtra para consumo directo por Tab 3
    // Estos mapas DEBEN viajar en el snapshot para que Tab 3 nunca dependa de legacy
    // ═══════════════════════════════════════════════════════════════════════
    updatedExtra[TrainingExtraKeys.targetSetsByMuscleUi] = targetSetsByMuscleUi;
    updatedExtra[TrainingExtraKeys.finalTargetSetsByMuscleUi] =
        finalTargetSetsByMuscleUi;

    // ═══════════════════════════════════════════════════════════════════════
    // SANITIZACIÓN DEFENSIVA: Eliminar keys legacy antes de persistir
    // ═══════════════════════════════════════════════════════════════════════
    final sanitizedExtra = _stripLegacyMuscleKeys(updatedExtra);

    final profileWithBounds = profile.copyWith(extra: sanitizedExtra);

    // Fase 3
    final r3 = _p3.calculateVolumeCapacity(
      profile: profileWithBounds,
      history: history,
      readinessAdjustment: r2.volumeAdjustmentFactor,
      readinessByMuscle: r2.readinessByMuscle,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r3.decisions);

    // Fase 4: Reutilizar estructura si existe y está lockeada para la semana actual
    TrainingStructure? existingStructure;
    final structureJson = updatedExtra['trainingStructure'];
    if (structureJson != null && structureJson is Map<String, dynamic>) {
      try {
        final structure = TrainingStructure.fromMap(structureJson);
        if (structure.isLockedForWeekIndex(
          profileWithBounds.currentWeekIndex,
        )) {
          existingStructure = structure;
          lastDecisions.add(
            DecisionTrace.info(
              phase: 'TrainingProgramEngine',
              category: 'structure_reused',
              description:
                  'Reutilizando estructura lockeada para la semana actual',
              context: {
                'splitId': structure.splitId,
                'daysPerWeek': structure.daysPerWeek,
                'lockedFromWeek': structure.lockedFromWeek,
                'lockedUntilWeek': structure.lockedUntilWeek,
              },
              action:
                  'Estructura bloqueada - solo se adaptarán sets/RIR/variantes',
            ),
          );
        }
      } catch (_) {
        // Ignorar errores de parseo, generar nueva estructura
      }
    }

    final r4 = _p4.buildWeeklySplit(
      profile: profileWithBounds,
      volumeByMuscle: r3.volumeLimitsByMuscle,
      readinessAdjustment: r2.volumeAdjustmentFactor,
      readinessMode: readinessMode,
      derivedContext: r1.derivedContext,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r4.decisions);

    // Usar estructura existente si está disponible, sino usar la recién generada
    final finalStructure = existingStructure ?? r4.structure;

    // Fase 5
    final r5 = _p5.periodize(
      profile: profileWithBounds,
      baseSplit: r4.split,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r5.decisions);

    // Fase 6
    final catalog =
        exercises ??
        exerciseCatalog?.entries
            .map(
              (e) => Exercise(
                id: e.code,
                externalId: e.code,
                name: e.name,
                muscleKey: e.muscleGroup.name,
                equipment: e.equipment.isNotEmpty ? e.equipment.first : '',
                difficulty: '',
                gifUrl: '',
              ),
            )
            .toList() ??
        const <Exercise>[];
    lastDecisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngine',
        category: 'exercise_catalog_loaded',
        description: 'Catálogo de ejercicios cargado',
        context: {'count': catalog.length},
      ),
    );

    // Extraer baseExercisesByMuscle del ciclo activo
    Map<String, List<String>>? baseExercisesByMuscle;
    if (client != null && client.activeCycleId != null) {
      try {
        TrainingCycle? cycle;
        for (final c in client.trainingCycles) {
          if (c.cycleId == client.activeCycleId) {
            cycle = c;
            break;
          }
        }
        if (cycle != null) {
          baseExercisesByMuscle = cycle.baseExercisesByMuscle;
          lastDecisions.add(
            DecisionTrace.info(
              phase: 'TrainingProgramEngine',
              category: 'cycle_base_exercises_loaded',
              description:
                  'Restricciones de ejercicios cargadas desde ciclo activo',
              context: {
                'cycleId': cycle.cycleId,
                'musclesCount': baseExercisesByMuscle.length,
                'baseExercisesCount': baseExercisesByMuscle.values.fold<int>(
                  0,
                  (sum, list) => sum + list.length,
                ),
              },
            ),
          );
        }
      } catch (_) {
        // Si hay error al buscar el ciclo, continuar sin restricciones
      }
    }

    final r6 = _p6.selectExercises(
      profile: profileWithBounds,
      baseSplit: r4.split,
      catalog: catalog,
      weeks: r5.weeks.length,
      baseExercisesByMuscle: baseExercisesByMuscle,
    );
    lastDecisions.addAll(r6.decisions);

    // Fase 7
    final r7 = _p7.buildPrescriptions(
      baseSplit: r4.split,
      periodization: r5,
      selections: r6.selections,
      manualOverride: manualOverride,
      volumeLimitsByMuscle: r3.volumeLimitsByMuscle,
      trainingLevel: profileWithBounds.trainingLevel,
      derivedContext: r1.derivedContext,
      profile: profileWithBounds,
    );
    lastDecisions.addAll(r7.decisions);

    final finalCheck = _applyFinalGuardrails(
      weekDayPrescriptions: r7.weekDayPrescriptions,
      volumeLimitsByMuscle: r3.volumeLimitsByMuscle,
      periodization: r5,
    );
    lastDecisions.addAll(finalCheck.decisions);

    // Validación final dura: cada día debe tener >= mínimo de ejercicios
    // Regla relajada: mínimo 3 ejercicios por día para todos los splits.
    // Esto evita bloqueos excesivos cuando el catálogo es limitado.
    final int minExercisesPerDay = (r4.split.daysPerWeek >= 4) ? 5 : 3;

    for (final pw in r5.weeks) {
      final weekIndex = pw.weekIndex;
      for (var d = 1; d <= r4.split.daysPerWeek; d++) {
        final count =
            finalCheck.weekDayPrescriptions[weekIndex]?[d]?.length ?? 0;
        if (count < minExercisesPerDay) {
          lastDecisions.add(
            DecisionTrace.critical(
              phase: 'TrainingProgramEngine',
              category: 'insufficient_exercises_after_prescription',
              description:
                  'Día con menos de $minExercisesPerDay ejercicios tras prescripción',
              context: {
                'week': weekIndex,
                'day': d,
                'count': count,
                'minimum': minExercisesPerDay,
              },
              action: 'Verificar catálogo y distribución; bloquear plan',
            ),
          );
          throw TrainingPlanBlockedException.insufficientExercisesPerDay(
            week: weekIndex,
            day: d,
            count: count,
            minimum: minExercisesPerDay,
          );
        }
      }
    }

    // Calcular señales semanales desde TrainingSessionLogV2
    WeeklyTrainingFeedbackSummary? weeklyFeedback;
    if (logs.isNotEmpty) {
      // Extraer logs V2 del client.extra o client.training.extra
      final logsV2 = logs.whereType<TrainingSessionLogV2>().toList();

      if (logsV2.isNotEmpty) {
        final aggregator = TrainingFeedbackAggregatorService();
        final totalPlannedSets = r7.weekDayPrescriptions.values
            .expand((dayMap) => dayMap.values)
            .expand((list) => list)
            .fold<int>(0, (sum, p) => sum + p.sets);

        final summary = aggregator.summarizeWeek(
          clientId: clientId,
          referenceDate: startDate, // Fecha de inicio del plan
          logs: logsV2,
          plannedSetsThisWeek: totalPlannedSets,
        );
        weeklyFeedback = summary;

        lastDecisions.add(
          DecisionTrace.info(
            phase: 'Phase8Preparation',
            category: 'weekly_feedback_computed',
            description:
                'Señales semanales calculadas desde ${logsV2.length} logs',
            context: {
              'signal': summary.signal,
              'adherenceRatio': summary.adherenceRatio,
              'progressionAllowed': summary.progressionAllowed,
              'deloadRecommended': summary.deloadRecommended,
            },
          ),
        );
      }
    }

    // Fase 8 (Adaptación para siguiente microciclo)
    final r8 = _p8.adapt(
      weeklyFeedbackSummary: weeklyFeedback,
      latestFeedback: latestFeedback,
      history: history,
      logs: logs,
      weekDayPrescriptions: finalCheck.weekDayPrescriptions,
      volumeLimitsByMuscle: r3.volumeLimitsByMuscle,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r8.decisions);

    // Construir semanas y sesiones finales desde prescriptions adaptadas
    final weeks = _buildWeeks(
      baseSplit: r4.split,
      periodWeeks: r5.weeks,
      adapted: r8.adaptedWeekDayPrescriptions,
    );

    // C2: Validación final obligatoria - el motor DEBE generar un plan completo
    assert(weeks.isNotEmpty, 'C2: El motor no debe devolver un plan vacío');
    for (final week in weeks) {
      assert(
        week.sessions.isNotEmpty,
        'C2: Cada semana debe tener al menos una sesión',
      );
      for (final session in week.sessions) {
        assert(
          session.prescriptions.isNotEmpty,
          'C2: Cada sesión debe tener al menos una prescripción',
        );
      }
    }

    final plan = TrainingPlanConfig(
      id: planId,
      name: planName,
      clientId: clientId,
      startDate: startDate,
      phase: r5.weeks.first.phase,
      splitId: r4.split.splitId,
      microcycleLengthInWeeks: r5.weeks.length,
      weeks: weeks,
      trainingProfileSnapshot: profileWithBounds.copyWith(
        extra: {
          ...updatedExtra,
          // ═══════════════════════════════════════════════════════════════
          // CRÍTICO: Garantizar que mapas UI estén presentes en snapshot
          // ═══════════════════════════════════════════════════════════════
          TrainingExtraKeys.targetSetsByMuscleUi: targetSetsByMuscleUi,
          TrainingExtraKeys.finalTargetSetsByMuscleUi:
              finalTargetSetsByMuscleUi,
          TrainingExtraKeys.trainingExtraVersion: '1.0.0-pr10',
          TrainingExtraKeys.progressionBlocked: finalCheck.progressionBlocked,
          TrainingExtraKeys.manualOverrideActive: manualOverride != null,
          TrainingExtraKeys.trainingStructure: finalStructure.toMap(),
          // Aprendizaje MRV empírico por músculo (conservador)
          TrainingExtraKeys
              .muscleVolumeProfiles: _p8.computeObservedCapsForNextCycle(
            summary: weeklyFeedback,
            limitsByMuscle: r3.volumeLimitsByMuscle,
            existingCaps:
                (updatedExtra[TrainingExtraKeys.muscleVolumeProfiles] is Map)
                ? (updatedExtra[TrainingExtraKeys.muscleVolumeProfiles] as Map)
                      .cast<String, dynamic>()
                : <String, dynamic>{},
          ),
        },
      ),
    );

    final migratedExtras = !profileWithBounds.extra.containsKey(
      TrainingExtraKeys.trainingExtraVersion,
    );
    if (migratedExtras) {
      lastDecisions.add(
        DecisionTrace.info(
          phase: 'TrainingProgramEngine',
          category: 'extra_migrated',
          description: 'Extras versionados a 1.0.0-pr10',
          context: {
            'progressionBlocked': finalCheck.progressionBlocked,
            'manualOverrideActive': manualOverride != null,
          },
        ),
      );
    }

    lastDecisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngine',
        category: 'summary',
        description: 'Plan generado 1→8',
        context: {
          'planId': planId,
          'clientId': clientId,
          'weeks': weeks.length,
          'splitId': r4.split.splitId,
        },
      ),
    );

    // === CORRECCIÓN PROFESIONAL DE VOLUMEN ===
    // Aplicar balanceador automático para garantizar que ningún músculo supere MRV
    var finalPlan = plan;
    final mrvByMuscle = _readDoubleMap(updatedExtra, 'mrvByMuscle');
    final mevByMuscle = _readDoubleMap(updatedExtra, 'mevByMuscle');

    if (mrvByMuscle.isNotEmpty) {
      try {
        final balancerResult = VolumeBudgetBalancer.balance(
          plan: finalPlan,
          mrvByMuscle: mrvByMuscle,
          mevByMuscle: mevByMuscle,
          exerciseKey: (dynamic ex) => (ex as ExercisePrescription).exerciseCode
              .toLowerCase()
              .replaceAll(' ', '_'),
          getSets: (dynamic ex) => (ex as ExercisePrescription).sets.toDouble(),
          setSets: (dynamic ex, double newSets) =>
              (ex as ExercisePrescription).copyWith(sets: newSets.round()),
          allExercises: (dynamic p) => (p as TrainingPlanConfig).weeks
              .expand((week) => week.sessions)
              .expand((session) => session.prescriptions),
        );

        finalPlan = balancerResult.plan;

        // Persistir sets efectivos para debug/observabilidad
        updatedExtra['effectiveSetsByMuscle'] = balancerResult.effectiveSets;

        if (balancerResult.iterations > 0) {
          lastDecisions.add(
            DecisionTrace.info(
              phase: 'VolumeBudgetBalancer',
              category: 'volume_corrected',
              description:
                  'Plan ajustado para respetar MRV por músculo (${balancerResult.iterations} iteraciones)',
              context: {
                'effectiveSetsByMuscle': balancerResult.effectiveSets,
                'iterations': balancerResult.iterations,
                'blocked': balancerResult.blocked,
              },
            ),
          );
        }

        // === ESTRATEGIA B2: SWAPS DE VOLUMEN ===
        // Redistribuir sets desde músculos NO prioritarios hacia prioritarios
        // manteniendo el volumen total y respetando MRV
        final swapResult = VolumeSwapService.apply(
          plan: finalPlan,
          effectiveSets: Map<String, double>.from(balancerResult.effectiveSets),
          mevByMuscle: mevByMuscle,
          mrvByMuscle: mrvByMuscle,
          primaryMuscles: _readStringList(
            updatedExtra,
            'priorityMusclesPrimary',
          ).toSet(),
          secondaryMuscles: _readStringList(
            updatedExtra,
            'priorityMusclesSecondary',
          ).toSet(),
          tertiaryMuscles: _readStringList(
            updatedExtra,
            'priorityMusclesTertiary',
          ).toSet(),
          exerciseKey: (dynamic ex) => (ex as ExercisePrescription).exerciseCode
              .toLowerCase()
              .replaceAll(' ', '_'),
          getSets: (dynamic ex) => (ex as ExercisePrescription).sets.toDouble(),
          setSets: (dynamic ex, double newSets) =>
              (ex as ExercisePrescription).copyWith(sets: newSets.round()),
          allExercises: (dynamic p) => (p as TrainingPlanConfig).weeks
              .expand((week) => week.sessions)
              .expand((session) => session.prescriptions),
        );

        finalPlan = swapResult.plan;

        // Actualizar sets efectivos después de swaps
        updatedExtra['effectiveSetsByMuscle'] = swapResult.effectiveSets;

        if (swapResult.swapsExecuted > 0) {
          lastDecisions.add(
            DecisionTrace.info(
              phase: 'VolumeSwapService',
              category: 'volume_redistributed',
              description:
                  'Sets redistribuidos desde músculos no prioritarios a prioritarios (${swapResult.swapsExecuted} swaps)',
              context: {
                'effectiveSetsByMuscle': swapResult.effectiveSets,
                'swapsExecuted': swapResult.swapsExecuted,
              },
            ),
          );
        }

        // Actualizar snapshot con los extras enriquecidos
        finalPlan = finalPlan.copyWith(
          trainingProfileSnapshot: finalPlan.trainingProfileSnapshot?.copyWith(
            extra: {
              ...finalPlan.trainingProfileSnapshot?.extra ?? {},
              ...updatedExtra,
            },
          ),
        );
      } catch (e) {
        lastDecisions.add(
          DecisionTrace.warning(
            phase: 'VolumeBudgetBalancer',
            category: 'balancer_error',
            description: 'Error al aplicar balanceador: $e',
            context: {},
          ),
        );
      }
    }

    return finalPlan;
  }

  /// Helper para leer un mapa de doubles desde extra
  Map<String, double> _readDoubleMap(Map<String, dynamic> extra, String key) {
    final raw = extra[key];
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }

  List<TrainingWeek> _buildWeeks({
    required SplitTemplate baseSplit,
    required List<PeriodizedWeek> periodWeeks,
    required Map<int, Map<int, List<ExercisePrescription>>> adapted,
  }) {
    final weeks = <TrainingWeek>[];
    for (final pw in periodWeeks) {
      final weekIndex = pw.weekIndex;
      final sessions = <TrainingSession>[];
      for (var d = 1; d <= baseSplit.daysPerWeek; d++) {
        final dayPres =
            adapted[weekIndex]?[d] ?? const <ExercisePrescription>[];
        final session = TrainingSession(
          id: 'W$weekIndex-D$d',
          dayNumber: d,
          sessionName: 'W$weekIndex-D$d',
          prescriptions: dayPres,
        );
        sessions.add(session);
      }
      weeks.add(
        TrainingWeek(
          id: 'W$weekIndex',
          weekNumber: weekIndex,
          phase: pw.phase,
          sessions: sessions,
        ),
      );
    }
    return weeks;
  }

  _FinalValidationResult _applyFinalGuardrails({
    required Map<int, Map<int, List<ExercisePrescription>>>
    weekDayPrescriptions,
    required Phase5PeriodizationResult periodization,
    Map<String, VolumeLimits>? volumeLimitsByMuscle,
  }) {
    final adjusted = <int, Map<int, List<ExercisePrescription>>>{};
    final decisions = <DecisionTrace>[];
    var progressionBlocked = false;

    final fatigueByWeek = {
      for (final w in periodization.weeks) w.weekIndex: w.fatigueExpectation,
    };

    for (final weekEntry in weekDayPrescriptions.entries) {
      final weekIndex = weekEntry.key;
      final fatigueExpectation = fatigueByWeek[weekIndex] ?? 'normal';
      final weekMap = <int, List<ExercisePrescription>>{};

      // Calcular sets totales por músculo en la semana
      final weeklySets = <String, int>{};
      weekEntry.value.forEach((_, dayPres) {
        for (final p in dayPres) {
          weeklySets[p.muscleGroup.name] =
              (weeklySets[p.muscleGroup.name] ?? 0) + p.sets;
        }
      });

      // Preconteo de técnicas exigentes (allowFailure) como proxy de esfuerzo
      final allowFailurePres = <ExercisePrescription>[];
      weekEntry.value.forEach((_, dayPres) {
        for (final p in dayPres) {
          if (p.allowFailureOnLastSet) {
            allowFailurePres.add(p);
          }
        }
      });

      for (final dayEntry in weekEntry.value.entries) {
        final dayIndex = dayEntry.key;
        final newDay = <ExercisePrescription>[];

        for (final p in dayEntry.value) {
          var np = p;
          final muscle = p.muscleGroup.name;
          final limits = volumeLimitsByMuscle?[muscle];

          // Guardrail 1: Volumen vs MRV y RIR muy bajo
          final totalSetsMuscle = weeklySets[muscle] ?? 0;
          if (limits != null && totalSetsMuscle > limits.mrv) {
            final scale = limits.mrv / totalSetsMuscle;
            final scaledSets = (p.sets * scale).round().clamp(1, limits.mrv);
            if (scaledSets != p.sets) {
              np = np.copyWith(sets: scaledSets);
              progressionBlocked = true;
              decisions.add(
                DecisionTrace.warning(
                  phase: 'TrainingProgramEngine',
                  category: 'engine_final_guardrail_applied',
                  description: 'Clamp de sets por MRV tras generación',
                  context: {
                    'week': weekIndex,
                    'day': dayIndex,
                    'muscle': muscle,
                    'setsBefore': p.sets,
                    'setsAfter': scaledSets,
                    'mrv': limits.mrv,
                  },
                ),
              );
            }
          }

          // Guardrail 2: RIR mínimo si volumen está alto
          final rirTarget = np.rirTarget;
          if (limits != null &&
              (weeklySets[muscle] ?? 0) > (limits.mrv * 0.9) &&
              rirTarget.min < 1) {
            // Subir conservadoramente a RIR 1-2 si está muy bajo
            np = np.copyWithRirTarget(const RirTarget.range(1, 2));
            progressionBlocked = true;
            decisions.add(
              DecisionTrace.warning(
                phase: 'TrainingProgramEngine',
                category: 'engine_final_guardrail_applied',
                description:
                    'RIR ajustado a 1-2 por volumen alto cercano a MRV',
                context: {
                  'week': weekIndex,
                  'day': dayIndex,
                  'muscle': muscle,
                  'mrv': limits.mrv,
                  'weeklySets': weeklySets[muscle],
                },
              ),
            );
          }

          // Guardrail 3: Intensificación vs fatiga alta
          if (fatigueExpectation == 'high' && np.allowFailureOnLastSet) {
            // Si fatiga es alta y hay fallo, subir RIR conservadoramente (1 punto)
            final currentRir = np.rirTarget;
            final increasedRir = _increaseRirConservatively(currentRir);
            np = np
                .copyWithRirTarget(increasedRir)
                .copyWith(allowFailureOnLastSet: false);
            progressionBlocked = true;
            decisions.add(
              DecisionTrace.warning(
                phase: 'TrainingProgramEngine',
                category: 'engine_final_guardrail_applied',
                description:
                    'Intensificación desactivada por fatiga alta, RIR ajustado',
                context: {
                  'week': weekIndex,
                  'day': dayIndex,
                  'muscle': muscle,
                  'fatigueExpectation': fatigueExpectation,
                  'previousRir': currentRir.label,
                  'newRir': increasedRir.label,
                },
              ),
            );
          }

          newDay.add(np);
        }

        weekMap[dayIndex] = newDay;
      }

      // Guardrail 4: Presupuesto de esfuerzo simple (máx 1 técnica por semana)
      var remainingEffort = 1;
      for (final day in weekMap.values) {
        for (var i = 0; i < day.length; i++) {
          final p = day[i];
          if (p.allowFailureOnLastSet) {
            if (remainingEffort <= 0) {
              // Técnica no permitida: subir RIR conservadoramente
              final currentRir = p.rirTarget;
              final increasedRir = _increaseRirConservatively(currentRir);
              day[i] = p
                  .copyWithRirTarget(increasedRir)
                  .copyWith(allowFailureOnLastSet: false);
              progressionBlocked = true;
              decisions.add(
                DecisionTrace.warning(
                  phase: 'TrainingProgramEngine',
                  category: 'engine_final_guardrail_applied',
                  description:
                      'Presupuesto de esfuerzo excedido: técnica removida, RIR ajustado',
                  context: {
                    'week': weekIndex,
                    'muscle': p.muscleGroup.name,
                    'previousRir': currentRir.label,
                    'newRir': increasedRir.label,
                  },
                ),
              );
            } else {
              remainingEffort--;
            }
          }
        }
      }

      adjusted[weekIndex] = weekMap;
    }

    return _FinalValidationResult(
      weekDayPrescriptions: adjusted,
      decisions: decisions,
      progressionBlocked: progressionBlocked,
    );
  }

  /// Normaliza claves de músculos para maps que vienen de extras/overrides.
  Map<String, double> _normalizeMuscleKeys(Map<String, dynamic> raw) {
    const keyMap = {
      'chest': 'pectorals',
      'back': 'upperBack',
      'lats': 'latissimus',
      'traps': 'trapezius',
      'shoulders': 'deltoids',
      'biceps': 'biceps',
      'triceps': 'triceps',
      'forearms': 'forearms',
      'quads': 'quadriceps',
      'hamstrings': 'hamstrings',
      'glutes': 'glutes',
      'calves': 'calves',
      'abs': 'abdominals',
      'fullBody': 'fullBody',
    };

    final normalized = <String, double>{};

    for (final entry in raw.entries) {
      final rawKey = entry.key.toString();
      final mappedKey = keyMap[rawKey] ?? rawKey;
      final canonicalKey = _canonicalMuscleKey(mappedKey);
      if (canonicalKey == null) continue;

      final value = entry.value;
      double? sets;
      if (value is num) {
        sets = value.toDouble();
      } else if (value is String) {
        sets = double.tryParse(value.replaceAll(',', '.'));
      }

      if (sets != null) {
        normalized[canonicalKey] = sets;
      }
    }

    return normalized;
  }

  String? _canonicalMuscleKey(String rawKey) {
    final normalized = rawKey.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-]+'),
      '',
    );

    const aliasToCanonical = {
      'pectorals': 'chest',
      'pectorales': 'chest',
      'upperback': 'upper_back',
      'latissimus': 'lats',
      'trapezius': 'traps',
      'deltoids': 'deltoide_lateral', // Fallback conservador a lateral
      'quadriceps': 'quads',
      'abdominals': 'abs',
    };

    final aliasMatch = aliasToCanonical[normalized];
    if (aliasMatch != null) {
      return aliasMatch;
    }

    // Buscar en las 14 keys canónicas
    for (final muscle in SupportedMuscles.keys) {
      final canonical = muscle.toLowerCase();
      final flattened = canonical.replaceAll(RegExp(r'[\s_\-]+'), '');
      if (normalized == flattened) {
        return muscle;
      }
    }

    return null;
  }

  /// Incrementa conservadoramente el RIR en 1 punto (sin decimales)
  /// Ejemplos:
  /// - RirTarget.single(2) -> RirTarget.single(3)
  /// - RirTarget.range(2, 3) -> RirTarget.range(3, 4)
  /// - RirTarget.single(3) -> RirTarget.single(4)
  RirTarget _increaseRirConservatively(RirTarget current) {
    final newMin = (current.min + 1).clamp(0, 4);
    final newMax = (current.max + 1).clamp(0, 4);
    if (newMin == newMax) {
      return RirTarget.single(newMin);
    }
    return RirTarget.range(newMin, newMax);
  }

  /// Helper para leer lista de strings desde extra de forma segura
  List<String> _readStringList(Map<String, dynamic> extra, String key) {
    final raw = extra[key];
    if (raw is! Iterable) return const [];
    return raw.map((e) => e.toString()).toList();
  }
}

class _FinalValidationResult {
  final Map<int, Map<int, List<ExercisePrescription>>> weekDayPrescriptions;
  final List<DecisionTrace> decisions;
  final bool progressionBlocked;

  const _FinalValidationResult({
    required this.weekDayPrescriptions,
    required this.decisions,
    required this.progressionBlocked,
  });
}

/// Entrypoint moderno que delega al Motor v2-FULL (sin legacy)
/// Mantiene la misma interfaz pública para compatibilidad con providers/UI.
class TrainingProgramEngine {
  final TrainingProgramEngineV2Full _v2 = TrainingProgramEngineV2Full();
  final TrainingContextBuilder _builder = TrainingContextBuilder();

  List<DecisionTrace> get lastDecisions => _v2.lastDecisions;

  TrainingPlanConfig generatePlan({
    required String planId,
    required String clientId,
    required String planName,
    required DateTime startDate,
    required TrainingProfile profile,
    Client? client,
    TrainingHistory? history,
    List<TrainingSessionLog> logs = const [],
    TrainingFeedback? latestFeedback,
    ExerciseCatalog? exerciseCatalog,
    List<Exercise>? exercises,
  }) {
    // Motor v2 FULL debe correr con TrainingContext para garantizar contrato.
    if (client == null) {
      // Si no hay Client, no generamos: bloquear con mensaje accionable.
      throw const TrainingPlanBlockedException(
        message:
            'No se puede generar plan sin Client completo (contexto requerido para Motor v2).',
      );
    }

    final build = _builder.build(client: client, asOfDate: startDate);
    if (!build.isOk || build.context == null) {
      throw TrainingPlanBlockedException(
        message:
            build.error?.message ?? 'No se pudo construir TrainingContext.',
      );
    }

    final TrainingContext ctx = build.context!;
    // Unificamos trace: primero build, luego motor
    _v2.lastDecisions.addAll(build.trace);

    return _v2.generatePlan(
      planId: planId,
      clientId: clientId,
      planName: planName,
      startDate: startDate,
      context: ctx,
      client: client,
      history: history,
      logs: logs,
      latestFeedback: latestFeedback,
      exerciseCatalog: exerciseCatalog,
      exercises: exercises,
    );
  }
}
