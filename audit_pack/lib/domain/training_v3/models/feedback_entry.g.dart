// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedbackEntry _$FeedbackEntryFromJson(Map<String, dynamic> json) =>
    _FeedbackEntry(
      userId: json['userId'] as String,
      muscle: json['muscle'] as String,
      weekNumber: (json['weekNumber'] as num).toInt(),
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      muscleActivation: (json['muscleActivation'] as num).toDouble(),
      pumpQuality: (json['pumpQuality'] as num).toDouble(),
      fatigueLevel: (json['fatigueLevel'] as num).toDouble(),
      recoveryQuality: (json['recoveryQuality'] as num).toDouble(),
      hadPain: json['hadPain'] as bool,
      deloadRequested: json['deloadRequested'] as bool,
      isInjury: json['isInjury'] as bool? ?? false,
      userComments: json['userComments'] as String,
      coachFeedback: json['coachFeedback'] as String? ?? '',
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      coachReviewedAt: json['coachReviewedAt'] == null
          ? null
          : DateTime.parse(json['coachReviewedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$FeedbackEntryToJson(_FeedbackEntry instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'muscle': instance.muscle,
      'weekNumber': instance.weekNumber,
      'weekStart': instance.weekStart.toIso8601String(),
      'weekEnd': instance.weekEnd.toIso8601String(),
      'muscleActivation': instance.muscleActivation,
      'pumpQuality': instance.pumpQuality,
      'fatigueLevel': instance.fatigueLevel,
      'recoveryQuality': instance.recoveryQuality,
      'hadPain': instance.hadPain,
      'deloadRequested': instance.deloadRequested,
      'isInjury': instance.isInjury,
      'userComments': instance.userComments,
      'coachFeedback': instance.coachFeedback,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'coachReviewedAt': instance.coachReviewedAt?.toIso8601String(),
      'metadata': instance.metadata,
    };
