// lib/domain/training_v3/models/performance_metrics.dart

import 'package:equatable/equatable.dart';

/// Métricas de rendimiento agregadas por músculo o ejercicio
///
/// Permite analizar tendencias a lo largo del tiempo:
/// - ¿Está progresando el volumen?
/// - ¿Está aumentando la carga?
/// - ¿Hay fatiga acumulada?
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Monitoreo de progresión
/// - Tendencia positiva = continuar
/// - Tendencia plana = variar estímulo
/// - Tendencia negativa = deload
///
/// Versión: 1.0.0
class PerformanceMetrics extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID del músculo o ejercicio
  final String targetId;

  /// Tipo de objetivo ('muscle' o 'exercise')
  final String targetType;

  /// Periodo de análisis
  final DateTime startDate;
  final DateTime endDate;

  // ════════════════════════════════════════════════════════════
  // MÉTRICAS DE VOLUMEN
  // ════════════════════════════════════════════════════════════

  /// Volumen semanal promedio (sets)
  final double averageWeeklyVolume;

  /// Volumen total del periodo (sets)
  final double totalVolume;

  /// Tendencia de volumen (-1.0 a +1.0)
  /// -1.0 = decreciendo fuerte
  /// 0.0 = estable
  /// +1.0 = creciendo fuerte
  final double volumeTrend;

  // ════════════════════════════════════════════════════════════
  // MÉTRICAS DE INTENSIDAD
  // ════════════════════════════════════════════════════════════

  /// Carga promedio levantada (kg)
  final double averageLoad;

  /// Tendencia de carga (-1.0 a +1.0)
  final double loadTrend;

  /// RPE promedio del periodo
  final double averageRpe;

  /// Tendencia de RPE (-1.0 a +1.0)
  /// Negativo = menos esfuerzo (bueno si carga sube)
  /// Positivo = más esfuerzo (malo si carga no sube)
  final double rpeTrend;

  // ════════════════════════════════════════════════════════════
  // MÉTRICAS DE ADHERENCIA
  // ════════════════════════════════════════════════════════════

  /// Adherencia promedio (0.0-1.0)
  final double averageAdherence;

  /// Sesiones completadas vs planeadas
  final int completedSessions;
  final int plannedSessions;

  // ════════════════════════════════════════════════════════════
  // RECOMENDACIONES
  // ════════════════════════════════════════════════════════════

  /// Estado del rendimiento
  /// 'improving', 'stable', 'declining', 'overreaching'
  final String performanceStatus;

  /// Acción recomendada
  /// 'continue', 'increase_volume', 'increase_load', 'deload', 'vary_stimulus'
  final String recommendedAction;

  const PerformanceMetrics({
    required this.targetId,
    required this.targetType,
    required this.startDate,
    required this.endDate,
    required this.averageWeeklyVolume,
    required this.totalVolume,
    required this.volumeTrend,
    required this.averageLoad,
    required this.loadTrend,
    required this.averageRpe,
    required this.rpeTrend,
    required this.averageAdherence,
    required this.completedSessions,
    required this.plannedSessions,
    required this.performanceStatus,
    required this.recommendedAction,
  });

  /// Validar que las métricas sean coherentes
  bool get isValid {
    // Validar targetType
    if (!['muscle', 'exercise'].contains(targetType)) return false;

    // Validar fechas
    if (endDate.isBefore(startDate)) return false;

    // Validar volumen no negativo
    if (averageWeeklyVolume < 0 || totalVolume < 0) return false;

    // Validar tendencias en rango
    if (volumeTrend < -1.0 || volumeTrend > 1.0) return false;
    if (loadTrend < -1.0 || loadTrend > 1.0) return false;
    if (rpeTrend < -1.0 || rpeTrend > 1.0) return false;

    // Validar RPE razonable
    if (averageRpe < 1 || averageRpe > 10) return false;

    // Validar adherencia 0-1
    if (averageAdherence < 0 || averageAdherence > 1) return false;

    // Validar sesiones
    if (completedSessions < 0 || plannedSessions < 0) return false;
    if (completedSessions > plannedSessions) return false;

    // Validar status
    if (![
      'improving',
      'stable',
      'declining',
      'overreaching',
    ].contains(performanceStatus)) {
      return false;
    }

    // Validar acción
    if (![
      'continue',
      'increase_volume',
      'increase_load',
      'deload',
      'vary_stimulus',
    ].contains(recommendedAction)) {
      return false;
    }

    return true;
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'targetType': targetType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'averageWeeklyVolume': averageWeeklyVolume,
      'totalVolume': totalVolume,
      'volumeTrend': volumeTrend,
      'averageLoad': averageLoad,
      'loadTrend': loadTrend,
      'averageRpe': averageRpe,
      'rpeTrend': rpeTrend,
      'averageAdherence': averageAdherence,
      'completedSessions': completedSessions,
      'plannedSessions': plannedSessions,
      'performanceStatus': performanceStatus,
      'recommendedAction': recommendedAction,
    };
  }

  /// Deserialización desde JSON
  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      averageWeeklyVolume: (json['averageWeeklyVolume'] as num).toDouble(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      volumeTrend: (json['volumeTrend'] as num).toDouble(),
      averageLoad: (json['averageLoad'] as num).toDouble(),
      loadTrend: (json['loadTrend'] as num).toDouble(),
      averageRpe: (json['averageRpe'] as num).toDouble(),
      rpeTrend: (json['rpeTrend'] as num).toDouble(),
      averageAdherence: (json['averageAdherence'] as num).toDouble(),
      completedSessions: json['completedSessions'] as int,
      plannedSessions: json['plannedSessions'] as int,
      performanceStatus: json['performanceStatus'] as String,
      recommendedAction: json['recommendedAction'] as String,
    );
  }

  @override
  List<Object?> get props => [
    targetId,
    targetType,
    startDate,
    endDate,
    averageWeeklyVolume,
    totalVolume,
    volumeTrend,
    averageLoad,
    loadTrend,
    averageRpe,
    rpeTrend,
    averageAdherence,
    completedSessions,
    plannedSessions,
    performanceStatus,
    recommendedAction,
  ];

  @override
  String toString() {
    return 'PerformanceMetrics($targetId: $performanceStatus, trend: ${volumeTrend > 0 ? '+' : ''}${(volumeTrend * 100).toStringAsFixed(0)}%)';
  }
}
