import 'package:equatable/equatable.dart';

/// Modelo de semana de entrenamiento
class TrainingWeek extends Equatable {
  final int weekNumber;
  final List<dynamic> sessions; // TrainingSession
  final String notes;

  const TrainingWeek({
    required this.weekNumber,
    required this.sessions,
    required this.notes,
  });

  @override
  List<Object?> get props => [weekNumber, sessions, notes];
}
