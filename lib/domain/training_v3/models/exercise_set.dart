import 'package:equatable/equatable.dart';

/// Modelo de un set individual con intensidad aplicada
class ExerciseSet extends Equatable {
  final String id;
  final int reps;
  final double weight;
  final Duration rest;
  final double rir; // Reps in Reserve

  const ExerciseSet({
    required this.id,
    required this.reps,
    required this.weight,
    required this.rest,
    required this.rir,
  });

  @override
  List<Object?> get props => [id, reps, weight, rest, rir];
}
