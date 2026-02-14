// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_muscle_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyMuscleAnalysis _$WeeklyMuscleAnalysisFromJson(
  Map<String, dynamic> json,
) => _WeeklyMuscleAnalysis(
  muscle: json['muscle'] as String,
  weekNumber: (json['weekNumber'] as num).toInt(),
  weekStart: DateTime.parse(json['weekStart'] as String),
  weekEnd: DateTime.parse(json['weekEnd'] as String),
  prescribedSets: (json['prescribedSets'] as num).toInt(),
  completedSets: (json['completedSets'] as num).toInt(),
  volumeAdherence: (json['volumeAdherence'] as num).toDouble(),
  averageLoad: (json['averageLoad'] as num).toDouble(),
  previousLoad: (json['previousLoad'] as num).toDouble(),
  loadChange: (json['loadChange'] as num).toDouble(),
  averageReps: (json['averageReps'] as num).toDouble(),
  previousReps: (json['previousReps'] as num).toDouble(),
  averageRir: (json['averageRir'] as num).toDouble(),
  prescribedRir: (json['prescribedRir'] as num).toInt(),
  rirDeviation: (json['rirDeviation'] as num).toDouble(),
  averageRpe: (json['averageRpe'] as num).toDouble(),
  muscleActivation: (json['muscleActivation'] as num).toDouble(),
  pumpQuality: (json['pumpQuality'] as num).toDouble(),
  fatigueLevel: (json['fatigueLevel'] as num).toDouble(),
  recoveryQuality: (json['recoveryQuality'] as num).toDouble(),
  hadPain: json['hadPain'] as bool? ?? false,
  painSeverity: (json['painSeverity'] as num?)?.toDouble(),
  painDescription: json['painDescription'] as String?,
  exerciseFeedback:
      (json['exerciseFeedback'] as List<dynamic>?)
          ?.map((e) => ExerciseFeedback.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WeeklyMuscleAnalysisToJson(
  _WeeklyMuscleAnalysis instance,
) => <String, dynamic>{
  'muscle': instance.muscle,
  'weekNumber': instance.weekNumber,
  'weekStart': instance.weekStart.toIso8601String(),
  'weekEnd': instance.weekEnd.toIso8601String(),
  'prescribedSets': instance.prescribedSets,
  'completedSets': instance.completedSets,
  'volumeAdherence': instance.volumeAdherence,
  'averageLoad': instance.averageLoad,
  'previousLoad': instance.previousLoad,
  'loadChange': instance.loadChange,
  'averageReps': instance.averageReps,
  'previousReps': instance.previousReps,
  'averageRir': instance.averageRir,
  'prescribedRir': instance.prescribedRir,
  'rirDeviation': instance.rirDeviation,
  'averageRpe': instance.averageRpe,
  'muscleActivation': instance.muscleActivation,
  'pumpQuality': instance.pumpQuality,
  'fatigueLevel': instance.fatigueLevel,
  'recoveryQuality': instance.recoveryQuality,
  'hadPain': instance.hadPain,
  'painSeverity': instance.painSeverity,
  'painDescription': instance.painDescription,
  'exerciseFeedback': instance.exerciseFeedback,
};
