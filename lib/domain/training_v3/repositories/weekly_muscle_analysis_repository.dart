import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';

/// Repository for detailed weekly muscle analyses.
///
/// Difference vs MuscleProgressionRepository:
/// - MuscleProgressionRepository: current state + lightweight history
/// - WeeklyMuscleAnalysisRepository: detailed weekly analyses (archived)
///
/// Persistence:
/// - Firebase Firestore: users/{userId}/weekly_analysis/{weekId}_{muscle}
/// - Historical files for ML training
abstract class WeeklyMuscleAnalysisRepository {
  /// Saves a full weekly analysis.
  Future<void> saveAnalysis({
    required String userId,
    required WeeklyMuscleAnalysis analysis,
  });

  /// Returns analysis for a specific week and muscle.
  Future<WeeklyMuscleAnalysis?> getAnalysis({
    required String userId,
    required String muscle,
    required int weekNumber,
  });

  /// Returns analyses for a week for all muscles.
  ///
  /// Map key: muscle.
  Future<Map<String, WeeklyMuscleAnalysis>> getWeekAnalyses({
    required String userId,
    required int weekNumber,
  });

  /// Returns analysis history for a muscle (last N weeks).
  Future<List<WeeklyMuscleAnalysis>> getAnalysisHistory({
    required String userId,
    required String muscle,
    int lastWeeks = 12,
  });
}
