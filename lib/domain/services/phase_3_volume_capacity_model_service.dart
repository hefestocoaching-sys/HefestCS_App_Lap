import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';
import 'package:hcs_app_lap/domain/constants/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart'
    show ReadinessLevel;
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

/// Resultado de la Fase 3: Modelo de capacidad de volumen
class Phase3Result {
  final Map<String, VolumeLimits> volumeLimitsByMuscle;
  final List<DecisionTrace> decisions;
  final Map<String, dynamic> metadata;

  const Phase3Result({
    required this.volumeLimitsByMuscle,
    required this.decisions,
    required this.metadata,
  });

  int getTotalMEV() =>
      volumeLimitsByMuscle.values.fold(0, (sum, limits) => sum + limits.mev);

  int getTotalMAV() =>
      volumeLimitsByMuscle.values.fold(0, (sum, limits) => sum + limits.mav);

  int getTotalMRV() =>
      volumeLimitsByMuscle.values.fold(0, (sum, limits) => sum + limits.mrv);

  int getTotalRecommendedVolume() => volumeLimitsByMuscle.values.fold(
    0,
    (sum, limits) => sum + limits.recommendedStartVolume,
  );
}

/// Fase 3: Modelo de capacidad de volumen (MEV/MAV/MRV por músculo).
///
/// Calcula los límites de volumen científicamente informados para cada grupo muscular
/// basándose en:
/// - Nivel de entrenamiento (principiante, intermedio, avanzado)
/// - Uso de farmacología anabólica (+10-15% MRV)
/// - Historial de volumen tolerado
/// - Edad y género (ajustes menores)
///
/// Referencias científicas:
/// - Schoenfeld et al., 2017: "Dose-response relationship between weekly set volume and muscle mass gain"
/// - Mike Israetel (Renaissance Periodization): "Volume Landmarks for Muscle Growth"
/// - Helms et al., 2018: "Evidence-based recommendations for natural bodybuilding contest preparation"
///
/// REGLAS ABSOLUTAS:
/// - MRV NUNCA debe excederse
/// - Principiantes: MRV máximo 16 sets/músculo/semana
/// - En duda, usar límites conservadores
class Phase3VolumeCapacityModelService {
  /// Calcula los límites de volumen para cada grupo muscular
  Phase3Result calculateVolumeCapacity({
    required TrainingProfile profile,
    TrainingHistory? history,
    required double readinessAdjustment, // Factor de Phase2 (0.5 - 1.15)
    Map<MuscleGroup, ReadinessLevel> readinessByMuscle = const {},
    ManualOverride? manualOverride,
  }) {
    final decisions = <DecisionTrace>[];
    final metadata = <String, dynamic>{};
    final volumeLimits = <String, VolumeLimits>{};

    // 1. Determinar nivel de entrenamiento efectivo
    final effectiveLevel = _determineEffectiveTrainingLevel(
      profile,
      history,
      decisions,
    );
    metadata['effectiveTrainingLevel'] = effectiveLevel.name;

    // 2. Calcular factores de ajuste globales
    final pharmacologyFactor = _calculatePharmacologyFactor(profile, decisions);
    final ageFactor = _calculateAgeFactor(profile, decisions);
    final genderFactor = _calculateGenderFactor(profile, decisions);

    metadata['pharmacologyFactor'] = pharmacologyFactor;
    metadata['ageFactor'] = ageFactor;
    metadata['genderFactor'] = genderFactor;
    metadata['readinessAdjustment'] = readinessAdjustment;

    // 3. Obtener lista de músculos a programar
    final muscleGroups = _getMuscleGroupsToProgram(profile, decisions);

    // 3b. C2: Normalización de VOP para músculos no prioritarios
    // Evitar bloqueo total cuando faltan VOPs explícitos para músculos secundarios
    final normalizedProfile = _normalizeVopForNonPriorityMuscles(
      profile,
      muscleGroups,
      effectiveLevel,
      decisions,
    );

    // 4. Calcular límites base para cada músculo
    for (final muscle in muscleGroups) {
      final baseLimits = _getBaseLimitsForMuscle(
        muscle,
        effectiveLevel,
        decisions,
      );

      // 5. Aplicar ajustes específicos
      var adjustedLimits = _applyAdjustments(
        baseLimits,
        pharmacologyFactor: pharmacologyFactor,
        ageFactor: ageFactor,
        genderFactor: genderFactor,
        readinessAdjustment: readinessAdjustment,
        readinessByMuscle: readinessByMuscle,
        profile: normalizedProfile,
        muscle: muscle,
        decisions: decisions,
      );

      // 5b. Aplicar overrides manuales de volumen
      if (manualOverride?.volumeOverrides != null) {
        final override = manualOverride!.volumeOverrides![muscle];
        if (override != null && !override.isEmpty) {
          var overriddenMev = override.mev ?? adjustedLimits.mev;
          var overriddenMav = override.mav ?? adjustedLimits.mav;
          var overriddenMrv = override.mrv ?? adjustedLimits.mrv;

          // Guardrails defensivos
          if (effectiveLevel == TrainingLevel.beginner && overriddenMrv > 16) {
            overriddenMrv = 16;
            decisions.add(
              DecisionTrace.warning(
                phase: 'Phase3VolumeCapacity',
                category: 'guardrail_override',
                description:
                    'Override de MRV para $muscle clampado a 16 (seguro principiante)',
                context: {
                  'muscle': muscle,
                  'overrideAttempted': override.mrv,
                  'clampedTo': 16,
                },
              ),
            );
          }

          // MRV >= MEV base (no permitir que override reduzca MRV por debajo de MEV base)
          if (overriddenMrv < baseLimits.mev) {
            overriddenMrv = baseLimits.mev;
            decisions.add(
              DecisionTrace.warning(
                phase: 'Phase3VolumeCapacity',
                category: 'guardrail_override',
                description:
                    'Override de MRV para $muscle debe ser >= MEV base (${baseLimits.mev})',
                context: {
                  'muscle': muscle,
                  'overrideMrv': override.mrv,
                  'baseMev': baseLimits.mev,
                  'adjustedMrv': overriddenMrv,
                },
              ),
            );
          }

          adjustedLimits = adjustedLimits.copyWith(
            mev: overriddenMev,
            mav: overriddenMav,
            mrv: overriddenMrv,
          );

          decisions.add(
            DecisionTrace.info(
              phase: 'Phase3VolumeCapacity',
              category: 'volume_override_applied',
              description: 'Override de volumen aplicado a $muscle',
              context: {
                'muscle': muscle,
                'mev': overriddenMev,
                'mav': overriddenMav,
                'mrv': overriddenMrv,
                'baseMev': baseLimits.mev,
                'baseMAV': baseLimits.mav,
                'baseMrv': baseLimits.mrv,
              },
            ),
          );
        }
      }

      volumeLimits[muscle] = adjustedLimits;
    }

    // 6. Validar límites totales
    _validateTotalVolume(volumeLimits, normalizedProfile, decisions);

    // 7. Validación final de seguridad por músculo
    _applyFinalSafetyValidation(volumeLimits, effectiveLevel, decisions);

    // 8. Decisión final
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacity',
        category: 'final_result',
        description:
            'Límites de volumen calculados para ${volumeLimits.length} grupos musculares',
        context: {
          'totalMEV': volumeLimits.values.fold(0, (sum, l) => sum + l.mev),
          'totalMAV': volumeLimits.values.fold(0, (sum, l) => sum + l.mav),
          'totalMRV': volumeLimits.values.fold(0, (sum, l) => sum + l.mrv),
          'recommendedVolume': volumeLimits.values.fold(
            0,
            (sum, l) => sum + l.recommendedStartVolume,
          ),
        },
      ),
    );

    return Phase3Result(
      volumeLimitsByMuscle: volumeLimits,
      decisions: decisions,
      metadata: metadata,
    );
  }

  /// V2: Calcula los límites de volumen usando TrainingContext V2
  Phase3Result calculateVolumeCapacityV2({
    required TrainingContext context,
    TrainingHistory? history,
    required double readinessAdjustment, // Factor de Phase2 (0.5 - 1.15)
    Map<MuscleGroup, ReadinessLevel> readinessByMuscle = const {},
    ManualOverride? manualOverride,
  }) {
    final decisions = <DecisionTrace>[];
    final metadata = <String, dynamic>{};
    final volumeLimits = <String, VolumeLimits>{};

    // 1. Determinar nivel de entrenamiento efectivo desde V2
    final effectiveLevel = _determineEffectiveTrainingLevelV2(
      context.meta.level,
      context.interview,
      history,
      decisions,
    );
    metadata['effectiveTrainingLevel'] = effectiveLevel.name;

    // 2. Calcular factores de ajuste globales usando V2
    final pharmacologyFactor = _calculatePharmacologyFactorV2(
      context.athlete,
      decisions,
    );
    final ageFactor = _calculateAgeFactorV2(context.athlete, decisions);
    final genderFactor = _calculateGenderFactorV2(context.athlete, decisions);

    metadata['pharmacologyFactor'] = pharmacologyFactor;
    metadata['ageFactor'] = ageFactor;
    metadata['genderFactor'] = genderFactor;
    metadata['readinessAdjustment'] = readinessAdjustment;

    // 3. Obtener lista de músculos a programar desde V2
    final muscleGroups = _getMuscleGroupsToProgramV2(
      context.priorities,
      decisions,
    );

    // 4. Calcular límites base para cada músculo
    for (final muscle in muscleGroups) {
      final baseLimits = _getBaseLimitsForMuscle(
        muscle,
        effectiveLevel,
        decisions,
      );

      // 5. Aplicar ajustes específicos usando datos V2
      var adjustedLimits = _applyAdjustmentsV2(
        baseLimits,
        pharmacologyFactor: pharmacologyFactor,
        ageFactor: ageFactor,
        genderFactor: genderFactor,
        readinessAdjustment: readinessAdjustment,
        readinessByMuscle: readinessByMuscle,
        context: context,
        muscle: muscle,
        decisions: decisions,
      );

      // 5b. Aplicar overrides manuales de volumen
      if (manualOverride?.volumeOverrides != null) {
        final override = manualOverride!.volumeOverrides![muscle];
        if (override != null && !override.isEmpty) {
          var overriddenMev = override.mev ?? adjustedLimits.mev;
          var overriddenMav = override.mav ?? adjustedLimits.mav;
          var overriddenMrv = override.mrv ?? adjustedLimits.mrv;

          // Guardrails defensivos
          if (effectiveLevel == TrainingLevel.beginner && overriddenMrv > 16) {
            overriddenMrv = 16;
            decisions.add(
              DecisionTrace.warning(
                phase: 'Phase3VolumeCapacityV2',
                category: 'guardrail_override',
                description:
                    'Override de MRV para $muscle clampado a 16 (seguro principiante)',
                context: {
                  'muscle': muscle,
                  'overrideAttempted': override.mrv,
                  'clampedTo': 16,
                },
              ),
            );
          }

          // MRV >= MEV base
          if (overriddenMrv < baseLimits.mev) {
            overriddenMrv = baseLimits.mev;
            decisions.add(
              DecisionTrace.warning(
                phase: 'Phase3VolumeCapacityV2',
                category: 'guardrail_override',
                description:
                    'Override de MRV para $muscle debe ser >= MEV base (${baseLimits.mev})',
                context: {
                  'muscle': muscle,
                  'overrideMrv': override.mrv,
                  'baseMev': baseLimits.mev,
                  'adjustedMrv': overriddenMrv,
                },
              ),
            );
          }

          adjustedLimits = adjustedLimits.copyWith(
            mev: overriddenMev,
            mav: overriddenMav,
            mrv: overriddenMrv,
          );

          decisions.add(
            DecisionTrace.info(
              phase: 'Phase3VolumeCapacityV2',
              category: 'volume_override_applied',
              description: 'Override de volumen aplicado a $muscle',
              context: {
                'muscle': muscle,
                'mev': overriddenMev,
                'mav': overriddenMav,
                'mrv': overriddenMrv,
              },
            ),
          );
        }
      }

      volumeLimits[muscle] = adjustedLimits;
    }

    // 6. Validar límites totales usando datos V2
    _validateTotalVolumeV2(volumeLimits, context, decisions);

    // 7. Validación final de seguridad
    _applyFinalSafetyValidation(volumeLimits, effectiveLevel, decisions);

    // 8. Decisión final
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacityV2',
        category: 'final_result',
        description:
            'Límites de volumen V2 calculados para ${volumeLimits.length} grupos musculares',
        context: {
          'totalMEV': volumeLimits.values.fold(0, (sum, l) => sum + l.mev),
          'totalMAV': volumeLimits.values.fold(0, (sum, l) => sum + l.mav),
          'totalMRV': volumeLimits.values.fold(0, (sum, l) => sum + l.mrv),
          'recommendedVolume': volumeLimits.values.fold(
            0,
            (sum, l) => sum + l.recommendedStartVolume,
          ),
          'avgWeeklySetsPerMuscle': context.interview.avgWeeklySetsPerMuscle,
          'consecutiveWeeksTraining':
              context.interview.consecutiveWeeksTraining,
        },
      ),
    );

    return Phase3Result(
      volumeLimitsByMuscle: volumeLimits,
      decisions: decisions,
      metadata: metadata,
    );
  }

  /// Determina el nivel de entrenamiento efectivo
  TrainingLevel _determineEffectiveTrainingLevel(
    TrainingProfile profile,
    TrainingHistory? history,
    List<DecisionTrace> decisions,
  ) {
    // Si el perfil tiene nivel explícito, usarlo
    if (profile.trainingLevel != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacity',
          category: 'level_determination',
          description:
              'Nivel de entrenamiento del perfil: ${profile.trainingLevel!.name}',
        ),
      );
      return profile.trainingLevel!;
    }

    // Inferir del historial si existe
    if (history != null && history.hasData) {
      final totalSessions = history.totalSessions;
      TrainingLevel inferredLevel;

      if (totalSessions >= 200) {
        inferredLevel = TrainingLevel.advanced;
      } else if (totalSessions >= 80) {
        inferredLevel = TrainingLevel.intermediate;
      } else {
        inferredLevel = TrainingLevel.beginner;
      }

      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase3VolumeCapacity',
          category: 'level_determination',
          description:
              'Nivel inferido del historial: ${inferredLevel.name} ($totalSessions sesiones)',
          action: 'Se recomienda especificar nivel explícitamente',
        ),
      );

      return inferredLevel;
    }

    // Default conservador: principiante
    decisions.add(
      DecisionTrace.warning(
        phase: 'Phase3VolumeCapacity',
        category: 'level_determination',
        description: 'Nivel no especificado y sin historial',
        action: 'Asumiendo nivel principiante (conservador)',
      ),
    );

    return TrainingLevel.beginner;
  }

  /// Calcula el factor de ajuste por farmacología
  double _calculatePharmacologyFactor(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
  ) {
    if (!profile.usesAnabolics) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacity',
          category: 'pharmacology',
          description: 'Sin farmacología anabólica',
        ),
      );
      return 1.0;
    }

    // Usuarios de anabólicos pueden tolerar 10-15% más volumen
    const factor = 1.125; // +12.5% promedio

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacity',
        category: 'pharmacology',
        description: 'Usuario de farmacología anabólica',
        context: {
          'protocol': profile.pharmacologyProtocol ?? 'no especificado',
        },
        action: 'Aplicando +12.5% a MRV por mayor capacidad de recuperación',
      ),
    );

    return factor;
  }

  /// Calcula el factor de ajuste por edad
  double _calculateAgeFactor(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
  ) {
    final age = profile.age;
    if (age == null) {
      return 1.0;
    }

    double factor;
    if (age < 25) {
      factor = 1.05; // Jóvenes pueden manejar ligeramente más volumen
    } else if (age < 40) {
      factor = 1.0; // Edad óptima
    } else if (age < 50) {
      factor = 0.95; // Reducción ligera
    } else {
      factor = 0.90; // Reducción moderada para recuperación
    }

    if (factor != 1.0) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacity',
          category: 'age_adjustment',
          description:
              'Ajuste por edad ($age años): ${(factor * 100).toStringAsFixed(0)}%',
        ),
      );
    }

    return factor;
  }

  /// Calcula el factor de ajuste por género
  double _calculateGenderFactor(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
  ) {
    // La literatura actual sugiere que las mujeres pueden tolerar
    // volúmenes similares o ligeramente superiores a los hombres
    // Fuente: Colquhoun et al., 2018; Schoenfeld et al., 2019

    // Por simplicidad, mantenemos factor neutro
    // Ajustes individuales se harán por readiness y feedback
    return 1.0;
  }

  /// C2: Normaliza VOP para músculos no prioritarios antes de bloquear
  ///
  /// Evita bloqueo total del motor cuando faltan VOPs explícitos para músculos
  /// secundarios. Asigna volumen mínimo efectivo (MEV ~2-4 sets) a músculos
  /// no prioritarios con VOP=0/null.
  ///
  /// Mantiene bloqueo SOLO para músculos prioritarios sin VOP explícito.
  TrainingProfile _normalizeVopForNonPriorityMuscles(
    TrainingProfile profile,
    List<String> muscleGroups,
    TrainingLevel effectiveLevel,
    List<DecisionTrace> decisions,
  ) {
    // Identificar músculos prioritarios
    final allPriorityMuscles = <String>{
      ...profile.priorityMusclesPrimary,
      ...profile.priorityMusclesSecondary,
      ...profile.priorityMusclesTertiary,
    };

    // Si no hay músculos prioritarios, no normalizar
    if (allPriorityMuscles.isEmpty) {
      return profile;
    }

    // Copiar baseVolumePerMuscle para modificar
    final normalizedVolumes = Map<String, int>.from(
      profile.baseVolumePerMuscle,
    );
    var normalizedCount = 0;

    // Iterar músculos a programar
    for (final muscle in muscleGroups) {
      final isPriority = allPriorityMuscles.contains(muscle);
      final currentVop = normalizedVolumes[muscle] ?? 0;

      // Solo normalizar músculos NO prioritarios con VOP=0/null
      if (!isPriority && currentVop == 0) {
        // Asignar MEV mínimo según nivel
        final minimumEffectiveVop = _getMinimumEffectiveVop(effectiveLevel);
        normalizedVolumes[muscle] = minimumEffectiveVop;
        normalizedCount++;

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase3VolumeCapacity',
            category: 'vop_normalization',
            description: 'VOP normalizado para músculo no prioritario: $muscle',
            context: {
              'muscle': muscle,
              'isPriority': false,
              'originalVop': currentVop,
              'normalizedVop': minimumEffectiveVop,
              'effectiveLevel': effectiveLevel.name,
            },
          ),
        );
      }
    }

    if (normalizedCount > 0) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacity',
          category: 'vop_normalization_summary',
          description:
              'C2: Normalización de VOP completada - $normalizedCount músculos no prioritarios normalizados',
          context: {
            'normalizedCount': normalizedCount,
            'totalMuscles': muscleGroups.length,
            'priorityMuscles': allPriorityMuscles.length,
          },
        ),
      );

      return profile.copyWith(baseVolumePerMuscle: normalizedVolumes);
    }

    return profile;
  }

  /// Obtiene el VOP mínimo efectivo según nivel de entrenamiento
  int _getMinimumEffectiveVop(TrainingLevel level) {
    // Basado en MEV científico (Mike Israetel, Renaissance Periodization)
    switch (level) {
      case TrainingLevel.beginner:
        return 2; // 2 sets/semana mínimo para principiantes
      case TrainingLevel.intermediate:
        return 3; // 3 sets/semana para intermedios
      case TrainingLevel.advanced:
        return 4; // 4 sets/semana para avanzados
    }
  }

  /// Obtiene la lista de grupos musculares a programar
  List<String> _getMuscleGroupsToProgram(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
  ) {
    final muscles = <String>{};
    final sources = <String>[];

    // (0) Canon de 14 músculos (SSOT para Phase 3)
    const canonicalMuscles = <String>[
      'chest',
      'back',
      'lats',
      'traps',
      'shoulders',
      'biceps',
      'triceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
      'deltoide_anterior',
      'deltoide_lateral',
    ];
    muscles.addAll(canonicalMuscles);
    sources.add('canonical_14');

    // (1) Agregar músculos de baseVolumePerMuscle (entrevista)
    if (profile.baseVolumePerMuscle.isNotEmpty) {
      muscles.addAll(profile.baseVolumePerMuscle.keys);
      sources.add('baseVolumePerMuscle');
    }

    // (2) Agregar prioridades
    final priorityCount =
        profile.priorityMusclesPrimary.length +
        profile.priorityMusclesSecondary.length +
        profile.priorityMusclesTertiary.length;

    if (priorityCount > 0) {
      muscles.addAll(profile.priorityMusclesPrimary);
      muscles.addAll(profile.priorityMusclesSecondary);
      muscles.addAll(profile.priorityMusclesTertiary);
      sources.add('priorities');
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacity',
        category: 'muscle_selection',
        description:
            'Músculos a programar determinados desde: ${sources.join(", ")}',
        context: {
          'muscleCount': muscles.length,
          'sources': sources,
          'daysPerWeek': profile.daysPerWeek,
        },
      ),
    );

    return muscles.toList();
  }

  /// Obtiene los límites base para un músculo según nivel
  VolumeLimits _getBaseLimitsForMuscle(
    String muscle,
    TrainingLevel level,
    List<DecisionTrace> decisions,
  ) {
    // Usar VolumeLandmarks centralizado
    final levelName = level.name; // 'beginner', 'intermediate', 'advanced'

    int mev;
    int mav;
    int mrv;
    int recommendedStart;
    String source;

    try {
      final mavMin = VolumeLandmarks.getMAVMin(muscle, levelName);
      final mavMax = VolumeLandmarks.getMAVMax(muscle, levelName);
      mev = VolumeLandmarks.getMEV(muscle, levelName);
      mrv = VolumeLandmarks.getMRV(muscle, levelName);

      // MAV es el punto medio del rango
      mav = ((mavMin + mavMax) / 2).round();

      // Volumen inicial recomendado
      recommendedStart = VolumeLandmarks.getRecommendedStart(muscle, levelName);
      source = 'VolumeLandmarks (Israetel 2024 + Ramos-Campo 2024)';
    } catch (e) {
      // Fallback por músculo canónico (P0-5)
      const canonicalFallback = <String, Map<String, int>>{
        'chest': {'mev': 6, 'mav': 16, 'mrv': 22},
        'back': {'mev': 8, 'mav': 14, 'mrv': 20},
        'lats': {'mev': 8, 'mav': 14, 'mrv': 22},
        'traps': {'mev': 6, 'mav': 10, 'mrv': 14},
        'shoulders': {'mev': 8, 'mav': 12, 'mrv': 20},
        'deltoide_anterior': {'mev': 6, 'mav': 10, 'mrv': 16},
        'deltoide_lateral': {'mev': 6, 'mav': 10, 'mrv': 16},
        'biceps': {'mev': 6, 'mav': 14, 'mrv': 18},
        'triceps': {'mev': 6, 'mav': 14, 'mrv': 18},
        'quads': {'mev': 8, 'mav': 14, 'mrv': 20},
        'hamstrings': {'mev': 6, 'mav': 12, 'mrv': 18},
        'glutes': {'mev': 8, 'mav': 15, 'mrv': 22},
        'calves': {'mev': 8, 'mav': 12, 'mrv': 16},
        'abs': {'mev': 6, 'mav': 14, 'mrv': 20},
      };

      final fallback = canonicalFallback[muscle];
      if (fallback != null) {
        mev = fallback['mev']!;
        mav = fallback['mav']!;
        mrv = fallback['mrv']!;
        recommendedStart = (mav * 0.8).round();
        source = 'canonical_fallback_table';
      } else {
        // Fallback conservador para músculos no reconocidos
        switch (level) {
          case TrainingLevel.beginner:
            mev = 6;
            mav = 10;
            mrv = 14;
            break;
          case TrainingLevel.intermediate:
            mev = 8;
            mav = 12;
            mrv = 18; // Conservador
            break;
          case TrainingLevel.advanced:
            mev = 10;
            mav = 14;
            mrv = 20; // Conservador
            break;
        }

        recommendedStart = mev + ((mav - mev) * 0.3).round();
        source = 'fallback_conservative';
      }

      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase3VolumeCapacity',
          category: 'unknown_muscle_fallback',
          description:
              'Músculo no reconocido: $muscle. Usando valores conservadores',
          context: {
            'muscle': muscle,
            'level': levelName,
            'mev': mev,
            'mav': mav,
            'mrv': mrv,
            'source': source,
          },
        ),
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacity',
        category: 'volume_landmarks_loaded',
        description: 'Límites de volumen cargados desde VolumeLandmarks',
        context: {
          'muscle': muscle,
          'level': levelName,
          'mev': mev,
          'mav': mav,
          'mrv': mrv,
          'source': source,
        },
      ),
    );

    return VolumeLimits(
      muscleGroup: muscle,
      mev: mev,
      mav: mav,
      mrv: mrv,
      recommendedStartVolume: recommendedStart,
      reasoning:
          'Límites base para $muscle, nivel ${level.name}. Source: $source',
    );
  }

  /// Tabla de límites de volumen base por grupo muscular
  // ignore: unused_element
  Map<String, int> _getBaseVolumeLandmarks(String muscle) {
    // DEPRECATED: Ahora se usa VolumeLandmarks
    throw DeprecationException(
      'Use VolumeLandmarks.getComplete() instead of _getBaseVolumeLandmarks()',
    );
  }

  /// Aplica todos los ajustes a los límites base
  VolumeLimits _applyAdjustments(
    VolumeLimits baseLimits, {
    required double pharmacologyFactor,
    required double ageFactor,
    required double genderFactor,
    required double readinessAdjustment,
    required Map<MuscleGroup, ReadinessLevel> readinessByMuscle,
    required TrainingProfile profile,
    required String muscle,
    required List<DecisionTrace> decisions,
  }) {
    // 1. PRIORIDAD: Fuente histórica (si existe)
    String volumeSource;
    int mev, mav, mrv;

    if (profile.pastVolumeTolerance.containsKey(muscle)) {
      final pastTolerance = profile.pastVolumeTolerance[muscle]!;
      final toleranceFactor = pastTolerance.tolerance;

      // Usar tolerancia histórica como fuente primaria
      mev = (baseLimits.mev * toleranceFactor).round();
      mav = (baseLimits.mav * toleranceFactor).round();
      mrv = (baseLimits.mrv * toleranceFactor).round();
      volumeSource = 'historical';

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacity',
          category: 'base_volume_source',
          description:
              'Fuente HISTÓRICA para $muscle (tolerancia: ${(toleranceFactor * 100).toStringAsFixed(0)}%)',
          context: {
            'muscle': muscle,
            'source': 'historical',
            'toleranceFactor': toleranceFactor,
            'historical_mev': mev,
            'historical_mav': mav,
            'historical_mrv': mrv,
          },
        ),
      );
    } else {
      // Usar tablas base
      mev = baseLimits.mev;
      mav = baseLimits.mav;
      mrv = baseLimits.mrv;
      volumeSource = 'table';

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacity',
          category: 'base_volume_source',
          description: 'Fuente TABLA para $muscle (sin historial)',
          context: {
            'muscle': muscle,
            'source': 'table',
            'table_mev': mev,
            'table_mav': mav,
            'table_mrv': mrv,
          },
        ),
      );
    }

    // Factor combinado (aplicado sobre fuente base)
    var combinedFactor = pharmacologyFactor * ageFactor * genderFactor;

    // 2. Ajuste científico por sexo (tren inferior en mujeres)
    final affectedMuscles = <String>[];
    if (profile.gender == Gender.female) {
      final ml = muscle.toLowerCase();
      if (ml == 'glutes' || ml == 'gluteos') {
        // MAV +12%, MRV +20% (promedio rango científico)
        mav = (mav * 1.12).round();
        mrv = (mrv * 1.20).round();
        affectedMuscles.add(muscle);
      } else if (ml == 'quads' || ml == 'cuadriceps') {
        mav = (mav * 1.12).round();
        mrv = (mrv * 1.18).round();
        affectedMuscles.add(muscle);
      } else if (ml == 'hamstrings' || ml == 'isquiotibiales') {
        mav = (mav * 1.10).round();
        mrv = (mrv * 1.15).round();
        affectedMuscles.add(muscle);
      }

      if (affectedMuscles.isNotEmpty) {
        decisions.add(
          DecisionTrace.info(
            phase: 'Phase3VolumeCapacity',
            category: 'gender_factor_applied',
            description: 'Ajuste por sexo (female) aplicado a tren inferior',
            context: {
              'muscle': muscle,
              'gender': 'female',
              'mav_boost': ml == 'glutes' || ml == 'gluteos'
                  ? '+12%'
                  : (ml == 'quads' || ml == 'cuadriceps' ? '+12%' : '+10%'),
              'mrv_boost': ml == 'glutes' || ml == 'gluteos'
                  ? '+20%'
                  : (ml == 'quads' || ml == 'cuadriceps' ? '+18%' : '+15%'),
              'rationale':
                  'Literatura científica: mujeres toleran mayor volumen en tren inferior',
            },
          ),
        );
      }
    }

    // 3. Readiness LOCAL (por músculo)
    final muscleGroup = _mapStringToMuscleGroup(muscle);
    final localReadiness = readinessByMuscle[muscleGroup];
    double readinessLocalFactor = 1.0;

    if (localReadiness != null) {
      switch (localReadiness) {
        case ReadinessLevel.critical:
          readinessLocalFactor = 0.6;
          break;
        case ReadinessLevel.low:
          readinessLocalFactor = 0.8;
          break;
        case ReadinessLevel.moderate:
          readinessLocalFactor = 0.9;
          break;
        case ReadinessLevel.good:
          readinessLocalFactor = 1.0;
          break;
        case ReadinessLevel.excellent:
          readinessLocalFactor = 1.05;
          break;
      }

      if (readinessLocalFactor != 1.0) {
        decisions.add(
          DecisionTrace.info(
            phase: 'Phase3VolumeCapacity',
            category: 'readiness_local_adjustment',
            description: 'Readiness local de $muscle: ${localReadiness.name}',
            context: {
              'muscle': muscle,
              'localReadiness': localReadiness.name,
              'adjustment':
                  '${(readinessLocalFactor * 100).toStringAsFixed(0)}%',
            },
          ),
        );
      }
    }

    // Aplicar farmacología, edad y género a MRV/MAV
    mrv = (mrv * combinedFactor).round();
    mav = (mav * combinedFactor).round();

    // GUARDRAIL ABSOLUTO: Principiantes nunca > 16 sets/músculo/semana
    if (profile.trainingLevel == TrainingLevel.beginner) {
      mrv = mrv.clamp(mev, 16);
      mav = mav.clamp(mev, mrv);
    }

    // MEV estable
    final adjustedMev = mev;
    final adjustedMav = mav.clamp(adjustedMev, mrv);
    final adjustedMrv = mrv;

    // Volumen recomendado: combinar readiness global + local
    var recommendedVolume = (mev + ((adjustedMav - mev) * 0.5)).round();
    recommendedVolume =
        (recommendedVolume * readinessAdjustment * readinessLocalFactor)
            .round();

    // Clampar entre MEV y MAV
    recommendedVolume = recommendedVolume.clamp(adjustedMev, adjustedMav);

    // DecisionTrace final con envelope completo
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacity',
        category: 'final_envelope',
        description: 'Envelope final para $muscle',
        context: {
          'muscle': muscle,
          'source': volumeSource,
          'MEV': adjustedMev,
          'MAV': adjustedMav,
          'MRV': adjustedMrv,
          'recommended': recommendedVolume,
          'pharmacologyFactor': pharmacologyFactor,
          'ageFactor': ageFactor,
          'genderAdjusted': affectedMuscles.isNotEmpty,
          'readinessGlobal': readinessAdjustment,
          'readinessLocal': readinessLocalFactor,
          'trainingLevel': profile.trainingLevel?.name ?? 'beginner',
        },
      ),
    );

    final reasoning =
        'Source: $volumeSource, '
        'pharm=${(pharmacologyFactor * 100).toStringAsFixed(0)}%, '
        'age=${(ageFactor * 100).toStringAsFixed(0)}%, '
        'gender=${affectedMuscles.isNotEmpty ? "adjusted" : "neutral"}, '
        'readiness=${(readinessAdjustment * readinessLocalFactor * 100).toStringAsFixed(0)}%';

    return baseLimits.copyWith(
      mev: adjustedMev,
      mav: adjustedMav,
      mrv: adjustedMrv,
      recommendedStartVolume: recommendedVolume,
      adjustmentFactor: combinedFactor * readinessLocalFactor,
      reasoning: reasoning,
    );
  }

  /// Valida que el volumen total sea razonable para el tiempo disponible
  void _validateTotalVolume(
    Map<String, VolumeLimits> volumeLimits,
    TrainingProfile profile,
    List<DecisionTrace> decisions,
  ) {
    final totalRecommended = volumeLimits.values.fold(
      0,
      (sum, limits) => sum + limits.recommendedStartVolume,
    );

    final totalMRV = volumeLimits.values.fold(
      0,
      (sum, limits) => sum + limits.mrv,
    );

    // Estimar tiempo necesario (promedio 4 minutos por serie)
    final estimatedMinutes = totalRecommended * 4;
    final availableMinutes =
        profile.daysPerWeek * profile.timePerSessionMinutes;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacity',
        category: 'time_validation',
        description:
            'Volumen recomendado: $totalRecommended series/semana '
            '(~$estimatedMinutes min vs $availableMinutes min disponibles)',
        context: {
          'totalRecommended': totalRecommended,
          'totalMRV': totalMRV,
          'estimatedMinutes': estimatedMinutes,
          'availableMinutes': availableMinutes,
        },
      ),
    );

    if (estimatedMinutes > availableMinutes * 1.1) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase3VolumeCapacity',
          category: 'time_constraint',
          description: 'Volumen recomendado excede tiempo disponible',
          action: 'Fase 4 deberá ajustar volumen o priorizar grupos musculares',
        ),
      );
    }
  }

  MuscleGroup? _mapStringToMuscleGroup(String muscle) {
    final ml = muscle.toLowerCase();
    switch (ml) {
      case 'chest':
      case 'pecho':
        return MuscleGroup.chest;
      case 'lats':
      case 'dorsales':
      case 'dorsal':
        return MuscleGroup.lats;
      case 'upper_back':
      case 'espalda alta':
      case 'romboides':
        return MuscleGroup.back; // back enum es la espalda alta/media
      case 'traps':
      case 'trapecio':
      case 'trapecios':
        return MuscleGroup.traps;
      case 'back':
      case 'espalda':
        return MuscleGroup.back;
      case 'shoulders':
      case 'hombros':
      case 'deltoide_anterior':
      case 'deltoide_lateral':
      case 'deltoide_posterior':
        return MuscleGroup.shoulders;
      case 'biceps':
        return MuscleGroup.biceps;
      case 'triceps':
        return MuscleGroup.triceps;
      case 'quads':
      case 'cuadriceps':
        return MuscleGroup.quads;
      case 'hamstrings':
      case 'isquiotibiales':
        return MuscleGroup.hamstrings;
      case 'glutes':
      case 'gluteos':
        return MuscleGroup.glutes;
      case 'calves':
      case 'pantorrillas':
      case 'gastrocnemio':
      case 'soleo':
        return MuscleGroup.calves;
      case 'abs':
      case 'abdominales':
      case 'core':
        return MuscleGroup.abs;
      default:
        return null;
    }
  }

  /// Validación final de seguridad antes de devolver el resultado.
  /// Asegura que:
  /// - MEV <= recommendedStartVolume <= MRV
  /// - Principiantes: MRV <= 16
  /// - recommendedStartVolume nunca sea 0 si el músculo está activo
  void _applyFinalSafetyValidation(
    Map<String, VolumeLimits> volumeLimits,
    TrainingLevel effectiveLevel,
    List<DecisionTrace> decisions,
  ) {
    for (final entry in volumeLimits.entries) {
      final muscle = entry.key;
      final limits = entry.value;
      var needsCorrection = false;
      var correctedVolume = limits.recommendedStartVolume;

      // 1. Validar que recommendedStartVolume esté dentro de [MEV, MRV]
      if (correctedVolume < limits.mev) {
        needsCorrection = true;
        correctedVolume = limits.mev;
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase3VolumeCapacity',
            category: 'volume_clamped_final',
            description:
                'Volumen recomendado para $muscle estaba por debajo del MEV',
            context: {
              'muscle': muscle,
              'originalVolume': limits.recommendedStartVolume,
              'correctedVolume': correctedVolume,
              'mev': limits.mev,
              'reason': 'recommendedStartVolume < MEV',
            },
          ),
        );
      }

      if (correctedVolume > limits.mrv) {
        needsCorrection = true;
        correctedVolume = limits.mrv;
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase3VolumeCapacity',
            category: 'volume_clamped_final',
            description: 'Volumen recomendado para $muscle excedía el MRV',
            context: {
              'muscle': muscle,
              'originalVolume': limits.recommendedStartVolume,
              'correctedVolume': correctedVolume,
              'mrv': limits.mrv,
              'reason': 'recommendedStartVolume > MRV',
            },
          ),
        );
      }

      // 2. Validar que principiantes no tengan MRV > 16
      if (effectiveLevel == TrainingLevel.beginner && limits.mrv > 16) {
        needsCorrection = true;
        final newMrv = 16;
        // Si el volumen recomendado excede el nuevo MRV, ajustarlo
        if (correctedVolume > newMrv) {
          correctedVolume = newMrv;
        }

        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase3VolumeCapacity',
            category: 'volume_clamped_final',
            description:
                'MRV para principiante en $muscle excedía límite de seguridad',
            context: {
              'muscle': muscle,
              'originalMrv': limits.mrv,
              'correctedMrv': newMrv,
              'originalVolume': limits.recommendedStartVolume,
              'correctedVolume': correctedVolume,
              'reason': 'beginner MRV > 16',
            },
          ),
        );

        // Actualizar el límite con el MRV corregido
        volumeLimits[muscle] = limits.copyWith(
          mrv: newMrv,
          mav: limits.mav > newMrv ? newMrv : limits.mav,
          recommendedStartVolume: correctedVolume,
        );
        continue; // Ya actualizamos, continuar con el siguiente músculo
      }

      // 3. Validar que recommendedStartVolume nunca sea 0 si el músculo está activo
      if (correctedVolume == 0) {
        needsCorrection = true;
        correctedVolume = limits.mev;
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase3VolumeCapacity',
            category: 'volume_clamped_final',
            description:
                'Volumen recomendado para $muscle era 0, ajustado a MEV',
            context: {
              'muscle': muscle,
              'originalVolume': 0,
              'correctedVolume': correctedVolume,
              'mev': limits.mev,
              'reason': 'recommendedStartVolume == 0',
            },
          ),
        );
      }

      // Aplicar corrección si fue necesaria
      if (needsCorrection && correctedVolume != limits.recommendedStartVolume) {
        volumeLimits[muscle] = limits.copyWith(
          recommendedStartVolume: correctedVolume,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTODOS V2 (NUEVOS) - Usan TrainingContext
  // ═══════════════════════════════════════════════════════════════

  /// Determina nivel efectivo usando datos V2
  TrainingLevel _determineEffectiveTrainingLevelV2(
    TrainingLevel? explicitLevel,
    TrainingInterviewSnapshot interview,
    TrainingHistory? history,
    List<DecisionTrace> decisions,
  ) {
    if (explicitLevel != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacityV2',
          category: 'level_determination_v2',
          description: 'Nivel explícito V2 desde meta: ${explicitLevel.name}',
          context: {'explicitLevel': explicitLevel.name},
        ),
      );
      return explicitLevel;
    }

    // Usar datos V2 para inferir nivel
    final yearsTraining = interview.yearsTrainingContinuous;
    final consecutiveWeeks = interview.consecutiveWeeksTraining;
    final avgWeeklySets = interview.avgWeeklySetsPerMuscle;

    TrainingLevel inferred;

    // Heurística basada en V2
    if (yearsTraining >= 3 && consecutiveWeeks >= 24 && avgWeeklySets >= 15) {
      inferred = TrainingLevel.advanced;
    } else if (yearsTraining >= 1 &&
        consecutiveWeeks >= 12 &&
        avgWeeklySets >= 10) {
      inferred = TrainingLevel.intermediate;
    } else {
      inferred = TrainingLevel.beginner;
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacityV2',
        category: 'level_determination_v2',
        description: 'Nivel inferido V2: ${inferred.name}',
        context: {
          'yearsTrainingContinuous': yearsTraining,
          'consecutiveWeeksTraining': consecutiveWeeks,
          'avgWeeklySetsPerMuscle': avgWeeklySets,
          'inferredLevel': inferred.name,
        },
      ),
    );

    return inferred;
  }

  /// Calcula factor de farmacología usando V2
  double _calculatePharmacologyFactorV2(
    AthleteSnapshot athlete,
    List<DecisionTrace> decisions,
  ) {
    if (athlete.usesAnabolics) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacityV2',
          category: 'pharmacology_adjustment_v2',
          description: 'Uso de farmacología V2 detectado: +15% MRV',
          context: {'factor': 1.15},
        ),
      );
      return 1.15;
    }
    return 1.0;
  }

  /// Calcula factor de edad usando V2
  double _calculateAgeFactorV2(
    AthleteSnapshot athlete,
    List<DecisionTrace> decisions,
  ) {
    if (athlete.ageYears == null) return 1.0;

    final age = athlete.ageYears!;
    double factor;

    if (age < 25) {
      factor = 1.05; // Jóvenes recuperan mejor
    } else if (age >= 25 && age < 40) {
      factor = 1.0; // Edad óptima
    } else if (age >= 40 && age < 50) {
      factor = 0.95; // Reducción leve
    } else {
      factor = 0.90; // Reducción moderada
    }

    if (factor != 1.0) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacityV2',
          category: 'age_adjustment_v2',
          description:
              'Ajuste por edad V2: $age años → factor ${factor.toStringAsFixed(2)}',
          context: {'age': age, 'factor': factor},
        ),
      );
    }

    return factor;
  }

  /// Calcula factor de género usando V2
  double _calculateGenderFactorV2(
    AthleteSnapshot athlete,
    List<DecisionTrace> decisions,
  ) {
    // Actualmente no hay ajustes específicos por género a nivel global
    // (los ajustes por género se aplican por músculo en _applyAdjustmentsV2)
    return 1.0;
  }

  /// Obtiene músculos a programar desde V2
  List<String> _getMuscleGroupsToProgramV2(
    PrioritiesSnapshot priorities,
    List<DecisionTrace> decisions,
  ) {
    final muscles = <String>{};

    muscles.addAll(priorities.primary);
    muscles.addAll(priorities.secondary);
    muscles.addAll(priorities.tertiary);

    if (muscles.isEmpty) {
      // Fallback: full-body balanceado
      muscles.addAll([
        'chest',
        'back',
        'shoulders',
        'quads',
        'hamstrings',
        'glutes',
      ]);

      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase3VolumeCapacityV2',
          category: 'muscle_selection_v2',
          description: 'Sin prioridades V2 → enfoque full-body balanceado',
          context: {'muscles': muscles.toList()},
        ),
      );
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3VolumeCapacityV2',
          category: 'muscle_selection_v2',
          description: 'Músculos seleccionados V2 desde prioridades',
          context: {
            'primary': priorities.primary,
            'secondary': priorities.secondary,
            'tertiary': priorities.tertiary,
            'total': muscles.length,
          },
        ),
      );
    }

    return muscles.toList();
  }

  /// Aplica ajustes usando datos V2
  VolumeLimits _applyAdjustmentsV2(
    VolumeLimits baseLimits, {
    required double pharmacologyFactor,
    required double ageFactor,
    required double genderFactor,
    required double readinessAdjustment,
    required Map<MuscleGroup, ReadinessLevel> readinessByMuscle,
    required TrainingContext context,
    required String muscle,
    required List<DecisionTrace> decisions,
  }) {
    var mev = baseLimits.mev;
    var mav = baseLimits.mav;
    var mrv = baseLimits.mrv;

    // Aplicar factores globales
    mrv = (mrv * pharmacologyFactor * ageFactor * genderFactor).round();

    // Ajustar por readiness
    mev = (mev * readinessAdjustment).round();
    mav = (mav * readinessAdjustment).round();
    mrv = (mrv * readinessAdjustment).round();

    // Usar avgWeeklySetsPerMuscle de V2 como referencia
    final historicalSets = context.interview.avgWeeklySetsPerMuscle;

    // Si el volumen histórico está bien documentado, usarlo como referencia
    if (historicalSets > 0) {
      // Ajustar MAV hacia el volumen histórico si es razonable
      if (historicalSets >= mev && historicalSets <= mrv) {
        mav = historicalSets;
        decisions.add(
          DecisionTrace.info(
            phase: 'Phase3VolumeCapacityV2',
            category: 'historical_volume_v2',
            description: 'MAV ajustado según volumen histórico V2 para $muscle',
            context: {
              'muscle': muscle,
              'historicalSets': historicalSets,
              'adjustedMAV': mav,
            },
          ),
        );
      }
    }

    // Calcular volumen recomendado (70-80% del MAV)
    final recommended = ((mav * 0.75).round()).clamp(mev, mrv);

    return VolumeLimits(
      muscleGroup: muscle,
      mev: mev,
      mav: mav,
      mrv: mrv,
      recommendedStartVolume: recommended,
    );
  }

  /// Valida volumen total usando datos V2
  void _validateTotalVolumeV2(
    Map<String, VolumeLimits> volumeLimits,
    TrainingContext context,
    List<DecisionTrace> decisions,
  ) {
    final totalMRV = volumeLimits.values.fold(0, (sum, l) => sum + l.mrv);
    final totalRecommended = volumeLimits.values.fold(
      0,
      (sum, l) => sum + l.recommendedStartVolume,
    );

    final daysPerWeek = context.meta.daysPerWeek;
    final timePerSession = context.meta.timePerSessionMinutes;
    final totalWeeklyTime = daysPerWeek * timePerSession;

    // Estimar tiempo necesario (~4 min por serie)
    final estimatedTimeNeeded = totalRecommended * 4;

    if (estimatedTimeNeeded > totalWeeklyTime * 1.2) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase3VolumeCapacityV2',
          category: 'time_constraint_v2',
          description:
              'Volumen recomendado V2 requiere más tiempo del disponible',
          context: {
            'totalRecommendedSets': totalRecommended,
            'estimatedMinutesNeeded': estimatedTimeNeeded,
            'availableMinutes': totalWeeklyTime,
            'daysPerWeek': daysPerWeek,
            'timePerSession': timePerSession,
          },
          action: 'Considerar reducir volumen o aumentar duración de sesiones',
        ),
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3VolumeCapacityV2',
        category: 'total_volume_validation_v2',
        description: 'Validación de volumen total V2',
        context: {
          'totalMEV': volumeLimits.values.fold(0, (sum, l) => sum + l.mev),
          'totalMAV': volumeLimits.values.fold(0, (sum, l) => sum + l.mav),
          'totalMRV': totalMRV,
          'totalRecommended': totalRecommended,
          'avgWeeklySetsPerMuscle': context.interview.avgWeeklySetsPerMuscle,
          'estimatedTimeNeeded': estimatedTimeNeeded,
          'availableTime': totalWeeklyTime,
        },
      ),
    );
  }
}

class DeprecationException implements Exception {
  final String message;

  DeprecationException(this.message);

  @override
  String toString() => 'DeprecationException: $message';
}
