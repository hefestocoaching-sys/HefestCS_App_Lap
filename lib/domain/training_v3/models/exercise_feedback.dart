import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_feedback.freezed.dart';
part 'exercise_feedback.g.dart';

/// Feedback for a single exercise.
@freezed
class ExerciseFeedback with _$ExerciseFeedback {
  const factory ExerciseFeedback({
    required String exerciseId,
    required String exerciseName,
    required double muscleActivation,
    required double formQuality,
    required double difficulty,
    @Default(true) bool feltGood,
    @Default(false) bool hadDiscomfort,
    String? discomfortDescription,
    @Default(false) bool wantsReplacement,
    String? replacementReason,
  }) = _ExerciseFeedback;

  factory ExerciseFeedback.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFeedbackFromJson(json);
}
