enum TrainingFlowStage {
  interview,
  landmarks,
  intensity,
  gymExercises,
  plan,
  monitoring,
}

extension TrainingFlowStageX on TrainingFlowStage {
  int get order {
    switch (this) {
      case TrainingFlowStage.interview:
        return 0;
      case TrainingFlowStage.landmarks:
        return 1;
      case TrainingFlowStage.intensity:
        return 2;
      case TrainingFlowStage.gymExercises:
        return 3;
      case TrainingFlowStage.plan:
        return 4;
      case TrainingFlowStage.monitoring:
        return 5;
    }
  }

  String get displayName {
    switch (this) {
      case TrainingFlowStage.interview:
        return 'Entrevista';
      case TrainingFlowStage.landmarks:
        return 'Landmarks';
      case TrainingFlowStage.intensity:
        return 'Intensidad';
      case TrainingFlowStage.gymExercises:
        return 'Preferencias de ejercicios';
      case TrainingFlowStage.plan:
        return 'Plan';
      case TrainingFlowStage.monitoring:
        return 'Monitoreo';
    }
  }

  static TrainingFlowStage fromRaw(String? raw) {
    for (final stage in TrainingFlowStage.values) {
      if (stage.name == raw) return stage;
    }
    return TrainingFlowStage.interview;
  }

  static TrainingFlowStage min(TrainingFlowStage a, TrainingFlowStage b) {
    return a.order <= b.order ? a : b;
  }
}
