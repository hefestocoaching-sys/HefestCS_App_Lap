import 'dart:math';

import 'package:flutter/foundation.dart';

class IntensitySessionPlan {
  final int heavySets;
  final int mediumSets;
  final int lightSets;
  final String primaryZone;
  final String secondaryZone;

  const IntensitySessionPlan({
    required this.heavySets,
    required this.mediumSets,
    required this.lightSets,
    required this.primaryZone,
    required this.secondaryZone,
  });
}

class IntensitySplitAllocator {
  IntensitySessionPlan allocateForSession({
    required String muscle,
    required int weeklySetsForMuscle,
    required int sessionSetsForMuscle,
    required int frequency,
    required int sessionIndex,
    required Map<String, double> intensitySplitPercent,
  }) {
    final split = _normalizedSplit(intensitySplitPercent);
    final zones = _zonesForSession(
      frequency: frequency,
      sessionIndex: sessionIndex,
    );

    final zoneA = zones.$1;
    final zoneB = zones.$2;

    int heavy = 0;
    int medium = 0;
    int light = 0;

    if (zoneA == zoneB) {
      switch (zoneA) {
        case 'heavy':
          heavy = sessionSetsForMuscle;
          break;
        case 'light':
          light = sessionSetsForMuscle;
          break;
        default:
          medium = sessionSetsForMuscle;
      }
    } else {
      final pA = max(1.0, split[zoneA] ?? 0.0);
      final pB = max(1.0, split[zoneB] ?? 0.0);
      final aSets = ((sessionSetsForMuscle * pA) / (pA + pB)).round();
      final bSets = max(0, sessionSetsForMuscle - aSets);

      for (final e in [MapEntry(zoneA, aSets), MapEntry(zoneB, bSets)]) {
        switch (e.key) {
          case 'heavy':
            heavy += e.value;
            break;
          case 'light':
            light += e.value;
            break;
          default:
            medium += e.value;
        }
      }
    }

    debugPrint(
      '[V3][INTENSITY_SESSION_PLAN] muscle=$muscle session=${sessionIndex + 1} '
      'heavy=$heavy medium=$medium light=$light weekly=$weeklySetsForMuscle',
    );

    return IntensitySessionPlan(
      heavySets: heavy,
      mediumSets: medium,
      lightSets: light,
      primaryZone: zoneA,
      secondaryZone: zoneB,
    );
  }

  (String, String) _zonesForSession({
    required int frequency,
    required int sessionIndex,
  }) {
    if (frequency <= 1) return ('medium', 'medium');

    if (frequency == 2) {
      if (sessionIndex == 0) return ('heavy', 'medium');
      return ('medium', 'light');
    }

    final mod = sessionIndex % 3;
    if (mod == 1) return ('medium', 'light');
    return ('medium', 'medium');
  }

  Map<String, double> _normalizedSplit(Map<String, double> raw) {
    final heavy = (raw['heavy'] ?? 20).toDouble().clamp(0, 100).toDouble();
    final medium = (raw['medium'] ?? 60).toDouble().clamp(0, 100).toDouble();
    final light = (raw['light'] ?? 20).toDouble().clamp(0, 100).toDouble();

    final total = heavy + medium + light;
    if (total <= 0) {
      return const {'heavy': 20, 'medium': 60, 'light': 20};
    }

    return {
      'heavy': (heavy * 100.0) / total,
      'medium': (medium * 100.0) / total,
      'light': (light * 100.0) / total,
    };
  }
}
