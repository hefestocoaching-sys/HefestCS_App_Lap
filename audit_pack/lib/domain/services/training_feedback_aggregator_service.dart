import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';

/// Servicio de agregación de feedback de entrenamiento.
///
/// Convierte logs de sesiones individuales (TrainingSessionLogV2) en
/// un resumen semanal con señales clínicas agregadas.
///
/// Garantías:
/// - Determinista (sin DateTime.now ni random)
/// - Conservador (progressionAllowed solo ante certeza)
/// - Auditable (reasons y debugContext completos)
/// - Sin efectos secundarios (stateless)
class TrainingFeedbackAggregatorService {
  /// Genera un resumen semanal a partir de logs de entrenamiento.
  ///
  /// Parámetros:
  /// - [clientId]: ID del cliente (para validación y coherencia)
  /// - [referenceDate]: Fecha dentro de la semana a analizar
  /// - [logs]: Lista de logs de sesiones (TrainingSessionLogV2)
  /// - [plannedSetsThisWeek]: Series planificadas según el plan (opcional)
  ///
  /// Si [plannedSetsThisWeek] no se provee o es 0, se calcula como
  /// la suma de plannedSets de los logs dentro de la semana.
  ///
  /// Retorna un [WeeklyTrainingFeedbackSummary] con señales agregadas.
  WeeklyTrainingFeedbackSummary summarizeWeek({
    required String clientId,
    required DateTime referenceDate,
    required List<TrainingSessionLogV2> logs,
    int plannedSetsThisWeek = 0,
  }) {
    // 1. Segmentación de semana
    final weekStart = _weekStartFrom(referenceDate);
    final weekEnd = _weekEndFrom(weekStart);

    // 2. Filtrar logs de esta semana y cliente
    final weekLogs = logs.where((log) {
      if (log.clientId != clientId) return false;
      final sessionDate = log.sessionDate;
      // Incluir si está en el rango [weekStart, weekEnd]
      return !sessionDate.isBefore(weekStart) && !sessionDate.isAfter(weekEnd);
    }).toList();

    // 3. Inicializar contadores y acumuladores
    final List<String> reasons = [];
    final Map<String, dynamic> debugContext = {};

    int logsCount = weekLogs.length;
    int completedSetsTotal = 0;
    double weightedRIRSum = 0.0;
    double weightedEffortSum = 0.0;
    int painEvents = 0;
    int formDegradationEvents = 0;
    int stoppedEarlyEvents = 0;
    int plannedSetsFromLogs = 0;

    // 4. Procesar cada log
    for (final log in weekLogs) {
      final completed = log.completedSets;
      completedSetsTotal += completed;
      plannedSetsFromLogs += log.plannedSets;

      // Promedios ponderados por sets completados
      weightedRIRSum += log.avgReportedRIR * completed;
      weightedEffortSum += log.perceivedEffort * completed;

      // Conteo de eventos
      if (log.painFlag) painEvents++;
      if (log.formDegradation) formDegradationEvents++;
      if (log.stoppedEarly) stoppedEarlyEvents++;
    }

    // 5. Determinar plannedSetsTotal
    final int plannedSetsTotal = plannedSetsThisWeek > 0
        ? plannedSetsThisWeek
        : plannedSetsFromLogs;

    // 6. Calcular adherencia (clamped 0..1)
    final double adherenceRatio = plannedSetsTotal > 0
        ? (completedSetsTotal / plannedSetsTotal).clamp(0.0, 1.0)
        : 0.0;

    if (plannedSetsTotal == 0) {
      reasons.add('planned_sets_zero');
    }

    // 7. Calcular promedios ponderados
    final double avgReportedRIR = completedSetsTotal > 0
        ? weightedRIRSum / completedSetsTotal
        : 0.0;

    final double avgEffort = completedSetsTotal > 0
        ? weightedEffortSum / completedSetsTotal
        : 0.0;

    // 8. Determinar fatigueExpectation (conservador)
    String fatigueExpectation = 'low';

    // HIGH si hay señales críticas
    if (painEvents > 0) {
      fatigueExpectation = 'high';
      reasons.add('pain_event_present');
    } else if (stoppedEarlyEvents > 0) {
      fatigueExpectation = 'high';
      reasons.add('stopped_early_event_present');
    } else if (avgEffort >= 8.5) {
      fatigueExpectation = 'high';
      reasons.add('avg_effort_high');
    } else if (avgReportedRIR <= 1.0 && completedSetsTotal > 0) {
      fatigueExpectation = 'high';
      reasons.add('avg_rir_very_low');
    } else if (adherenceRatio < 0.70) {
      fatigueExpectation = 'high';
      reasons.add('adherence_very_low');
    }
    // MODERATE si hay señales intermedias
    else if (avgEffort >= 7.0 && avgEffort < 8.5) {
      fatigueExpectation = 'moderate';
      reasons.add('avg_effort_moderate');
    } else if (avgReportedRIR > 1.0 &&
        avgReportedRIR <= 1.75 &&
        completedSetsTotal > 0) {
      fatigueExpectation = 'moderate';
      reasons.add('avg_rir_moderate');
    } else if (adherenceRatio >= 0.70 && adherenceRatio < 0.85) {
      fatigueExpectation = 'moderate';
      reasons.add('adherence_moderate');
    } else if (formDegradationEvents > 0) {
      fatigueExpectation = 'moderate';
      reasons.add('form_degradation_present');
    }
    // LOW en caso contrario
    else {
      reasons.add('low_fatigue_indicators');
    }

    // 9. Determinar signal (positive/ambiguous/negative)
    String signal;
    if (fatigueExpectation == 'high') {
      signal = 'negative';
      reasons.add('signal_negative_high_fatigue');
    } else if (fatigueExpectation == 'low' &&
        adherenceRatio >= 0.85 &&
        painEvents == 0 &&
        stoppedEarlyEvents == 0) {
      signal = 'positive';
      reasons.add('signal_positive_conditions_met');
    } else {
      signal = 'ambiguous';
      reasons.add('signal_ambiguous_mixed_indicators');
    }

    // 10. Determinar progressionAllowed (muy conservador)
    bool progressionAllowed = false;
    if (signal == 'positive' && painEvents == 0 && stoppedEarlyEvents == 0) {
      progressionAllowed = true;
      reasons.add('progression_allowed');
    } else {
      reasons.add('progression_not_allowed');
    }

    // 11. Determinar deloadRecommended
    bool deloadRecommended = false;
    if (fatigueExpectation == 'high') {
      deloadRecommended = true;
      reasons.add('deload_recommended_high_fatigue');
    } else if (adherenceRatio < 0.70 && plannedSetsTotal > 0) {
      deloadRecommended = true;
      reasons.add('deload_recommended_low_adherence');
    }

    // 12. Construir debugContext
    debugContext['weekStart'] = weekStart.toIso8601String();
    debugContext['weekEnd'] = weekEnd.toIso8601String();
    debugContext['logsCount'] = logsCount;
    debugContext['plannedSetsTotal'] = plannedSetsTotal;
    debugContext['completedSetsTotal'] = completedSetsTotal;
    debugContext['adherenceRatio'] = adherenceRatio;
    debugContext['avgEffort'] = avgEffort;
    debugContext['avgReportedRIR'] = avgReportedRIR;
    debugContext['painEvents'] = painEvents;
    debugContext['stoppedEarlyEvents'] = stoppedEarlyEvents;
    debugContext['formDegradationEvents'] = formDegradationEvents;
    debugContext['thresholds'] = {
      'adherence_high': 0.85,
      'adherence_moderate': 0.70,
      'effort_high': 8.5,
      'effort_moderate': 7.0,
      'rir_low': 1.0,
      'rir_moderate': 1.75,
    };

    // 13. Construir y retornar resumen
    return WeeklyTrainingFeedbackSummary(
      clientId: clientId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      plannedSetsTotal: plannedSetsTotal,
      completedSetsTotal: completedSetsTotal,
      adherenceRatio: adherenceRatio,
      avgReportedRIR: avgReportedRIR,
      avgEffort: avgEffort,
      painEvents: painEvents,
      formDegradationEvents: formDegradationEvents,
      stoppedEarlyEvents: stoppedEarlyEvents,
      signal: signal,
      fatigueExpectation: fatigueExpectation,
      progressionAllowed: progressionAllowed,
      deloadRecommended: deloadRecommended,
      reasons: reasons,
      debugContext: debugContext,
    );
  }

  /// Calcula el inicio de la semana (lunes 00:00:00) para una fecha dada.
  ///
  /// Usa ISO 8601: lunes = día 1, domingo = día 7.
  DateTime _weekStartFrom(DateTime date) {
    final dayOfWeek = date.weekday; // 1=lunes, 7=domingo
    final daysToSubtract = dayOfWeek - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  /// Calcula el fin de la semana (domingo 23:59:59.999) para un weekStart dado.
  DateTime _weekEndFrom(DateTime weekStart) {
    return weekStart
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));
  }
}
