// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/services/phase_8_adaptation_service.dart';

void main() {
  group('Phase8AdaptationService - Adaptación con Logs', () {
    late Phase8AdaptationService service;

    setUp(() {
      service = Phase8AdaptationService();
    });

    Map<int, Map<int, List<ExercisePrescription>>> samplePrescriptions() {
      return {
        1: {
          1: [
            ExercisePrescription(
              id: 'bench_d1',
              sessionId: 'day_1',
              muscleGroup: MuscleGroup.chest,
              exerciseCode: 'bench',
              label: 'A',
              exerciseName: 'Bench Press',
              sets: 4,
              repRange: const RepRange(8, 12),
              rir: '2',
              restMinutes: 2,
              allowFailureOnLastSet: false,
              notes: null,
              order: 0,
              templateCode: null,
              supersetGroup: null,
              slotLabel: null,
            ),
          ],
        },
      };
    }

    test('con logs: determinismo mantiene plan', () {
      final prescriptions = samplePrescriptions();
      final log = TrainingSessionLog(
        dateIso: '2024-01-01',
        sessionName: 'session',
        entries: [
          ExerciseLogEntry(
            exerciseIdOrName: 'bench',
            sets: 1,
            reps: [10],
            load: [100],
            rpe: [8],
          ),
        ],
        createdAtIso: '2024-01-01',
      );

      final a = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: prescriptions,
        volumeLimitsByMuscle: null,
      );

      final b = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: prescriptions,
        volumeLimitsByMuscle: null,
      );

      expect(
        a.adaptedWeekDayPrescriptions[1]![1]![0].sets,
        equals(b.adaptedWeekDayPrescriptions[1]![1]![0].sets),
      );
    });

    test('sin datos mantiene plan', () {
      final prescriptions = samplePrescriptions();

      final result = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [],
        weekDayPrescriptions: prescriptions,
        volumeLimitsByMuscle: null,
      );

      expect(result.adaptedWeekDayPrescriptions, equals(prescriptions));
    });

    test('DecisionTrace contiene métricas de logs', () {
      final prescriptions = samplePrescriptions();
      final log = TrainingSessionLog(
        dateIso: '2024-01-01',
        sessionName: 'session',
        entries: [
          ExerciseLogEntry(
            exerciseIdOrName: 'bench',
            sets: 1,
            reps: [10],
            load: [100],
            rpe: [8],
          ),
        ],
        createdAtIso: '2024-01-01',
      );

      final result = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: prescriptions,
        volumeLimitsByMuscle: null,
      );

      expect(
        result.decisions.any((d) => d.category == 'log_metrics_summary'),
        true,
      );
      expect(
        result.decisions.any((d) => d.category == 'signal_detection'),
        true,
      );
    });
  });
}
