import 'package:freezed_annotation/freezed_annotation.dart';

import 'muscle_progression_tracker.dart';

part 'muscle_decision.freezed.dart';
part 'muscle_decision.g.dart';

/// Weekly decision for a single muscle.
@freezed
class MuscleDecision with _$MuscleDecision {
  const factory MuscleDecision({
    required String muscle,
    required VolumeAction action,
    required int newVolume,
    required ProgressionPhase newPhase,
    required String reason,
    required double confidence,
    @Default(false) bool requiresMicrodeload,
    int? weeksToMicrodeload,
    int? vmrDiscovered,
    @Default(false) bool isNewCycle,
    @Default([]) List<ExerciseReplacement> exercisesToReplace,
  }) = _MuscleDecision;

  const factory MuscleDecision.noChange({
    required String muscle,
    required String reason,
  }) = _NoChangeMuscleDecision;

  factory MuscleDecision.fromJson(Map<String, dynamic> json) =>
      _$MuscleDecisionFromJson(json);
}

enum VolumeAction { increase, maintain, decrease, deload, microdeload, adjust }

@freezed
class ExerciseReplacement with _$ExerciseReplacement {
  const factory ExerciseReplacement({
    required String exerciseId,
    required String exerciseName,
    required String reason,
    required double muscleActivation,
    @Default(false) bool hadDiscomfort,
  }) = _ExerciseReplacement;

  factory ExerciseReplacement.fromJson(Map<String, dynamic> json) =>
      _$ExerciseReplacementFromJson(json);
}
