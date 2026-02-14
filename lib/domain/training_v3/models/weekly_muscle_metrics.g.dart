// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_muscle_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyMuscleMetrics _$WeeklyMuscleMetricsFromJson(Map<String, dynamic> json) =>
    _WeeklyMuscleMetrics(
      weekNumber: (json['weekNumber'] as num).toInt(),
      volume: (json['volume'] as num).toInt(),
      loadChange: (json['loadChange'] as num).toDouble(),
      rirDeviation: (json['rirDeviation'] as num).toDouble(),
      adherence: (json['adherence'] as num).toDouble(),
      recoveryQuality: (json['recoveryQuality'] as num).toDouble(),
      fatigueLevel: (json['fatigueLevel'] as num).toDouble(),
      muscleActivation: (json['muscleActivation'] as num).toDouble(),
      hadPain: json['hadPain'] as bool? ?? false,
      painSeverity: (json['painSeverity'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WeeklyMuscleMetricsToJson(
  _WeeklyMuscleMetrics instance,
) => <String, dynamic>{
  'weekNumber': instance.weekNumber,
  'volume': instance.volume,
  'loadChange': instance.loadChange,
  'rirDeviation': instance.rirDeviation,
  'adherence': instance.adherence,
  'recoveryQuality': instance.recoveryQuality,
  'fatigueLevel': instance.fatigueLevel,
  'muscleActivation': instance.muscleActivation,
  'hadPain': instance.hadPain,
  'painSeverity': instance.painSeverity,
};
