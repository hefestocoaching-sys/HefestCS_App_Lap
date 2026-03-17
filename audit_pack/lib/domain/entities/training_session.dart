import 'package:equatable/equatable.dart';
import 'exercise_prescription.dart';

class TrainingSession extends Equatable {
  final String id;
  final int dayNumber;
  final String sessionName;
  final List<ExercisePrescription> prescriptions;

  // Alias para compatibilidad con código que busca 'exercises'
  List<ExercisePrescription> get exercises => prescriptions;

  const TrainingSession({
    required this.id,
    required this.dayNumber,
    required this.sessionName,
    required this.prescriptions,
  });

  TrainingSession copyWith({
    String? id,
    int? dayNumber,
    String? sessionName,
    List<ExercisePrescription>? prescriptions,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      sessionName: sessionName ?? this.sessionName,
      prescriptions: prescriptions ?? this.prescriptions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayNumber': dayNumber,
    'sessionName': sessionName,
    'prescriptions': prescriptions.map((e) => e.toJson()).toList(),
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final resolvedDayNumber = json['dayNumber'] as int? ?? 1;
    final resolvedSessionName = json['sessionName'] as String? ?? 'Sesión';
    return TrainingSession(
      id: (rawId != null && rawId.isNotEmpty)
          ? rawId
          : 'session-$resolvedDayNumber-$resolvedSessionName',
      dayNumber: resolvedDayNumber,
      sessionName: resolvedSessionName,
      prescriptions: (json['prescriptions'] as List<dynamic>? ?? [])
          .map((e) => ExercisePrescription.fromJson(e))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, dayNumber, sessionName, prescriptions];
}
