// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseFeedback _$ExerciseFeedbackFromJson(Map<String, dynamic> json) =>
    _ExerciseFeedback(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      muscleActivation: (json['muscleActivation'] as num).toDouble(),
      formQuality: (json['formQuality'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      feltGood: json['feltGood'] as bool? ?? true,
      hadDiscomfort: json['hadDiscomfort'] as bool? ?? false,
      discomfortDescription: json['discomfortDescription'] as String?,
      wantsReplacement: json['wantsReplacement'] as bool? ?? false,
      replacementReason: json['replacementReason'] as String?,
    );

Map<String, dynamic> _$ExerciseFeedbackToJson(_ExerciseFeedback instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'muscleActivation': instance.muscleActivation,
      'formQuality': instance.formQuality,
      'difficulty': instance.difficulty,
      'feltGood': instance.feltGood,
      'hadDiscomfort': instance.hadDiscomfort,
      'discomfortDescription': instance.discomfortDescription,
      'wantsReplacement': instance.wantsReplacement,
      'replacementReason': instance.replacementReason,
    };
