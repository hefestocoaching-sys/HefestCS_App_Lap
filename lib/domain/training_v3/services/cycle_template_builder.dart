import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_ordering_rules.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/policies/split_table_ssot.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/rep_structure_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/session_intensity_set_allocator.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/session_time_estimator.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_ordering_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_role_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_distribution_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/mesocycle_exercise_pool.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_set_allocator.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/session_structure_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/antagonist_pairing_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/data/interference_matrix.dart';
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

  static const int _defaultDailyCapPerMuscle = 10;
  static const Map<String, double> _defaultIntensitySplit = {
    'heavy': 20,
    'medium': 60,
    'light': 20,
  };

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
    'lats',
    'upper_back',
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
  };

  static const Set<String> _lowerMuscles = {
    'quads',
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
    required Map<String, List<String>> mesocycleExercisePoolByMuscle,
    Map<int, List<String>>? dayMusclePriorityOrder,
    Map<String, double> intensityProfilePercentSplit = _defaultIntensitySplit,
    Map<String, IntensityDistribution>? weeklyIntensityTargetsByMuscle,
    required int availableDays,
    TrainingSplit split = TrainingSplit.upperLower,
    String? backFocus,
  }) {
    debugPrint(
      '[CycleTemplateBuilder][B4] Building Base Week: days=$availableDays split=$split',
    );

    final canonicalTargetVolume = _canonicalizeVolumeMap(targetVolumeByMuscle);
    final canonicalExercisePool = _canonicalizeExercisePool(
      mesocycleExercisePoolByMuscle,
    );

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
    final focusBackMuscle = (backFocus == 'lats' || backFocus == 'upper_back')
        ? backFocus!
        : 'upper_back';
    var backHeavyAssignedForWeek = false;

    final maxPerSession = _sessionCapForDays(availableDays);
    final maxPerMusclePerDay = _maxExercisesPerMusclePerDay(availableDays);
    final repStructureEngine = RepStructureEngine();
    final sessionTimeEstimator = SessionTimeEstimator();
    final roleEngine = ExerciseRoleEngine();
    final muscleOccurrenceCount = <String, int>{};
    final lastPairByMuscle = <String, List<String>>{};
    final lockedAnchorByMuscle = <String, String>{};

    final weeklySetsByMuscle = <String, int>{
      for (final entry in muscleConfig.entries)
        entry.key: entry.value.weeklySets,
    };
    final intensityTargets =
        weeklyIntensityTargetsByMuscle ??
        IntensityDistributionEngine.buildWeeklyTargets(
          weeklySetsByMuscle: weeklySetsByMuscle,
          intensitySplitPercent: intensityProfilePercentSplit,
        );

    final setsByAppearancePerMuscle = <String, List<int>>{};
    for (final day in dailyAllocations) {
      for (final entry in day.entries) {
        final normalized = normalizeMuscleKey(entry.key);
        setsByAppearancePerMuscle
            .putIfAbsent(normalized, () => <int>[])
            .add(entry.value);
      }
    }

    final intensityByAppearancePerMuscle =
        <String, Map<int, IntensityDistribution>>{};
    for (final entry in setsByAppearancePerMuscle.entries) {
      final weeklyTarget =
          intensityTargets[entry.key] ??
          IntensityDistributionEngine.splitWeeklySets(
            weeklySets: entry.value.fold<int>(0, (sum, sets) => sum + sets),
            intensitySplitPercent: intensityProfilePercentSplit,
          );
      intensityByAppearancePerMuscle[entry.key] =
          IntensityDistributionEngine.distributeAcrossAppearances(
            weeklyTarget: weeklyTarget,
            setsByAppearance: entry.value,
          );
    }

    for (int dayIndex = 0; dayIndex < dailyAllocations.length; dayIndex++) {
      final dayAlloc = dailyAllocations[dayIndex];
      final dayNum = dayIndex + 1;

      debugPrint(
        '[CycleTemplateBuilder][B4] Day $dayNum: '
        '${dayAlloc.entries.map((e) => "${e.key}(${e.value}s)").join(", ")}',
      );

      final daySeedExercises = <_DayExerciseSeed>[];
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

      // Block-first: determine a day plan A/B/C/D before selecting exercises.
      final primaryMuscleOfDay = _findPrimaryMuscleForDay(dayAlloc, priorities);
      final preferredOrderForDay =
          dayMusclePriorityOrder?[dayNum] ?? const <String>[];
      final dayOrderedByPriority = _applyPreferredDayOrder(
        dayAlloc.keys.toList(),
        preferredOrderForDay,
      );
      final orderedMuscles = _orderMusclesByBlockPriority(
        dayOrderedByPriority,
        primaryMuscle: primaryMuscleOfDay,
      );
      final dayBlockPlan = _buildDayBlockMusclePlan(
        orderedMuscles,
        primaryMuscle: primaryMuscleOfDay,
      );
      debugPrint(
        '[CycleTemplateBuilder][Block-First] day=$dayNum '
        'primaryMuscle=$primaryMuscleOfDay '
        'orderedMuscles=$orderedMuscles '
        'blockPlan=$dayBlockPlan',
      );

      const blockOrder = <String>['A', 'B', 'C', 'D'];
      for (final blockLabel in blockOrder) {
        final musclesForBlock = dayBlockPlan[blockLabel] ?? const <String>[];
        for (final muscle in musclesForBlock) {
          final setsForDay = dayAlloc[muscle]!;
          final normalizedMuscle = normalizeMuscleKey(muscle);
          addSets(normalizedMuscle, setsForDay);

          final poolIds = canonicalExercisePool[normalizedMuscle] ?? const [];
          debugPrint(
            '[B4][POOL_RAW] muscle=$normalizedMuscle day=$dayNum desired_zone=pre ids=$poolIds',
          );
          final pool = ExerciseCatalogV3.getExercisesByIds(poolIds);
          debugPrint(
            '[B4][POOL_RESOLVED] muscle=$normalizedMuscle day=$dayNum desired_zone=pre ids=${pool.map((e) => e.id).toList()}',
          );
          final lockedPool = MesocycleExercisePool.lockExercises(
            '${userProfile.id}:$normalizedMuscle:${poolIds.join('|')}',
            pool,
          );
          debugPrint(
            '[V3][MESOCYCLE_POOL] muscle=$normalizedMuscle day=$dayNum ids=${lockedPool.map((e) => e.id).toList()}',
          );
          if (lockedPool.isEmpty) {
            throw StateError(
              '[B4] No exercises available for muscle=$normalizedMuscle '
              'day=$dayNum rawPool=$poolIds resolved=[] zone=pre',
            );
          }

          // Sort by quality (compounds first)
          lockedPool.sort(
            (a, b) => ExerciseOrderingRules.getScore(
              b,
            ).compareTo(ExerciseOrderingRules.getScore(a)),
          );

          final frequency = muscleConfig[normalizedMuscle]?.frequency ?? 1;
          final structures = repStructureEngine.buildForFrequency(frequency);
          final occurrence = muscleOccurrenceCount[normalizedMuscle] ?? 0;
          final structure = structures[min(occurrence, structures.length - 1)];
          muscleOccurrenceCount[normalizedMuscle] = occurrence + 1;

          final roleMap = roleEngine.classify(
            muscle: normalizedMuscle,
            pool: lockedPool,
          );
          lockedAnchorByMuscle.putIfAbsent(
            normalizedMuscle,
            () => roleMap.primaryAnchor.isNotEmpty
                ? roleMap.primaryAnchor.first.id
                : '',
          );
          final dayIntensity =
              intensityByAppearancePerMuscle[normalizedMuscle]?[occurrence + 1];
          final resolvedDayIntensity =
              dayIntensity ??
              IntensityDistributionEngine.splitWeeklySets(
                weeklySets: setsForDay,
                intensitySplitPercent: intensityProfilePercentSplit,
              );
          final (primaryZone, secondaryZone) =
              IntensityDistributionEngine.zonesForDay(resolvedDayIntensity);
          final rolePlan = _resolveSessionRolePlan(
            frequency: frequency,
            sessionIndex: occurrence,
          );
          debugPrint(
            '[V3][SESSION_ROLE_PLAN] muscle=$normalizedMuscle session=${occurrence + 1} '
            'roles=${rolePlan.map((r) => r.name).toList()}',
          );

          if (dayIntensity != null) {
            debugPrint(
              '[V3][INTENSITY_DISTRIBUTION] muscle=$normalizedMuscle session=${occurrence + 1} '
              'heavy=${dayIntensity.heavySets} medium=${dayIntensity.mediumSets} light=${dayIntensity.lightSets}',
            );
          }

          debugPrint(
            '[V3][REP_STRUCTURE] muscle=$normalizedMuscle freq=$frequency '
            'session=${occurrence + 1} '
            'ex1=${structure.firstExercise.min}-${structure.firstExercise.max} '
            'ex2=${structure.secondExercise.min}-${structure.secondExercise.max}',
          );

          final requestedExerciseCount = setsForDay <= 3 ? 1 : 2;
          final exerciseCount = min(requestedExerciseCount, maxPerMusclePerDay);

          final sessionUsedIds = daySeedExercises
              .map((e) => e.exercise.id)
              .toSet();
          final selected = _selectExercisesForMuscleDay(
            rawPoolIds: poolIds,
            pool: lockedPool,
            roleMap: roleMap,
            sessionUsedIds: sessionUsedIds,
            primaryZone: primaryZone,
            secondaryZone: secondaryZone,
            preferredRoles: rolePlan,
            desiredCount: exerciseCount,
            muscle: normalizedMuscle,
            dayNum: dayNum,
            sessionIndex: occurrence,
            lastPair: lastPairByMuscle[normalizedMuscle],
            lockedAnchorId: lockedAnchorByMuscle[normalizedMuscle],
          );

          if (selected.length >= 2) {
            final previousPair = lastPairByMuscle[normalizedMuscle];
            if (previousPair != null) {
              final status =
                  (previousPair[0] == selected[0].id &&
                      previousPair[1] == selected[1].id)
                  ? 'mirrored_limited'
                  : 'varied';
              debugPrint(
                '[V3][PAIR_VARIATION] muscle=$normalizedMuscle '
                'session$occurrence=$previousPair '
                'session${occurrence + 1}=${selected.map((e) => e.id).toList()} '
                'status=$status',
              );
            }
            lastPairByMuscle[normalizedMuscle] = [
              selected[0].id,
              selected[1].id,
            ];
          }

          if (selected.isEmpty) {
            throw StateError(
              '[B4] No exercises available for muscle=$normalizedMuscle '
              'day=$dayNum rawPool=$poolIds '
              'resolved=${lockedPool.map((e) => e.id).toList()} '
              'zone=${_intensityZoneForRepRange(structure.firstExercise)}',
            );
          }

          final slotSets = selected.length >= 2
              ? SessionIntensitySetAllocator.allocateTwoSlots(
                  totalSets: setsForDay,
                  firstRepRange: structure.firstExercise,
                  secondRepRange: structure.secondExercise,
                  firstZone: primaryZone,
                  secondZone: secondaryZone,
                  preferFrontLoaded: true,
                )
              : [setsForDay];

          debugPrint(
            '[V3][SESSION_SLOT_PLAN] '
            'muscle=$normalizedMuscle '
            'session=${occurrence + 1} '
            'slot1_zone=$primaryZone '
            'slot2_zone=$secondaryZone '
            'slot1_reps=${structure.firstExercise.min}-${structure.firstExercise.max} '
            'slot2_reps=${structure.secondExercise.min}-${structure.secondExercise.max} '
            'slot_sets=$slotSets',
          );

          debugPrint(
            '[V3][EX_ASSIGN_FINAL] muscle=$normalizedMuscle day=$dayNum '
            'exercises=${selected.map((e) => e.id).toList()} '
            'sets=$slotSets '
            'reps=['
            '${structure.firstExercise.min}-${structure.firstExercise.max},'
            '${structure.secondExercise.min}-${structure.secondExercise.max}]'
            '${selected.length == 1 ? ' reason=single_forced' : ''}',
          );

          for (var i = 0; i < selected.length; i++) {
            final chosen = selected[i];
            final repRange = i == 0
                ? structure.firstExercise
                : structure.secondExercise;
            final rir = repRange.max >= 16 ? 1 : 2;
            final setsForExercise = i < slotSets.length
                ? slotSets[i]
                : slotSets.last;

            daySeedExercises.add(
              _DayExerciseSeed(
                exercise: chosen,
                muscleKey: normalizedMuscle,
                repsMin: repRange.min,
                repsMax: repRange.max,
                rir: rir,
                baseSets: setsForExercise,
                isPrimaryRole:
                    i == 0 &&
                    rolePlan.isNotEmpty &&
                    rolePlan.first == ExerciseRole.primaryAnchor,
                preferredBlock: blockLabel,
              ),
            );
          }
        }
      }

      final sessionExercises = _buildStructuredSessionFromSeeds(
        seeds: daySeedExercises,
        dayAlloc: dayAlloc,
      );

      // B4 Session Cap Enforcement (post-build safety net)
      if (sessionExercises.length > maxPerSession) {
        _applySessionCap(sessionExercises, maxPerSession, priorities);
      }

      _validateSessionCoverage(
        dayAlloc: dayAlloc,
        sessionExercises: sessionExercises,
      );

      // Refinador: solo completa metadata faltante, nunca sobreescribe
      // una estructura A/B/C/D que ya venga construida desde el builder.
      final needsRefine = sessionExercises.any(
        (e) => e.blockLabel == null || e.slotLabel == null,
      );
      if (needsRefine) {
        final refined = SessionStructureEngine.refinePlannedExercises(
          sessionExercises,
        );
        sessionExercises
          ..clear()
          ..addAll(refined);
      }

      final estimatedMinutes = sessionTimeEstimator.estimateMinutes(
        sessionExercises,
      );
      final allowedMinutes = userProfile.sessionDuration;
      if (estimatedMinutes > (allowedMinutes + 15)) {
        debugPrint(
          '[V3][TIME_WARN] day=$dayNum estimated=$estimatedMinutes allowed=$allowedMinutes',
        );
      }

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
      const int dailyCap = 10;
      final int weeklySets = cfg.weeklySets;
      final int minDaysNeeded = (weeklySets / dailyCap).ceil();
      final int requestedFrequency = cfg.frequency;
      final int desiredFrequency = max(
        requestedFrequency,
        minDaysNeeded,
      ).clamp(1, groupDays.length);
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

      // P0.2: degradar en vez de lanzar excepción si el cap diario hace
      // imposible asignar todos los sets solicitados.
      int effectiveWeeklySets = weeklySets;
      final maxAssignableSets = assignedDays.length * dailyCap;
      if (effectiveWeeklySets > maxAssignableSets) {
        debugPrint(
          '[V3][P0.2][INFEASIBLE_DAILY_ALLOCATION] '
          'muscle="$muscle" '
          'weeklySets=$weeklySets '
          'minDaysNeeded=$minDaysNeeded '
          'assignedDays=${assignedDays.length} '
          'groupDays=${groupDays.length} '
          'cap=$dailyCap '
          'action=cap_to_$maxAssignableSets',
        );
        effectiveWeeklySets = maxAssignableSets;
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

      final sets = effectiveWeeklySets;
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
      'quads',
      'hamstrings',
      'glutes',
    };
    return largeMuscles.contains(normalized) ? 1 : 0;
  }

  static void _validateSessionCoverage({
    required Map<String, int> dayAlloc,
    required List<PlannedExercise> sessionExercises,
  }) {
    final assignedByMuscle = <String, int>{};
    for (final exercise in sessionExercises) {
      final muscle = normalizeMuscleKey(exercise.muscleKey);
      assignedByMuscle[muscle] =
          (assignedByMuscle[muscle] ?? 0) + exercise.sets.length;
    }

    for (final entry in dayAlloc.entries) {
      final normalized = normalizeMuscleKey(entry.key);
      final target = entry.value;
      final assigned = assignedByMuscle[normalized] ?? 0;
      if (assigned != target) {
        throw StateError(
          '[P0 COVERAGE FAIL] muscle=$normalized target=$target assigned=$assigned',
        );
      }
    }
  }

  static String normalizeMuscleKey(String k) {
    return muscle_registry.normalize(k) ?? k.trim().toLowerCase();
  }

  static bool _isUpperMuscle(String muscle) =>
      _upperMuscles.contains(normalizeMuscleKey(muscle));

  static bool _isLowerMuscle(String muscle) =>
      _lowerMuscles.contains(normalizeMuscleKey(muscle));

  static List<String> _applyPreferredDayOrder(
    List<String> dayMuscles,
    List<String> preferredOrder,
  ) {
    if (preferredOrder.isEmpty) return dayMuscles;

    final normalizedDay = dayMuscles.map(normalizeMuscleKey).toSet();
    final ordered = <String>[];

    for (final muscle in preferredOrder.map(normalizeMuscleKey)) {
      if (normalizedDay.contains(muscle) && !ordered.contains(muscle)) {
        ordered.add(muscle);
      }
    }

    for (final muscle in dayMuscles.map(normalizeMuscleKey)) {
      if (!ordered.contains(muscle)) {
        ordered.add(muscle);
      }
    }

    return ordered;
  }

  static Map<String, int> _canonicalizeVolumeMap(Map<String, int> source) {
    final canonical = <String, int>{};
    for (final entry in source.entries) {
      final normalized = normalizeMuscleKey(entry.key);
      canonical[normalized] = (canonical[normalized] ?? 0) + entry.value;
    }
    return canonical;
  }

  static Map<String, List<String>> _canonicalizeExercisePool(
    Map<String, List<String>> source,
  ) {
    final canonical = <String, List<String>>{};
    for (final entry in source.entries) {
      final normalized = normalizeMuscleKey(entry.key);
      final current = canonical.putIfAbsent(normalized, () => <String>[]);
      for (final exerciseId in entry.value) {
        if (!current.contains(exerciseId)) {
          current.add(exerciseId);
        }
      }
    }
    return canonical;
  }

  static List<Exercise> _selectExercisesForMuscleDay({
    required List<String> rawPoolIds,
    required List<Exercise> pool,
    required MuscleExerciseRoleMap roleMap,
    required Set<String> sessionUsedIds,
    required String primaryZone,
    required String secondaryZone,
    required List<ExerciseRole> preferredRoles,
    required int desiredCount,
    required String muscle,
    required int dayNum,
    required int sessionIndex,
    required List<String>? lastPair,
    required String? lockedAnchorId,
  }) {
    final firstRole = preferredRoles.isNotEmpty
        ? preferredRoles.first
        : ExerciseRole.primaryAnchor;
    final secondRole = preferredRoles.length > 1
        ? preferredRoles[1]
        : ExerciseRole.secondarySupport;

    final firstRolePool = _poolForRole(
      muscle: muscle,
      fullPool: pool,
      roleMap: roleMap,
      preferredRole: firstRole,
    );

    // a) exact intensity + exact role
    var firstIntensitySelection = _selectByPreferredZone(
      pool: _filterByIntensityZone(firstRolePool, primaryZone),
      desiredZone: primaryZone,
    );
    // b) exact intensity + same muscle + unused
    if (firstIntensitySelection.candidates.isEmpty) {
      firstIntensitySelection = _selectByPreferredZone(
        pool: _filterByIntensityZone(pool, primaryZone),
        desiredZone: primaryZone,
      );
    }
    // c) same role + fallback intensity
    if (firstIntensitySelection.candidates.isEmpty) {
      firstIntensitySelection = _selectByPreferredZone(
        pool: firstRolePool,
        desiredZone: primaryZone,
      );
    }
    // d/e fallback to same muscle/accessory path
    if (firstIntensitySelection.candidates.isEmpty) {
      final accessoryPool = roleMap.accessory.isNotEmpty
          ? roleMap.accessory
          : pool;
      firstIntensitySelection = _selectByPreferredZone(
        pool: accessoryPool,
        desiredZone: primaryZone,
      );
    }

    debugPrint(
      '[B4][POOL_AFTER_INTENSITY] muscle=$muscle day=$dayNum desired_zone=$primaryZone '
      'used_zone=${firstIntensitySelection.usedZone} '
      'ids=${firstIntensitySelection.candidates.map((e) => e.id).toList()}',
    );

    final firstAfterEq = List<Exercise>.from(
      firstIntensitySelection.candidates,
    );
    debugPrint(
      '[B4][POOL_AFTER_EQ] muscle=$muscle day=$dayNum desired_zone=$primaryZone '
      'ids=${firstAfterEq.map((e) => e.id).toList()}',
    );

    final firstAfterDayFilter = firstAfterEq
        .where((ex) => !sessionUsedIds.contains(ex.id))
        .toList();
    var rotatedFirst = _rotateCandidates(
      firstAfterDayFilter,
      seed: sessionIndex,
    );
    if (lockedAnchorId != null &&
        lockedAnchorId.isNotEmpty &&
        rotatedFirst.any((e) => e.id == lockedAnchorId)) {
      final locked = rotatedFirst.firstWhere((e) => e.id == lockedAnchorId);
      rotatedFirst = [
        locked,
        ...rotatedFirst.where((e) => e.id != lockedAnchorId),
      ];
    }
    debugPrint(
      '[B4][POOL_AFTER_DAY_FILTER] muscle=$muscle day=$dayNum desired_zone=$primaryZone '
      'ids=${rotatedFirst.map((e) => e.id).toList()}',
    );

    if (rotatedFirst.isEmpty) {
      throw StateError(
        '[B4] No exercises available for muscle=$muscle day=$dayNum '
        'rawPool=$rawPoolIds resolved=${pool.map((e) => e.id).toList()} '
        'zone=$primaryZone',
      );
    }

    final chosenFirst = rotatedFirst.first;
    if (desiredCount <= 1) {
      return [chosenFirst];
    }

    final firstEqGroup = ExerciseCatalogV3.getEquivalenceGroup(chosenFirst.id);
    final secondRolePoolFull = _poolForRole(
      muscle: muscle,
      fullPool: pool,
      roleMap: roleMap,
      preferredRole: secondRole,
    );
    final secondRolePool = secondRolePoolFull
        .where((ex) => ex.id != chosenFirst.id)
        .toList();

    // a) exact intensity + exact role + diff equivalence
    var secondCandidates = _filterByIntensityZone(secondRolePool, secondaryZone)
        .where((candidate) {
          final secondEq = ExerciseCatalogV3.getEquivalenceGroup(candidate.id);
          return firstEqGroup == null ||
              secondEq == null ||
              firstEqGroup != secondEq;
        })
        .toList();
    // b) exact intensity + same muscle + unused
    if (secondCandidates.isEmpty) {
      secondCandidates = _filterByIntensityZone(pool, secondaryZone)
          .where((ex) => ex.id != chosenFirst.id)
          .where((candidate) {
            final secondEq = ExerciseCatalogV3.getEquivalenceGroup(
              candidate.id,
            );
            return firstEqGroup == null ||
                secondEq == null ||
                firstEqGroup != secondEq;
          })
          .toList();
    }
    // c) same role + fallback intensity
    if (secondCandidates.isEmpty) {
      secondCandidates =
          _selectByPreferredZone(
            pool: secondRolePool,
            desiredZone: secondaryZone,
          ).candidates.where((candidate) {
            final secondEq = ExerciseCatalogV3.getEquivalenceGroup(
              candidate.id,
            );
            return firstEqGroup == null ||
                secondEq == null ||
                firstEqGroup != secondEq;
          }).toList();
    }
    // d) same muscle + different equivalence group
    if (secondCandidates.isEmpty) {
      secondCandidates = pool.where((ex) => ex.id != chosenFirst.id).where((
        candidate,
      ) {
        final secondEq = ExerciseCatalogV3.getEquivalenceGroup(candidate.id);
        return firstEqGroup == null ||
            secondEq == null ||
            firstEqGroup != secondEq;
      }).toList();
    }
    // e) accessory fallback
    if (secondCandidates.isEmpty) {
      final accessoryPool = roleMap.accessory
          .where((ex) => ex.id != chosenFirst.id)
          .toList();
      secondCandidates = _selectByPreferredZone(
        pool: accessoryPool,
        desiredZone: secondaryZone,
      ).candidates;
    }

    // allow same equivalence as last resort before single.
    if (secondCandidates.isEmpty) {
      secondCandidates = _selectByPreferredZone(
        pool: secondRolePool,
        desiredZone: secondaryZone,
      ).candidates;
    }

    final secondIntensitySelection = _ZoneSelection(
      usedZone: secondaryZone,
      candidates: secondCandidates,
    );
    debugPrint(
      '[B4][POOL_AFTER_INTENSITY] muscle=$muscle day=$dayNum desired_zone=$secondaryZone '
      'used_zone=${secondIntensitySelection.usedZone} '
      'ids=${secondIntensitySelection.candidates.map((e) => e.id).toList()}',
    );

    var secondAfterEq = secondIntensitySelection.candidates.where((candidate) {
      final secondEqGroup = ExerciseCatalogV3.getEquivalenceGroup(candidate.id);
      if (firstEqGroup == null || secondEqGroup == null) return true;
      return firstEqGroup != secondEqGroup;
    }).toList();
    if (secondAfterEq.isEmpty) {
      secondAfterEq = List<Exercise>.from(secondIntensitySelection.candidates);
      debugPrint(
        '[V3][ROLE_FALLBACK] muscle=$muscle reason=eq_exhausted used=same_equivalence_group',
      );
    }
    debugPrint(
      '[B4][POOL_AFTER_EQ] muscle=$muscle day=$dayNum desired_zone=$secondaryZone '
      'ids=${secondAfterEq.map((e) => e.id).toList()}',
    );

    final secondAfterDayFilter = secondAfterEq
        .where((ex) => !sessionUsedIds.contains(ex.id))
        .toList();
    final rotatedSecond = _rotateCandidates(
      secondAfterDayFilter,
      seed: sessionIndex + 1,
    );
    debugPrint(
      '[B4][POOL_AFTER_DAY_FILTER] muscle=$muscle day=$dayNum desired_zone=$secondaryZone '
      'ids=${rotatedSecond.map((e) => e.id).toList()}',
    );

    if (rotatedSecond.isEmpty) {
      debugPrint(
        '[V3][ROLE_FALLBACK] muscle=$muscle reason=limited_pool used=single_only',
      );
      return [chosenFirst];
    }

    for (final candidate in rotatedSecond) {
      final secondEqGroup = ExerciseCatalogV3.getEquivalenceGroup(candidate.id);
      if (firstEqGroup == null || secondEqGroup == null) {
        return _applyPairVariation(
          first: chosenFirst,
          candidate: candidate,
          alternatives: rotatedSecond,
          lastPair: lastPair,
        );
      }
      if (firstEqGroup != secondEqGroup) {
        debugPrint(
          '[V3][EQ_GROUP_FILTER] muscle=$muscle day=$dayNum first=$firstEqGroup second=$secondEqGroup result=ok',
        );
        return _applyPairVariation(
          first: chosenFirst,
          candidate: candidate,
          alternatives: rotatedSecond,
          lastPair: lastPair,
        );
      }
    }

    debugPrint(
      '[V3][EQ_GROUP_FILTER] muscle=$muscle day=$dayNum first=$firstEqGroup result=fallback_single',
    );
    return [chosenFirst];
  }

  static List<ExerciseRole> _resolveSessionRolePlan({
    required int frequency,
    required int sessionIndex,
  }) {
    if (frequency <= 1) {
      return const [ExerciseRole.primaryAnchor];
    }
    if (frequency == 2) {
      return sessionIndex == 0
          ? const [ExerciseRole.primaryAnchor, ExerciseRole.secondarySupport]
          : const [ExerciseRole.primaryAnchor, ExerciseRole.accessory];
    }

    final mod = sessionIndex % 3;
    if (mod == 1) {
      return const [ExerciseRole.primaryAnchor, ExerciseRole.accessory];
    }
    if (mod == 2) {
      return const [ExerciseRole.secondarySupport, ExerciseRole.accessory];
    }
    return const [ExerciseRole.primaryAnchor, ExerciseRole.secondarySupport];
  }

  static List<Exercise> _poolForRole({
    required String muscle,
    required List<Exercise> fullPool,
    required MuscleExerciseRoleMap roleMap,
    required ExerciseRole preferredRole,
  }) {
    final rolePool = roleMap.forRole(preferredRole);
    if (rolePool.isNotEmpty) return rolePool;
    debugPrint(
      '[V3][ROLE_FALLBACK] muscle=$muscle reason=limited_pool used=${preferredRole.name}->any',
    );
    return fullPool;
  }

  static List<Exercise> _rotateCandidates(List<Exercise> list, {int seed = 0}) {
    if (list.length <= 1) return list;
    final shift = seed % list.length;
    return [...list.sublist(shift), ...list.sublist(0, shift)];
  }

  static List<Exercise> _applyPairVariation({
    required Exercise first,
    required Exercise candidate,
    required List<Exercise> alternatives,
    required List<String>? lastPair,
  }) {
    if (lastPair == null || lastPair.length < 2) {
      return [first, candidate];
    }
    if (lastPair[0] != first.id || lastPair[1] != candidate.id) {
      return [first, candidate];
    }

    for (final alt in alternatives) {
      if (alt.id != candidate.id && alt.id != first.id) {
        return [first, alt];
      }
    }

    return [first, candidate];
  }

  static List<Exercise> _filterByIntensityZone(
    List<Exercise> pool,
    String zone,
  ) {
    return pool.where((exercise) {
      final allowed = ExerciseCatalogV3.getAllowedIntensityZones(exercise.id);
      return allowed[zone] == true;
    }).toList();
  }

  static _ZoneSelection _selectByPreferredZone({
    required List<Exercise> pool,
    required String desiredZone,
  }) {
    final desiredCandidates = _filterByIntensityZone(pool, desiredZone);
    if (desiredCandidates.isNotEmpty) {
      return _ZoneSelection(
        usedZone: desiredZone,
        candidates: desiredCandidates,
      );
    }

    final mediumCandidates = _filterByIntensityZone(pool, 'medium');
    if (mediumCandidates.isNotEmpty) {
      return _ZoneSelection(usedZone: 'medium', candidates: mediumCandidates);
    }

    return _ZoneSelection(
      usedZone: 'any',
      candidates: List<Exercise>.from(pool),
    );
  }

  static String _intensityZoneForRepRange(RepRange range) {
    if (range.max <= 8) return 'heavy';
    if (range.min >= 16) return 'light';
    return 'medium';
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

  static List<PlannedExercise> _buildStructuredSessionFromSeeds({
    required List<_DayExerciseSeed> seeds,
    required Map<String, int> dayAlloc,
  }) {
    final sessionExercises = seeds
        .map(
          (seed) => PlannedExercise(
            exerciseId: seed.exercise.id,
            name: seed.exercise.name,
            muscleKey: seed.muscleKey,
            primaryMuscle: _exercisePrimaryMuscle(seed.exercise),
            secondaryMuscles: List<String>.from(seed.exercise.secondaryMuscles),
            sets: List.generate(
              max(1, seed.baseSets),
              (_) => SetPrescription(
                repsMin: seed.repsMin,
                repsMax: seed.repsMax,
                rir: seed.rir,
              ),
            ),
          ),
        )
        .toList();

    final structuredData = _buildStructuredSessionDataFromSeeds(seeds);
    _applyStructuredSessionData(sessionExercises, structuredData);
    _allocateSetsByBlockAndMuscle(sessionExercises, dayAlloc);
    return sessionExercises;
  }

  static _StructuredSessionData _buildStructuredSessionDataFromSeeds(
    List<_DayExerciseSeed> seeds,
  ) {
    if (seeds.isEmpty) {
      return const _StructuredSessionData(orderedIds: <String>[]);
    }

    if (seeds.length == 1) {
      final single = seeds.first.exercise;
      return _StructuredSessionData(
        orderedIds: <String>[single.id],
        placementByExerciseId: <String, StructuredExercisePlacement>{
          single.id: StructuredExercisePlacement(
            exerciseId: single.id,
            blockLabel: 'A',
            slotLabel: 'A',
            isMainLift: true,
          ),
        },
      );
    }

    final sortedForMain = List<_DayExerciseSeed>.from(seeds)
      ..sort((a, b) {
        int compareBool(bool x, bool y) => (y ? 1 : 0).compareTo(x ? 1 : 0);

        final byPreferredBlock = compareBool(
          a.preferredBlock == 'A',
          b.preferredBlock == 'A',
        );
        if (byPreferredBlock != 0) return byPreferredBlock;

        final byRole = compareBool(a.isPrimaryRole, b.isPrimaryRole);
        if (byRole != 0) return byRole;

        final byHeavy = compareBool(
          _isHeavyExercise(a.exercise),
          _isHeavyExercise(b.exercise),
        );
        if (byHeavy != 0) return byHeavy;

        final byCompound = compareBool(
          _isCompoundExercise(a.exercise),
          _isCompoundExercise(b.exercise),
        );
        if (byCompound != 0) return byCompound;

        return ExerciseOrderingEngine.scoreFor(
          b.exercise,
        ).compareTo(ExerciseOrderingEngine.scoreFor(a.exercise));
      });

    final main = sortedForMain.first;
    final mainMuscle = _exercisePrimaryMuscle(main.exercise);
    final remaining = seeds
        .where((seed) => seed.exercise.id != main.exercise.id)
        .toList();

    // Pass 1: classify each remaining seed by its relationship to the main lift.
    // Order: antagonists (B) → low-interference (B/C) → same-muscle secondary (C)
    //         → accessories (D) → other (C if compatible, else D)
    final antagonistSeeds = <_DayExerciseSeed>[];
    final lowInterferenceSeeds = <_DayExerciseSeed>[];
    final sameMuscleAsA =
        <_DayExerciseSeed>[]; // secondary exercise of same muscle as A
    final accessorySeeds = <_DayExerciseSeed>[];
    final otherSeeds = <_DayExerciseSeed>[];

    for (final seed in remaining) {
      final currentMuscle = _exercisePrimaryMuscle(seed.exercise);
      if (seed.preferredBlock == 'D') {
        accessorySeeds.add(seed);
        continue;
      }
      if (seed.preferredBlock == 'B') {
        if (AntagonistPairingEngine.areAntagonists(mainMuscle, currentMuscle)) {
          antagonistSeeds.add(seed);
        } else {
          lowInterferenceSeeds.add(seed);
        }
        continue;
      }
      if (currentMuscle == mainMuscle) {
        // Same primary muscle as main lift → secondary A support → block C
        sameMuscleAsA.add(seed);
        continue;
      }
      if (AntagonistPairingEngine.areAntagonists(mainMuscle, currentMuscle)) {
        antagonistSeeds.add(seed);
        continue;
      }
      if (_isAccessoryExercise(seed.exercise)) {
        accessorySeeds.add(seed);
        continue;
      }
      if (_isLowInterference(mainMuscle, currentMuscle)) {
        lowInterferenceSeeds.add(seed);
        continue;
      }
      otherSeeds.add(seed);
    }

    // Block B: true antagonists first; fill to 2 with low-interference if needed.
    final blockBSeeds = <_DayExerciseSeed>[...antagonistSeeds.take(2)];
    if (blockBSeeds.length < 2) {
      final bMusclesUsed = blockBSeeds
          .map((s) => _exercisePrimaryMuscle(s.exercise))
          .toSet();
      for (final seed in lowInterferenceSeeds) {
        if (blockBSeeds.length >= 2) break;
        final m = _exercisePrimaryMuscle(seed.exercise);
        if (!bMusclesUsed.contains(m)) {
          blockBSeeds.add(seed);
          bMusclesUsed.add(m);
        }
      }
    }
    final usedB = blockBSeeds.map((seed) => seed.exercise.id).toSet();
    final bMusclesSet = blockBSeeds
        .map((s) => _exercisePrimaryMuscle(s.exercise))
        .toSet();

    // Block C: low-interference not already in B + same-A-muscle secondary +
    //          compatible otherSeeds (not antagonist of any B exercise).
    final blockCCandidates = <_DayExerciseSeed>[
      ...lowInterferenceSeeds.where((s) => !usedB.contains(s.exercise.id)),
      ...sameMuscleAsA,
      ...otherSeeds.where((s) {
        final seedMuscle = _exercisePrimaryMuscle(s.exercise);
        final fatigue = _systemicFatigueScore(s.exercise);
        return bMusclesSet.every(
              (bm) => !AntagonistPairingEngine.areAntagonists(bm, seedMuscle),
            ) &&
            fatigue <= 3;
      }),
    ];
    final blockCSeeds = blockCCandidates.take(2).toList();
    final usedC = blockCSeeds.map((seed) => seed.exercise.id).toSet();

    // Block D: pure accessories + remaining high-interference exercises.
    final blockDSeeds = <_DayExerciseSeed>[
      ...accessorySeeds,
      ...remaining.where(
        (seed) =>
            !usedB.contains(seed.exercise.id) &&
            !usedC.contains(seed.exercise.id),
      ),
    ];

    void sortByQuality(List<_DayExerciseSeed> list) {
      list.sort(
        (a, b) => ExerciseOrderingEngine.scoreFor(
          b.exercise,
        ).compareTo(ExerciseOrderingEngine.scoreFor(a.exercise)),
      );
    }

    sortByQuality(blockBSeeds);
    sortByQuality(blockCSeeds);
    blockDSeeds.sort(
      (a, b) => _systemicFatigueScore(
        a.exercise,
      ).compareTo(_systemicFatigueScore(b.exercise)),
    );

    final blockPlans = <_SessionBlockPlan>[
      _SessionBlockPlan(
        blockLabel: 'A',
        exercises: <Exercise>[main.exercise],
        isMainLiftBlock: true,
      ),
      if (blockBSeeds.isNotEmpty)
        _SessionBlockPlan(
          blockLabel: 'B',
          exercises: blockBSeeds.take(2).map((seed) => seed.exercise).toList(),
        ),
      if (blockCSeeds.isNotEmpty)
        _SessionBlockPlan(
          blockLabel: 'C',
          exercises: blockCSeeds.take(2).map((seed) => seed.exercise).toList(),
        ),
      if (blockDSeeds.isNotEmpty)
        _SessionBlockPlan(
          blockLabel: 'D',
          exercises: blockDSeeds.take(2).map((seed) => seed.exercise).toList(),
        ),
    ];

    final orderedIds = <String>[];
    final placements = <String, StructuredExercisePlacement>{};

    for (final block in blockPlans) {
      if (block.blockLabel == 'A') {
        final exercise = block.exercises.first;
        orderedIds.add(exercise.id);
        placements[exercise.id] = StructuredExercisePlacement(
          exerciseId: exercise.id,
          blockLabel: 'A',
          slotLabel: 'A',
          isMainLift: true,
        );
        continue;
      }

      final pairGroupId = block.exercises.length >= 2
          ? '${block.blockLabel}_1'
          : null;
      for (var index = 0; index < block.exercises.length; index++) {
        final exercise = block.exercises[index];
        final slot = '${block.blockLabel}${index + 1}';
        orderedIds.add(exercise.id);
        placements[exercise.id] = StructuredExercisePlacement(
          exerciseId: exercise.id,
          blockLabel: block.blockLabel,
          slotLabel: slot,
          pairGroupId: pairGroupId,
          isMainLift: false,
        );
      }
    }

    return _StructuredSessionData(
      orderedIds: orderedIds,
      placementByExerciseId: placements,
    );
  }

  static void _allocateSetsByBlockAndMuscle(
    List<PlannedExercise> exercises,
    Map<String, int> dayAlloc,
  ) {
    if (exercises.isEmpty) return;

    // Keep volume SSOT per muscle and distribute only inside each muscle.
    final indexesByMuscle = <String, List<int>>{};
    for (var index = 0; index < exercises.length; index++) {
      final muscle = normalizeMuscleKey(exercises[index].muscleKey);
      indexesByMuscle.putIfAbsent(muscle, () => <int>[]).add(index);
    }

    for (final entry in dayAlloc.entries) {
      final muscle = normalizeMuscleKey(entry.key);
      final targetSetsForMuscle = entry.value;
      final indexes = indexesByMuscle[muscle] ?? const <int>[];
      if (indexes.isEmpty || targetSetsForMuscle <= 0) continue;

      final blockLabels = indexes.map((i) => exercises[i].blockLabel).toList();
      final allocation = ExerciseSetAllocator.allocateSets(
        targetSetsForMuscle,
        indexes.length,
        blockLabelsByIndex: blockLabels,
      );

      for (var localIndex = 0; localIndex < indexes.length; localIndex++) {
        final exerciseIndex = indexes[localIndex];
        final current = exercises[exerciseIndex];
        final targetSets = max(
          1,
          allocation['ex$localIndex'] ?? current.sets.length,
        );
        if (targetSets == current.sets.length) continue;

        final template = current.sets.isNotEmpty
            ? current.sets.first
            : const SetPrescription(repsMin: 8, repsMax: 12, rir: 2);
        exercises[exerciseIndex] = current.copyWith(
          sets: List.generate(targetSets, (_) => template),
        );
      }
    }
  }

  static bool _isCompoundExercise(Exercise exercise) {
    final type = ExerciseCatalogV3.getTypeById(exercise.id);
    if (type == 'compound') return true;
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    return metadata['movementType']?.toString() == 'compound';
  }

  static bool _isHeavyExercise(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    return metadata['loadCategory']?.toString() == 'heavy';
  }

  static bool _isAccessoryExercise(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    return metadata['category']?.toString() == 'isolation';
  }

  static int _systemicFatigueScore(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    final raw = metadata['fatigueScore'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 2;
  }

  static bool _isLowInterference(String a, String b) {
    final lowA = InterferenceMatrix.lowInterference[a] ?? const <String>[];
    final lowB = InterferenceMatrix.lowInterference[b] ?? const <String>[];
    return lowA.contains(b) || lowB.contains(a);
  }

  static String _exercisePrimaryMuscle(Exercise exercise) {
    if (exercise.primaryMuscles.isNotEmpty) {
      return normalizeMuscleKey(exercise.primaryMuscles.first);
    }
    return normalizeMuscleKey(exercise.muscleKey);
  }

  /// Returns the muscle with the most allocated sets for the day.
  /// Ties are broken by priority (higher priority wins).
  static String _findPrimaryMuscleForDay(
    Map<String, int> dayAlloc,
    Map<String, int> priorities,
  ) {
    if (dayAlloc.isEmpty) {
      return '';
    }
    return dayAlloc.keys.reduce((a, b) {
      final aScore = (dayAlloc[a] ?? 0) * 10 + (priorities[a] ?? 0);
      final bScore = (dayAlloc[b] ?? 0) * 10 + (priorities[b] ?? 0);
      return aScore >= bScore ? a : b;
    });
  }

  /// Orders muscles by block affinity relative to [primaryMuscle].
  /// Order: primary → antagonists of primary → low-interference → rest.
  static List<String> _orderMusclesByBlockPriority(
    List<String> muscles, {
    required String primaryMuscle,
  }) {
    return List<String>.from(muscles)..sort((a, b) {
      if (a == primaryMuscle) return -1;
      if (b == primaryMuscle) return 1;
      final aIsAntagonist = AntagonistPairingEngine.areAntagonists(
        primaryMuscle,
        a,
      );
      final bIsAntagonist = AntagonistPairingEngine.areAntagonists(
        primaryMuscle,
        b,
      );
      if (aIsAntagonist && !bIsAntagonist) return -1;
      if (!aIsAntagonist && bIsAntagonist) return 1;
      final aIsLow = _isLowInterference(primaryMuscle, a);
      final bIsLow = _isLowInterference(primaryMuscle, b);
      if (aIsLow && !bIsLow) return -1;
      if (!aIsLow && bIsLow) return 1;
      return 0;
    });
  }

  static Map<String, List<String>> _buildDayBlockMusclePlan(
    List<String> orderedMuscles, {
    required String primaryMuscle,
  }) {
    final plan = <String, List<String>>{
      'A': <String>[],
      'B': <String>[],
      'C': <String>[],
      'D': <String>[],
    };
    if (orderedMuscles.isEmpty) return plan;

    final remaining = <String>[...orderedMuscles];
    remaining.remove(primaryMuscle);
    plan['A']!.add(primaryMuscle);

    bool isAccessoryMuscle(String m) =>
        m == 'calves' ||
        m == 'abs' ||
        m == 'biceps' ||
        m == 'triceps' ||
        m == 'traps';

    final bCandidates = remaining.where((m) {
      return AntagonistPairingEngine.areAntagonists(primaryMuscle, m) ||
          _isLowInterference(primaryMuscle, m);
    }).toList();
    for (final muscle in bCandidates.take(2)) {
      plan['B']!.add(muscle);
      remaining.remove(muscle);
    }

    final cCandidates = remaining.where((m) {
      if (isAccessoryMuscle(m)) return false;
      return !plan['B']!.any(
        (b) => AntagonistPairingEngine.areAntagonists(b, m),
      );
    }).toList();
    for (final muscle in cCandidates.take(2)) {
      plan['C']!.add(muscle);
      remaining.remove(muscle);
    }

    plan['D']!.addAll(remaining);
    return plan;
  }

  static void _applyStructuredSessionData(
    List<PlannedExercise> sessionExercises,
    _StructuredSessionData data,
  ) {
    final orderedIds = data.orderedIds;
    final rank = <String, int>{};
    for (var index = 0; index < orderedIds.length; index++) {
      rank[orderedIds[index]] = index;
    }

    final originalIndex = <String, int>{};
    for (var index = 0; index < sessionExercises.length; index++) {
      originalIndex[sessionExercises[index].id] = index;
    }

    sessionExercises.sort((a, b) {
      final rankA = rank[a.exerciseId] ?? 1 << 20;
      final rankB = rank[b.exerciseId] ?? 1 << 20;
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      return (originalIndex[a.id] ?? 0).compareTo(originalIndex[b.id] ?? 0);
    });

    for (var i = 0; i < sessionExercises.length; i++) {
      final current = sessionExercises[i];
      // Refinador: preserve existing structural metadata if already set.
      if (current.blockLabel != null && current.slotLabel != null) continue;
      final placement = data.placementByExerciseId[current.exerciseId];
      if (placement == null) continue;
      sessionExercises[i] = current.copyWith(
        slotLabel: placement.slotLabel,
        blockLabel: placement.blockLabel,
        pairGroupId: placement.pairGroupId,
        isMainLift: placement.isMainLift,
      );
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

class _ZoneSelection {
  final String usedZone;
  final List<Exercise> candidates;

  const _ZoneSelection({required this.usedZone, required this.candidates});
}

class _StructuredSessionData {
  final List<String> orderedIds;
  final Map<String, StructuredExercisePlacement> placementByExerciseId;

  const _StructuredSessionData({
    required this.orderedIds,
    this.placementByExerciseId = const <String, StructuredExercisePlacement>{},
  });
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

/// Represents a structured block plan for a training session.
///
/// Used internally by [CycleTemplateBuilder] to model the A/B/C/D block
/// layout. The [blockWeight] values drive proportional set distribution
/// (spec §7.7): A gets more sets, D gets fewer.
class _SessionBlockPlan {
  final String blockLabel;
  final List<Exercise> exercises;
  final bool isMainLiftBlock;

  const _SessionBlockPlan({
    required this.blockLabel,
    required this.exercises,
    this.isMainLiftBlock = false,
  });
}

class _DayExerciseSeed {
  final Exercise exercise;
  final String muscleKey;
  final int repsMin;
  final int repsMax;
  final int rir;
  final int baseSets;
  final bool isPrimaryRole;
  final String preferredBlock;

  const _DayExerciseSeed({
    required this.exercise,
    required this.muscleKey,
    required this.repsMin,
    required this.repsMax,
    required this.rir,
    required this.baseSets,
    required this.isPrimaryRole,
    required this.preferredBlock,
  });
}
