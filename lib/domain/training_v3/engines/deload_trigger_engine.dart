// lib/domain/training_v3/engines/deload_trigger_engine.dart

import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';

/// Motor de detección automática de necesidad de deload
///
/// Evalúa múltiples marcadores para determinar si se requiere deload:
/// - Marcadores subjetivos: PRS, RPE, DOMS
/// - Marcadores objetivos: Adherencia, volumen completado
/// - Tendencias temporales: Deterioro progresivo
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Triggers de deload
/// - Deload preventivo > Deload reactivo
/// - Periodización ondulante (wave loading)
///
/// REFERENCIAS:
/// - Israetel et al. (2020): Deload timing and implementation
/// - Pritchard et al. (2015): Deload effectiveness
///
/// Versión: 1.0.0
class DeloadTriggerEngine {
  /// Evalúa si se requiere deload basado en logs recientes
  ///
  /// ALGORITMO:
  /// 1. Evaluar marcadores individuales (8 criterios)
  /// 2. Asignar score a cada criterio (0-10)
  /// 3. Calcular score total ponderado
  /// 4. Determinar urgencia y tipo de deload
  ///
  /// PARÁMETROS:
  /// - [recentLogs]: WorkoutLogs de última 1-2 semanas
  /// - [weeksInProgram]: Semanas consecutivas entrenando sin deload
  ///
  /// RETORNA:
  /// - Map con decisión, urgencia, tipo de deload y protocolo
  static Map<String, dynamic> evaluateDeloadNeed({
    required List<WorkoutLog> recentLogs,
    required int weeksInProgram,
  }) {
    if (recentLogs.isEmpty) {
      throw ArgumentError('Se requiere al menos 1 log');
    }

    // PASO 1: Evaluar 8 criterios
    final criteria = _evaluateCriteria(recentLogs, weeksInProgram);

    // PASO 2: Calcular score total (0-100)
    final totalScore = _calculateTotalScore(criteria);

    // PASO 3: Determinar decisión
    final decision = _makeDeloadDecision(totalScore);

    // PASO 4: Determinar protocolo de deload
    final protocol = _generateDeloadProtocol(decision, criteria);

    return {
      'needs_deload': decision['needs_deload'],
      'urgency': decision['urgency'],
      'total_score': totalScore,
      'criteria_breakdown': criteria,
      'protocol': protocol,
      'reasoning': decision['reasoning'],
    };
  }

  /// Evalúa 8 criterios de deload (cada uno 0-10)
  ///
  /// CRITERIOS:
  /// 1. PRS promedio (10 = muy bajo)
  /// 2. RPE promedio (10 = muy alto)
  /// 3. DOMS promedio (10 = muy alto)
  /// 4. Adherencia (10 = muy baja)
  /// 5. Tendencia PRS (10 = decreciendo rápido)
  /// 6. Tendencia RPE (10 = creciendo rápido)
  /// 7. Señales de fatiga alta (10 = múltiples señales)
  /// 8. Semanas sin deload (10 = >6 semanas)
  static Map<String, double> _evaluateCriteria(
    List<WorkoutLog> logs,
    int weeksInProgram,
  ) {
    // Criterio 1: PRS promedio
    final avgPrs =
        logs.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
        logs.length;
    final prsScore = _scorePrs(avgPrs);

    // Criterio 2: RPE promedio
    final avgRpe = logs.fold(0.0, (sum, l) => sum + l.sessionRpe) / logs.length;
    final rpeScore = _scoreRpe(avgRpe);

    // Criterio 3: DOMS promedio
    final avgDoms =
        logs.fold(0.0, (sum, l) => sum + l.muscleSoreness) / logs.length;
    final domsScore = _scoreDoms(avgDoms);

    // Criterio 4: Adherencia promedio
    final avgAdherence =
        logs.fold(0.0, (sum, l) => sum + l.adherencePercentage) / logs.length;
    final adherenceScore = _scoreAdherence(avgAdherence);

    // Criterio 5: Tendencia PRS
    final prsTrend = _calculateTrend(
      logs.map((l) => l.perceivedRecoveryStatus).toList(),
    );
    final prsTrendScore = _scorePrsTrend(prsTrend);

    // Criterio 6: Tendencia RPE
    final rpeTrend = _calculateTrend(logs.map((l) => l.sessionRpe).toList());
    final rpeTrendScore = _scoreRpeTrend(rpeTrend);

    // Criterio 7: Señales de fatiga
    final fatigueSignals = logs.where((l) => l.showsFatigueSignals).length;
    final fatigueScore = _scoreFatigueSignals(fatigueSignals, logs.length);

    // Criterio 8: Semanas sin deload
    final weeksScore = _scoreWeeksWithoutDeload(weeksInProgram);

    return {
      'prs_avg': prsScore,
      'rpe_avg': rpeScore,
      'doms_avg': domsScore,
      'adherence': adherenceScore,
      'prs_trend': prsTrendScore,
      'rpe_trend': rpeTrendScore,
      'fatigue_signals': fatigueScore,
      'weeks_without_deload': weeksScore,
    };
  }

