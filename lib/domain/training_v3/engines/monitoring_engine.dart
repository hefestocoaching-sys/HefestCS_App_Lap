// lib/domain/training_v3/engines/monitoring_engine.dart

import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';

/// Motor de monitoreo continuo de rendimiento y fatiga
///
/// Analiza logs históricos para detectar:
/// - Acumulación de fatiga
/// - Tendencias de adherencia
/// - Señales de sobreentrenamiento
/// - Necesidad de deload
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Monitoreo científico
/// - Marcadores subjetivos (PRS, RPE, DOMS) son predictores válidos
/// - Detección temprana previene lesiones y burnout
///
/// REFERENCIAS:
/// - Halson (2014): Monitoring training and recovery
/// - Saw et al. (2016): Monitoring athletes
///
/// Versión: 1.0.0
class MonitoringEngine {
  /// Analiza ventana de logs y genera alertas
  ///
  /// PARÁMETROS:
  /// - [logs]: WorkoutLogs de las últimas 2-4 semanas
  /// - [windowWeeks]: Ventana de análisis (default: 2)
  ///
  /// RETORNA:
  /// - Map con estado, alertas y recomendaciones
  static Map<String, dynamic> analyzeTrainingLoad({
    required List<WorkoutLog> logs,
    int windowWeeks = 2,
  }) {
    if (logs.isEmpty) {
      return {
        'status': 'insufficient_data',
        'alerts': [],
        'recommendations': ['Registrar al menos 3 sesiones para análisis'],
      };
    }

    // Calcular métricas promedio
    final avgPrs =
        logs.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
        logs.length;
    final avgRpe = logs.fold(0.0, (sum, l) => sum + l.sessionRpe) / logs.length;
    final avgDoms =
        logs.fold(0.0, (sum, l) => sum + l.muscleSoreness) / logs.length;
    final avgAdherence =
        logs.fold(0.0, (sum, l) => sum + l.adherencePercentage) / logs.length;

    // Detectar tendencias
    final prsTrend = _calculateTrend(
      logs.map((l) => l.perceivedRecoveryStatus).toList(),
    );
    final rpeTrend = _calculateTrend(logs.map((l) => l.sessionRpe).toList());

    // Generar alertas
    final alerts = <String>[];

    // Alerta 1: PRS bajo sostenido
    if (avgPrs < 5) {
      alerts.add(
        '⚠️  PRS promedio bajo (${avgPrs.toStringAsFixed(1)}/10) - Fatiga acumulada',
      );
    }

    // Alerta 2: RPE alto sostenido
    if (avgRpe > 8.5) {
      alerts.add(
        '⚠️  RPE promedio muy alto (${avgRpe.toStringAsFixed(1)}/10) - Carga excesiva',
      );
    }

    // Alerta 3: DOMS alto persistente
    if (avgDoms > 6) {
      alerts.add(
        '⚠️  DOMS alto persistente (${avgDoms.toStringAsFixed(1)}/10) - Recuperación insuficiente',
      );
    }

    // Alerta 4: Adherencia decreciente
    if (avgAdherence < 80 && prsTrend < -0.2) {
      alerts.add(
        '⚠️  Adherencia baja (${avgAdherence.toStringAsFixed(1)}%) + PRS decreciente - Posible sobreentrenamiento',
      );
    }

    // Alerta 5: RPE creciente + PRS decreciente (señal crítica)
    if (rpeTrend > 0.2 && prsTrend < -0.2) {
      alerts.add(
        '🛑 CRÍTICO: RPE↑ + PRS↓ - Fuerte indicador de sobreentrenamiento',
      );
    }

    // Determinar estado
    String status;
    if (alerts.any((a) => a.contains('CRÍTICO'))) {
      status = 'critical';
    } else if (alerts.length >= 3) {
      status = 'warning';
    } else if (alerts.length >= 1) {
      status = 'caution';
    } else {
      status = 'good';
    }

    // Generar recomendaciones
    final recommendations = _generateMonitoringRecommendations(
      status,
      alerts,
      avgPrs,
      avgRpe,
    );

    return {
      'status': status,
      'alerts': alerts,
      'recommendations': recommendations,
      'metrics': {
        'avg_prs': avgPrs,
        'avg_rpe': avgRpe,
        'avg_doms': avgDoms,
        'avg_adherence': avgAdherence,
        'prs_trend': prsTrend,
        'rpe_trend': rpeTrend,
      },
    };
  }

