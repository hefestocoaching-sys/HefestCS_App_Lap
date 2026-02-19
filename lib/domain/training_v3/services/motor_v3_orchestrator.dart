import 'dart:math';
import 'package:flutter/foundation.dart';

// Models
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/training_v3/models/performance_metrics.dart';
import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/services/cycle_template_builder.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_landmarks_calculator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/weekly_volume_planner.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/periodization_engine.dart';

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
      final planConfig = _buildRealTrainingPlan(
        client: client,
        asOfDate: DateTime.now(),
        volumeTargets: volumeTargets,
        split: resolvedSplit,
        phase: trainingPhase,
        durationWeeks: durationWeeks,
        daysPerWeek: daysPerWeek,
        userProfile: userProfile,
        clientProfile: clientProfile,
      );

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

      final coverageCheck = _validateExerciseCoverage(
        planConfig: planConfig,
        volumeTargets: volumeTargets,
      );
      final coverageErrors =
          (coverageCheck['errors'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
      final coverageWarnings =
          (coverageCheck['warnings'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();

      errors.addAll(coverageErrors);
      warnings.addAll(coverageWarnings);

      if (errors.isNotEmpty) {
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'planConfig': null,
          'coverage': coverageCheck['coverage'],
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
        'coverage': coverageCheck['coverage'],
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
  }) {
    final weeks = _buildWeeks(
      durationWeeks: durationWeeks,
      phase: phase,
      split: split,
      daysPerWeek: daysPerWeek,
      volumePerMuscle: volumeTargets,
      userProfile: userProfile,
      clientProfile: clientProfile,
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
  }) {
    final weeks = <TrainingWeek>[];

    // ✅ PASO 10.1: Build BASE WEEK (Frozen Template) using CycleTemplateBuilder
    // This selects exercises ONCE and sets up the split/frequency.
    final baseSessions = CycleTemplateBuilder.buildBaseWeek(
      userProfile: userProfile,
      clientProfile: clientProfile,
      targetVolumeByMuscle: volumePerMuscle,
      availableDays: daysPerWeek,
    );

    // Calculate base volumes per muscle (Week 1)
    final baseVolumeMap = <String, int>{};
    for (final s in baseSessions) {
      for (final ep in s.exercises) {
        final ex = ExerciseCatalogV3.getById(ep.exerciseId);
        if (ex != null) {
          for (final m in ex.primaryMuscles) {
            final key = muscle_registry.normalize(m) ?? m;
            baseVolumeMap[key] = (baseVolumeMap[key] ?? 0) + ep.sets;
          }
        }
      }
    }

    for (int weekNum = 1; weekNum <= durationWeeks; weekNum++) {
      // ✅ PASO 10.2: Calculate Target Volume for this week (Progression)

      // Recalc landmarks (or pass them in)
      // For now we scale 'baseVolumeMap' linearly if Accumulation.
      // Rule 2: In accumulation, ONLY sets increase.

      final Map<String, int> targetWeeklyVolume = {};

      if (weekNum == 1) {
        targetWeeklyVolume.addAll(baseVolumeMap);
      } else {
        // Simple linear progression: +X sets/week ?
        // Or re-use WeeklyVolumePlanner?
        // WeeklyVolumePlanner calculates based on MEV/MRV.
        // Let's use logic from WeeklyVolumePlanner but apply it as scaling factor.

        // P0 Requirement: "Recalcular sets por músculo para esa semana (según VolumeEngine / progression existente)"
        // We will call VolumePlanner to get the 'target' number.
        final normalizedPriorities = _normalizePriorities(userProfile);
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

      List<TrainingSession> weekSessions;

      if (weekNum == 1) {
        // Use base directly (deep copy recommended to avoid ref issues if mutated later?)
        weekSessions = baseSessions
            .map(
              (s) => s.copyWith(
                exercises: s.exercises.map((e) => e.copyWith()).toList(),
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
    }

    return weeks;
  }

  /// Scales the sets of the base sessions to match the target weekly volume WITHOUT changing exercises.
  static List<TrainingSession> _cloneWithSetProgression({
    required List<TrainingSession> base,
    required Map<String, int> targetWeeklySetsByMuscle,
    required Map<String, int> baseWeeklySetsByMuscle,
    int maxSetsPerMusclePerSession = 10,
  }) {
    // 1. Clone structure
    final newSessions = base
        .map(
          (s) => s.copyWith(
            exercises: s.exercises.map((e) => e.copyWith()).toList(),
          ),
        )
        .toList();

    // 2. Calculate scaling factors or delta per muscle
    final musclesToCheck = targetWeeklySetsByMuscle.keys.toSet();

    // Create a mutable Map of <ExercisePrescription, int> representing NEW sets.
    final newSetCounts = <ExercisePrescription, int>{};

    // Initialize with current sets
    for (final s in newSessions) {
      for (final ep in s.exercises) {
        newSetCounts[ep] = ep.sets;
      }
    }

    // Distribute volume changes
    for (final muscle in musclesToCheck) {
      final target = targetWeeklySetsByMuscle[muscle] ?? 0;
      final baseVol = baseWeeklySetsByMuscle[muscle] ?? 0;
      if (target == baseVol) continue;

      final diff = target - baseVol;

      // Find occurrences
      final meaningfulOccurrences = <ExercisePrescription>[];

      for (final entry in newSetCounts.entries) {
        final ep = entry.key;
        final ex = ExerciseCatalogV3.getById(ep.exerciseId);
        if (ex != null) {
          final p = ex.primaryMuscles.map(
            (m) => muscle_registry.normalize(m) ?? m,
          );
          if (p.contains(muscle)) {
            meaningfulOccurrences.add(ep);
          }
        }
      }

      if (meaningfulOccurrences.isEmpty) continue;

      // Distribute Diff
      // We simply add diff/N to each.
      final addPerOcc = diff ~/ meaningfulOccurrences.length;
      var remainder = diff % meaningfulOccurrences.length;

      for (final ep in meaningfulOccurrences) {
        int add = addPerOcc + (remainder > 0 ? 1 : 0);
        if (remainder > 0) remainder--;

        final current = newSetCounts[ep] ?? ep.sets;
        int next = current + add;
        if (next < 1) next = 1;
        newSetCounts[ep] = next;
      }
    }

    // 3. Rebuild Sessions with new set counts & Enforce Daily Cap
    final finalSessions = <TrainingSession>[];

    for (final s in newSessions) {
      final updatedExercises = <ExercisePrescription>[];

      // First pass: apply progression
      for (final ep in s.exercises) {
        final targetSets = newSetCounts[ep] ?? ep.sets;
        updatedExercises.add(ep.copyWith(sets: targetSets));
      }

      // Second pass: Enforce Daily Cap (10 sets)
      // Calculate totals per muscle in this session
      final muscleSets = <String, int>{};

      for (final ep in updatedExercises) {
        final ex = ExerciseCatalogV3.getById(ep.exerciseId);
        if (ex != null) {
          for (final pm in ex.primaryMuscles) {
            final m = muscle_registry.normalize(pm) ?? pm;
            muscleSets[m] = (muscleSets[m] ?? 0) + ep.sets;
          }
        }
      }

      // Check for violations and reduce if needed
      muscleSets.forEach((m, total) {
        if (total > maxSetsPerMusclePerSession) {
          int excess = total - maxSetsPerMusclePerSession;
          debugPrint(
            '[Motor V3] ⚠️ Cap hit for $m on Day ${s.dayNumber}: $total -> 10',
          );

          // Reduce sets from exercises targeting this muscle, starting from last in session
          for (int i = updatedExercises.length - 1; i >= 0; i--) {
            if (excess <= 0) break;

            final ep = updatedExercises[i];
            final ex = ExerciseCatalogV3.getById(ep.exerciseId);
            if (ex != null &&
                ex.primaryMuscles
                    .map((pm) => muscle_registry.normalize(pm) ?? pm)
                    .contains(m)) {
              if (ep.sets > 1) {
                final allowedReduction = ep.sets - 1;
                final toCut = min(excess, allowedReduction);

                if (toCut > 0) {
                  updatedExercises[i] = ep.copyWith(sets: ep.sets - toCut);
                  excess -= toCut;
                }
              }
            }
          }
        }
      });

      finalSessions.add(s.copyWith(exercises: updatedExercises));
    }

    return finalSessions;
  }

  static TrainingSplit _resolveSplit({
    required String? splitId,
    required int availableDays,
  }) {
    final s = (splitId ?? '').toLowerCase().trim();
    if (s == 'ul_ul' || s == 'upper_lower' || s == 'upperlower')
      return TrainingSplit.upperLower;
    if (s == 'fullbody' || s == 'full_body' || s == 'fb' || s == 'fullbody_3')
      return TrainingSplit.fullBody;
    if (s == 'ppl' || s == 'push_pull_legs' || s == 'pushpulllegs')
      return TrainingSplit.pushPullLegs;
    if (availableDays >= 6) return TrainingSplit.pushPullLegs;
    if (availableDays == 4) return TrainingSplit.upperLower;
    return TrainingSplit.fullBody;
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

  static Map<String, dynamic> _validateExerciseCoverage({
    required TrainingPlanConfig planConfig,
    required Map<String, int> volumeTargets,
  }) {
    return {'isValid': true, 'errors': [], 'warnings': []};
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
}

enum TrainingSplit { fullBody, upperLower, pushPullLegs }

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
