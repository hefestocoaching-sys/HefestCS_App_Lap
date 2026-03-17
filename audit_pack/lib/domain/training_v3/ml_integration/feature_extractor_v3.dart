// lib/domain/training_v3/ml_integration/feature_extractor_v3.dart

import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/performance_metrics.dart';

/// Extractor de features del Motor V3 para ML
///
/// Convierte datos del Motor V3 en vector de features normalizado
/// compatible con el sistema ML legacy.
///
/// Features extraídas: 45 features
/// - 15 del perfil de usuario
/// - 20 de logs históricos (últimas 4 semanas)
/// - 10 de métricas de rendimiento
///
/// Versión: 1.0.0
class FeatureExtractorV3 {
  /// Extrae features completas de un usuario
  ///
  /// PARÁMETROS:
  /// - [profile]: Perfil del usuario
  /// - [recentLogs]: Logs de últimas 4 semanas (opcional)
  /// - [metrics]: Métricas agregadas (opcional)
  ///
  /// RETORNA:
  /// - Map&lt;String, double&gt;: Features normalizadas (0.0-1.0)
  static Map<String, double> extractFeatures({
    required UserProfile profile,
    List<WorkoutLog>? recentLogs,
    PerformanceMetrics? metrics,
  }) {
    final features = <String, double>{};

    // ═══════════════════════════════════════════════════
    // GRUPO 1: FEATURES DEL PERFIL (15 features)
    // ═══════════════════════════════════════════════════

    // Demográficas
    features['age_norm'] = _normalizeAge(profile.age);
    features['gender_male'] = profile.gender == 'male' ? 1.0 : 0.0;
    features['height_norm'] = _normalizeHeight(profile.heightCm as int);
    features['weight_norm'] = _normalizeWeight(profile.weightKg);
    features['bmi_norm'] = _normalizeBMI(
      profile.weightKg / ((profile.heightCm / 100) * (profile.heightCm / 100)),
    );

    // Experiencia
    features['training_level'] = _encodeTrainingLevel(profile.trainingLevel);
    features['years_training_norm'] = _normalizeYears(
      profile.yearsTraining as int,
    );
    features['available_days_norm'] = profile.availableDays / 7.0;
    features['session_duration_norm'] =
        profile.sessionDuration / 180.0; // max 3h

    // Objetivo y prioridades
    features['goal_hypertrophy'] = profile.primaryGoal == 'hypertrophy'
        ? 1.0
        : 0.0;
    features['goal_strength'] = profile.primaryGoal == 'strength' ? 1.0 : 0.0;

    // Prioridades musculares (top 4)
    final topMuscles = profile.musclePriorities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    features['priority_1'] = topMuscles.isNotEmpty
        ? topMuscles[0].value / 5.0
        : 0.0;
    features['priority_2'] = topMuscles.length > 1
        ? topMuscles[1].value / 5.0
        : 0.0;
    features['priority_3'] = topMuscles.length > 2
        ? topMuscles[2].value / 5.0
        : 0.0;
    features['priority_4'] = topMuscles.length > 3
        ? topMuscles[3].value / 5.0
        : 0.0;

    // ═══════════════════════════════════════════════════
    // GRUPO 2: FEATURES DE LOGS RECIENTES (20 features)
    // ═══════════════════════════════════════════════════

    if (recentLogs != null && recentLogs.isNotEmpty) {
      features.addAll(_extractLogFeatures(recentLogs));
    } else {
      // Valores neutros si no hay logs
      features.addAll(_getDefaultLogFeatures());
    }

    // ═══════════════════════════════════════════════════
    // GRUPO 3: FEATURES DE MÉTRICAS (10 features)
    // ═══════════════════════════════════════════════════

    if (metrics != null) {
      features.addAll(_extractMetricsFeatures(metrics));
    } else {
      features.addAll(_getDefaultMetricsFeatures());
    }

    return features;
  }

