import 'package:equatable/equatable.dart';

/// Modelo de configuración de plan de entrenamiento (Motor V3)
///
/// PROPIEDADES TIPADAS (v2.0.0):
/// - volumePerMuscle: Volumen semanal por músculo (reemplaza extra['volume_targets'])
/// - phase: Fase de periodización
/// - split: Nombre del split
class TrainingPlanConfig extends Equatable {
  final String id;
  final String clientId;
  final DateTime startDate;
  final List<dynamic> weeks; // TrainingWeek
  final DateTime createdAt;

  /// @deprecated Usar volumePerMuscle, phase, split en su lugar
  final Map<String, dynamic> extra;

  // ✨ PROPIEDADES TIPADAS MOTOR V3
  /// Volumen por músculo (sets semanales)
  final Map<String, int>? volumePerMuscle;

  /// Fase de periodización ('accumulation'|'intensification'|'deload')
  final String? phase;

  /// Nombre del split ('fullBody'|'upperLower'|'pushPullLegs')
  final String? split;

  const TrainingPlanConfig({
    required this.id,
    required this.clientId,
    required this.startDate,
    required this.weeks,
    required this.createdAt,
    required this.extra,
    this.volumePerMuscle,
    this.phase,
    this.split,
  });

  @override
  List<Object?> get props => [
    id,
    clientId,
    startDate,
    weeks,
    createdAt,
    extra,
    volumePerMuscle,
    phase,
    split,
  ];
}
