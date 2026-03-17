import 'dart:math';

import 'package:hcs_app_lap/domain/training_v3/models/muscle_progress_state.dart';

enum TrainingPhase { adaptation, accumulation, maintenance, regeneration }

class PhaseProgressionEngine {
  int resolveWeeklySets({
    required TrainingPhase phase,
    required MuscleProgressState state,
  }) {
    switch (phase) {
      case TrainingPhase.adaptation:
        return state.vop;
      case TrainingPhase.accumulation:
        if (state.localDeloadPending) {
          return max(state.vme, (state.currentSets * 0.7).round());
        }
        return min(state.mrv, state.currentSets + 1);
      case TrainingPhase.maintenance:
        return state.currentSets >= state.mrv ? state.currentSets : state.mrv;
      case TrainingPhase.regeneration:
        return max(state.vme, (state.currentSets * 0.6).round());
    }
  }
}
