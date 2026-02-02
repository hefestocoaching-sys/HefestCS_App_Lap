// lib/domain/training_v3/services/analytics_service.dart

import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/performance_metrics.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/workout_log_processor.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/monitoring_engine.dart';

/// Servicio de análisis y métricas de entrenamiento
///
/// Proporciona:
/// - Análisis de adherencia
/// - Tendencias de rendimiento
/// - Reportes semanales/mensuales
/// - Predicciones
///
/// Versión: 1.0.0
class AnalyticsService {
  /// Genera reporte semanal de entrenamiento
  ///
  /// PARÁMETROS:
  /// - [weekLogs]: Logs de la semana (5-7 sesiones)
  ///
  /// RETORNA:
  /// - Reporte completo con métricas y recomendaciones
  static Map<String, dynamic> generateWeeklyReport({
    required List<WorkoutLog> weekLogs,
  }) {
    if (weekLogs.isEmpty) {
      return {
        'has_data': false,
        'message': 'No hay datos para generar reporte',
      };
    }

    // Calcular métricas agregadas
    final totalSessions = weekLogs.length;
    final completedSessions = weekLogs.where((l) => l.completed).length;
    final avgAdherence =
        weekLogs.fold(0.0, (sum, l) => sum + l.adherencePercentage) /
        totalSessions;
    final avgRpe =
        weekLogs.fold(0.0, (sum, l) => sum + l.sessionRpe) / totalSessions;
    final avgPrs =
        weekLogs.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
        totalSessions;
    final avgDoms =
        weekLogs.fold(0.0, (sum, l) => sum + l.muscleSoreness) / totalSessions;

    // Volumen total
    final totalSets = weekLogs.fold(0, (sum, l) => sum + l.totalSets);

    // Análisis de carga
    final loadAnalysis = MonitoringEngine.analyzeTrainingLoad(
      logs: weekLogs,
      windowWeeks: 1,
    );

    // Determinar estado general
    String weekStatus;
    if (avgAdherence >= 90 && avgRpe <= 8.0 && avgPrs >= 7) {
      weekStatus = 'Excelente';
    } else if (avgAdherence >= 80 && avgRpe <= 8.5 && avgPrs >= 6) {
      weekStatus = 'Bueno';
    } else if (avgAdherence >= 70 && avgRpe <= 9.0 && avgPrs >= 5) {
      weekStatus = 'Aceptable';
    } else {
      weekStatus = 'Necesita atención';
    }

    return {
      'has_data': true,
      'week_status': weekStatus,
      'metrics': {
        'sessions_completed': completedSessions,
        'sessions_planned': totalSessions,
        'avg_adherence': avgAdherence,
        'avg_rpe': avgRpe,
        'avg_prs': avgPrs,
        'avg_doms': avgDoms,
        'total_sets': totalSets,
      },
      'load_analysis': loadAnalysis,
      'summary': _generateWeeklySummary(
        weekStatus,
        avgAdherence,
        avgRpe,
        avgPrs,
      ),
    };
  }

  /// Genera reporte mensual con tendencias
  static Map<String, dynamic> generateMonthlyReport({
    required List<WorkoutLog> monthLogs,
  }) {
    if (monthLogs.length < 8) {
      return {
        'has_data': false,
        'message': 'Insuficientes datos (mínimo 8 sesiones)',
      };
    }

    // Dividir en semanas
    final weeks = _groupByWeek(monthLogs);

    // Calcular tendencias
    final weeklyAverages = weeks.map((weekLogs) {
      return {
        'adherence':
            weekLogs.fold(0.0, (sum, l) => sum + l.adherencePercentage) /
            weekLogs.length,
        'rpe':
            weekLogs.fold(0.0, (sum, l) => sum + l.sessionRpe) /
            weekLogs.length,
        'prs':
            weekLogs.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
            weekLogs.length,
      };
    }).toList();

    // Calcular tendencias
    final adherenceTrend = _calculateTrend(
      weeklyAverages.map((w) => w['adherence'] as double).toList(),
    );
    final rpeTrend = _calculateTrend(
      weeklyAverages.map((w) => w['rpe'] as double).toList(),
    );
    final prsTrend = _calculateTrend(
      weeklyAverages.map((w) => w['prs'] as double).toList(),
    );

    return {
      'has_data': true,
      'period_weeks': weeks.length,
      'total_sessions': monthLogs.length,
      'trends': {'adherence': adherenceTrend, 'rpe': rpeTrend, 'prs': prsTrend},
      'weekly_averages': weeklyAverages,
      'interpretation': _interpretMonthlyTrends(
        adherenceTrend,
        rpeTrend,
        prsTrend,
      ),
    };
  }

