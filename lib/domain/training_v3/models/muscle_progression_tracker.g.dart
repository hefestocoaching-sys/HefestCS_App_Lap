// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_progression_tracker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MuscleProgressionTracker _$MuscleProgressionTrackerFromJson(
  Map<String, dynamic> json,
) => _MuscleProgressionTracker(
  muscle: json['muscle'] as String,
  priority: (json['priority'] as num).toInt(),
  landmarks: VolumeLandmarks.fromJson(
    json['landmarks'] as Map<String, dynamic>,
  ),
  currentVolume: (json['currentVolume'] as num).toInt(),
  currentPhase: $enumDecode(_$ProgressionPhaseEnumMap, json['currentPhase']),
  weekInCurrentPhase: (json['weekInCurrentPhase'] as num).toInt(),
  totalWeeksInCycle: (json['totalWeeksInCycle'] as num).toInt(),
  vmrDiscovered: (json['vmrDiscovered'] as num?)?.toInt(),
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => WeeklyMuscleMetrics.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  phaseTimeline:
      (json['phaseTimeline'] as List<dynamic>?)
          ?.map((e) => PhaseTransition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$MuscleProgressionTrackerToJson(
  _MuscleProgressionTracker instance,
) => <String, dynamic>{
  'muscle': instance.muscle,
  'priority': instance.priority,
  'landmarks': instance.landmarks,
  'currentVolume': instance.currentVolume,
  'currentPhase': _$ProgressionPhaseEnumMap[instance.currentPhase]!,
  'weekInCurrentPhase': instance.weekInCurrentPhase,
  'totalWeeksInCycle': instance.totalWeeksInCycle,
  'vmrDiscovered': instance.vmrDiscovered,
  'history': instance.history,
  'phaseTimeline': instance.phaseTimeline,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};

const _$ProgressionPhaseEnumMap = {
  ProgressionPhase.discovering: 'discovering',
  ProgressionPhase.maintaining: 'maintaining',
  ProgressionPhase.overreaching: 'overreaching',
  ProgressionPhase.deloading: 'deloading',
  ProgressionPhase.microdeload: 'microdeload',
};

_PhaseTransition _$PhaseTransitionFromJson(Map<String, dynamic> json) =>
    _PhaseTransition(
      weekNumber: (json['weekNumber'] as num).toInt(),
      fromPhase: $enumDecode(_$ProgressionPhaseEnumMap, json['fromPhase']),
      toPhase: $enumDecode(_$ProgressionPhaseEnumMap, json['toPhase']),
      volume: (json['volume'] as num).toInt(),
      reason: json['reason'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$PhaseTransitionToJson(_PhaseTransition instance) =>
    <String, dynamic>{
      'weekNumber': instance.weekNumber,
      'fromPhase': _$ProgressionPhaseEnumMap[instance.fromPhase]!,
      'toPhase': _$ProgressionPhaseEnumMap[instance.toPhase]!,
      'volume': instance.volume,
      'reason': instance.reason,
      'timestamp': instance.timestamp.toIso8601String(),
    };
