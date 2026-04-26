import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';

// Models
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/services/cycle_template_builder.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_landmarks_calculator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_selection_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_set_allocator.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/mesocycle_exercise_pool.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/ordering_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/session_structure_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_distribution_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/muscle_priority_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/effort_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/phase_progression_engine.dart'
    as phase_engine;
import 'package:hcs_app_lap/domain/training_v3/engines/local_fatigue_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progress_state.dart';
import 'package:hcs_app_lap/domain/constants/volume_to_frequency_rule.dart';
import 'package:hcs_app_lap/domain/training_v3/services/frequency_feasibility_resolver.dart';
import 'package:hcs_app_lap/domain/training_v3/services/volume_feasibility_normalizer.dart';
import 'package:hcs_app_lap/domain/training_v3/policies/intensification_eligibility.dart';

// Validators
import 'package:hcs_app_lap/domain/training_v3/validators/volume_validator.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/configuration_validator.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/training_plan_forensic_validator.dart';

/// Orquestador principal del Motor V3
///
/// Coordina todos los engines y validadores para generar un programa completo:
/// 1. Genera split óptimo
/// 2. Calcula volumen por músculo
/// 3. Selecciona ejercicios
/// 4. Asigna intensidades
/// 5. Asigna RIR
/// 6. Ordena ejercicios
/// 7. Valida programa completo
///
/// FUNDAMENTO CIENTÍFICO:
/// - Pipeline completo basado en Semanas 1-7
/// - Validación científica en cada paso
///
/// Versión: 1.0.0
class MotorV3Orchestrator {
  static final _logger = _MotorLogger();
  static const Map<String, double> _defaultIntensityProfilePercentSplit = {
    'heavy': 20,
    'medium': 60,
    'light': 20,
  };

  static const String _activePlanIdKey = 'activePlanId';

  static const int _adaptationWeeksDefault = 2;
  static const int _maintenanceWeeksDefault = 2;
  static const int _deloadWeeksDefault = 2;

  static const int _microDeloadWindowMin = 4;
  static const int _microDeloadWindowMax = 6;
  static const int _microDeloadDefaultAt = 5; // si no hay bitácora

  static const double _microDeloadVolumeFactor =
      0.85; // -15% (micro-deload activo)
  static const double _deloadVolumeFactor =
      0.80; // -20% (deload activo estándar)
  // Fuente: Androulakis-Korakakis et al. Sports Med Open 2024
  // Cese total (0.0) afecta negativamente la fuerza — Coleman et al. PeerJ 2024
  // Rango práctico consenso: -15% a -25%

  static const double _overreachMaxFactor = 1.15;
  static const int _overreachMaxIncrementPerWeek =
      2; // Máximo aumento semanal vs base

  static const double _localDeloadFactor = 0.5; // Reduce volumen en un 50%
  static const int _fatigueThreshold = 4; // escala 1-5

  // P1-E: Intensification Config
  static const double _intensificationExerciseRatio = 0.30;
  static const int _minSetsForIntensification = 4;

  /// Genera un programa de entrenamiento completo con lógica científica
  ///
  /// **ALGORITMO CIENTÍFICO COMPLETO (10 PASOS):**
  ///
  /// ✅ PASO 1: Validación de entrada
  /// ✅ PASO 2: Conversión Client → UserProfile
  /// ✅ PASO 3: Construir perfil científico (age, experience, recovery)
  /// ✅ PASO 4: Calcular volumen por músculo (VolumeEngine)
  /// ✅ PASO 5: Seleccionar split (SplitGeneratorEngine)
  /// ✅ PASO 6: Seleccionar ejercicios (ExerciseSelectionEngine)
  /// ✅ PASO 7: Distribuir intensidad (IntensityEngine)
  /// ✅ PASO 8: Asignar RIR (EffortEngine)
  /// ✅ PASO 9: Determinar fase periodización (PeriodizationEngine)
  /// ✅ PASO 10: Construir TrainingPlanConfig real con semanas/sesiones
  ///
  /// PARÁMETROS:
  /// - `userProfile`: Perfil completo del usuario
  /// - `phase`: Fase del programa ('accumulation'|'intensification'|'deload')
  /// - `durationWeeks`: Duración en semanas
  /// - `client`: Cliente (opcional, para contexto adicional)
  /// - `exercises`: Lista de ejercicios disponibles
  ///
  /// RETORNA:
  /// - TrainingPlanConfig completo y validado o TrainingProgram
  static Future<Map<String, dynamic>> generateProgram({
    required UserProfile userProfile,
    required String phase,
    required int durationWeeks,
    DateTime? asOfDate,
    String? splitId,
    int? trainingDaysPerWeek,
    Map<String, double>? intensityProfilePercentSplit,
    Map<String, Landmarks>? muscleLandmarks,
    dynamic client,
    List<dynamic> exercises = const [],
  }) async {
    // ✅ PASO 1: Validación de entrada
    if (!userProfile.isValid) {
      throw ArgumentError('UserProfile inválido');
    }

    final errors = <String>[];
    final warnings = <String>[];

    try {
      final effectiveAsOfDate = asOfDate ?? userProfile.updatedAt;

      // ✅ PASO 2: Conversión Client → UserProfile
      // (El UserProfile ya está proporcionado)

      // ✅ PASO 3: Construir perfil científico
      final clientProfile = ClientProfile(
        age: userProfile.age,
        experience: userProfile.trainingLevel,
        recoveryCapacity: _calculateRecoveryCapacity(userProfile),
        caloricBalance: _calculateCaloricBalance(userProfile),
        geneticResponse: 1.0, // default, puede variar según genética individual
      );

      debugPrint('👤 Perfil científico construido:');
      debugPrint('   - Age: ${clientProfile.age}');
      debugPrint('   - Experience: ${clientProfile.experience}');
      debugPrint('   - Recovery: ${clientProfile.recoveryCapacity}');

      final resolvedBackFocus = _resolveBackFocus(client) ?? 'upper_back';

      // ✅ PASO 5: Resolver split efectivo (UI → Motor V3)
      final daysPerWeek = trainingDaysPerWeek ?? userProfile.availableDays;
      final resolvedSplit = _resolveSplit(
        splitId: splitId,
        availableDays: daysPerWeek,
      );
      _logger.info(
        '[Motor V3] splitId=$splitId availableDays=$daysPerWeek resolvedSplit=$resolvedSplit',
      );

      // ✅ PASO 4: Calcular volumen INICIAL con nuevo sistema
      final originalVolumeTargets = expandBackMuscle(
        _resolveVolumeTargets(userProfile, muscleLandmarks),
        backFocus: resolvedBackFocus,
      );
      final normalizedVolumeOutcome = _normalizeVolumeMapForFeasibility(
        targetVolume: originalVolumeTargets,
        daysPerWeek: daysPerWeek,
        split: resolvedSplit,
      );
      final volumeTargets = normalizedVolumeOutcome.normalizedTargets;

      if (normalizedVolumeOutcome.adjustedCount > 0) {
        warnings.add(
          '[V3][P0.3] Se normalizo volumen en ${normalizedVolumeOutcome.adjustedCount} musculos para respetar frecuencia contractual y cap diario.',
        );
      }
      debugPrint(
        '📊 Volumen INICIAL por músculo (VOP): ${volumeTargets.length} grupos',
      );

      await ExerciseCatalogV3.ensureLoaded();
      if (exercises.isNotEmpty) {
        debugPrint(
          '[V3][CATALOG] Ignoring external exercises list. Runtime SSOT uses assets/data/training_v3/catalog/exercise_catalog_v3_runtime.json only.',
        );
      }

      // ✅ PASO 9: Usar fase recibida desde el provider/orchestrator
      final trainingPhase = _resolveTrainingPhase(phase);
      debugPrint('📅 Fase de entrada: ${trainingPhase.name}');

      // ✅ PASO 10: Construir TrainingPlanConfig real
      // P0.3: target original -> target factible normalizado (sin tocar frecuencia).

      final previousPlanConfig = _resolvePreviousPlanConfig(
        client,
        asOfDate: effectiveAsOfDate,
      );
      var cycleStateWrapper = _CycleStateWrapper(
        _readCycleState(previousPlanConfig, profile: userProfile),
      );
      cycleStateWrapper.planConfig = previousPlanConfig;
      final backFocus = resolvedBackFocus;
      final resolvedIntensitySplit = _resolveIntensitySplit(
        intensityProfilePercentSplit,
        client: client,
      );
      final normalizedPriorities = _normalizePriorities(userProfile);
      var mesocyclePoolByMuscle = _resolveMesocycleExercisePoolByMuscle(client);

      // FALLBACK: Si el pool está vacío O si falta algún músculo canónico, reconstruir desde catálogo
      // Esto maneja casos donde el ciclo viejo tiene keys desactualizadas o incompletas
      if (mesocyclePoolByMuscle.isEmpty ||
          volumeTargets.keys.any((muscle) {
            final canonicalMuscle = _canonicalMuscleKey(muscle);
            final poolIds = mesocyclePoolByMuscle[canonicalMuscle] ?? const [];
            return poolIds.isEmpty;
          })) {
        debugPrint(
          '[V3] FALLBACK: Reconstructing exercise pool from catalog (empty or incomplete)',
        );
        final fallbackPool = <String, List<String>>{};
        for (final muscle in volumeTargets.keys) {
          final canonicalMuscle = _canonicalMuscleKey(muscle);
          final catalogExercises = ExerciseCatalogV3.getByMuscle(
            canonicalMuscle,
          );
          final catalogIds = catalogExercises.map((e) => e.id).toList();

          // Usar ejercicios del catálogo si no hay en el pool, sino usar lo que hay
          if (catalogIds.isNotEmpty) {
            fallbackPool[canonicalMuscle] = catalogIds;
          } else {
            fallbackPool[canonicalMuscle] =
                mesocyclePoolByMuscle[canonicalMuscle] ?? [];
          }
        }
        mesocyclePoolByMuscle = fallbackPool;
      }
      debugPrint(
        '[V3][INTENSITY_PROFILE] '
        'heavy=${resolvedIntensitySplit['heavy']} '
        'medium=${resolvedIntensitySplit['medium']} '
        'light=${resolvedIntensitySplit['light']}',
      );

      final planBuildResult = _buildRealTrainingPlan(
        client: client,
        asOfDate: effectiveAsOfDate,
        volumeTargets: volumeTargets,
        originalVolumeTargets: originalVolumeTargets,
        normalizationResults: normalizedVolumeOutcome.results,
        muscleLandmarks: muscleLandmarks,
        mesocycleExercisePoolByMuscle: mesocyclePoolByMuscle,
        intensityProfilePercentSplit: resolvedIntensitySplit,
        split: resolvedSplit,
        phase: trainingPhase,
        durationWeeks: durationWeeks,
        daysPerWeek: daysPerWeek,
        userProfile: userProfile,
        clientProfile: clientProfile,
        cycleStateWrapper: cycleStateWrapper,
        backFocus: backFocus,
      );

      if (!planBuildResult.success) {
        errors.add(
          planBuildResult.error ??
              '[Motor V3] Error construyendo plan real (sin detalle)',
        );
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'planConfig': null,
        };
      }

      var planConfig = planBuildResult.planConfig!;

      // P1A-8: Al final de generatePlan: actualizar estado
      final next = _advanceCycleStateNoLog(cycleStateWrapper.state);
      planConfig = _writeCycleState(planConfig, next);

      final generatedWeeks = planConfig.weeks
          .whereType<TrainingWeek>()
          .toList();
      final hasInvalidSessions = generatedWeeks.any(
        (w) =>
            w.sessions.isEmpty ||
            w.sessions.any((s) => (s as TrainingSession).exercises.isEmpty),
      );
      if (generatedWeeks.isEmpty || hasInvalidSessions) {
        errors.add('[Motor V3] Plan inválido: no se generaron sesiones reales');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'planConfig': null,
        };
      }

      // P0: Extract Week 1 structure for validation
      final Map<int, List<PlannedExercise>> week1Structure = {};
      if (generatedWeeks.isNotEmpty) {
        for (final session in generatedWeeks.first.sessions) {
          week1Structure[session.dayNumber] = session.exercises;
        }
      }

      final coverageResult = _validateExerciseCoverage(
        targetVolume: volumeTargets,
        weekStructure: week1Structure,
        feasibilityPassed: true,
      );

      if (!coverageResult.isValid) {
        return {
          'success': false,
          'errors': coverageResult.errors,
          'warnings': warnings,
          'planConfig': null,
        };
      }

      final forensicResult = TrainingPlanForensicValidator.validate(
        planConfig: planConfig,
        expectedWeeklyVolumeByMuscle: volumeTargets,
        musclePriorities: normalizedPriorities,
      );
      TrainingPlanForensicValidator.logStructured(forensicResult);

      if (!forensicResult.isValid) {
        return {
          'success': false,
          'errors': forensicResult.blockingErrors,
          'warnings': [...warnings, ...forensicResult.warnings],
          'forensicValidation': forensicResult.toMap(),
          'planConfig': null,
        };
      }

      warnings.addAll(forensicResult.warnings);

      final totalSessions = planConfig.weeks.fold<int>(0, (sum, week) {
        final w = week as TrainingWeek;
        return sum + w.sessions.length;
      });
      final totalExercises = planConfig.weeks.fold<int>(0, (sum, week) {
        final w = week as TrainingWeek;
        return sum +
            w.sessions.fold<int>(0, (innerSum, session) {
              final s = session as TrainingSession;
              return innerSum + s.exercises.length;
            });
      });
      _logger.info(
        '[Motor V3] Plan generado: weeks=${planConfig.weeks.length} sessions=$totalSessions exercises=$totalExercises split=$resolvedSplit daysPerWeek=$daysPerWeek',
      );

