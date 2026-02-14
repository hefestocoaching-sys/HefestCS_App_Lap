// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_decision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MuscleDecision _$MuscleDecisionFromJson(Map<String, dynamic> json) =>
    _MuscleDecision(
      muscle: json['muscle'] as String,
      action: $enumDecode(_$VolumeActionEnumMap, json['action']),
      newVolume: (json['newVolume'] as num).toInt(),
      newPhase: $enumDecode(_$ProgressionPhaseEnumMap, json['newPhase']),
      reason: json['reason'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      requiresMicrodeload: json['requiresMicrodeload'] as bool? ?? false,
      weeksToMicrodeload: (json['weeksToMicrodeload'] as num?)?.toInt(),
      vmrDiscovered: (json['vmrDiscovered'] as num?)?.toInt(),
      isNewCycle: json['isNewCycle'] as bool? ?? false,
      exercisesToReplace:
          (json['exercisesToReplace'] as List<dynamic>?)
              ?.map(
                (e) => ExerciseReplacement.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MuscleDecisionToJson(_MuscleDecision instance) =>
    <String, dynamic>{
      'muscle': instance.muscle,
      'action': _$VolumeActionEnumMap[instance.action]!,
      'newVolume': instance.newVolume,
      'newPhase': _$ProgressionPhaseEnumMap[instance.newPhase]!,
      'reason': instance.reason,
      'confidence': instance.confidence,
      'requiresMicrodeload': instance.requiresMicrodeload,
      'weeksToMicrodeload': instance.weeksToMicrodeload,
      'vmrDiscovered': instance.vmrDiscovered,
      'isNewCycle': instance.isNewCycle,
      'exercisesToReplace': instance.exercisesToReplace,
    };

const _$VolumeActionEnumMap = {
  VolumeAction.increase: 'increase',
  VolumeAction.maintain: 'maintain',
  VolumeAction.decrease: 'decrease',
  VolumeAction.deload: 'deload',
  VolumeAction.microdeload: 'microdeload',
  VolumeAction.adjust: 'adjust',
};

const _$ProgressionPhaseEnumMap = {
  ProgressionPhase.discovering: 'discovering',
  ProgressionPhase.maintaining: 'maintaining',
  ProgressionPhase.overreaching: 'overreaching',
  ProgressionPhase.deloading: 'deloading',
  ProgressionPhase.microdeload: 'microdeload',
};

_ExerciseReplacement _$ExerciseReplacementFromJson(Map<String, dynamic> json) =>
    _ExerciseReplacement(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      reason: json['reason'] as String,
      muscleActivation: (json['muscleActivation'] as num).toDouble(),
      hadDiscomfort: json['hadDiscomfort'] as bool? ?? false,
    );

Map<String, dynamic> _$ExerciseReplacementToJson(
  _ExerciseReplacement instance,
) => <String, dynamic>{
  'exerciseId': instance.exerciseId,
  'exerciseName': instance.exerciseName,
  'reason': instance.reason,
  'muscleActivation': instance.muscleActivation,
  'hadDiscomfort': instance.hadDiscomfort,
};
