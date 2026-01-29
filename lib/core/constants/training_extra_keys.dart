class TrainingExtraKeys {
  static const sportDiscipline = 'sportDiscipline';
  static const trainingYears = 'trainingYears';
  static const injuries = 'injuries';
  static const availableEquipment = 'availableEquipment';
  static const barriers = 'barriers';
  static const periodizationHistory = 'periodizationHistory';
  static const priorityExercises = 'priorityExercises';
  static const prSquat = 'prSquat';
  static const prBench = 'prBench';
  static const prDeadlift = 'prDeadlift';
  static const detailedInjuryHistory = 'detailedInjuryHistory';
  static const pastVolumeTolerance = 'pastVolumeTolerance';
  static const typicalRestPeriods = 'typicalRestPeriods';
  static const trainingPreferences = 'trainingPreferences';
  static const trainingLevel = 'trainingLevel';
  static const trainingLevelLabel = 'trainingLevelLabel';
  static const previousTrainingExperience = 'previousTrainingExperience';
  static const daysPerWeek = 'daysPerWeek';
  static const timePerSession = 'timePerSession';
  static const timePerSessionMinutes = 'timePerSessionMinutes';
  static const restBetweenSetsSeconds = 'restBetweenSetsSeconds';
  static const planDurationInWeeks = 'planDurationInWeeks';
  static const movementRestrictions = 'movementRestrictions';
  static const avgSleepHours = 'avgSleepHours';
  static const perceivedStress = 'perceivedStress';
  static const recoveryQuality = 'recoveryQuality';
  static const usesAnabolics = 'usesAnabolics';
  static const isCompetitor = 'isCompetitor';
  static const competitionCategory = 'competitionCategory';
  static const competitionDateIso = 'competitionDateIso';
  static const competitionDateLegacy = 'competitionDate';
  static const priorityMusclesPrimary = 'priorityMusclesPrimary';
  static const priorityMusclesSecondary = 'priorityMusclesSecondary';
  static const priorityMusclesTertiary = 'priorityMusclesTertiary';
  static const gluteSpecializationProfile = 'gluteSpecializationProfile';
  static const baseSeries = 'baseSeries';
  static const generatedPlan = 'generatedPlan';
  static const generatedAtIso = 'generatedAtIso';
  static const forDateIso = 'forDateIso';
  static const generatedPlanRecords = 'generatedPlanRecords';
  static const trainingSessionLogRecords = 'trainingSessionLogRecords';
  static const trainingEvaluationRecords = 'trainingEvaluationRecords';
  static const trainingPlanConfig = 'trainingPlanConfig';
  static const decisionTraceRecords = 'decisionTraceRecords';
  static const manualOverrides = 'manualOverrides';
  static const trainingExtraVersion = 'trainingExtraVersion';
  static const progressionBlocked = 'progressionBlocked';
  static const manualOverrideActive = 'manualOverrideActive';
  static const selectedPlanStartDateIso = 'selectedPlanStartDateIso';
  static const activePlanId = 'activePlanId'; // SSOT: plan vigente del ciclo
  static const weeklySplitTemplateId = 'weeklySplitTemplateId';
  static const weeklyPlanOverrides = 'weeklyPlanOverrides';

  // NUEVAS KEYS PARA FORMULARIO CERRADO
  static const discipline = 'discipline';
  static const trainingAge = 'trainingAge';
  static const historicalFrequency = 'historicalFrequency';
  static const plannedFrequency = 'plannedFrequency';
  static const timePerSessionBucket = 'timePerSessionBucket';
  static const volumeTolerance = 'volumeTolerance';
  static const intensityTolerance = 'intensityTolerance';
  static const restProfile = 'restProfile';
  static const sleepBucket = 'sleepBucket';
  static const stressLevel = 'stressLevel';
  static const activeInjuries = 'activeInjuries';
  static const knowsPRs = 'knowsPRs';

  // --- Estructura y adaptación (v1) ---
  static const selectedSplitId = 'selectedSplitId'; // elegido por coach en UI
  static const trainingStructure =
      'trainingStructure'; // estructura lockeada (map)
  static const muscleVolumeProfiles =
      'muscleVolumeProfiles'; // MRV observado por músculo (map)
  static const structureLock =
      'structureLock'; // { lockedFromWeek, lockedUntilWeek? }

  // --- Nuevas keys para formulario cerrado ampliado ---
  static const heightCm = 'heightCm';
  static const strengthLevelClass = 'strengthLevelClass';
  static const workCapacityScore = 'workCapacityScore';
  static const recoveryHistoryScore = 'recoveryHistoryScore';
  static const externalRecoverySupport = 'externalRecoverySupport';
  static const programNoveltyClass = 'programNoveltyClass';
  static const externalPhysicalStressLevel = 'externalPhysicalStressLevel';
  static const nonPhysicalStressLevel2 = 'nonPhysicalStressLevel2';
  static const restQuality2 = 'restQuality2';
  static const dietHabitsClass = 'dietHabitsClass';
  static const targetSetsByMuscleUi = 'targetSetsByMuscleUi';
  static const finalTargetSetsByMuscleUi = 'finalTargetSetsByMuscleUi';

  // --- Volumen Individualizado (MEV/MRV por atleta) ---
  static const mevIndividual = 'mevIndividual'; // Double global
  static const mrvIndividual = 'mrvIndividual'; // Double global
  static const weightKg = 'weightKg'; // Double peso del atleta
  static const mevByMuscle = 'mevByMuscle'; // Map<String, double>
  static const mrvByMuscle = 'mrvByMuscle'; // Map<String, double>
  static const targetSetsByMuscle = 'targetSetsByMuscle'; // Map<String, int>

  // --- Periodización (Tab 3) ---
  static const macroPlan = 'macroPlan'; // Map serializado
  static const macroPlanSchemaVersion = 'macroPlanSchemaVersion';
  static const macroPlanStartDateIso = 'macroPlanStartDateIso';
  static const macroPlanActiveBlockId = 'macroPlanActiveBlockId';

  // --- Intensidad (Tab 2) ---
  // Guardar perfil por planId (selectedPlanStartDateIso) para que sincronice offline/online
  static const intensityProfileByPlanStartIso =
      'intensityProfileByPlanStartIso';

  // Perfiles de carga (ligero/medio/pesado)
  static const intensityProfiles = 'intensityProfiles';

  // Historial semanal real de series
  static const weeklyVolumeHistory = 'weeklyVolumeHistory';

  // Distribución porcentual de series por tipo de intensidad (heavy/medium/light)
  static const seriesTypePercentSplit = 'seriesTypePercentSplit';
  // ejemplo value: { "heavy": 20, "medium": 60, "light": 20 }

  // --- SSOT para Volume Over Prescribed (VOP) ---
  // Single source of truth escrito una sola vez en Tab 2, leído por Tabs 1, 3, 4
  // Contiene: totalSetsByMuscle, setsByMuscleAndIntensity, setsByMuscleAndPriority,
  // muscleGroupMapping, allMuscles, y flags de migración
  static const vopSnapshot = 'vopSnapshot';

  const TrainingExtraKeys._();
}
