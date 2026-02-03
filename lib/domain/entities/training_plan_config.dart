import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'training_profile.dart';

class TrainingPlanConfig extends Equatable {
  final String id;
  final String name;
  final String clientId;
  final DateTime startDate;
  final TrainingPhase phase;
  final String splitId;
  final int microcycleLengthInWeeks;
  final List<TrainingWeek> weeks;
  final Map<String, dynamic>? state;
  final TrainingProfile?
  trainingProfileSnapshot; // Foto del perfil al momento de crear el plan

  const TrainingPlanConfig({
    required this.id,
    required this.name,
    required this.clientId,
    required this.startDate,
    required this.phase,
    required this.splitId,
    required this.microcycleLengthInWeeks,
    required this.weeks,
    this.state,
    this.trainingProfileSnapshot,
  });

  // --- SERIALIZACIÓN (Lo que faltaba) ---

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientId': clientId,
      'startDate': startDate.toIso8601String(),
      'phase': phase.name,
      'splitId': splitId,
      'microcycleLengthInWeeks': microcycleLengthInWeeks,
      'weeks': weeks.map((x) => x.toJson()).toList(),
      'state': state,
      'trainingProfileSnapshot': trainingProfileSnapshot?.toJson(),
    };
  }

  factory TrainingPlanConfig.fromMap(Map<String, dynamic> map) {
    return TrainingPlanConfig(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Plan Sin Nombre',
      clientId: map['clientId'] as String? ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      phase: TrainingPhase.values.firstWhere(
        (e) => e.name == map['phase'],
        orElse: () => TrainingPhase.accumulation,
      ),
      splitId: map['splitId'] as String? ?? '',
      microcycleLengthInWeeks: map['microcycleLengthInWeeks'] as int? ?? 4,
      weeks: (map['weeks'] as List<dynamic>? ?? [])
          .map<TrainingWeek>(
            (x) => TrainingWeek.fromJson(x as Map<String, dynamic>),
          )
          .toList(),
      state: map['state'] is Map
          ? Map<String, dynamic>.from(map['state'] as Map)
          : null,
      trainingProfileSnapshot: map['trainingProfileSnapshot'] != null
          ? TrainingProfile.fromJson(
              map['trainingProfileSnapshot'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  // Alias para compatibilidad si alguna parte usa toJson/fromJson
  Map<String, dynamic> toJson() => toMap();
  factory TrainingPlanConfig.fromJson(Map<String, dynamic> json) =>
      TrainingPlanConfig.fromMap(json);

  // --- COPY WITH ---

  TrainingPlanConfig copyWith({
    String? id,
    String? name,
    String? clientId,
    DateTime? startDate,
    TrainingPhase? phase,
    String? splitId,
    int? microcycleLengthInWeeks,
    List<TrainingWeek>? weeks,
    Map<String, dynamic>? state,
    TrainingProfile? trainingProfileSnapshot,
  }) {
    return TrainingPlanConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      clientId: clientId ?? this.clientId,
      startDate: startDate ?? this.startDate,
      phase: phase ?? this.phase,
      splitId: splitId ?? this.splitId,
      microcycleLengthInWeeks:
          microcycleLengthInWeeks ?? this.microcycleLengthInWeeks,
      weeks: weeks ?? this.weeks,
      state: state ?? this.state,
      trainingProfileSnapshot:
          trainingProfileSnapshot ?? this.trainingProfileSnapshot,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    clientId,
    startDate,
    phase,
    splitId,
    microcycleLengthInWeeks,
    weeks,
    state,
    trainingProfileSnapshot,
  ];
}
