import 'package:freezed_annotation/freezed_annotation.dart';

import 'muscle_progression_tracker.dart';

part 'muscle_decision.freezed.dart';
part 'muscle_decision.g.dart';

@freezed
abstract class MuscleDecision with _$MuscleDecision {
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

  factory MuscleDecision.fromJson(Map<String, dynamic> json) =>
      _$MuscleDecisionFromJson(json);
}

/// Helpers para MuscleDecision
extension MuscleDecisionHelpers on MuscleDecision {
  /// Crea una decision de "no cambio"
  static MuscleDecision noChange({
    required String muscle,
    required String reason,
  }) {
    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.maintain,
      newVolume: 0,
      newPhase: ProgressionPhase.maintaining,
      reason: reason,
      confidence: 1.0,
    );
  }
}

enum VolumeAction { increase, maintain, decrease, deload, microdeload, adjust }

@freezed
abstract class ExerciseReplacement with _$ExerciseReplacement {
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
