// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_progression.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MuscleProgression _$MuscleProgressionFromJson(Map<String, dynamic> json) =>
    _MuscleProgression(
      muscle: json['muscle'] as String,
      priority: (json['priority'] as num).toInt(),
      landmarks: VolumeLandmarks.fromJson(
        json['landmarks'] as Map<String, dynamic>,
      ),
      currentSets: (json['currentSets'] as num).toInt(),
      vopSets: (json['vopSets'] as num).toInt(),
      mrvSets: (json['mrvSets'] as num).toInt(),
      hasDiscoveredMRV: json['hasDiscoveredMRV'] as bool,
      currentPhase: json['currentPhase'] as String,
      weeksInCurrentPhase: (json['weeksInCurrentPhase'] as num).toInt(),
      totalWeeksInTraining: (json['totalWeeksInTraining'] as num).toInt(),
      weeksSinceDeload: (json['weeksSinceDeload'] as num).toInt(),
      weeksUntilAutoDeload: (json['weeksUntilAutoDeload'] as num).toInt(),
      isAutoDeloadScheduled: json['isAutoDeloadScheduled'] as bool,
      last4WeeksVolume:
          (json['last4WeeksVolume'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      last4WeeksAdherence:
          (json['last4WeeksAdherence'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      last4WeeksPhase:
          (json['last4WeeksPhase'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastDeloadDate: DateTime.parse(json['lastDeloadDate'] as String),
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$MuscleProgressionToJson(_MuscleProgression instance) =>
    <String, dynamic>{
      'muscle': instance.muscle,
      'priority': instance.priority,
      'landmarks': instance.landmarks,
      'currentSets': instance.currentSets,
      'vopSets': instance.vopSets,
      'mrvSets': instance.mrvSets,
      'hasDiscoveredMRV': instance.hasDiscoveredMRV,
      'currentPhase': instance.currentPhase,
      'weeksInCurrentPhase': instance.weeksInCurrentPhase,
      'totalWeeksInTraining': instance.totalWeeksInTraining,
      'weeksSinceDeload': instance.weeksSinceDeload,
      'weeksUntilAutoDeload': instance.weeksUntilAutoDeload,
      'isAutoDeloadScheduled': instance.isAutoDeloadScheduled,
      'last4WeeksVolume': instance.last4WeeksVolume,
      'last4WeeksAdherence': instance.last4WeeksAdherence,
      'last4WeeksPhase': instance.last4WeeksPhase,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'lastDeloadDate': instance.lastDeloadDate.toIso8601String(),
      'notes': instance.notes,
    };
