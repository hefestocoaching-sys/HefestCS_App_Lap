import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';

class FormattedTrainingPlan {
  final List<FormattedWeek> weeks;

  const FormattedTrainingPlan({required this.weeks});
}

class FormattedWeek {
  final int weekNumber;
  final List<FormattedSession> sessions;

  const FormattedWeek({required this.weekNumber, required this.sessions});
}

class FormattedSession {
  final String sessionId;
  final int dayNumber;
  final String name;
  final List<FormattedExerciseRow> rows;

  const FormattedSession({
    required this.sessionId,
    required this.dayNumber,
    required this.name,
    required this.rows,
  });
}

class FormattedExerciseRow {
  final String slotLabel;
  final String blockLabel;
  final String exerciseName;
  final String primaryMuscle;
  final int sets;
  final String reps;

  const FormattedExerciseRow({
    required this.slotLabel,
    required this.blockLabel,
    required this.exerciseName,
    required this.primaryMuscle,
    required this.sets,
    required this.reps,
  });
}

const List<String> _slotOrder = ['A', 'B1', 'B2', 'C1', 'C2', 'D1', 'D2'];

FormattedTrainingPlan formatPlan(TrainingPlan plan) {
  final formattedWeeks = <FormattedWeek>[];

  for (final week in plan.weeks) {
    final sessions = week.sessions.whereType<TrainingSession>().toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    final formattedSessions = <FormattedSession>[];
    for (final session in sessions) {
      final sortedExercises = List<PlannedExercise>.from(session.exercises)
        ..sort((a, b) {
          final idxA = _slotOrder.indexOf((a.slotLabel ?? '').toUpperCase());
          final idxB = _slotOrder.indexOf((b.slotLabel ?? '').toUpperCase());
          final aRank = idxA >= 0 ? idxA : 1 << 20;
          final bRank = idxB >= 0 ? idxB : 1 << 20;
          if (aRank != bRank) return aRank.compareTo(bRank);
          return a.name.compareTo(b.name);
        });

      final rows = sortedExercises.map((exercise) {
        final sets = exercise.sets.length;
        final reps = _repsLabel(exercise.sets);
        return FormattedExerciseRow(
          slotLabel: exercise.slotLabel ?? '-',
          blockLabel: exercise.blockLabel ?? '-',
          exerciseName: exercise.name,
          primaryMuscle: exercise.primaryMuscle,
          sets: sets,
          reps: reps,
        );
      }).toList();

      formattedSessions.add(
        FormattedSession(
          sessionId: session.id,
          dayNumber: session.dayNumber,
          name: session.name,
          rows: rows,
        ),
      );
    }

    formattedWeeks.add(
      FormattedWeek(weekNumber: week.weekNumber, sessions: formattedSessions),
    );
  }

  return FormattedTrainingPlan(weeks: formattedWeeks);
}

String _repsLabel(List<SetPrescription> sets) {
  if (sets.isEmpty) return '-';
  final minReps = sets.map((s) => s.repsMin).reduce((a, b) => a < b ? a : b);
  final maxReps = sets.map((s) => s.repsMax).reduce((a, b) => a > b ? a : b);
  if (minReps == maxReps) return '$minReps';
  return '$minReps-$maxReps';
}
