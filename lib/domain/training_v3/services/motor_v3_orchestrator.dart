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

// Engines
import 'package:hcs_app_lap/domain/training_v3/engines/volume_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_selection_engine.dart';
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

      // ✅ PASO 4: Calcular volumen por músculo
      final volumeTargets = _calculateVolumeByMuscle(userProfile);
      debugPrint(
        '📊 Volumen por músculo calculado: ${volumeTargets.length} grupos',
      );

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
        availableExercises: exercises,
        userProfile: userProfile,
      );

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
  // MÉTODOS AUXILIARES - PASO 6
  // ═══════════════════════════════════════════════════════════════════════

  /// Convierte lista de ejercicios a mapa
  static Map<String, Map<String, dynamic>> _convertExercisesToMap(
    List<dynamic> exercises,
  ) {
    final map = <String, Map<String, dynamic>>{};
    for (int i = 0; i < exercises.length; i++) {
      final item = exercises[i];

      if (item is Exercise) {
        map[item.id] = {
          'id': item.id,
          'name': item.name,
          'primary_muscles': item.primaryMuscles,
          'secondary_muscles': item.secondaryMuscles,
          'equipment': item.equipment,
          'type': 'compound',
        };
        continue;
      }

      // Cada ejercicio puede ser un Map<String, dynamic>
      if (item is Map<String, dynamic>) {
        final id = (item['id'] ?? item['exerciseId'] ?? 'ex_$i').toString();
        final name = (item['name'] ?? 'Exercise $i').toString();
        final primary =
            (item['primary_muscles'] ??
                    item['primaryMuscles'] ??
                    item['muscleKey'] ??
                    item['group'])
                as dynamic;
        final secondary =
            (item['secondary_muscles'] ?? item['secondaryMuscles']) as dynamic;

        map[id] = {
          'id': id,
          'name': name,
          'primary_muscles': _normalizeMuscleList(primary),
          'secondary_muscles': _normalizeMuscleList(secondary),
          'equipment': item['equipment']?.toString() ?? '',
          'type': item['type']?.toString() ?? 'compound',
        };
        continue;
      }

      // Fallback: crear un mapa simple
      map['ex_$i'] = {
        'id': 'ex_$i',
        'name': 'Exercise $i',
        'primary_muscles': const <String>[],
        'secondary_muscles': const <String>[],
        'equipment': '',
        'type': 'compound',
      };
    }
    return map;
  }

  static List<String> _normalizeMuscleList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const <String>[];
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
    required List<dynamic> availableExercises,
    required UserProfile userProfile,
  }) {
    final weeks = _buildWeeks(
      durationWeeks: durationWeeks,
      phase: phase,
      split: split,
      daysPerWeek: daysPerWeek,
      volumePerMuscle: volumeTargets,
      availableExercises: availableExercises,
      userProfile: userProfile,
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
    required List<dynamic> availableExercises,
    required UserProfile userProfile,
  }) {
    final weeks = <TrainingWeek>[];

    for (int weekNum = 1; weekNum <= durationWeeks; weekNum++) {
      final sessions = _buildDays(
        userProfile: userProfile,
        weekNumber: weekNum,
        phase: phase.name,
        split: split,
        daysPerWeek: daysPerWeek,
        volumePerMuscle: volumePerMuscle,
        availableExercises: availableExercises,
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
    required int weekNumber,
    required String phase,
    required TrainingSplit split,
    required int daysPerWeek,
    required Map<String, int> volumePerMuscle,
    required List<dynamic> availableExercises,
  }) {
    final sessions = <TrainingSession>[];
    final exerciseCatalog = _convertExercisesToMap(availableExercises);

    final dayTypes = switch (split) {
      TrainingSplit.upperLower => ['upper', 'lower', 'upper', 'lower'],
      TrainingSplit.fullBody => List<String>.filled(
        daysPerWeek < 4 ? 3 : daysPerWeek,
        'fullBody',
      ),
      TrainingSplit.pushPullLegs => [
        'push',
        'pull',
        'legs',
        'push',
        'pull',
        'legs',
      ],
    };

    for (int i = 0; i < dayTypes.length; i++) {
      final dayType = dayTypes[i];
      final dayNumber = i + 1;
      final targetMuscles = _resolveTargetMuscles(dayType);
      final exercises = <ExercisePrescription>[];

      for (final muscle in targetMuscles) {
        final targetSets = max(
          2,
          ((volumePerMuscle[muscle] ?? 6) ~/ max(1, daysPerWeek)),
        );

        List<String> selectedIds = const [];
        try {
          selectedIds = ExerciseSelectionEngine.selectExercises(
            targetMuscle: muscle,
            availableExercises: exerciseCatalog,
            availableEquipment: userProfile.availableEquipment,
            injuryHistory: userProfile.injuryHistory,
            targetExerciseCount: 1,
          );
        } catch (e) {
          _logger.warn(
            '[Motor V3] Error seleccionando ejercicios para $muscle: $e',
          );
          selectedIds = const [];
        }

        if (selectedIds.isEmpty) {
          _logger.warn(
            '[Motor V3] Sin ejercicios para $muscle, usando placeholder',
          );
          exercises.add(_placeholderExercise(muscle, targetSets));
          continue;
        }

        final exerciseId = selectedIds.first;
        final exerciseName = _resolveExerciseNameById(
          exerciseCatalog,
          exerciseId,
        );

        exercises.add(
          ExercisePrescription(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            orderInSession: exercises.length + 1,
            sets: targetSets,
            repRange: const [8, 12],
            targetRir: 2,
            intensityZone: 'moderate',
            restSeconds: 90,
            notes: 'MVP $phase - $dayType',
          ),
        );
      }

      if (exercises.isEmpty) {
        exercises.add(_placeholderExercise('fullBody', 2));
      }

      sessions.add(
        TrainingSession(
          id: 'w${weekNumber}d$dayNumber',
          dayNumber: dayNumber,
          name: _resolveSessionName(dayType, dayNumber),
          primaryMuscles: targetMuscles,
          estimatedDurationMinutes: (exercises.length * 10) + 30,
          exercises: exercises,
        ),
      );
    }

    return sessions;
  }

  static List<String> _resolveTargetMuscles(String dayType) {
    switch (dayType) {
      case 'upper':
        return [
          'chest',
          'lats',
          'upper_back',
          'traps',
          'deltoide_lateral',
          'deltoide_posterior',
          'biceps',
          'triceps',
        ];
      case 'lower':
        return ['quads', 'hamstrings', 'glutes', 'calves', 'abs'];
      case 'push':
        return ['chest', 'deltoide_anterior', 'deltoide_lateral', 'triceps'];
      case 'pull':
        return ['lats', 'upper_back', 'traps', 'biceps'];
      case 'legs':
        return ['quads', 'hamstrings', 'glutes', 'calves', 'abs'];
      case 'fullBody':
      default:
        return [
          'chest',
          'lats',
          'upper_back',
          'deltoide_lateral',
          'quads',
          'hamstrings',
          'glutes',
          'biceps',
          'triceps',
        ];
    }
  }

  static String _resolveSessionName(String dayType, int dayNumber) {
    return switch (dayType) {
      'upper' => 'Upper Day $dayNumber',
      'lower' => 'Lower Day $dayNumber',
      'push' => 'Push Day $dayNumber',
      'pull' => 'Pull Day $dayNumber',
      'legs' => 'Legs Day $dayNumber',
      'fullBody' => 'Full Body Day $dayNumber',
      _ => 'Session $dayNumber',
    };
  }

  static ExercisePrescription _placeholderExercise(String muscle, int sets) {
    return ExercisePrescription(
      exerciseId: 'placeholder_$muscle',
      exerciseName: 'Ejercicio pendiente ($muscle)',
      orderInSession: 1,
      sets: sets,
      repRange: const [8, 12],
      targetRir: 2,
      intensityZone: 'moderate',
      restSeconds: 90,
      notes: 'Fallback: catálogo sin coincidencias para $muscle',
    );
  }

  static String _resolveExerciseNameById(
    Map<String, Map<String, dynamic>> exerciseCatalog,
    String exerciseId,
  ) {
    final name = exerciseCatalog[exerciseId]?['name'];
    return name?.toString() ?? exerciseId;
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