  /// Calcula estadísticas de un músculo específico
  static Map<String, dynamic> calculateMuscleStatistics({
    required String muscle,
    required List<WorkoutLog> logs,
  }) {
    // PLACEHOLDER: Implementación completa requiere filtrar por ejercicios del músculo
    return {
      'muscle': muscle,
      'sessions_analyzed': logs.length,
      'message': 'PLACEHOLDER: Implementación completa pendiente',
    };
  }

  /// Agrupa logs por semana
  static List<List<WorkoutLog>> _groupByWeek(List<WorkoutLog> logs) {
    final weeks = <List<WorkoutLog>>[];
    var currentWeek = <WorkoutLog>[];

    for (var i = 0; i < logs.length; i++) {
      currentWeek.add(logs[i]);

      // Nueva semana cada 7 días o cada 5-7 sesiones
      if (currentWeek.length >= 5 ||
          (i < logs.length - 1 &&
              logs[i + 1].startTime
                      .difference(currentWeek.first.startTime)
                      .inDays >
                  7)) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

  /// Calcula tendencia simple
  static double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    final first = values.first;
    final last = values.last;

    if (first == 0) return 0.0;
    return ((last - first) / first).clamp(-1.0, 1.0);
  }

  /// Genera resumen semanal
  static String _generateWeeklySummary(
    String status,
    double adherence,
    double rpe,
    double prs,
  ) {
    if (status == 'Excelente') {
      return '✅ Semana excelente. Adherencia alta (${adherence.toStringAsFixed(1)}%), RPE controlado (${rpe.toStringAsFixed(1)}), recuperación óptima (PRS ${prs.toStringAsFixed(1)}).';
    } else if (status == 'Bueno') {
      return '👍 Buena semana. Continuar con plan actual.';
    } else if (status == 'Aceptable') {
      return '⚠️  Semana aceptable. Monitorear adherencia y recuperación.';
    } else {
      return '🛑 Semana problemática. Revisar factores de fatiga, sueño, estrés.';
    }
  }

  /// Interpreta tendencias mensuales
  static String _interpretMonthlyTrends(
    double adherence,
    double rpe,
    double prs,
  ) {
    final trends = <String>[];

    if (adherence > 0.1) {
      trends.add(
        '📈 Adherencia mejorando (+${(adherence * 100).toStringAsFixed(0)}%)',
      );
    } else if (adherence < -0.1) {
      trends.add(
        '📉 Adherencia decayendo (${(adherence * 100).toStringAsFixed(0)}%)',
      );
    }

    if (rpe > 0.1) {
      trends.add('⚠️  RPE aumentando (señal de fatiga acumulada)');
    } else if (rpe < -0.1) {
      trends.add('✅ RPE disminuyendo (adaptación positiva)');
    }

    if (prs > 0.1) {
      trends.add('✅ PRS mejorando (mejor recuperación)');
    } else if (prs < -0.1) {
      trends.add('⚠️  PRS empeorando (peor recuperación)');
    }

    return trends.isEmpty ? 'Tendencias estables' : trends.join(', ');
  }
}
