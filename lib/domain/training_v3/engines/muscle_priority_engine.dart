import 'dart:math';

import 'package:hcs_app_lap/core/registry/muscle_registry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

class MusclePriorityEngine {
  static const Set<String> _upperMuscles = {
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
    'abs',
  };

  static const Set<String> _lowerMuscles = {
    'quads',
    'hamstrings',
    'glutes',
    'calves',
  };

  /// Build deterministic muscle ordering per day.
  ///
  /// Priority rules:
  /// 1) primary rotate between sessions
  /// 2) secondary always after primaries
  /// 3) tertiary at the end
  static Map<int, List<String>> buildDayMuscleOrder({
    required TrainingSplit split,
    required int availableDays,
    required Map<String, int> musclePriorities,
    required Map<String, int> frequencyByMuscle,
  }) {
    final normalizedPriorities = _normalizeMuscleIntMap(musclePriorities);
    final normalizedFrequency = _normalizeMuscleIntMap(
      frequencyByMuscle,
      minValue: 1,
    );

    final allMuscles = normalizedPriorities.keys.toSet()
      ..addAll(normalizedFrequency.keys);

    final primary = <String>[];
    final secondary = <String>[];
    final tertiary = <String>[];

    for (final muscle in allMuscles) {
      final score = normalizedPriorities[muscle] ?? 1;
      if (score >= 4) {
        primary.add(muscle);
      } else if (score >= 2) {
        secondary.add(muscle);
      } else {
        tertiary.add(muscle);
      }
    }

    int compareByWeight(String a, String b) {
      final pA = normalizedPriorities[a] ?? 1;
      final pB = normalizedPriorities[b] ?? 1;
      if (pA != pB) return pB.compareTo(pA);
      final fA = normalizedFrequency[a] ?? 1;
      final fB = normalizedFrequency[b] ?? 1;
      if (fA != fB) return fB.compareTo(fA);
      return a.compareTo(b);
    }

    primary.sort(compareByWeight);
    secondary.sort(compareByWeight);
    tertiary.sort(compareByWeight);

    final out = <int, List<String>>{};

    for (var day = 1; day <= max(availableDays, 1); day++) {
      final rotatedPrimary = _rotate(primary, day - 1);
      final ordered = <String>[...rotatedPrimary, ...secondary, ...tertiary];
      out[day] = _filterBySplit(ordered, split: split, day: day);
    }

    return out;
  }

  static Map<String, int> _normalizeMuscleIntMap(
    Map<String, int> source, {
    int? minValue,
  }) {
    final out = <String, int>{};

    for (final entry in source.entries) {
      final canonical = tryNormalizeMuscleKey(entry.key);
      if (canonical == null) continue;
      out[canonical] = minValue == null
          ? entry.value
          : max(minValue, entry.value);
    }

    return out;
  }

  static List<String> _rotate(List<String> source, int offset) {
    if (source.length <= 1) return List<String>.from(source);
    final out = <String>[];
    for (var i = 0; i < source.length; i++) {
      out.add(source[(i + offset) % source.length]);
    }
    return out;
  }

  static List<String> _filterBySplit(
    List<String> source, {
    required TrainingSplit split,
    required int day,
  }) {
    if (split == TrainingSplit.fullBody ||
        split == TrainingSplit.pushPullLegs) {
      return source;
    }

    final isUpperDay = day.isOdd;
    return source.where((muscle) {
      if (isUpperDay) return _upperMuscles.contains(muscle);
      return _lowerMuscles.contains(muscle);
    }).toList();
  }
}
