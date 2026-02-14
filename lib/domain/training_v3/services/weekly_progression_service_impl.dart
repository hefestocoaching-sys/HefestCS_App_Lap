// lib/domain/training_v3/services/weekly_progression_service_impl.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/weekly_adaptation_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_metrics.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_feedback_collector.dart';

import 'weekly_progression_service.dart';

/// Implementation of WeeklyProgressionService
///
/// ARCHITECTURE:
/// - Uses dependency injection for repositories
/// - Handles errors gracefully (continue processing other muscles)
/// - Logs detailed debug information
/// - Validates input data
///
/// Version: 1.0.0
class WeeklyProgressionServiceImpl implements WeeklyProgressionService {
  final MuscleProgressionRepository _progressionRepo;
  final WeeklyMuscleAnalysisRepository _analysisRepo;
  final Map<String, Set<String>> _exerciseIdToMuscles = {};
  bool _missingCatalogWarned = false;

  WeeklyProgressionServiceImpl({
    required MuscleProgressionRepository progressionRepo,
    required WeeklyMuscleAnalysisRepository analysisRepo,
  }) : _progressionRepo = progressionRepo,
       _analysisRepo = analysisRepo;

  @override
  Future<Map<String, MuscleDecision>> processWeeklyProgression({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, Map<String, dynamic>> userFeedbackByMuscle,
  }) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint(
      '[WeeklyProgression] Processing week $weekNumber for user $userId',
    );
    debugPrint('[WeeklyProgression] Total logs: ${exerciseLogs.length}');
    debugPrint(
      '[WeeklyProgression] Muscles with feedback: ${userFeedbackByMuscle.keys.length}',
    );
    debugPrint('═══════════════════════════════════════════════════════');

    final decisions = <String, MuscleDecision>{};
    final errors = <String, String>{};

    // Get all current trackers
    final allTrackers = await _progressionRepo.getAllTrackers(userId: userId);

    if (allTrackers.isEmpty) {
      debugPrint(
        '[WeeklyProgression] ⚠️ No trackers found. User needs initialization.',
      );
      throw Exception(
        'User $userId has no muscle trackers. Run initializeAllTrackers first.',
      );
    }

    debugPrint('[WeeklyProgression] Found ${allTrackers.length} trackers');

    // Process each muscle
    for (final muscle in muscle_registry.canonicalMuscles) {
      try {
        debugPrint('');
        debugPrint('[WeeklyProgression] ─────────────────────────────────');
        debugPrint('[WeeklyProgression] Processing: $muscle');

        // Get muscle-specific data
        final muscleLogs = exerciseLogs.where((log) {
          // Filter logs for this muscle
          return _isLogForMuscle(log, muscle);
        }).toList();

        final feedback = userFeedbackByMuscle[muscle] ?? _getDefaultFeedback();
        final tracker = allTrackers[muscle];

        if (tracker == null) {
          debugPrint('[WeeklyProgression] ⚠️ No tracker for $muscle, skipping');
          errors[muscle] = 'No tracker found';
          continue;
        }

        // Get prescribed sets (from tracker's current volume)
        final prescribedSets = tracker.currentVolume;
        const prescribedRir = 2; // Default RIR, could be dynamic

        debugPrint(
          '[WeeklyProgression] Logs: ${muscleLogs.length}, Prescribed: $prescribedSets sets',
        );

        // Process this muscle
        final decision = await processMuscleProgression(
          userId: userId,
          muscle: muscle,
          weekNumber: weekNumber,
          weekStart: weekStart,
          weekEnd: weekEnd,
          exerciseLogs: muscleLogs,
          prescribedSets: prescribedSets,
          prescribedRir: prescribedRir,
          userFeedback: feedback,
        );

        decisions[muscle] = decision;

        debugPrint('[WeeklyProgression] ✅ Decision: ${decision.action.name}');
        debugPrint(
          '[WeeklyProgression]    Volume: ${tracker.currentVolume} → ${decision.newVolume}',
        );
        debugPrint(
          '[WeeklyProgression]    Phase: ${tracker.currentPhase.name} → ${decision.newPhase.name}',
        );
        debugPrint('[WeeklyProgression]    Reason: ${decision.reason}');
      } catch (e, stackTrace) {
        debugPrint('[WeeklyProgression] ❌ Error processing $muscle: $e');
        debugPrint('[WeeklyProgression] Stack trace: $stackTrace');
        errors[muscle] = e.toString();

        // Create fallback "maintain" decision
        decisions[muscle] = MuscleDecisionHelpers.noChange(
          muscle: muscle,
          reason: 'Error processing: ${e.toString()}',
        );
      }
    }

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[WeeklyProgression] Week $weekNumber COMPLETE');
    debugPrint('[WeeklyProgression] Decisions: ${decisions.length}');
    debugPrint('[WeeklyProgression] Errors: ${errors.length}');
    if (errors.isNotEmpty) {
      debugPrint(
        '[WeeklyProgression] Failed muscles: ${errors.keys.join(", ")}',
      );
    }
    debugPrint('═══════════════════════════════════════════════════════');

