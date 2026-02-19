import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_ordering_rules.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

/// Builds the template for the training cycle (Frozen Week 1).
///
/// Implements P0 Rules:
/// 1. Frequency based on volume (<=10->1x, 11-20->2x, >=21->3x).
/// 2. Daily Cap 10 sets/muscle (hard cap).
/// 3. Frozen exercises (selected once here).
/// 4. Dynamic Split based on frequency needs.
class CycleTemplateBuilder {
  /// Builds the Base Week (Week 1) with all exercises selected and frozen.
  static List<TrainingSession> buildBaseWeek({
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required Map<String, int> targetVolumeByMuscle, // Week 1 Volume
    required int availableDays,
  }) {
    debugPrint(
      '[CycleTemplateBuilder] Building Base Week for ${availableDays} days...',
    );

    // 1. Calculate Frequency & Sets per Session needed per muscle
    final muscleConfig = _calculateMuscleConfig(
      targetVolumeByMuscle,
      availableDays,
    );

    // 2. Distribute Muscles into Days (Dynamic Split)
    final normalizedPriorities = <String, int>{};
    userProfile.musclePriorities.forEach((m, p) {
      normalizedPriorities[m] = p;
    });

    final dailyAllocations = _distributeMusclesToDays(
      muscleConfig,
      availableDays,
      normalizedPriorities,
    );

    // 3. Select Exercises & Build Sessions
    final sessions = <TrainingSession>[];

    // Track used exercises to avoid repetition if possible (or force variation)
    final usedExercises = <String>{};

    for (int dayIndex = 0; dayIndex < dailyAllocations.length; dayIndex++) {
      final dayAlloc = dailyAllocations[dayIndex];
      // Day number 1-based
      final dayNum = dayIndex + 1;

      debugPrint(
        '[CycleTemplateBuilder] Day $dayNum: ${dayAlloc.entries.map((e) => "${e.key}(${e.value}s)").join(", ")}',
      );

      final sessionExercises = <ExercisePrescription>[];

      // Sort muscles by priority/size for ordering within session
      // Big/Compound/Primary first logic handled by Engine but we iterate muscles here.
      // We rely on dailyAlloc keys order (sorted by load).
      // We can also sort keys by catalog 'size' logic if we had it. Keeping simplistic for now.

      final musclesOnDay = dayAlloc.keys.toList();

      for (final muscle in musclesOnDay) {
        final setsForDay = dayAlloc[muscle]!;

        // Select Exercises
        // Map muscle string to MuscleGroup enum?
        // ExerciseSelectionEngine.selectExercisesByGroups expects specific enums.
        // We can use a direct catalog lookup if Engine is too strict.
        // Or we construct a generic request.

        // Since we refactored Engine to use 'resolver', let's try to map string -> enum?
        // Actually, Engine selects by 'resolver.MuscleGroup'.
        // If 'muscle' string matches a group name, we can use it.
        // If not, we fall back to Catalog.

        // Simpler: Use Catalog directly as P0 requires specific muscle targeting.
        final candidates = ExerciseCatalogV3.getByMuscle(muscle);

        // Filter used?
        final available = candidates
            .where((e) => !usedExercises.contains(e.id))
            .toList();
        final pool = available.isNotEmpty ? available : candidates;

        if (pool.isEmpty) {
          debugPrint(
            '[CycleTemplateBuilder] ⚠️ No exercises found for $muscle',
          );
          continue;
        }

        // Sort pool by "Quality" (Compounds first)
        pool.sort(
          (a, b) => ExerciseOrderingRules.getScore(
            b,
          ).compareTo(ExerciseOrderingRules.getScore(a)),
        );

        // Select top N needed to fill sets
        final numExercises = (setsForDay / 3)
            .ceil()
            .clamp(1, min(4, pool.length))
            .toInt();
        final selected = pool.take(numExercises).toList();

        usedExercises.addAll(selected.map((e) => e.id));

        // Distribute Sets
        final baseSets = setsForDay ~/ selected.length;
        var remainder = setsForDay % selected.length;

        for (int i = 0; i < selected.length; i++) {
          final ex = selected[i];
          int sets = baseSets + (remainder > 0 ? 1 : 0);
          if (remainder > 0) remainder--;

          // Add to session
          sessionExercises.add(
            ExercisePrescription(
              exerciseId: ex.id,
              exerciseName: ex.name,
              orderInSession: sessionExercises.length + 1,
              sets: sets,
              repRange: _defaultReps(userProfile),
              targetRir: 2,
              intensityZone: 'moderate', // Logic to refine later?
              restSeconds: 90,
              notes: 'Week 1 Base',
            ),
          );
        }
      }

      // Sort Intra-session (Rule 6)
      // Now we have Prescriptions. We need to look up Exercise to sort.
      sessionExercises.sort((a, b) {
        final exA = ExerciseCatalogV3.getById(a.exerciseId);
        final exB = ExerciseCatalogV3.getById(b.exerciseId);
        if (exA == null || exB == null) return 0;
        return ExerciseOrderingRules.getScore(
          exB,
        ).compareTo(ExerciseOrderingRules.getScore(exA));
      });

      // Re-normalize order numbers
      for (int i = 0; i < sessionExercises.length; i++) {
        sessionExercises[i] = sessionExercises[i].copyWith(
          orderInSession: i + 1,
        );
      }

      // Calculate duration
      final duration = (sessionExercises.length * 10) + 10; // Rough heuristic

      sessions.add(
        TrainingSession(
          id: 'day_$dayNum',
          dayNumber: dayNum,
          name: 'Day $dayNum',
          primaryMuscles: musclesOnDay,
          estimatedDurationMinutes: duration,
          exercises: sessionExercises,
        ),
      );
    }

    return sessions;
  }

