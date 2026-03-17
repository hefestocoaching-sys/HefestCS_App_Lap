/// Agregador de bitácoras de entrenamiento para métricas de adherencia y fatiga
///
/// Propósito:
/// - Analizar logs de las últimas 2 semanas
/// - Calcular adherencia (sesiones completadas vs planificadas)
/// - Detectar señales de fatiga excesiva (painFlag, stoppedEarly, RIR, esfuerzo)
/// - Proporcionar input para ajustes de volumen/intensidad en generación de plan
library;

import 'package:hcs_app_lap/domain/entities/training_session_log.dart';

/// Resultado del análisis de logs de entrenamiento
class TrainingLogAnalysis {
  const TrainingLogAnalysis({
    required this.adherenceRate,
    required this.fatigueFlag,
    required this.painFlag,
    required this.avgReportedRIR,
    required this.avgPerceivedEffort,
    required this.totalLoggedSessions,
    required this.totalStoppedEarlySessions,
    required this.totalPainSessions,
  });

  /// Tasa de adherencia (0.0-1.0): completedSets / plannedSets en promedio
  ///
  /// - >= 0.85: Adherencia excelente, cliente ejecuta plan consistentemente
  /// - 0.70-0.84: Adherencia moderada, puede requerir ajuste de volumen
  /// - < 0.70: Adherencia baja, volumen puede ser excesivo o hay factores externos
  final double adherenceRate;

  /// Bandera de fatiga elevada
  ///
  /// true si se cumple alguna condición:
  /// - avgReportedRIR < 1.0 (RIR muy bajo, cerca del fallo)
  /// - avgPerceivedEffort > 8.0 (esfuerzo percibido muy alto)
  /// - totalStoppedEarlySessions >= 2 (múltiples sesiones interrumpidas)
  final bool fatigueFlag;

  /// Bandera de dolor reportado
  ///
  /// true si alguna sesión registró painFlag=true
  /// SEÑAL CRÍTICA: debe reducir volumen y evitar ejercicios problemáticos
  final bool painFlag;

  /// RIR promedio reportado (ponderado por completedSets)
  ///
  /// - < 1.0: Muy cerca del fallo, fatiga elevada
  /// - 1.0-2.0: RIR ideal para hipertrofia
  /// - > 3.0: RIR conservador, margen para aumentar intensidad
  final double avgReportedRIR;

  /// Esfuerzo percibido promedio (ponderado por completedSets)
  ///
  /// - <= 6: Esfuerzo bajo/moderado
  /// - 7-8: Esfuerzo moderado-alto (rango ideal)
  /// - > 8: Esfuerzo muy alto, posible fatiga
  final double avgPerceivedEffort;

  /// Total de sesiones registradas en ventana de análisis
  final int totalLoggedSessions;

  /// Total de sesiones detenidas anticipadamente
  final int totalStoppedEarlySessions;

  /// Total de sesiones con dolor reportado
  final int totalPainSessions;

  /// Análisis vacío cuando no hay logs
  static const empty = TrainingLogAnalysis(
    adherenceRate: 0.0,
    fatigueFlag: false,
    painFlag: false,
    avgReportedRIR: 2.0,
    avgPerceivedEffort: 7.0,
    totalLoggedSessions: 0,
    totalStoppedEarlySessions: 0,
    totalPainSessions: 0,
  );

  @override
  String toString() {
    return 'TrainingLogAnalysis('
        'adherence: ${(adherenceRate * 100).toStringAsFixed(1)}%, '
        'fatigueFlag: $fatigueFlag, '
        'painFlag: $painFlag, '
        'avgRIR: ${avgReportedRIR.toStringAsFixed(1)}, '
        'avgEffort: ${avgPerceivedEffort.toStringAsFixed(1)}, '
        'sessions: $totalLoggedSessions'
        ')';
  }
}

/// Servicio agregador de logs de entrenamiento
class TrainingLogAggregator {
  const TrainingLogAggregator();

