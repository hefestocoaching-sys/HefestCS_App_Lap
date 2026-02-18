// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProgressRecord _$ProgressRecordFromJson(Map<String, dynamic> json) =>
    _ProgressRecord(
      userId: json['userId'] as String,
      muscle: json['muscle'] as String,
      weekNumber: (json['weekNumber'] as num).toInt(),
      volumePrescribed: (json['volumePrescribed'] as num).toInt(),
      volumePerformed: (json['volumePerformed'] as num).toInt(),
      volumeAdherence: (json['volumeAdherence'] as num).toDouble(),
      ripRange: (json['ripRange'] as num).toInt(),
      ripTarget: (json['ripTarget'] as num).toInt(),
      muscleActivation: (json['muscleActivation'] as num).toDouble(),
      pumpQuality: (json['pumpQuality'] as num).toDouble(),
      fatigueLevel: (json['fatigueLevel'] as num).toDouble(),
      recoveryQuality: (json['recoveryQuality'] as num).toDouble(),
      hadPain: json['hadPain'] as bool,
      userComments: json['userComments'] as String,
      exerciseAngles: json['exerciseAngles'] as String,
      exerciseVariations: (json['exerciseVariations'] as num).toInt(),
      volumeAction: json['volumeAction'] as String,
      newVolume: (json['newVolume'] as num).toInt(),
      progressionPhase: json['progressionPhase'] as String,
      decisionReason: json['decisionReason'] as String,
      wasDeload: json['wasDeload'] as bool,
      deloadReason: json['deloadReason'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      coachNotes: json['coachNotes'] as String? ?? '',
      auditMetadata: json['auditMetadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ProgressRecordToJson(_ProgressRecord instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'muscle': instance.muscle,
      'weekNumber': instance.weekNumber,
      'volumePrescribed': instance.volumePrescribed,
      'volumePerformed': instance.volumePerformed,
      'volumeAdherence': instance.volumeAdherence,
      'ripRange': instance.ripRange,
      'ripTarget': instance.ripTarget,
      'muscleActivation': instance.muscleActivation,
      'pumpQuality': instance.pumpQuality,
      'fatigueLevel': instance.fatigueLevel,
      'recoveryQuality': instance.recoveryQuality,
      'hadPain': instance.hadPain,
      'userComments': instance.userComments,
      'exerciseAngles': instance.exerciseAngles,
      'exerciseVariations': instance.exerciseVariations,
      'volumeAction': instance.volumeAction,
      'newVolume': instance.newVolume,
      'progressionPhase': instance.progressionPhase,
      'decisionReason': instance.decisionReason,
      'wasDeload': instance.wasDeload,
      'deloadReason': instance.deloadReason,
      'recordedAt': instance.recordedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'coachNotes': instance.coachNotes,
      'auditMetadata': instance.auditMetadata,
    };
