import 'dart:math';

import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

class MusclePriorityEngine {
  static const Set<String> _upperMuscles = {
    'pectorals',
    'chest',
    'lats',
    'upper_back',
    'traps',
    'deltoide_anterior',
    'deltoide_lateral',
    'deltoide_posterior',
    'biceps',
    'triceps',
    'abs',
  };

  static const Set<String> _lowerMuscles = {
    'quads',
    'quadriceps',
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
    final normalizedPriorities = <String, int>{
      for (final entry in musclePriorities.entries)
        normalizeMuscleKey(entry.key): entry.value,
    };

    final normalizedFrequency = <String, int>{
      for (final entry in frequencyByMuscle.entries)
        normalizeMuscleKey(entry.key): max(1, entry.value),
    };

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
