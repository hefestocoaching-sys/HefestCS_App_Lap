// test/domain/training_v3/engines/deload_trigger_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/deload_trigger_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';

void main() {
  group('DeloadTriggerEngine', () {
    group('evaluateDeloadNeed', () {
      test('debe recomendar deload con score alto (fatiga crítica)', () {
        final logs = [
          _createMockLog(prs: 3, rpe: 9.5, doms: 8, adherence: 60),
          _createMockLog(prs: 2, rpe: 9.0, doms: 7, adherence: 65),
        ];

        final result = DeloadTriggerEngine.evaluateDeloadNeed(
          recentLogs: logs,
          weeksInProgram: 6,
        );

        expect(result['needs_deload'], isTrue);
        expect(result['urgency'], equals('urgent'));
      });

      test('NO debe recomendar deload con score bajo (todo bien)', () {
        final logs = [
          _createMockLog(prs: 8, rpe: 7.5, doms: 3, adherence: 95),
          _createMockLog(prs: 8, rpe: 7.0, doms: 2, adherence: 90),
        ];

        final result = DeloadTriggerEngine.evaluateDeloadNeed(
          recentLogs: logs,
          weeksInProgram: 2,
        );

        expect(result['needs_deload'], isFalse);
        expect(result['urgency'], equals('none'));
      });

      test('debe incluir protocol de deload completo si urgente', () {
        final logs = [_createMockLog(prs: 2, rpe: 9.5, doms: 8, adherence: 60)];

        final result = DeloadTriggerEngine.evaluateDeloadNeed(
          recentLogs: logs,
          weeksInProgram: 7,
        );

        expect(result['protocol'], isNotNull);
        expect(result['protocol']['type'], equals('complete_deload'));
      });
    });
  });
}

WorkoutLog _createMockLog({
  required double prs,
  required double rpe,
  required double doms,
  required double adherence,
}) {
  final now = DateTime.now();
  return WorkoutLog(
    id: 'log_${now.millisecondsSinceEpoch}',
    userId: 'test_user',
    programId: 'test_program',
    plannedSessionId: 'test_session',
    startTime: now,
    endTime: now.add(const Duration(hours: 1)),
    exerciseLogs: const [],
    sessionRpe: rpe,
    perceivedRecoveryStatus: prs,
    muscleSoreness: doms,
    adherencePercentage: adherence,
    completed: true,
    createdAt: now,
  );
}
