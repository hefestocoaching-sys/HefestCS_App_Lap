import 'package:equatable/equatable.dart';

/// Resumen semanal de feedback de entrenamiento.
///
/// Entidad de dominio que representa las señales clínicas agregadas
/// a partir de los logs de entrenamiento reales de una semana.
///
/// Sirve como input para:
/// - Fase 8 (adaptación bidireccional)
/// - Auditoría longitudinal
/// - Decisiones de progresión/deload
///
/// Garantías:
/// - Determinista (sin DateTime.now)
/// - Conservador (progressionAllowed solo ante certeza)
/// - Auditable (reasons y debugContext completos)
class WeeklyTrainingFeedbackSummary extends Equatable {
  /// Identificador del cliente.
  final String clientId;

  /// Inicio de la semana (lunes 00:00:00).
  final DateTime weekStart;

  /// Fin de la semana (domingo 23:59:59).
  final DateTime weekEnd;

  // =========================================================================
  // ADHERENCIA
  // =========================================================================

  /// Total de series planificadas para esta semana.
  final int plannedSetsTotal;

  /// Total de series efectivamente completadas.
  final int completedSetsTotal;

  /// Ratio de adherencia (completedSets / plannedSets).
  /// Rango: [0.0, 1.0]. Si plannedSets == 0, este valor es 0.0.
  final double adherenceRatio;

  // =========================================================================
  // FATIGA / ESFUERZO
  // =========================================================================

  /// RIR promedio reportado, ponderado por sets completados.
  /// Rango esperado: [0.0, 5.0].
  final double avgReportedRIR;

  /// Esfuerzo percibido promedio, ponderado por sets completados.
  /// Rango esperado: [1, 10].
  final double avgEffort;

  /// Cantidad de logs con painFlag == true.
  final int painEvents;

  /// Cantidad de logs con formDegradation == true.
  final int formDegradationEvents;

  /// Cantidad de logs con stoppedEarly == true.
  final int stoppedEarlyEvents;

  // =========================================================================
  // SEÑALES CLÍNICAS (OUTPUT PARA EL MOTOR)
  // =========================================================================

  /// Señal agregada de la semana.
  /// Valores: 'positive' | 'ambiguous' | 'negative'
  ///
  /// - positive: Semana con baja fatiga, alta adherencia, sin dolor.
  /// - negative: Semana con alta fatiga, dolor, o detenciones tempranas.
  /// - ambiguous: Cualquier caso intermedio o con señales mixtas.
  final String signal;

  /// Expectativa de fatiga derivada de los datos.
  /// Valores: 'low' | 'moderate' | 'high'
  ///
  /// Determina si el cliente está en condiciones de progresar.
  final String fatigueExpectation;

  /// Indica si el motor puede autorizar progresión esta semana.
  /// true SOLO si signal == 'positive' y sin banderas de dolor/detención.
  final bool progressionAllowed;

  /// Recomienda deload inmediato.
  /// true si fatigueExpectation == 'high' o adherenceRatio < 0.70.
  final bool deloadRecommended;

  // =========================================================================
  // AUDITORÍA
  // =========================================================================

  /// Razones textuales de las decisiones tomadas.
  /// Ej: ['pain_event_present', 'avg_effort_high', 'adherence_low']
  final List<String> reasons;

  /// Contexto de depuración con valores intermedios.
  /// Incluye: thresholds, logsCount, cálculos intermedios.
  final Map<String, dynamic> debugContext;

  const WeeklyTrainingFeedbackSummary({
    required this.clientId,
    required this.weekStart,
    required this.weekEnd,
    required this.plannedSetsTotal,
    required this.completedSetsTotal,
    required this.adherenceRatio,
    required this.avgReportedRIR,
    required this.avgEffort,
    required this.painEvents,
    required this.formDegradationEvents,
    required this.stoppedEarlyEvents,
    required this.signal,
    required this.fatigueExpectation,
    required this.progressionAllowed,
    required this.deloadRecommended,
    required this.reasons,
    required this.debugContext,
  });

  @override
  List<Object?> get props => [
    clientId,
    weekStart,
    weekEnd,
    plannedSetsTotal,
    completedSetsTotal,
    adherenceRatio,
    avgReportedRIR,
    avgEffort,
    painEvents,
    formDegradationEvents,
    stoppedEarlyEvents,
    signal,
    fatigueExpectation,
    progressionAllowed,
    deloadRecommended,
    reasons,
    debugContext,
  ];

  /// Serializa a JSON para persistencia o auditoría.
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'plannedSetsTotal': plannedSetsTotal,
      'completedSetsTotal': completedSetsTotal,
      'adherenceRatio': adherenceRatio,
      'avgReportedRIR': avgReportedRIR,
      'avgEffort': avgEffort,
      'painEvents': painEvents,
      'formDegradationEvents': formDegradationEvents,
      'stoppedEarlyEvents': stoppedEarlyEvents,
      'signal': signal,
      'fatigueExpectation': fatigueExpectation,
      'progressionAllowed': progressionAllowed,
      'deloadRecommended': deloadRecommended,
      'reasons': reasons,
      'debugContext': debugContext,
    };
  }

  /// Deserializa desde JSON.
  factory WeeklyTrainingFeedbackSummary.fromJson(Map<String, dynamic> json) {
    return WeeklyTrainingFeedbackSummary(
      clientId: json['clientId'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      plannedSetsTotal: json['plannedSetsTotal'] as int,
      completedSetsTotal: json['completedSetsTotal'] as int,
      adherenceRatio: (json['adherenceRatio'] as num).toDouble(),
      avgReportedRIR: (json['avgReportedRIR'] as num).toDouble(),
      avgEffort: (json['avgEffort'] as num).toDouble(),
      painEvents: json['painEvents'] as int,
      formDegradationEvents: json['formDegradationEvents'] as int,
      stoppedEarlyEvents: json['stoppedEarlyEvents'] as int,
      signal: json['signal'] as String,
      fatigueExpectation: json['fatigueExpectation'] as String,
      progressionAllowed: json['progressionAllowed'] as bool,
      deloadRecommended: json['deloadRecommended'] as bool,
      reasons: List<String>.from(json['reasons'] as List),
      debugContext: Map<String, dynamic>.from(json['debugContext'] as Map),
    );
  }
}
