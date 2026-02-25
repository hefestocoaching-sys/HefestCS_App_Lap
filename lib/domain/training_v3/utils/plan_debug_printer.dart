import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';

class PlanDebugPrinter {
  static String toPrettyText(TrainingPlanConfig plan) {
    final buffer = StringBuffer();

    buffer.writeln('=== PLAN DEBUG: ${plan.id} ===');
    buffer.writeln('Split: ${plan.split}');
    buffer.writeln('Phase: ${plan.phase}');
    buffer.writeln('Duration: ${plan.weeks.length} weeks');
    buffer.writeln('--------------------------------');

    for (var week in plan.weeks) {
      if (week is! TrainingWeek) continue;

      buffer.writeln('\nWEEK ${week.weekNumber}:');
      buffer.writeln('  Notes: ${week.notes}');

      int weekVolume = 0;

      for (var session in week.sessions) {
        if (session is! TrainingSession) continue;

        buffer.writeln('  DAY ${session.dayNumber} (${session.name}):');

        for (var i = 0; i < session.exercises.length; i++) {
          final p = session.exercises[i];
          final setCount = p.sets.length;
          weekVolume += setCount;
          final repsDesc = p.sets.isNotEmpty
              ? '${p.sets.first.repsMin}–${p.sets.last.repsMax}'
              : 'N/A';
          final rirDesc = p.sets.isNotEmpty ? '${p.sets.first.rir}' : '?';
          buffer.writeln(
            '    ${i + 1}. ${p.name} | Sets: $setCount | Reps: $repsDesc | RIR: $rirDesc | ${p.muscleKey}',
          );
        }
      }
      buffer.writeln('  >> Total Weekly Volume: $weekVolume sets');
    }

    // Print Decision Trace if available
    if (plan.extra['v3_decision_trace'] != null) {
      buffer.writeln('\n=== DECISION TRACE ===');
      final trace = plan.extra['v3_decision_trace'] as Map;
      if (trace['weekDecisions'] != null) {
        (trace['weekDecisions'] as Map).forEach((k, v) {
          buffer.writeln('  Week $k Decisions: $v');
        });
      }
    }

    return buffer.toString();
  }
}
