import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'training_session.dart';

class TrainingWeek extends Equatable {
  final String id;
  final int weekNumber;
  final TrainingPhase phase;
  final List<TrainingSession> sessions;

  const TrainingWeek({
    required this.id,
    required this.weekNumber,
    required this.phase,
    required this.sessions,
  });

  TrainingWeek copyWith({
    String? id,
    int? weekNumber,
    TrainingPhase? phase,
    List<TrainingSession>? sessions,
  }) {
    return TrainingWeek(
      id: id ?? this.id,
      weekNumber: weekNumber ?? this.weekNumber,
      phase: phase ?? this.phase,
      sessions: sessions ?? this.sessions,
    );
  }

  // CORRECCIÓN: Alias de compatibilidad
  Map<String, dynamic> toMap() => toJson();

  factory TrainingWeek.fromMap(Map<String, dynamic> map) =>
      TrainingWeek.fromJson(map);

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekNumber': weekNumber,
    'phase': phase.name,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };

  factory TrainingWeek.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final resolvedWeekNumber = json['weekNumber'] as int? ?? 1;
    final resolvedPhase = TrainingPhase.values.firstWhere(
      (e) => e.name == json['phase'],
      orElse: () => TrainingPhase.accumulation,
    );
    return TrainingWeek(
      id: (rawId != null && rawId.isNotEmpty)
          ? rawId
          : 'week-$resolvedWeekNumber-${resolvedPhase.name}',
      weekNumber: resolvedWeekNumber,
      phase: resolvedPhase,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((e) => TrainingSession.fromJson(e))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, weekNumber, phase, sessions];
}
