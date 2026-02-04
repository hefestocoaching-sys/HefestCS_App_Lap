import 'package:equatable/equatable.dart';

/// Modelo de ejercicio prescrito con instrucciones
class PrescribedExercise extends Equatable {
  final String exerciseId;
  final int sets;
  final int reps;
  final int rir;
  final Duration rest;
  final String? notes;

  const PrescribedExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.rir,
    required this.rest,
    this.notes,
  });

  @override
  List<Object?> get props => [exerciseId, sets, reps, rir, rest, notes];
}
