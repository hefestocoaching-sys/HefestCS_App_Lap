// lib/domain/training_v3/engines/workout_log_processor.dart

import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/performance_metrics.dart';

/// Procesador de logs de entrenamiento
///
/// Transforma bitácoras brutas en métricas accionables:
/// - Calcula adherencia real vs planeada
/// - Detecta patrones de fatiga
/// - Identifica ejercicios problemáticos
/// - Genera recomendaciones
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Sistema reactivo
/// - Autoregulación basada en datos objetivos
/// - Detección temprana de sobreentrenamiento
///
/// Versión: 1.0.0
class WorkoutLogProcessor {
  /// Procesa un log de entrenamiento y genera insights
  ///
  /// ALGORITMO:
  /// 1. Validar log
  /// 2. Calcular métricas de adherencia
  /// 3. Analizar RPE vs planeado
  /// 4. Detectar señales de fatiga
  /// 5. Generar recomendaciones
  ///
  /// PARÁMETROS:
  /// - [log]: WorkoutLog completado
  /// - [plannedSession]: Sesión original planeada (para comparación)
  ///
  /// RETORNA:
  /// - Map con métricas y recomendaciones
  static Map<String, dynamic> processLog({
    required WorkoutLog log,
    required Map<String, dynamic> plannedSession,
  }) {
    // PASO 1: Validar log
    if (!log.isValid) {
      throw ArgumentError('WorkoutLog inválido');
    }

    // PASO 2: Calcular adherencia
    final adherenceMetrics = _calculateAdherence(log, plannedSession);

    // PASO 3: Analizar RPE
    final rpeAnalysis = _analyzeRpe(log, plannedSession);

    // PASO 4: Detectar fatiga
    final fatigueSignals = _detectFatigue(log);

    // PASO 5: Generar recomendaciones
    final recommendations = _generateRecommendations(
      adherenceMetrics,
      rpeAnalysis,
      fatigueSignals,
    );

    return {
      'adherence': adherenceMetrics,
      'rpe_analysis': rpeAnalysis,
      'fatigue_signals': fatigueSignals,
      'recommendations': recommendations,
      'processed_at': DateTime.now().toIso8601String(),
    };
  }

  /// Calcula métricas de adherencia
  ///
  /// FUENTE: Semana 7
  ///
  /// MÉTRICAS:
  /// - Adherencia total (sets completados / sets planeados)
  /// - Adherencia por ejercicio
  /// - Ejercicios omitidos
  static Map<String, dynamic> _calculateAdherence(
    WorkoutLog log,
    Map<String, dynamic> plannedSession,
  ) {
    final plannedExercises = plannedSession['exercises'] as List? ?? [];
    final completedExercises = log.exerciseLogs;

    // Sets totales
    final totalPlannedSets = log.totalPlannedSets;
    final totalCompletedSets = log.totalSets;
    final adherencePct = totalPlannedSets > 0
        ? (totalCompletedSets / totalPlannedSets) * 100
        : 0.0;

    // Ejercicios omitidos
    final plannedIds = plannedExercises
        .map((e) => e['exerciseId'] as String)
        .toSet();
    final completedIds = completedExercises.map((e) => e.exerciseId).toSet();
    final omittedExercises = plannedIds.difference(completedIds).toList();

    return {
      'total_adherence_pct': adherencePct,
      'planned_sets': totalPlannedSets,
      'completed_sets': totalCompletedSets,
      'omitted_exercises': omittedExercises,
      'is_acceptable': adherencePct >= 80.0, // Umbral científico
    };
  }

  /// Analiza RPE real vs planeado
  ///
  /// REGLA: Si RPE real > RPE planeado + 1.5 → carga muy alta
  static Map<String, dynamic> _analyzeRpe(
    WorkoutLog log,
    Map<String, dynamic> plannedSession,
  ) {
    final sessionRpe = log.sessionRpe;
    final plannedRpe =
        (plannedSession['target_rpe'] as num?)?.toDouble() ?? 7.0;
    final rpeDelta = sessionRpe - plannedRpe;

    String interpretation;
    String action;

    if (rpeDelta > 1.5) {
      interpretation = 'RPE muy alto: sesión más dura de lo planeado';
      action = 'Considerar reducir carga 5-10% próxima sesión';
    } else if (rpeDelta < -1.5) {
      interpretation = 'RPE muy bajo: sesión más fácil de lo planeado';
      action = 'Considerar aumentar carga 2.5-5% próxima sesión';
    } else {
      interpretation = 'RPE en rango esperado';
      action = 'Continuar con progresión normal';
    }

    return {
      'session_rpe': sessionRpe,
      'planned_rpe': plannedRpe,
      'delta': rpeDelta,
      'interpretation': interpretation,
      'action': action,
    };
  }

  /// Detecta señales de fatiga alta
  ///
  /// FUENTE: Semana 7, Imagen 96-105
  ///
  /// SEÑALES:
  /// - RPE > 8.5 + PRS < 5 + DOMS > 6
  /// - Adherencia < 70% + PRS < 5
  static Map<String, dynamic> _detectFatigue(WorkoutLog log) {
    final signals = <String>[];
    bool highFatigue = false;

    // Señal 1: Combinación RPE-PRS-DOMS
    if (log.sessionRpe > 8.5 &&
        log.perceivedRecoveryStatus < 5 &&
        log.muscleSoreness > 6) {
      signals.add(
        'RPE muy alto (${log.sessionRpe}) + PRS bajo (${log.perceivedRecoveryStatus}) + DOMS alto (${log.muscleSoreness})',
      );
      highFatigue = true;
    }

    // Señal 2: Baja adherencia + PRS bajo
    if (log.adherencePercentage < 70 && log.perceivedRecoveryStatus < 5) {
      signals.add(
        'Adherencia baja (${log.adherencePercentage.toStringAsFixed(1)}%) + PRS bajo (${log.perceivedRecoveryStatus})',
      );
      highFatigue = true;
    }

    // Señal 3: PRS muy bajo (< 3)
    if (log.perceivedRecoveryStatus < 3) {
      signals.add('PRS crítico (${log.perceivedRecoveryStatus}/10)');
      highFatigue = true;
    }

    return {
      'has_high_fatigue': highFatigue,
      'signals': signals,
      'fatigue_level': _calculateFatigueLevel(log),
    };
  }

