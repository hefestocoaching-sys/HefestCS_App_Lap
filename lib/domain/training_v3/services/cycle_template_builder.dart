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

  /// Hard cap on unique exercises per session, keyed by availableDays.
  static int _sessionCapForDays(int days) {
    if (days == 4) return 12;
    switch (days) {
      case 3:
        return 12;
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
    'chest',
    'lats',
    'upper_back',
    'traps',
    'biceps',
    'triceps',
    'abs',
  };

  static const Set<String> _lowerMuscles = {
    'quadriceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'deltoide_anterior',
    'deltoide_lateral',
    'deltoide_posterior',
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
    String? backFocus,
  }) {
    debugPrint(
      '[CycleTemplateBuilder][B4] Building Base Week: days=$availableDays split=$split',
    );

    final canonicalTargetVolume = _canonicalizeVolumeMap(targetVolumeByMuscle);

    // 1. Calculate Frequency & Sets per Session needed per muscle
    final configResult = _calculateMuscleConfigOrFail(
      canonicalTargetVolume,
      availableDays,
    );
    if (!configResult.success) return configResult.asBuildResult;
    final muscleConfig = configResult._muscleConfig!;

    // 2. Build priority map (SSOT defaults + user overrides)
    final priorities = <String, int>{};
    for (final m in canonicalTargetVolume.keys) {
      priorities[m] = SplitTableSSOT.getPriority(m);
    }
    userProfile.musclePriorities.forEach((m, p) {
      final key = normalizeMuscleKey(m);
      priorities[key] = p;
    });

    // 3. Forzar frecuencia mínima 2 en UL 4 días
    if (availableDays == 4 && split == TrainingSplit.upperLower) {
      muscleConfig.updateAll(
        (key, cfg) =>
            _MuscleFreqConfig(weeklySets: cfg.weeklySets, frequency: 2),
      );
    }

    // 4. Distribute Muscles into Days using split template
    final dailyAllocations = _distributeMusclesToDaysBySplit(
      config: muscleConfig,
      availableDays: availableDays,
      split: split,
      priorities: priorities,
    );

    final dailyCapError = _validateDailyAllocationCaps(
      dailyAllocations,
      config: muscleConfig,
      dailyCapPerMuscle: _defaultDailyCapPerMuscle,
      availableDays: availableDays,
      split: split,
    );
    if (dailyCapError != null) {
      return TemplateBuildResult.failure(error: dailyCapError);
    }

    // 4. Select Exercises & Build Sessions
    final sessions = <TrainingSession>[];
    final usedExercisesGlobal = <String>{}; // cross-session freeze
    final focusBackMuscle = (backFocus == 'lats' || backFocus == 'upper_back')
        ? backFocus!
        : 'upper_back';
    var backHeavyAssignedForWeek = false;

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
      final setsByMuscle = <String, int>{};
      final dayHasBack =
          dayAlloc.containsKey('lats') || dayAlloc.containsKey('upper_back');
      final applyBackFocusThisDay = !backHeavyAssignedForWeek && dayHasBack;
      if (applyBackFocusThisDay) {
        backHeavyAssignedForWeek = true;
        final latsSets = dayAlloc['lats'] ?? 0;
        final upperBackSets = dayAlloc['upper_back'] ?? 0;
        final totalBackSets = latsSets + upperBackSets;
        debugPrint(
          '[BackFocus] día de heavy aplicado: day=$dayNum totalBackSets=$totalBackSets latsSets=$latsSets upperBackSets=$upperBackSets focus=$focusBackMuscle',
        );
      }

      void addSets(String muscle, int sets) {
        final normalized = normalizeMuscleKey(muscle);
        final current = setsByMuscle[normalized] ?? 0;
        final next = current + sets;
        if (next > _defaultDailyCapPerMuscle) {
          throw StateError(
            '[DAILY CAP VIOLATION] muscle=$normalized day=$dayNum attempted=$next cap=$_defaultDailyCapPerMuscle',
          );
        }
        setsByMuscle[normalized] = next;
      }

      for (final muscle in dayAlloc.keys) {
        if (sessionExercises.length >= maxPerSession) break;

        final setsForDay = dayAlloc[muscle]!;
        final normalizedMuscle = normalizeMuscleKey(muscle);
        addSets(normalizedMuscle, setsForDay);
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
        int numExercisesNeeded;
        if (setsForDay <= 6) {
          numExercisesNeeded = 1;
        } else if (setsForDay <= 10) {
          numExercisesNeeded = 2;
        } else {
          numExercisesNeeded = 2; // nunca más de 2 por músculo por día
        }
        numExercisesNeeded = min(numExercisesNeeded, maxPerMusclePerDay);

        // B4: No-repeat — within this muscle/day, each intensity zone
        // gets a different exerciseId when alternatives exist.
        // Compute intensity split first.
        final split0 = IntensityEngine().computeSetSplitForDay(
          setsForDay: setsForDay,
        );
        int heavySets = split0['heavy'] ?? 0;
        int mediumSets = split0['medium'] ?? 0;
        int lightSets = split0['light'] ?? 0;

        // BackFocus: primera exposición semanal de espalda concentra heavy en el foco
        if (applyBackFocusThisDay &&
            (normalizedMuscle == 'lats' || normalizedMuscle == 'upper_back')) {
          if (normalizedMuscle == focusBackMuscle) {
            if (setsForDay > 0) {
              if (heavySets >= 1) {
                final carryToMedium = heavySets - 1;
                heavySets = 1;
                mediumSets += carryToMedium;
              } else {
                heavySets = 1;
                if (mediumSets > 0) {
                  mediumSets -= 1;
                } else if (lightSets > 0) {
                  lightSets -= 1;
                } else {
                  heavySets = 0;
                }
              }
            }
          } else {
            mediumSets += heavySets;
            heavySets = 0;
          }
        }

        int remainingHeavy = heavySets;
        int remainingMedium = mediumSets;
        int remainingLight = lightSets;

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

          // Nueva regla: el último ejercicio toma todos los sets restantes, sin cap
          int setsForEx = 0;
          if (muscleExCount == numExercisesNeeded - 1) {
            setsForEx = remainingHeavy + remainingMedium + remainingLight;
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
              muscleKey: normalizedMuscle,
              heavy: exHeavy,
              medium: exMedium,
              light: exLight,
              priorityScore: priorities[normalizedMuscle] ?? 0,
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

      // Validación estricta post-build: cada músculo debe tener sets exactos
      for (final muscle in dayAlloc.keys) {
        final normalized = normalizeMuscleKey(muscle);
        final assigned = setsByMuscle[normalized] ?? 0;
        final target = dayAlloc[muscle] ?? 0;
        if (assigned != target) {
          throw StateError(
            '[P0 COVERAGE FAIL] muscle=$normalized target=$target assigned=$assigned',
          );
        }
      }

      // B4 Session Cap Enforcement (post-build safety net)
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
    final canonicalConfig = _canonicalizeConfigMap(config);
    final canonicalPriorities = _canonicalizePriorityMap(priorities);
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
        config: canonicalConfig,
        availableDays: availableDays,
        priorities: canonicalPriorities,
        maxMusclesPerDay: maxMusclesPerDay,
        allocation: allocation,
      );
    } else {
      // upperLower (or pushPullLegs fallback → also upperLower)
      _distributeUpperLower(
        config: canonicalConfig,
        availableDays: availableDays,
        priorities: canonicalPriorities,
        maxMusclesPerDay: maxMusclesPerDay,
        allocation: allocation,
      );
    }

    for (int dayIndex = 0; dayIndex < allocation.length; dayIndex++) {
      debugPrint(
        '[Template] day=${dayIndex + 1} músculos=${allocation[dayIndex].length} maxMusclesPerDay=$maxMusclesPerDay',
      );
    }

    return allocation;
  }

  static String? _validateDailyAllocationCaps(
    List<Map<String, int>> allocation, {
    required Map<String, _MuscleFreqConfig> config,
    required int dailyCapPerMuscle,
    required int availableDays,
    required TrainingSplit split,
  }) {
    for (int dayIdx = 0; dayIdx < allocation.length; dayIdx++) {
      for (final entry in allocation[dayIdx].entries) {
        final normalized = normalizeMuscleKey(entry.key);
        final sets = entry.value;
        if (sets <= dailyCapPerMuscle) continue;
        final eligibleDays = _eligibleDaysForMuscle(
          normalized,
          split: split,
          availableDays: availableDays,
        );
        final cfg =
            config[normalized] ??
            config.entries
                .firstWhere(
                  (e) => normalizeMuscleKey(e.key) == normalized,
                  orElse: () => MapEntry(
                    normalized,
                    _MuscleFreqConfig(weeklySets: sets, frequency: 1),
                  ),
                )
                .value;
        final freqComputed = _effectiveFrequencyForMuscle(
          muscle: normalized,
          requestedFrequency: cfg.frequency,
          split: split,
          availableDays: availableDays,
        );
        if (kDebugMode) {
          debugPrint(
            '[FreqDebug] muscle=${entry.key} normalized=$normalized split=${split.name} days=$availableDays freqComputed=$freqComputed eligibleDays=$eligibleDays',
          );
        }
        return '[V3][P0.2][INFEASIBLE_DAILY_ALLOCATION] '
            'muscle="$normalized" day=${dayIdx + 1} '
            'attempted=$sets cap=$dailyCapPerMuscle '
            '(split=${split.name}, days=$availableDays). '
            'Fix: increase effective frequency for that muscle/split '
            'or reduce weekly target volume.';
      }
    }
    return null;
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
    final upperPool = sorted.where((m) => _isUpperMuscle(m)).toList();
    final lowerPool = sorted
        .where((m) => _isLowerMuscle(m) && !_isUpperMuscle(m))
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

    _assignUpperLowerDeterministic(
      groupName: 'upper',
      groupMuscles: upperPool,
      groupDays: upperDays,
      availableDays: availableDays,
      priorities: priorities,
      maxMusclesPerDay: maxMusclesPerDay,
      config: config,
      allocation: allocation,
    );
    _assignUpperLowerDeterministic(
      groupName: 'lower',
      groupMuscles: lowerPool,
      groupDays: lowerDays,
      availableDays: availableDays,
      priorities: priorities,
      maxMusclesPerDay: maxMusclesPerDay,
      config: config,
      allocation: allocation,
    );

    debugPrint(
      '[CycleTemplateBuilder][B4][UpperLower] '
      'upper=${upperPool.length} lower=${lowerPool.length}',
    );
  }

  /// Asignación determinista para Upper/Lower: cada músculo se asigna exactamente "frequency" veces,
  /// distribuyendo los sets de forma equitativa y sin rotación ni duplicación extra.
  static void _assignUpperLowerDeterministic({
    required String groupName,
    required List<String> groupMuscles,
    required List<int> groupDays,
    required int availableDays,
    required Map<String, int> priorities,
    required int maxMusclesPerDay,
    required Map<String, _MuscleFreqConfig> config,
    required List<Map<String, int>> allocation,
  }) {
    if (groupMuscles.isEmpty || groupDays.isEmpty) return;

    final sortedMuscles = List<String>.from(groupMuscles)
      ..sort((a, b) {
        final priorityCompare = (priorities[b] ?? 0).compareTo(
          priorities[a] ?? 0,
        );
        if (priorityCompare != 0) return priorityCompare;

        final targetCompare = (config[b]?.weeklySets ?? 0).compareTo(
          config[a]?.weeklySets ?? 0,
        );
        if (targetCompare != 0) return targetCompare;

        final sizeCompare = _muscleSizeRank(b).compareTo(_muscleSizeRank(a));
        if (sizeCompare != 0) return sizeCompare;

        return a.compareTo(b);
      });

    final dayMuscles = <int, List<String>>{
      for (final dayIndex in groupDays) dayIndex: <String>[],
    };

    for (final muscle in sortedMuscles) {
      final candidateDays = List<int>.from(groupDays)
        ..sort((a, b) {
          final remainingA = maxMusclesPerDay - dayMuscles[a]!.length;
          final remainingB = maxMusclesPerDay - dayMuscles[b]!.length;
          final byCapacity = remainingB.compareTo(remainingA);
          if (byCapacity != 0) return byCapacity;
          return a.compareTo(b);
        });

      final primaryDay = candidateDays.firstWhere(
        (dayIndex) => dayMuscles[dayIndex]!.length < maxMusclesPerDay,
        orElse: () => candidateDays.first,
      );

      dayMuscles[primaryDay]!.add(muscle);
    }

    for (final muscle in sortedMuscles) {
      final cfg = config[muscle];
      if (cfg == null) continue;

      // P0: garantizar factibilidad de sets respecto al dailyCap
      const dailyCap = 10;
      final minDaysNeeded = (cfg.weeklySets / dailyCap).ceil();
      final desiredFrequency = min(
        max(cfg.frequency, minDaysNeeded),
        groupDays.length,
      );
      final assignedDays = groupDays
          .where((dayIndex) => dayMuscles[dayIndex]!.contains(muscle))
          .toList();

      while (assignedDays.length < desiredFrequency) {
        // Etapa A: respetar maxMusclesPerDay
        final possibleDaysStrict =
            groupDays
                .where(
                  (dayIndex) =>
                      !dayMuscles[dayIndex]!.contains(muscle) &&
                      dayMuscles[dayIndex]!.length < maxMusclesPerDay,
                )
                .toList()
              ..sort((a, b) {
                final remainingA = maxMusclesPerDay - dayMuscles[a]!.length;
                final remainingB = maxMusclesPerDay - dayMuscles[b]!.length;
                final byCapacity = remainingB.compareTo(remainingA);
                if (byCapacity != 0) return byCapacity;
                return a.compareTo(b);
              });

        if (possibleDaysStrict.isNotEmpty) {
          final selectedDay = possibleDaysStrict.first;
          dayMuscles[selectedDay]!.add(muscle);
          assignedDays.add(selectedDay);
        } else {
          // Etapa B: overflow controlado para cumplir factibilidad de sets
          final possibleDaysRelaxed =
              groupDays.where((d) => !dayMuscles[d]!.contains(muscle)).toList()
                ..sort(
                  (a, b) =>
                      dayMuscles[a]!.length.compareTo(dayMuscles[b]!.length),
                );

          if (possibleDaysRelaxed.isEmpty) break;

          final selectedDay = possibleDaysRelaxed.first;
          dayMuscles[selectedDay]!.add(muscle);
          assignedDays.add(selectedDay);
        }
      }

      // P0.2: guard de factibilidad — diagnóstico temprano si no se pudo cumplir
      if (assignedDays.length < minDaysNeeded) {
        throw StateError(
          '[V3][P0.2][INFEASIBLE_DAILY_ALLOCATION] muscle="$muscle" '
          'weeklySets=${cfg.weeklySets} minDaysNeeded=$minDaysNeeded '
          'assignedDays=${assignedDays.length} groupDays=${groupDays.length} '
          'cap=10. Fix: increase split frequency or reduce weekly volume.',
        );
      }

      if (desiredFrequency == 2 &&
          assignedDays.length == 1 &&
          availableDays == 4 &&
          groupDays.length == 2) {
        final missingDay = groupDays.firstWhere(
          (day) => !assignedDays.contains(day),
          orElse: () => groupDays.first,
        );

        if (!dayMuscles[missingDay]!.contains(muscle)) {
          if (dayMuscles[missingDay]!.length < maxMusclesPerDay) {
            dayMuscles[missingDay]!.add(muscle);
            assignedDays.add(missingDay);
          } else {
            final removable = List<String>.from(dayMuscles[missingDay]!)
              ..sort((a, b) {
                final byPriority = (priorities[a] ?? 0).compareTo(
                  priorities[b] ?? 0,
                );
                if (byPriority != 0) return byPriority;
                return a.compareTo(b);
              });
            final toRemove = removable.firstWhere(
              (m) => m != muscle,
              orElse: () => '',
            );
            if (toRemove.isNotEmpty) {
              dayMuscles[missingDay]!.remove(toRemove);
              dayMuscles[missingDay]!.add(muscle);
              assignedDays.add(missingDay);
            }
          }
        }
      }

      if (assignedDays.isEmpty) {
        final fallbackDay = groupDays.first;
        dayMuscles[fallbackDay]!.add(muscle);
        assignedDays.add(fallbackDay);
      }

      final sets = cfg.weeklySets;
      final baseSets = sets ~/ assignedDays.length;
      final remainder = sets % assignedDays.length;

      for (var i = 0; i < assignedDays.length; i++) {
        final dayIndex = assignedDays[i];
        final setsForDay = baseSets + (i < remainder ? 1 : 0);
        final normalized = normalizeMuscleKey(muscle);
        allocation[dayIndex][normalized] =
            (allocation[dayIndex][normalized] ?? 0) + setsForDay;
      }
    }

    for (final dayIndex in groupDays) {
      debugPrint(
        '[Template] group=$groupName day=${dayIndex + 1} músculos=${dayMuscles[dayIndex]!.length} maxMusclesPerDay=$maxMusclesPerDay',
      );
    }
  }

  static int _muscleSizeRank(String muscle) {
    final normalized = normalizeMuscleKey(muscle);
    const largeMuscles = {
      'pectorals',
      'lats',
      'upper_back',
      'quadriceps',
      'hamstrings',
      'glutes',
    };
    return largeMuscles.contains(normalized) ? 1 : 0;
  }

  static String normalizeMuscleKey(String k) {
    switch (k) {
      case 'chest':
        return 'pectorals';
      case 'quads':
        return 'quadriceps';
      default:
        return muscle_registry.normalize(k) ?? k;
    }
  }

  static bool _isUpperMuscle(String muscle) =>
      _upperMuscles.contains(normalizeMuscleKey(muscle));

  static bool _isLowerMuscle(String muscle) =>
      _lowerMuscles.contains(normalizeMuscleKey(muscle));

  static Map<String, int> _canonicalizeVolumeMap(Map<String, int> source) {
    final canonical = <String, int>{};
    for (final entry in source.entries) {
      final normalized = normalizeMuscleKey(entry.key);
      canonical[normalized] = (canonical[normalized] ?? 0) + entry.value;
    }
    return canonical;
  }

  static Map<String, int> _canonicalizePriorityMap(Map<String, int> source) {
    final canonical = <String, int>{};
    for (final entry in source.entries) {
      final normalized = normalizeMuscleKey(entry.key);
      final previous = canonical[normalized];
      if (previous == null) {
        canonical[normalized] = entry.value;
      } else {
        canonical[normalized] = min(previous, entry.value);
      }
    }
    return canonical;
  }

  static Map<String, _MuscleFreqConfig> _canonicalizeConfigMap(
    Map<String, _MuscleFreqConfig> source,
  ) {
    final canonical = <String, _MuscleFreqConfig>{};
    for (final entry in source.entries) {
      final normalized = normalizeMuscleKey(entry.key);
      final current = canonical[normalized];
      if (current == null) {
        canonical[normalized] = _MuscleFreqConfig(
          weeklySets: entry.value.weeklySets,
          frequency: entry.value.frequency,
        );
      } else {
        canonical[normalized] = _MuscleFreqConfig(
          weeklySets: current.weeklySets + entry.value.weeklySets,
          frequency: max(current.frequency, entry.value.frequency),
        );
      }
    }
    return canonical;
  }

  static List<int> _eligibleDaysForMuscle(
    String muscle, {
    required TrainingSplit split,
    required int availableDays,
  }) {
    final normalized = normalizeMuscleKey(muscle);
    switch (split) {
      case TrainingSplit.upperLower:
        if (_isUpperMuscle(normalized)) {
          return List<int>.generate(
            availableDays,
            (i) => i + 1,
          ).where((day) => day.isOdd).toList();
        }
        if (_isLowerMuscle(normalized)) {
          return List<int>.generate(
            availableDays,
            (i) => i + 1,
          ).where((day) => day.isEven).toList();
        }
        return List<int>.generate(availableDays, (i) => i + 1);
      case TrainingSplit.fullBody:
      case TrainingSplit.pushPullLegs:
        return List<int>.generate(availableDays, (i) => i + 1);
    }
  }

  static int _effectiveFrequencyForMuscle({
    required String muscle,
    required int requestedFrequency,
    required TrainingSplit split,
    required int availableDays,
  }) {
    final eligibleDays = _eligibleDaysForMuscle(
      muscle,
      split: split,
      availableDays: availableDays,
    );
    var effective = min(requestedFrequency, eligibleDays.length);
    if (split == TrainingSplit.upperLower &&
        availableDays == 4 &&
        eligibleDays.length == 2 &&
        effective < 2) {
      effective = 2;
    }
    return max(effective, 1);
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
