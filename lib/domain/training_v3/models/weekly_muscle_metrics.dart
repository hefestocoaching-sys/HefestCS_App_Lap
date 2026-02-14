import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_muscle_metrics.freezed.dart';
part 'weekly_muscle_metrics.g.dart';

@freezed
abstract class WeeklyMuscleMetrics with _$WeeklyMuscleMetrics {
  const factory WeeklyMuscleMetrics({
    required int weekNumber,
    required int volume,
    required double loadChange,
    required double rirDeviation,
    required double adherence,
    required double recoveryQuality,
    required double fatigueLevel,
    required double muscleActivation,
    @Default(false) bool hadPain,
    double? painSeverity,
  }) = _WeeklyMuscleMetrics;

  factory WeeklyMuscleMetrics.fromJson(Map<String, dynamic> json) =>
      _$WeeklyMuscleMetricsFromJson(json);
}
