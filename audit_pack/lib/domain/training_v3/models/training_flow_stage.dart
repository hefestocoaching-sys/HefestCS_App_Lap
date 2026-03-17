enum TrainingFlowStage { interview, landmarks, intensity, plan }

extension TrainingFlowStageX on TrainingFlowStage {
  static TrainingFlowStage fromRaw(String? raw) {
    for (final stage in TrainingFlowStage.values) {
      if (stage.name == raw) return stage;
    }
    return TrainingFlowStage.interview;
  }
}
