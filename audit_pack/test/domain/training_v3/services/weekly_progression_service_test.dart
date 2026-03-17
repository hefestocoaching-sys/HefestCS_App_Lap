// test/domain/training_v3/services/weekly_progression_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/set_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';

class MockMuscleProgressionRepository extends Mock
    implements MuscleProgressionRepository {}

class MockWeeklyMuscleAnalysisRepository extends Mock
    implements WeeklyMuscleAnalysisRepository {}

void main() {
  late WeeklyProgressionServiceImpl service;
  late MockMuscleProgressionRepository mockProgressionRepo;
  late MockWeeklyMuscleAnalysisRepository mockAnalysisRepo;

  setUp(() {
    mockProgressionRepo = MockMuscleProgressionRepository();
    mockAnalysisRepo = MockWeeklyMuscleAnalysisRepository();
    service = WeeklyProgressionServiceImpl(
      progressionRepo: mockProgressionRepo,
      analysisRepo: mockAnalysisRepo,
    );

    registerFallbackValue(_buildTracker());
    registerFallbackValue(_buildAnalysis());
  });

  group('processWeeklyProgression', () {
    test('should process single muscle and persist updates', () async {
      const userId = 'user123';
      const muscle = 'pectorals';
      final tracker = _buildTracker();

      when(
        () => mockProgressionRepo.getAllTrackers(userId: userId),
      ).thenAnswer((_) async => {muscle: tracker});

      when(
        () => mockProgressionRepo.getTracker(userId: userId, muscle: muscle),
      ).thenAnswer((_) async => tracker);

      when(
        () => mockProgressionRepo.saveTracker(
          userId: userId,
          tracker: any(named: 'tracker'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockAnalysisRepo.saveAnalysis(
          userId: userId,
          analysis: any(named: 'analysis'),
        ),
      ).thenAnswer((_) async {});

      final decisions = await service.processWeeklyProgression(
        userId: userId,
        weekNumber: 1,
        weekStart: DateTime.parse('2024-01-02'),
        weekEnd: DateTime.parse('2024-01-07'),
        exerciseLogs: [_buildLog(exerciseId: 'bench_press')],
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
      verify(
        () => mockProgressionRepo.getAllTrackers(userId: userId),
      ).called(1);
      verify(
        () => mockProgressionRepo.getTracker(userId: userId, muscle: muscle),
      ).called(1);
      verify(
        () => mockProgressionRepo.saveTracker(
          userId: userId,
          tracker: any(named: 'tracker'),
        ),
      ).called(1);
      verify(
        () => mockAnalysisRepo.saveAnalysis(
          userId: userId,
          analysis: any(named: 'analysis'),
        ),
      ).called(1);
    });
  });

  group('processMuscleProgression', () {
    test('should return decision and persist tracker', () async {
      const userId = 'user123';
      const muscle = 'lats';
      final tracker = _buildTracker(muscle: muscle, currentVolume: 14);

      when(
        () => mockProgressionRepo.getTracker(userId: userId, muscle: muscle),
      ).thenAnswer((_) async => tracker);

      when(
        () => mockProgressionRepo.saveTracker(
          userId: userId,
          tracker: any(named: 'tracker'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockAnalysisRepo.saveAnalysis(
          userId: userId,
          analysis: any(named: 'analysis'),
        ),
      ).thenAnswer((_) async {});

      final decision = await service.processMuscleProgression(
        userId: userId,
        muscle: muscle,
        weekNumber: 1,
        weekStart: DateTime.parse('2024-01-02'),
        weekEnd: DateTime.parse('2024-01-07'),
        exerciseLogs: [_buildLog(exerciseId: 'lat_pulldown')],
        prescribedSets: 14,
        prescribedRir: 2,
        userFeedback: {
          'muscle_activation': 7.5,
          'pump_quality': 7.0,
          'fatigue_level': 5.5,
          'recovery_quality': 7.5,
          'had_pain': false,
        },
      );

      expect(decision.muscle, muscle);
      expect(decision.newVolume, greaterThan(0));
      verify(
        () => mockProgressionRepo.saveTracker(
          userId: userId,
          tracker: any(named: 'tracker'),
        ),
      ).called(1);
      verify(
        () => mockAnalysisRepo.saveAnalysis(
          userId: userId,
          analysis: any(named: 'analysis'),
        ),
      ).called(1);
    });
  });

  group('getProgressionSummary', () {
    test('should return summary for multiple trackers', () async {
      const userId = 'user123';
      final trackers = {
        'pectorals': _buildTracker(currentVolume: 14),
        'lats': _buildTracker(muscle: 'lats', currentVolume: 16),
      };

      when(
        () => mockProgressionRepo.getAllTrackers(userId: userId),
      ).thenAnswer((_) async => trackers);

      final summary = await service.getProgressionSummary(userId: userId);

      expect(summary['summary']['total_volume'], 30);
      expect(summary['muscles'].length, 2);
      verify(
        () => mockProgressionRepo.getAllTrackers(userId: userId),
      ).called(1);
    });
  });
}

MuscleProgressionTracker _buildTracker({
  String muscle = 'pectorals',
  int currentVolume = 12,
}) {
  return MuscleProgressionTracker(
    muscle: muscle,
    priority: 5,
    landmarks: const VolumeLandmarks(
      vme: 8,
      vop: 12,
      vmr: 20,
      vmrTarget: 20,
    ),
    currentVolume: currentVolume,
    currentPhase: ProgressionPhase.discovering,
    weekInCurrentPhase: 0,
    totalWeeksInCycle: 0,
    lastUpdated: DateTime.parse('2024-01-02'),
  );
}

WeeklyMuscleAnalysis _buildAnalysis() {
  return WeeklyMuscleAnalysis(
    muscle: 'pectorals',
    weekNumber: 1,
    weekStart: DateTime.parse('2024-01-02'),
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

ExerciseLog _buildLog({required String exerciseId}) {
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
