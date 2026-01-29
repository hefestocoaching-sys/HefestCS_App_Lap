// lib/domain/entities/training_history.dart
import 'package:equatable/equatable.dart';

/// Historial agregado de entrenamiento para un cliente.
/// No guarda cada sesión suelta, sino métricas resumidas y
/// datos clave para analítica y machine learning.
class TrainingHistory extends Equatable {
  /// Primera sesión registrada.
  final DateTime? firstSessionDate;

  /// Última sesión registrada.
  final DateTime? lastSessionDate;

  /// Número total de sesiones registradas.
  final int totalSessions;

  /// Sesiones completadas (no canceladas).
  final int completedSessions;

  /// Sesiones canceladas/no realizadas.
  final int cancelledSessions;

  /// Adherencia promedio (0–1) sobre el periodo evaluado.
  final double averageAdherence;

  /// Sesiones promedio por semana (en la ventana histórica).
  final double averageWeeklySessions;

  /// RPE promedio reportado (1–10 aprox).
  final double averageRpe;

  /// Fatiga percibida promedio (1–10).
  final double averageFatigue;

  /// Resumen de mejores marcas (1RM u otro criterio) por ejercicio clave.
  /// Ejemplo: { "squat": 180.0, "bench": 120.0, "deadlift": 210.0 }
  final Map<String, double> bestLifts;

  /// Volumen efectivo agregado por mesociclo o bloque.
  /// Ejemplo: { "block_1": 320.0, "block_2": 410.0 } (total series o eVL).
  final Map<String, double> volumeByBlock;

  /// Flag simple para saber si existe historial “real”.
  bool get hasData => totalSessions > 0;

  const TrainingHistory({
    this.firstSessionDate,
    this.lastSessionDate,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.cancelledSessions = 0,
    this.averageAdherence = 0.0,
    this.averageWeeklySessions = 0.0,
    this.averageRpe = 0.0,
    this.averageFatigue = 0.0,
    this.bestLifts = const {},
    this.volumeByBlock = const {},
  });

  /// Historial vacío para clientes nuevos o sin datos.
  factory TrainingHistory.empty() => const TrainingHistory();

  TrainingHistory copyWith({
    DateTime? firstSessionDate,
    DateTime? lastSessionDate,
    int? totalSessions,
    int? completedSessions,
    int? cancelledSessions,
    double? averageAdherence,
    double? averageWeeklySessions,
    double? averageRpe,
    double? averageFatigue,
    Map<String, double>? bestLifts,
    Map<String, double>? volumeByBlock,
  }) {
    return TrainingHistory(
      firstSessionDate: firstSessionDate ?? this.firstSessionDate,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      cancelledSessions: cancelledSessions ?? this.cancelledSessions,
      averageAdherence: averageAdherence ?? this.averageAdherence,
      averageWeeklySessions:
          averageWeeklySessions ?? this.averageWeeklySessions,
      averageRpe: averageRpe ?? this.averageRpe,
      averageFatigue: averageFatigue ?? this.averageFatigue,
      bestLifts: bestLifts ?? this.bestLifts,
      volumeByBlock: volumeByBlock ?? this.volumeByBlock,
    );
  }

  factory TrainingHistory.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TrainingHistory.empty();

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, double> parseDoubleMap(dynamic raw) {
      if (raw is Map) {
        return raw.map<String, double>((key, value) {
          final k = key.toString();
          final v = (value is num) ? value.toDouble() : 0.0;
          return MapEntry(k, v);
        });
      }
      return {};
    }

    return TrainingHistory(
      firstSessionDate: parseDate(json['firstSessionDate']),
      lastSessionDate: parseDate(json['lastSessionDate']),
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      completedSessions: (json['completedSessions'] as num?)?.toInt() ?? 0,
      cancelledSessions: (json['cancelledSessions'] as num?)?.toInt() ?? 0,
      averageAdherence: (json['averageAdherence'] as num?)?.toDouble() ?? 0.0,
      averageWeeklySessions:
          (json['averageWeeklySessions'] as num?)?.toDouble() ?? 0.0,
      averageRpe: (json['averageRpe'] as num?)?.toDouble() ?? 0.0,
      averageFatigue: (json['averageFatigue'] as num?)?.toDouble() ?? 0.0,
      bestLifts: parseDoubleMap(json['bestLifts']),
      volumeByBlock: parseDoubleMap(json['volumeByBlock']),
    );
  }

  Map<String, dynamic> toJson() {
    String? dateToString(DateTime? d) => d?.toIso8601String();

    return {
      'firstSessionDate': dateToString(firstSessionDate),
      'lastSessionDate': dateToString(lastSessionDate),
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'cancelledSessions': cancelledSessions,
      'averageAdherence': averageAdherence,
      'averageWeeklySessions': averageWeeklySessions,
      'averageRpe': averageRpe,
      'averageFatigue': averageFatigue,
      'bestLifts': bestLifts,
      'volumeByBlock': volumeByBlock,
    };
  }

  @override
  List<Object?> get props => [
    firstSessionDate,
    lastSessionDate,
    totalSessions,
    completedSessions,
    cancelledSessions,
    averageAdherence,
    averageWeeklySessions,
    averageRpe,
    averageFatigue,
    bestLifts,
    volumeByBlock,
  ];
}
