import 'package:freezed_annotation/freezed_annotation.dart';

import 'volume_landmarks.dart';
import 'weekly_muscle_metrics.dart';

part 'muscle_progression_tracker.freezed.dart';
part 'muscle_progression_tracker.g.dart';

@freezed
abstract class MuscleProgressionTracker with _$MuscleProgressionTracker {
  const factory MuscleProgressionTracker({
    required String muscle,
    required int priority,
    required VolumeLandmarks landmarks,
    required int currentVolume,
    required ProgressionPhase currentPhase,
    required int weekInCurrentPhase,
    required int totalWeeksInCycle,
    int? vmrDiscovered,
    @Default([]) List<WeeklyMuscleMetrics> history,
    @Default([]) List<PhaseTransition> phaseTimeline,
    required DateTime lastUpdated,
  }) = _MuscleProgressionTracker;

  factory MuscleProgressionTracker.fromJson(Map<String, dynamic> json) =>
      _$MuscleProgressionTrackerFromJson(json);

  factory MuscleProgressionTracker.initialize({
    required String muscle,
    required int priority,
    required VolumeLandmarks landmarks,
  }) {
    return MuscleProgressionTracker(
      muscle: muscle,
      priority: priority,
      landmarks: landmarks,
      currentVolume: landmarks.vop,
      currentPhase: priority == 1
          ? ProgressionPhase.maintaining
          : ProgressionPhase.discovering,
      weekInCurrentPhase: 0,
      totalWeeksInCycle: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

enum ProgressionPhase {
  discovering,
  maintaining,
  overreaching,
  deloading,
  microdeload,
}

@freezed
abstract class PhaseTransition with _$PhaseTransition {
  const factory PhaseTransition({
    required int weekNumber,
    required ProgressionPhase fromPhase,
    required ProgressionPhase toPhase,
    required int volume,
    required String reason,
    required DateTime timestamp,
  }) = _PhaseTransition;

  factory PhaseTransition.fromJson(Map<String, dynamic> json) =>
      _$PhaseTransitionFromJson(json);
}
