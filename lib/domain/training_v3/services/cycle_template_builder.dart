import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_ordering_rules.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/policies/split_table_ssot.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/ordering_engine.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

/// Builds the template for the training cycle (Frozen Week 1).
///
/// Implements B4 Rules:
/// 1. Split-aware muscle distribution (upperLower / fullBody).
/// 2. No-repeat exercise within same muscle/day across intensity zones.
/// 3. Session cap: max exercises per session by availableDays.
/// 4. maxExercisesPerMusclePerDay = 2 (days>=4) or 1 (days==3).
/// 5. maxSetsPerExercise = 5.
class CycleTemplateBuilder {
  // ─────────────────────────────────────────────────────────────────────────
  // B4 Constants
  // ─────────────────────────────────────────────────────────────────────────

  static const int _maxSetsPerExercise = 5;
  static const int _defaultDailyCapPerMuscle = 10;
  static const int _upperLowerHardCapMusclesPerDay = 12;

  /// Hard cap on unique exercises per session, keyed by availableDays.
  static int _sessionCapForDays(int days) {
    switch (days) {
      case 3:
        return 12;
      case 4:
        return 8;
      case 5:
        return 12;
      case 6:
        return 14;
      default:
        return days <= 3 ? 12 : 14;
    }
  }

  /// Max exercises per muscle per day (B4 Rule).
  static int _maxExercisesPerMusclePerDay(int availableDays) =>
      availableDays >= 4 ? 2 : 1;

  // ─────────────────────────────────────────────────────────────────────────
  // Upper / Lower muscle sets (canonical keys)
  // ─────────────────────────────────────────────────────────────────────────

