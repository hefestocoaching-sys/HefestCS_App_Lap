import 'package:uuid/uuid.dart';

class PlannedExercise {
  final String id;
  final String exerciseId;
  final String name;
  final String muscleKey;

  final List<SetPrescription> sets;

  final IntensificationRule? intensification;

  PlannedExercise({
    String? id,
    required this.exerciseId,
    required this.name,
    required this.muscleKey,
    required this.sets,
    this.intensification,
  }) : id = id ?? const Uuid().v4();
}

class SetPrescription {
  final int repsMin;
  final int repsMax;
  final int rir;

  const SetPrescription({
    required this.repsMin,
    required this.repsMax,
    required this.rir,
  });
}

enum IntensificationType { restPause, dropSet, myoReps, cluster, isometricHold }

class IntensificationRule {
  final IntensificationType type;
  final bool applyToLastSetOnly;
  final bool applyToLastTwoSets;

  const IntensificationRule({
    required this.type,
    this.applyToLastSetOnly = true,
    this.applyToLastTwoSets = false,
  });
}
