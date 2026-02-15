// test/domain/training_v3/models/exercise_log_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/set_log.dart';

void main() {
  group('ExerciseLog', () {
    test('should create log with all fields', () {
      final log = ExerciseLog(
        id: 'log123',
        exerciseId: 'bench_press',
        exerciseName: 'Bench Press',
        plannedPrescriptionId: 'presc_1',
        plannedSets: 4,
        sets: [
          _buildSet(1, 80, 10, 8.0),
          _buildSet(2, 80, 9, 9.0),
          _buildSet(3, 80, 9, 9.0),
          _buildSet(4, 80, 8, 9.5),
        ],
        plannedRir: 2,
        averageRpe: 8.9,
        completed: true,
        notes: 'Felt strong today',
      );

      expect(log.id, 'log123');
      expect(log.exerciseId, 'bench_press');
      expect(log.exerciseName, 'Bench Press');
      expect(log.plannedSets, 4);
      expect(log.sets.length, 4);
      expect(log.plannedRir, 2);
      expect(log.averageRpe, 8.9);
      expect(log.completed, true);
      expect(log.notes, 'Felt strong today');
    });

    test('should serialize to JSON correctly', () {
      final log = ExerciseLog(
        id: 'log123',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        plannedPrescriptionId: 'presc_2',
        plannedSets: 5,
        sets: [
          _buildSet(1, 120, 8, 8.5),
          _buildSet(2, 120, 8, 8.5),
          _buildSet(3, 120, 8, 9.0),
          _buildSet(4, 120, 7, 9.0),
          _buildSet(5, 120, 6, 9.5),
        ],
        plannedRir: 2,
        averageRpe: 8.9,
        completed: true,
      );

      final json = log.toJson();

      expect(json['id'], 'log123');
      expect(json['exerciseId'], 'squat');
      expect(json['exerciseName'], 'Squat');
      expect(json['plannedPrescriptionId'], 'presc_2');
      expect(json['plannedSets'], 5);
      expect((json['sets'] as List).length, 5);
      expect(json['plannedRir'], 2);
      expect(json['averageRpe'], 8.9);
      expect(json['completed'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'log789',
        'exerciseId': 'deadlift',
        'exerciseName': 'Deadlift',
        'plannedPrescriptionId': 'presc_3',
        'plannedSets': 3,
        'sets': [
          _buildSet(1, 140, 6, 9.0).toJson(),
          _buildSet(2, 140, 6, 9.5).toJson(),
          _buildSet(3, 140, 5, 9.5).toJson(),
        ],
        'plannedRir': 2,
        'averageRpe': 9.3,
        'completed': true,
        'incompletionReason': null,
        'notes': null,
      };

      final log = ExerciseLog.fromJson(json);

      expect(log.id, 'log789');
      expect(log.exerciseId, 'deadlift');
      expect(log.exerciseName, 'Deadlift');
      expect(log.sets.length, 3);
      expect(log.plannedRir, 2);
    });

    test('should calculate total volume (sets x reps x weight)', () {
      final log = ExerciseLog(
        id: 'log1',
        exerciseId: 'curl',
        exerciseName: 'Curl',
        plannedPrescriptionId: 'presc_4',
        plannedSets: 2,
        sets: [
          _buildSet(1, 20, 12, 8.0),
          _buildSet(2, 20, 12, 8.5),
        ],
        plannedRir: 3,
        averageRpe: 8.2,
        completed: true,
      );

      expect(log.totalVolume, 480.0);
    });

    test('should validate log consistency', () {
      final log = ExerciseLog(
        id: 'log1',
        exerciseId: 'press',
        exerciseName: 'Press',
        plannedPrescriptionId: 'presc_5',
        plannedSets: 3,
        sets: [
          _buildSet(1, 40, 10, 8.0),
          _buildSet(2, 40, 10, 8.5),
          _buildSet(3, 40, 9, 9.0),
        ],
        plannedRir: 2,
        averageRpe: 8.5,
        completed: true,
      );

      expect(log.isValid, true);
    });

    test('should handle missing optional fields', () {
      final log = ExerciseLog(
        id: 'log1',
        exerciseId: 'plank',
        exerciseName: 'Plank',
        plannedPrescriptionId: 'presc_6',
        plannedSets: 1,
        sets: [_buildSet(1, 0, 30, 6.0)],
        plannedRir: 4,
        averageRpe: 6.0,
        completed: true,
      );

      expect(log.incompletionReason, null);
      expect(log.notes, null);
    });
  });

  group('ExerciseLog copyWith', () {
    test('should copy with modified fields', () {
      final original = ExerciseLog(
        id: 'log1',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        plannedPrescriptionId: 'presc_7',
        plannedSets: 4,
        sets: [
          _buildSet(1, 100, 10, 8.0),
          _buildSet(2, 100, 10, 8.0),
          _buildSet(3, 100, 9, 8.5),
          _buildSet(4, 100, 8, 9.0),
        ],
        plannedRir: 2,
        averageRpe: 8.4,
        completed: true,
      );

      final modified = original.copyWith(
        plannedSets: 5,
        averageRpe: 9.0,
      );

      expect(modified.id, original.id);
      expect(modified.plannedSets, 5);
      expect(modified.averageRpe, 9.0);
    });
  });
}

SetLog _buildSet(int number, double weight, int reps, double rpe) {
  return SetLog.fromRpe(
    setNumber: number,
    weight: weight,
    reps: reps,
    rpe: rpe,
    completedAt: DateTime(2024, 1, 15, 10, 30),
  );
}
