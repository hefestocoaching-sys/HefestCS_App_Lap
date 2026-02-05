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

  /// @deprecated Usar volumePerMuscle, weeklyVolumeTarget, landmarks en su lugar
  final Map<String, dynamic>? state;

  final TrainingProfile?
  trainingProfileSnapshot; // Foto del perfil al momento de crear el plan

  // ✨ PROPIEDADES TIPADAS MOTOR V3 (reemplazo de state['phase3'])
  /// Volumen por músculo (reemplaza state['phase3']['targetWeeklySetsByMuscle'])
  final Map<String, int>? volumePerMuscle;

  /// Target de volumen semanal total (opcional)
  final int? weeklyVolumeTarget;

  /// Hitos del plan (semana deload, etc.)
  final Map<String, dynamic>? landmarks;

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
    this.volumePerMuscle,
    this.weeklyVolumeTarget,
    this.landmarks,
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
      'volumePerMuscle': volumePerMuscle,
      'weeklyVolumeTarget': weeklyVolumeTarget,
      'landmarks': landmarks,
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
      volumePerMuscle: map['volumePerMuscle'] != null
          ? Map<String, int>.from(map['volumePerMuscle'])
          : null,
      weeklyVolumeTarget: map['weeklyVolumeTarget'] as int?,
      landmarks: map['landmarks'] != null
          ? Map<String, dynamic>.from(map['landmarks'])
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
    Map<String, int>? volumePerMuscle,
    int? weeklyVolumeTarget,
    Map<String, dynamic>? landmarks,
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
      volumePerMuscle: volumePerMuscle ?? this.volumePerMuscle,
      weeklyVolumeTarget: weeklyVolumeTarget ?? this.weeklyVolumeTarget,
      landmarks: landmarks ?? this.landmarks,
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
    volumePerMuscle,
    weeklyVolumeTarget,
    landmarks,
  ];
}
