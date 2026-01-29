/// Constantes canónicas para las claves de datos de entrevista de entrenamiento
/// que se persisten en TrainingProfile.extra
///
/// Estos datos alimentan los cálculos de VME (Volumen Máximo Efectivo) y
/// VMR (Volumen Máximo Recuperable) según PDF Semana 2
class TrainingInterviewKeys {
  // ============================================================
  // DATOS CUANTITATIVOS BÁSICOS
  // ============================================================

  /// Años de entrenamiento continuo (int)
  /// Afecta: VME base
  static const yearsTrainingContinuous = 'yearsTrainingContinuous';

  /// Horas promedio de sueño (double)
  /// Afecta: VMR (calidad de recuperación)
  static const avgSleepHours = 'avgSleepHours';

  /// Duración típica de sesión en minutos (int)
  /// Afecta: Capacidad de trabajo total
  static const sessionDurationMinutes = 'sessionDurationMinutes';

  /// Descanso entre series en segundos (int)
  /// Afecta: Capacidad de trabajo total
  static const restBetweenSetsSeconds = 'restBetweenSetsSeconds';

  // ============================================================
  // FACTORES DE PERIODIZACIÓN (ESCALAS 1–5)
  // ============================================================

  /// Capacidad de trabajo (int 1–5)
  /// 1 = muy baja, 3 = normal, 5 = muy alta
  /// Afecta: VME y VMR (capacidad de manejar volumen)
  static const workCapacity = 'workCapacity';

  /// Historial de recuperación (int 1–5)
  /// 1 = mala, 3 = normal, 5 = excelente
  /// Afecta: VMR (velocidad de recuperación)
  static const recoveryHistory = 'recoveryHistory';

  // ============================================================
  // FACTORES BINARIOS
  // ============================================================

  /// Soporte externo de recuperación (bool)
  /// true = masajes, fisioterapia, crioterapia, etc.
  /// Afecta: VMR (+10-15% si true)
  static const externalRecovery = 'externalRecovery';

  // ============================================================
  // FACTORES CATEGÓRICOS (ENUMS)
  // ============================================================

  /// Novedad del programa (enum ProgramNovelty.name)
  /// newProgram | basic | intermediate | advanced
  /// Afecta: VME (programas nuevos reducen tolerancia inicial)
  static const programNovelty = 'programNovelty';

  /// Estrés físico externo (enum StressLevel.name)
  /// low | moderate | high
  /// Afecta: VMR (trabajo físico fuera del gym)
  static const physicalStress = 'physicalStress';

  /// Estrés no físico (enum StressLevel.name)
  /// low | moderate | high
  /// Afecta: VMR (cortisol, recuperación)
  static const nonPhysicalStress = 'nonPhysicalStress';

  /// Calidad del descanso (enum RestQuality.name)
  /// good | average | poor
  /// Afecta: VMR (sueño profundo, interrupciones)
  static const restQuality = 'restQuality';

  /// Calidad de la dieta (enum DietQuality.name)
  /// surplusClean | surplusDirty | isocaloric | deficitClean | deficitModerate | deficitAggressive
  /// Afecta: VMR (disponibilidad energética para recuperación)
  static const dietQuality = 'dietQuality';

  // ============================================================
  // LEGACY KEYS (mantener para compatibilidad)
  // ============================================================

  /// @deprecated Usar yearsTrainingContinuous
  static const yearsTraining = 'yearsTraining';

  /// @deprecated Usar sessionDurationMinutes
  static const sessionDuration = 'sessionDuration';

  /// @deprecated Usar restBetweenSetsSeconds
  static const restBetweenSets = 'restBetweenSets';

  /// @deprecated Usar workCapacity
  static const workCapacityScore = 'workCapacityScore';

  /// @deprecated Usar recoveryHistory
  static const recoveryHistoryScore = 'recoveryHistoryScore';

  /// @deprecated Usar externalRecovery
  static const externalRecoverySupport = 'externalRecoverySupport';

  /// @deprecated Usar programNovelty (enum)
  static const programNoveltyClass = 'programNoveltyClass';

  /// @deprecated Usar physicalStress (enum)
  static const externalPhysicalStressLevel = 'externalPhysicalStressLevel';

  /// @deprecated Usar nonPhysicalStress (enum)
  static const nonPhysicalStressLevel = 'nonPhysicalStressLevel';
  static const nonPhysicalStressLevel2 = 'nonPhysicalStressLevel2';

  /// @deprecated Usar restQuality (enum)
  static const restQuality2 = 'restQuality2';

  /// @deprecated Usar dietQuality (enum)
  static const dietHabitsClass = 'dietHabitsClass';

  static const strengthLevelClass = 'strengthLevelClass';
  static const heightCm = 'heightCm';
  static const weightKg = 'weightKg';
  static const usesAnabolics = 'usesAnabolics';
  static const trainingLevel = 'trainingLevel';
  static const trainingLevelLabel = 'trainingLevelLabel';
}