  /// Extrae features de logs históricos
  static Map<String, double> _extractLogFeatures(List<WorkoutLog> logs) {
    final features = <String, double>{};

    // Promedios
    final avgAdherence =
        logs.fold(0.0, (sum, l) => sum + l.adherencePercentage) /
        logs.length /
        100;
    final avgRpe = logs.fold(0.0, (sum, l) => sum + l.sessionRpe) / logs.length;
    final avgPrs =
        logs.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
        logs.length;
    final avgDoms =
        logs.fold(0.0, (sum, l) => sum + l.muscleSoreness) / logs.length;

    features['avg_adherence'] = avgAdherence;
    features['avg_rpe'] = avgRpe / 10.0;
    features['avg_prs'] = avgPrs / 10.0;
    features['avg_doms'] = avgDoms / 10.0;

    // Tendencias (primera mitad vs segunda mitad)
    final mid = logs.length ~/ 2;
    final firstHalf = logs.take(mid).toList();
    final secondHalf = logs.skip(mid).toList();

    final rpeFirst =
        firstHalf.fold(0.0, (sum, l) => sum + l.sessionRpe) / firstHalf.length;
    final rpeSecond =
        secondHalf.fold(0.0, (sum, l) => sum + l.sessionRpe) /
        secondHalf.length;
    final rpeTrend = _normalizeTrend((rpeSecond - rpeFirst) / rpeFirst);

    final prsFirst =
        firstHalf.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
        firstHalf.length;
    final prsSecond =
        secondHalf.fold(0.0, (sum, l) => sum + l.perceivedRecoveryStatus) /
        secondHalf.length;
    final prsTrend = _normalizeTrend((prsSecond - prsFirst) / prsFirst);

    features['rpe_trend'] = rpeTrend;
    features['prs_trend'] = prsTrend;

    // Volatilidad (desviación estándar normalizada)
    final rpeStd = _calculateStdDev(logs.map((l) => l.sessionRpe).toList());
    final prsStd = _calculateStdDev(
      logs.map((l) => l.perceivedRecoveryStatus).toList(),
    );

    features['rpe_volatility'] = rpeStd / 10.0;
    features['prs_volatility'] = prsStd / 10.0;

    // Fatiga acumulada
    final fatigueScore =
        logs.fold(0.0, (sum, l) {
          final fatigue = (10 - l.perceivedRecoveryStatus) / 10;
          final rpe = l.sessionRpe / 10;
          return sum + (fatigue * 0.6 + rpe * 0.4);
        }) /
        logs.length;

    features['accumulated_fatigue'] = fatigueScore;

    // Sesiones completadas
    final completedCount = logs.where((l) => l.completed).length;
    features['completion_rate'] = completedCount / logs.length;

    // Consistencia (días entre sesiones)
    features['training_consistency'] = _calculateConsistency(logs);

    // Últimos valores
    final lastLog = logs.last;
    features['last_rpe'] = lastLog.sessionRpe / 10.0;
    features['last_prs'] = lastLog.perceivedRecoveryStatus / 10.0;
    features['last_doms'] = lastLog.muscleSoreness / 10.0;
    features['last_adherence'] = lastLog.adherencePercentage / 100.0;

    // Flags de señales de fatiga
    features['has_fatigue_signals'] = lastLog.showsFatigueSignals ? 1.0 : 0.0;

    // Semanas consecutivas entrenando
    features['consecutive_weeks'] = _calculateConsecutiveWeeks(logs) / 52.0;

    // Volumen promedio
    final avgVolume =
        logs.fold(0.0, (sum, l) => sum + l.totalSets) / logs.length;
    features['avg_weekly_volume'] =
        avgVolume / 150.0; // normalizar a 150 sets max

    return features;
  }

  /// Extrae features de métricas de rendimiento
  static Map<String, double> _extractMetricsFeatures(
    PerformanceMetrics metrics,
  ) {
    return {
      'volume_trend': _normalizeTrend(metrics.volumeTrend),
      'load_trend': _normalizeTrend(metrics.loadTrend),
      'rpe_trend_metrics': _normalizeTrend(metrics.rpeTrend),
      'avg_adherence_metrics': metrics.averageAdherence,
      'performance_improving': metrics.performanceStatus == 'improving'
          ? 1.0
          : 0.0,
      'performance_stable': metrics.performanceStatus == 'stable' ? 1.0 : 0.0,
      'performance_declining': metrics.performanceStatus == 'declining'
          ? 1.0
          : 0.0,
      'sessions_completion':
          metrics.completedSessions / metrics.plannedSessions,
      'avg_weekly_volume_metrics': metrics.averageWeeklyVolume / 150.0,
      'total_volume_norm':
          metrics.totalVolume / (metrics.averageWeeklyVolume * 52),
    };
  }

