// lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart' as v2;
import 'package:hcs_app_lap/domain/entities/training_session.dart' as v2;
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart' as v2;
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart'
    as v3;
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart' as v3;
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart'
    as v3;
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_domain/training_ssot_v1_service.dart';
// DecisionTrace is defined in training_program_v3_result.dart, already imported above

/// Orquestador principal del Motor V3
///
/// Proporciona una interfaz simplificada que retorna resultados tipados
/// (TrainingProgramV3Result) en lugar de Maps.
///
/// RESPONSABILIDADES:
/// 1. Convertir Client → UserProfile
/// 2. Delegar generación a MotorV3Orchestrator (científico puro)
/// 3. Convertir resultado V3 → TrainingProgramV3Result
/// 4. Proporcionar interfaz clara para el provider
///
/// ARQUITECTURA:
/// - TrainingOrchestratorV3 (este archivo): API pública
/// - MotorV3Orchestrator: Generación científica pura (VME/MAV/MRV)
///
/// Versión: 2.0.0 - Sin HybridOrchestratorV3
class TrainingOrchestratorV3 {
  // ════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN POR DEFECTO
  // ════════════════════════════════════════════════════════════════

  /// Fase de periodización por defecto
  /// TODO: Obtener del ciclo activo del cliente
  static const String _defaultPhase = 'accumulation';

  /// Duración en semanas por defecto
  /// TODO: Obtener del ciclo activo del cliente
  static const int _defaultDurationWeeks = 4;

  /// Edad por defecto para perfiles incompletos
  static const int _defaultAge = 30;

  /// Género por defecto para perfiles incompletos
  static const String _defaultGender = 'male';

  /// Altura por defecto en cm para perfiles incompletos
  static const double _defaultHeightCm = 170.0;

  /// Peso por defecto en kg para perfiles incompletos
  static const double _defaultWeightKg = 75.0;

  /// Años de entrenamiento por defecto para usuarios nuevos
  static const double _defaultYearsTraining = 1.0;

  /// Sesión de duración por defecto en minutos
  static const int _defaultSessionDuration = 60;

  /// Semanas consecutivas de entrenamiento inicial (valor inicial)
  static const int _initialConsecutiveWeeks = 0;

  // ════════════════════════════════════════════════════════════════
  // MIEMBROS DE INSTANCIA
  // ════════════════════════════════════════════════════════════════

  /// Estrategia de decisión a utilizar (deprecada, se mantiene por compatibilidad)
  final DecisionStrategy strategy;

  TrainingOrchestratorV3({
    required this.strategy,
    bool recordPredictions = false, // Ignorado en v2.0.0
  });

