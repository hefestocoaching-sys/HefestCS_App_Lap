import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_shared_types.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_meta.dart';

/// Entidad persistida de plan de entrenamiento
///
/// ARQUITECTURA:
/// - Genera: Motor V3 (MotorV3Orchestrator)
/// - Persiste: Firestore (JSON serializable)
/// - Usa: UI (Widgets, Providers)
///
/// PROPIEDADES V3 (reemplazo de state['phase3']):
/// - volumePerMuscle: Volumen semanal por músculo (Map&lt;String, int&gt;)
/// - weeklyVolumeTarget: Target de volumen total
/// - landmarks: Hitos del plan (semana deload, etc.)
///
/// PROPIEDADES DEPRECATED:
/// - state: Mapa genérico legacy (NO generar nuevos)
///
/// NOTA: Esta entidad V2 es la SSOT (Single Source of Truth) para UI.
/// NO existe duplicado para Motor V3. Todos usan esta clase.
class TrainingPlanConfig extends Equatable
    implements TrainingProfileSnapshotSource {
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

  /// Estado longitudinal del ciclo Motor V3
  final TrainingPlanMeta? meta;

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
    this.meta,
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
      'meta': meta?.toMap(),
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
      meta: map['meta'] != null
          ? TrainingPlanMeta.fromMap(
              Map<String, dynamic>.from(map['meta'] as Map),
            )
          : null,
    );
  }

  // Alias para compatibilidad si alguna parte usa toJson/fromJson
  Map<String, dynamic> toJson() => toMap();
  factory TrainingPlanConfig.fromJson(Map<String, dynamic> json) =>
      TrainingPlanConfig.fromMap(json);

  @override
  Map<String, dynamic>? get trainingProfileSnapshotExtra =>
      trainingProfileSnapshot?.extra;

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
    TrainingPlanMeta? meta,
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
      meta: meta ?? this.meta,
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
    meta,
  ];
}
