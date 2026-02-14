import 'package:flutter/foundation.dart';

import '../models/volume_landmarks.dart';

/// Calculates volume landmarks per muscle.
class VolumeLandmarksCalculator {
  static Map<String, VolumeLandmarks> calculateForAllMuscles({
    required Map<String, int> musclePriorities,
    required String trainingLevel,
    required int age,
  }) {
    final landmarks = <String, VolumeLandmarks>{};

    for (final entry in musclePriorities.entries) {
      final muscle = entry.key;
      final priority = entry.value;

      landmarks[muscle] = VolumeLandmarks.calculate(
        muscle: muscle,
        priority: priority,
        trainingLevel: trainingLevel,
        age: age,
      );

      debugPrint('[LandmarksCalc] $muscle (P$priority):');
      debugPrint('  VME: ${landmarks[muscle]!.vme} sets');
      debugPrint('  VOP: ${landmarks[muscle]!.vop} sets');
      debugPrint('  VMR: ${landmarks[muscle]!.vmr} sets (100%)');
      debugPrint('  Target: ${landmarks[muscle]!.vmrTarget} sets');
    }

    return landmarks;
  }

  static int calculateInitialTotalVolume(
    Map<String, VolumeLandmarks> landmarks,
  ) {
    return landmarks.values.fold(0, (sum, lm) => sum + lm.vop);
  }

  static int calculateMaxTotalVolume(Map<String, VolumeLandmarks> landmarks) {
    return landmarks.values.fold(0, (sum, lm) => sum + lm.vmrTarget);
  }
}
