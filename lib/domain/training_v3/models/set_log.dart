// lib/domain/training_v3/models/set_log.dart

import 'package:equatable/equatable.dart';

/// Log de una serie individual
///
/// Representa el nivel más granular de tracking:
/// - Peso levantado
/// - Repeticiones completadas
/// - RPE percibido
/// - RIR estimado
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 4, Imagen 36-43: Relación RIR-RPE
///   * RIR 0 = RPE 10 (fallo)
///   * RIR 1 = RPE 9
///   * RIR 2 = RPE 8
///   * RIR 3 = RPE 7
/// - Autoregulación: Ajustar carga según RPE real
///
/// Versión: 1.0.0
class SetLog extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// Número de la serie (1-based)
  final int setNumber;

  // ════════════════════════════════════════════════════════════
  // EJECUCIÓN
  // ════════════════════════════════════════════════════════════

  /// Peso levantado en kg
  final double weight;

  /// Repeticiones completadas
  final int reps;

  /// RPE (Rate of Perceived Exertion) 1-10
  /// 1-3 = fácil, 4-6 = moderado, 7-8 = duro, 9 = muy duro, 10 = fallo
  final double rpe;

  /// RIR estimado (Reps in Reserve)
  /// Calculado desde RPE: RIR ≈ 10 - RPE
  /// 0 = fallo, 1-2 = cerca del fallo, 3-4 = conservador
  final int estimatedRir;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Timestamp de cuándo se completó la serie
  final DateTime completedAt;

  /// Técnica de intensificación usada (opcional)
  /// Valores: 'drop_set', 'rest_pause', 'cluster', null
  final String? techniqueUsed;

  /// Notas de la serie
  final String? notes;

  const SetLog({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.estimatedRir,
    required this.completedAt,
    this.techniqueUsed,
    this.notes,
  });

  /// Validar que el set sea coherente
  bool get isValid {
    // Validar set number positivo
    if (setNumber < 1) return false;

    // Validar peso no negativo
    if (weight < 0) return false;

    // Validar reps positivas
    if (reps < 1) return false;

    // Validar RPE razonable
    if (rpe < 1 || rpe > 10) return false;

    // Validar RIR razonable
    if (estimatedRir < 0 || estimatedRir > 10) return false;

    // Validar coherencia RPE-RIR
    // Semana 4: RIR ≈ 10 - RPE (±1 de tolerancia)
    final expectedRir = (10 - rpe).round();
    if ((estimatedRir - expectedRir).abs() > 2) return false;

    return true;
  }

  /// Calcular si esta serie llegó a fallo muscular
  bool get wasToFailure => estimatedRir == 0 || rpe >= 10;

  /// Calcular volumen de esta serie (reps × peso)
  double get volume => reps * weight;

  /// Factory: Calcular RIR automáticamente desde RPE
  factory SetLog.fromRpe({
    required int setNumber,
    required double weight,
    required int reps,
    required double rpe,
    required DateTime completedAt,
    String? techniqueUsed,
    String? notes,
  }) {
    final estimatedRir = (10 - rpe).round().clamp(0, 10);

    return SetLog(
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      rpe: rpe,
      estimatedRir: estimatedRir,
      completedAt: completedAt,
      techniqueUsed: techniqueUsed,
      notes: notes,
    );
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'estimatedRir': estimatedRir,
      'completedAt': completedAt.toIso8601String(),
      'techniqueUsed': techniqueUsed,
      'notes': notes,
    };
  }

  /// Deserialización desde JSON
  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      rpe: (json['rpe'] as num).toDouble(),
      estimatedRir: json['estimatedRir'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      techniqueUsed: json['techniqueUsed'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// CopyWith para actualizaciones inmutables
  SetLog copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    int? estimatedRir,
    DateTime? completedAt,
    String? techniqueUsed,
    String? notes,
  }) {
    return SetLog(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      estimatedRir: estimatedRir ?? this.estimatedRir,
      completedAt: completedAt ?? this.completedAt,
      techniqueUsed: techniqueUsed ?? this.techniqueUsed,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    setNumber,
    weight,
    reps,
    rpe,
    estimatedRir,
    completedAt,
    techniqueUsed,
    notes,
  ];

  @override
  String toString() {
    return 'SetLog(#$setNumber: ${weight}kg × ${reps}r @RPE${rpe.toStringAsFixed(1)})';
  }
}
