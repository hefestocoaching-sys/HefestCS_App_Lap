import 'package:freezed_annotation/freezed_annotation.dart';

import 'exercise_feedback.dart';

part 'weekly_muscle_analysis.freezed.dart';
part 'weekly_muscle_analysis.g.dart';

/// Weekly analysis combining objective and subjective data for a muscle.
@freezed
class WeeklyMuscleAnalysis with _$WeeklyMuscleAnalysis {
  const factory WeeklyMuscleAnalysis({
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required int prescribedSets,
    required int completedSets,
    required double volumeAdherence,
    required double averageLoad,
    required double previousLoad,
    required double loadChange,
    required double averageReps,
    required double previousReps,
    required double averageRir,
    required int prescribedRir,
    required double rirDeviation,
    required double averageRpe,
    required double muscleActivation,
    required double pumpQuality,
    required double fatigueLevel,
    required double recoveryQuality,
    @Default(false) bool hadPain,
    double? painSeverity,
    String? painDescription,
    @Default([]) List<ExerciseFeedback> exerciseFeedback,
  }) = _WeeklyMuscleAnalysis;

  factory WeeklyMuscleAnalysis.fromJson(Map<String, dynamic> json) =>
      _$WeeklyMuscleAnalysisFromJson(json);
}