    return decisions;
  }

  @override
  Future<MuscleDecision> processMuscleProgression({
    required String userId,
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required int prescribedSets,
    required int prescribedRir,
    required Map<String, dynamic> userFeedback,
  }) async {
    // ═══════════════════════════════════════════════════════════════
    // STEP 1: Get current tracker
    // ═══════════════════════════════════════════════════════════════

    final tracker = await _progressionRepo.getTracker(
      userId: userId,
      muscle: muscle,
    );

    if (tracker == null) {
      throw Exception('No tracker found for $muscle (user: $userId)');
    }

    // ═══════════════════════════════════════════════════════════════
    // STEP 2: Get previous week's analysis (for comparison)
    // ═══════════════════════════════════════════════════════════════

    final previousAnalysis = weekNumber > 1
        ? await _analysisRepo.getAnalysis(
            userId: userId,
            muscle: muscle,
            weekNumber: weekNumber - 1,
          )
        : null;

    // ═══════════════════════════════════════════════════════════════
    // STEP 3: Build weekly analysis (objective + subjective data)
    // ═══════════════════════════════════════════════════════════════

    final analysis = WeeklyFeedbackCollector.buildAnalysis(
      muscle: muscle,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      exerciseLogs: exerciseLogs,
      prescribedSets: prescribedSets,
      prescribedRir: prescribedRir,
      previousAnalysis: previousAnalysis,
      userFeedback: userFeedback,
    );

    debugPrint('[WeeklyProgression]    Analysis generated:');
    debugPrint(
      '[WeeklyProgression]      Adherence: ${(analysis.volumeAdherence * 100).toStringAsFixed(0)}%',
    );
    debugPrint(
      '[WeeklyProgression]      Load change: ${analysis.loadChange.toStringAsFixed(1)}%',
    );
    debugPrint(
      '[WeeklyProgression]      RIR deviation: ${analysis.rirDeviation.toStringAsFixed(1)}',
    );
    debugPrint(
      '[WeeklyProgression]      Recovery: ${analysis.recoveryQuality.toStringAsFixed(1)}/10',
    );
    debugPrint(
      '[WeeklyProgression]      Fatigue: ${analysis.fatigueLevel.toStringAsFixed(1)}/10',
    );

    // ═══════════════════════════════════════════════════════════════
    // STEP 4: Generate decision (AI/rules-based)
    // ═══════════════════════════════════════════════════════════════

    final decision = WeeklyAdaptationEngine.analyzeAndDecide(
      tracker: tracker,
      analysis: analysis,
    );

    // ═══════════════════════════════════════════════════════════════
    // STEP 5: Apply decision to tracker (update state)
    // ═══════════════════════════════════════════════════════════════

    final updatedTracker = applyDecisionToTracker(
      tracker: tracker,
      decision: decision,
      weekNumber: weekNumber,
    );

    // ═══════════════════════════════════════════════════════════════
    // STEP 6: Add weekly metrics to history
    // ═══════════════════════════════════════════════════════════════

    final metrics = WeeklyMuscleMetrics(
      weekNumber: weekNumber,
      volume: decision.newVolume,
      loadChange: analysis.loadChange,
      rirDeviation: analysis.rirDeviation,
      adherence: analysis.volumeAdherence,
      recoveryQuality: analysis.recoveryQuality,
      fatigueLevel: analysis.fatigueLevel,
      muscleActivation: analysis.muscleActivation,
      hadPain: analysis.hadPain,
    );

    final trackerWithMetrics = updatedTracker.copyWith(
      history: [...updatedTracker.history, metrics],
    );

    // ═══════════════════════════════════════════════════════════════
    // STEP 7: Save updated tracker to Firebase
    // ═══════════════════════════════════════════════════════════════

    await _progressionRepo.saveTracker(
      userId: userId,
      tracker: trackerWithMetrics,
    );

    // ═══════════════════════════════════════════════════════════════
    // STEP 8: Archive analysis for ML training
    // ═══════════════════════════════════════════════════════════════

    await _analysisRepo.saveAnalysis(userId: userId, analysis: analysis);

    debugPrint(
      '[WeeklyProgression]    Tracker saved (volume: ${trackerWithMetrics.currentVolume})',
    );
    debugPrint('[WeeklyProgression]    Analysis archived (week $weekNumber)');

    return decision;
  }

  @override
  Future<Map<String, dynamic>> getProgressionSummary({
    required String userId,
    int lastWeeks = 4,
  }) async {
    final allTrackers = await _progressionRepo.getAllTrackers(userId: userId);

    if (allTrackers.isEmpty) {
      return {
        'total_weeks_tracked': 0,
        'muscles': {},
        'summary': {
          'total_volume': 0,
          'muscles_discovering': 0,
          'muscles_maintaining': 0,
          'muscles_deloading': 0,
        },
      };
    }

    final musclesSummary = <String, dynamic>{};
    int totalVolume = 0;
    int countDiscovering = 0;
    int countMaintaining = 0;
    int countDeloading = 0;

    for (final entry in allTrackers.entries) {
      final muscle = entry.key;
      final tracker = entry.value;

      // Get last N weeks from history
      final recentHistory = tracker.history.length > lastWeeks
          ? tracker.history.skip(tracker.history.length - lastWeeks).toList()
          : tracker.history;

      musclesSummary[muscle] = {
        'current_volume': tracker.currentVolume,
        'current_phase': tracker.currentPhase.name,
        'vmr_discovered': tracker.vmrDiscovered,
        'weeks_in_phase': tracker.weekInCurrentPhase,
        'priority': tracker.priority,
        'last_${lastWeeks}_weeks': recentHistory
            .map(
              (m) => {
                'week': m.weekNumber,
                'volume': m.volume,
                'load_change': m.loadChange,
                'adherence': m.adherence,
                'recovery': m.recoveryQuality,
                'fatigue': m.fatigueLevel,
              },
            )
            .toList(),
      };

      totalVolume += tracker.currentVolume;

      switch (tracker.currentPhase) {
        case ProgressionPhase.discovering:
          countDiscovering++;
          break;
        case ProgressionPhase.maintaining:
          countMaintaining++;
          break;
        case ProgressionPhase.deloading:
        case ProgressionPhase.microdeload:
          countDeloading++;
          break;
        case ProgressionPhase.overreaching:
          // Count as discovering (transition state)
          countDiscovering++;
          break;
      }
    }

    return {
      'total_weeks_tracked': allTrackers.values.first.totalWeeksInCycle,
      'muscles': musclesSummary,
      'summary': {
        'total_volume': totalVolume,
        'muscles_discovering': countDiscovering,
        'muscles_maintaining': countMaintaining,
        'muscles_deloading': countDeloading,
      },
    };
  }

  @override
  MuscleProgressionTracker applyDecisionToTracker({
    required MuscleProgressionTracker tracker,
    required MuscleDecision decision,
    required int weekNumber,
  }) {
    // Check if phase changed
    final phaseChanged = tracker.currentPhase != decision.newPhase;

    MuscleProgressionTracker updatedTracker = tracker.copyWith(
      currentVolume: decision.newVolume,
      currentPhase: decision.newPhase,
      weekInCurrentPhase: phaseChanged ? 0 : tracker.weekInCurrentPhase + 1,
      totalWeeksInCycle: tracker.totalWeeksInCycle + 1,
      vmrDiscovered: decision.vmrDiscovered ?? tracker.vmrDiscovered,
      lastUpdated: DateTime.now(),
    );

    // If phase changed, record transition
    if (phaseChanged) {
      final transition = PhaseTransition(
        weekNumber: weekNumber,
        fromPhase: tracker.currentPhase,
        toPhase: decision.newPhase,
        volume: decision.newVolume,
        reason: decision.reason,
        timestamp: DateTime.now(),
      );

      updatedTracker = updatedTracker.copyWith(
        phaseTimeline: [...tracker.phaseTimeline, transition],
      );

      debugPrint('[WeeklyProgression]    Phase transition recorded:');
      debugPrint(
        '[WeeklyProgression]      ${transition.fromPhase.name} → ${transition.toPhase.name}',
      );
      debugPrint('[WeeklyProgression]      Reason: ${transition.reason}');
    }

    // If new cycle started
    if (decision.isNewCycle) {
      debugPrint('[WeeklyProgression]    NEW CYCLE started');
      updatedTracker = updatedTracker.copyWith(totalWeeksInCycle: 0);
    }

    return updatedTracker;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  void _ensureExerciseIndex() {
    if (_exerciseIdToMuscles.isNotEmpty) return;

    final exercises = ExerciseCatalogV3.getAllExercises();
    if (exercises.isEmpty) return;

    for (final exercise in exercises) {
      final muscles = <String>{
        ...exercise.primaryMuscles,
        ...exercise.secondaryMuscles,
        ...exercise.tertiaryMuscles,
        ...exercise.stimulusContribution.keys,
      };

      if (exercise.muscleKey.isNotEmpty) {
        muscles.add(exercise.muscleKey);
      }

      final normalized = <String>{};
      for (final muscle in muscles) {
        final canonical = muscle_registry.normalize(muscle) ?? muscle;
        normalized.add(canonical);
      }

      if (normalized.isEmpty) continue;

      _exerciseIdToMuscles[exercise.id] = normalized;
    }
  }

  /// Check if an ExerciseLog is for a specific muscle
  bool _isLogForMuscle(ExerciseLog log, String muscle) {
    _ensureExerciseIndex();

    if (_exerciseIdToMuscles.isEmpty) {
      if (!_missingCatalogWarned) {
        debugPrint(
          '[WeeklyProgression] ⚠️ ExerciseCatalogV3 not loaded. Defaulting to include all logs.',
        );
        _missingCatalogWarned = true;
      }
      return true;
    }

    final muscles = _exerciseIdToMuscles[log.exerciseId];
    if (muscles == null) return false;

    return muscles.contains(muscle);
  }

  /// Get default feedback when user doesn't provide it
  Map<String, dynamic> _getDefaultFeedback() {
    return {
      'muscle_activation': 7.0,
      'pump_quality': 7.0,
      'fatigue_level': 5.0,
      'recovery_quality': 7.0,
      'had_pain': false,
      'pain_severity': null,
      'pain_description': null,
      'exercises': {},
    };
  }
}