  /// Genera plan de entrenamiento completo
  ///
  /// PARÁMETROS:
  /// - [client]: Cliente para quien generar el plan
  /// - [exercises]: Catálogo de ejercicios disponibles
  /// - [asOfDate]: Fecha de inicio del plan
  /// - [recordPrediction]: Si se debe registrar la predicción ML
  ///
  /// RETORNA:
  /// - TrainingProgramV3Result: Resultado tipado con plan o bloqueo
  ///
  /// FLUJO:
  /// 1. Validar inputs
  /// 2. Convertir Client → UserProfile
  /// 3. Delegar a MotorV3Orchestrator
  /// 4. Convertir resultado V3 → TrainingProgramV3Result
  Future<TrainingProgramV3Result> generatePlan({
    required Client client,
    required List<Exercise> exercises,
    required DateTime asOfDate,
    bool recordPrediction = false,
  }) async {
    // ═══════════════════════════════════════════════════════════════
    // PASO 1: VALIDACIÓN DE INPUTS
    // ═══════════════════════════════════════════════════════════════

    // Validar que el cliente tenga datos mínimos
    final age = client.training.age ?? client.profile.age;
    final gender = client.training.gender ?? client.profile.gender;

    if (age == null) {
      return TrainingProgramV3Result.blocked(
        reason: 'Edad no disponible',
        suggestions: ['Completa la edad en Personal Data'],
      );
    }

    if (gender == null) {
      return TrainingProgramV3Result.blocked(
        reason: 'Género no disponible',
        suggestions: ['Completa el género en Personal Data'],
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // PASO 2: CONVERTIR Client → UserProfile
    // ═══════════════════════════════════════════════════════════════

    final userProfile = _convertClientToUserProfile(client);

    // ═══════════════════════════════════════════════════════════════
    // PASO 3: DELEGAR A MotorV3Orchestrator (CIENTÍFICO PURO)
    // ═══════════════════════════════════════════════════════════════

    // Determinar fase y duración
    // Nota: Por ahora usamos valores por defecto definidos en constantes.
    // Estos deberían reemplazarse con valores del ciclo activo del cliente.
    final phase = _defaultPhase;
    final durationWeeks = _defaultDurationWeeks;

    debugPrint('🎯 [TrainingOrchestratorV3] Delegando a MotorV3Orchestrator:');
    debugPrint('   - phase: $phase');
    debugPrint('   - durationWeeks: $durationWeeks');
    debugPrint('   - userProfile.id: ${userProfile.id}');

    final splitId =
        client.training.extra['splitId'] as String? ??
        client.training.extra['split'] as String?;
    final trainingDaysPerWeek = _parseInt(
      client.training.extra['trainingDaysPerWeek'] ??
          client.training.extra['daysPerWeek'],
    );

    final result = await MotorV3Orchestrator.generateProgram(
      userProfile: userProfile,
      phase: phase,
      durationWeeks: durationWeeks,
      splitId: splitId,
      trainingDaysPerWeek: trainingDaysPerWeek,
      client: client,
      exercises: exercises,
    );

    debugPrint('✅ [TrainingOrchestratorV3] MotorV3Orchestrator completado');
    debugPrint('   - success: ${result['success']}');
    debugPrint('   - planConfig: ${result['planConfig'] != null}');

    // ═══════════════════════════════════════════════════════════════
    // PASO 4: CONVERTIR Resultado V3 → TrainingProgramV3Result
    // ═══════════════════════════════════════════════════════════════

    final converted = _convertMapToResult(result, client, asOfDate);

    if (!converted.isBlocked) {
      final plan = converted.plan;
      if (plan == null) {
        throw StateError('Resultado V3 sin plan (plan == null)');
      }
      if (plan.weeks.isEmpty) {
        throw StateError('Plan generado sin semanas (weeks.isEmpty)');
      }
    }

    return converted;
  }

  /// Convierte Client (entidad de dominio) a UserProfile (modelo V3)
  ///
  /// TRANSFORMACIÓN:
  /// - Client.training → UserProfile con características técnicas
  /// - Client.profile → Datos demográficos
  /// - Client.trainingHistory → Logs históricos
  UserProfile _convertClientToUserProfile(Client client) {
    // Extraer datos de entrenamiento
    final training = client.training;
    final profile = client.profile;

    // ═══════════════════════════════════════════════════════════════════════
    // E3 SSOT V1: LEER setupV1 + evalV1 PRIMERO (fallback a legacy si no existen)
    // ═══════════════════════════════════════════════════════════════════════
    final setupV1 = TrainingSsotV1Service.readSetup(client);
    final evalV1 = TrainingSsotV1Service.readEvaluation(client);
    final useSsotV1 = setupV1 != null && evalV1 != null;

    // Extraer availableDays (SSOT V1 primero, luego legacy)
    final availableDays = useSsotV1 && setupV1.daysPerWeek > 0
        ? setupV1.daysPerWeek
        : (_parseInt(training.extra['daysPerWeek']) ?? 4);

    // E4 P0: Extraer sessionDurationMinutes (prioridad: extra, luego setupV1, luego legacy)
    int sessionDuration =
        (training.extra['sessionDurationMinutes'] as int?) ??
        (useSsotV1 && setupV1.timePerSessionMinutes > 0
            ? setupV1.timePerSessionMinutes
            : null) ??
        (training.extra['sessionDuration'] as int? ?? _defaultSessionDuration);

    // E4 P0: Extraer planDurationInWeeks (prioridad: extra, luego setupV1, luego legacy)
    int planDurationWeeks =
        (training.extra['planDurationInWeeks'] as int?) ??
        (useSsotV1 && setupV1.planDurationInWeeks > 0
            ? setupV1.planDurationInWeeks
            : null) ??
        8;

    // E4 P0: Extraer yearsTrainingContinuous (prioridad: extra, luego setupV1, luego legacy)
    double yearsTraining =
        (training.extra['yearsTrainingContinuous'] as double?) ??
        (useSsotV1 && setupV1.trainingExperienceYearsContinuous > 0
            ? setupV1.trainingExperienceYearsContinuous.toDouble()
            : null) ??
        (training.extra['yearsTraining'] as double? ?? _defaultYearsTraining);

    // E4 P0: Extraer altura y peso (prioridad: extra, luego setupV1, luego legacy)
    double heightCm =
        (training.extra['heightCm'] as double?) ??
        (useSsotV1 && setupV1.heightCm > 0 ? setupV1.heightCm : null) ??
        _defaultHeightCm;
    double weightKg =
        (training.extra['weightKg'] as double?) ??
        (useSsotV1 && setupV1.weightKg > 0 ? setupV1.weightKg : null) ??
        _defaultWeightKg;

    // ═══════════════════════════════════════════════════════════════════════
    // E3 PRIORIDADES MUSCULARES: SSOT V1 primero (con pesos Primary=1.0, Secondary=0.66, Tertiary=0.33)
    // ═══════════════════════════════════════════════════════════════════════
    Map<String, int> musclePrioritiesMap;

    if (useSsotV1) {
      // CASO 1: Usar evalV1.primaryMuscles/secondaryMuscles/tertiaryMuscles
      musclePrioritiesMap = <String, int>{};

      // Primary = peso 5 (máxima prioridad)
      for (final muscle in evalV1.primaryMuscles) {
        if (muscle.isNotEmpty) {
          musclePrioritiesMap[muscle] = 5;
        }
      }

      // Secondary = peso 3 (prioridad media)
      for (final muscle in evalV1.secondaryMuscles) {
        if (muscle.isNotEmpty && !musclePrioritiesMap.containsKey(muscle)) {
          musclePrioritiesMap[muscle] = 3;
        }
      }

      // Tertiary = peso 2 (prioridad baja)
      for (final muscle in evalV1.tertiaryMuscles) {
        if (muscle.isNotEmpty && !musclePrioritiesMap.containsKey(muscle)) {
          musclePrioritiesMap[muscle] = 2;
        }
      }
    } else {
      // CASO 2: Fallback a legacy (extraer desde strings CSV)
      final priorityMuscles = _extractPriorityMuscles(training.extra);
      musclePrioritiesMap = <String, int>{};

      // Assign priority scores if muscles exist
      // Score decreases from list length to 1, ensuring all scores are positive
      if (priorityMuscles.isNotEmpty) {
        for (int i = 0; i < priorityMuscles.length; i++) {
          // First muscle gets highest score, last gets 1
          // Example: 8 muscles → [8, 7, 6, 5, 4, 3, 2, 1]
          final descendingPriorityScore = (priorityMuscles.length - i);
          musclePrioritiesMap[priorityMuscles[i]] = descendingPriorityScore;
        }
      }
    }

    // Normalizar claves a canónicas (14 músculos) para el Motor V3
    final normalizedMusclePrioritiesMap = normalizeLegacyVopToCanonical(
      musclePrioritiesMap,
    );

    // Clamp de prioridades a rango válido (1-5)
    final clampedMusclePrioritiesMap = <String, int>{};
    normalizedMusclePrioritiesMap.forEach((key, value) {
      final clamped = value.clamp(1, 5).toInt();
      clampedMusclePrioritiesMap[key] = clamped;
    });

    // ═══════════════════════════════════════════════════════════════════════
    // E3 DEBUG: Load-bearing log para auditar fuente de datos
    // ═══════════════════════════════════════════════════════════════════════
    debugPrint(
      '\n═══════════════════════════════════════════════════════════════',
    );
    debugPrint('🔍 E3 MOTOR V3 INPUT SOURCE AUDIT');
    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('SSOT V1 used: $useSsotV1');
    debugPrint('availableDays resolved: $availableDays');
    debugPrint('sessionDuration resolved: $sessionDuration min');
    debugPrint('planDurationWeeks resolved: $planDurationWeeks weeks');
    debugPrint('yearsTraining resolved: $yearsTraining years');
    debugPrint(
      'musclePriorities keys (${clampedMusclePrioritiesMap.length}): ${clampedMusclePrioritiesMap.keys.toList()}',
    );
    debugPrint(
      '═══════════════════════════════════════════════════════════════\n',
    );

    // Convertir nivel de experiencia
    final trainingLevel = _convertTrainingLevel(training.extra['level']);

    // Extraer objetivo
    final goal = training.extra['goal'] as String? ?? 'hypertrophy';

    // Crear mapa de historial de lesiones
    // TODO: Extract actual injury status from client data (active/healed/recovered)
    final injuries = _getInjuries(training.extra);
    final injuryHistory = <String, String>{};
    for (final injury in injuries) {
      // Currently assume all listed injuries are active
      // In the future, retrieve actual status from injury tracking data
      injuryHistory[injury] = 'active';
    }

    // Normalizar género al formato esperado por UserProfile
    final genderValue = training.gender ?? profile.gender ?? _defaultGender;
    final normalizedGender = _normalizeGender(genderValue);

    // Crear UserProfile con todos los parámetros requeridos
    return UserProfile(
      id: client.id,
      name: profile.fullName,
      email: profile.email,
      age: training.age ?? profile.age ?? _defaultAge,
      gender: normalizedGender,
      heightCm: heightCm,
      weightKg: weightKg,
      yearsTraining: yearsTraining,
      trainingLevel: trainingLevel,
      consecutiveWeeks: _initialConsecutiveWeeks,
      availableDays: availableDays,
      sessionDuration: sessionDuration,
      primaryGoal: goal,
      musclePriorities: clampedMusclePrioritiesMap,
      availableEquipment: _getAvailableEquipment(training.extra),
      injuryHistory: injuryHistory,
      excludedExercises: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convierte nivel de entrenamiento (string) a valor normalizado
  String _convertTrainingLevel(dynamic level) {
    if (level == null) return 'intermediate';

    final levelStr = level.toString().toLowerCase();

    if (levelStr.contains('principiante') ||
        levelStr.contains('beginner') ||
        levelStr.contains('novice')) {
      return 'novice';
    }

    if (levelStr.contains('intermedio') || levelStr.contains('intermediate')) {
      return 'intermediate';
    }

    if (levelStr.contains('avanzado') || levelStr.contains('advanced')) {
      return 'advanced';
    }

    return 'intermediate'; // Default
  }

  /// Normaliza género al formato requerido por UserProfile (male/female/other)
  String _normalizeGender(dynamic gender) {
    if (gender is String) {
      final normalized = gender.toLowerCase().trim();
      if (normalized.contains('male') ||
          normalized.contains('hombre') ||
          normalized == 'm') {
        return 'male';
      }
      if (normalized.contains('female') ||
          normalized.contains('mujer') ||
          normalized == 'f') {
        return 'female';
      }
      if (normalized.contains('other') || normalized.contains('otro')) {
        return 'other';
      }
    }

    // Enums: usar name cuando aplique (Gender.male -> "male")
    if (gender is Enum) {
      final name = gender.name;
      if (name == 'male' || name == 'female' || name == 'other') {
        return name;
      }
    }

    return _defaultGender;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Extrae músculos prioritarios del perfil
  List<String> _extractPriorityMuscles(Map<String, dynamic> extra) {
    final primary = (extra['priorityMusclesPrimary'] as String? ?? '')
        .split(',')
        .where((m) => m.trim().isNotEmpty)
        .toList();

    final secondary = (extra['priorityMusclesSecondary'] as String? ?? '')
        .split(',')
        .where((m) => m.trim().isNotEmpty)
        .toList();

    final tertiary = (extra['priorityMusclesTertiary'] as String? ?? '')
        .split(',')
        .where((m) => m.trim().isNotEmpty)
        .toList();

    final all = <String>{};
    all.addAll(primary);
    all.addAll(secondary);
    all.addAll(tertiary);

    return all.toList();
  }

  /// Obtiene equipo disponible del perfil
  List<String> _getAvailableEquipment(Map<String, dynamic> extra) {
    final equipment = extra['availableEquipment'] as List<dynamic>? ?? [];
    return equipment.map((e) => e.toString()).toList();
  }

  /// Obtiene lesiones del perfil
  List<String> _getInjuries(Map<String, dynamic> extra) {
    final injuries = extra['injuries'] as List<dynamic>? ?? [];
    return injuries.map((e) => e.toString()).toList();
  }

  /// Convierte Map (resultado Motor V3) a TrainingProgramV3Result
  ///
  /// ESTRUCTURA DEL MAP:
  /// ```
  /// {
  ///   'success': bool,
  ///   'program': TrainingProgram?,
  ///   'errors': List<String>?,
  ///   'warnings': List<String>?,
  ///   'planConfig': TrainingPlanConfig,
  /// }
  /// ```
  TrainingProgramV3Result _convertMapToResult(
    Map<String, dynamic> result,
    Client client,
    DateTime asOfDate,
  ) {
    final success = result['success'] == true;

    if (!success) {
      // Plan bloqueado o error
      final errors = result['errors'];
      final warnings = result['warnings'];

      final errorMessages = errors is List
          ? errors.map((e) => e.toString()).toList()
          : <String>[];
      final warningMessages = warnings is List
          ? warnings.map((e) => e.toString()).toList()
          : <String>[];

      final blockReason = errorMessages.isNotEmpty
          ? errorMessages.join('. ')
          : 'No se pudo generar el plan';

      return TrainingProgramV3Result.blocked(
        reason: blockReason,
        suggestions: warningMessages,
      );
    }

    // Plan generado exitosamente
    final planConfigValue = result['planConfig'];
    final TrainingPlanConfig planConfig;
    if (planConfigValue is TrainingPlanConfig) {
      planConfig = planConfigValue;
    } else if (planConfigValue is v3.TrainingPlanConfig) {
      planConfig = _convertV3PlanConfigToEntity(planConfigValue, client);
    } else {
      throw StateError('Resultado V3 sin TrainingPlanConfig válido');
    }

    // Crear trace para debugging
    final trace = _createDecisionTrace(result);

    return TrainingProgramV3Result.success(
      plan: planConfig,
      trace: trace,
      metadata: {
        'generated_at': DateTime.now().toIso8601String(),
        'version': 'motor_v3_1.0.0',
        'strategy': strategy.name,
        'ml_applied': false,
      },
    );
  }

  /// Crea DecisionTrace desde el resultado del orquestador
  DecisionTrace? _createDecisionTrace(Map<String, dynamic> result) {
    try {
      return DecisionTrace(
        volumeDecisions: result['volumeDecisions'] ?? {},
        intensityDecisions: result['intensityDecisions'] ?? {},
        exerciseSelections: result['exerciseSelections'] ?? {},
        splitRationale: 'Split seleccionado automáticamente',
        phaseRationale: 'Fase determinada por ciclo de entrenamiento',
      );
    } catch (e) {
      debugPrint('⚠️  No se pudo crear DecisionTrace: $e');
      return null;
    }
  }

  TrainingPlanConfig _convertV3PlanConfigToEntity(
    v3.TrainingPlanConfig planV3,
    Client client,
  ) {
    final resolvedPhase = TrainingPhase.values.firstWhere(
      (e) => e.name == (planV3.phase ?? ''),
      orElse: () => TrainingPhase.accumulation,
    );

    final resolvedSplitId = planV3.split ?? 'fullBody';

    final weeks = planV3.weeks
        .whereType<v3.TrainingWeek>()
        .map(
          (w) => v2.TrainingWeek(
            id: 'week-${w.weekNumber}-${resolvedPhase.name}',
            weekNumber: w.weekNumber,
            phase: resolvedPhase,
            sessions: _convertV3Sessions(w.sessions),
          ),
        )
        .toList();

    return TrainingPlanConfig(
      id: planV3.id,
      name: 'Plan ${client.profile.fullName}',
      clientId: planV3.clientId,
      startDate: planV3.startDate,
      phase: resolvedPhase,
      splitId: resolvedSplitId,
      microcycleLengthInWeeks: weeks.length,
      weeks: weeks,
      state: planV3.extra,
      volumePerMuscle: planV3.volumePerMuscle,
    );
  }

  List<v2.TrainingSession> _convertV3Sessions(List<dynamic> sessions) {
    final out = <v2.TrainingSession>[];
    for (final session in sessions) {
      if (session is! v3.TrainingSession) continue;
      final sessionId = session.id;
      final primary = session.primaryMuscles.isNotEmpty
          ? session.primaryMuscles.first
          : 'full_body';
      final muscleGroup =
          muscleGroupFromString(primary) ?? MuscleGroup.fullBody;

      final prescriptions = <v2.ExercisePrescription>[];
      for (final ex in session.exercises) {
        final order = ex.orderInSession;
        final repsMin = ex.repRange.isNotEmpty ? ex.repRange.first : 8;
        final repsMax = ex.repRange.length > 1 ? ex.repRange[1] : 12;

        prescriptions.add(
          v2.ExercisePrescription(
            id: 'presc_${sessionId}_$order',
            sessionId: sessionId,
            muscleGroup: muscleGroup,
            exerciseCode: ex.exerciseId,
            label: _labelForOrder(order),
            exerciseName: ex.exerciseName,
            sets: ex.sets,
            repRange: RepRange(repsMin, repsMax),
            rir: ex.targetRir.toString(),
            restMinutes: (ex.restSeconds / 60).round().clamp(1, 10),
            notes: ex.notes,
            order: order,
          ),
        );
      }

      out.add(
        v2.TrainingSession(
          id: sessionId,
          dayNumber: session.dayNumber,
          sessionName: session.name,
          prescriptions: prescriptions,
        ),
      );
    }
    return out;
  }

  String _labelForOrder(int order) {
    final index = (order - 1) % 26;
    return String.fromCharCode(65 + index);
  }

  /// Registra el resultado de un programa completado
  @Deprecated('ML features removidos en v2.0.0')
  Future<void> recordProgramOutcome({
    required String predictionId,
    required dynamic completedLogs,
    bool injuryOccurred = false,
  }) async {
    // No-op: ML features removidos
    debugPrint('⚠️  recordProgramOutcome deprecado');
  }

  /// Obtiene precisión del sistema ML
  @Deprecated('ML features removidos en v2.0.0')
  Future<Map<String, dynamic>> getMLAccuracy({required String userId}) async {
    debugPrint('⚠️  getMLAccuracy deprecado');
    return {'accuracy': 0.0, 'deprecado': true};
  }
}
