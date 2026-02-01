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

  // ════════════════════════════════════════════════════════════════
  // TRAINING INTERVIEW V2 - MANDATORY FIELDS (2025)
  // Basado en Israetel, Schoenfeld, Helms, NSCA 2024-2025
  // ════════════════════════════════════════════════════════════════

  /// Volumen promedio semanal por músculo (sets/semana)
  /// Ejemplo: 12 = entrena pecho con 12 sets totales/semana
  /// Rango típico: 8-25 sets
  static const avgWeeklySetsPerMuscle = 'avgWeeklySetsPerMuscle';

  /// Semanas consecutivas entrenando sin pausas >1 semana
  /// Usado para evaluar consistencia y adaptación
  /// Ejemplo: 16 = lleva 16 semanas sin parar
  static const consecutiveWeeksTraining = 'consecutiveWeeksTraining';

  /// Perceived Recovery Status (PRS) - Escala 1-10
  /// 1 = Completamente fatigado, 10 = Completamente recuperado
  /// Promedio antes de cada sesión
  static const perceivedRecoveryStatus = 'perceivedRecoveryStatus';

  /// Reps In Reserve promedio (0-5)
  /// 0 = Fallo muscular, 5 = Muy fácil
  /// Usado para autoregulación por RIR
  static const averageRIR = 'averageRIR';

  /// Rating of Perceived Exertion promedio (1-10)
  /// Esfuerzo percibido al final de la sesión
  /// 1 = Muy fácil, 10 = Máximo esfuerzo
  static const averageSessionRPE = 'averageSessionRPE';

  // ════════════════════════════════════════════════════════════════
  // TRAINING INTERVIEW V2 - RECOMMENDED FIELDS (2025)
  // ════════════════════════════════════════════════════════════════

  /// Máximo sets por músculo por semana antes de overreaching
  /// Usado para calcular MRV individual
  static const maxWeeklySetsBeforeOverreaching =
      'maxWeeklySetsBeforeOverreaching';

  /// Frecuencia de deload en semanas (cada cuántas semanas)
  /// Ejemplo: 4 = necesita deload cada 4 semanas
  static const deloadFrequencyWeeks = 'deloadFrequencyWeeks';

  /// Resting Heart Rate (RHR) - Frecuencia cardíaca en reposo
  /// Medido por la mañana, en bpm
  /// Usado para detectar fatiga sistémica
  static const restingHeartRate = 'restingHeartRate';

  /// Heart Rate Variability (HRV) - Variabilidad cardíaca
  /// Medido en ms (RMSSD típicamente)
  /// Indicador de recuperación del sistema nervioso
  static const heartRateVariability = 'heartRateVariability';

  /// DOMS promedio a las 48h (1-10)
  /// Delayed Onset Muscle Soreness
  /// 1 = Sin dolor, 10 = Dolor extremo
  static const soreness48hAverage = 'soreness48hAverage';

  /// Pausas >2 semanas en últimos 12 meses
  /// Ejemplo: 2 = tuvo 2 pausas largas en el año
  static const periodBreaksLast12Months = 'periodBreaksLast12Months';

  /// Tasa de completitud de sesiones (0.0-1.0)
  /// Ejemplo: 0.85 = completa 85% de sesiones planificadas
  static const sessionCompletionRate = 'sessionCompletionRate';

  /// Tendencia de rendimiento actual
  /// Valores: 'improving', 'plateaued', 'declining'
  static const performanceTrend = 'performanceTrend';
}