      final program = _buildProgramFromPlanConfig(
        planConfig: planConfig,
        split: resolvedSplit,
        daysPerWeek: daysPerWeek,
        durationWeeks: durationWeeks,
        userProfile: userProfile,
        volumeTargets: volumeTargets,
      );

      return {
        'success': true,
        'errors': [],
        'warnings': warnings,
        'forensicValidation': forensicResult.toMap(),
        'program': program,
        'planConfig': planConfig,
        'clientProfile': clientProfile,
        'optimizations_applied': 0,
      };
    } catch (e) {
      errors.add('Error generando programa: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
        'planConfig': null,
      };
    }
  }

  /// Calcula volumen INICIAL por músculo (VERSIÓN 2.0)
  ///
  /// CAMBIOS V2.0:
  /// - Usa VolumeLandmarksCalculator
  /// - Retorna VOP (no MAV)
  /// - Normaliza a 14 músculos canónicos
  /// - Calcula landmarks completos por prioridad
  ///
  /// RETORNA: `Map<String, int>` con volumen VOP por músculo
  static Map<String, int> _calculateVolumeByMuscleV2(UserProfile profile) {
    final volumeByMuscle = <String, int>{};

    // ═══════════════════════════════════════════════════════════════
    // PASO 1: Normalizar prioridades a 14 músculos canónicos
    // ═══════════════════════════════════════════════════════════════

    final normalizedPriorities = <String, int>{};
    bool hasBackGroupPriority = false;
    bool hasExplicitLats = false;
    bool hasExplicitUpperBack = false;
    int? backGroupPriority;

    profile.musclePriorities.forEach((muscle, priority) {
      final normalized = muscle_registry.normalize(muscle);

      if (normalized != null) {
        if (normalized == 'lats') hasExplicitLats = true;
        if (normalized == 'upper_back') hasExplicitUpperBack = true;

        if (normalizedPriorities.containsKey(normalized)) {
          normalizedPriorities[normalized] = max(
            normalizedPriorities[normalized]!,
            priority,
          );
        } else {
          normalizedPriorities[normalized] = priority;
        }
        return;
      }

      final expandedGroup = muscle_registry.expandGroup(muscle);
      if (expandedGroup.isNotEmpty) {
        for (final expandedMuscle in expandedGroup) {
          if (normalizedPriorities.containsKey(expandedMuscle)) {
            normalizedPriorities[expandedMuscle] = max(
              normalizedPriorities[expandedMuscle]!,
              priority,
            );
          } else {
            normalizedPriorities[expandedMuscle] = priority;
          }
        }

        if (expandedGroup.contains('lats') &&
            expandedGroup.contains('upper_back')) {
          hasBackGroupPriority = true;
          backGroupPriority = max(backGroupPriority ?? priority, priority);
        }
        return;
      }

      debugPrint(
        '[Motor V3] ⚠️ Músculo desconocido: "$muscle" - será ignorado',
      );
    });

    debugPrint('[Motor V3] ═══════════════════════════════════════');
    debugPrint(
      '[Motor V3] Prioridades normalizadas (${normalizedPriorities.length} músculos):',
    );
    normalizedPriorities.forEach((muscle, priority) {
      debugPrint('  - $muscle: P$priority');
    });
    debugPrint('[Motor V3] ═══════════════════════════════════════');

    // ═══════════════════════════════════════════════════════════════
    // PASO 2: Calcular landmarks completos para músculos con prioridad
    // ═══════════════════════════════════════════════════════════════

    final allLandmarks = VolumeLandmarksCalculator.calculateForAllMuscles(
      musclePriorities: normalizedPriorities,
      trainingLevel: profile.trainingLevel,
      age: profile.age,
    );

    // ═══════════════════════════════════════════════════════════════
    // PASO 3: Extraer VOP de cada landmark + Fallback para músculos sin prioridad
    // ═══════════════════════════════════════════════════════════════

    for (final muscle in muscle_registry.canonicalMuscles) {
      final landmarks = allLandmarks[muscle];

      if (landmarks != null) {
        // Músculo tiene prioridad definida → usar VOP
        volumeByMuscle[muscle] = landmarks.vop;
      } else {
        // Músculo sin prioridad → asignar prioridad default 3 (secundario)
        final fallbackLandmarks = VolumeLandmarks.calculate(
          muscle: muscle,
          priority: 3, // Default: secundario
          trainingLevel: profile.trainingLevel,
          age: profile.age,
        );
        volumeByMuscle[muscle] = fallbackLandmarks.vop;

        debugPrint(
          '[Motor V3] 📌 $muscle sin prioridad → asignado P3 (${fallbackLandmarks.vop} sets)',
        );
      }
    }

    if (hasBackGroupPriority && !hasExplicitLats && !hasExplicitUpperBack) {
      final resolvedPriority = (backGroupPriority ?? 3).clamp(1, 5).toInt();
      final backLandmarks = VolumeLandmarks.calculate(
        muscle: 'upper_back',
        priority: resolvedPriority,
        trainingLevel: profile.trainingLevel,
        age: profile.age,
      );
      final totalBackTarget = max(backLandmarks.vop, 2);
      final latsTarget = (totalBackTarget / 2).ceil();
      final upperBackTarget = totalBackTarget - latsTarget;

      volumeByMuscle['lats'] = latsTarget;
      volumeByMuscle['upper_back'] = upperBackTarget;

      debugPrint(
        '[Motor V3][BackMap] back -> lats=$latsTarget upper_back=$upperBackTarget (total=$totalBackTarget, priority=$resolvedPriority)',
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // PASO 4: Reporte final
    // ═══════════════════════════════════════════════════════════════

    final totalVolume = volumeByMuscle.values.fold(0, (sum, vol) => sum + vol);

    debugPrint('[Motor V3] ═══════════════════════════════════════');
    debugPrint('[Motor V3] VOLÚMENES INICIALES (VOP) - VERSIÓN 2.0:');
    debugPrint('[Motor V3] ═══════════════════════════════════════');

    // Ordenar por prioridad para display
    final sortedMuscles = volumeByMuscle.keys.toList()
      ..sort((a, b) {
        final priorityA = normalizedPriorities[a] ?? 3;
        final priorityB = normalizedPriorities[b] ?? 3;
        return priorityB.compareTo(priorityA); // Descendente (5 primero)
      });

    for (final muscle in sortedMuscles) {
      final volume = volumeByMuscle[muscle]!;
      final priority = normalizedPriorities[muscle] ?? 3;
      final category = priority == 5
          ? 'PRIMARIO'
          : priority >= 3
          ? 'SECUNDARIO'
          : 'TERCIARIO';

      debugPrint('  $muscle (P$priority $category): $volume sets/semana');
    }

    debugPrint('[Motor V3] ───────────────────────────────────────');
    debugPrint('[Motor V3] TOTAL: $totalVolume sets/semana');
    debugPrint('[Motor V3] ═══════════════════════════════════════');

    return volumeByMuscle;
  }

  /// Calcula volumen por músculo (VERSIÓN LEGACY)
  ///
  /// @deprecated Usar _calculateVolumeByMuscleV2() en su lugar.
  /// Este método usa nomenclatura antigua (MAV/MRV) y será eliminado.
  @Deprecated('Usar _calculateVolumeByMuscleV2()')
  // ignore: unused_element
  static Map<String, int> _calculateVolumeByMuscle(UserProfile profile) {
    return _calculateVolumeByMuscleV2(profile);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MÉTODOS AUXILIARES - PASO 3
  // ═══════════════════════════════════════════════════════════════════════

  /// Calcula la capacidad de recuperación (0-10) del atleta
  static double _calculateRecoveryCapacity(UserProfile profile) {
    double capacity = 5.0; // Base 5.0

    // Edad: menores edad → mejor recuperación
    if (profile.age < 25) capacity += 1.5;
    if (profile.age > 40) capacity -= 1.0;

    // Experiencia: mayor experiencia → mejor manejo de fatiga
    if (profile.trainingLevel == 'beginner') capacity -= 0.5;
    if (profile.trainingLevel == 'advanced') capacity += 1.0;

    return capacity.clamp(0.0, 10.0);
  }

  /// Calcula el balance calórico estimado (-500 a +500)
  static double _calculateCaloricBalance(UserProfile profile) {
    // En base al objetivo primario
    switch (profile.primaryGoal) {
      case 'hypertrophy':
        return 300.0; // Superávit leve
      case 'strength':
        return 200.0;
      case 'endurance':
        return -200.0; // Déficit leve
      default:
        return 0.0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MÉTODOS AUXILIARES - PASO 10
  // ═══════════════════════════════════════════════════════════════════════

  /// Construye un TrainingPlanConfig REAL con semanas y progresión científica
  ///
  /// **FUNDAMENTO CIENTÍFICO:**
  ///
  /// **Progresión volumétrica** (01-volume.md):
  /// - Semanas 1-4 (accumulation): +2 sets/semana de progresión
  /// - Semana 5 (intensification): -10% volumen, +intensidad
  /// - Semana 6+ (deload): -50% volumen para recuperación
  ///
  /// **Fases de periodización** (06-progression-variation.md):
  /// - Accumulation: Construir capacidad de trabajo
  /// - Intensification: Pico de rendimiento
  /// - Deload: Recuperación y supercompensación
  static _PlanBuildResult _buildRealTrainingPlan({
    required dynamic client,
    required DateTime asOfDate,
    required Map<String, int> volumeTargets,
    required Map<String, int> originalVolumeTargets,
    required List<VolumeFeasibilityNormalizationResult> normalizationResults,
    required Map<String, Landmarks>? muscleLandmarks,
    required Map<String, List<String>> mesocycleExercisePoolByMuscle,
    required Map<String, double> intensityProfilePercentSplit,
    required TrainingSplit split,
    required TrainingPhase phase,
    required int durationWeeks,
    required int daysPerWeek,
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required _CycleStateWrapper cycleStateWrapper,
    required String? backFocus,
  }) {
    final weeksBuildResult = _buildWeeks(
      durationWeeks: durationWeeks,
      phase: phase,
      split: split,
      daysPerWeek: daysPerWeek,
      muscleLandmarks: muscleLandmarks,
      mesocycleExercisePoolByMuscle: mesocycleExercisePoolByMuscle,
      intensityProfilePercentSplit: intensityProfilePercentSplit,
      volumePerMuscle: volumeTargets,
      userProfile: userProfile,
      clientProfile: clientProfile,
      cycleStateWrapper: cycleStateWrapper,
      backFocus: backFocus,
    );

    if (!weeksBuildResult.success) {
      return _PlanBuildResult.failure(
        weeksBuildResult.error ?? 'Unknown Template Build Error',
      );
    }

    final weeks = weeksBuildResult.weeks!;
    final buildMetadata = weeksBuildResult.extraMetadata;

    final inheritedExtra = Map<String, dynamic>.from(
      cycleStateWrapper.planConfig?.extra ?? const <String, dynamic>{},
    );

    final clientId = client != null
        ? (client as dynamic).id ?? 'client_unknown'
        : 'client_unknown';

    // ═══════════════════════════════════════════════════════════════════
    // PASO 7: Construir TrainingPlanConfig completo con propiedades tipadas
    // ═══════════════════════════════════════════════════════════════════
    return _PlanBuildResult.success(
      TrainingPlanConfig(
        id: 'plan_${clientId}_${asOfDate.millisecondsSinceEpoch}',
        clientId: clientId,
        startDate: asOfDate,
        weeks: weeks,
        createdAt: asOfDate,

        // ✅ PROPIEDADES TIPADAS (reemplazo de extra)
        volumePerMuscle: volumeTargets,
        phase: phase.name,
        split: _splitToString(split),

        // Mantener extra para compatibilidad legacy (deprecado)
        extra: {
          ...inheritedExtra,
          'generated_by': 'motor_v3_scientific',
          'strategy': 'v3_orchestrator',
          'phase': phase.name,
          'split': _splitToString(split),
          'duration_weeks': durationWeeks,
          'volume_targets': volumeTargets,
          'volume_targets_original': originalVolumeTargets,
          'volume_targets_final': volumeTargets,
          'volume_normalization': normalizationResults
              .map((e) => e.toMap())
              .toList(growable: false),
          ...buildMetadata,
          'scientific_version': '2.0.0',
          'periodization_model': 'linear_progressive',
          if (backFocus != null) 'backFocus': backFocus,
        },
      ),
    );
  }

  static _WeeksBuildResult _buildWeeks({
    required int durationWeeks,
    required TrainingPhase phase,
    required TrainingSplit split,
    required int daysPerWeek,
    required Map<String, Landmarks>? muscleLandmarks,
    required Map<String, List<String>> mesocycleExercisePoolByMuscle,
    required Map<String, double> intensityProfilePercentSplit,
    required Map<String, int> volumePerMuscle,
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required _CycleStateWrapper cycleStateWrapper,
    required String? backFocus,
  }) {
    final weeks = <TrainingWeek>[];
    final resolvedBackFocus = (backFocus == 'lats' || backFocus == 'upper_back')
        ? backFocus!
        : 'upper_back';
    final expandedBaseVolume = expandBackMuscle(
      volumePerMuscle,
      backFocus: resolvedBackFocus,
    );

    final weeklyIntensityTargetsByMuscle =
        IntensityDistributionEngine.buildWeeklyTargets(
          weeklySetsByMuscle: expandedBaseVolume,
          intensitySplitPercent: intensityProfilePercentSplit,
        );

    final normalizedPriorities = _normalizePriorities(userProfile);
    final frequencyByMuscle = _deriveFrequencyByMuscle(
      targetVolume: expandedBaseVolume,
      split: split,
      daysPerWeek: daysPerWeek,
    );
    final dayMusclePriorityOrder = MusclePriorityEngine.buildDayMuscleOrder(
      split: split,
      availableDays: daysPerWeek,
      musclePriorities: normalizedPriorities,
      frequencyByMuscle: frequencyByMuscle,
    );

    // ✅ PASO 10.1: Build BASE WEEK (Frozen Template) using CycleTemplateBuilder
    // This selects exercises ONCE and sets up the split/frequency.

    final buildResult = CycleTemplateBuilder.buildBaseWeek(
      userProfile: userProfile,
      clientProfile: clientProfile,
      targetVolumeByMuscle: expandedBaseVolume,
      mesocycleExercisePoolByMuscle: mesocycleExercisePoolByMuscle,
      dayMusclePriorityOrder: dayMusclePriorityOrder,
      intensityProfilePercentSplit: intensityProfilePercentSplit,
      weeklyIntensityTargetsByMuscle: weeklyIntensityTargetsByMuscle,
      availableDays: daysPerWeek,
      split: split,
      backFocus: resolvedBackFocus,
    );

    if (!buildResult.success) {
      return _WeeksBuildResult.failure(
        buildResult.error ?? 'Unknown Template Build Error',
      );
    }
    final baseSessions = buildResult.sessions!;

    // Calculate base volumes per muscle (Week 1)
    final baseVolumeMap = <String, int>{};
    for (final s in baseSessions) {
      for (final ep in s.exercises) {
        final ex = ExerciseCatalogV3.getById(ep.exerciseId);
        if (ex != null) {
          // P0-A: Use muscleKey for structural volume, sets.length for set count
          baseVolumeMap[ep.muscleKey] =
              (baseVolumeMap[ep.muscleKey] ?? 0) + ep.sets.length;
        }
      }
    }

    final allLandmarks = VolumeLandmarksCalculator.calculateForAllMuscles(
      musclePriorities: normalizedPriorities,
      trainingLevel: userProfile.trainingLevel,
      age: userProfile.age,
    );
    final volumeLandmarksByMuscle = <String, Map<String, dynamic>>{
      for (final entry in allLandmarks.entries)
        entry.key: {
          'vme': entry.value.vme,
          'vop': entry.value.vop,
          'vmr': entry.value.vmr,
          'vmrTarget': entry.value.vmrTarget,
        },
    };
    final providedLandmarksByMuscle = <String, Landmarks>{
      if (muscleLandmarks != null)
        for (final entry in muscleLandmarks.entries)
          normalizeMuscleKey(entry.key): entry.value,
    };
    final phaseProgressionEngine = phase_engine.PhaseProgressionEngine();
    final localFatigueEngine = LocalFatigueEngine();

    final muscleStates = <String, MuscleProgressState>{};
    final businessPhaseByWeek = <int, String>{};
    for (final entry in expandedBaseVolume.entries) {
      final m = entry.key;
      final vop = entry.value;
      final provided = providedLandmarksByMuscle[m];
      final lm = allLandmarks[m];
      final vme = provided?.vme ?? lm?.vme ?? max(1, (vop * 0.7).round());
      final mrv = provided?.vmr ?? lm?.vmr ?? max(vop, (vop * 1.3).round());
      muscleStates[m] = MuscleProgressState(
        muscle: m,
        vme: vme,
        vop: vop,
        mrv: mrv,
        currentSets: vop,
        weeksAccumulating: 0,
        localDeloadPending: false,
        localFatigue: 0.0,
        localRecovery: 10.0,
      );
    }

    for (int weekNum = 1; weekNum <= durationWeeks; weekNum++) {
      // ✅ PASO 10.2: Calculate Target Volume for this week (Progression)
      final Map<String, int> targetWeeklyVolume = {};

      final businessPhaseLabel = _resolveBusinessPhaseLabel(
        cycleStateWrapper.state,
      );
      businessPhaseByWeek[weekNum] = businessPhaseLabel;
      final volumeFactor = _businessPhaseVolumeFactor(businessPhaseLabel);
      final allowZoneIntensification = _businessPhaseAllowsZoneIntensification(
        businessPhaseLabel,
      );

      if (weekNum == 1) {
        targetWeeklyVolume.addAll(expandedBaseVolume);
      } else {
        for (final entry in muscleStates.entries) {
          final muscle = entry.key;
          final state = entry.value;

          final phaseForEngine = _mapCyclePhaseToProgression(
            cycleStateWrapper.state.phase,
          );
          final shouldLocalDeload =
              phaseForEngine == phase_engine.TrainingPhase.accumulation &&
              localFatigueEngine.needsLocalDeload(
                localFatigue: state.localFatigue,
                localRecovery: state.localRecovery,
                weeksAccumulating: state.weeksAccumulating,
              );

          final stateForWeek = state.copyWith(
            localDeloadPending: shouldLocalDeload,
          );
          final resolvedSets = phaseProgressionEngine.resolveWeeklySets(
            phase: phaseForEngine,
            state: stateForWeek,
          );
          targetWeeklyVolume[muscle] = resolvedSets;

          if (shouldLocalDeload) {
            debugPrint(
              '[V3][LOCAL_DELOAD] muscle=$muscle currentSets=${state.currentSets} deloadSets=$resolvedSets',
            );
          }

          muscleStates[muscle] = state.copyWith(
            currentSets: resolvedSets,
            weeksAccumulating:
                phaseForEngine == phase_engine.TrainingPhase.accumulation
                ? (shouldLocalDeload ? 0 : state.weeksAccumulating + 1)
                : 0,
            localDeloadPending: false,
          );
        }
      }

      final expandedWeekVolume = expandBackMuscle(
        targetWeeklyVolume,
        backFocus: resolvedBackFocus,
      );
      targetWeeklyVolume
        ..clear()
        ..addAll(expandedWeekVolume);

      targetWeeklyVolume
        ..clear()
        ..addAll(
          _enforcePriorityCapsBeforeMaterialization(
            targetWeeklyVolume: expandedWeekVolume,
            landmarksByMuscle: allLandmarks,
            prioritiesByMuscle: normalizedPriorities,
            allowPrimaryOverVmr: false,
          ),
        );

      // ─────────────────────────────────────────────────────────────────
      // P1-D & P1-C: GATE PARA LOCAL DELOAD, HOLD / OVERREACH
      // ─────────────────────────────────────────────────────────────────
      if (cycleStateWrapper.state.phase == CyclePhase.accumulation) {
        final assigned = _computeAssignedDirectVolume(baseSessions);
        final Map<String, int> newTargets = Map.of(targetWeeklyVolume);

        // P1D-MARK: Detectar fatiga en la semana actual N
        final pendingMap = _readPendingLocalDeload(
          cycleStateWrapper.planConfig,
        );

        // Primero verificamos fatigas para marcar (MARK) antes de evaluar volumen
        for (final m in newTargets.keys) {
          if (_shouldTriggerLocalDeload(
            muscleKey: m,
            planConfig: cycleStateWrapper.planConfig,
          )) {
            pendingMap[m] = true;
            debugPrint('[V3][P1D][MARK] muscle=$m fatigue threshold met');
          }
        }

        // P1D-APPLY y P1C: Evaluar targets (1. Deload, 2. HOLD/OVERREACH)
        for (final m in newTargets.keys) {
          final t = newTargets[m] ?? 0;
          if (t <= 0) continue;

          // 1) P1D Aplicación de Micro-descarga local en semana N+1
          if (pendingMap[m] == true) {
            final a = assigned[m] ?? 0;
            final reduced = (a * _localDeloadFactor).round();

            newTargets[m] = reduced;
            debugPrint('[V3][P1D][APPLY] muscle=$m from=$a to=$reduced');

            // limpiar flag después de aplicar para que regrese a la normalidad en N+2
            pendingMap[m] = false;
            continue; // NO ejecutar HOLD/OVERREACH esta semana
          }

          // 2) P1C HOLD / OVERREACH
          final lm = allLandmarks[m];
          if (lm == null) continue;

          final vmrTarget = lm.vmrTarget;
          final vmr = lm.vmr;
          final a = assigned[m] ?? 0;

          final hasSunday = _hasSundayCheckForMuscle(
            planConfig: cycleStateWrapper.planConfig,
            muscleKey: m,
          );

          // Caso HOLD: en vmrTarget o superior sin evidencia dominical
          if (a >= vmrTarget && !hasSunday) {
            debugPrint(
              '[V3][P1C][HOLD] muscle=$m assigned=$a vmrTarget=$vmrTarget reason=no_sunday_check',
            );
            newTargets[m] = a; // Congela en asignado actual (no sube)
            continue;
          }

          // Caso HOLD u OVERREACH con evidencia
          if (a >= vmrTarget && hasSunday) {
            final ceiling = _softCeilingFromLandmarks(lm);

            if (a >= ceiling) {
              debugPrint(
                '[V3][P1C][HOLD] muscle=$m assigned=$a vmr=$vmr ceiling=$ceiling reason=at_ceiling',
              );
              newTargets[m] = a; // Congela en el límite permitido
              continue;
            }

            final desired = t;
            final allowed = a + _overreachMaxIncrementPerWeek;
            final capped = min(allowed, ceiling);
            final finalTarget = min(desired, capped);

            debugPrint(
              '[V3][P1C][OVERREACH] muscle=$m assigned=$a vmrTarget=$vmrTarget ceiling=$ceiling desired=$desired finalTarget=$finalTarget',
            );
            newTargets[m] = finalTarget;
            continue;
          }
        }

        targetWeeklyVolume.clear();
        targetWeeklyVolume.addAll(newTargets);

        cycleStateWrapper.planConfig = _writePendingLocalDeload(
          cycleStateWrapper.planConfig,
          pendingMap,
        );
      } else {
        // Log compatibility for no meta
        if (cycleStateWrapper.planConfig == null ||
            cycleStateWrapper.planConfig?.extra == null) {
          // Warning already logged during state extraction
        }
      }

      // Apply volume factor (P1A-6)
      for (final m in targetWeeklyVolume.keys) {
        targetWeeklyVolume[m] = (targetWeeklyVolume[m]! * volumeFactor).round();
      }

      final normalizedWeekOutcome = _normalizeVolumeMapForFeasibility(
        targetVolume: targetWeeklyVolume,
        daysPerWeek: daysPerWeek,
        split: split,
      );
      targetWeeklyVolume
        ..clear()
        ..addAll(normalizedWeekOutcome.normalizedTargets);

      debugPrint(
        '[V3][P1A][PHASE] week=${cycleStateWrapper.state.cycleWeek} cyclePhase=${cycleStateWrapper.state.phase.name} businessPhase=$businessPhaseLabel volFactor=$volumeFactor intensificationAllowed=$allowZoneIntensification',
      );

      // P0.1-MVO-1: REMOVED silent cap of 20 sets on weeks > 1.
      // Volume is taken as-is from WeeklyVolumePlanner. If it yields an
      // infeasible value, the pre-build _feasibilityErrors check above
      // will have already hard-failed before reaching this code path.

      List<TrainingSession> weekSessions;

      if (weekNum == 1) {
        // Use base directly (deep copy recommended to avoid ref issues if mutated later?)
        weekSessions = baseSessions
            .map(
              (s) => s.copyWith(
                exercises: s.exercises.map((e) => _cloneExercise(e)).toList(),
              ),
            )
            .toList();
      } else {
        // Clone and Scale Sets
        weekSessions = _cloneWithSetProgression(
          base: baseSessions,
          targetWeeklySetsByMuscle: targetWeeklyVolume,
          baseWeeklySetsByMuscle: baseVolumeMap,
        );
      }

      weekSessions = _applyZoneIntensificationContract(
        sessions: weekSessions,
        businessPhaseLabel: businessPhaseLabel,
        allowZoneIntensification: allowZoneIntensification,
      );

      // ─────────────────────────────────────────────────────────────────
      // P1-E: Intensificación Automática en Fase de Mantenimiento
      // ─────────────────────────────────────────────────────────────────
      if (cycleStateWrapper.state.phase == CyclePhase.maintenance) {
        _applyMaintenanceIntensificationAndRir(
          sessions: weekSessions,
          planConfig: cycleStateWrapper.planConfig,
          musclePriorities: normalizedPriorities,
        );
      }

      final totalSets = weekSessions.fold<int>(
        0,
        (sum, session) => sum + session.totalSets,
      );

      weeks.add(
        TrainingWeek(
          weekNumber: weekNum,
          sessions: weekSessions,
          notes:
              'Semana $weekNum - Fase: ${phase.name.capitalize()} - FaseNegocio: $businessPhaseLabel - Volumen: $totalSets sets',
        ),
      );

      if (weekNum < durationWeeks) {
        cycleStateWrapper.state = _advanceCycleStateNoLog(
          cycleStateWrapper.state,
        );
      }
    }

    return _WeeksBuildResult.success(
      weeks,
      extraMetadata: {
        'volume_landmarks_by_muscle': volumeLandmarksByMuscle,
        'business_phase_by_week': businessPhaseByWeek,
        'frequency_contract': {
          'f1': {
            'distribution': [100],
            'tolerance': [100, 100],
          },
          'f2': {
            'distribution': [50, 50],
            'tolerance': [40, 60],
          },
          'f3': {
            'distribution': [40, 30, 30],
            'tolerance': [35, 45],
          },
        },
        'split_contract': _splitContractMetadata(split, daysPerWeek),
      },
    );
  }

  /// [V3][P0] Scales sets of base sessions to match target WITHOUT changing exercises.
  /// Uses ONLY ep.directTargetMuscleKey (SSOT). Never uses Exercise.primaryMuscles.
  static PlannedExercise _cloneExercise(
    PlannedExercise exercise, {
    List<SetPrescription>? sets,
    IntensificationRule? intensification,
  }) {
    return PlannedExercise(
      id: exercise.id,
      exerciseId: exercise.exerciseId,
      name: exercise.name,
      muscleKey: exercise.muscleKey,
      primaryMuscle: exercise.primaryMuscle,
      secondaryMuscles: List<String>.from(exercise.secondaryMuscles),
      slotLabel: exercise.slotLabel,
      blockLabel: exercise.blockLabel,
      pairGroupId: exercise.pairGroupId,
      isMainLift: exercise.isMainLift,
      sets: sets ?? List<SetPrescription>.from(exercise.sets),
      intensification: intensification ?? exercise.intensification,
    );
  }

  static List<TrainingSession> _cloneWithSetProgression({
    required List<TrainingSession> base,
    required Map<String, int> targetWeeklySetsByMuscle,
    required Map<String, int> baseWeeklySetsByMuscle,
    int maxSetsPerMusclePerSession = 10,
  }) {
    // ── Step 1: Clone structure (deep copy) ──
    final newSessions = base
        .map(
          (s) => s.copyWith(
            exercises: s.exercises.map((e) => _cloneExercise(e)).toList(),
          ),
        )
        .toList();

    // ── Step 2: Flatten all EPs in stable day order ──
    // Track (sessionIdx, epIdx) for reconstruction
    final List<PlannedExercise> allEps = [];
    final List<int> epSessionIndices = []; // which session each EP belongs to
    for (int si = 0; si < newSessions.length; si++) {
      for (final ep in newSessions[si].exercises) {
        allEps.add(ep);
        epSessionIndices.add(si);
      }
    }

    // ── Step 3: Compute assigned direct volume (SSOT) ──
    Map<String, int> computeAssigned(List<PlannedExercise> eps) {
      final out = <String, int>{};
      for (final ep in eps) {
        final m = ep.muscleKey;
        out[m] = (out[m] ?? 0) + ep.sets.length;
      }
      return out;
    }

    var assigned = computeAssigned(allEps);

    // ── Step 4: Deterministic diff distribution per muscle ──
    final musclesToCheck = targetWeeklySetsByMuscle.keys.toSet();

    for (final muscle in musclesToCheck) {
      final target = targetWeeklySetsByMuscle[muscle] ?? 0;
      final current = assigned[muscle] ?? 0;
      var d = target - current;
      if (d == 0) continue;

      // Collect indices of EPs for this muscle (stable order)
      final idxs = <int>[];
      for (int i = 0; i < allEps.length; i++) {
        if (allEps[i].muscleKey == muscle) idxs.add(i);
      }
      if (idxs.isEmpty) {
        continue; // No EPs for this muscle; skip (P0: no new EP creation)
      }

      if (d > 0) {
        // ADD sets: scale up sets in existing EP's set list (round-robin copy)
        final per = d ~/ idxs.length;
        var rem = d % idxs.length;
        for (final i in idxs) {
          final extra = per + (rem > 0 ? 1 : 0);
          if (rem > 0) rem--;
          if (extra > 0) {
            final ep = allEps[i];
            final additionalSets = List.generate(extra, (_) => ep.sets.last);
            allEps[i] = _cloneExercise(
              ep,
              sets: [...ep.sets, ...additionalSets],
            );
          }
        }
      } else {
        // REMOVE sets: round-robin trim, min 1 per EP
        var toRemove = -d;
        var changed = true;
        while (toRemove > 0 && changed) {
          changed = false;
          for (final i in idxs) {
            if (toRemove <= 0) break;
            final curSets = allEps[i].sets;
            if (curSets.length > 1) {
              allEps[i] = _cloneExercise(
                allEps[i],
                sets: curSets.sublist(0, curSets.length - 1),
              );
              toRemove--;
              changed = true;
            }
          }
        }
      }
    }

    // Recompute after diff distribution
    assigned = computeAssigned(allEps);

    // ── Step 5: Log target vs assigned (P0.2-MVO-5) ──
    for (final m in musclesToCheck) {
      final t = targetWeeklySetsByMuscle[m] ?? 0;
      final a = assigned[m] ?? 0;
      if (t > 0) {
        debugPrint('[V3][P0.2][VOL] muscle=$m target=$t assigned=$a');
      }
    }

    // ── Step 6: Levelling pass by directTargetMuscleKey ──
    // Build per-session loads by muscle
    for (final muscle in musclesToCheck) {
      // sessionIdx -> total sets for this muscle
      final sessionLoads = <int, int>{};
      // epGlobalIdx -> sessionIdx
      final epIdxToSession = <int, int>{};

      for (int gi = 0; gi < allEps.length; gi++) {
        if (allEps[gi].muscleKey == muscle) {
          final si = epSessionIndices[gi];
          sessionLoads[si] = (sessionLoads[si] ?? 0) + allEps[gi].sets.length;
          epIdxToSession[gi] = si;
        }
      }

      bool needsBalancing = sessionLoads.values.any(
        (v) => v > maxSetsPerMusclePerSession,
      );

      if (needsBalancing && sessionLoads.length > 1) {
        final days = sessionLoads.keys.toList()
          ..sort((a, b) => sessionLoads[b]!.compareTo(sessionLoads[a]!));

        for (final overloadedDay in days) {
          int excess =
              sessionLoads[overloadedDay]! - maxSetsPerMusclePerSession;
          if (excess <= 0) continue;

          for (final receiverDay in days) {
            if (receiverDay == overloadedDay) continue;
            int room = maxSetsPerMusclePerSession - sessionLoads[receiverDay]!;
            if (room <= 0) continue;

            int toMove = min(excess, room);

            // Find source EP (last in overloaded day with sets>1)
            int? sourceGi;
            for (int gi = allEps.length - 1; gi >= 0; gi--) {
              if (epIdxToSession[gi] == overloadedDay &&
                  allEps[gi].muscleKey == muscle &&
                  allEps[gi].sets.length > 1) {
                sourceGi = gi;
                break;
              }
            }

            // Find dest EP (any in receiver day for this muscle)
            int? destGi;
            for (int gi = 0; gi < allEps.length; gi++) {
              if (epIdxToSession[gi] == receiverDay &&
                  allEps[gi].muscleKey == muscle) {
                destGi = gi;
                break;
              }
            }

            if (sourceGi != null && destGi != null) {
              int realMove = min(toMove, allEps[sourceGi].sets.length - 1);
              if (realMove > 0) {
                final srcSets = allEps[sourceGi].sets;
                final dstSets = allEps[destGi].sets;
                allEps[sourceGi] = _cloneExercise(
                  allEps[sourceGi],
                  sets: srcSets.sublist(0, srcSets.length - realMove),
                );
                final extraSets = List.generate(realMove, (_) => srcSets.last);
                allEps[destGi] = _cloneExercise(
                  allEps[destGi],
                  sets: [...dstSets, ...extraSets],
                );
                sessionLoads[overloadedDay] =
                    sessionLoads[overloadedDay]! - realMove;
                sessionLoads[receiverDay] =
                    sessionLoads[receiverDay]! + realMove;
                excess -= realMove;
                debugPrint(
                  '[V3][P0] ⚖️ Levelled $muscle: Moved $realMove sets from session $overloadedDay to $receiverDay',
                );
              }
            }
            if (excess <= 0) break;
          }
        }
      }
    }

    // ── Step 7: Reconstruct sessions and enforce daily cap ──
    final finalSessions = <TrainingSession>[];

    // Group EPs back into sessions
    final sessionEpMap = <int, List<PlannedExercise>>{};
    for (int gi = 0; gi < allEps.length; gi++) {
      final si = epSessionIndices[gi];
      sessionEpMap.putIfAbsent(si, () => []);
      sessionEpMap[si]!.add(allEps[gi]);
    }

    for (int si = 0; si < newSessions.length; si++) {
      var updatedExercises = sessionEpMap[si] ?? <PlannedExercise>[];

      // Daily Cap enforcement by muscleKey (P0-A-adapted from P0-MVO-5)
      final muscleSets = <String, int>{};
      for (final ep in updatedExercises) {
        muscleSets[ep.muscleKey] =
            (muscleSets[ep.muscleKey] ?? 0) + ep.sets.length;
      }

      muscleSets.forEach((m, total) {
        if (total > maxSetsPerMusclePerSession) {
          final before = total;
          int excess = total - maxSetsPerMusclePerSession;

          // Reduce from last exercise matching this muscle (remove trailing sets), min 1
          for (int i = updatedExercises.length - 1; i >= 0; i--) {
            if (excess <= 0) break;
            final ep = updatedExercises[i];
            if (ep.muscleKey == m && ep.sets.length > 1) {
              final allowedReduction = ep.sets.length - 1;
              final toCut = min(excess, allowedReduction);
              if (toCut > 0) {
                updatedExercises[i] = _cloneExercise(
                  ep,
                  sets: ep.sets.sublist(0, ep.sets.length - toCut),
                );
                excess -= toCut;
              }
            }
          }

          debugPrint(
            '[V3][P0][CAP] day=${newSessions[si].dayNumber} muscle=$m cap=$maxSetsPerMusclePerSession before=$before after=${total - excess}',
          );
        }
      });

      finalSessions.add(newSessions[si].copyWith(exercises: updatedExercises));
    }

    // ── Step 8: Final validation log (P0 — log only, no throw) ──
    _rebalanceToTargetWithoutNewExercises(
      sessions: finalSessions,
      targetWeeklySetsByMuscle: targetWeeklySetsByMuscle,
      maxSetsPerMusclePerSession: maxSetsPerMusclePerSession,
    );

    // ── Step 9: Final validation log (P0 — log only, no throw) ──
    final finalAssigned = <String, int>{};
    for (final s in finalSessions) {
      for (final ep in s.exercises) {
        finalAssigned[ep.muscleKey] =
            (finalAssigned[ep.muscleKey] ?? 0) + ep.sets.length;
      }
    }
    for (final m in targetWeeklySetsByMuscle.keys) {
      final t = targetWeeklySetsByMuscle[m] ?? 0;
      final a = finalAssigned[m] ?? 0;
      if (t > 0 && a != t) {
        debugPrint(
          '[V3][P0][ERR] coverage mismatch muscle=$m target=$t assigned=$a',
        );
      }
    }

    return finalSessions;
  }

  static void _rebalanceToTargetWithoutNewExercises({
    required List<TrainingSession> sessions,
    required Map<String, int> targetWeeklySetsByMuscle,
    required int maxSetsPerMusclePerSession,
  }) {
    int assignedForMuscle(String muscle) {
      var total = 0;
      for (final session in sessions) {
        for (final exercise in session.exercises) {
          if (exercise.muscleKey == muscle) {
            total += exercise.sets.length;
          }
        }
      }
      return total;
    }

    for (final entry in targetWeeklySetsByMuscle.entries) {
      final muscle = entry.key;
      final target = entry.value;
      if (target <= 0) continue;

      final assignedBefore = assignedForMuscle(muscle);
      var delta = target - assignedBefore;
      if (delta < 0) {
        var toRemove = -delta;
        for (
          var sessionIndex = sessions.length - 1;
          sessionIndex >= 0;
          sessionIndex--
        ) {
          if (toRemove <= 0) break;
          final session = sessions[sessionIndex];
          final updatedExercises = List<PlannedExercise>.from(
            session.exercises,
          );

          for (
            var exerciseIndex = updatedExercises.length - 1;
            exerciseIndex >= 0;
            exerciseIndex--
          ) {
            if (toRemove <= 0) break;
            final exercise = updatedExercises[exerciseIndex];
            if (exercise.muscleKey != muscle || exercise.sets.length <= 1) {
              continue;
            }

            final removable = exercise.sets.length - 1;
            final cut = min(removable, toRemove);
            if (cut <= 0) continue;

            updatedExercises[exerciseIndex] = _cloneExercise(
              exercise,
              sets: exercise.sets.sublist(0, exercise.sets.length - cut),
            );
            toRemove -= cut;
          }

          sessions[sessionIndex] = session.copyWith(
            exercises: updatedExercises,
          );
        }

        final assignedFinal = assignedForMuscle(muscle);
        debugPrint(
          '[RebalanceCapAware] muscle=$muscle target=$target assignedFinal=$assignedFinal deltaApplied=${assignedFinal - assignedBefore}',
        );
        continue;
      }

      if (delta == 0) {
        debugPrint(
          '[RebalanceCapAware] muscle=$muscle target=$target assignedFinal=$assignedBefore deltaApplied=0',
        );
        continue;
      }

      final sessionIndexesWithMuscle = <int>[];
      for (
        var sessionIndex = 0;
        sessionIndex < sessions.length;
        sessionIndex++
      ) {
        if (sessions[sessionIndex].exercises.any(
          (ep) => ep.muscleKey == muscle,
        )) {
          sessionIndexesWithMuscle.add(sessionIndex);
        }
      }

      if (sessionIndexesWithMuscle.isEmpty) {
        debugPrint(
          '[RebalanceCapAware][WARN] '
          'UNSATISFIABLE_DAILY_CAP muscle=$muscle delta=$delta sessions=0 '
          '-> keeping assigned=$assignedBefore target=$target',
        );
        continue;
      }

      for (final sessionIndex in sessionIndexesWithMuscle) {
        if (delta <= 0) break;

        final session = sessions[sessionIndex];
        int? targetExerciseIndex;
        var currentForMuscleInSession = 0;

        for (
          var exerciseIndex = 0;
          exerciseIndex < session.exercises.length;
          exerciseIndex++
        ) {
          final exercise = session.exercises[exerciseIndex];
          if (exercise.muscleKey != muscle) continue;
          targetExerciseIndex ??= exerciseIndex;
          currentForMuscleInSession += exercise.sets.length;
        }

        if (targetExerciseIndex == null) continue;

        final availableSpace =
            maxSetsPerMusclePerSession - currentForMuscleInSession;
        if (availableSpace <= 0) continue;

        final setsToAdd = min(delta, availableSpace);
        if (setsToAdd <= 0) continue;

        final targetExercise = session.exercises[targetExerciseIndex];
        final templateSet = targetExercise.sets.isNotEmpty
            ? targetExercise.sets.last
            : const SetPrescription(repsMin: 8, repsMax: 12, rir: 2);
        final additionalSets = List<SetPrescription>.generate(
          setsToAdd,
          (_) => templateSet,
        );

        final updatedExercises = List<PlannedExercise>.from(session.exercises);
        updatedExercises[targetExerciseIndex] = _cloneExercise(
          targetExercise,
          sets: [...targetExercise.sets, ...additionalSets],
        );
        sessions[sessionIndex] = session.copyWith(exercises: updatedExercises);

        delta -= setsToAdd;
      }

      final assignedFinal = assignedForMuscle(muscle);
      final deltaApplied = assignedFinal - assignedBefore;

      if (delta > 0) {
        final maxByDailyCap =
            sessionIndexesWithMuscle.length * maxSetsPerMusclePerSession;
        debugPrint(
          '[RebalanceCapAware][WARN] '
          'UNSATISFIABLE_DAILY_CAP muscle=$muscle '
          'target=$target assignedFinal=$assignedFinal '
          'unassignedDelta=$delta sessions=${sessionIndexesWithMuscle.length} '
          'maxByDailyCap=$maxByDailyCap',
        );
      }

      debugPrint(
        '[RebalanceCapAware] muscle=$muscle target=$target assignedFinal=$assignedFinal deltaApplied=$deltaApplied',
      );
    }
  }

  static TrainingSplit _resolveSplit({
    required String? splitId,
    required int availableDays,
  }) {
    final s = (splitId ?? '').toLowerCase().trim();
    if (s == 'ul_ul' || s == 'upper_lower' || s == 'upperlower') {
      return TrainingSplit.upperLower;
    }
    if (s == 'fullbody' || s == 'full_body' || s == 'fb' || s == 'fullbody_3') {
      return TrainingSplit.fullBody;
    }
    if (s == 'ppl' || s == 'push_pull_legs' || s == 'pushpulllegs') {
      return TrainingSplit.pushPullLegs;
    }
    if (availableDays == 5) return TrainingSplit.pushPullLegs;
    if (availableDays >= 6) return TrainingSplit.pushPullLegs;
    if (availableDays == 4) return TrainingSplit.upperLower;
    return TrainingSplit.fullBody;
  }

  @Deprecated(
    'Legacy session builder path. Use _buildRealTrainingPlan -> CycleTemplateBuilder.buildBaseWeek as canonical Motor V3 runtime path.',
  )
  @pragma('vm:entry-point')
  // ignore: unused_element
  static List<TrainingSession> _buildSessions(
    SplitConfig split,
    Map<String, int> volumeByMuscle,
    UserProfile profile,
    String phase,
    Map<String, Map<String, dynamic>> exerciseCatalog,
  ) {
    final sessions = <TrainingSession>[];

    for (
      int dayIndex = 0;
      dayIndex < split.muscleDistribution.length;
      dayIndex++
    ) {
      final musclesForDay = split.muscleDistribution[dayIndex];

      final setsPerMuscle = <String, int>{};
      for (final muscle in musclesForDay) {
        final weeklyVol = volumeByMuscle[muscle] ?? 0;
        final freq = split.muscleDistribution
            .where((d) => d.contains(muscle))
            .length;
        final sets = (weeklyVol / max(freq, 1)).ceil();
        if (sets > 10) {
          debugPrint(
            '[V3][P0][FEASIBILITY_FAIL] muscle=$muscle weeklyVol=$weeklyVol freq=$freq setsPerSession=$sets',
          );
        }
        setsPerMuscle[muscle] = sets;
        debugPrint(
          '[V3][P0][SESSION_DISTRIB] day=${dayIndex + 1} muscle=$muscle weeklyVol=$weeklyVol freq=$freq setsPerSession=$sets',
        );
      }

      final selectedIds = <String>[];
      final exToMuscle = <String, String>{};
      for (final muscle in musclesForDay) {
        final count = setsPerMuscle[muscle]! >= 8 ? 2 : 1;
        final ids = ExerciseSelectionEngine.selectExercises(
          targetMuscle: muscle,
          availableExercises: exerciseCatalog,
          availableEquipment: profile.availableEquipment,
          injuryHistory: profile.injuryHistory,
          targetExerciseCount: count,
        );
        for (final id in ids) {
          selectedIds.add(id);
          exToMuscle[id] = muscle;
        }
      }

      final exTypes = {
        for (final id in selectedIds)
          id: exerciseCatalog[id]?['type'] as String? ?? 'compound',
      };

      final lockedExercises = MesocycleExercisePool.lockExercises(
        '${profile.id}:legacy_day_${dayIndex + 1}',
        ExerciseCatalogV3.getExercisesByIds(selectedIds),
      );
      final session = SessionStructureEngine.build(lockedExercises);
      final placementByExercise = session.placementByExerciseId();
      final ordered = session
          .flattenExercises()
          .map((exercise) => exercise.id)
          .where(exTypes.containsKey)
          .toList();
      if (ordered.isEmpty) {
        ordered.addAll(
          OrderingEngine.orderExercises(
            exercises: selectedIds,
            exerciseData: exerciseCatalog,
          ),
        );
      }

      final orderedIdsByMuscle = <String, List<String>>{};
      for (final id in ordered) {
        final muscle = exToMuscle[id];
        if (muscle == null) continue;
        orderedIdsByMuscle.putIfAbsent(muscle, () => <String>[]).add(id);
      }

      final allocatedSetsByExercise = <String, int>{};
      for (final muscle in musclesForDay) {
        final muscleExercises = orderedIdsByMuscle[muscle] ?? const <String>[];
        final blockLabels = muscleExercises
            .map((id) => placementByExercise[id]?.blockLabel)
            .toList();
        final allocation = ExerciseSetAllocator.allocateSets(
          setsPerMuscle[muscle] ?? 0,
          muscleExercises.length,
          blockLabelsByIndex: blockLabels,
        );
        for (var index = 0; index < muscleExercises.length; index++) {
          allocatedSetsByExercise[muscleExercises[index]] =
              allocation['ex$index'] ?? 0;
        }
      }

      final intensities = IntensityEngine.distributeIntensities(
        exercises: ordered,
        exerciseTypes: exTypes,
        dayIndex: dayIndex,
      );

      final planned = <PlannedExercise>[];
      for (int i = 0; i < ordered.length; i++) {
        final id = ordered[i];
        final rawZone = intensities[id] ?? IntensityZone.medium;
        final zone = _normalizeIntensityZoneKey(rawZone);
        final exType = exTypes[id] ?? 'compound';
        final muscle = exToMuscle[id]!;
        final sets = max(1, allocatedSetsByExercise[id] ?? 0);
        final placement = placementByExercise[id];
        final repRange = IntensityEngine.getRepRangeForIntensity(zone);
        final rir = EffortEngine.assignRir(
          exerciseId: id,
          intensity: zone,
          exerciseType: exType,
          phase: phase,
        );

        planned.add(
          PlannedExercise(
            exerciseId: id,
            name: exerciseCatalog[id]?['name'] as String? ?? id,
            muscleKey: muscle,
            primaryMuscle: placement?.isMainLift == true
                ? muscle
                : (placement != null ? muscle : muscle),
            secondaryMuscles: const <String>[],
            slotLabel: placement?.slotLabel,
            blockLabel: placement?.blockLabel,
            pairGroupId: placement?.pairGroupId,
            isMainLift: placement?.isMainLift ?? false,
            sets: List.generate(
              sets,
              (_) => SetPrescription(
                repsMin: repRange.first,
                repsMax: repRange.last,
                rir: rir,
              ),
            ),
          ),
        );
      }

      final totalSetsDay = planned.fold<int>(0, (s, e) => s + e.sets.length);
      sessions.add(
        TrainingSession(
          id: 'session_day${dayIndex + 1}',
          dayNumber: dayIndex + 1,
          name: _sessionName(split.type, split.daysPerWeek, dayIndex),
          primaryMuscles: musclesForDay,
          estimatedDurationMinutes: ((planned.length * 8) + (totalSetsDay * 2))
              .clamp(30, 120),
          exercises: planned,
        ),
      );
    }

    return sessions;
  }

  static String _sessionName(String splitType, int daysPerWeek, int i) {
    if (splitType == 'upper_lower') {
      return ['Upper A', 'Lower A', 'Upper B', 'Lower B'][i % 4];
    }
    if (splitType == 'full_body') return 'Full Body ${i + 1}';
    if (splitType == 'push_pull_legs') {
      if (daysPerWeek >= 6) {
        return ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs'][i % 6];
      }
      if (daysPerWeek == 5) {
        return ['Push', 'Pull', 'Legs A', 'Torso', 'Legs B'][i % 5];
      }
      return ['Push', 'Pull', 'Legs'][i % 3];
    }
    return 'Día ${i + 1}';
  }

  static String _splitToString(TrainingSplit split) {
    return switch (split) {
      TrainingSplit.upperLower => 'upperLower',
      TrainingSplit.fullBody => 'fullBody',
      TrainingSplit.pushPullLegs => 'pushPullLegs',
    };
  }

  static SplitConfig _splitToConfig(TrainingSplit split, int daysPerWeek) {
    switch (split) {
      case TrainingSplit.upperLower:
        return SplitConfig.upperLower4x();
      case TrainingSplit.pushPullLegs:
        if (daysPerWeek == 5) {
          return SplitConfig.pushPullLegs5x();
        }
        return daysPerWeek >= 6
            ? SplitConfig.pushPullLegs6x()
            : SplitConfig.pushPullLegs3x();
      case TrainingSplit.fullBody:
        if (daysPerWeek >= 5) return SplitConfig.fullBody5x();
        if (daysPerWeek == 4) return SplitConfig.fullBody4x();
        return SplitConfig.fullBody3x();
    }
  }

  static CoverageResult _validateExerciseCoverage({
    required Map<String, int> targetVolume,
    required Map<int, List<PlannedExercise>> weekStructure,
    required bool feasibilityPassed,
  }) {
    final Map<String, int> assignedTotals = {};
    final Map<int, Map<String, int>> muscleSetsByDay = {};

    for (final entry in weekStructure.entries) {
      final dayNumber = entry.key;
      final dayExercises = entry.value;
      final dayTotals = <String, int>{};

      for (final plannedExercise in dayExercises) {
        final setsCount = plannedExercise.sets.length;
        assignedTotals[plannedExercise.muscleKey] =
            (assignedTotals[plannedExercise.muscleKey] ?? 0) + setsCount;
        dayTotals[plannedExercise.muscleKey] =
            (dayTotals[plannedExercise.muscleKey] ?? 0) + setsCount;
      }

      muscleSetsByDay[dayNumber] = dayTotals;
    }

    debugPrint('[Coverage] assignedTotals reales por músculo: $assignedTotals');

    final List<String> errors = [];

    targetVolume.forEach((muscle, targetSets) {
      if (targetSets <= 0) return;
      final actual = assignedTotals[muscle] ?? 0;
      if (actual != targetSets) {
        errors.add('Muscle "$muscle": target=$targetSets, assigned=$actual');
      }
    });

    if (errors.isNotEmpty) {
      debugPrint('[V3][P0.2][COVERAGE_FAIL] ${errors.join(' | ')}');
    }

    return CoverageResult(isValid: errors.isEmpty, errors: errors);
  }

  static String? _resolveBackFocus(dynamic client) {
    if (client == null) return null;
    try {
      final dynamic training = (client as dynamic).training;
      final dynamic extra = training?.extra;
      if (extra is Map && extra['backFocus'] is String) {
        final raw = (extra['backFocus'] as String).trim().toLowerCase();
        if (raw == 'lats' || raw == 'upper_back') {
          return raw;
        }
      }
    } catch (_) {}
    return null;
  }

  static Map<String, int> expandBackMuscle(
    Map<String, int> targetSetsByMuscle, {
    required String backFocus,
  }) {
    final expanded = Map<String, int>.from(targetSetsByMuscle);
    final totalBackSets = expanded['back'] ?? 0;
    final existingLats = expanded['lats'] ?? 0;
    final existingUpperBack = expanded['upper_back'] ?? 0;
    final existingTotal = existingLats + existingUpperBack;

    if (totalBackSets <= 0) {
      expanded.remove('back');
      return expanded;
    }

    final focus = (backFocus == 'lats' || backFocus == 'upper_back')
        ? backFocus
        : 'upper_back';
    final consolidatedBackSets = max(totalBackSets, existingTotal);
    final a = (consolidatedBackSets * 0.5).ceil();
    final b = consolidatedBackSets - a;

    final latsSets = focus == 'lats' ? a : b;
    final upperBackSets = consolidatedBackSets - latsSets;

    expanded.remove('back');
    expanded['lats'] = latsSets;
    expanded['upper_back'] = upperBackSets;

    debugPrint(
      '[BackFocus] backInput=$totalBackSets existingBack=$existingTotal consolidatedBack=$consolidatedBackSets latsSets=$latsSets upperBackSets=$upperBackSets focus=$focus',
    );

    return expanded;
  }

  static TrainingProgram _buildProgramFromPlanConfig({
    required TrainingPlanConfig planConfig,
    required TrainingSplit split,
    required int daysPerWeek,
    required int durationWeeks,
    required UserProfile userProfile,
    required Map<String, int> volumeTargets,
  }) {
    final weeks = planConfig.weeks.whereType<TrainingWeek>().toList();
    final sessions = weeks.isNotEmpty
        ? weeks.first.sessions.whereType<TrainingSession>().toList()
        : const <TrainingSession>[];

    return TrainingProgram(
      id: 'program_${planConfig.id}',
      userId: userProfile.id,
      name: 'Motor V3 ${planConfig.split ?? _splitToString(split)}',
      split: _splitToConfig(split, daysPerWeek),
      phase: planConfig.phase ?? 'accumulation',
      durationWeeks: durationWeeks,
      sessions: sessions,
      weeklyVolumeByMuscle: volumeTargets.map(
        (k, v) => MapEntry(k, v.toDouble()),
      ),
      startDate: planConfig.startDate,
      estimatedEndDate: planConfig.startDate.add(
        Duration(days: durationWeeks * 7),
      ),
      createdAt: planConfig.createdAt,
    );
  }

  static Map<String, dynamic> calculateProgramQuality({
    required TrainingProgram program,
    required UserProfile profile,
  }) {
    final volumeScore = VolumeValidator.calculateVolumeQualityScore(
      volumeByMuscle: program.weeklyVolumeByMuscle.map(
        (k, v) => MapEntry(k, v.toInt()),
      ),
      trainingLevel: profile.trainingLevel,
    );
    final overallScore = ConfigurationValidator.calculateOverallQualityScore(
      split: program.split,
      phase: program.phase,
      durationWeeks: program.durationWeeks,
      totalExercises: program.sessions.length,
      volumeScore: volumeScore,
      intensityScore: 1.0,
      effortScore: 1.0,
    );
    return {
      'overall_score': overallScore,
      'volume_score': volumeScore,
      'intensity_score': 1.0,
      'effort_score': 1.0,
      'quality_level': _getQualityLevel(overallScore),
    };
  }

  static String _getQualityLevel(double score) {
    if (score >= 0.9) return 'Excelente';
    if (score >= 0.75) return 'Bueno';
    if (score >= 0.6) return 'Aceptable';
    if (score >= 0.4) return 'Subóptimo';
    return 'Deficiente';
  }

  static Map<String, int> _normalizePriorities(UserProfile profile) {
    final normalized = <String, int>{};
    profile.musclePriorities.forEach((muscle, priority) {
      final key = muscle_registry.normalize(muscle);
      if (key != null) {
        normalized[key] = max(normalized[key] ?? 0, priority);
      }
    });
    return normalized;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // P0.1-MVO-2: Global feasibility check (pre-build)
  // ─────────────────────────────────────────────────────────────────────────

  static const int _defaultDailyCapPerMuscle = 10;

  static const Set<String> _upperMusclesForFeasibility = {
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'biceps',
    'triceps',
    'abs',
  };

  static const Set<String> _lowerMusclesForFeasibility = {
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'delts_front',
    'delts_lateral',
    'delts_rear',
  };

  static Map<String, int> _computeAssignedDirectVolume(
    List<TrainingSession> sessions,
  ) {
    final Map<String, int> out = {};
    for (final s in sessions) {
      for (final ep in s.exercises) {
        final m = ep.muscleKey;
        out[m] = (out[m] ?? 0) + ep.sets.length;
      }
    }
    return out;
  }

  static bool _hasSundayCheckForMuscle({
    required TrainingPlanConfig? planConfig,
    required String muscleKey,
  }) {
    if (planConfig == null) {
      debugPrint(
        '[V3][P1C][WARN] no planConfig available for sunday check; default=false',
      );
      return false;
    }

    final Map<String, dynamic> meta = planConfig.extra;
    final dynamic raw = meta['weeklySundayCheck'];

    if (raw is Map) {
      final v = raw[muscleKey];
      if (v is bool) return v;
    }
    return false;
  }

  static int _softCeilingFromLandmarks(VolumeLandmarks lm) {
    return (lm.vmr * _overreachMaxFactor).round();
  }

  static phase_engine.TrainingPhase _mapCyclePhaseToProgression(
    CyclePhase phase,
  ) {
    switch (phase) {
      case CyclePhase.adaptation:
        return phase_engine.TrainingPhase.adaptation;
      case CyclePhase.accumulation:
        return phase_engine.TrainingPhase.accumulation;
      case CyclePhase.maintenance:
        return phase_engine.TrainingPhase.maintenance;
      case CyclePhase.deload:
      case CyclePhase.microDeload:
        return phase_engine.TrainingPhase.regeneration;
    }
  }

  static TrainingPhase _resolveTrainingPhase(String phase) {
    switch (phase.trim().toLowerCase()) {
      case 'intensification':
        return TrainingPhase.intensification;
      case 'deload':
      case 'micro_deload':
      case 'microdeload':
        return TrainingPhase.deload;
      case 'accumulation':
      default:
        return TrainingPhase.accumulation;
    }
  }

  static TrainingPlanConfig? _resolvePreviousPlanConfig(
    dynamic client, {
    required DateTime asOfDate,
  }) {
    try {
      final dynamic trainingPlansRaw = client?.trainingPlans;
      final dynamic training = client?.training;
      final dynamic extraRaw = training?.extra;

      if (trainingPlansRaw is List && trainingPlansRaw.isNotEmpty) {
        final plans = trainingPlansRaw.cast<dynamic>();
        final activePlanId = extraRaw is Map
            ? extraRaw[_activePlanIdKey]?.toString().trim()
            : null;

        dynamic selected;
        if (activePlanId != null && activePlanId.isNotEmpty) {
          for (final plan in plans) {
            if (plan?.id?.toString() == activePlanId) {
              selected = plan;
              break;
            }
          }
        }

        selected ??= _selectMostRecentPlan(plans);

        if (selected != null) {
          final selectedExtra = _extractPlanExtra(selected);
          if (extraRaw is Map && extraRaw['weeklyFatigue'] is Map) {
            selectedExtra['weeklyFatigue'] = Map<String, dynamic>.from(
              extraRaw['weeklyFatigue'] as Map,
            );
          }
          final startDate = _parseDateTime(selected?.startDate) ?? asOfDate;
          final createdAt =
              _parseDateTime(selected?.createdAt) ??
              _parseDateTime(selected?.updatedAt) ??
              startDate;

          final selectedClientId = selected?.clientId?.toString();
          final clientId =
              (selectedClientId != null && selectedClientId.isNotEmpty)
              ? selectedClientId
              : client?.id?.toString() ?? 'client_unknown';

          final phase =
              selected?.phase?.toString() ??
              selectedExtra['phase']?.toString() ??
              selectedExtra['cyclePhase']?.toString();

          final split =
              selected?.split?.toString() ??
              selected?.splitId?.toString() ??
              selectedExtra['split']?.toString() ??
              selectedExtra['splitId']?.toString();

          final volumePerMuscle = _extractVolumePerMuscle(selected);

          return TrainingPlanConfig(
            id: selected?.id?.toString() ?? 'cycle_state_$clientId',
            clientId: clientId,
            startDate: startDate,
            weeks: const [],
            createdAt: createdAt,
            extra: selectedExtra,
            phase: phase,
            split: split,
            volumePerMuscle: volumePerMuscle,
          );
        }
      }

      if (extraRaw is! Map) return null;

      final extra = Map<String, dynamic>.from(extraRaw);
      final hasCycleState =
          extra.containsKey('cycleWeek') ||
          extra.containsKey('cyclePhase') ||
          extra.containsKey('phase') ||
          extra.containsKey('weeksInPhase');

      if (!hasCycleState) return null;

      final clientId = client?.id?.toString() ?? 'client_unknown';
      return TrainingPlanConfig(
        id: 'cycle_state_$clientId',
        clientId: clientId,
        startDate: asOfDate,
        weeks: const [],
        createdAt: asOfDate,
        extra: extra,
        phase: extra['phase']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static dynamic _selectMostRecentPlan(List<dynamic> plans) {
    dynamic selected;
    var bestEpoch = -1;

    for (final plan in plans) {
      final dt = _parseDateTime(plan?.startDate);
      final epoch = dt?.millisecondsSinceEpoch ?? -1;
      if (selected == null || epoch > bestEpoch) {
        selected = plan;
        bestEpoch = epoch;
      }
    }

    return selected;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static Map<String, dynamic> _extractPlanExtra(dynamic plan) {
    if (plan == null) return <String, dynamic>{};

    final dynamic extraRaw = plan.extra;
    if (extraRaw is Map) {
      return Map<String, dynamic>.from(extraRaw);
    }

    final dynamic stateRaw = plan.state;
    if (stateRaw is Map) {
      return Map<String, dynamic>.from(stateRaw);
    }

    return <String, dynamic>{};
  }

  static Map<String, int>? _extractVolumePerMuscle(dynamic plan) {
    final dynamic raw = plan?.volumePerMuscle;
    if (raw is Map) {
      final out = <String, int>{};
      raw.forEach((key, value) {
        if (value is num) {
          out[key.toString()] = value.toInt();
        }
      });
      return out.isEmpty ? null : out;
    }
    return null;
  }

  static Map<String, List<String>> _resolveMesocycleExercisePoolByMuscle(
    dynamic client,
  ) {
    if (client == null) return const {};

    final activeCycleId = client.activeCycleId?.toString().trim();
    final trainingCycles = client.trainingCycles;
    if (trainingCycles is! List) return const {};

    dynamic activeCycle;
    if (activeCycleId != null && activeCycleId.isNotEmpty) {
      for (final cycle in trainingCycles) {
        if (cycle?.cycleId == activeCycleId) {
          activeCycle = cycle;
          break;
        }
      }
    }

    activeCycle ??= trainingCycles.cast<dynamic>().firstWhere(
      (cycle) => cycle?.status == 'active',
      orElse: () => null,
    );

    final raw = activeCycle?.baseExercisesByMuscle;
    if (raw is! Map) return const {};

    return raw.map(
      (k, v) => MapEntry(
        _canonicalMuscleKey(k.toString()),
        (v as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(),
      ),
    );
  }

  static String _canonicalMuscleKey(String raw) {
    final normalized = muscle_registry.normalize(raw);
    if (normalized != null) return normalized;

    final expanded = muscle_registry.expandGroup(raw);
    if (expanded.isNotEmpty) {
      if (expanded.contains('upper_back')) return 'upper_back';
      return expanded.first;
    }

    return raw.trim().toLowerCase();
  }

  static Map<String, double> _resolveIntensitySplit(
    Map<String, double>? provided, {
    dynamic client,
  }) {
    final raw = <String, dynamic>{};
    if (provided != null && provided.isNotEmpty) {
      raw.addAll(provided);
    } else if (client != null && client.training?.extra is Map) {
      final fromExtra =
          (client.training.extra['seriesTypePercentSplit'] as Map?)
              ?.cast<String, dynamic>();
      if (fromExtra != null) {
        raw.addAll(fromExtra);
      }
    }

    final heavy =
        (raw['heavy'] as num?)?.toDouble() ??
        _defaultIntensityProfilePercentSplit['heavy']!;
    final medium =
        (raw['medium'] as num?)?.toDouble() ??
        // Backward compatibility en borde de entrada: mapear legacy moderate -> medium.
        (raw['moderate'] as num?)?.toDouble() ??
        _defaultIntensityProfilePercentSplit['medium']!;
    final light =
        (raw['light'] as num?)?.toDouble() ??
        _defaultIntensityProfilePercentSplit['light']!;

    final total = heavy + medium + light;
    if (total <= 0) return _defaultIntensityProfilePercentSplit;

    return {
      'heavy': (heavy * 100.0) / total,
      'medium': (medium * 100.0) / total,
      'light': (light * 100.0) / total,
    };
  }

  static String _normalizeIntensityZoneKey(String zone) {
    if (zone == 'moderate') {
      return IntensityZone.medium;
    }
    return zone;
  }

  static Map<String, int> _enforcePriorityCapsBeforeMaterialization({
    required Map<String, int> targetWeeklyVolume,
    required Map<String, VolumeLandmarks> landmarksByMuscle,
    required Map<String, int> prioritiesByMuscle,
    required bool allowPrimaryOverVmr,
  }) {
    final capped = <String, int>{};

    for (final entry in targetWeeklyVolume.entries) {
      final muscle = normalizeMuscleKey(entry.key);
      final requested = max(0, entry.value);
      final landmarks = landmarksByMuscle[muscle];

      if (landmarks == null) {
        capped[muscle] = requested;
        continue;
      }

      final priority = prioritiesByMuscle[muscle] ?? 3;
      final isPrimary = priority >= 5;
      final isSecondary = priority >= 3 && priority < 5;
      final isTertiary = priority < 3;

      int hardCap;
      String capLabel;
      if (isPrimary) {
        final primaryCap = allowPrimaryOverVmr
            ? (landmarks.vmr * _overreachMaxFactor).round()
            : landmarks.vmr;
        hardCap = max(1, primaryCap);
        capLabel = allowPrimaryOverVmr ? 'VMR_SOFT' : 'VMR';
      } else if (isSecondary) {
        hardCap = max(1, (landmarks.vmr * 0.75).floor());
        capLabel = '0.75_VMR';
      } else if (isTertiary) {
        hardCap = max(1, landmarks.vop);
        capLabel = 'VOP';
      } else {
        hardCap = max(1, landmarks.vop);
        capLabel = 'VOP';
      }

      final finalTarget = min(requested, hardCap);
      capped[muscle] = finalTarget;

      if (requested > finalTarget) {
        debugPrint(
          '[V3][CAP_ENFORCE_EARLY] muscle=$muscle priority=$priority requested=$requested cap=$hardCap capType=$capLabel final=$finalTarget',
        );
      }
    }

    return capped;
  }

  static Map<String, int> _resolveVolumeTargets(
    UserProfile userProfile,
    Map<String, Landmarks>? muscleLandmarks,
  ) {
    if (muscleLandmarks == null || muscleLandmarks.isEmpty) {
      return _calculateVolumeByMuscleV2(userProfile);
    }

    final resolved = <String, int>{};
    for (final entry in muscleLandmarks.entries) {
      final key = normalizeMuscleKey(entry.key);
      final vop = entry.value.vop;
      if (vop > 0) {
        resolved[key] = vop;
      }
    }

    if (resolved.isNotEmpty) {
      return resolved;
    }

    return _calculateVolumeByMuscleV2(userProfile);
  }

  static Map<String, bool> _readPendingLocalDeload(
    TrainingPlanConfig? planConfig,
  ) {
    final Map<String, dynamic> meta = planConfig?.extra ?? <String, dynamic>{};
    final raw = meta['pendingLocalDeload'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v == true));
    }
    return {};
  }

  static TrainingPlanConfig? _writePendingLocalDeload(
    TrainingPlanConfig? planConfig,
    Map<String, bool> map,
  ) {
    if (planConfig == null) return null;
    final updatedExtra = Map<String, dynamic>.from(planConfig.extra);
    updatedExtra['pendingLocalDeload'] = Map<String, bool>.from(map);

    return TrainingPlanConfig(
      id: planConfig.id,
      clientId: planConfig.clientId,
      startDate: planConfig.startDate,
      weeks: planConfig.weeks,
      createdAt: planConfig.createdAt,
      extra: updatedExtra,
      volumePerMuscle: planConfig.volumePerMuscle,
      phase: planConfig.phase,
      split: planConfig.split,
    );
  }

  static bool _shouldTriggerLocalDeload({
    required String muscleKey,
    required TrainingPlanConfig? planConfig,
  }) {
    final Map<String, dynamic> meta = planConfig?.extra ?? <String, dynamic>{};
    final raw = meta['weeklyFatigue'];

    // esperado formato:
    // {
    //   "chest": 4,
    //   "lats": 2,
    // }

    if (raw is Map) {
      final val = raw[muscleKey];
      if (val is int && val >= _fatigueThreshold) {
        return true;
      }
    }
    return false;
  }

  static _CycleState _readCycleState(
    TrainingPlanConfig? planConfig, {
    UserProfile? profile,
  }) {
    final Map<String, dynamic> meta = planConfig?.extra ?? <String, dynamic>{};

    int cycleWeek = 1;
    if (meta.containsKey('cycleWeek')) {
      cycleWeek = meta['cycleWeek'] as int;
    } else if (profile != null) {
      cycleWeek = (profile.consecutiveWeeks % 6) + 1;
    }

    final String phaseStr =
        (meta['cyclePhase'] as String?) ??
        (meta['phase'] as String?) ??
        'adaptation';
    final int weeksInPhase = (meta['weeksInPhase'] as int?) ?? 1;
    final int weeksSinceLastMicro = (meta['weeksSinceLastMicro'] as int?) ?? 1;

    CyclePhase phase;
    switch (phaseStr) {
      case 'accumulation':
        phase = CyclePhase.accumulation;
        break;
      case 'microDeload':
        phase = CyclePhase.microDeload;
        break;
      case 'maintenance':
        phase = CyclePhase.maintenance;
        break;
      case 'deload':
        phase = CyclePhase.deload;
        break;
      case 'adaptation':
      default:
        phase = CyclePhase.adaptation;
    }

    return _CycleState(
      cycleWeek: cycleWeek,
      phase: phase,
      weeksInPhase: weeksInPhase,
      weeksSinceLastMicro: weeksSinceLastMicro,
      maintenanceWeeksPlanned:
          (meta['maintenanceWeeksPlanned'] as int?) ?? _maintenanceWeeksDefault,
      deloadWeeksPlanned:
          (meta['deloadWeeksPlanned'] as int?) ?? _deloadWeeksDefault,
      adaptationWeeksPlanned:
          (meta['adaptationWeeksPlanned'] as int?) ?? _adaptationWeeksDefault,
    );
  }

  static TrainingPlanConfig _writeCycleState(
    TrainingPlanConfig planConfig,
    _CycleState s,
  ) {
    debugPrint(
      '[V3][P1A][STATE_WRITE] week=${s.cycleWeek} phase=${s.phase.name} '
      'wPhase=${s.weeksInPhase} wMicro=${s.weeksSinceLastMicro}',
    );
    final updatedExtra = Map<String, dynamic>.from(planConfig.extra);
    updatedExtra['cycleWeek'] = s.cycleWeek;
    updatedExtra['cyclePhase'] = s.phase.name;
    updatedExtra['weeksInPhase'] = s.weeksInPhase;
    updatedExtra['weeksSinceLastMicro'] = s.weeksSinceLastMicro;
    updatedExtra['maintenanceWeeksPlanned'] = s.maintenanceWeeksPlanned;
    updatedExtra['deloadWeeksPlanned'] = s.deloadWeeksPlanned;
    updatedExtra['adaptationWeeksPlanned'] = s.adaptationWeeksPlanned;
    updatedExtra['phase'] = s.phase.name;

    return TrainingPlanConfig(
      id: planConfig.id,
      clientId: planConfig.clientId,
      startDate: planConfig.startDate,
      weeks: planConfig.weeks,
      createdAt: planConfig.createdAt,
      extra: updatedExtra,
      volumePerMuscle: planConfig.volumePerMuscle,
      phase: s.phase.name,
      split: planConfig.split,
    );
  }

  static _CycleState _advanceCycleStateNoLog(_CycleState s) {
    final nextCycleWeek = s.cycleWeek + 1;

    if (s.phase == CyclePhase.adaptation) {
      if (s.weeksInPhase >= s.adaptationWeeksPlanned) {
        return s.copyWith(
          cycleWeek: nextCycleWeek,
          phase: CyclePhase.accumulation,
          weeksInPhase: 1,
          weeksSinceLastMicro: 1,
        );
      }
      return s.copyWith(
        cycleWeek: nextCycleWeek,
        weeksInPhase: s.weeksInPhase + 1,
        weeksSinceLastMicro: s.weeksSinceLastMicro + 1,
      );
    }

    if (s.phase == CyclePhase.microDeload) {
      return s.copyWith(
        cycleWeek: nextCycleWeek,
        phase: CyclePhase.accumulation,
        weeksInPhase: 1,
        weeksSinceLastMicro: 1,
      );
    }

    if (s.phase == CyclePhase.maintenance) {
      if (s.weeksInPhase >= s.maintenanceWeeksPlanned) {
        return s.copyWith(
          cycleWeek: nextCycleWeek,
          phase: CyclePhase.deload,
          weeksInPhase: 1,
          weeksSinceLastMicro: s.weeksSinceLastMicro + 1,
        );
      }
      return s.copyWith(
        cycleWeek: nextCycleWeek,
        weeksInPhase: s.weeksInPhase + 1,
        weeksSinceLastMicro: s.weeksSinceLastMicro + 1,
      );
    }

    if (s.phase == CyclePhase.deload) {
      if (s.weeksInPhase >= s.deloadWeeksPlanned) {
        return s.copyWith(
          cycleWeek: 1,
          phase: CyclePhase.adaptation,
          weeksInPhase: 1,
          weeksSinceLastMicro: 1,
        );
      }
      return s.copyWith(
        cycleWeek: nextCycleWeek,
        weeksInPhase: s.weeksInPhase + 1,
        weeksSinceLastMicro: s.weeksSinceLastMicro + 1,
      );
    }

    if (s.phase == CyclePhase.accumulation) {
      final int w = s.weeksSinceLastMicro + 1;
      if (w >= _microDeloadWindowMin && w <= _microDeloadWindowMax) {
        if (w == _microDeloadDefaultAt) {
          return s.copyWith(
            cycleWeek: nextCycleWeek,
            phase: CyclePhase.microDeload,
            weeksInPhase: 1,
            weeksSinceLastMicro: w,
          );
        }
      }
      return s.copyWith(
        cycleWeek: nextCycleWeek,
        weeksInPhase: s.weeksInPhase + 1,
        weeksSinceLastMicro: w,
      );
    }

    return s.copyWith(
      cycleWeek: nextCycleWeek,
      weeksInPhase: s.weeksInPhase + 1,
      weeksSinceLastMicro: s.weeksSinceLastMicro + 1,
    );
  }

  static Map<String, int> _deriveFrequencyByMuscle({
    required Map<String, int> targetVolume,
    required TrainingSplit split,
    required int daysPerWeek,
  }) {
    final freqByMuscle = <String, int>{};

    targetVolume.forEach((muscle, sets) {
      if (sets <= 0) return;

      final baseFrequency = VolumeToFrequencyRule.frequencyForWeeklyVolume(
        sets,
      );
      final resolution = FrequencyFeasibilityResolver.resolveFeasibleFrequency(
        muscle: muscle,
        targetSets: sets,
        baseFrequency: baseFrequency,
        maxFrequency: daysPerWeek,
        dailyCap: _defaultDailyCapPerMuscle,
        effectiveFrequencyForCandidate: (candidateFrequency) =>
            _effectiveFrequencyForSplit(
              muscle: muscle,
              baseFrequency: candidateFrequency,
              split: split,
              daysPerWeek: daysPerWeek,
            ),
        errorContext: 'motor_v3_orchestrator',
      );

      debugPrint(resolution.toLogLine(tag: 'V3][P0.2][FREQ_TRACE'));

      freqByMuscle[muscle] = resolution.effectiveFrequency;
    });

    return freqByMuscle;
  }

  static List<String> _feasibilityErrors({
    required Map<String, int> targetVolume,
    required int daysPerWeek,
    required TrainingSplit split,
    int dailyCapPerMuscle = _defaultDailyCapPerMuscle,
  }) {
    final errors = <String>[];

    targetVolume.forEach((muscle, targetSets) {
      if (targetSets <= 0) return;

      final baseFrequency = VolumeToFrequencyRule.frequencyForWeeklyVolume(
        targetSets,
      );
      final resolution = FrequencyFeasibilityResolver.resolveFeasibleFrequency(
        muscle: muscle,
        targetSets: targetSets,
        baseFrequency: baseFrequency,
        maxFrequency: daysPerWeek,
        dailyCap: dailyCapPerMuscle,
        effectiveFrequencyForCandidate: (candidateFrequency) =>
            _effectiveFrequencyForSplit(
              muscle: muscle,
              baseFrequency: candidateFrequency,
              split: split,
              daysPerWeek: daysPerWeek,
            ),
        errorContext:
            'motor_v3_orchestrator split=${split.name} days=$daysPerWeek',
      );

      debugPrint(resolution.toLogLine(tag: 'V3][P0.2][FREQ_TRACE'));

      if (!resolution.isFeasible) {
        errors.add(
          resolution.blockingError ??
              '[V3][P0.2][INFEASIBLE] muscle="$muscle" target=$targetSets unresolved_frequency',
        );
      }
    });

    return errors;
  }

  static _VolumeNormalizationOutcome _normalizeVolumeMapForFeasibility({
    required Map<String, int> targetVolume,
    required int daysPerWeek,
    required TrainingSplit split,
    int dailyCapPerMuscle = _defaultDailyCapPerMuscle,
  }) {
    final normalized = <String, int>{};
    final results = <VolumeFeasibilityNormalizationResult>[];

    for (final entry in targetVolume.entries) {
      final muscle = normalizeMuscleKey(entry.key);
      final originalTarget = entry.value;

      if (originalTarget <= 0) {
        normalized[muscle] = 0;
        continue;
      }

      final baseFrequency = VolumeToFrequencyRule.frequencyForWeeklyVolume(
        originalTarget,
      );
      final effectiveFrequency = _effectiveFrequencyForSplit(
        muscle: muscle,
        baseFrequency: baseFrequency,
        split: split,
        daysPerWeek: daysPerWeek,
      );
      final maxAssignable = effectiveFrequency * dailyCapPerMuscle;

      final result = VolumeFeasibilityNormalizer.normalizeTargetVolume(
        muscle: muscle,
        targetSets: originalTarget,
        baseFrequency: baseFrequency,
        effectiveFrequency: effectiveFrequency,
        dailyCap: dailyCapPerMuscle,
        maxAssignable: maxAssignable,
        splitId: split.name,
        daysPerWeek: daysPerWeek,
      );

      normalized[muscle] = result.normalizedTargetSets;
      results.add(result);
      debugPrint(result.toLogLine());
    }

    return _VolumeNormalizationOutcome(
      normalizedTargets: normalized,
      results: results,
    );
  }

  static int _effectiveFrequencyForSplit({
    required String muscle,
    required int baseFrequency,
    required TrainingSplit split,
    required int daysPerWeek,
  }) {
    final normalized = muscle_registry.normalize(muscle) ?? muscle;
    final boundedByDays = min(baseFrequency, max(daysPerWeek, 1));

    switch (split) {
      case TrainingSplit.upperLower:
        final upperDays = (daysPerWeek / 2).ceil();
        final lowerDays = daysPerWeek ~/ 2;

        if (_upperMusclesForFeasibility.contains(normalized)) {
          return min(boundedByDays, max(upperDays, 1));
        }
        if (_lowerMusclesForFeasibility.contains(normalized)) {
          return min(boundedByDays, max(lowerDays, 1));
        }
        return boundedByDays;
      case TrainingSplit.fullBody:
      case TrainingSplit.pushPullLegs:
        return boundedByDays;
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// P1-E: Intensificación Automática en Maintenance
  /// ─────────────────────────────────────────────────────────────────────────
  static void _applyMaintenanceIntensificationAndRir({
    required List<TrainingSession> sessions,
    required TrainingPlanConfig? planConfig,
    required Map<String, int> musclePriorities,
  }) {
    // 1) [P0-A] RIR adjustment skipped — PlannedExercise uses SetPrescription with fixed rir
    // Sets are frozen inside PlannedExercise — intensity is determined by repsMin/repsMax/rir.

    // 2) Obtener estado de deloads para evitar intensificar músculos fatigados
    final pendingMap = _readPendingLocalDeload(planConfig);

    // 3) Aplicar intensificación día por día
    for (int dayIdx = 0; dayIdx < sessions.length; dayIdx++) {
      final session = sessions[dayIdx];

      // Agrupar los ejercicios por muscleKey en esta sesión
      final muscleEps = <String, List<int>>{};
      for (int i = 0; i < session.exercises.length; i++) {
        final m = session.exercises[i].muscleKey;
        muscleEps.putIfAbsent(m, () => []).add(i);
      }

      for (final entry in muscleEps.entries) {
        final muscle = entry.key;
        final epIndices = entry.value;

        // P1-E Regla: Skip si la prioridad es menos importante que P2 (prioridad >= P3 = <3 numérico en nuestro index mapping invertido)
        // Ojo: prioridades numéricas (1=Primary, 2=Secondary, 3=Tertiary).
        // "priority < P3" implica priority 1 o 2 (Primary/Secondary)
        final priority = musclePriorities[muscle] ?? 3;
        if (priority > 2) continue;

        // P1-E Regla: Skip si hay un local deload de la semana pasada
        if (pendingMap[muscle] == true) continue;

        // Contar volumen (sets) de este músculo en ESTE DÍA
        int totalSetsToday = 0;
        int uniqueExercisesToday = epIndices.length;
        for (final idx in epIndices) {
          totalSetsToday += session.exercises[idx].sets.length;
        }

        // P1-E Regla: Min Sets
        if (totalSetsToday < _minSetsForIntensification) continue;

        // Limite de ejercicios a intensificar hoy
        int exercisesToIntensify =
            (uniqueExercisesToday * _intensificationExerciseRatio).ceil();

        int intensifiedCount = 0;

        for (final idx in epIndices) {
          if (intensifiedCount >= exercisesToIntensify) break;

          // [P0-A] PlannedExercise: Intensification is managed via IntensificationRule,
          // not via a plain string technique. Only mark if exercise has no intensification yet.
          final ep = session.exercises[idx];
          final firstSetRepsMin = ep.sets.isNotEmpty
              ? ep.sets.first.repsMin
              : 12;
          final isHeavyOrMedium = firstSetRepsMin <= 12;
          if (isHeavyOrMedium && ep.intensification == null) {
            final ex = ExerciseCatalogV3.getById(ep.exerciseId);
            if (ex != null) {
              final isCompoundLike =
                  ex.name.toLowerCase().contains('press') ||
                  ex.name.toLowerCase().contains('squat') ||
                  ex.name.toLowerCase().contains('deadlift') ||
                  ex.name.toLowerCase().contains('row') ||
                  ex.difficulty.toLowerCase().contains('compound');

              final techniqueType = isCompoundLike
                  ? IntensificationType.restPause
                  : IntensificationType.myoReps;

              // ignore: unused_local_variable
              final rule = IntensificationRule(type: techniqueType);
              // NOTE: Not applying rule yet per P0-A requirement (no intensification activation)
            }

            intensifiedCount++;
          }
        }
      }
    }
  }

  static String _resolveBusinessPhaseLabel(_CycleState state) {
    switch (state.phase) {
      case CyclePhase.adaptation:
        return 'AA';
      case CyclePhase.accumulation:
        if (state.weeksInPhase <= 1) return 'HF1';
        if (state.weeksInPhase == 2) return 'HF2';
        return 'HF3';
      case CyclePhase.maintenance:
        return state.weeksInPhase < 3
            ? 'maintenance_early'
            : 'maintenance_late';
      case CyclePhase.microDeload:
      case CyclePhase.deload:
        return 'regeneration';
    }
  }

  static double _businessPhaseVolumeFactor(String businessPhaseLabel) {
    switch (businessPhaseLabel) {
      case 'AA':
        return 0.85;
      case 'HF1':
        return 1.0;
      case 'HF2':
        return 1.05;
      case 'HF3':
        return 1.10;
      case 'maintenance_early':
        return 1.0;
      case 'maintenance_late':
        return 1.0;
      case 'regeneration':
        return 0.5;
      default:
        return 1.0;
    }
  }

  static bool _businessPhaseAllowsZoneIntensification(
    String businessPhaseLabel,
  ) {
    return businessPhaseLabel == 'HF2' ||
        businessPhaseLabel == 'HF3' ||
        businessPhaseLabel == 'maintenance_late';
  }

  static List<TrainingSession> _applyZoneIntensificationContract({
    required List<TrainingSession> sessions,
    required String businessPhaseLabel,
    required bool allowZoneIntensification,
  }) {
    final updatedSessions = <TrainingSession>[];

    for (final session in sessions) {
      final updatedExercises = <PlannedExercise>[];
      for (final exercise in session.exercises) {
        if (ExerciseCatalogV3.getById(exercise.exerciseId) == null) {
          updatedExercises.add(exercise);
          continue;
        }

        if (!allowZoneIntensification) {
          updatedExercises.add(exercise.copyWith(clearIntensification: true));
          continue;
        }

        final loadCategory = ExerciseCatalogV3.getLoadCategory(
          exercise.exerciseId,
        );
        final movementPattern = ExerciseCatalogV3.getMovementPattern(
          exercise.exerciseId,
        );
        final requirement = IntensificationEligibility.requirementForExercise(
          businessPhaseLabel: businessPhaseLabel,
          exerciseId: exercise.exerciseId,
          loadCategory: loadCategory,
          movementPattern: movementPattern,
          blockLabel: exercise.blockLabel,
        );
        if (requirement == IntensificationRequirement.exempt) {
          updatedExercises.add(exercise.copyWith(clearIntensification: true));
          continue;
        }

        final rule = _intensificationRuleForZone(loadCategory);
        if (rule == null) {
          updatedExercises.add(exercise.copyWith(clearIntensification: true));
          continue;
        }

        updatedExercises.add(exercise.copyWith(intensification: rule));
      }

      updatedSessions.add(session.copyWith(exercises: updatedExercises));
    }

    debugPrint(
      '[V3][ZONE_INTENSIFICATION] businessPhase=$businessPhaseLabel allow=$allowZoneIntensification sessions=${updatedSessions.length}',
    );

    return updatedSessions;
  }

  static IntensificationRule? _intensificationRuleForZone(String zone) {
    switch (zone.trim().toLowerCase()) {
      case 'heavy':
        return IntensificationRule(
          type: IntensificationType.dropSet,
          applyToLastSetOnly: true,
          applyToLastTwoSets: false,
          parameters: {
            'drop_percentages': [0.25, 0.25],
            'to_failure': true,
            'reps_range': {'min': 6, 'max': 8},
          },
        );
      case 'medium':
        return IntensificationRule(
          type: IntensificationType.restPause,
          applyToLastSetOnly: false,
          applyToLastTwoSets: false,
          parameters: {
            'rest_seconds_min': 20,
            'rest_seconds_max': 30,
            'target_reps': 12,
            'reps_range': {'min': 8, 'max': 12},
          },
        );
      case 'light':
        return IntensificationRule(
          type: IntensificationType.isometricHold,
          applyToLastSetOnly: false,
          applyToLastTwoSets: true,
          parameters: {
            'hold_seconds_min': 15,
            'hold_seconds_max': 30,
            'reps_range': {'min': 15, 'max': 20},
          },
        );
      default:
        return null;
    }
  }

  static Map<String, dynamic> _splitContractMetadata(
    TrainingSplit split,
    int daysPerWeek,
  ) {
    switch (split) {
      case TrainingSplit.fullBody:
        return {
          'official_split': 'fullBody',
          'daysPerWeek': daysPerWeek,
          'day_order': ['torso_dominant', 'leg_dominant', 'mixed_posterior'],
        };
      case TrainingSplit.upperLower:
        return {
          'official_split': 'upperLower',
          'daysPerWeek': daysPerWeek,
          'day_order': ['torso_a', 'legs_a', 'torso_b', 'legs_b'],
        };
      case TrainingSplit.pushPullLegs:
        if (daysPerWeek >= 6) {
          return {
            'official_split': 'pushPullLegs6x',
            'daysPerWeek': daysPerWeek,
            'day_order': ['push', 'pull', 'legs', 'push', 'pull', 'legs'],
          };
        }
        if (daysPerWeek == 5) {
          return {
            'official_split': 'pushPullLegs5x',
            'daysPerWeek': daysPerWeek,
            'day_order': ['push', 'pull', 'legs_a', 'torso', 'legs_b'],
          };
        }
        return {
          'official_split': 'pushPullLegs3x',
          'daysPerWeek': daysPerWeek,
          'day_order': ['push', 'pull', 'legs'],
        };
    }
  }
}

// TrainingSplit moved to lib/domain/training_v3/models/training_split.dart
// to avoid circular import with cycle_template_builder.dart.

class _MotorLogger {
  void info(String message) => debugPrint(message);
  void warn(String message) => debugPrint('⚠️ $message');
}

class _VolumeNormalizationOutcome {
  final Map<String, int> normalizedTargets;
  final List<VolumeFeasibilityNormalizationResult> results;

  const _VolumeNormalizationOutcome({
    required this.normalizedTargets,
    required this.results,
  });

  int get adjustedCount => results.where((r) => r.wasAdjusted).length;
}

/// Extension para capitalizar strings
extension StringExtension on String {
  /// Capitaliza la primera letra del string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Capacidad de recuperación del atleta
enum RecoveryCapacity {
  /// Déficit >500 kcal, sueño <6h, estrés alto
  low,

  /// Mantenimiento, sueño 6-7h, estrés intermedio
  medium,

  /// Superávit, sueño >7h, estrés bajo
  high,
}

/// Balance calórico del atleta
enum CaloricBalance {
  /// >500 kcal déficit
  highDeficit,

  /// 200-500 kcal déficit
  mediumDeficit,

  /// ±200 kcal
  maintenance,

  /// >200 kcal superávit
  surplus,
}

class CoverageResult {
  final bool isValid;
  final List<String> errors;

  CoverageResult({required this.isValid, required this.errors});
}

enum CyclePhase { adaptation, accumulation, microDeload, maintenance, deload }

class _CycleState {
  final int cycleWeek; // 1..N dentro del ciclo
  final CyclePhase phase;
  final int weeksInPhase;
  final int weeksSinceLastMicro;
  final int maintenanceWeeksPlanned; // default 2 (futuro override)
  final int deloadWeeksPlanned; // default 2
  final int adaptationWeeksPlanned; // default 2

  const _CycleState({
    required this.cycleWeek,
    required this.phase,
    required this.weeksInPhase,
    required this.weeksSinceLastMicro,
    required this.maintenanceWeeksPlanned,
    required this.deloadWeeksPlanned,
    required this.adaptationWeeksPlanned,
  });

  _CycleState copyWith({
    int? cycleWeek,
    CyclePhase? phase,
    int? weeksInPhase,
    int? weeksSinceLastMicro,
    int? maintenanceWeeksPlanned,
    int? deloadWeeksPlanned,
    int? adaptationWeeksPlanned,
  }) {
    return _CycleState(
      cycleWeek: cycleWeek ?? this.cycleWeek,
      phase: phase ?? this.phase,
      weeksInPhase: weeksInPhase ?? this.weeksInPhase,
      weeksSinceLastMicro: weeksSinceLastMicro ?? this.weeksSinceLastMicro,
      maintenanceWeeksPlanned:
          maintenanceWeeksPlanned ?? this.maintenanceWeeksPlanned,
      deloadWeeksPlanned: deloadWeeksPlanned ?? this.deloadWeeksPlanned,
      adaptationWeeksPlanned:
          adaptationWeeksPlanned ?? this.adaptationWeeksPlanned,
    );
  }
}

class _CycleStateWrapper {
  _CycleState state;
  TrainingPlanConfig? planConfig;
  _CycleStateWrapper(this.state);
}

class _WeeksBuildResult {
  final List<TrainingWeek>? weeks;
  final String? error;
  final Map<String, dynamic> extraMetadata;

  const _WeeksBuildResult._({
    this.weeks,
    this.error,
    this.extraMetadata = const <String, dynamic>{},
  });

  bool get success => weeks != null;

  factory _WeeksBuildResult.success(
    List<TrainingWeek> weeks, {
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
  }) => _WeeksBuildResult._(weeks: weeks, extraMetadata: extraMetadata);

  factory _WeeksBuildResult.failure(String error) =>
      _WeeksBuildResult._(error: error);
}

class _PlanBuildResult {
  final TrainingPlanConfig? planConfig;
  final String? error;

  const _PlanBuildResult._({this.planConfig, this.error});

  bool get success => planConfig != null;

  factory _PlanBuildResult.success(TrainingPlanConfig planConfig) =>
      _PlanBuildResult._(planConfig: planConfig);

  factory _PlanBuildResult.failure(String error) =>
      _PlanBuildResult._(error: error);
}
