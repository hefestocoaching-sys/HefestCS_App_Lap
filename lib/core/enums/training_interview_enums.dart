/// Enums estandarizados para datos categóricos de entrevista de entrenamiento.
/// Estos valores se persisten como strings (usando .name) en TrainingProfile.extra
library;

/// Novedad del programa de entrenamiento
/// Afecta VME: programas completamente nuevos reducen tolerancia inicial
enum ProgramNovelty {
  /// Programa completamente nuevo (primera vez)
  newProgram,

  /// Familiarizado con ejercicios básicos
  basic,

  /// Experiencia intermedia con el estilo de programa
  intermediate,

  /// Muy familiarizado con este tipo de entrenamiento
  advanced,
}

/// Nivel de estrés percibido en entrevista clínica (físico o no físico)
/// NOTA: Distinto de StressLevel usado en otros contextos
enum InterviewStressLevel {
  /// Estrés bajo
  low,

  /// Estrés moderado
  moderate,

  /// Estrés alto
  high,
}

/// Calidad del descanso/sueño
enum InterviewRestQuality {
  /// Buen descanso (sueño profundo, sin interrupciones)
  good,

  /// Descanso promedio (algunas interrupciones)
  average,

  /// Mal descanso (sueño fragmentado, insomnio)
  poor,
}

/// Calidad y tipo de dieta
/// Afecta VMR significativamente (disponibilidad energética)
enum DietQuality {
  /// Superávit calórico con alimentos limpios
  surplusClean,

  /// Superávit calórico con alimentos procesados
  surplusDirty,

  /// Dieta isocalórica (mantenimiento)
  isocaloric,

  /// Déficit calórico moderado con alimentos limpios
  deficitClean,

  /// Déficit calórico moderado
  deficitModerate,

  /// Déficit calórico agresivo
  deficitAggressive,
}
