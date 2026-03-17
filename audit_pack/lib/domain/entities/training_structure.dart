import 'package:equatable/equatable.dart';

/// Estructura lockeada del plan. NO es prescripción.
/// Se mantiene estable por decisión del coach (bloque condicional, no por semanas fijas).
class TrainingStructure extends Equatable {
  final String splitId;
  final int daysPerWeek;

  /// Guardrails de densidad (para evitar días subdensos).
  final int minExercisesPerDay;
  final int targetExercisesPerDay;

  /// Lock condicional: untilWeek puede ser null (bloque abierto).
  final int lockedFromWeek;
  final int? lockedUntilWeek;

  const TrainingStructure({
    required this.splitId,
    required this.daysPerWeek,
    required this.minExercisesPerDay,
    required this.targetExercisesPerDay,
    required this.lockedFromWeek,
    required this.lockedUntilWeek,
  });

  bool isLockedForWeekIndex(int weekIndex) {
    final until = lockedUntilWeek;
    if (until == null) return weekIndex >= lockedFromWeek;
    return weekIndex >= lockedFromWeek && weekIndex <= until;
  }

  Map<String, dynamic> toMap() => {
    'splitId': splitId,
    'daysPerWeek': daysPerWeek,
    'minExercisesPerDay': minExercisesPerDay,
    'targetExercisesPerDay': targetExercisesPerDay,
    'lockedFromWeek': lockedFromWeek,
    'lockedUntilWeek': lockedUntilWeek,
  };

  factory TrainingStructure.fromMap(Map<String, dynamic> map) {
    int readInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    final untilRaw = map['lockedUntilWeek'];
    final until = (untilRaw == null) ? null : readInt(untilRaw, 0);

    return TrainingStructure(
      splitId: map['splitId']?.toString() ?? '',
      daysPerWeek: readInt(map['daysPerWeek'], 0),
      minExercisesPerDay: readInt(map['minExercisesPerDay'], 5),
      targetExercisesPerDay: readInt(map['targetExercisesPerDay'], 7),
      lockedFromWeek: readInt(map['lockedFromWeek'], 0),
      lockedUntilWeek: (until != null && until <= 0) ? null : until,
    );
  }

  @override
  List<Object?> get props => [
    splitId,
    daysPerWeek,
    minExercisesPerDay,
    targetExercisesPerDay,
    lockedFromWeek,
    lockedUntilWeek,
  ];
}
