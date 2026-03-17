import 'package:equatable/equatable.dart';

/// Registro detallado del motor de entrenamiento.
/// Útil para trazabilidad, auditoría científica y machine learning.
class EngineAudit extends Equatable {
  final String engineUsed; // ej: "gluteSpecialization"
  final String reason; // explicación humana
  final Map<String, dynamic> details; // información granular del motor

  const EngineAudit({
    required this.engineUsed,
    required this.reason,
    required this.details,
  });

  Map<String, dynamic> toMap() => {
    'engineUsed': engineUsed,
    'reason': reason,
    'details': details,
  };

  factory EngineAudit.fromMap(Map<String, dynamic> map) => EngineAudit(
    engineUsed: map['engineUsed'] ?? 'unknown',
    reason: map['reason'] ?? '',
    details: Map<String, dynamic>.from(map['details'] ?? {}),
  );

  @override
  List<Object?> get props => [engineUsed, reason, details];
}