  static const Set<String> _upperMuscles = {
    'pectorals',
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
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // buildBaseWeek — main entry point
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds the Base Week (Week 1) with all exercises selected and frozen.
  static TemplateBuildResult buildBaseWeek({
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required Map<String, int> targetVolumeByMuscle,
    required int availableDays,
    TrainingSplit split = TrainingSplit.upperLower,
  }) {
    debugPrint(
      '[CycleTemplateBuilder][B4] Building Base Week: days=$availableDays split=$split',
    );

    // 1. Calculate Frequency & Sets per Session needed per muscle
    final configResult = _calculateMuscleConfigOrFail(
      targetVolumeByMuscle,
      availableDays,
    );
    if (!configResult.success) return configResult.asBuildResult;
    final muscleConfig = configResult._muscleConfig!;

    // 2. Build priority map (SSOT defaults + user overrides)
    final priorities = <String, int>{};
    for (final m in targetVolumeByMuscle.keys) {
      priorities[m] = SplitTableSSOT.getPriority(m);
    }
    userProfile.musclePriorities.forEach((m, p) {
      final key = muscle_registry.normalize(m) ?? m;
      priorities[key] = p;
    });

    // 3. Distribute Muscles into Days using split template
    final dailyAllocations = _distributeMusclesToDaysBySplit(
      config: muscleConfig,
      availableDays: availableDays,
      split: split,
      priorities: priorities,
    );

    // 4. Select Exercises & Build Sessions
    final sessions = <TrainingSession>[];
    final usedExercisesGlobal = <String>{}; // cross-session freeze

    final maxPerSession = _sessionCapForDays(availableDays);
    final maxPerMusclePerDay = _maxExercisesPerMusclePerDay(availableDays);

    for (int dayIndex = 0; dayIndex < dailyAllocations.length; dayIndex++) {
      final dayAlloc = dailyAllocations[dayIndex];
      final dayNum = dayIndex + 1;

      debugPrint(
        '[CycleTemplateBuilder][B4] Day $dayNum: '
        '${dayAlloc.entries.map((e) => "${e.key}(${e.value}s)").join(", ")}',
      );

      final sessionExercises = <PlannedExercise>[];

      for (final muscle in dayAlloc.keys) {
        if (sessionExercises.length >= maxPerSession) break;

        final setsForDay = dayAlloc[muscle]!;
        final normalizedMuscle = muscle_registry.normalize(muscle) ?? muscle;
        final candidates = ExerciseCatalogV3.getByMuscle(normalizedMuscle);

        // Prefer exercises not yet used globally (across all days)
        final available = candidates
            .where((e) => !usedExercisesGlobal.contains(e.id))
            .toList();
        final pool = available.isNotEmpty ? available : candidates;

        if (pool.isEmpty) {
          return TemplateBuildResult.failure(
            error:
                '[B4] No exercises available for muscle "$muscle". '
                'Catalog does not cover requested volume.',
          );
        }

        // Sort by quality (compounds first)
        pool.sort(
          (a, b) => ExerciseOrderingRules.getScore(
            b,
          ).compareTo(ExerciseOrderingRules.getScore(a)),
        );

        // B4: correct numExercises formula
        final numExercisesNeeded = min(
          maxPerMusclePerDay,
          max(1, (setsForDay / _maxSetsPerExercise).ceil()),
        );

        // B4: No-repeat — within this muscle/day, each intensity zone
        // gets a different exerciseId when alternatives exist.
        // Compute intensity split first.
        final split0 = IntensityEngine().computeSetSplitForDay(
          setsForDay: setsForDay,
        );
        int remainingHeavy = split0['heavy'] ?? 0;
        int remainingMedium = split0['medium'] ?? 0;
        int remainingLight = split0['light'] ?? 0;

        // We need up to numExercisesNeeded exercises, each with a unique id
        // within this muscle/day.
        final usedForMuscleDay = <String>{}; // local: this muscle, this day
        int muscleExCount = 0;

        // Pick exercises from pool without repeating id within muscle/day
        final selectedExercises = <_ExerciseWithSets>[];
        int poolIdx = 0;
        while (muscleExCount < numExercisesNeeded && poolIdx < pool.length) {
          final candidate = pool[poolIdx++];
          if (usedForMuscleDay.contains(candidate.id)) continue;

          // Distribute remaining sets to this exercise
          int setsForEx = 0;
          if (muscleExCount == numExercisesNeeded - 1) {
            // Last exercise takes all remaining
            setsForEx = min(
              remainingHeavy + remainingMedium + remainingLight,
              _maxSetsPerExercise,
            );
          } else {
            setsForEx = min(
              (setsForDay / numExercisesNeeded).ceil(),
              _maxSetsPerExercise,
            );
          }

          if (setsForEx <= 0) break;

          // Allocate sets per zone for this exercise
          int exHeavy = 0, exMedium = 0, exLight = 0;

          int takeH = min(remainingHeavy, setsForEx);
          exHeavy += takeH;
          remainingHeavy -= takeH;
          setsForEx -= takeH;

          int takeM = min(remainingMedium, setsForEx);
          exMedium += takeM;
          remainingMedium -= takeM;
          setsForEx -= takeM;

          int takeL = min(remainingLight, setsForEx);
          exLight += takeL;
          remainingLight -= takeL;

          if (exHeavy + exMedium + exLight == 0) break;

          selectedExercises.add(
            _ExerciseWithSets(
              id: candidate.id,
              name: candidate.name,
              muscleKey: muscle,
              heavy: exHeavy,
              medium: exMedium,
              light: exLight,
              priorityScore: priorities[muscle] ?? 0,
            ),
          );

          usedForMuscleDay.add(candidate.id);
          usedExercisesGlobal.add(candidate.id);
          muscleExCount++;
        }

        // Build PlannedExercise objects from selected
        for (final exData in selectedExercises) {
          if (sessionExercises.length >= maxPerSession) break;
          sessionExercises.add(
            _buildExerciseWithDistributedSets(
              exerciseId: exData.id,
              name: exData.name,
              muscleKey: exData.muscleKey,
              heavySets: exData.heavy,
              mediumSets: exData.medium,
              lightSets: exData.light,
            ),
          );
        }
      }

      // B4 Session Cap Enforcement (post-build safety net)
      // If still over cap (shouldn't happen with pre-caps but safety net):
      if (sessionExercises.length > maxPerSession) {
        _applySessionCap(sessionExercises, maxPerSession, priorities);
      }

      // Sort intra-session (Rule E)
      OrderingEngine.orderPlannedExercises(sessionExercises);

      final duration = (sessionExercises.length * 10) + 10;

      sessions.add(
        TrainingSession(
          id: 'day_$dayNum',
          dayNumber: dayNum,
          name: 'Day $dayNum',
          primaryMuscles: dayAlloc.keys.toList(),
          estimatedDurationMinutes: duration,
          exercises: sessionExercises,
        ),
      );

      debugPrint(
        '[CycleTemplateBuilder][B4] Day $dayNum built: '
        '${sessionExercises.length} exercises (cap=$maxPerSession)',
      );
    }

    return TemplateBuildResult.success(sessions);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // B4 — Split-aware muscle distribution
  // ─────────────────────────────────────────────────────────────────────────

  /// Distributes muscles into days following the split template.
  /// Upper/Lower: odd dayIndex → upper muscles, even dayIndex → lower muscles.
  /// Full Body (3 days): rotating top-N by priority.
  static List<Map<String, int>> _distributeMusclesToDaysBySplit({
    required Map<String, _MuscleFreqConfig> config,
    required int availableDays,
    required TrainingSplit split,
    required Map<String, int> priorities,
  }) {
    final allocation = List.generate(availableDays, (_) => <String, int>{});

    // Max muscles per day by availableDays
    int maxMusclesPerDay;
    switch (availableDays) {
      case 3:
        maxMusclesPerDay = 7;
        break;
      case 4:
        maxMusclesPerDay = 5;
        break;
      case 5:
        maxMusclesPerDay = 6;
        break;
      case 6:
        maxMusclesPerDay = 5;
        break;
      default:
        maxMusclesPerDay = 6;
    }

    if (availableDays == 3 || split == TrainingSplit.fullBody) {
      // Full-body rotating distribution for 3 days
      _distributeFullBody(
        config: config,
        availableDays: availableDays,
        priorities: priorities,
        maxMusclesPerDay: maxMusclesPerDay,
        allocation: allocation,
      );
    } else {
      // upperLower (or pushPullLegs fallback → also upperLower)
      _distributeUpperLower(
        config: config,
        availableDays: availableDays,
        priorities: priorities,
        maxMusclesPerDay: maxMusclesPerDay,
        allocation: allocation,
      );
    }

    return allocation;
  }

  /// Upper / Lower split distribution.
  /// dayIndex 0,2,4 → Upper; dayIndex 1,3,5 → Lower.
  static void _distributeUpperLower({
    required Map<String, _MuscleFreqConfig> config,
    required int availableDays,
    required Map<String, int> priorities,
    required int maxMusclesPerDay,
    required List<Map<String, int>> allocation,
  }) {
    // Sort all muscles by priority desc
    final sorted = config.keys.toList()
      ..sort((a, b) {
        final byPriority = (priorities[b] ?? 0).compareTo(priorities[a] ?? 0);
        if (byPriority != 0) return byPriority;
        return a.compareTo(b);
      });

    // Upper and lower subsets from the requested muscles
    final upperPool = sorted.where((m) => _upperMuscles.contains(m)).toList();
    final lowerPool = sorted
        .where((m) => _lowerMuscles.contains(m) && !_upperMuscles.contains(m))
        .toList();
    // 'abs' is in both — already included in upperPool; don't double-add to lower

    final upperDays = <int>[];
    final lowerDays = <int>[];
    for (int dayIdx = 0; dayIdx < availableDays; dayIdx++) {
      if (dayIdx % 2 == 0) {
        upperDays.add(dayIdx);
      } else {
        lowerDays.add(dayIdx);
      }
    }

    _assignUpperLowerGroupCoverageFirst(
      groupName: 'upper',
      groupMuscles: upperPool,
      groupDays: upperDays,
      baseCap: maxMusclesPerDay,
      config: config,
      priorities: priorities,
      allocation: allocation,
    );

    _assignUpperLowerGroupCoverageFirst(
      groupName: 'lower',
      groupMuscles: lowerPool,
      groupDays: lowerDays,
      baseCap: maxMusclesPerDay,
      config: config,
      priorities: priorities,
      allocation: allocation,
    );

    debugPrint(
      '[CycleTemplateBuilder][B4][UpperLower] '
      'upper=${upperPool.length} lower=${lowerPool.length}',
    );
  }

  static void _assignUpperLowerGroupCoverageFirst({
    required String groupName,
    required List<String> groupMuscles,
    required List<int> groupDays,
    required int baseCap,
    required Map<String, _MuscleFreqConfig> config,
    required Map<String, int> priorities,
    required List<Map<String, int>> allocation,
  }) {
    if (groupMuscles.isEmpty || groupDays.isEmpty) return;

    int cap = baseCap;

    if (groupMuscles.length > cap) {
      var totalSlots = groupDays.length * cap;
      if (totalSlots < groupMuscles.length) {
        final neededCap = (groupMuscles.length / groupDays.length).ceil();
        cap = min(
          _upperLowerHardCapMusclesPerDay,
          max(cap, min(groupMuscles.length, neededCap)),
        );
        totalSlots = groupDays.length * cap;
      }

      if (totalSlots < groupMuscles.length) {
        debugPrint(
          '[CycleTemplateBuilder][B4][UpperLower][$groupName] '
          'WARNING coverage impossible: muscles=${groupMuscles.length} '
          'days=${groupDays.length} cap=$cap slots=$totalSlots',
        );
      }
    }

    for (int groupDayIdx = 0; groupDayIdx < groupDays.length; groupDayIdx++) {
      final dayIdx = groupDays[groupDayIdx];
      final musclesToday = groupMuscles.length <= cap
          ? List<String>.from(groupMuscles)
          : _selectRotatingWindow(
              pool: groupMuscles,
              cap: cap,
              dayIndex: groupDayIdx,
            );

      for (final muscle in musclesToday) {
        final cfg = config[muscle];
        if (cfg == null) continue;
        final setsPerAppearance = (cfg.weeklySets / cfg.frequency).round();
        allocation[dayIdx][muscle] = min(
          setsPerAppearance,
          _defaultDailyCapPerMuscle,
        );
      }
    }

    _applyUpperLowerCoverageFallback(
      groupName: groupName,
      groupMuscles: groupMuscles,
      groupDays: groupDays,
      cap: cap,
      config: config,
      priorities: priorities,
      allocation: allocation,
    );
  }

  static List<String> _selectRotatingWindow({
    required List<String> pool,
    required int cap,
    required int dayIndex,
  }) {
    if (pool.isEmpty || cap <= 0) return const [];
    if (pool.length <= cap) return List<String>.from(pool);

    final start = (dayIndex * cap) % pool.length;
    final selected = <String>[];
    for (int i = 0; i < cap; i++) {
      selected.add(pool[(start + i) % pool.length]);
    }
    return selected;
  }

  static void _applyUpperLowerCoverageFallback({
    required String groupName,
    required List<String> groupMuscles,
    required List<int> groupDays,
    required int cap,
    required Map<String, _MuscleFreqConfig> config,
    required Map<String, int> priorities,
    required List<Map<String, int>> allocation,
  }) {
    if (groupMuscles.isEmpty || groupDays.isEmpty) return;

    final covered = <String>{};
    for (final dayIdx in groupDays) {
      covered.addAll(allocation[dayIdx].keys);
    }

    final uncovered = groupMuscles.where((m) => !covered.contains(m)).toList();
    if (uncovered.isEmpty) return;

    for (final muscle in uncovered) {
      int targetDay = groupDays.first;
      int minLoad = allocation[targetDay].length;
      for (final dayIdx in groupDays) {
        final load = allocation[dayIdx].length;
        if (load < minLoad) {
          minLoad = load;
          targetDay = dayIdx;
        }
      }

      if (allocation[targetDay].length < cap) {
        final cfg = config[muscle];
        if (cfg != null) {
          allocation[targetDay][muscle] = min(
            (cfg.weeklySets / cfg.frequency).round(),
            _defaultDailyCapPerMuscle,
          );
        }
        continue;
      }

      final dayMuscles = allocation[targetDay].keys.toList()
        ..sort((a, b) {
          final byPriority = (priorities[a] ?? 0).compareTo(priorities[b] ?? 0);
          if (byPriority != 0) return byPriority;
          return a.compareTo(b);
        });

      if (dayMuscles.isEmpty) continue;

      final protectedTop = dayMuscles.length > 1 ? dayMuscles.last : null;

      String replaceMuscle = dayMuscles.first;
      if (protectedTop != null && replaceMuscle == protectedTop) {
        replaceMuscle = dayMuscles.length > 1
            ? dayMuscles[1]
            : dayMuscles.first;
      }

      allocation[targetDay].remove(replaceMuscle);
      final cfg = config[muscle];
      if (cfg != null) {
        allocation[targetDay][muscle] = min(
          (cfg.weeklySets / cfg.frequency).round(),
          _defaultDailyCapPerMuscle,
        );
      }
    }

    final coveredAfter = <String>{};
    for (final dayIdx in groupDays) {
      coveredAfter.addAll(allocation[dayIdx].keys);
    }
    final stillUncovered = groupMuscles
        .where((m) => !coveredAfter.contains(m))
        .length;
    if (stillUncovered > 0) {
      debugPrint(
        '[CycleTemplateBuilder][B4][UpperLower][$groupName] '
        'WARNING uncoveredAfterFallback=$stillUncovered',
      );
    }
  }

  /// Full-body rotating distribution for 3 days.
  static void _distributeFullBody({
    required Map<String, _MuscleFreqConfig> config,
    required int availableDays,
    required Map<String, int> priorities,
    required int maxMusclesPerDay,
    required List<Map<String, int>> allocation,
  }) {
    // Sort all muscles by priority desc
    final sorted = config.keys.toList()
      ..sort((a, b) => (priorities[b] ?? 0).compareTo(priorities[a] ?? 0));

    for (int dayIdx = 0; dayIdx < availableDays; dayIdx++) {
      // Rotate: shift start index by 2 each day
      final shift = (dayIdx * 2) % sorted.length;
      final rotated = [...sorted.sublist(shift), ...sorted.sublist(0, shift)];
      final musclesToday = rotated.take(maxMusclesPerDay).toList();

      for (final muscle in musclesToday) {
        final cfg = config[muscle];
        if (cfg == null) continue;

        final setsPerAppearance = (cfg.weeklySets / cfg.frequency).round();

        // Special case: abs gets reduced sets in full-body
        final isAbs = muscle == 'abs';
        final sets = isAbs
            ? max(1, (setsPerAppearance * 0.5).floor())
            : setsPerAppearance;

        allocation[dayIdx][muscle] = min(sets, _defaultDailyCapPerMuscle);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // B4 — Session Cap Post-Enforcement
  // ─────────────────────────────────────────────────────────────────────────

  /// Prunes sessionExercises to maxPerSession if over cap.
  /// Removes low-priority muscles first, within same priority removes
  /// light zone first, then medium, then heavy.
  static void _applySessionCap(
    List<PlannedExercise> exercises,
    int maxPerSession,
    Map<String, int> priorities,
  ) {
    while (exercises.length > maxPerSession) {
      // Find the exercise to prune: lowest priority muscle, then prefer light
      // Build score: lower = candidate for removal
      PlannedExercise? toRemove;
      int lowestPrio = 9999;
      bool hasLight = false;

      for (final ex in exercises) {
        final prio = priorities[ex.muscleKey] ?? 0;
        final exHasLight = ex.sets.any((s) => s.repsMin >= 12);
        if (prio < lowestPrio ||
            (prio == lowestPrio && !hasLight && exHasLight)) {
          lowestPrio = prio;
          hasLight = exHasLight;
          toRemove = ex;
        }
      }

      if (toRemove != null) {
        exercises.remove(toRemove);
      } else {
        exercises.removeLast();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // P0.1 — Feasibility helpers
  // ─────────────────────────────────────────────────────────────────────────

  static TemplateBuildResult _failIfInfeasible({
    required String muscle,
    required int targetSets,
    required int frequency,
    required int daysPerWeek,
    int dailyCapPerMuscle = _defaultDailyCapPerMuscle,
  }) {
    final maxAssignable = frequency * dailyCapPerMuscle;

    if (targetSets > maxAssignable) {
      return TemplateBuildResult.failure(
        error:
            '[V3][P0.2][INFEASIBLE] muscle="$muscle" '
            'target=$targetSets exceeds maxAssignable=$maxAssignable '
            '(freq=$frequency, dailyCap=$dailyCapPerMuscle, days=$daysPerWeek). '
            'Fix: increase days/split capacity OR reduce target volume.',
      );
    }

    debugPrint(
      '[V3][P0.2][FEASIBLE] muscle=$muscle target=$targetSets '
      'freq=$frequency dailyCap=$dailyCapPerMuscle maxAssignable=$maxAssignable',
    );

    return TemplateBuildResult.success(null);
  }

  /// [P0.1] Calculates frequency config for each muscle, performing a
  /// hard-fail feasibility check instead of silently capping volume.
  static _ConfigOrFail _calculateMuscleConfigOrFail(
    Map<String, int> volume,
    int availableDays,
  ) {
    final config = <String, _MuscleFreqConfig>{};

    for (final entry in volume.entries) {
      final muscle = entry.key;
      final sets = entry.value;

      int freq = 1;
      if (sets <= 10) {
        freq = 1;
      } else if (sets <= 20) {
        freq = 2;
      } else {
        freq = 3;
      }

      if (freq > availableDays) freq = availableDays;

      final feasResult = _failIfInfeasible(
        muscle: muscle,
        targetSets: sets,
        frequency: freq,
        daysPerWeek: availableDays,
      );
      if (!feasResult.success) {
        return _ConfigOrFail.failure(feasResult);
      }

      config[muscle] = _MuscleFreqConfig(weeklySets: sets, frequency: freq);
    }
    return _ConfigOrFail.ok(config);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exercise builder
  // ─────────────────────────────────────────────────────────────────────────

  static PlannedExercise _buildExerciseWithDistributedSets({
    required String exerciseId,
    required String name,
    required String muscleKey,
    required int heavySets,
    required int mediumSets,
    required int lightSets,
  }) {
    final sets = <SetPrescription>[];

    // Heavy 5–8
    for (int i = 0; i < heavySets; i++) {
      sets.add(const SetPrescription(repsMin: 5, repsMax: 8, rir: 2));
    }

    // Medium 8–12
    for (int i = 0; i < mediumSets; i++) {
      sets.add(const SetPrescription(repsMin: 8, repsMax: 12, rir: 2));
    }

    // Light 12–20
    for (int i = 0; i < lightSets; i++) {
      sets.add(const SetPrescription(repsMin: 12, repsMax: 20, rir: 0));
    }

    return PlannedExercise(
      exerciseId: exerciseId,
      name: name,
      muscleKey: muscleKey,
      sets: sets,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Intermediate data class for exercise selection before building PlannedExercise.
class _ExerciseWithSets {
  final String id;
  final String name;
  final String muscleKey;
  final int heavy;
  final int medium;
  final int light;
  final int priorityScore;

  const _ExerciseWithSets({
    required this.id,
    required this.name,
    required this.muscleKey,
    required this.heavy,
    required this.medium,
    required this.light,
    required this.priorityScore,
  });
}

/// Internal helper: holds either a valid muscleConfig map OR a failure result.
class _ConfigOrFail {
  final Map<String, _MuscleFreqConfig>? _muscleConfig;
  final TemplateBuildResult? _failure;

  bool get success => _failure == null;

  _ConfigOrFail.ok(Map<String, _MuscleFreqConfig> config)
    : _muscleConfig = config,
      _failure = null;

  _ConfigOrFail.failure(TemplateBuildResult fail)
    : _muscleConfig = null,
      _failure = fail;

  bool get isFailure => !success;

  TemplateBuildResult get asBuildResult =>
      _failure ?? TemplateBuildResult.failure(error: 'Unknown config error');
}

class _MuscleFreqConfig {
  final int weeklySets;
  final int frequency;

  _MuscleFreqConfig({required this.weeklySets, required this.frequency});
}

class TemplateBuildResult {
  final bool success;
  final String? error;
  final List<TrainingSession>? sessions;

  TemplateBuildResult.success(this.sessions) : success = true, error = null;

  TemplateBuildResult.failure({required this.error})
    : success = false,
      sessions = null;
}