  /// Calcula nivel de fatiga (0.0-1.0)
  static double _calculateFatigueLevel(WorkoutLog log) {
    // Fórmula heurística basada en PRS, RPE, DOMS
    final prsComponent = (10 - log.perceivedRecoveryStatus) / 10; // 0-1
    final rpeComponent = (log.sessionRpe - 5) / 5; // 0-1
    final domsComponent = log.muscleSoreness / 10; // 0-1

    // Pesos: PRS 50%, RPE 30%, DOMS 20%
    final fatigue =
        (prsComponent * 0.5) + (rpeComponent * 0.3) + (domsComponent * 0.2);

    return fatigue.clamp(0.0, 1.0);
  }

  /// Genera recomendaciones accionables
  static List<String> _generateRecommendations(
    Map<String, dynamic> adherence,
    Map<String, dynamic> rpe,
    Map<String, dynamic> fatigue,
  ) {
    final recommendations = <String>[];

    // Recomendación 1: Adherencia
    if (adherence['is_acceptable'] == false) {
      recommendations.add(
        '⚠️  Adherencia baja (${adherence['total_adherence_pct'].toStringAsFixed(1)}%). '
        'Revisar si volumen es muy alto o hay factores externos (tiempo, sueño, estrés).',
      );
    }

    // Recomendación 2: RPE
    recommendations.add(rpe['action'] as String);

    // Recomendación 3: Fatiga
    if (fatigue['has_high_fatigue'] == true) {
      final fatigueLevel = fatigue['fatigue_level'] as double;
      if (fatigueLevel > 0.8) {
        recommendations.add(
          '🛑 FATIGA CRÍTICA: Considerar deload inmediato (reducir volumen 40-50% por 1 semana).',
        );
      } else if (fatigueLevel > 0.6) {
        recommendations.add(
          '⚠️  FATIGA ALTA: Reducir volumen 20-30% próxima semana y monitorear.',
        );
      }
    } else {
      recommendations.add('✅ Sin señales de fatiga alta. Continuar con plan.');
    }

    return recommendations;
  }

  /// Analiza logs históricos para tendencias
  ///
  /// PARÁMETROS:
  /// - [logs]: Lista de WorkoutLog (últimas 2-4 semanas)
  ///
  /// RETORNA:
  /// - PerformanceMetrics con tendencias
  static PerformanceMetrics analyzeTrends({
    required List<WorkoutLog> logs,
    required String targetMuscle,
  }) {
    if (logs.isEmpty) {
      throw ArgumentError('Se requiere al menos 1 log');
    }

    // Calcular métricas promedio
    final avgAdherence =
        logs.fold(0.0, (sum, log) => sum + log.adherencePercentage) /
        logs.length /
        100;
    final avgRpe =
        logs.fold(0.0, (sum, log) => sum + log.sessionRpe) / logs.length;
    final avgPrs =
        logs.fold(0.0, (sum, log) => sum + log.perceivedRecoveryStatus) /
        logs.length;

    // Calcular tendencias (simple: comparar primera mitad vs segunda mitad)
    final firstHalf = logs.take(logs.length ~/ 2).toList();
    final secondHalf = logs.skip(logs.length ~/ 2).toList();

    final avgRpeFirst =
        firstHalf.fold(0.0, (sum, log) => sum + log.sessionRpe) /
        firstHalf.length;
    final avgRpeSecond =
        secondHalf.fold(0.0, (sum, log) => sum + log.sessionRpe) /
        secondHalf.length;
    final rpeTrend = _calculateTrend(avgRpeFirst, avgRpeSecond);

    // Determinar estado
    String status;
    String action;

    if (avgAdherence < 0.7 || avgRpe > 8.5 || avgPrs < 5) {
      status = 'declining';
      action = 'deload';
    } else if (avgAdherence > 0.9 && avgRpe < 7.5 && avgPrs > 7) {
      status = 'improving';
      action = 'increase_load';
    } else {
      status = 'stable';
      action = 'continue';
    }

    return PerformanceMetrics(
      targetId: targetMuscle,
      targetType: 'muscle',
      startDate: logs.first.startTime,
      endDate: logs.last.endTime,
      averageWeeklyVolume: 0.0, // Calcular desde logs si es necesario
      totalVolume: 0.0,
      volumeTrend: 0.0,
      averageLoad: 0.0,
      loadTrend: 0.0,
      averageRpe: avgRpe,
      rpeTrend: rpeTrend,
      averageAdherence: avgAdherence,
      completedSessions: logs.where((l) => l.completed).length,
      plannedSessions: logs.length,
      performanceStatus: status,
      recommendedAction: action,
    );
  }

  /// Calcula tendencia normalizada (-1.0 a +1.0)
  static double _calculateTrend(double first, double second) {
    if (first == 0) return 0.0;
    final change = (second - first) / first;
    return change.clamp(-1.0, 1.0);
  }
}
