import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_ordering_rules.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/policies/split_table_ssot.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/effort_engine.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

/// Builds the template for the training cycle (Frozen Week 1).
///
/// Implements P0 Rules:
/// 1. Frequency based on volume (<=10->1x, 11-20->2x, >=21->3x).
/// 2. Daily Cap 10 sets/muscle (hard cap).
/// 3. Frozen exercises (selected once here).
/// 4. Dynamic Split based on frequency needs and SplitTableSSOT priorities.
class CycleTemplateBuilder {
  /// Builds the Base Week (Week 1) with all exercises selected and frozen.
  static TemplateBuildResult buildBaseWeek({
    required UserProfile userProfile,
    required ClientProfile clientProfile,
    required Map<String, int> targetVolumeByMuscle, // Week 1 Volume
    required int availableDays,
  }) {
    debugPrint(
      '[CycleTemplateBuilder] Building Base Week for $availableDays days...',
    );

    // 1. Calculate Frequency & Sets per Session needed per muscle
    // P0.1: _calculateMuscleConfig now returns TemplateBuildResult on infeasibility.
    final configResult = _calculateMuscleConfigOrFail(
      targetVolumeByMuscle,
      availableDays,
    );
    if (!configResult.success) return configResult.asBuildResult;
    final muscleConfig = configResult._muscleConfig!;

    // 2. Distribute Muscles into Days (Dynamic Split)
    // We use the SSOT logic to determine priority if needed,
    // though UserProfile priorities override defaults if present.
    final priorities = <String, int>{};

    // Initialize with SSOT defaults
    for (final m in targetVolumeByMuscle.keys) {
      priorities[m] = SplitTableSSOT.getPriority(m);
    }

    // Override with User Protocol if explicitly set
    userProfile.musclePriorities.forEach((m, p) {
      // Normalize first to ensure key match
      final key = muscle_registry.normalize(m) ?? m;
      priorities[key] = p;
    });

    final dailyAllocations = _distributeMusclesToDays(
      muscleConfig,
      availableDays,
      priorities,
    );

    // 3. Select Exercises & Build Sessions
    final sessions = <TrainingSession>[];
    final usedExercises = <String>{};

    for (int dayIndex = 0; dayIndex < dailyAllocations.length; dayIndex++) {
      final dayAlloc = dailyAllocations[dayIndex];
      final dayNum = dayIndex + 1;

      debugPrint(
        '[CycleTemplateBuilder] Day $dayNum: ${dayAlloc.entries.map((e) => "${e.key}(${e.value}s)").join(", ")}',
      );

      final sessionExercises = <ExercisePrescription>[];
      final musclesOnDay = dayAlloc.keys.toList();

      for (final muscle in musclesOnDay) {
        final setsForDay = dayAlloc[muscle]!;

        // Use normalized muscle for catalog lookup
        final normalizedMuscle = muscle_registry.normalize(muscle) ?? muscle;
        final candidates = ExerciseCatalogV3.getByMuscle(normalizedMuscle);

        final available = candidates
            .where((e) => !usedExercises.contains(e.id))
            .toList();

        // Retry logic: if strict filter yields nothing, reuse exercises
        final pool = available.isNotEmpty ? available : candidates;

        if (pool.isEmpty) {
          return TemplateBuildResult.failure(
            error:
                'No exercises available for muscle "$muscle". '
                'Catalog does not cover requested volume.',
          );
        }

        // Sort pool by "Quality" (Compounds first) as per SSOT/Ordering Rules
        pool.sort(
          (a, b) => ExerciseOrderingRules.getScore(
            b,
          ).compareTo(ExerciseOrderingRules.getScore(a)),
        );

        // Select top N needed to fill sets
        // Heuristic: ~3 sets per exercise.
        final numExercises = (setsForDay / 3)
            .ceil()
            .clamp(1, min(4, pool.length))
            .toInt();

        final selected = pool.take(numExercises).toList();
        usedExercises.addAll(selected.map((e) => e.id));

        // [V3][P0.2] Distribute sets using intensity split (heavy/medium/light)
        final eps = _buildIntensityPrescriptions(
          muscleKey: muscle,
          exercises: selected,
          setsForDay: setsForDay,
        );
        // Assign orderInSession
        for (final ep in eps) {
          sessionExercises.add(
            ep.copyWith(orderInSession: sessionExercises.length + 1),
          );
        }
      }

      // Sort Intra-session (Rule D: Follow table/ordering)
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

    return TemplateBuildResult.success(sessions);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // P0.1 — Feasibility helpers
  // ─────────────────────────────────────────────────────────────────────────

  static const int _defaultDailyCapPerMuscle = 10;

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
  ///
  /// Returns a [_ConfigOrFail] that either carries the config map or an error.
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

      // Hard Cap freq to available days (cannot train a muscle more days than exist)
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

  /// Distributes muscles into days using SSOT Rule D (Priorities).
  static List<Map<String, int>> _distributeMusclesToDays(
    Map<String, _MuscleFreqConfig> config,
    int days,
    Map<String, int> priorities,
  ) {
    final allocation = List.generate(days, (_) => <String, int>{});

    // Rule D: Order by priority
    final sortedMuscles = config.keys.toList()
      ..sort((a, b) {
        final pA = priorities[a] ?? 0;
        final pB = priorities[b] ?? 0;
        if (pA != pB) return pB.compareTo(pA); // Descending Priority
        return config[b]!.weeklySets.compareTo(
          config[a]!.weeklySets,
        ); // Volume Tie-breaker
      });

    for (final muscle in sortedMuscles) {
      final info = config[muscle]!;
      final freq = info.frequency;
      final totalSets = info.weeklySets;

      // Select Days with Min Load logic
      final indices = <int>[];

      // Initial day selection
      if (freq <= 1) {
        indices.add(_findDayWithMinLoad(allocation));
      } else {
        // Distributed logic
        final step = days / freq;
        int start = _findDayWithMinLoad(allocation);
        for (int i = 0; i < freq; i++) {
          indices.add((start + (i * step).round()) % days);
        }
      }

      final uniqueIndices = indices.toSet().toList();

      // Calculate allocation per day
      int setsPerDay = totalSets ~/ uniqueIndices.length;
      int extra = totalSets % uniqueIndices.length;

      for (final idx in uniqueIndices) {
        int s = setsPerDay + (extra > 0 ? 1 : 0);
        if (extra > 0) extra--;

        // P0.1: No silent cap here. Feasibility was already validated in
        // _calculateMuscleConfigOrFail. If sets per day still exceeds the
        // daily cap it means a bug in the distribution logic — log as ERROR
        // (volume is NOT silently dropped).
        if (s > 10) {
          debugPrint(
            '[V3][P0.1][BUG] DISTRIBUTION OVERFLOW: muscle=$muscle '
            'day=${idx + 1} setsComputed=$s > dailyCap=10. '
            'This should have been caught by feasibility check. '
            'Assigning as-is to preserve target volume.',
          );
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
    int minIndex = -1;
    int minLoad = 9999;

    for (int i = 0; i < allocation.length; i++) {
      if (exclude != null && exclude.contains(i)) continue;

      // Load = sum of sets assigned to that day
      final load = allocation[i].values.fold(0, (sum, v) => sum + v);
      if (load < minLoad) {
        minLoad = load;
        minIndex = i;
      }
    }
    return minIndex == -1 ? 0 : minIndex;
  }

  static List<int> _roundRobinDistribute(int totalSets, int n) {
    final out = List<int>.filled(n, 0);
    if (n <= 0 || totalSets <= 0) return out;
    var remaining = totalSets;
    var idx = 0;
    while (remaining > 0) {
      out[idx] += 1;
      remaining -= 1;
      idx = (idx + 1) % n;
    }
    return out;
  }

  static List<ExercisePrescription> _buildIntensityPrescriptions({
    required String muscleKey,
    required List<dynamic> exercises,
    required int setsForDay,
  }) {
    final split = IntensityEngine().computeSetSplitForDay(
      setsForDay: setsForDay,
    );
    final heavySets = split['heavy']!;
    final mediumSets = split['medium']!;
    final lightSets = split['light']!;

    debugPrint(
      '[V3][P0.2][INT] muscle=$muscleKey setsForDay=$setsForDay '
      'heavy=$heavySets medium=$mediumSets light=$lightSets exCount=${exercises.length}',
    );

    final n = exercises.length;
    final heavyPer = _roundRobinDistribute(heavySets, n);
    final mediumPer = _roundRobinDistribute(mediumSets, n);
    final lightPer = _roundRobinDistribute(lightSets, n);

    final out = <ExercisePrescription>[];

    for (var i = 0; i < n; i++) {
      final ex = exercises[i];
      final isCompound = (ex.primaryMuscles.length > 1);

      void addZone(String zone, int zoneSets) {
        if (zoneSets <= 0) return;

        final repRange = IntensityEngine.getRepRangeForIntensity(zone);
        final restSec = IntensityEngine.getRestSecondsForIntensity(zone);

        int baseRir = EffortEngine.assignRir(
          exerciseId: ex.id,
          intensity: zone,
          exerciseType: isCompound ? 'compound' : 'isolation',
        );

        int targetRir = EffortEngine.adjustRirForPhase(
          baseRir: baseRir,
          phase: 'accumulation', // P0.2: week1 default
        );

        out.add(
          ExercisePrescription(
            exerciseId: ex.id,
            exerciseName: ex.name,
            orderInSession: 0,
            sets: zoneSets,
            intensityZone: zone, // heavy/medium/light
            repRange: repRange,
            restSeconds: restSec,
            targetRir: targetRir,
            directTargetMuscleKey: muscleKey, // SSOT volumen directo
            notes: 'Week 1 Base',
          ),
        );
      }

      addZone('heavy', heavyPer[i]);
      addZone('medium', mediumPer[i]);
      addZone('light', lightPer[i]);
    }

    return out;
  }
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

  /// Returns the failure result. Only call when success == false.
  bool get isFailure => !success;

  // Expose the failure result as a TemplateBuildResult so callers can
  // propagate it directly.
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
