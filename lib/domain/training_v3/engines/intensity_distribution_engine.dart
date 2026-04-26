import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_intensity_policy.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

class IntensityDistribution {
  final int heavySets;
  final int mediumSets;
  final int lightSets;

  const IntensityDistribution({
    required this.heavySets,
    required this.mediumSets,
    required this.lightSets,
  });

  int get totalSets => heavySets + mediumSets + lightSets;
}

class IntensityDistributionEngine {
  static ({int min, int max}) repRangeForZone(String zone) {
    switch (zone.trim().toLowerCase()) {
      case 'heavy':
        return (min: 6, max: 8);
      case 'medium':
        return (min: 8, max: 12);
      case 'light':
        return (min: 15, max: 20);
      default:
        throw ArgumentError('Zona de intensidad inválida: $zone');
    }
  }

  static Map<String, IntensityDistribution> buildWeeklyTargets({
    required Map<String, int> weeklySetsByMuscle,
    required Map<String, double> intensitySplitPercent,
  }) {
    return {
      for (final entry in weeklySetsByMuscle.entries)
        entry.key: splitWeeklySets(
          muscleKey: entry.key,
          weeklySets: entry.value,
          intensitySplitPercent: intensitySplitPercent,
        ),
    };
  }

  static IntensityDistribution splitWeeklySets({
    String? muscleKey,
    required int weeklySets,
    required Map<String, double> intensitySplitPercent,
  }) {
    if (weeklySets <= 0) {
      return const IntensityDistribution(
        heavySets: 0,
        mediumSets: 0,
        lightSets: 0,
      );
    }

    final normalized = _normalizedSplit(intensitySplitPercent);
    final rawHeavy = weeklySets * (normalized['heavy'] ?? 0) / 100.0;
    final rawMedium = weeklySets * (normalized['medium'] ?? 0) / 100.0;
    final rawLight = weeklySets * (normalized['light'] ?? 0) / 100.0;

    int heavy = rawHeavy.floor();
    int medium = rawMedium.floor();
    int light = rawLight.floor();

    var assigned = heavy + medium + light;
    final fractions = <MapEntry<String, double>>[
      MapEntry('heavy', rawHeavy - heavy),
      MapEntry('medium', rawMedium - medium),
      MapEntry('light', rawLight - light),
    ]..sort((a, b) => b.value.compareTo(a.value));

    var cursor = 0;
    while (assigned < weeklySets) {
      final key = fractions[cursor % fractions.length].key;
      if (key == 'heavy') {
        heavy++;
      } else if (key == 'medium') {
        medium++;
      } else {
        light++;
      }
      assigned++;
      cursor++;
    }

    final originalDistribution = IntensityDistribution(
      heavySets: heavy,
      mediumSets: medium,
      lightSets: light,
    );

    if (muscleKey == null || muscleKey.trim().isEmpty) {
      return originalDistribution;
    }

    return _applyMusclePolicy(
      muscleKey: muscleKey,
      originalDistribution: originalDistribution,
    );
  }

  static Map<int, IntensityDistribution> distributeAcrossAppearances({
    required IntensityDistribution weeklyTarget,
    required List<int> setsByAppearance,
  }) {
    final appearanceCount = setsByAppearance.length;
    if (appearanceCount == 0) return const <int, IntensityDistribution>{};

    final remainingCapacity = List<int>.from(setsByAppearance);
    final heavyByDay = List<int>.filled(appearanceCount, 0);
    final mediumByDay = List<int>.filled(appearanceCount, 0);
    final lightByDay = List<int>.filled(appearanceCount, 0);

    final forwardOrder = List<int>.generate(appearanceCount, (i) => i);
    final backwardOrder = List<int>.generate(
      appearanceCount,
      (i) => appearanceCount - 1 - i,
    );
    final middleOrder = appearanceCount <= 2
        ? <int>[]
        : List<int>.generate(appearanceCount - 2, (i) => i + 1);

    var heavyRemaining = _assignByPriority(
      heavyByDay,
      remainingCapacity,
      weeklyTarget.heavySets,
      forwardOrder,
    );

    var lightRemaining = _assignByPriority(
      lightByDay,
      remainingCapacity,
      weeklyTarget.lightSets,
      backwardOrder,
    );

    var mediumRemaining = _assignByPriority(
      mediumByDay,
      remainingCapacity,
      weeklyTarget.mediumSets,
      middleOrder,
    );

    // If there are not enough middle appearances/capacity, finish in any
    // remaining day while still respecting per-appearance capacity.
    mediumRemaining = _assignByPriority(
      mediumByDay,
      remainingCapacity,
      mediumRemaining,
      forwardOrder,
    );

    // Preserve total assigned sets by respecting the original capacities.
    // In pathological mismatches between weekly target and capacity, any
    // unresolved remainder is folded into medium where capacity exists.
    final unresolved = heavyRemaining + lightRemaining + mediumRemaining;
    _assignByPriority(mediumByDay, remainingCapacity, unresolved, forwardOrder);

    return {
      for (var i = 0; i < appearanceCount; i++)
        i + 1: IntensityDistribution(
          heavySets: heavyByDay[i],
          mediumSets: mediumByDay[i],
          lightSets: lightByDay[i],
        ),
    };
  }