  // ═══════════════════════════════════════════════════
  // HELPERS DE NORMALIZACIÓN
  // ═══════════════════════════════════════════════════

  static double _normalizeAge(int age) => (age - 18) / (65 - 18);
  static double _normalizeHeight(int cm) => (cm - 140) / (220 - 140);
  static double _normalizeWeight(double kg) => (kg - 40) / (160 - 40);
  static double _normalizeBMI(double bmi) => (bmi - 15) / (40 - 15);
  static double _normalizeYears(int years) => years / 30.0;
  static double _normalizeTrend(double trend) =>
      (trend + 1.0) / 2.0; // -1,1 → 0,1

  static double _encodeTrainingLevel(String level) {
    switch (level) {
      case 'novice':
        return 0.2;
      case 'intermediate':
        return 0.5;
      case 'advanced':
        return 0.8;
      default:
        return 0.5;
    }
  }

  static double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.fold(0.0, (sum, v) => sum + v) / values.length;
    final variance =
        values.fold(0.0, (sum, v) => sum + ((v - mean) * (v - mean))) /
        values.length;
    return variance.isFinite ? variance : 0.0;
  }

  static double _calculateConsistency(List<WorkoutLog> logs) {
    if (logs.length < 2) return 1.0;

    final sortedLogs = logs.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final gaps = <int>[];

    for (int i = 1; i < sortedLogs.length; i++) {
      final daysBetween = sortedLogs[i].startTime
          .difference(sortedLogs[i - 1].startTime)
          .inDays;
      gaps.add(daysBetween);
    }

    final avgGap = gaps.fold(0, (sum, gap) => sum + gap) / gaps.length;
    // Consistencia alta = gaps cerca de 2-3 días
    final deviation = (avgGap - 2.5).abs();
    return (1.0 - (deviation / 7.0)).clamp(0.0, 1.0);
  }

  static int _calculateConsecutiveWeeks(List<WorkoutLog> logs) {
    if (logs.isEmpty) return 0;

    final sortedLogs = logs.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    int weeks = 1;
    DateTime currentWeekStart = sortedLogs.first.startTime;

    for (final log in sortedLogs.skip(1)) {
      final daysSince = log.startTime.difference(currentWeekStart).inDays;
      if (daysSince > 14) break; // Gap > 2 semanas rompe racha
      if (daysSince >= 7) {
        weeks++;
        currentWeekStart = log.startTime;
      }
    }

    return weeks;
  }

  // Features por defecto cuando no hay datos
  static Map<String, double> _getDefaultLogFeatures() {
    return {
      'avg_adherence': 0.5,
      'avg_rpe': 0.5,
      'avg_prs': 0.5,
      'avg_doms': 0.3,
      'rpe_trend': 0.5,
      'prs_trend': 0.5,
      'rpe_volatility': 0.3,
      'prs_volatility': 0.3,
      'accumulated_fatigue': 0.3,
      'completion_rate': 0.5,
      'training_consistency': 0.5,
      'last_rpe': 0.5,
      'last_prs': 0.5,
      'last_doms': 0.3,
      'last_adherence': 0.5,
      'has_fatigue_signals': 0.0,
      'consecutive_weeks': 0.0,
      'avg_weekly_volume': 0.5,
    };
  }

  static Map<String, double> _getDefaultMetricsFeatures() {
    return {
      'volume_trend': 0.5,
      'load_trend': 0.5,
      'rpe_trend_metrics': 0.5,
      'avg_adherence_metrics': 0.5,
      'performance_improving': 0.0,
      'performance_stable': 1.0,
      'performance_declining': 0.0,
      'sessions_completion': 0.5,
      'avg_weekly_volume_metrics': 0.5,
      'total_volume_norm': 0.5,
    };
  }
}
