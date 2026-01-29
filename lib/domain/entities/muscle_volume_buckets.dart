import 'package:freezed_annotation/freezed_annotation.dart';

part '../../muscle_volume_buckets.freezed.dart';

@freezed
abstract class MuscleVolumeBuckets with _$MuscleVolumeBuckets {
  const factory MuscleVolumeBuckets({
    required double heavySets,
    required double mediumSets,
    required double lightSets,
  }) = _MuscleVolumeBuckets;
}