  static (String, String) zonesForDay(IntensityDistribution dayDistribution) {
    final weighted = <MapEntry<String, int>>[
      MapEntry('heavy', dayDistribution.heavySets),
      MapEntry('medium', dayDistribution.mediumSets),
      MapEntry('light', dayDistribution.lightSets),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final first = weighted.firstWhere(
      (entry) => entry.value > 0,
      orElse: () => const MapEntry('medium', 1),
    );
    final second = weighted.firstWhere(
      (entry) => entry.value > 0 && entry.key != first.key,
      orElse: () => first,
    );

    return (first.key, second.key);
  }

  static int _assignByPriority(
    List<int> targetByDay,
    List<int> remainingCapacity,
    int setsToAssign,
    List<int> priorityDays,
  ) {
    var remaining = setsToAssign;
    if (remaining <= 0 || priorityDays.isEmpty) return remaining;

    for (final day in priorityDays) {
      if (remaining <= 0) break;
      final assigned = min(remainingCapacity[day], remaining);
      if (assigned <= 0) continue;
      targetByDay[day] += assigned;
      remainingCapacity[day] -= assigned;
      remaining -= assigned;
    }

    return remaining;
  }

  static Map<String, double> _normalizedSplit(Map<String, double> raw) {
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

  static IntensityDistribution _applyMusclePolicy({
    required String muscleKey,
    required IntensityDistribution originalDistribution,
  }) {
    final allowedZones = MuscleIntensityPolicy.allowedZonesForMuscle(muscleKey);
    final original = <String, int>{
      'heavy': originalDistribution.heavySets,
      'medium': originalDistribution.mediumSets,
      'light': originalDistribution.lightSets,
    };
    final adjusted = Map<String, int>.from(original);
    final removedZones = <String>[];
    var reason = 'policy_ok';

    void moveZone(String fromZone, List<String> targets) {
      final amount = adjusted[fromZone] ?? 0;
      if (amount <= 0) {
        adjusted[fromZone] = 0;
        return;
      }

      final targetZone = targets.firstWhere(
        allowedZones.contains,
        orElse: () => targets.first,
      );
      if (!allowedZones.contains(targetZone)) {
        return;
      }

      adjusted[fromZone] = 0;
      adjusted[targetZone] = (adjusted[targetZone] ?? 0) + amount;
      removedZones.add(fromZone);
    }

    if (!allowedZones.contains('heavy')) {
      moveZone('heavy', const ['medium', 'light']);
      reason = 'policy_disallows_heavy';
    }
    if (!allowedZones.contains('medium')) {
      moveZone('medium', const ['heavy', 'light']);
      reason = reason == 'policy_disallows_heavy'
          ? 'policy_disallows_heavy_medium'
          : 'policy_disallows_medium';
    }
    if (!allowedZones.contains('light')) {
      moveZone('light', const ['medium', 'heavy']);
      reason = reason == 'policy_ok' ? 'policy_disallows_light' : reason;
    }

    final adjustedDistribution = IntensityDistribution(
      heavySets: adjusted['heavy'] ?? 0,
      mediumSets: adjusted['medium'] ?? 0,
      lightSets: adjusted['light'] ?? 0,
    );

    if (adjustedDistribution.totalSets != originalDistribution.totalSets) {
      final total = originalDistribution.totalSets;
      debugPrint(
        '[V3][INTENSITY_POLICY_WARN] muscle=$muscleKey totalMismatch original=$original adjusted=$adjusted total=$total',
      );
    }

    if (adjustedDistribution.heavySets != originalDistribution.heavySets ||
        adjustedDistribution.mediumSets != originalDistribution.mediumSets ||
        adjustedDistribution.lightSets != originalDistribution.lightSets) {
      debugPrint(
        '[V3][INTENSITY_POLICY_TRACE] muscle=$muscleKey original=$original adjusted={heavy:${adjustedDistribution.heavySets}, medium:${adjustedDistribution.mediumSets}, light:${adjustedDistribution.lightSets}} removedZones=$removedZones reason=$reason',
      );
    }

    final catalogZones = <String>{};
    for (final exercise in ExerciseCatalogV3.getByMuscle(muscleKey)) {
      for (final zone in MuscleIntensityPolicy.allZones) {
        if (ExerciseCatalogV3.allowsZone(exercise.id, zone)) {
          catalogZones.add(zone);
        }
      }
    }
    final intersection = catalogZones.intersection(allowedZones);
    if (intersection.isEmpty &&
        ExerciseCatalogV3.getByMuscle(muscleKey).isNotEmpty) {
      debugPrint(
        '[V3][INTENSITY_POLICY_WARN] muscle=$muscleKey policyZones=$allowedZones catalogZones=$catalogZones reason=no_intersection_with_catalog',
      );
    }

    return adjustedDistribution;
  }
}
