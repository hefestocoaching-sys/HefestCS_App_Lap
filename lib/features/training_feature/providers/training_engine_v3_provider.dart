import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/hybrid_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/ml_config_v3.dart';

final trainingEngineV3Provider = Provider<HybridOrchestratorV3>((ref) {
  return HybridOrchestratorV3(config: MLConfigV3.hybrid());
});

class TrainingProgramV3State {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  const TrainingProgramV3State({
    this.isLoading = false,
    this.result,
    this.error,
  });

  TrainingProgramV3State copyWith({
    bool? isLoading,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return TrainingProgramV3State(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}
