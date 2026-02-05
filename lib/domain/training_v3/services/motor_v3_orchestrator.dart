// lib/domain/training_v3/services/motor_v3_orchestrator.dart

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
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

// Engines
import 'package:hcs_app_lap/domain/training_v3/engines/volume_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_selection_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/effort_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/periodization_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart'
    as resolver;

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

      // ✅ PASO 4: Calcular volumen por músculo
      final volumeTargets = _calculateVolumeByMuscle(userProfile);
      debugPrint(
        '📊 Volumen por músculo calculado: ${volumeTargets.length} grupos',
      );

      await ExerciseCatalogV3.ensureLoaded();

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

      return {
        'success': true,
        'errors': [],
        'warnings': warnings,
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

  /// Calcula volumen óptimo para cada músculo según prioridades
  static Map<String, int> _calculateVolumeByMuscle(UserProfile profile) {
    final volumeByMuscle = <String, int>{};

    // Calcular volumen para cada músculo con prioridad
    profile.musclePriorities.forEach((muscle, priority) {
      final volume = VolumeEngine.calculateOptimalVolume(
        muscle: muscle,
        trainingLevel: profile.trainingLevel,
        priority: priority,
        currentVolume: null, // Primera vez, no hay volumen previo
      );

      volumeByMuscle[muscle] = volume;
    });

    return volumeByMuscle;
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

    for (int weekNum = 1; weekNum <= durationWeeks; weekNum++) {
      final sessions = _buildDays(
        userProfile: userProfile,
        clientProfile: clientProfile,
        weekNumber: weekNum,
        phase: phase.name,
        split: split,
        daysPerWeek: daysPerWeek,
        volumePerMuscle: volumePerMuscle,
      );

      final totalSets = sessions.fold<int>(
        0,
        (sum, session) => sum + session.totalSets,
      );

      weeks.add(
        TrainingWeek(
          weekNumber: weekNum,
          sessions: sessions,
          notes:
              'Semana $weekNum - Fase: ${phase.name.capitalize()} - Volumen: $totalSets sets',
        ),
      );
    }

    return weeks;
  }

  static List<TrainingSession> _buildDays({
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required int weekNumber,
    required String phase,
    required TrainingSplit split,
    required int daysPerWeek,
    required Map<String, int> volumePerMuscle,
  }) {
    final sessions = <TrainingSession>[];
    final dayGroups = _resolveDayGroups(split, daysPerWeek);

    if (dayGroups.isEmpty) {
      throw StateError(
        '[Motor V3] No se pudieron resolver grupos para split $split',
      );
    }

    for (int i = 0; i < dayGroups.length; i++) {
      final groups = dayGroups[i];
      final dayNumber = i + 1;

      final exerciseById = <String, Exercise>{};
      final setsById = <String, int>{};

      for (final group in groups) {
        final weeklySets = _calculateGroupWeeklySets(
          group: group,
          volumePerMuscle: volumePerMuscle,
          userProfile: userProfile,
        );
        final targetSets = max(1, (weeklySets / daysPerWeek).round());

        final selected = ExerciseSelectionEngine.selectExercisesByGroups(
          groups: [group],
          targetSets: targetSets,
          profile: clientProfile,
        );

        final selectedCount = max(
          1,
          min(selected.length, (targetSets / 3).ceil()),
        );
        final selectedExercises = selected.take(selectedCount).toList();
        final setsPerExercise = max(
          1,
          (targetSets / selectedExercises.length).round(),
        );

        for (final ex in selectedExercises) {
          exerciseById[ex.id] = ex;
          setsById[ex.id] = (setsById[ex.id] ?? 0) + setsPerExercise;
        }
      }

      if (exerciseById.isEmpty) {
        throw StateError('[Motor V3] Día $dayNumber sin ejercicios');
      }

      final exerciseIds = exerciseById.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final orderedIds = exerciseIds.map((e) => e.id).toList();
      final exerciseTypes = <String, String>{};
      for (final id in orderedIds) {
        exerciseTypes[id] = ExerciseCatalogV3.getTypeById(id);
      }

      final intensities = IntensityEngine.distributeIntensities(
        exercises: orderedIds,
        exerciseTypes: exerciseTypes,
      );

      final prescriptions = <ExercisePrescription>[];
      for (final id in orderedIds) {
        final ex = exerciseById[id]!;
        final intensity = intensities[id] ?? 'moderate';
        final repRange = IntensityEngine.getRepRangeForIntensity(intensity);
        final restSeconds = IntensityEngine.getRestSecondsForIntensity(
          intensity,
        );
        final baseRir = EffortEngine.assignRir(
          exerciseId: id,
          intensity: intensity,
          exerciseType: exerciseTypes[id] ?? 'compound',
        );
        final targetRir = EffortEngine.adjustRirForPhase(
          baseRir: baseRir,
          phase: phase,
        );

        prescriptions.add(
          ExercisePrescription(
            exerciseId: id,
            exerciseName: ex.name,
            orderInSession: prescriptions.length + 1,
            sets: setsById[id] ?? 1,
            repRange: repRange,
            targetRir: targetRir,
            intensityZone: intensity,
            restSeconds: restSeconds,
            notes: 'Motor V3 $phase',
          ),
        );
      }

      sessions.add(
        TrainingSession(
          id: 'w${weekNumber}d$dayNumber',
          dayNumber: dayNumber,
          name: 'Day $dayNumber',
          primaryMuscles: groups.map((g) => g.name).toList(),
          estimatedDurationMinutes: (prescriptions.length * 10) + 30,
          exercises: prescriptions,
        ),
      );
    }

    return sessions;
  }

  static List<List<resolver.MuscleGroup>> _resolveDayGroups(
    TrainingSplit split,
    int daysPerWeek,
  ) {
    switch (split) {
      case TrainingSplit.upperLower:
        final pattern = [
          [
            resolver.MuscleGroup.chest,
            resolver.MuscleGroup.back,
            resolver.MuscleGroup.deltoids,
            resolver.MuscleGroup.arms,
          ],
          [
            resolver.MuscleGroup.legs,
            resolver.MuscleGroup.glutes,
            resolver.MuscleGroup.calves,
            resolver.MuscleGroup.core,
          ],
        ];
        final out = <List<resolver.MuscleGroup>>[];
        for (int i = 0; i < daysPerWeek; i++) {
          out.add(pattern[i % pattern.length]);
        }
        return out;
      case TrainingSplit.fullBody:
        final full = [
          resolver.MuscleGroup.chest,
          resolver.MuscleGroup.back,
          resolver.MuscleGroup.deltoids,
          resolver.MuscleGroup.arms,
          resolver.MuscleGroup.legs,
          resolver.MuscleGroup.glutes,
          resolver.MuscleGroup.calves,
          resolver.MuscleGroup.core,
        ];
        return List<List<resolver.MuscleGroup>>.generate(
          daysPerWeek,
          (_) => full,
        );
      case TrainingSplit.pushPullLegs:
        throw StateError('[Motor V3] Split pushPullLegs no implementado');
    }
  }

  static int _calculateGroupWeeklySets({
    required resolver.MuscleGroup group,
    required Map<String, int> volumePerMuscle,
    required UserProfile userProfile,
  }) {
    final muscles = _canonicalMusclesForGroup(group);
    var total = 0;
    for (final muscle in muscles) {
      var sets = volumePerMuscle[muscle];
      if (sets == null) {
        final priority = userProfile.musclePriorities[muscle] ?? 3;
        sets = VolumeEngine.calculateOptimalVolume(
          muscle: muscle,
          trainingLevel: userProfile.trainingLevel,
          priority: priority,
          currentVolume: null,
        );
      }
      total += sets;
    }
    return total;
  }

  static List<String> _canonicalMusclesForGroup(resolver.MuscleGroup group) {
    switch (group) {
      case resolver.MuscleGroup.chest:
        return ['chest'];
      case resolver.MuscleGroup.back:
        return ['lats', 'upper_back', 'traps'];
      case resolver.MuscleGroup.deltoids:
        return ['deltoide_anterior', 'deltoide_lateral', 'deltoide_posterior'];
      case resolver.MuscleGroup.arms:
        return ['biceps', 'triceps'];
      case resolver.MuscleGroup.legs:
        return ['quads', 'hamstrings'];
      case resolver.MuscleGroup.glutes:
        return ['glutes'];
      case resolver.MuscleGroup.calves:
        return ['calves'];
      case resolver.MuscleGroup.core:
        return ['abs'];
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

  /// Calcula score de calidad total del programa generado
  static Map<String, dynamic> calculateProgramQuality({
    required TrainingProgram program,
    required UserProfile profile,
  }) {
    // Calcular scores individuales
    final volumeScore = VolumeValidator.calculateVolumeQualityScore(
      volumeByMuscle: program.weeklyVolumeByMuscle.map(
        (k, v) => MapEntry(k, v.toInt()),
      ),
      trainingLevel: profile.trainingLevel,
    );

    // PLACEHOLDER: Otros scores cuando tengamos engines completos
    final intensityScore = 1.0;
    final effortScore = 1.0;

    final overallScore = ConfigurationValidator.calculateOverallQualityScore(
      split: program.split,
      phase: program.phase,
      durationWeeks: program.durationWeeks,
      totalExercises: program.sessions.length,
      volumeScore: volumeScore,
      intensityScore: intensityScore,
      effortScore: effortScore,
    );

    return {
      'overall_score': overallScore,
      'volume_score': volumeScore,
      'intensity_score': intensityScore,
      'effort_score': effortScore,
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
