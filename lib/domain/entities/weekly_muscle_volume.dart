import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/muscle_volume_buckets.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';

class WeeklyMuscleVolume {
  final int weekIndex;
  final TrainingPhase phase;

  /// Volumen por músculo
  final Map<MuscleGroup, MuscleVolumeBuckets> muscles;

  const WeeklyMuscleVolume({
    required this.weekIndex,
    required this.phase,
    required this.muscles,
  });
}
