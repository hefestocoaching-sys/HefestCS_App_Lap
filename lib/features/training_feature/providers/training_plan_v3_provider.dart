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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/orchestrator/training_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
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
  }) async {
    // Iniciar carga
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1) Validar inputs mínimos
      final age = client.training.age ?? client.profile.age;
      if (age == null || age <= 0) {
        throw ArgumentError('Client: edad inválida');
      }

      // 2) Crear orquestador y llamar Motor V3
      final orchestrator = TrainingOrchestratorV3(
        strategy: RuleBasedStrategy(),
        recordPredictions: false,
      );

      final result = await orchestrator.generatePlan(
        client: client,
        exercises: exercises,
        asOfDate: DateTime.now(),
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

  /// Limpiar estado
  void clearPlan() {
    state = TrainingPlanV3State.empty;
  }

  /// Actualizar estado de error
  void setError(String message) {
    state = state.copyWith(error: message, isLoading: false);
  }
}
