import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/rep_structure_engine.dart';

class SessionIntensitySetAllocator {
  static List<int> allocateTwoSlots({
    required int totalSets,
    required RepRange firstRepRange,
    required RepRange secondRepRange,
    required String firstZone,
    required String secondZone,
    required bool preferFrontLoaded,
  }) {
    if (totalSets <= 3) return [totalSets];

    // Base deterministic mapping requested by spec.
    List<int> mapped;
    switch (totalSets) {
      case 4:
        mapped = [2, 2];
        break;
      case 5:
        mapped = [3, 2];
        break;
      case 6:
        mapped = [4, 2];
        break;
      case 7:
        mapped = [4, 3];
        break;
      case 8:
        mapped = [5, 3];
        break;
      case 9:
        mapped = [5, 4];
        break;
      default:
        final front = (totalSets / 2).ceil();
        final back = totalSets - front;
        mapped = [front, back];
    }

    if (totalSets >= 10) {
      // Keep slot1 >= slot2 and avoid excessive asymmetry.
      final diff = mapped[0] - mapped[1];
      if (diff > 2) {
        final adjust = (diff - 2 + 1) ~/ 2;
        mapped = [mapped[0] - adjust, mapped[1] + adjust];
      }
      if (mapped[0] < mapped[1]) {
        mapped = [mapped[1], mapped[0]];
      }
    }

    // Heavy/medium forward bias for slot1 when requested.
    final firstIsFrontBiased =
        firstZone == IntensityZone.heavy || firstZone == IntensityZone.medium;
    final secondIsFrontBiased =
        secondZone == IntensityZone.heavy || secondZone == IntensityZone.medium;

    if (!preferFrontLoaded && secondIsFrontBiased && !firstIsFrontBiased) {
      mapped = [mapped[1], mapped[0]];
    }

    // If first slot is lighter than second and counts are tied, nudge to second.
    final firstLight =
        firstRepRange.min >= 16 || firstZone == IntensityZone.light;
    final secondHeavy =
        secondRepRange.max <= 8 || secondZone == IntensityZone.heavy;
    if (mapped[0] == mapped[1] && firstLight && secondHeavy && mapped[0] > 1) {
      mapped = [mapped[0] - 1, mapped[1] + 1];
    }

    return mapped;
  }
}
