import 'dart:math';

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
  static Map<String, IntensityDistribution> buildWeeklyTargets({
    required Map<String, int> weeklySetsByMuscle,
    required Map<String, double> intensitySplitPercent,
  }) {
    return {
      for (final entry in weeklySetsByMuscle.entries)
        entry.key: splitWeeklySets(
          weeklySets: entry.value,
          intensitySplitPercent: intensitySplitPercent,
        ),
    };
  }

  static IntensityDistribution splitWeeklySets({
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

    return IntensityDistribution(
      heavySets: heavy,
      mediumSets: medium,
      lightSets: light,
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
}
