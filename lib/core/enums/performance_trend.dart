// lib/core/enums/performance_trend.dart

/// Tendencia de rendimiento actual del atleta
enum PerformanceTrend {
  /// Rendimiento mejorando constantemente
  improving,

  /// Rendimiento estancado (meseta)
  plateaued,

  /// Rendimiento empeorando
  declining,
}

extension PerformanceTrendX on PerformanceTrend {
  String get label {
    switch (this) {
      case PerformanceTrend.improving:
        return 'Mejorando';
      case PerformanceTrend.plateaued:
        return 'Estancado';
      case PerformanceTrend.declining:
        return 'Empeorando';
    }
  }

  String get description {
    switch (this) {
      case PerformanceTrend.improving:
        return 'Rendimiento mejora semana a semana (más carga/reps/volumen)';
      case PerformanceTrend.plateaued:
        return 'Rendimiento sin cambios (meseta)';
      case PerformanceTrend.declining:
        return 'Rendimiento empeorando (menos carga/reps, fatiga acumulada)';
    }
  }
}

/// Parse desde string
PerformanceTrend? performanceTrendFromString(String? str) {
  if (str == null || str.isEmpty) return null;
  final normalized = str.toLowerCase().trim();

  for (final trend in PerformanceTrend.values) {
    if (trend.name == normalized) return trend;
  }

  // Aliases
  switch (normalized) {
    case 'mejorando':
    case 'improving':
    case 'progressing':
      return PerformanceTrend.improving;
    case 'estancado':
    case 'plateaued':
    case 'stalled':
      return PerformanceTrend.plateaued;
    case 'empeorando':
    case 'declining':
    case 'regressing':
      return PerformanceTrend.declining;
    default:
      return null;
  }
}
