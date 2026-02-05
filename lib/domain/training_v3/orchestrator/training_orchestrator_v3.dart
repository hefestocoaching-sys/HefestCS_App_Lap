// lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
// DecisionTrace is defined in training_program_v3_result.dart, already imported above

/// Orquestador principal del Motor V3
///
/// Proporciona una interfaz simplificada que retorna resultados tipados
/// (TrainingProgramV3Result) en lugar de Maps.
///
/// RESPONSABILIDADES:
/// 1. Convertir Client → UserProfile
/// 2. Delegar generación a MotorV3Orchestrator (científico puro)
/// 3. Convertir Map → TrainingProgramV3Result
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
  /// 3. Delegar a HybridOrchestratorV3
  /// 4. Convertir Map → TrainingProgramV3Result
  Future<TrainingProgramV3Result> generatePlan({
    required Client client,
    required List<Exercise> exercises,
    required DateTime asOfDate,
    bool recordPrediction = false,
  }) async {
    try {
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

      final result = await MotorV3Orchestrator.generateProgram(
        userProfile: userProfile,
        phase: phase,
        durationWeeks: durationWeeks,
        client: client,
        exercises: exercises,
      );

      // ═══════════════════════════════════════════════════════════════
      // PASO 4: CONVERTIR Map → TrainingProgramV3Result
      // ═══════════════════════════════════════════════════════════════

      return _convertMapToResult(result, client, asOfDate);
    } catch (e, stackTrace) {
      debugPrint('❌ [TrainingOrchestratorV3] Error generando plan: $e');
      debugPrint('Stack trace: $stackTrace');

      return TrainingProgramV3Result.blocked(
        reason: 'Error técnico: ${e.toString()}',
        suggestions: [
          'Verifica que los datos del perfil estén completos',
          'Intenta nuevamente',
        ],
      );
    }
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

    // Convertir nivel de experiencia
    final trainingLevel = _convertTrainingLevel(training.extra['level']);

    // Extraer músculos prioritarios (para musclePriorities map)
    final priorityMuscles = _extractPriorityMuscles(training.extra);
    final musclePrioritiesMap = <String, int>{};

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

    // Extraer días disponibles
    final availableDays = _parseInt(training.extra['daysPerWeek']) ?? 4;

    // Extraer duración de sesión (en minutos)
    final sessionDuration =
        training.extra['sessionDuration'] as int? ?? _defaultSessionDuration;

    // Extraer objetivo
    final goal = training.extra['goal'] as String? ?? 'hypertrophy';

    // Extraer años de entrenamiento
    final yearsTraining =
        training.extra['yearsTraining'] as double? ?? _defaultYearsTraining;

    // Extraer altura y peso (con valores por defecto)
    final heightCm = training.extra['heightCm'] as double? ?? _defaultHeightCm;
    final weightKg = training.extra['weightKg'] as double? ?? _defaultWeightKg;

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

  /// Convierte Map (resultado de HybridOrchestrator) a TrainingProgramV3Result
  ///
  /// ESTRUCTURA DEL MAP:
  /// ```
  /// {
  ///   'success': bool,
  ///   'program': TrainingProgram?,
  ///   'errors': List<String>?,
  ///   'warnings': List<String>?,
  ///   'ml': { ... },
  ///   'scientific': { ... },
  /// }
  /// ```
  TrainingProgramV3Result _convertMapToResult(
    Map<String, dynamic> result,
    Client client,
    DateTime asOfDate,
  ) {
    final success = result['success'] as bool? ?? false;

    if (!success) {
      // Plan bloqueado o error
      final errors = result['errors'] as List<dynamic>? ?? [];
      final warnings = result['warnings'] as List<dynamic>? ?? [];

      final errorMessages = errors.map((e) => e.toString()).toList();
      final warningMessages = warnings.map((e) => e.toString()).toList();

      final blockReason = errorMessages.isNotEmpty
          ? errorMessages.join('. ')
          : 'No se pudo generar el plan';

      return TrainingProgramV3Result.blocked(
        reason: blockReason,
        suggestions: warningMessages,
      );
    }

    // Plan generado exitosamente
    // Si HybridOrchestratorV3 ya incluye planConfig, usarlo directamente.
    final planConfig = (result['planConfig'] is TrainingPlanConfig)
        ? (result['planConfig'] as TrainingPlanConfig)
        : _createBasicPlanConfig(client, asOfDate);

    // Crear trace para debugging
    final trace = _createDecisionTrace(result);

    return TrainingProgramV3Result.success(
      plan: planConfig,
      trace: trace,
      metadata: {
        'generated_at': DateTime.now().toIso8601String(),
        'version': 'motor_v3_1.0.0',
        'strategy': strategy.name,
        'ml_applied': result['ml']?['applied'] ?? false,
      },
    );
  }

  /// Crea un TrainingPlanConfig básico
  ///
  /// NOTA: Esto es un placeholder temporal.
  /// Debería convertir TrainingProgram (V3) → TrainingPlanConfig (domain).
  TrainingPlanConfig _createBasicPlanConfig(Client client, DateTime asOfDate) {
    // Por ahora, retornar un plan vacío con estructura básica
    // TODO: Implementar conversión real

    return TrainingPlanConfig(
      id: 'plan_${client.id}_${asOfDate.millisecondsSinceEpoch}',
      name: 'Plan ${client.profile.fullName}',
      clientId: client.id,
      startDate: asOfDate,
      phase: TrainingPhase.accumulation,
      splitId: 'ul_ul', // Default Upper/Lower
      microcycleLengthInWeeks: 4,
      weeks: [], // TODO: Convertir desde TrainingProgram
      state: {'generated_by': 'motor_v3', 'strategy': strategy.name},
    );
  }

  /// Crea DecisionTrace desde el resultado del orquestador
  DecisionTrace? _createDecisionTrace(Map<String, dynamic> result) {
    try {
      return DecisionTrace(
        volumeDecisions: result['scientific']?['volume_validation'] ?? {},
        intensityDecisions: result['ml']?['adjustments'] ?? {},
        exerciseSelections: {},
        splitRationale: 'Split seleccionado automáticamente',
        phaseRationale: 'Fase determinada por ciclo de entrenamiento',
      );
    } catch (e) {
      debugPrint('⚠️  No se pudo crear DecisionTrace: $e');
      return null;
    }
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
