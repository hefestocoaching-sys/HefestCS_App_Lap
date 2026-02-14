import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/engines/volume_landmarks_calculator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_metrics.dart';
import 'muscle_progression_repository.dart';

/// Firebase implementation of MuscleProgressionRepository.
class MuscleProgressionRepositoryImpl implements MuscleProgressionRepository {
  final FirebaseFirestore _firestore;

  MuscleProgressionRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String _getCollectionPath(String userId) =>
      'users/$userId/muscle_progression';

  String _getDocumentPath(String userId, String muscle) =>
      '${_getCollectionPath(userId)}/$muscle';

  @override
  Future<MuscleProgressionTracker?> getTracker({
    required String userId,
    required String muscle,
  }) async {
    try {
      final doc = await _firestore.doc(_getDocumentPath(userId, muscle)).get();

      if (!doc.exists) {
        debugPrint('[MuscleProgressionRepo] No tracker found for $muscle');
        return null;
      }

      final data = doc.data()!;
      return MuscleProgressionTracker.fromJson(data);
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error getting tracker: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, MuscleProgressionTracker>> getAllTrackers({
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_getCollectionPath(userId))
          .get();

      final trackers = <String, MuscleProgressionTracker>{};

      for (final doc in snapshot.docs) {
        final muscle = doc.id;
        final data = doc.data();
        trackers[muscle] = MuscleProgressionTracker.fromJson(data);
      }

      debugPrint(
        '[MuscleProgressionRepo] Loaded ${trackers.length} trackers for user $userId',
      );

      return trackers;
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error getting all trackers: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveTracker({
    required String userId,
    required MuscleProgressionTracker tracker,
  }) async {
    try {
      final docPath = _getDocumentPath(userId, tracker.muscle);

      await _firestore
          .doc(docPath)
          .set(tracker.toJson(), SetOptions(merge: true));

      debugPrint(
        '[MuscleProgressionRepo] Saved tracker for ${tracker.muscle}: '
        'volume=${tracker.currentVolume} phase=${tracker.currentPhase}',
      );
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error saving tracker: $e');
      rethrow;
    }
  }

  @override
  Future<void> initializeAllTrackers({
    required String userId,
    required Map<String, int> musclePriorities,
    required String trainingLevel,
    required int age,
  }) async {
    try {
      final normalizedPriorities = <String, int>{};
      musclePriorities.forEach((muscle, priority) {
        final normalized = muscle_registry.normalize(muscle);
        if (normalized != null) {
          normalizedPriorities[normalized] = priority;
        }
      });

      final allLandmarks = VolumeLandmarksCalculator.calculateForAllMuscles(
        musclePriorities: normalizedPriorities,
        trainingLevel: trainingLevel,
        age: age,
      );

      final batch = _firestore.batch();

      for (final muscle in muscle_registry.canonicalMuscles) {
        final landmarks =
            allLandmarks[muscle] ??
            VolumeLandmarks.calculate(
              muscle: muscle,
              priority: 3,
              trainingLevel: trainingLevel,
              age: age,
            );

        final tracker = MuscleProgressionTracker.initialize(
          muscle: muscle,
          priority: normalizedPriorities[muscle] ?? 3,
          landmarks: landmarks,
        );

        final docRef = _firestore.doc(_getDocumentPath(userId, muscle));
        batch.set(docRef, tracker.toJson());
      }

      await batch.commit();

      debugPrint(
        '[MuscleProgressionRepo] Initialized ${muscle_registry.canonicalMuscles.length} trackers for user $userId',
      );
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error initializing trackers: $e');
      rethrow;
    }
  }

  @override
  Future<void> addWeeklyMetrics({
    required String userId,
    required String muscle,
    required WeeklyMuscleMetrics metrics,
  }) async {
    try {
      final tracker = await getTracker(userId: userId, muscle: muscle);

      if (tracker == null) {
        throw Exception('Tracker not found for $muscle');
      }

      final updatedHistory = [...tracker.history, metrics];

      final updatedTracker = tracker.copyWith(
        history: updatedHistory,
        lastUpdated: DateTime.now(),
      );

      await saveTracker(userId: userId, tracker: updatedTracker);

      debugPrint(
        '[MuscleProgressionRepo] Added weekly metrics for $muscle (week ${metrics.weekNumber})',
      );
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error adding metrics: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordPhaseTransition({
    required String userId,
    required String muscle,
    required PhaseTransition transition,
  }) async {
    try {
      final tracker = await getTracker(userId: userId, muscle: muscle);

      if (tracker == null) {
        throw Exception('Tracker not found for $muscle');
      }

      final updatedTimeline = [...tracker.phaseTimeline, transition];

      final updatedTracker = tracker.copyWith(
        phaseTimeline: updatedTimeline,
        currentPhase: transition.toPhase,
        weekInCurrentPhase: 0,
        lastUpdated: DateTime.now(),
      );

      await saveTracker(userId: userId, tracker: updatedTracker);

      debugPrint(
        '[MuscleProgressionRepo] Recorded phase transition for $muscle: '
        '${transition.fromPhase} -> ${transition.toPhase}',
      );
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error recording transition: $e');
      rethrow;
    }
  }

  @override
  Future<void> pruneOldHistory({
    required String userId,
    int keepLastWeeks = 12,
  }) async {
    try {
      final trackers = await getAllTrackers(userId: userId);

      final batch = _firestore.batch();

      for (final entry in trackers.entries) {
        final muscle = entry.key;
        final tracker = entry.value;

        if (tracker.history.length > keepLastWeeks) {
          final prunedHistory = tracker.history
              .skip(tracker.history.length - keepLastWeeks)
              .toList();

          final updatedTracker = tracker.copyWith(
            history: prunedHistory,
            lastUpdated: DateTime.now(),
          );

          final docRef = _firestore.doc(_getDocumentPath(userId, muscle));
          batch.set(docRef, updatedTracker.toJson());
        }
      }

      await batch.commit();

      debugPrint(
        '[MuscleProgressionRepo] Pruned history (keeping last $keepLastWeeks weeks)',
      );
    } catch (e) {
      debugPrint('[MuscleProgressionRepo] Error pruning history: $e');
      rethrow;
    }
  }
}