  /// Calculates how many times/week each muscle should be hit and sets/session.
  static Map<String, _MuscleFreqConfig> _calculateMuscleConfig(
    Map<String, int> volume,
    int availableDays,
  ) {
    final config = <String, _MuscleFreqConfig>{};

    // Cap total volume if days are low (Rule 3.4)
    final effectiveVolume = Map<String, int>.from(volume);
    if (availableDays <= 4) {
      for (final m in effectiveVolume.keys) {
        if (effectiveVolume[m]! > 20) {
          debugPrint(
            '[CycleTemplateBuilder] Capping $m to 20 sets (4 days limit).',
          );
          effectiveVolume[m] = 20;
        }
      }
    }

    effectiveVolume.forEach((muscle, sets) {
      int freq = 1;

      // P0 Frequency Logic:
      // <= 20 sets -> Freq 1-2 (Prefer 2)
      // >= 21 sets -> Freq 3

      if (sets >= 21 && availableDays >= 3) {
        freq = 3;
      } else if (sets > 6) {
        // If sets > 6, we prefer Freq 2 to split volume (better quality).
        // If sets <= 6, Freq 1 is fine (6 sets in 1 session is easy).
        freq = 2;
      } else {
        freq = 1;
      }

      // Cap frequency to available days
      if (freq > availableDays) freq = availableDays;

      config[muscle] = _MuscleFreqConfig(weeklySets: sets, frequency: freq);
    });
    return config;
  }

  /// Distributes muscles into days attempting to respect frequency and spacing.
  static List<Map<String, int>> _distributeMusclesToDays(
    Map<String, _MuscleFreqConfig> config,
    int days,
    Map<String, int> priorities,
  ) {
    // List of days, each is a Map<Muscle, Sets>
    final allocation = List.generate(days, (_) => <String, int>{});

    // P0 Ordering Logic:
    // 1. Priority (High to Low: 2->Primary, 1->Secondary, 0->Tertiary)
    // 2. Volume (High to Low)

    final sortedMuscles = config.keys.toList()
      ..sort((a, b) {
        final pA = priorities[a] ?? 0;
        final pB = priorities[b] ?? 0;

        if (pA != pB) {
          return pB.compareTo(pA); // Descending Priority
        }

        // Tie-breaker: Volume
        return config[b]!.weeklySets.compareTo(config[a]!.weeklySets);
      });

    for (final muscle in sortedMuscles) {
      final info = config[muscle]!;
      final freq = info.frequency;
      final totalSets = info.weeklySets;

      final indices = <int>[];
      if (freq == 1) {
        indices.add(_findDayWithMinLoad(allocation));
      } else if (freq == 2) {
        int first = _findDayWithMinLoad(allocation);
        int second = (first + (days / 2).ceil()) % days;
        if (second == first) second = (first + 1) % days;
        indices.add(first);
        indices.add(second);
      } else {
        double step = days / freq;
        int start = _findDayWithMinLoad(allocation);
        for (int i = 0; i < freq; i++) {
          indices.add((start + (i * step).round()) % days);
        }
      }

      final uniqueIndices = indices.toSet().toList();

      // Distribute sets
      int setsPerDay = totalSets ~/ uniqueIndices.length;
      int extra = totalSets % uniqueIndices.length;

      for (final idx in uniqueIndices) {
        int s = setsPerDay + (extra > 0 ? 1 : 0);
        if (extra > 0) extra--;

        // Cap check (Rule 4)
        if (s > 10) {
          debugPrint(
            '[CycleTemplateBuilder] ⚠️ Cap hit for $muscle on Day ${idx + 1}: $s -> 10. Volume lost.',
          );
          s = 10;
        }

        allocation[idx][muscle] = s;
      }
    }

    return allocation;
  }

  static int _findDayWithMinLoad(
    List<Map<String, int>> allocation, {
    Set<int>? exclude,
  }) {
    int minLoad = 9999;
    int minIdx = 0;
    for (int i = 0; i < allocation.length; i++) {
      if (exclude != null && exclude.contains(i)) continue;
      int load = allocation[i].values.fold(0, (a, b) => a + b);
      if (load < minLoad) {
        minLoad = load;
        minIdx = i;
      }
    }
    return minIdx;
  }

  static List<int> _defaultReps(UserProfile p) {
    if (p.primaryGoal == 'strength') return [3, 5];
    if (p.primaryGoal == 'endurance') return [15, 20];
    return [8, 12];
  }
}

class _MuscleFreqConfig {
  final int weeklySets;
  final int frequency;
  _MuscleFreqConfig({required this.weeklySets, required this.frequency});
}
