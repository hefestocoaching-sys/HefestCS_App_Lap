import 'package:hcs_app_lap/core/enums/effective_training_state.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';

class TrainingHistoryDerivationService {
  static EffectiveTrainingState deriveState({
    required bool hasTrainedBefore,
    required bool isTrainingNow,
    required int monthsTrainingNow,
  }) {
    if (!hasTrainedBefore) {
      return EffectiveTrainingState.neverTrained;
    }

    if (!isTrainingNow) {
      return EffectiveTrainingState.detrained;
    }

    if (monthsTrainingNow < 6) {
      return EffectiveTrainingState.reconditioning;
    }

    return EffectiveTrainingState.continuousTraining;
  }

  static TrainingLevel deriveTrainingLevel({
    required EffectiveTrainingState state,
    required int totalYearsTrainedBefore,
  }) {
    switch (state) {
      case EffectiveTrainingState.neverTrained:
        return TrainingLevel.beginner;
      case EffectiveTrainingState.reconditioning:
        return TrainingLevel.beginner;
      case EffectiveTrainingState.detrained:
        return TrainingLevel.beginner;
      case EffectiveTrainingState.continuousTraining:
        if (totalYearsTrainedBefore < 1) return TrainingLevel.beginner;
        if (totalYearsTrainedBefore < 3) return TrainingLevel.intermediate;
        return TrainingLevel.advanced;
    }
  }

  static bool isReconditioningPhase(EffectiveTrainingState state) {
    return state == EffectiveTrainingState.reconditioning;
  }

  static double volumeToleranceModifier(EffectiveTrainingState state) {
    switch (state) {
      case EffectiveTrainingState.neverTrained:
        return 0.85;
      case EffectiveTrainingState.detrained:
        return 0.9;
      case EffectiveTrainingState.reconditioning:
        return 0.9;
      case EffectiveTrainingState.continuousTraining:
        return 1.0;
    }
  }
}
