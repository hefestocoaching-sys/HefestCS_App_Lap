import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_metrics.dart';

/// Repository for persisting muscle progression state.
///
/// Responsibilities:
/// - Save/retrieve MuscleProgressionTracker by user and muscle.
/// - Update weekly state (volume, phase, history).
/// - Maintain a timeline of phase transitions.
///
/// Persistence:
/// - Firebase Firestore: users/{userId}/muscle_progression/{muscle}
/// - Local cache: Shared Preferences for quick access.
abstract class MuscleProgressionRepository {
  /// Returns the current tracker for a muscle and user.
  ///
  /// If not found, returns null (first time).
  /// The caller should initialize with MuscleProgressionTracker.initialize().
  Future<MuscleProgressionTracker?> getTracker({
    required String userId,
    required String muscle,
  });

  /// Returns all trackers for a user (14 muscles).
  ///
  /// Map key: muscle (canonical name).
  /// Map value: current tracker.
  Future<Map<String, MuscleProgressionTracker>> getAllTrackers({
    required String userId,
  });

  /// Saves/updates the tracker for a muscle.
  ///
  /// Updates:
  /// - currentVolume
  /// - currentPhase
  /// - weekInCurrentPhase
  /// - history (append new metric)
  /// - phaseTimeline (if transition occurs)
  /// - lastUpdated
  Future<void> saveTracker({
    required String userId,
    required MuscleProgressionTracker tracker,
  });

  /// Initializes all trackers for a new user.
  ///
  /// Calculates landmarks and creates initial trackers for the 14 muscles.
  Future<void> initializeAllTrackers({
    required String userId,
    required Map<String, int> musclePriorities,
    required String trainingLevel,
    required int age,
  });

  /// Adds a new weekly metric to history.
  ///
  /// Updates:
  /// - tracker.history (append WeeklyMuscleMetrics)
  /// - tracker.lastUpdated
  Future<void> addWeeklyMetrics({
    required String userId,
    required String muscle,
    required WeeklyMuscleMetrics metrics,
  });

  /// Records a phase transition.
  ///
  /// Updates:
  /// - tracker.phaseTimeline (append PhaseTransition)
  /// - tracker.currentPhase
  /// - tracker.weekInCurrentPhase (reset to 0)
  Future<void> recordPhaseTransition({
    required String userId,
    required String muscle,
    required PhaseTransition transition,
  });

  /// Prunes old history (keep last N weeks).
  ///
  /// Prevents the Firestore document from growing indefinitely.
  Future<void> pruneOldHistory({
    required String userId,
    int keepLastWeeks = 12,
  });
}
