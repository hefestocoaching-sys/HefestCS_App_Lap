import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_angle_coverage.dart';
import 'exercise_angle_coverage_repository.dart';

/// Implementación de Firestore para ExerciseAngleCoverageRepository.
class ExerciseAngleCoverageRepositoryImpl
    implements ExerciseAngleCoverageRepository {
  final FirebaseFirestore _firestore;

  ExerciseAngleCoverageRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String _getCollectionPath(String userId) => 'users/$userId/angle_coverage';

  @override
  Future<void> saveCoverage(ExerciseAngleCoverage coverage) async {
    try {
      final docId = 'w${coverage.weekNumber}_${coverage.muscle}';
      final docRef =
          _firestore.collection(_getCollectionPath(coverage.userId)).doc(docId);

      await docRef.set(coverage.toJson(), SetOptions(merge: true));

      debugPrint(
        '[AngleRepo] Saved coverage for ${coverage.muscle} (week ${coverage.weekNumber})',
      );
    } catch (e) {
      debugPrint('[AngleRepo] Error saving coverage: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExerciseAngleCoverage>> getCoverageHistory({
    required String userId,
    required String muscle,
    int? limit,
  }) async {
    try {
      var query = _firestore
          .collection(_getCollectionPath(userId))
          .where('muscle', isEqualTo: muscle)
          .orderBy('weekNumber', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ExerciseAngleCoverage.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[AngleRepo] Error getting coverage history: $e');
      return [];
    }
  }
}
