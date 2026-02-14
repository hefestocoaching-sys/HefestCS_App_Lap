// lib/domain/training_v3/repositories/weekly_muscle_analysis_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';

import 'weekly_muscle_analysis_repository.dart';

/// Firebase implementation of WeeklyMuscleAnalysisRepository
///
/// FIRESTORE SCHEMA:
/// ```
/// users/{userId}/weekly_analysis/{weekId}_{muscle}
/// ```
///
/// Document ID format: "2026-W06_pectorals"
/// - Year-Week format for easy querying
/// - Muscle name for identification
///
/// Version: 1.0.0
class WeeklyMuscleAnalysisRepositoryImpl
    implements WeeklyMuscleAnalysisRepository {
  final FirebaseFirestore _firestore;

  WeeklyMuscleAnalysisRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String _getCollectionPath(String userId) => 'users/$userId/weekly_analysis';

  String _generateDocumentId(int weekNumber, String muscle) {
    // Format: "YYYY-WXX_muscle"
    final year = DateTime.now().year;
    final weekFormatted = weekNumber.toString().padLeft(2, '0');
    return '$year-W$weekFormatted'
        '_$muscle';
  }

  @override
  Future<void> saveAnalysis({
    required String userId,
    required WeeklyMuscleAnalysis analysis,
  }) async {
    try {
      final docId = _generateDocumentId(analysis.weekNumber, analysis.muscle);
      final docPath = '${_getCollectionPath(userId)}/$docId';

      await _firestore.doc(docPath).set(analysis.toJson());

      debugPrint('[WeeklyAnalysisRepo] ✅ Saved analysis: $docId');
    } catch (e, stackTrace) {
      debugPrint('[WeeklyAnalysisRepo] ❌ Error saving analysis: $e');
      debugPrint('[WeeklyAnalysisRepo] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<WeeklyMuscleAnalysis?> getAnalysis({
    required String userId,
    required String muscle,
    required int weekNumber,
  }) async {
    try {
      final docId = _generateDocumentId(weekNumber, muscle);
      final doc = await _firestore
          .doc('${_getCollectionPath(userId)}/$docId')
          .get();

      if (!doc.exists) {
        debugPrint(
          '[WeeklyAnalysisRepo] No analysis found for $muscle week $weekNumber',
        );
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      return WeeklyMuscleAnalysis.fromJson(data);
    } catch (e) {
      debugPrint('[WeeklyAnalysisRepo] Error getting analysis: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, WeeklyMuscleAnalysis>> getWeekAnalyses({
    required String userId,
    required int weekNumber,
  }) async {
    try {
      final year = DateTime.now().year;
      final weekFormatted = weekNumber.toString().padLeft(2, '0');
      final weekPrefix = '$year-W$weekFormatted';

      final snapshot = await _firestore
          .collection(_getCollectionPath(userId))
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: weekPrefix)
          .where(FieldPath.documentId, isLessThan: '${weekPrefix}z')
          .get();

      final analyses = <String, WeeklyMuscleAnalysis>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final analysis = WeeklyMuscleAnalysis.fromJson(data);
        analyses[analysis.muscle] = analysis;
      }

      debugPrint(
        '[WeeklyAnalysisRepo] Loaded ${analyses.length} analyses for week $weekNumber',
      );

      return analyses;
    } catch (e) {
      debugPrint('[WeeklyAnalysisRepo] Error getting week analyses: $e');
      rethrow;
    }
  }

  @override
  Future<List<WeeklyMuscleAnalysis>> getAnalysisHistory({
    required String userId,
    required String muscle,
    int lastWeeks = 12,
  }) async {
    try {
      final currentWeek = _getCurrentWeekNumber();
      final startWeek = currentWeek - lastWeeks;

      final analyses = <WeeklyMuscleAnalysis>[];

      for (int week = startWeek; week <= currentWeek; week++) {
        if (week < 1) continue;

        final analysis = await getAnalysis(
          userId: userId,
          muscle: muscle,
          weekNumber: week,
        );

        if (analysis != null) {
          analyses.add(analysis);
        }
      }

      debugPrint(
        '[WeeklyAnalysisRepo] Loaded ${analyses.length} historical analyses for $muscle',
      );

      return analyses;
    } catch (e) {
      debugPrint('[WeeklyAnalysisRepo] Error getting history: $e');
      rethrow;
    }
  }

  /// Get current week number (simple implementation)
  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    // ignore: avoid_redundant_argument_values
    final startOfYear = DateTime(now.year, 1, 1);
    final daysSinceStartOfYear = now.difference(startOfYear).inDays;
    return (daysSinceStartOfYear / 7).ceil();
  }
}
