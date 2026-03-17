// lib/domain/training_v3/services/weekly_progression_service.dart

import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';

/// Weekly progression orchestrator service
///
/// RESPONSIBILITIES:
/// - Process weekly training data for all 14 muscles
/// - Generate adaptive decisions using WeeklyAdaptationEngine
/// - Update muscle progression trackers in Firebase
/// - Archive weekly analyses for ML training
/// - Handle phase transitions (discovering -> maintaining, etc.)
///
/// WORKFLOW (End-to-End):
/// ```
/// User completes training week
///         ↓
/// processWeeklyProgression(userId, logs, feedback)
///         ↓
/// For each muscle (14 total):
///   1. WeeklyFeedbackCollector.buildAnalysis()
///      -> Generate WeeklyMuscleAnalysis
///   2. MuscleProgressionRepository.getTracker()
///      -> Get current state
///   3. WeeklyAdaptationEngine.analyzeAndDecide()
///      -> Generate MuscleDecision
///   4. Apply decision to tracker
///   5. MuscleProgressionRepository.saveTracker()
///      -> Persist new state
///   6. WeeklyMuscleAnalysisRepository.saveAnalysis()
///      -> Archive for ML
///         ↓
/// Return Map<muscle, MuscleDecision>
/// ```
///
/// SCIENTIFIC FOUNDATION:
/// - Adaptive volume progression based on real performance
/// - Individualized VMR discovery per muscle
/// - Preventive microdeloads every 3 weeks
/// - Fatigue-based deload triggers
///
/// Version: 1.0.0
abstract class WeeklyProgressionService {
  /// Process weekly progression for ALL muscles (main entry point)
  ///
  /// PARAMETERS:
  /// - userId: User ID
  /// - weekNumber: Global week number (incremental)
  /// - weekStart: Start of week (Monday 00:00:00)
  /// - weekEnd: End of week (Sunday 23:59:59)
  /// - exerciseLogs: ALL exercise logs for the week (all muscles)
  /// - userFeedbackByMuscle: Subjective feedback organized by muscle
  ///
  /// userFeedbackByMuscle structure:
  /// ```dart
  /// {
  ///   'pectorals': {
  ///     'muscle_activation': 8.5,
  ///     'pump_quality': 8.0,
  ///     'fatigue_level': 5.5,
  ///     'recovery_quality': 7.2,
  ///     'had_pain': false,
  ///     'exercises': {
  ///       'bench_press': {...},
  ///       'incline_press': {...},
  ///     }
  ///   },
  ///   'quadriceps': {...},
  ///   ...
  /// }
  /// ```
  ///
  /// RETURNS:
  /// - Map of muscle to MuscleDecision with decisions for all muscles
  ///
  /// EXAMPLE:
  /// ```dart
  /// final decisions = await service.processWeeklyProgression(
  ///   userId: 'user123',
  ///   weekNumber: 8,
  ///   weekStart: DateTime(2026, 2, 8),
  ///   weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
  ///   exerciseLogs: allLogsThisWeek,
  ///   userFeedbackByMuscle: feedbackMap,
  /// );
  ///
  /// // decisions['pectorals'].newVolume = 15
  /// // decisions['pectorals'].action = VolumeAction.increase
  /// // decisions['quadriceps'].action = VolumeAction.microdeload
  /// ```
  Future<Map<String, MuscleDecision>> processWeeklyProgression({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, Map<String, dynamic>> userFeedbackByMuscle,
  });

  /// Process progression for a SINGLE muscle (granular control)
  ///
  /// PARAMETERS:
  /// - userId: User ID
  /// - muscle: Muscle canonical name ('pectorals', 'quadriceps', etc.)
  /// - weekNumber: Global week number
  /// - weekStart: Start of week
  /// - weekEnd: End of week
  /// - exerciseLogs: Exercise logs for THIS muscle only
  /// - prescribedSets: Total sets planned for this muscle this week
  /// - prescribedRir: Planned RIR (usually 2-3)
  /// - userFeedback: Subjective feedback for this muscle
  ///
  /// RETURNS:
  /// - MuscleDecision with new volume and action
  ///
  /// EXAMPLE:
  /// ```dart
  /// final decision = await service.processMuscleProgression(
  ///   userId: 'user123',
  ///   muscle: 'pectorals',
  ///   weekNumber: 8,
  ///   weekStart: DateTime(2026, 2, 8),
  ///   weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
  ///   exerciseLogs: pectoralLogs,
  ///   prescribedSets: 15,
  ///   prescribedRir: 2,
  ///   userFeedback: {
  ///     'muscle_activation': 8.5,
  ///     'pump_quality': 8.0,
  ///     // ...
  ///   },
  /// );
  /// ```
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
  });

  /// Get progression summary for dashboard (multi-week overview)
  ///
  /// PARAMETERS:
  /// - userId: User ID
  /// - lastWeeks: Number of weeks to include (default: 4)
  ///
  /// RETURNS:
  /// Map with progression summary:
  /// ```dart
  /// {
  ///   'total_weeks_tracked': 8,
  ///   'muscles': {
  ///     'pectorals': {
  ///       'current_volume': 15,
  ///       'current_phase': 'discovering',
  ///       'vmr_discovered': null,
  ///       'weeks_in_phase': 3,
  ///       'last_4_weeks': [
  ///         {'week': 5, 'volume': 11, 'phase': 'discovering'},
  ///         {'week': 6, 'volume': 13, 'phase': 'discovering'},
  ///         {'week': 7, 'volume': 15, 'phase': 'discovering'},
  ///         {'week': 8, 'volume': 10, 'phase': 'microdeload'},
  ///       ],
  ///     },
  ///     'quadriceps': {...},
  ///     ...
  ///   },
  ///   'summary': {
  ///     'total_volume': 118,
  ///     'muscles_discovering': 8,
  ///     'muscles_maintaining': 4,
  ///     'muscles_deloading': 2,
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getProgressionSummary({
    required String userId,
    int lastWeeks = 4,
  });

  /// Apply a decision to a tracker (update state)
  ///
  /// INTERNAL HELPER METHOD
  /// Updates tracker based on decision:
  /// - currentVolume = decision.newVolume
  /// - currentPhase = decision.newPhase
  /// - weekInCurrentPhase++
  /// - If phase changed: record PhaseTransition
  /// - If VMR discovered: set vmrDiscovered
  ///
  /// PARAMETERS:
  /// - tracker: Current tracker
  /// - decision: Decision to apply
  /// - weekNumber: Current week number
  ///
  /// RETURNS:
  /// - Updated tracker
  MuscleProgressionTracker applyDecisionToTracker({
    required MuscleProgressionTracker tracker,
    required MuscleDecision decision,
    required int weekNumber,
  });
}
