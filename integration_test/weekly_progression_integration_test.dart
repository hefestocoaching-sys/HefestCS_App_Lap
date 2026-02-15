// integration_test/weekly_progression_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/set_log.dart';

void main() {
  group('Weekly Progression Integration', () {
    late WeeklyProgressionServiceImpl service;
    late MuscleProgressionRepositoryImpl progressionRepo;
    late WeeklyMuscleAnalysisRepositoryImpl analysisRepo;

    setUp(() {
      progressionRepo = MuscleProgressionRepositoryImpl();
      analysisRepo = WeeklyMuscleAnalysisRepositoryImpl();
      service = WeeklyProgressionServiceImpl(
        progressionRepo: progressionRepo,
        analysisRepo: analysisRepo,
      );
    });

    test('Process a single week for one muscle', () async {
      final userId =
          'integration_test_user_${DateTime.now().millisecondsSinceEpoch}';
      const muscle = 'pectorals';

      await progressionRepo.initializeAllTrackers(
        userId: userId,
        musclePriorities: {muscle: 5},
        trainingLevel: 'intermediate',
        age: 30,
      );

      final decisions = await service.processWeeklyProgression(
        userId: userId,
        weekNumber: 1,
        weekStart: DateTime.parse('2024-01-01'),
        weekEnd: DateTime.parse('2024-01-07'),
        exerciseLogs: [_buildLog('bench_press')],
        userFeedbackByMuscle: {
          muscle: {
            'muscle_activation': 8.0,
            'pump_quality': 8.0,
            'fatigue_level': 5.0,
            'recovery_quality': 8.0,
            'had_pain': false,
          },
        },
      );

      expect(decisions.containsKey(muscle), true);
    });
  });
}

ExerciseLog _buildLog(String exerciseId) {
  return ExerciseLog(
    id: 'log_$exerciseId',
    exerciseId: exerciseId,
    exerciseName: exerciseId,
    plannedPrescriptionId: 'presc_$exerciseId',
    plannedSets: 2,
    sets: [_buildSet(1, 50, 10, 8.0), _buildSet(2, 50, 10, 8.5)],
    plannedRir: 2,
    averageRpe: 8.3,
    completed: true,
  );
}

SetLog _buildSet(int number, double weight, int reps, double rpe) {
  return SetLog.fromRpe(
    setNumber: number,
    weight: weight,
    reps: reps,
    rpe: rpe,
    completedAt: DateTime.parse('2024-01-02'),
  );
}
