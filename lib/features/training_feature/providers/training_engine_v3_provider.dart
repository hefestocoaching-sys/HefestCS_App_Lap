import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/engine/training_program_engine_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/hybrid_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/training_dataset_service.dart';

/// Provider para Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider para TrainingDatasetService
final trainingDatasetServiceProvider = Provider<TrainingDatasetService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TrainingDatasetService(firestore: firestore);
});

/// Provider para DecisionStrategy (configurable)
///
/// Por defecto usa RuleBasedStrategy.
/// Para testing ML, cambiar a HybridStrategy en settings.
final decisionStrategyProvider = Provider<DecisionStrategy>((ref) {
  // Por defecto: Rules científicas (100% confiable)
  return RuleBasedStrategy();

  // Para testing ML (cuando modelo esté disponible):
  // return HybridStrategy(mlWeight: 0.3); // 70% rules + 30% ML
});

/// Provider para TrainingProgramEngineV3
final trainingEngineV3Provider = Provider<TrainingProgramEngineV3>((ref) {
  final strategy = ref.watch(decisionStrategyProvider);
  final datasetService = ref.watch(trainingDatasetServiceProvider);

  return TrainingProgramEngineV3(
    strategy: strategy,
    datasetService: datasetService,
  );
});

/// Provider para factory production
final trainingEngineV3ProductionProvider = Provider<TrainingProgramEngineV3>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return TrainingProgramEngineV3.production(firestore: firestore);
});

/// Provider para factory hybrid (testing ML)
final trainingEngineV3HybridProvider = Provider<TrainingProgramEngineV3>((ref) {
  final firestore = ref.watch(firestoreProvider);
  // Ajustar mlWeight según fase de testing (0.2 → 0.3 → 0.5)
  return TrainingProgramEngineV3.hybrid(
    firestore: firestore,
    mlWeight: 0.3, // 70% rules + 30% ML
  );
});

/// StateNotifier para gestionar estado de generación de plan
class TrainingPlanGenerationState {
  final bool isLoading;
  final TrainingProgramV3Result? result;
  final String? error;

  const TrainingPlanGenerationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  TrainingPlanGenerationState copyWith({
    bool? isLoading,
    TrainingProgramV3Result? result,
    String? error,
  }) {
    return TrainingPlanGenerationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

class TrainingPlanGenerationNotifier
    extends StateNotifier<TrainingPlanGenerationState> {
  final TrainingProgramEngineV3 _engine;

  TrainingPlanGenerationNotifier(this._engine)
    : super(const TrainingPlanGenerationState());

  /// Genera plan usando Motor V3
  Future<void> generatePlan({
    required Client client,
    required List<Exercise> exercises,
    DateTime? asOfDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _engine.generatePlan(
        client: client,
        exercises: exercises,
        asOfDate: asOfDate,
        recordPrediction: true, // ✅ Guardar en Firestore para ML
      );

      state = state.copyWith(
        isLoading: false,
        result: result,
        error: result.isBlocked ? result.blockedReason : null,
      );
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al generar plan: ${e.toString()}',
      );

      // Log error para debugging
      // ignore: avoid_print
      print('TrainingPlanGenerationNotifier ERROR: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
    }
  }

  /// Reset estado
  void reset() {
    state = const TrainingPlanGenerationState();
  }
}

/// Provider para StateNotifier
final trainingPlanGenerationProvider =
    StateNotifierProvider<
      TrainingPlanGenerationNotifier,
      TrainingPlanGenerationState
    >((ref) {
      final engine = ref.watch(trainingEngineV3Provider);
      return TrainingPlanGenerationNotifier(engine);
    });
