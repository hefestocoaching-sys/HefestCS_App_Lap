/// Fuente de los datos de volumen semanal
enum WeekVolumeSource {
  /// Datos registrados en la bitácora (reales)
  real,

  /// Datos calculados por el motor (teóricos) o PLAN prescrito sin adaptación (S1 de AA)
  planned,

  /// Datos de fallback motor (S2+ sin bitácora previa, AUTO-adaptado por reglas conservadoras)
  auto,
}

/// Patrón de entrenamiento de la semana
enum WeekPattern {
  /// Incremento progresivo de volumen
  increase,

  /// Mantenimiento del volumen
  stable,

  /// Descarga (reducción temporal de volumen)
  deload,

  /// Intensificación (preparación para competencia)
  intensification,
}

/// Modelo de visualización para volumen semanal (NO persistente)
/// Solo cálculo y presentación de datos para la Tab 3
class WeeklyVolumeView {
  /// Número de semana (1–52)
  final int weekIndex;

  /// Músculo específico
  final String muscle;

  /// Total de series para la semana
  final int totalSeries;

  /// Series pesadas (RIR 0–2)
  final int heavySeries;

  /// Series medias (RIR 2–4)
  final int mediumSeries;

  /// Series ligeras (RIR 4+)
  final int lightSeries;

  /// Origen de los datos
  final WeekVolumeSource source;

  /// Patrón de entrenamiento de la semana
  final WeekPattern pattern;

  WeeklyVolumeView({
    required this.weekIndex,
    required this.muscle,
    required this.totalSeries,
    required this.heavySeries,
    required this.mediumSeries,
    required this.lightSeries,
    required this.source,
    required this.pattern,
  });

  /// Si es real, quién registró y cuándo (metadata, opcional)
  /// Aquí solo usamos el tipo de fuente
  bool get isReal => source == WeekVolumeSource.real;
  bool get isPlanned => source == WeekVolumeSource.planned;
}
