import 'dart:math';

import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';

class MesocycleEngine {
  /// Builds a 4-week mesocycle from a baseline week.
  ///
  /// Week 1: baseline
  /// Week 2: +5% sets on accessory slots
  /// Week 3: +10% sets on accessory slots
  /// Week 4: deload 60% of baseline sets
  static List<TrainingWeek> generateFourWeeks({
    required List<TrainingSession> baselineSessions,
  }) {
    final week1 = _cloneSessions(baselineSessions);
    final week2 = _scaleAccessory(
      _cloneSessions(baselineSessions),
      factor: 1.05,
    );
    final week3 = _scaleAccessory(
      _cloneSessions(baselineSessions),
      factor: 1.10,
    );
    final week4 = _scaleAll(_cloneSessions(baselineSessions), factor: 0.60);

    return [
      TrainingWeek(
        weekNumber: 1,
        sessions: week1,
        notes: 'Semana 1 - baseline',
      ),
      TrainingWeek(
        weekNumber: 2,
        sessions: week2,
        notes: 'Semana 2 - progresión accesorios +5%',
      ),
      TrainingWeek(
        weekNumber: 3,
        sessions: week3,
        notes: 'Semana 3 - progresión accesorios +10%',
      ),
      TrainingWeek(
        weekNumber: 4,
        sessions: week4,
        notes: 'Semana 4 - deload 60%',
      ),
    ];
  }

  static List<TrainingSession> _cloneSessions(List<TrainingSession> sessions) {
    return sessions
        .map(
          (session) => session.copyWith(
            exercises: session.exercises
                .map(
                  (exercise) => exercise.copyWith(
                    sets: List<SetPrescription>.from(exercise.sets),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  static List<TrainingSession> _scaleAccessory(
    List<TrainingSession> sessions, {
    required double factor,
  }) {
    return sessions
        .map(
          (session) => session.copyWith(
            exercises: session.exercises.map((exercise) {
              final isAccessory = !_isPrimaryA(exercise);
              if (!isAccessory) return exercise;
              return exercise.copyWith(sets: _scaleSets(exercise.sets, factor));
            }).toList(),
          ),
        )
        .toList();
  }

  static List<TrainingSession> _scaleAll(
    List<TrainingSession> sessions, {
    required double factor,
  }) {
    return sessions
        .map(
          (session) => session.copyWith(
            exercises: session.exercises
                .map(
                  (exercise) => exercise.copyWith(
                    sets: _scaleSets(exercise.sets, factor),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  static bool _isPrimaryA(PlannedExercise exercise) {
    if (exercise.blockLabel == 'A') return true;
    if (exercise.slotLabel == 'A') return true;
    return exercise.isMainLift;
  }

  static List<SetPrescription> _scaleSets(
    List<SetPrescription> baselineSets,
    double factor,
  ) {
    if (baselineSets.isEmpty) {
      return const [SetPrescription(repsMin: 8, repsMax: 12, rir: 2)];
    }

    final baselineCount = baselineSets.length;
    final nextCount = max(1, (baselineCount * factor).round());

    if (nextCount == baselineCount) {
      return List<SetPrescription>.from(baselineSets);
    }

    if (nextCount < baselineCount) {
      return baselineSets.sublist(0, nextCount);
    }

    final template = baselineSets.last;
    final extra = List<SetPrescription>.generate(
      nextCount - baselineCount,
      (_) => template,
    );
    return [...baselineSets, ...extra];
  }
}
