import 'package:hcs_app_lap/domain/training_domain/training_evaluation_snapshot_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_progression_state_v1.dart';

enum PlanAction { generate, regenerate, adapt }

class TrainingPlanDecisionService {
  static PlanAction decide({
    required TrainingProgressionStateV1 progression,
    required TrainingEvaluationSnapshotV1 evaluation,
    required TrainingEvaluationSnapshotV1 previousEvaluation,
  }) {
    if (progression.sessionsCompleted < 6 || progression.weeksCompleted < 2) {
      return PlanAction.regenerate;
    }

    if (evaluation.daysPerWeek != previousEvaluation.daysPerWeek) {
      return PlanAction.adapt;
    }

    return PlanAction.adapt;
  }
}