  // Funciones de scoring (0-10)

  static double _scorePrs(double prs) {
    // PRS < 3 = score 10, PRS > 7 = score 0
    if (prs <= 3) return 10.0;
    if (prs >= 7) return 0.0;
    return (7 - prs) / 4 * 10;
  }

  static double _scoreRpe(double rpe) {
    // RPE > 9 = score 10, RPE < 7 = score 0
    if (rpe >= 9) return 10.0;
    if (rpe <= 7) return 0.0;
    return (rpe - 7) / 2 * 10;
  }

  static double _scoreDoms(double doms) {
    // DOMS > 7 = score 10, DOMS < 4 = score 0
    if (doms >= 7) return 10.0;
    if (doms <= 4) return 0.0;
    return (doms - 4) / 3 * 10;
  }

  static double _scoreAdherence(double adherence) {
    // Adherencia < 70% = score 10, > 90% = score 0
    if (adherence <= 70) return 10.0;
    if (adherence >= 90) return 0.0;
    return (90 - adherence) / 20 * 10;
  }

  static double _scorePrsTrend(double trend) {
    // Trend < -0.3 = score 10 (decreciendo rápido)
    if (trend <= -0.3) return 10.0;
    if (trend >= 0) return 0.0;
    return (-trend) / 0.3 * 10;
  }

  static double _scoreRpeTrend(double trend) {
    // Trend > 0.3 = score 10 (creciendo rápido)
    if (trend >= 0.3) return 10.0;
    if (trend <= 0) return 0.0;
    return trend / 0.3 * 10;
  }

  static double _scoreFatigueSignals(int signals, int totalSessions) {
    final ratio = signals / totalSessions;
    // > 50% sesiones con fatiga = score 10
    if (ratio >= 0.5) return 10.0;
    return ratio * 20;
  }

  static double _scoreWeeksWithoutDeload(int weeks) {
    // > 6 semanas = score 10, < 3 semanas = score 0
    if (weeks >= 6) return 10.0;
    if (weeks <= 3) return 0.0;
    return (weeks - 3) / 3 * 10;
  }

  /// Calcula score total ponderado (0-100)
  ///
  /// PESOS:
  /// - PRS avg: 20%
  /// - RPE avg: 15%
  /// - DOMS avg: 10%
  /// - Adherencia: 15%
  /// - PRS trend: 15%
  /// - RPE trend: 10%
  /// - Fatigue signals: 10%
  /// - Weeks without deload: 5%
  static double _calculateTotalScore(Map<String, double> criteria) {
    final weights = {
      'prs_avg': 0.20,
      'rpe_avg': 0.15,
      'doms_avg': 0.10,
      'adherence': 0.15,
      'prs_trend': 0.15,
      'rpe_trend': 0.10,
      'fatigue_signals': 0.10,
      'weeks_without_deload': 0.05,
    };

    double score = 0.0;
    criteria.forEach((key, value) {
      score += value * (weights[key] ?? 0.0);
    });

    return score * 10;
  }