  /// Analiza logs de las últimas 2 semanas
  ///
  /// - [logs]: Lista completa de logs del cliente (se filtrará por fecha)
  /// - [clientId]: ID del cliente para filtrar multi-tenant
  ///
  /// Devuelve [TrainingLogAnalysis] con métricas agregadas
  /// Si no hay logs en ventana, devuelve análisis vacío
  TrainingLogAnalysis analyzeLast2Weeks({
    required List<TrainingSessionLogV2> logs,
    required String clientId,
  }) {
    // Filtrar logs del cliente específico
    final clientLogs = logs.where((log) => log.clientId == clientId).toList();

    if (clientLogs.isEmpty) {
      return TrainingLogAnalysis.empty;
    }

    // Calcular fecha de corte (hace 2 semanas desde hoy)
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    // Filtrar logs de últimas 2 semanas
    final recentLogs = clientLogs
        .where((log) => log.sessionDate.isAfter(twoWeeksAgo))
        .toList();

    if (recentLogs.isEmpty) {
      return TrainingLogAnalysis.empty;
    }

    // Calcular adherencia: suma ponderada de completedSets/plannedSets
    double totalAdherenceWeight = 0.0;
    double adherenceSum = 0.0;

    for (final log in recentLogs) {
      if (log.plannedSets > 0) {
        final sessionAdherence = log.completedSets / log.plannedSets;
        adherenceSum += sessionAdherence;
        totalAdherenceWeight += 1.0;
      }
    }

    final adherenceRate = totalAdherenceWeight > 0
        ? adherenceSum / totalAdherenceWeight
        : 0.0;

    // Calcular RIR promedio ponderado por completedSets
    double totalSets = 0.0;
    double rirSum = 0.0;

    for (final log in recentLogs) {
      if (log.completedSets > 0) {
        rirSum += log.avgReportedRIR * log.completedSets;
        totalSets += log.completedSets;
      }
    }

    final avgRIR = totalSets > 0 ? rirSum / totalSets : 2.0;

    // Calcular esfuerzo percibido promedio ponderado por completedSets
    double effortSum = 0.0;

    for (final log in recentLogs) {
      if (log.completedSets > 0) {
        effortSum += log.perceivedEffort * log.completedSets;
      }
    }

    final avgEffort = totalSets > 0 ? effortSum / totalSets : 7.0;

    // Contar sesiones con señales de alarma
    int stoppedEarlyCount = 0;
    int painCount = 0;
    bool anyPain = false;

    for (final log in recentLogs) {
      if (log.stoppedEarly) {
        stoppedEarlyCount++;
      }
      if (log.painFlag) {
        painCount++;
        anyPain = true;
      }
    }

    // Determinar bandera de fatiga
    // Condiciones: RIR < 1.0 OR esfuerzo > 8.0 OR >= 2 sesiones detenidas
    final fatigueFlag =
        avgRIR < 1.0 || avgEffort > 8.0 || stoppedEarlyCount >= 2;

    return TrainingLogAnalysis(
      adherenceRate: adherenceRate.clamp(0.0, 1.0),
      fatigueFlag: fatigueFlag,
      painFlag: anyPain,
      avgReportedRIR: avgRIR,
      avgPerceivedEffort: avgEffort,
      totalLoggedSessions: recentLogs.length,
      totalStoppedEarlySessions: stoppedEarlyCount,
      totalPainSessions: painCount,
    );
  }

  /// Analiza logs de un período personalizado
  ///
  /// - [logs]: Lista completa de logs
  /// - [clientId]: ID del cliente
  /// - [startDate]: Fecha de inicio del período
  /// - [endDate]: Fecha de fin del período
  TrainingLogAnalysis analyzeCustomPeriod({
    required List<TrainingSessionLogV2> logs,
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final clientLogs = logs.where((log) => log.clientId == clientId).toList();

    if (clientLogs.isEmpty) {
      return TrainingLogAnalysis.empty;
    }

    final periodLogs = clientLogs
        .where(
          (log) =>
              log.sessionDate.isAfter(startDate) &&
              log.sessionDate.isBefore(endDate),
        )
        .toList();

    if (periodLogs.isEmpty) {
      return TrainingLogAnalysis.empty;
    }

    // Reutilizar lógica de cálculo (mismo algoritmo que last2Weeks)
    double totalAdherenceWeight = 0.0;
    double adherenceSum = 0.0;
    double totalSets = 0.0;
    double rirSum = 0.0;
    double effortSum = 0.0;
    int stoppedEarlyCount = 0;
    int painCount = 0;
    bool anyPain = false;

    for (final log in periodLogs) {
      if (log.plannedSets > 0) {
        adherenceSum += log.completedSets / log.plannedSets;
        totalAdherenceWeight += 1.0;
      }

      if (log.completedSets > 0) {
        rirSum += log.avgReportedRIR * log.completedSets;
        effortSum += log.perceivedEffort * log.completedSets;
        totalSets += log.completedSets;
      }

      if (log.stoppedEarly) stoppedEarlyCount++;
      if (log.painFlag) {
        painCount++;
        anyPain = true;
      }
    }

    final adherenceRate = totalAdherenceWeight > 0
        ? adherenceSum / totalAdherenceWeight
        : 0.0;
    final avgRIR = totalSets > 0 ? rirSum / totalSets : 2.0;
    final avgEffort = totalSets > 0 ? effortSum / totalSets : 7.0;
    final fatigueFlag =
        avgRIR < 1.0 || avgEffort > 8.0 || stoppedEarlyCount >= 2;

    return TrainingLogAnalysis(
      adherenceRate: adherenceRate.clamp(0.0, 1.0),
      fatigueFlag: fatigueFlag,
      painFlag: anyPain,
      avgReportedRIR: avgRIR,
      avgPerceivedEffort: avgEffort,
      totalLoggedSessions: periodLogs.length,
      totalStoppedEarlySessions: stoppedEarlyCount,
      totalPainSessions: painCount,
    );
  }

  /// Helper: Obtiene el primer log registrado del cliente
  ///
  /// Útil para saber si hay historial de entrenamientos
  /// y ajustar recomendaciones iniciales
  TrainingSessionLogV2? getFirstLog({
    required List<TrainingSessionLogV2> logs,
    required String clientId,
  }) {
    final clientLogs = logs.where((log) => log.clientId == clientId).toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    return clientLogs.isEmpty ? null : clientLogs.first;
  }

  /// Helper: Obtiene el último log registrado del cliente
  ///
  /// Útil para decidir si ajustar plan basado en última sesión
  TrainingSessionLogV2? getLatestLog({
    required List<TrainingSessionLogV2> logs,
    required String clientId,
  }) {
    final clientLogs = logs.where((log) => log.clientId == clientId).toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return clientLogs.isEmpty ? null : clientLogs.first;
  }
}
