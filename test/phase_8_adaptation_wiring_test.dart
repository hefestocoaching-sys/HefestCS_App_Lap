// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';
import 'package:hcs_app_lap/domain/services/phase_8_adaptation_service.dart';

/// Test de integración: verifica que Phase8 consume correctamente
/// WeeklyTrainingFeedbackSummary (señales reales desde logs).
void main() {
  group('Phase8AdaptationService - Wiring con WeeklyTrainingFeedbackSummary', () {
    late Phase8AdaptationService service;

    setUp(() {
      service = Phase8AdaptationService();
    });

    ExercisePrescription prescription({
      required MuscleGroup muscle,
      required String exerciseCode,
      required String name,
      required int sets,
      String rir = '2',
    }) {
      return ExercisePrescription(
        id: '${exerciseCode}_id',
        sessionId: 'session_1',
        muscleGroup: muscle,
        exerciseCode: exerciseCode,
        label: 'A',
        exerciseName: name,
        sets: sets,
        repRange: const RepRange(8, 12),
        rir: rir,
        restMinutes: 2,
      );
    }

    WeeklyTrainingFeedbackSummary feedback({
      required String signal,
      required bool progressionAllowed,
      required bool deloadRecommended,
      double adherence = 1.0,
      double avgEffort = 7.5,
      double avgRIR = 1.8,
      String fatigueExpectation = 'moderate',
      int stoppedEarly = 0,
      int painEvents = 0,
    }) {
      return WeeklyTrainingFeedbackSummary(
        clientId: 'test_client',
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        plannedSetsTotal: 40,
        completedSetsTotal: (40 * adherence).round(),
        adherenceRatio: adherence,
        avgReportedRIR: avgRIR,
        avgEffort: avgEffort,
        painEvents: painEvents,
        formDegradationEvents: 0,
        stoppedEarlyEvents: stoppedEarly,
        signal: signal,
        fatigueExpectation: fatigueExpectation,
        progressionAllowed: progressionAllowed,
        deloadRecommended: deloadRecommended,
        reasons: ['test'],
        debugContext: {},
      );
    }

    TrainingSessionLog dummyLog() {
      return const TrainingSessionLog(
        dateIso: '2024-01-01',
        sessionName: 'W1-D1',
        entries: <ExerciseLogEntry>[],
        createdAtIso: '2024-01-01T00:00:00.000Z',
      );
    }

    test(
      'phase8_no_logs_keeps_plan_deterministic: sin logs, mantiene plan sin cambios',
      () {
        final prescriptions = {
          0: {
            1: [
              prescription(
                muscle: MuscleGroup.quads,
                exerciseCode: 'squat',
                name: 'Sentadilla',
                sets: 4,
                rir: '2',
              ),
            ],
          },
        };

        final result = service.adapt(
          latestFeedback: null,
          history: TrainingHistory.empty(),
          logs: [],
          weeklyFeedbackSummary: null, // Sin logs
          weekDayPrescriptions: prescriptions,
        );

        expect(result.adaptedWeekDayPrescriptions[0]![1]![0].sets, 4);
        expect(result.adaptedWeekDayPrescriptions[0]![1]![0].rir, '2');

        // Verifica que hay decisión de "no_logs_no_adaptation"
        final skippedDecisions = result.decisions.where(
          (d) => d.category == 'no_logs_no_adaptation',
        );
        expect(skippedDecisions.isNotEmpty, true);
      },
    );

    test(
      'phase8_positive_signal_applies_small_progression: señal positiva → +5-8%',
      () {
        final weeklyFeedback = feedback(
          signal: 'positive',
          progressionAllowed: true,
          deloadRecommended: false,
        );

        final prescriptions = {
          0: {
            1: [
              prescription(
                muscle: MuscleGroup.chest,
                exerciseCode: 'bench_press',
                name: 'Press Banca',
                sets: 4,
                rir: '2',
              ),
            ],
          },
        };

        final result = service.adapt(
          latestFeedback: null,
          history: TrainingHistory.empty(),
          logs: [dummyLog()],
          weeklyFeedbackSummary: weeklyFeedback,
          weekDayPrescriptions: prescriptions,
          trainingLevel: TrainingLevel.intermediate,
        );

        final adaptedSets = result.adaptedWeekDayPrescriptions[0]![1]![0].sets;

        // Para intermediate: 1.06 factor → 4 * 1.06 = 4.24 → 4 sets (round)
        expect(adaptedSets, greaterThanOrEqualTo(4));
        expect(adaptedSets, lessThanOrEqualTo(5));

        // Verifica que hay decisión de "applied" con acción "progress"
        final appliedDecisions = result.decisions.where(
          (d) =>
              d.category == 'phase_8_adaptation_applied' &&
              d.context['action'] == 'progress',
        );
        expect(appliedDecisions.isNotEmpty, true);
      },
    );

    test(
      'phase8_high_fatigue_triggers_deload: señal de alta fatiga → -15% volumen',
      () {
        final weeklyFeedback = feedback(
          signal: 'negative',
          progressionAllowed: false,
          deloadRecommended: true,
          adherence: 0.75,
          avgEffort: 9.2,
          avgRIR: 0.5,
          fatigueExpectation: 'high',
          stoppedEarly: 1,
          painEvents: 1,
        );

        final prescriptions = {
          0: {
            1: [
              prescription(
                muscle: MuscleGroup.hamstrings,
                exerciseCode: 'deadlift',
                name: 'Peso Muerto',
                sets: 4,
                rir: '2',
              ),
            ],
          },
        };

        final volumeLimits = {
          'hamstrings': VolumeLimits(
            muscleGroup: 'hamstrings',
            mev: 2,
            mav: 8,
            mrv: 10,
            recommendedStartVolume: 6,
          ),
        };

        final result = service.adapt(
          latestFeedback: null,
          history: TrainingHistory.empty(),
          logs: [dummyLog()],
          weeklyFeedbackSummary: weeklyFeedback,
          weekDayPrescriptions: prescriptions,
          volumeLimitsByMuscle: volumeLimits,
        );

        final adaptedSets = result.adaptedWeekDayPrescriptions[0]![1]![0].sets;
        final adaptedRIR = result.adaptedWeekDayPrescriptions[0]![1]![0].rir;

        // 4 * 0.85 = 3.4 → 3 sets
        expect(adaptedSets, 3);
        // Phase8 no modifica RIR
        expect(adaptedRIR, '2');
        final deloadDecisions = result.decisions.where(
          (d) =>
              d.category == 'phase_8_adaptation_applied' &&
              d.context['action'] == 'deload',
        );
        expect(deloadDecisions.isNotEmpty, true);
        expect(deloadDecisions.first.context['volumeFactor'], 0.85);
      },
    );

    test('phase8_records_decision_trace_categories: categorías auditables', () {
      final weeklyFeedback = feedback(
        signal: 'positive',
        progressionAllowed: true,
        deloadRecommended: false,
      );

      final prescriptions = {
        0: {
          1: [
            prescription(
              muscle: MuscleGroup.lats,
              exerciseCode: 'row',
              name: 'Remo',
              sets: 4,
              rir: '2',
            ),
          ],
        },
      };

      final result = service.adapt(
        latestFeedback: null,
        history: TrainingHistory.empty(),
        logs: [dummyLog()],
        weeklyFeedbackSummary: weeklyFeedback,
        weekDayPrescriptions: prescriptions,
      );

      // Verifica que todas las decisiones tienen categorías auditables
      expect(result.decisions.isNotEmpty, true);

      final categories = result.decisions.map((d) => d.category).toSet();
      expect(categories.any((c) => c.startsWith('phase_8_')), true);

      // Verifica que hay contexto con metadata
      final decisionsWithContext = result.decisions.where(
        (d) => d.context.isNotEmpty,
      );
      expect(decisionsWithContext.isNotEmpty, true);
    });

    test(
      'phase8_respects_mev_mrv_on_deload: deload respeta límites MEV/MRV',
      () {
        final weeklyFeedback = feedback(
          signal: 'negative',
          progressionAllowed: false,
          deloadRecommended: true,
          adherence: 0.5,
          avgEffort: 9.5,
          avgRIR: 0.2,
          fatigueExpectation: 'high',
          stoppedEarly: 2,
        );

        final prescriptions = {
          0: {
            1: [
              prescription(
                muscle: MuscleGroup.biceps,
                exerciseCode: 'curl',
                name: 'Curl Bíceps',
                sets: 4,
                rir: '2',
              ),
            ],
          },
        };

        final volumeLimits = {
          'biceps': VolumeLimits(
            muscleGroup: 'biceps',
            mev: 3,
            mav: 6,
            mrv: 8,
            recommendedStartVolume: 5,
          ),
        };

        final result = service.adapt(
          latestFeedback: null,
          history: TrainingHistory.empty(),
          logs: [dummyLog()],
          weeklyFeedbackSummary: weeklyFeedback,
          weekDayPrescriptions: prescriptions,
          volumeLimitsByMuscle: volumeLimits,
        );

        final adaptedSets = result.adaptedWeekDayPrescriptions[0]![1]![0].sets;

        // 4 * 0.85 = 3.4 → 3 sets (dentro de MEV=3, MRV=8)
        expect(adaptedSets, 3);
        expect(adaptedSets, greaterThanOrEqualTo(volumeLimits['biceps']!.mev));
        expect(adaptedSets, lessThanOrEqualTo(volumeLimits['biceps']!.mrv));
      },
    );

    test(
      'phase8_moderate_signal_maintains_plan: señal moderada sin progresión clara → mantener',
      () {
        final weeklyFeedback = feedback(
          signal: 'moderate',
          progressionAllowed: false,
          deloadRecommended: false,
          adherence: 0.75,
          avgEffort: 8.0,
          avgRIR: 1.5,
          fatigueExpectation: 'moderate',
        );

        final prescriptions = {
          0: {
            1: [
              prescription(
                muscle: MuscleGroup.shoulders,
                exerciseCode: 'overhead_press',
                name: 'Press Militar',
                sets: 3,
                rir: '2',
              ),
            ],
          },
        };

        final result = service.adapt(
          latestFeedback: null,
          history: TrainingHistory.empty(),
          logs: [dummyLog()],
          weeklyFeedbackSummary: weeklyFeedback,
          weekDayPrescriptions: prescriptions,
        );

        final adaptedSets = result.adaptedWeekDayPrescriptions[0]![1]![0].sets;
        final adaptedRIR = result.adaptedWeekDayPrescriptions[0]![1]![0].rir;

        // Sin progresión ni deload → mantener
        expect(adaptedSets, 3);
        expect(adaptedRIR, '2');

        // Verifica que hay decisión de "skipped" (mantener)
        final maintainDecisions = result.decisions.where(
          (d) =>
              d.category == 'phase_8_adaptation_skipped' &&
              d.context['action'] == 'maintain',
        );
        expect(maintainDecisions.isNotEmpty, true);
      },
    );
  });
}
