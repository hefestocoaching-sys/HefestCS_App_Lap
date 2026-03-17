/// Provider para generación y gestión de planes Motor V3
///
/// RESPONSABILIDADES:
/// 1. Generar plan científico usando TrainingOrchestratorV3
/// 2. Mantener estado (cargando, error, resultado)
/// 3. Persistir TrainingPlanConfig en repositorio
/// 4. Cargar planes persistidos
///
/// NO usa GeneratedPlan ni TrainingPlanBuilder
/// SSOT único: TrainingPlanV3State con TrainingProgramV3Result
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/orchestrator/training_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/deload_trigger_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/workout_log_repository.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_v3_state.dart';

/// Provider Notifier para planes V3
final trainingPlanV3Provider =
    NotifierProvider<TrainingPlanV3Notifier, TrainingPlanV3State>(
      TrainingPlanV3Notifier.new,
    );

/// Notifier que maneja la lógica de generación V3
class TrainingPlanV3Notifier extends Notifier<TrainingPlanV3State> {
  @override
  TrainingPlanV3State build() => TrainingPlanV3State.empty;

  /// Generar nuevo plan científico con Motor V3
  ///
  /// PARÁMETROS:
  /// - [client]: Cliente con datos de perfil y entrenamiento
  /// - [exercises]: Catálogo de ejercicios disponibles
  ///
  /// FLUJO:
  /// 1. Validar inputs
  /// 2. Llamar TrainingOrchestratorV3.generatePlan
  /// 3. Capturar resultado (success o blocked)
  /// 4. Actualizar state
  /// 5. Persistir si es exitoso
  ///
  /// ERROR HANDLING:
  /// - Si falla la generación → state.error con mensaje
  /// - Si bloqueado → state.result.isBlocked = true
  Future<void> generateV3({
    required Client client,
    required List<Exercise> exercises,
    DateTime? asOfDate,
  }) async {
    final effectiveAsOfDate = asOfDate ?? DateTime.now();

    // Iniciar carga
    state = state.copyWith(isLoading: true);

    try {
      // 1) Validar inputs mínimos
      final age = _resolveAge(client);
      if (age == null || age <= 0) {
        throw ArgumentError(
          'Client: edad inválida. Completa la edad en la entrevista o en datos personales.',
        );
      }

      const plannedPhase = 'accumulation';
      final resolvedPhase = await _resolvePhase(
        clientId: client.id,
        consecutiveWeeks: _resolveConsecutiveWeeks(client),
        plannedPhase: plannedPhase,
        asOfDate: effectiveAsOfDate,
      );

      if (resolvedPhase == 'deload') {
        state = state.copyWith(
          isLoading: false,
          deloadAlert:
              'Se detectó fatiga acumulada. Se recomienda semana de descarga antes de generar el nuevo plan.',
        );
        return;
      }

      final availableTrainingDays = _resolveAvailableTrainingDays(client);
      if (availableTrainingDays == null || availableTrainingDays < 3) {
        throw StateError(
          'Training interview incomplete: training days missing',
        );
      }

      // 2) Crear orquestador y llamar Motor V3
      final orchestrator = TrainingOrchestratorV3(
        strategy: RuleBasedStrategy(),
      );

      final result = await orchestrator.generatePlan(
        client: client,
        exercises: exercises,
        asOfDate: effectiveAsOfDate,
        phase: resolvedPhase,
      );

      // 3) Actualizar state con resultado
      if (result.isBlocked) {
        // Plan bloqueado (fatiga, datos insuficientes, error)
        state = state.copyWith(
          isLoading: false,
          error: result.blockReason,
          result: result,
        );
      } else {
        // Plan exitoso
        state = state.copyWith(
          isLoading: false,
          result: result,
          plan: result.plan,
        );
      }
    } catch (e) {
      // Error técnico durante generación
      state = state.copyWith(
        isLoading: false,
        error: 'Error generando plan V3: ${e.toString()}',
      );
    }
  }

  Future<String> _resolvePhase({
    required String clientId,
    required int consecutiveWeeks,
    required String plannedPhase,
    required DateTime asOfDate,
  }) async {
    final recentLogs = await WorkoutLogRepository.getLogsByUser(
      userId: clientId,
      limit: 14,
      startDate: asOfDate.subtract(const Duration(days: 14)),
    );

    if (recentLogs.isEmpty) return plannedPhase;

    try {
      final eval = DeloadTriggerEngine.evaluateDeloadNeed(
        recentLogs: recentLogs,
        weeksInProgram: consecutiveWeeks,
      );

      final needsDeload = eval['needs_deload'] as bool? ?? false;
      final urgency = eval['urgency'] as String? ?? 'none';
      final reasoning = eval['reasoning'] as String? ?? '';

      if (needsDeload && (urgency == 'urgent' || urgency == 'recommended')) {
        debugPrint('🔄 [DeloadTrigger] Override → deload. Reason: $reasoning');
        return 'deload';
      }
    } catch (e) {
      debugPrint(
        '⚠️ [DeloadTrigger] Error evaluando: $e. Usando fase planeada.',
      );
    }

    return plannedPhase;
  }

  int _resolveConsecutiveWeeks(Client client) {
    final raw =
        client.training.extra['consecutiveWeeks'] ??
        client.training.extra['weeksCompleted'] ??
        client.training.currentWeekIndex;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  int? _resolveAvailableTrainingDays(Client client) {
    if (client.training.daysPerWeek > 0) {
      return client.training.daysPerWeek;
    }

    final raw =
        client.training.extra['availableTrainingDays'] ??
        client.training.extra['trainingDaysPerWeek'] ??
        client.training.extra['daysPerWeek'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  int? _resolveAge(Client client) {
    if (client.training.age != null && client.training.age! > 0) {
      return client.training.age;
    }
    if (client.profile.age != null && client.profile.age! > 0) {
      return client.profile.age;
    }
    final raw = client.training.extra['ageYears'];
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw > 0) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Limpiar estado
  void clearPlan() {
    state = TrainingPlanV3State.empty;
  }

  /// Actualizar estado de error
  void setError(String message) {
    state = state.copyWith(error: message, isLoading: false);
  }
}
