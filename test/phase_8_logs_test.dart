// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/services/phase_8_adaptation_service.dart';

void main() {
  group('Phase8 adaptation with logs', () {
    late Phase8AdaptationService service;
    late Map<int, Map<int, List<ExercisePrescription>>> basePlan;
    late Map<String, VolumeLimits> limits;

    setUp(() {
      service = Phase8AdaptationService();

      basePlan = {
        1: {
          1: [
            ExercisePrescription(
              id: 'curl__d1',
              sessionId: 'day_1',
              muscleGroup: MuscleGroup.biceps,
              exerciseCode: 'curl',
              label: 'A',
              exerciseName: 'Curl',
              sets: 10,
              repRange: const RepRange(8, 12),
              rir: '2',
              restMinutes: 1,
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

      limits = {
        'biceps': const VolumeLimits(
          muscleGroup: 'biceps',
          mev: 6,
          mav: 12,
          mrv: 20,
          recommendedStartVolume: 10,
        ),
      };
    });

    test('determinismo: mismos logs -> misma adaptación', () {
      final log = TrainingSessionLog(
        dateIso: '2024-01-01',
        sessionName: 'session',
        entries: [
          ExerciseLogEntry(
            exerciseIdOrName: 'curl',
            sets: 3,
            reps: [10, 9, 8],
            load: [20, 20, 20],
            rpe: [8, 8.5, 9],
          ),
        ],
        createdAtIso: '2024-01-01',
      );

      final a = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: basePlan,
        volumeLimitsByMuscle: limits,
      );

      final b = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: basePlan,
        volumeLimitsByMuscle: limits,
      );

      // Prescriptions must be identical
      expect(
        a.adaptedWeekDayPrescriptions[1]![1]![0].sets,
        b.adaptedWeekDayPrescriptions[1]![1]![0].sets,
      );
      expect(
        a.adaptedWeekDayPrescriptions[1]![1]![0].rir,
        b.adaptedWeekDayPrescriptions[1]![1]![0].rir,
      );
    });

    test('DecisionTrace incluye log_metrics_summary', () {
      final log = TrainingSessionLog(
        dateIso: '2024-01-01',
        sessionName: 'session',
        entries: [
          ExerciseLogEntry(
            exerciseIdOrName: 'curl',
            sets: 3,
            reps: [10, 9, 8],
            load: [20, 20, 20],
            rpe: [8, 8.5, 9],
          ),
        ],
        createdAtIso: '2024-01-01',
      );

      final res = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: basePlan,
        volumeLimitsByMuscle: limits,
      );

      final hasSummary = res.decisions.any(
        (d) => d.category == 'log_metrics_summary',
      );
      expect(hasSummary, true);
    });

    test('señales detectadas en DecisionTrace', () {
      final log = TrainingSessionLog(
        dateIso: '2024-01-01',
        sessionName: 'session',
        entries: [
          ExerciseLogEntry(
            exerciseIdOrName: 'curl',
            sets: 3,
            reps: [10, 9, 8],
            load: [20, 20, 20],
            rpe: null,
          ),
        ],
        createdAtIso: '2024-01-01',
      );

      final res = service.adapt(
        latestFeedback: null,
        history: null,
        logs: [log],
        weekDayPrescriptions: basePlan,
        volumeLimitsByMuscle: limits,
      );

      final hasSignal = res.decisions.any(
        (d) => d.category == 'signal_detection',
      );
      expect(hasSignal, true);
    });
  });
}
