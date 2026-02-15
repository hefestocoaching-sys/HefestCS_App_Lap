// integration_test/repository_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';

void main() {
  group('Repository Integration Tests', () {
    late MuscleProgressionRepositoryImpl progressionRepo;
    late WeeklyMuscleAnalysisRepositoryImpl analysisRepo;

    setUp(() {
      progressionRepo = MuscleProgressionRepositoryImpl();
      analysisRepo = WeeklyMuscleAnalysisRepositoryImpl();
    });

    test('Initialize and retrieve all trackers', () async {
      final userId = 'repo_test_${DateTime.now().millisecondsSinceEpoch}';

      const priorities = {
        'pectorals': 5,
        'lats': 5,
        'quadriceps': 5,
        'hamstrings': 3,
        'biceps': 3,
      };

      await progressionRepo.initializeAllTrackers(
        userId: userId,
        musclePriorities: priorities,
        trainingLevel: 'intermediate',
        age: 30,
      );

      final trackers = await progressionRepo.getAllTrackers(userId: userId);

      expect(trackers.length, greaterThan(0));
      for (final muscle in priorities.keys) {
        expect(trackers[muscle]?.muscle, muscle);
      }
    });

    test('Save and retrieve weekly analysis', () async {
      final userId = 'analysis_test_${DateTime.now().millisecondsSinceEpoch}';
      const muscle = 'lats';

      final analysis = _buildAnalysis(muscle: muscle, weekNumber: 1);

      await analysisRepo.saveAnalysis(userId: userId, analysis: analysis);

      final retrieved = await analysisRepo.getAnalysis(
        userId: userId,
        muscle: muscle,
        weekNumber: 1,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.muscle, muscle);
      expect(retrieved.weekNumber, 1);
    });

    test('Get week analyses for multiple muscles', () async {
      final userId = 'week_test_${DateTime.now().millisecondsSinceEpoch}';

      await analysisRepo.saveAnalysis(
        userId: userId,
        analysis: _buildAnalysis(muscle: 'pectorals', weekNumber: 2),
      );
      await analysisRepo.saveAnalysis(
        userId: userId,
        analysis: _buildAnalysis(muscle: 'lats', weekNumber: 2),
      );

      final weekAnalyses = await analysisRepo.getWeekAnalyses(
        userId: userId,
        weekNumber: 2,
      );

      expect(weekAnalyses.length, greaterThanOrEqualTo(2));
    });
  });
}

WeeklyMuscleAnalysis _buildAnalysis({
  required String muscle,
  required int weekNumber,
}) {
  return WeeklyMuscleAnalysis(
    muscle: muscle,
    weekNumber: weekNumber,
    weekStart: DateTime.parse('2024-01-01'),
    weekEnd: DateTime.parse('2024-01-07'),
    prescribedSets: 12,
    completedSets: 12,
    volumeAdherence: 1.0,
    averageLoad: 100.0,
    previousLoad: 95.0,
    loadChange: 5.0,
    averageReps: 10.0,
    previousReps: 9.5,
    averageRir: 2.0,
    prescribedRir: 2,
    rirDeviation: 0.0,
    averageRpe: 8.0,
    muscleActivation: 8.0,
    pumpQuality: 8.0,
    fatigueLevel: 5.0,
    recoveryQuality: 8.0,
  );
}
