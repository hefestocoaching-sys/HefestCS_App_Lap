import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';

class TrainingPlan {
  final String id;
  final String clientId;
  final String name;
  final DateTime startDate;
  final List<TrainingWeek> weeks;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Metadata Motor V3 (opcional pero preservada)
  final String? phase;
  final String? split;
  final Map<String, int>? volumePerMuscle;

  const TrainingPlan({
    required this.id,
    required this.clientId,
    required this.name,
    required this.startDate,
    required this.weeks,
    required this.createdAt,
    required this.updatedAt,
    this.phase,
    this.split,
    this.volumePerMuscle,
  });

  int get totalWeeks => weeks.length;

  int get totalWorkouts =>
      weeks.fold(0, (sum, week) => sum + week.sessions.length);

  TrainingPlan copyWith({
    String? id,
    String? clientId,
    String? name,
    DateTime? startDate,
    List<TrainingWeek>? weeks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phase,
    String? split,
    Map<String, int>? volumePerMuscle,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      weeks: weeks ?? this.weeks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phase: phase ?? this.phase,
      split: split ?? this.split,
      volumePerMuscle: volumePerMuscle ?? this.volumePerMuscle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'weeks': weeks
          .map(
            (w) => {
              'weekNumber': w.weekNumber,
              'sessions': w.sessions,
              'notes': w.notes,
            },
          )
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'phase': phase,
      'split': split,
      'volumePerMuscle': volumePerMuscle,
    };
  }

  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    return TrainingPlan(
      id: map['id'],
      clientId: map['clientId'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      weeks: (map['weeks'] as List)
          .map(
            (w) => TrainingWeek(
              weekNumber: (w as Map)['weekNumber'] as int? ?? 1,
              sessions: (w)['sessions'] as List<dynamic>? ?? const [],
              notes: (w)['notes'] as String? ?? '',
            ),
          )
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      phase: map['phase'],
      split: map['split'],
      volumePerMuscle: map['volumePerMuscle'] != null
          ? Map<String, int>.from(map['volumePerMuscle'])
          : null,
    );
  }
}
