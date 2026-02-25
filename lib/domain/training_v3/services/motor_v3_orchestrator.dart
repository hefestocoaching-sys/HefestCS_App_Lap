import 'dart:math';
import 'package:flutter/foundation.dart';

// Models
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/performance_metrics.dart';
import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/services/cycle_template_builder.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_landmarks_calculator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/weekly_volume_planner.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/periodization_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_selection_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/ordering_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/effort_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';

// Validators
import 'package:hcs_app_lap/domain/training_v3/validators/volume_validator.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/configuration_validator.dart';

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

  static const int _adaptationWeeksDefault = 2;
  static const int _maintenanceWeeksDefault = 2;
  static const int _deloadWeeksDefault = 2;

  static const int _microDeloadWindowMin = 4;
  static const int _microDeloadWindowMax = 6;
  static const int _microDeloadDefaultAt = 5; // si no hay bitácora

  static const double _microDeloadVolumeFactor = 0.75; // -25%
  static const double _deloadVolumeFactor = 0.65; // -35%

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
    String? splitId,
    int? trainingDaysPerWeek,
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

      // ✅ PASO 4: Calcular volumen INICIAL con nuevo sistema
      final volumeTargets = _calculateVolumeByMuscleV2(userProfile);
      debugPrint(
        '📊 Volumen INICIAL por músculo (VOP): ${volumeTargets.length} grupos',
      );

      if (exercises.isNotEmpty) {
        final seeded = exercises.whereType<Exercise>().toList();
        ExerciseCatalogV3.loadFromExercises(seeded);
      } else {
        await ExerciseCatalogV3.ensureLoaded();
      }

      // ✅ PASO 5: Resolver split efectivo (UI → Motor V3)
      final daysPerWeek = trainingDaysPerWeek ?? userProfile.availableDays;
      final resolvedSplit = _resolveSplit(
        splitId: splitId,
        availableDays: daysPerWeek,
      );
      _logger.info(
        '[Motor V3] splitId=$splitId availableDays=$daysPerWeek resolvedSplit=$resolvedSplit',
      );

      // ✅ PASO 9: Determinar fase periodización
      final weekInMesocycle = userProfile.consecutiveWeeks % 6 + 1;
      final performanceMetrics = PerformanceMetrics(
        targetId: userProfile.id,
        targetType: 'muscle',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        averageWeeklyVolume: 12.0,
        totalVolume: 12.0,
        volumeTrend: 0.0,
        averageLoad: 70.0,
        loadTrend: 0.0,
        averageRpe: 7.0,
        rpeTrend: 0.0,
        averageAdherence: 1.0,
        completedSessions: 3,
        plannedSessions: 3,
        performanceStatus: 'stable',
        recommendedAction: 'continue',
        sleepQuality: 7.0,
        energyLevel: 7.0,
        jointPain: 0,
        domsIntensity: 2,
        loadProgression: 0.0,
      );

      final trainingPhase = PeriodizationEngine.determinePhase(
        weekInMesocycle,
        performanceMetrics,
      );
      debugPrint('📅 Fase periodización: ${trainingPhase.name}');

      // ✅ PASO 10: Construir TrainingPlanConfig real
      // P0.2-MVO-2: Feasibility check BEFORE building the plan — hard-fail.
      final feasErrors = _feasibilityErrors(
        targetVolume: volumeTargets,
        daysPerWeek: daysPerWeek,
      );
      if (feasErrors.isNotEmpty) {
        for (final e in feasErrors) {
          debugPrint(e);
        }
        return {
          'success': false,
          'errors': feasErrors,
          'warnings': warnings,
          'planConfig': null,
        };
      }

      var cycleStateWrapper = _CycleStateWrapper(
        _readCycleState(null, profile: userProfile),
      );

      var planConfig = _buildRealTrainingPlan(
        client: client,
        asOfDate: DateTime.now(),
        volumeTargets: volumeTargets,
        split: resolvedSplit,
        phase: trainingPhase,
        durationWeeks: durationWeeks,
        daysPerWeek: daysPerWeek,
        userProfile: userProfile,
        clientProfile: clientProfile,
        cycleStateWrapper: cycleStateWrapper,
      );

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
        throw StateError(
          '[Motor V3] Plan inválido: no se generaron sesiones reales',
        );
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
      );

      if (!coverageResult.isValid) {
        return {
          'success': false,
          'errors': coverageResult.errors,
          'warnings': warnings,
          'planConfig': null,
        };
      }

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

    profile.musclePriorities.forEach((muscle, priority) {
      final normalized = muscle_registry.normalize(muscle);

      if (normalized == null) {
        debugPrint(
          '[Motor V3] ⚠️ Músculo desconocido: "$muscle" - será ignorado',
        );
        return; // Skip unknown muscles
      }

      // Si ya existe, tomar la prioridad más alta
      if (normalizedPriorities.containsKey(normalized)) {
        normalizedPriorities[normalized] = max(
          normalizedPriorities[normalized]!,
          priority,
        );
      } else {
        normalizedPriorities[normalized] = priority;
      }
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
  static TrainingPlanConfig _buildRealTrainingPlan({
    required dynamic client,
    required DateTime asOfDate,
    required Map<String, int> volumeTargets,
    required TrainingSplit split,
    required TrainingPhase phase,
    required int durationWeeks,
    required int daysPerWeek,
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required _CycleStateWrapper cycleStateWrapper,
  }) {
    final weeks = _buildWeeks(
      durationWeeks: durationWeeks,
      phase: phase,
      split: split,
      daysPerWeek: daysPerWeek,
      volumePerMuscle: volumeTargets,
      userProfile: userProfile,
      clientProfile: clientProfile,
      cycleStateWrapper: cycleStateWrapper,
    );

    final clientId = client != null
        ? (client as dynamic).id ?? 'client_unknown'
        : 'client_unknown';

    // ═══════════════════════════════════════════════════════════════════
    // PASO 7: Construir TrainingPlanConfig completo con propiedades tipadas
    // ═══════════════════════════════════════════════════════════════════
    return TrainingPlanConfig(
      id: 'plan_${clientId}_${asOfDate.millisecondsSinceEpoch}',
      clientId: clientId,
      startDate: asOfDate,
      weeks: weeks,
      createdAt: DateTime.now(),

      // ✅ PROPIEDADES TIPADAS (reemplazo de extra)
      volumePerMuscle: volumeTargets,
      phase: phase.name,
      split: _splitToString(split),

      // Mantener extra para compatibilidad legacy (deprecado)
      extra: {
        'generated_by': 'motor_v3_scientific',
        'strategy': 'v3_orchestrator',
        'phase': phase.name,
        'split': _splitToString(split),
        'duration_weeks': durationWeeks,
        'volume_targets': volumeTargets,
        'scientific_version': '2.0.0',
        'periodization_model': 'linear_progressive',
      },
    );
  }

  static List<TrainingWeek> _buildWeeks({
    required int durationWeeks,
    required TrainingPhase phase,
    required TrainingSplit split,
    required int daysPerWeek,
    required Map<String, int> volumePerMuscle,
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required _CycleStateWrapper cycleStateWrapper,
  }) {
    final weeks = <TrainingWeek>[];

    // ✅ PASO 10.1: Build BASE WEEK (Frozen Template) using CycleTemplateBuilder
    // This selects exercises ONCE and sets up the split/frequency.
    final buildResult = CycleTemplateBuilder.buildBaseWeek(
      userProfile: userProfile,
      clientProfile: clientProfile,
      targetVolumeByMuscle: volumePerMuscle,
      availableDays: daysPerWeek,
      split: split,
    );

    if (!buildResult.success) {
      throw StateError(buildResult.error ?? 'Unknown Template Build Error');
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

    for (int weekNum = 1; weekNum <= durationWeeks; weekNum++) {
      // ✅ PASO 10.2: Calculate Target Volume for this week (Progression)
      final Map<String, int> targetWeeklyVolume = {};
      final normalizedPriorities = _normalizePriorities(userProfile);

      double volumeFactor;
      // ignore: unused_local_variable
      String phaseNameForRir;

      switch (cycleStateWrapper.state.phase) {
        case CyclePhase.adaptation:
          volumeFactor = 1.0;
          phaseNameForRir = 'adaptation';
          break;
        case CyclePhase.accumulation:
          volumeFactor = 1.0;
          phaseNameForRir = 'accumulation';
          break;
        case CyclePhase.microDeload:
          volumeFactor = _microDeloadVolumeFactor; // 0.75
          phaseNameForRir = 'deload';
          break;
        case CyclePhase.maintenance:
          volumeFactor = 1.0;
          phaseNameForRir = 'maintenance';
          break;
        case CyclePhase.deload:
          volumeFactor = _deloadVolumeFactor; // 0.65
          phaseNameForRir = 'deload';
          break;
      }

      if (weekNum == 1) {
        targetWeeklyVolume.addAll(volumePerMuscle);
      } else {
        if (cycleStateWrapper.state.phase == CyclePhase.adaptation ||
            cycleStateWrapper.state.phase == CyclePhase.maintenance) {
          // P1A-7: clonar week anterior SIN aumentar sets
          targetWeeklyVolume.addAll(volumePerMuscle);
        } else {
          // Simple linear progression: +X sets/week ?
          // Or re-use WeeklyVolumePlanner?
          // WeeklyVolumePlanner calculates based on MEV/MRV.
          // Let's use logic from WeeklyVolumePlanner but apply it as scaling factor.

          // P0 Requirement: "Recalcular sets por músculo para esa semana (según VolumeEngine / progression existente)"
          // We will call VolumePlanner to get the 'target' number.
          final allLandmarks = VolumeLandmarksCalculator.calculateForAllMuscles(
            musclePriorities: normalizedPriorities,
            trainingLevel: userProfile.trainingLevel,
            age: userProfile.age,
          );

          // We assume 'volumePerMuscle' passed to _buildWeeks is the VOP/Start point.
          // Re-calc weekly volume.
          final mevByMuscle = <String, int>{};
          final mrvByMuscle = <String, int>{};
          allLandmarks.forEach((m, l) {
            mevByMuscle[m] = l.vme;
            mrvByMuscle[m] = l.vmr;
          });

          targetWeeklyVolume.addAll(
            WeeklyVolumePlanner.buildWeekVolume(
              baseVop: volumePerMuscle,
              mevByMuscle: mevByMuscle,
              mrvByMuscle: mrvByMuscle,
              priorities: normalizedPriorities,
              trainingLevel: userProfile.trainingLevel,
              weekNumber: weekNum,
              phase: phase.name,
              feedback: {},
            ),
          );
        }
      }

      // ─────────────────────────────────────────────────────────────────
      // P1-D & P1-C: GATE PARA LOCAL DELOAD, HOLD / OVERREACH
      // ─────────────────────────────────────────────────────────────────
      if (cycleStateWrapper.state.phase == CyclePhase.accumulation) {
        final normalizedPriorities = _normalizePriorities(userProfile);
        final allLandmarks = VolumeLandmarksCalculator.calculateForAllMuscles(
          musclePriorities: normalizedPriorities,
          trainingLevel: userProfile.trainingLevel,
          age: userProfile.age,
        );

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

      debugPrint(
        '[V3][P1A][PHASE] week=${cycleStateWrapper.state.cycleWeek} phase=${cycleStateWrapper.state.phase.name} volFactor=$volumeFactor',
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
              'Semana $weekNum - Fase: ${phase.name.capitalize()} - Volumen: $totalSets sets',
        ),
      );

      if (weekNum < durationWeeks) {
        cycleStateWrapper.state = _advanceCycleStateNoLog(
          cycleStateWrapper.state,
        );
      }
    }

    return weeks;
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
    if (availableDays >= 6) return TrainingSplit.pushPullLegs;
    if (availableDays == 4) return TrainingSplit.upperLower;
    return TrainingSplit.fullBody;
  }

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
        setsPerMuscle[muscle] = (weeklyVol / max(freq, 1)).ceil().clamp(2, 10);
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

      final ordered = OrderingEngine.orderExercises(
        exercises: selectedIds,
        exerciseData: exerciseCatalog,
      );
      final intensities = IntensityEngine.distributeIntensities(
        exercises: ordered,
        exerciseTypes: exTypes,
        dayIndex: dayIndex,
      );

      final planned = <PlannedExercise>[];
      for (int i = 0; i < ordered.length; i++) {
        final id = ordered[i];
        final zone = intensities[id] ?? IntensityZone.medium;
        final exType = exTypes[id] ?? 'compound';
        final muscle = exToMuscle[id]!;
        final totalSets = setsPerMuscle[muscle] ?? 3;
        final exCount = ordered.where((x) => exToMuscle[x] == muscle).length;
        final sets = (totalSets / max(exCount, 1)).round().clamp(2, 6);
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
          name: _sessionName(split.type, dayIndex),
          primaryMuscles: musclesForDay,
          estimatedDurationMinutes: ((planned.length * 8) + (totalSetsDay * 2))
              .clamp(30, 120),
          exercises: planned,
        ),
      );
    }

    return sessions;
  }

  static String _sessionName(String splitType, int i) {
    if (splitType == 'upper_lower') {
      return ['Upper A', 'Lower A', 'Upper B', 'Lower B'][i % 4];
    }
    if (splitType == 'full_body') return 'Full Body ${i + 1}';
    if (splitType == 'push_pull_legs') return ['Push', 'Pull', 'Legs'][i % 3];
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
  }) {
    final Map<String, int> directVolume = {};

    for (final day in weekStructure.values) {
      for (final ex in day) {
        directVolume[ex.muscleKey] =
            (directVolume[ex.muscleKey] ?? 0) + ex.sets.length;
      }
    }

    final List<String> errors = [];

    targetVolume.forEach((muscle, targetSets) {
      if (targetSets <= 0) return;

      final actual = directVolume[muscle] ?? 0;

      if (actual != targetSets) {
        errors.add('Muscle "$muscle": target=$targetSets, assigned=$actual');
      }
    });

    // P0.2-MVO-4: Log coverage result per muscle
    if (errors.isNotEmpty) {
      debugPrint('[V3][P0.2][COVERAGE_FAIL] ${errors.join(' | ')}');
    }

    return CoverageResult(isValid: errors.isEmpty, errors: errors);
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
      debugPrint('[V3][P1C][WARN] no meta available -> overreach disabled');
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
    debugPrint(
      '[V3][P1D][WARN] TrainingPlanConfig has no meta/copyWith(meta); tracking locally during build but will not persist globally unless rewritten',
    );
    return planConfig; // fallback
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

    final String phaseStr = (meta['cyclePhase'] as String?) ?? 'adaptation';
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
      '[V3][P1A][WARN] TrainingPlanConfig has no meta/copyWith(meta); using non-persistent defaults',
    );
    debugPrint(
      '[V3][P1A][STATE_WRITE] week=${s.cycleWeek} phase=${s.phase.name} wPhase=${s.weeksInPhase} wMicro=${s.weeksSinceLastMicro}',
    );
    return planConfig; // fallback
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

  static List<String> _feasibilityErrors({
    required Map<String, int> targetVolume,
    required int daysPerWeek,
    int dailyCapPerMuscle = _defaultDailyCapPerMuscle,
  }) {
    final errors = <String>[];

    targetVolume.forEach((muscle, targetSets) {
      if (targetSets <= 0) return;

      final int freq;
      if (targetSets <= 10) {
        freq = 1;
      } else if (targetSets <= 20) {
        freq = 2;
      } else {
        freq = 3;
      }

      final maxAssignable = freq * dailyCapPerMuscle;

      if (targetSets > maxAssignable) {
        errors.add(
          '[V3][P0.2][INFEASIBLE] muscle="$muscle" target=$targetSets '
          'exceeds maxAssignable=$maxAssignable (freq=$freq, dailyCap=$dailyCapPerMuscle, days=$daysPerWeek).',
        );
      }
    });

    return errors;
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
}

// TrainingSplit moved to lib/domain/training_v3/models/training_split.dart
// to avoid circular import with cycle_template_builder.dart.

class _MotorLogger {
  void info(String message) => debugPrint(message);
  void warn(String message) => debugPrint('⚠️ $message');
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

  /// Mantenimiento, sueño 6-7h, estrés moderado
  moderate,

  /// Superávit, sueño >7h, estrés bajo
  high,
}

/// Balance calórico del atleta
enum CaloricBalance {
  /// >500 kcal déficit
  highDeficit,

  /// 200-500 kcal déficit
  moderateDeficit,

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
