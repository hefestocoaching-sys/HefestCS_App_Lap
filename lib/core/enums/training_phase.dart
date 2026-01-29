enum TrainingPhase { accumulation, intensification, deload }

extension TrainingPhaseX on TrainingPhase {
  bool get isAccumulation => this == TrainingPhase.accumulation;
  bool get isIntensification => this == TrainingPhase.intensification;
  bool get isDeload => this == TrainingPhase.deload;
}
