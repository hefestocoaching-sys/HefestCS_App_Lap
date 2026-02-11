import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';
import 'package:hcs_app_lap/domain/services/training_feedback_aggregator_service.dart';

void main() {
  group('TrainingFeedbackAggregatorService', () {
    late TrainingFeedbackAggregatorService service;

    setUp(() {
      service = TrainingFeedbackAggregatorService();
    });

    // =========================================================================
    // HELPERS PARA CREAR LOGS DETERMINISTAS
    // =========================================================================

    TrainingSessionLogV2 createLog({
      required DateTime sessionDate,
      String clientId = 'client-1',
      String exerciseId = 'exercise-1',
      int plannedSets = 4,
      int completedSets = 4,
      double avgReportedRIR = 2.0,
      int perceivedEffort = 7,
      bool painFlag = false,
      bool formDegradation = false,
      bool stoppedEarly = false,
    }) {
      return TrainingSessionLogV2(
        id: 'log-${sessionDate.toIso8601String()}',
        clientId: clientId,
        exerciseId: exerciseId,
        sessionDate: sessionDate,
        createdAt: sessionDate.add(const Duration(hours: 1)),
        source: 'mobile',
        plannedSets: plannedSets,
        completedSets: completedSets,
        avgReportedRIR: avgReportedRIR,
        perceivedEffort: perceivedEffort,
        stoppedEarly: stoppedEarly,
        painFlag: painFlag,
        formDegradation: formDegradation,
        schemaVersion: 'v1.0.0',
      );
    }

    // =========================================================================
    // TESTS DE SEÑALES POSITIVAS
    // =========================================================================

    test('positive_signal_when_low_fatigue_high_adherence_no_pain', () {
      // Semana del lunes 15 enero 2025
      final referenceDate = DateTime(2025, 1, 15); // miércoles
      final logs = [
        createLog(
          sessionDate: DateTime(2025, 1, 13), // lunes
          avgReportedRIR: 2.5,
          perceivedEffort: 6,
        ),
        createLog(
          sessionDate: DateTime(2025, 1, 15), // miércoles
          perceivedEffort: 6,
        ),
        createLog(
          sessionDate: DateTime(2025, 1, 17), // viernes
          avgReportedRIR: 2.5,
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 12,
      );

      expect(summary.signal, equals('positive'));
      expect(summary.fatigueExpectation, equals('low'));
      expect(summary.progressionAllowed, isTrue);
      expect(summary.deloadRecommended, isFalse);
      expect(summary.adherenceRatio, equals(1.0)); // 12/12
      expect(summary.completedSetsTotal, equals(12));
      expect(summary.painEvents, equals(0));
      expect(summary.stoppedEarlyEvents, equals(0));
      expect(summary.reasons, contains('signal_positive_conditions_met'));
      expect(summary.reasons, contains('progression_allowed'));
    });

    // =========================================================================
    // TESTS DE SEÑALES NEGATIVAS
    // =========================================================================

    test('negative_signal_when_pain_event_present', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(
          sessionDate: DateTime(2025, 1, 13),
          painFlag: true, // DOLOR
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 12,
      );

      expect(summary.signal, equals('negative'));
      expect(summary.fatigueExpectation, equals('high'));
      expect(summary.progressionAllowed, isFalse);
      expect(summary.deloadRecommended, isTrue);
      expect(summary.painEvents, equals(1));
      expect(summary.reasons, contains('pain_event_present'));
      expect(summary.reasons, contains('signal_negative_high_fatigue'));
      expect(summary.reasons, contains('progression_not_allowed'));
      expect(summary.reasons, contains('deload_recommended_high_fatigue'));
    });

    test('negative_signal_when_stopped_early', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(
          sessionDate: DateTime(2025, 1, 13),
          completedSets: 2,
          avgReportedRIR: 1.0,
          perceivedEffort: 9,
          stoppedEarly: true, // DETENCIÓN TEMPRANA
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 12,
      );

      expect(summary.signal, equals('negative'));
      expect(summary.fatigueExpectation, equals('high'));
      expect(summary.progressionAllowed, isFalse);
      expect(summary.deloadRecommended, isTrue);
      expect(summary.stoppedEarlyEvents, equals(1));
      expect(summary.reasons, contains('stopped_early_event_present'));
    });

    test('negative_signal_when_avg_effort_very_high', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(
          sessionDate: DateTime(2025, 1, 13),
          avgReportedRIR: 0.5,
          perceivedEffort: 9, // ESFUERZO ALTO
        ),
        createLog(
          sessionDate: DateTime(2025, 1, 15),
          avgReportedRIR: 0.5,
          perceivedEffort: 9,
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 8,
      );

      expect(summary.signal, equals('negative'));
      expect(summary.fatigueExpectation, equals('high'));
      expect(summary.avgEffort, equals(9.0));
      expect(summary.reasons, contains('avg_effort_high'));
    });

    test('negative_signal_when_adherence_very_low', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(sessionDate: DateTime(2025, 1, 13), completedSets: 2),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 12, // Solo completó 2/12 = 16.6%
      );

      expect(summary.signal, equals('negative'));
      expect(summary.fatigueExpectation, equals('high'));
      expect(summary.adherenceRatio, closeTo(0.166, 0.01));
      expect(summary.deloadRecommended, isTrue);
      expect(summary.reasons, contains('adherence_very_low'));
      expect(summary.reasons, contains('deload_recommended_high_fatigue'));
    });

    // =========================================================================
    // TESTS DE FATIGA MODERADA
    // =========================================================================

    test('moderate_fatigue_when_form_degradation_present', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(
          sessionDate: DateTime(2025, 1, 13),
          avgReportedRIR: 2.5,
          perceivedEffort: 6,
          formDegradation: true, // DEGRADACIÓN TÉCNICA
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 4, // Cambiar para que adherencia sea 100%
      );

      expect(summary.fatigueExpectation, equals('moderate'));
      expect(summary.signal, equals('ambiguous'));
      expect(summary.progressionAllowed, isFalse);
      expect(summary.formDegradationEvents, equals(1));
      expect(summary.reasons, contains('form_degradation_present'));
      expect(summary.reasons, contains('signal_ambiguous_mixed_indicators'));
    });

    test('moderate_fatigue_when_avg_effort_moderate', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(sessionDate: DateTime(2025, 1, 13)),
        createLog(sessionDate: DateTime(2025, 1, 15), perceivedEffort: 8),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 8,
      );

      expect(summary.fatigueExpectation, equals('moderate'));
      expect(summary.signal, equals('ambiguous'));
      expect(summary.avgEffort, equals(7.5));
      expect(summary.reasons, contains('avg_effort_moderate'));
    });

    test('moderate_fatigue_when_adherence_moderate', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(
          sessionDate: DateTime(2025, 1, 13),
          completedSets: 3,
          avgReportedRIR: 2.5,
          perceivedEffort: 6,
        ),
        createLog(
          sessionDate: DateTime(2025, 1, 15),
          completedSets: 3,
          avgReportedRIR: 2.5,
          perceivedEffort: 6,
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 8, // 6/8 = 75% adherencia
      );

      expect(summary.fatigueExpectation, equals('moderate'));
      expect(summary.adherenceRatio, equals(0.75));
      expect(summary.reasons, contains('adherence_moderate'));
    });

    // =========================================================================
    // TESTS DE CÁLCULOS
    // =========================================================================

    test('weighted_average_by_completed_sets', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(sessionDate: DateTime(2025, 1, 13), perceivedEffort: 8),
        createLog(
          sessionDate: DateTime(2025, 1, 15),
          completedSets: 2,
          avgReportedRIR: 3.0,
          perceivedEffort: 6,
        ),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        plannedSetsThisWeek: 6,
      );

      // avgReportedRIR = (2.0*4 + 3.0*2) / 6 = (8 + 6) / 6 = 14/6 = 2.333...
      expect(summary.avgReportedRIR, closeTo(2.333, 0.01));

      // avgEffort = (8*4 + 6*2) / 6 = (32 + 12) / 6 = 44/6 = 7.333...
      expect(summary.avgEffort, closeTo(7.333, 0.01));
    });

    test('adherence_ratio_clamped_and_zero_when_planned_zero', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [createLog(sessionDate: DateTime(2025, 1, 13))];

      // Sin plannedSetsThisWeek (default 0)
      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
        // plannedSetsThisWeek no especificado, usa plannedSets de logs
      );

      // Debería usar plannedSets de logs = 4
      expect(summary.plannedSetsTotal, equals(4));
      expect(summary.adherenceRatio, equals(1.0));

      // Caso con plannedSetsThisWeek = 0 explícito
      final summary2 = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: [],
      );

      expect(summary2.adherenceRatio, equals(0.0));
      expect(summary2.reasons, contains('planned_sets_zero'));
    });

    // =========================================================================
    // TESTS DE SEGMENTACIÓN DE SEMANA
    // =========================================================================

    test('week_segmentation_filters_outside_logs', () {
      // Semana del 13-19 enero 2025 (lunes-domingo)
      final referenceDate = DateTime(2025, 1, 15); // miércoles

      final logs = [
        // DENTRO de la semana
        createLog(sessionDate: DateTime(2025, 1, 13)), // lunes
        createLog(sessionDate: DateTime(2025, 1, 19)), // domingo
        // FUERA de la semana
        createLog(sessionDate: DateTime(2025, 1, 12)), // domingo anterior
        createLog(sessionDate: DateTime(2025, 1, 20)), // lunes siguiente
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
      );

      // Solo deben contarse 2 logs (lunes y domingo de la semana)
      expect(summary.debugContext['logsCount'], equals(2));
      expect(summary.completedSetsTotal, equals(8)); // 4*2
    });

    test('week_start_is_monday_00_00', () {
      // Cualquier día de la semana debe mapear al lunes anterior
      final wednesday = DateTime(2025, 1, 15); // miércoles 15
      final sunday = DateTime(2025, 1, 19); // domingo 19
      final monday = DateTime(2025, 1, 13); // lunes 13

      final logs = [createLog(sessionDate: DateTime(2025, 1, 13))];

      final summaryWed = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: wednesday,
        logs: logs,
      );

      final summarySun = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: sunday,
        logs: logs,
      );

      final summaryMon = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: monday,
        logs: logs,
      );

      // Todos deben tener el mismo weekStart (lunes 13)
      expect(summaryWed.weekStart, equals(DateTime(2025, 1, 13)));
      expect(summarySun.weekStart, equals(DateTime(2025, 1, 13)));
      expect(summaryMon.weekStart, equals(DateTime(2025, 1, 13)));
    });

    test('filters_logs_from_different_client', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [
        createLog(sessionDate: DateTime(2025, 1, 13)),
        createLog(
          sessionDate: DateTime(2025, 1, 14),
          clientId: 'client-2', // DIFERENTE CLIENTE
        ),
        createLog(sessionDate: DateTime(2025, 1, 15)),
      ];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
      );

      // Solo deben contarse 2 logs de client-1
      expect(summary.debugContext['logsCount'], equals(2));
      expect(summary.completedSetsTotal, equals(8));
    });

    // =========================================================================
    // TESTS DE EDGE CASES
    // =========================================================================

    test('empty_logs_produces_safe_summary', () {
      final referenceDate = DateTime(2025, 1, 15);

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: [],
        plannedSetsThisWeek: 12,
      );

      expect(summary.completedSetsTotal, equals(0));
      expect(summary.adherenceRatio, equals(0.0));
      expect(summary.avgReportedRIR, equals(0.0));
      expect(summary.avgEffort, equals(0.0));
      expect(summary.painEvents, equals(0));
      expect(summary.formDegradationEvents, equals(0));
      expect(summary.stoppedEarlyEvents, equals(0));
      expect(
        summary.signal,
        equals('negative'),
      ); // adherence_very_low → high fatigue → negative
      expect(summary.progressionAllowed, isFalse);
    });

    test(
      'deload_recommended_when_low_adherence_even_with_moderate_fatigue',
      () {
        final referenceDate = DateTime(2025, 1, 15);
        final logs = [
          createLog(
            sessionDate: DateTime(2025, 1, 13),
            completedSets: 2,
            avgReportedRIR: 2.5,
            perceivedEffort: 6,
          ),
        ];

        final summary = service.summarizeWeek(
          clientId: 'client-1',
          referenceDate: referenceDate,
          logs: logs,
          plannedSetsThisWeek: 12, // 2/12 = 16.6% adherencia
        );

        expect(summary.deloadRecommended, isTrue);
        expect(summary.reasons, contains('deload_recommended_high_fatigue'));
      },
    );

    test('serialization_and_deserialization', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [createLog(sessionDate: DateTime(2025, 1, 13))];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
      );

      final json = summary.toJson();
      final deserialized = WeeklyTrainingFeedbackSummary.fromJson(json);

      expect(deserialized.clientId, equals(summary.clientId));
      expect(deserialized.signal, equals(summary.signal));
      expect(
        deserialized.fatigueExpectation,
        equals(summary.fatigueExpectation),
      );
      expect(
        deserialized.progressionAllowed,
        equals(summary.progressionAllowed),
      );
      expect(deserialized.adherenceRatio, equals(summary.adherenceRatio));
      expect(deserialized.reasons, equals(summary.reasons));
    });

    test('debug_context_includes_all_thresholds', () {
      final referenceDate = DateTime(2025, 1, 15);
      final logs = [createLog(sessionDate: DateTime(2025, 1, 13))];

      final summary = service.summarizeWeek(
        clientId: 'client-1',
        referenceDate: referenceDate,
        logs: logs,
      );

      expect(summary.debugContext, isNotEmpty);
      expect(summary.debugContext['thresholds'], isNotNull);
      expect(
        summary.debugContext['thresholds']['adherence_high'],
        equals(0.85),
      );
      expect(summary.debugContext['thresholds']['effort_high'], equals(8.5));
      expect(summary.debugContext['weekStart'], isNotNull);
      expect(summary.debugContext['weekEnd'], isNotNull);
    });
  });
}