  /// Calcula tendencia simple (primera mitad vs segunda mitad)
  static double _calculateTrend(List<double> values) {
    if (values.length < 4) return 0.0;

    final mid = values.length ~/ 2;
    final firstHalf = values.take(mid).toList();
    final secondHalf = values.skip(mid).toList();

    final avgFirst =
        firstHalf.fold(0.0, (sum, v) => sum + v) / firstHalf.length;
    final avgSecond =
        secondHalf.fold(0.0, (sum, v) => sum + v) / secondHalf.length;

    if (avgFirst == 0) return 0.0;
    return ((avgSecond - avgFirst) / avgFirst).clamp(-1.0, 1.0);
  }

  /// Genera recomendaciones basadas en estado
  static List<String> _generateMonitoringRecommendations(
    String status,
    List<String> alerts,
    double avgPrs,
    double avgRpe,
  ) {
    final recs = <String>[];

    switch (status) {
      case 'critical':
        recs.add('🛑 DELOAD INMEDIATO: Reducir volumen 50% por 1 semana');
        recs.add('Priorizar sueño (8+ horas) y manejo de estrés');
        recs.add('Considerar semana de descanso activo');
        break;

      case 'warning':
        recs.add('⚠️  Reducir volumen 30% próxima semana');
        recs.add('Revisar factores de recuperación (sueño, nutrición, estrés)');
        recs.add('Monitorear PRS diariamente');
        break;

      case 'caution':
        recs.add('⚠️  Reducir volumen 10-15% próxima semana');
        recs.add('Mantener monitoreo cercano');
        break;

      case 'good':
        recs.add('✅ Estado óptimo - Continuar con progresión planeada');
        break;
    }

    return recs;
  }

  /// Calcula índice de estrés de entrenamiento (TSI)
  ///
  /// FÓRMULA: TSI = (10 - PRS) × RPE × (DOMS/10)
  /// - TSI < 20: Bajo estrés
  /// - TSI 20-40: Moderado
  /// - TSI 40-60: Alto
  /// - TSI > 60: Crítico
  static double calculateTrainingStressIndex({
    required double prs,
    required double rpe,
    required double doms,
  }) {
    final tsi = (10 - prs) * rpe * (doms / 10);
    return tsi;
  }

  /// Predice necesidad de deload en N sesiones
  ///
  /// ALGORITMO:
  /// - Extrapola tendencias actuales
  /// - Estima cuándo PRS < 3 o RPE > 9.5
  static Map<String, dynamic> predictDeloadTiming({
    required List<WorkoutLog> logs,
  }) {
    if (logs.length < 4) {
      return {
        'can_predict': false,
        'reason': 'Insuficientes datos (mínimo 4 sesiones)',
      };
    }

    final prsTrend = _calculateTrend(
      logs.map((l) => l.perceivedRecoveryStatus).toList(),
    );
    final rpeTrend = _calculateTrend(logs.map((l) => l.sessionRpe).toList());

    final lastPrs = logs.last.perceivedRecoveryStatus;
    final lastRpe = logs.last.sessionRpe;

    // Extrapolar: cuántas sesiones hasta PRS < 3 o RPE > 9.5
    int sessionsUntilDeload = 999;

    if (prsTrend < -0.1) {
      // PRS decreciendo
      final sessionsTo3 = ((lastPrs - 3) / (prsTrend.abs() * lastPrs)).round();
      if (sessionsTo3 > 0 && sessionsTo3 < sessionsUntilDeload) {
        sessionsUntilDeload = sessionsTo3;
      }
    }

    if (rpeTrend > 0.1) {
      // RPE creciendo
      final sessionsTo95 = ((9.5 - lastRpe) / (rpeTrend * lastRpe)).round();
      if (sessionsTo95 > 0 && sessionsTo95 < sessionsUntilDeload) {
        sessionsUntilDeload = sessionsTo95;
      }
    }

    if (sessionsUntilDeload < 999) {
      String urgency;
      if (sessionsUntilDeload <= 2) {
        urgency = 'immediate';
      } else if (sessionsUntilDeload <= 4) {
        urgency = 'soon';
      } else {
        urgency = 'monitor';
      }

      return {
        'can_predict': true,
        'sessions_until_deload': sessionsUntilDeload,
        'urgency': urgency,
        'recommendation': _getDeloadUrgencyRecommendation(urgency),
      };
    }

    return {
      'can_predict': true,
      'sessions_until_deload': null,
      'urgency': 'none',
      'recommendation': 'Tendencias actuales son sostenibles',
    };
  }

  static String _getDeloadUrgencyRecommendation(String urgency) {
    switch (urgency) {
      case 'immediate':
        return 'Deload recomendado en próxima sesión';
      case 'soon':
        return 'Planificar deload en 3-4 sesiones';
      case 'monitor':
        return 'Continuar monitoreando, deload en ~1-2 semanas';
      default:
        return 'No se requiere deload en corto plazo';
    }
  }
}