  /// Toma decisión basada en score total
  ///
  /// UMBRALES:
  /// - Score < 30: No deload
  /// - Score 30-50: Deload preventivo (opcional)
  /// - Score 50-70: Deload recomendado
  /// - Score > 70: Deload urgente
  static Map<String, dynamic> _makeDeloadDecision(double totalScore) {
    if (totalScore >= 70) {
      return {
        'needs_deload': true,
        'urgency': 'urgent',
        'reasoning':
            'Score crítico (${totalScore.toStringAsFixed(1)}/100) - Múltiples indicadores de fatiga alta',
      };
    } else if (totalScore >= 50) {
      return {
        'needs_deload': true,
        'urgency': 'recommended',
        'reasoning':
            'Score elevado (${totalScore.toStringAsFixed(1)}/100) - Deload recomendado para optimizar recuperación',
      };
    } else if (totalScore >= 30) {
      return {
        'needs_deload': false,
        'urgency': 'optional',
        'reasoning':
            'Score moderado (${totalScore.toStringAsFixed(1)}/100) - Deload preventivo opcional',
      };
    } else {
      return {
        'needs_deload': false,
        'urgency': 'none',
        'reasoning':
            'Score bajo (${totalScore.toStringAsFixed(1)}/100) - No se requiere deload',
      };
    }
  }

  /// Genera protocolo de deload específico
  ///
  /// TIPOS DE DELOAD:
  /// 1. Deload de volumen (reducir sets 40-50%)
  /// 2. Deload de intensidad (reducir peso 20-30%)
  /// 3. Deload completo (volumen + intensidad)
  /// 4. Descanso activo (ejercicio de baja intensidad)
  static Map<String, dynamic> _generateDeloadProtocol(
    Map<String, dynamic> decision,
    Map<String, double> criteria,
  ) {
    if (decision['needs_deload'] != true && decision['urgency'] != 'optional') {
      return {
        'type': 'none',
        'description': 'Continuar con plan normal',
        'duration_weeks': 0,
      };
    }

    final urgency = decision['urgency'] as String;

    // Deload urgente → Completo
    if (urgency == 'urgent') {
      return {
        'type': 'complete_deload',
        'description': 'Reducir volumen 50% Y peso 20-30%',
        'duration_weeks': 1,
        'volume_reduction': 0.50,
        'intensity_reduction': 0.25,
        'notes': 'Priorizar técnica, ROM completo, y recuperación',
      };
    }

    // Deload recomendado → Analizar qué está más alto
    if (urgency == 'recommended') {
      final volumeIndicators =
          (criteria['adherence']! + criteria['fatigue_signals']!) / 2;
      final intensityIndicators =
          (criteria['rpe_avg']! + criteria['doms_avg']!) / 2;

      if (volumeIndicators > intensityIndicators) {
        // Deload de volumen
        return {
          'type': 'volume_deload',
          'description': 'Reducir volumen 40%, mantener intensidad',
          'duration_weeks': 1,
          'volume_reduction': 0.40,
          'intensity_reduction': 0.0,
          'notes': 'Reducir sets pero mantener peso',
        };
      } else {
        // Deload de intensidad
        return {
          'type': 'intensity_deload',
          'description': 'Mantener volumen, reducir peso 20-25%',
          'duration_weeks': 1,
          'volume_reduction': 0.0,
          'intensity_reduction': 0.25,
          'notes': 'Mantener sets pero reducir carga',
        };
      }
    }

    // Deload opcional → Deload leve
    return {
      'type': 'light_deload',
      'description': 'Reducir volumen 20-30%',
      'duration_weeks': 1,
      'volume_reduction': 0.25,
      'intensity_reduction': 0.0,
      'notes': 'Deload preventivo leve',
    };
  }

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
}
