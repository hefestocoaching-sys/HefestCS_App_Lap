// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_angle_coverage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseAngleCoverage _$ExerciseAngleCoverageFromJson(
  Map<String, dynamic> json,
) => _ExerciseAngleCoverage(
  userId: json['userId'] as String,
  muscle: json['muscle'] as String,
  weekNumber: (json['weekNumber'] as num).toInt(),
  cycleId: json['cycleId'] as String,
  angleExerciseMap: (json['angleExerciseMap'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
  coverageRatio: (json['coverageRatio'] as num).toDouble(),
  knownAngles:
      (json['knownAngles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  coveredAngles:
      (json['coveredAngles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  missingAngles:
      (json['missingAngles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  changedFromLastWeek: json['changedFromLastWeek'] as bool,
  recordedAt: DateTime.parse(json['recordedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ExerciseAngleCoverageToJson(
  _ExerciseAngleCoverage instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'muscle': instance.muscle,
  'weekNumber': instance.weekNumber,
  'cycleId': instance.cycleId,
  'angleExerciseMap': instance.angleExerciseMap,
  'coverageRatio': instance.coverageRatio,
  'knownAngles': instance.knownAngles,
  'coveredAngles': instance.coveredAngles,
  'missingAngles': instance.missingAngles,
  'changedFromLastWeek': instance.changedFromLastWeek,
  'recordedAt': instance.recordedAt.toIso8601String(),
  'metadata': instance.metadata,
};
