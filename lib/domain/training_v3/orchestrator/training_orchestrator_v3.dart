// lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart

import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/hybrid_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/ml_config_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';

/// Orquestador principal del Motor V3
///
/// Envuelve HybridOrchestratorV3 para proporcionar una interfaz simplificada
/// que retorna resultados tipados (TrainingProgramV3Result) en lugar de Maps.
///
/// RESPONSABILIDADES:
/// 1. Convertir Client → UserProfile
/// 2. Delegar generación a HybridOrchestratorV3
/// 3. Convertir Map → TrainingProgramV3Result
/// 4. Proporcionar interfaz clara para el provider
///
/// ARQUITECTURA:
/// - TrainingOrchestratorV3 (este archivo): API pública
/// - HybridOrchestratorV3: Implementación del pipeline científico + ML
/// - MotorV3Orchestrator: Generación científica pura
///
/// Versión: 1.0.0
class TrainingOrchestratorV3 {
  /// Estrategia de decisión a utilizar
  final DecisionStrategy strategy;

  /// Si se deben registrar predicciones ML
  final bool recordPredictions;

  /// Orquestador híbrido interno
  late final HybridOrchestratorV3 _hybridOrchestrator;

  TrainingOrchestratorV3({
    required this.strategy,
    this.recordPredictions = false,
  }) {
    // Crear configuración ML basada en estrategia
    final config = MLConfigV3(
      strategy: strategy,
      recordPredictions: recordPredictions,
    );

    // Inicializar orquestador híbrido
    _hybridOrchestrator = HybridOrchestratorV3(config: config);
  }

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
      // PASO 3: DELEGAR A HybridOrchestratorV3
      // ═══════════════════════════════════════════════════════════════

      // Determinar fase y duración
      // Por ahora usamos valores por defecto, pero esto debería venir
      // del ciclo activo del cliente
      final phase = 'accumulation'; // TODO: Obtener del ciclo activo
      final durationWeeks = 4; // TODO: Obtener del ciclo activo

      final result = await _hybridOrchestrator.generateHybridProgram(
        userProfile: userProfile,
        phase: phase,
        durationWeeks: durationWeeks,
      );

      // ═══════════════════════════════════════════════════════════════
      // PASO 4: CONVERTIR Map → TrainingProgramV3Result
      // ═══════════════════════════════════════════════════════════════

      return _convertMapToResult(result, client, asOfDate);
    } catch (e, stackTrace) {
      print('❌ [TrainingOrchestratorV3] Error generando plan: $e');
      print('Stack trace: $stackTrace');

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

    // Extraer músculos prioritarios
    final priorityMuscles = _extractPriorityMuscles(training.extra);

    // Extraer días disponibles
    final daysPerWeek = training.extra['daysPerWeek'] as int? ?? 4;

    // Extraer objetivo
    final goal = training.extra['goal'] as String? ?? 'hypertrophy';

    // Crear UserProfile
    return UserProfile(
      id: client.id,
      name: profile.name,
      age: training.age ?? profile.age ?? 30,
      gender: training.gender ?? profile.gender ?? 'male',
      trainingLevel: trainingLevel,
      daysPerWeek: daysPerWeek,
      primaryGoal: goal,
      priorityMuscles: priorityMuscles,
      availableEquipment: _getAvailableEquipment(training.extra),
      injuries: _getInjuries(training.extra),
      // Factores de recuperación
      sleepQuality: training.extra['sleepQuality'] as int? ?? 7,
      stressLevel: training.extra['stressLevel'] as int? ?? 5,
      energyLevel: training.extra['energyLevel'] as int? ?? 7,
      // Factores metabólicos
      caloricDeficit: training.extra['caloricDeficit'] as int? ?? 0,
      // Metadata
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Convierte nivel de entrenamiento (string) a valor normalizado
  String _convertTrainingLevel(dynamic level) {
    if (level == null) return 'intermediate';

    final levelStr = level.toString().toLowerCase();

    if (levelStr.contains('principiante') ||
        levelStr.contains('beginner') ||
        levelStr.contains('novice')) {
      return 'beginner';
    }

    if (levelStr.contains('intermedio') ||
        levelStr.contains('intermediate')) {
      return 'intermediate';
    }

    if (levelStr.contains('avanzado') || levelStr.contains('advanced')) {
      return 'advanced';
    }

    return 'intermediate'; // Default
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
  /// {
  ///   'success': bool,
  ///   'program': TrainingProgram?,
  ///   'errors': List<String>?,
  ///   'warnings': List<String>?,
  ///   'ml': { ... },
  ///   'scientific': { ... },
  /// }
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

      final blockReason =
          errorMessages.isNotEmpty
              ? errorMessages.join('. ')
              : 'No se pudo generar el plan';

      return TrainingProgramV3Result.blocked(
        reason: blockReason,
        suggestions: warningMessages,
      );
    }

    // Plan generado exitosamente
    // NOTA: HybridOrchestratorV3 retorna TrainingProgram (modelo V3),
    // pero el provider espera TrainingPlanConfig (entidad de dominio)
    // Por ahora, retornamos un TrainingPlanConfig básico
    // TODO: Implementar conversión TrainingProgram → TrainingPlanConfig

    // Crear TrainingPlanConfig básico
    final planConfig = _createBasicPlanConfig(client, asOfDate);

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
  TrainingPlanConfig _createBasicPlanConfig(
    Client client,
    DateTime asOfDate,
  ) {
    // Por ahora, retornar un plan vacío con estructura básica
    // TODO: Implementar conversión real

    return TrainingPlanConfig(
      id: 'plan_${client.id}_${asOfDate.millisecondsSinceEpoch}',
      clientId: client.id,
      startDate: asOfDate,
      weeks: [], // TODO: Convertir desde TrainingProgram
      createdAt: DateTime.now(),
      extra: {
        'generated_by': 'motor_v3',
        'strategy': strategy.name,
      },
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
      print('⚠️  No se pudo crear DecisionTrace: $e');
      return null;
    }
  }

  /// Registra el resultado de un programa completado
  Future<void> recordProgramOutcome({
    required String predictionId,
    required dynamic completedLogs,
    bool injuryOccurred = false,
  }) async {
    // Delegar a HybridOrchestratorV3
    await _hybridOrchestrator.recordProgramOutcome(
      predictionId: predictionId,
      completedLogs: completedLogs,
      injuryOccurred: injuryOccurred,
    );
  }

  /// Obtiene precisión del sistema ML
  Future<Map<String, dynamic>> getMLAccuracy({
    required String userId,
  }) async {
    return await _hybridOrchestrator.getMLAccuracy(userId: userId);
  }
}
