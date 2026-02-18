// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingAuditLogEntry _$TrainingAuditLogEntryFromJson(
  Map<String, dynamic> json,
) => _TrainingAuditLogEntry(
  userId: json['userId'] as String,
  eventType: json['eventType'] as String,
  muscleAffected: json['muscleAffected'] as String? ?? null,
  weekNumber: (json['weekNumber'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  severity: json['severity'] as String,
  volumeBefore: (json['volumeBefore'] as num?)?.toInt() ?? null,
  volumeAfter: (json['volumeAfter'] as num?)?.toInt() ?? null,
  decisionReason: json['decisionReason'] as String? ?? null,
  feedbackContext: json['feedbackContext'] as String? ?? null,
  actorType: json['actorType'] as String,
  actorDetails: json['actorDetails'] as String? ?? '',
  isValid: json['isValid'] as bool,
  validationErrors:
      (json['validationErrors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  timestamp: DateTime.parse(json['timestamp'] as String),
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  linkedToProgressRecordId: json['linkedToProgressRecordId'] as String? ?? null,
  linkedToFeedbackEntryId: json['linkedToFeedbackEntryId'] as String? ?? null,
  linkedToPreviousLogId: json['linkedToPreviousLogId'] as String? ?? null,
);

Map<String, dynamic> _$TrainingAuditLogEntryToJson(
  _TrainingAuditLogEntry instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'eventType': instance.eventType,
  'muscleAffected': instance.muscleAffected,
  'weekNumber': instance.weekNumber,
  'title': instance.title,
  'description': instance.description,
  'severity': instance.severity,
  'volumeBefore': instance.volumeBefore,
  'volumeAfter': instance.volumeAfter,
  'decisionReason': instance.decisionReason,
  'feedbackContext': instance.feedbackContext,
  'actorType': instance.actorType,
  'actorDetails': instance.actorDetails,
  'isValid': instance.isValid,
  'validationErrors': instance.validationErrors,
  'timestamp': instance.timestamp.toIso8601String(),
  'metadata': instance.metadata,
  'linkedToProgressRecordId': instance.linkedToProgressRecordId,
  'linkedToFeedbackEntryId': instance.linkedToFeedbackEntryId,
  'linkedToPreviousLogId': instance.linkedToPreviousLogId,
};
