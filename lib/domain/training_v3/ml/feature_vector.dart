// NOTE: TrainingContext class was never implemented - ML dataset feature incomplete
// import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

/// Vector de características normalizado para ML.
///
/// Basado en investigación científica:
/// - Israetel et al. (2020-2024): MEV/MAV/MRV, volume landmarks
/// - Schoenfeld et al. (2017-2021): dose-response, proximity to failure
/// - Helms et al. (2018-2023): RPE/RIR autoregulation, readiness markers
/// - NSCA (2022): recovery, fatigue management
///
/// Schema version: 1.1.0 (corregido)
/// Features: 38 (24 numerical + 8 categorical + 6 derived)
/// Changes from 1.0.0:
///   - Added sessionDurationNorm
///   - Added restBetweenSetsNorm
///   - Fixed clientId (required parameter in fromContext)
///   - Fixed adherenceHistorical (prioritizes sessionCompletionRate)
class FeatureVector {
  // ════════════════════════════════════════════════════════════
  // NUMERICAL FEATURES (normalizadas 0-1)
  // ════════════════════════════════════════════════════════════

  /// Edad normalizada (0-100 años → 0.0-1.0)
  final double ageYearsNorm;

  /// Género codificado (male=1.0, female=0.0)
  final double genderMaleEncoded;

  /// Altura normalizada (140-220 cm → 0.0-1.0)
  final double heightCmNorm;

  /// Peso normalizado (40-160 kg → 0.0-1.0)
  final double weightKgNorm;

  /// BMI normalizado (15-40 → 0.0-1.0)
  final double bmiNorm;

  /// Años de entrenamiento continuo normalizado (0-30 años → 0.0-1.0)
  final double yearsTrainingNorm;

  /// Semanas consecutivas entrenando (0-52 semanas → 0.0-1.0)
  final double consecutiveWeeksNorm;

  /// Nivel de entrenamiento codificado
  /// beginner=0.2, intermediate=0.5, advanced=0.8
  final double trainingLevelEncoded;

  /// Sets promedio por músculo por semana (0-30 sets → 0.0-1.0)
  /// CRÍTICO: Input histórico real del usuario
  final double avgWeeklySetsNorm;

  /// Sets máximos tolerados (MRV individual) (0-40 sets → 0.0-1.0)
  final double maxSetsToleratedNorm;

  /// Ratio volumen/experiencia (sets / (años + 1))
  final double volumeToleranceRatio;

  /// Horas de sueño promedio (4-12 horas → 0.0-1.0)
  final double avgSleepHoursNorm;

  /// Perceived Recovery Status (PRS 1-10 → 0.0-1.0)
  /// Helms et al. (2018): readiness marker pre-sesión
  final double perceivedRecoveryNorm;

  /// Nivel de estrés (0-10 → 0.0-1.0)
  final double stressLevelNorm;

  /// Dolor muscular a las 48h (DOMS 0-10 → 0.0-1.0)
  final double soreness48hNorm;

  /// Duración de sesión normalizada (30-120 min → 0.0-1.0)
  /// Indica capacidad de tiempo del usuario
  final double sessionDurationNorm;

  /// Descanso entre series normalizado (30-300 seg → 0.0-1.0)
  /// Indica estilo de entrenamiento (metabolic vs strength)
  final double restBetweenSetsNorm;

  /// RIR promedio (0-5 RIR → 0.0-1.0)
  /// Schoenfeld (2021): proximity to failure
  final double averageRIRNorm;

  /// RPE promedio de sesión (1-10 RPE → 0.0-1.0)
  /// Helms RPE-RIR method
  final double averageSessionRPENorm;

  /// Qué tan cerca está del RIR óptimo (2-3 RIR = hipertrofia óptima)
  /// 1.0 = óptimo, 0.0 = muy desviado
  final double rirOptimalityScore;

  /// Frecuencia de deload (0-12 semanas → 0.0-1.0)
  final double deloadFrequencyNorm;

  /// Pausas >2 semanas en últimos 12 meses (0-6 pausas → 0.0-1.0)
  final double periodBreaksNorm;

  /// Adherencia histórica (0.0-1.0)
  /// Prioriza sessionCompletionRate si existe, fallback a parameter
  final double adherenceHistorical;

  /// Tendencia de rendimiento codificada
  /// improving=1.0, plateaued=0.5, declining=0.0
  final double performanceTrendEncoded;

  // ════════════════════════════════════════════════════════════
  // CATEGORICAL FEATURES (one-hot encoded)
  // ════════════════════════════════════════════════════════════

  /// Objetivo de entrenamiento one-hot
  /// {hypertrophy: 1.0/0.0, strength: 1.0/0.0, endurance: 1.0/0.0, general: 1.0/0.0}
  final Map<String, double> goalOneHot;

  /// Enfoque de entrenamiento one-hot
  /// {hypertrophy: 1.0/0.0, strength: 1.0/0.0, power: 1.0/0.0, mixed: 1.0/0.0}
  final Map<String, double> focusOneHot;

  // ════════════════════════════════════════════════════════════
  // DERIVED FEATURES (feature engineering científico)
  // ════════════════════════════════════════════════════════════

  /// Índice de fatiga acumulada (Helms et al. 2018)
  /// Fórmula: (10 - PRS) * RPE / 100
  /// Interpretación:
  /// - >0.5 = fatiga alta, considerar deload
  /// - 0.3-0.5 = fatiga moderada, mantener volumen
  /// - <0.3 = bien recuperado, puede progresar
  final double fatigueIndex;

  /// Capacidad de recuperación (Schoenfeld 2016)
  /// Fórmula: sleepNorm * (1 - stressNorm) * prsNorm
  /// Interpretación:
  /// - >0.7 = buena recuperación, puede manejar volumen alto
  /// - 0.4-0.7 = recuperación adecuada, volumen moderado
  /// - <0.4 = mala recuperación, reducir volumen
  final double recoveryCapacity;

  /// Madurez de entrenamiento (Israetel MRV progression)
  /// Fórmula: yearsTraining * (consecutiveWeeks / 52)
  /// Interpretación:
  /// - >3.0 = atleta maduro, puede tolerar MRV alto
  /// - 1.0-3.0 = intermedio, volumen progresivo
  /// - <1.0 = principiante, empezar conservador en MEV
  final double trainingMaturity;

  /// Riesgo de sobreentrenamiento (Israetel overreaching detection)
  /// Fórmula: (avgSets / maxSetsTolerated) * fatigueIndex
  /// Interpretación:
  /// - >0.8 = riesgo alto, deload inmediato
  /// - 0.5-0.8 = proximidad a MRV, monitorear
  /// - <0.5 = seguro, puede progresar
  final double overreachingRisk;

  /// Score de readiness compuesto (Helms RPE-RIR method)
  /// Fórmula: (prs/10) * (1 - fatigueIndex) * recoveryCapacity
  /// Interpretación:
  /// - >0.7 = listo para entrenar duro
  /// - 0.4-0.7 = sesión moderada
  /// - <0.4 = necesita deload o descanso
  final double readinessScore;

  /// Índice de volumen óptimo (Schoenfeld dose-response)
  /// Fórmula: avgSets / referenceMEV(level, goal)
  /// Interpretación:
  /// - 1.0 = en MEV (mínimo efectivo)
  /// - 2.0 = en MAV (óptimo para hipertrofia)
  /// - 3.0 = cerca de MRV (máximo recuperable)
  /// - >3.0 = excediendo MRV, riesgo overtraining
  final double volumeOptimalityIndex;

  // ════════════════════════════════════════════════════════════
  // METADATA (trazabilidad, NO entra en tensor)
  // ════════════════════════════════════════════════════════════

  /// clientId real del usuario (no timestamp)
  final String clientId;
  final DateTime timestamp;
  final int schemaVersion;

  const FeatureVector({
    // Numerical
    required this.ageYearsNorm,
    required this.genderMaleEncoded,
    required this.heightCmNorm,
    required this.weightKgNorm,
    required this.bmiNorm,
    required this.yearsTrainingNorm,
    required this.consecutiveWeeksNorm,
    required this.trainingLevelEncoded,
    required this.avgWeeklySetsNorm,
    required this.maxSetsToleratedNorm,
    required this.volumeToleranceRatio,
    required this.avgSleepHoursNorm,
    required this.perceivedRecoveryNorm,
    required this.stressLevelNorm,
    required this.soreness48hNorm,
    required this.sessionDurationNorm,
    required this.restBetweenSetsNorm,
    required this.averageRIRNorm,
    required this.averageSessionRPENorm,
    required this.rirOptimalityScore,
    required this.deloadFrequencyNorm,
    required this.periodBreaksNorm,
    required this.adherenceHistorical,
    required this.performanceTrendEncoded,
    // Categorical
    required this.goalOneHot,
    required this.focusOneHot,
    // Derived
    required this.fatigueIndex,
    required this.recoveryCapacity,
    required this.trainingMaturity,
    required this.overreachingRisk,
    required this.readinessScore,
    required this.volumeOptimalityIndex,
    // Metadata
    required this.clientId,
    required this.timestamp,
    this.schemaVersion = 2,
  });

  /// Convierte a tensor 1D para TensorFlow Lite o Firebase ML
  ///
  /// CRÍTICO: Orden DEBE ser el mismo que el modelo entrenado
  /// Total: 38 features
  List<double> toTensor() {
    return [
      // Biological (5)
      ageYearsNorm,
      genderMaleEncoded,
      heightCmNorm,
      weightKgNorm,
      bmiNorm,

      // Experience (3)
      yearsTrainingNorm,
      consecutiveWeeksNorm,
      trainingLevelEncoded,

      // Volume (3)
      avgWeeklySetsNorm,
      maxSetsToleratedNorm,
      volumeToleranceRatio,

      // Recovery (6)
      avgSleepHoursNorm,
      perceivedRecoveryNorm,
      stressLevelNorm,
      soreness48hNorm,
      sessionDurationNorm,
      restBetweenSetsNorm,

      // Intensity (3)
      averageRIRNorm,
      averageSessionRPENorm,
      rirOptimalityScore,

      // Consistency (3)
      deloadFrequencyNorm,
      periodBreaksNorm,
      adherenceHistorical,

      // Performance (1)
      performanceTrendEncoded,

      // Derived (6)
      fatigueIndex,
      recoveryCapacity,
      trainingMaturity,
      overreachingRisk,
      readinessScore,
      volumeOptimalityIndex,

      // One-hot goal (4) - expandir Map a valores
      goalOneHot['hypertrophy'] ?? 0.0,
      goalOneHot['strength'] ?? 0.0,
      goalOneHot['endurance'] ?? 0.0,
      goalOneHot['general'] ?? 0.0,

      // One-hot focus (4) - expandir Map a valores
      focusOneHot['hypertrophy'] ?? 0.0,
      focusOneHot['strength'] ?? 0.0,
      focusOneHot['power'] ?? 0.0,
      focusOneHot['mixed'] ?? 0.0,
    ];
  }

  /// Convierte a JSON para Firestore, export CSV, o REST API
  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'clientId': clientId,
        'timestamp': timestamp.toIso8601String(),
        'schemaVersion': schemaVersion,
      },
      'biological': {
        'age_norm': ageYearsNorm,
        'gender_male': genderMaleEncoded,
        'height_norm': heightCmNorm,
        'weight_norm': weightKgNorm,
        'bmi_norm': bmiNorm,
      },
      'experience': {
        'years_training_norm': yearsTrainingNorm,
        'consecutive_weeks_norm': consecutiveWeeksNorm,
        'level_encoded': trainingLevelEncoded,
      },
      'volume': {
        'avg_sets_norm': avgWeeklySetsNorm,
        'max_sets_norm': maxSetsToleratedNorm,
        'tolerance_ratio': volumeToleranceRatio,
      },
      'recovery': {
        'sleep_norm': avgSleepHoursNorm,
        'prs_norm': perceivedRecoveryNorm,
        'stress_norm': stressLevelNorm,
        'doms_norm': soreness48hNorm,
        'session_duration_norm': sessionDurationNorm,
        'rest_between_sets_norm': restBetweenSetsNorm,
      },
      'intensity': {
        'rir_norm': averageRIRNorm,
        'rpe_norm': averageSessionRPENorm,
        'rir_optimality': rirOptimalityScore,
      },
      'consistency': {
        'deload_freq_norm': deloadFrequencyNorm,
        'breaks_norm': periodBreaksNorm,
        'adherence': adherenceHistorical,
      },
      'performance': {'trend_encoded': performanceTrendEncoded},
      'derived': {
        'fatigue_index': fatigueIndex,
        'recovery_capacity': recoveryCapacity,
        'training_maturity': trainingMaturity,
        'overreaching_risk': overreachingRisk,
        'readiness_score': readinessScore,
        'volume_optimality': volumeOptimalityIndex,
      },
      'categorical': {'goal': goalOneHot, 'focus': focusOneHot},
    };
  }

  /// COMMENTED OUT: TrainingContext class was never implemented
  /// This factory method was planned for ML dataset feature but TrainingContext
  /// class doesn't exist. Keeping code commented for future reference.
  ///
  /*
  /// Crea desde TrainingContext V2
  factory FeatureVector.fromContext(
    TrainingContext context, {
    required String clientId,
    double? historicalAdherence,
  }) {
    final interview = context.interview;
    final athlete = context.athlete;
    final meta = context.meta;

    // ════════════════════════════════════════════════════════════
    // NORMALIZACIÓN (min-max scaling)
    // ════════════════════════════════════════════════════════════

    final ageNorm = (athlete.ageYears ?? 30) / 100.0;
    final genderMale = athlete.gender == Gender.male ? 1.0 : 0.0;
    final heightNorm = ((athlete.heightCm ?? 170) - 140) / 80.0;
    final weightNorm = ((athlete.weightKg ?? 70) - 40) / 120.0;
    final bmi =
        (athlete.weightKg ?? 70) /
        (((athlete.heightCm ?? 170) / 100) * ((athlete.heightCm ?? 170) / 100));
    final bmiNorm = (bmi - 15) / 25.0;

    final yearsNorm = interview.yearsTrainingContinuous / 30.0;
    final weeksNorm = interview.consecutiveWeeksTraining / 52.0;

    double levelEncoded = 0.5; // intermediate default
    switch (meta.level) {
      case TrainingLevel.beginner:
        levelEncoded = 0.2;
        break;
      case TrainingLevel.intermediate:
        levelEncoded = 0.5;
        break;
      case TrainingLevel.advanced:
        levelEncoded = 0.8;
        break;
      default:
        levelEncoded = 0.5;
    }

    final setsNorm = interview.avgWeeklySetsPerMuscle / 30.0;
    final maxSetsNorm =
        (interview.maxWeeklySetsBeforeOverreaching ?? 25) / 40.0;
    final volRatio =
        interview.avgWeeklySetsPerMuscle /
        (interview.yearsTrainingContinuous + 1);

    final sleepNorm = (interview.avgSleepHours - 4.0) / 8.0;
    final prsNorm = interview.perceivedRecoveryStatus / 10.0;
    final stressNorm = interview.stressLevel / 10.0;
    final domsNorm = (interview.soreness48hAverage ?? 5) / 10.0;

    final sessionNorm = (interview.sessionDurationMinutes - 30) / 90.0;
    final restNorm = (interview.restBetweenSetsSeconds - 30) / 270.0;

    final rirNorm = interview.averageRIR / 5.0;
    final rpeNorm = interview.averageSessionRPE / 10.0;

    // RIR optimality: 2-3 RIR es óptimo para hipertrofia (Schoenfeld 2021)
    final rirOptimal =
        1.0 - ((interview.averageRIR - 2.5).abs() / 2.5).clamp(0.0, 1.0);

    final deloadNorm = (interview.deloadFrequencyWeeks ?? 6) / 12.0;
    final breaksNorm = (interview.periodBreaksLast12Months ?? 1) / 6.0;

    final adherence =
        interview.sessionCompletionRate ?? historicalAdherence ?? 0.8;

    double trendEncoded = 0.5; // plateau default
    switch (interview.performanceTrend) {
      case PerformanceTrend.improving:
        trendEncoded = 1.0;
        break;
      case PerformanceTrend.plateaued:
        trendEncoded = 0.5;
        break;
      case PerformanceTrend.declining:
        trendEncoded = 0.0;
        break;
      default:
        trendEncoded = 0.5;
    }

    // ════════════════════════════════════════════════════════════
    // ONE-HOT ENCODING
    // ════════════════════════════════════════════════════════════

    final goalOneHot = <String, double>{
      'hypertrophy': meta.goal == TrainingGoal.hypertrophy ? 1.0 : 0.0,
      'strength': meta.goal == TrainingGoal.strength ? 1.0 : 0.0,
      'endurance': meta.goal == TrainingGoal.endurance ? 1.0 : 0.0,
      'general': meta.goal == TrainingGoal.generalFitness ? 1.0 : 0.0,
    };

    final focusOneHot = <String, double>{
      'hypertrophy': meta.focus == TrainingFocus.hypertrophy ? 1.0 : 0.0,
      'strength': meta.focus == TrainingFocus.strength ? 1.0 : 0.0,
      'power': meta.focus == TrainingFocus.power ? 1.0 : 0.0,
      'mixed':
          (meta.focus == TrainingFocus.mixed ||
              meta.focus == TrainingFocus.gluteSpecialization)
          ? 1.0
          : 0.0,
    };

    // ════════════════════════════════════════════════════════════
    // DERIVED FEATURES (feature engineering científico)
    // ════════════════════════════════════════════════════════════

    /// Fatigue Index (Helms et al. 2018 - RPE autoregulation)
    final fatigueIdx =
        (10.0 - interview.perceivedRecoveryStatus) *
        interview.averageSessionRPE /
        100.0;

    /// Recovery Capacity (Schoenfeld 2016 - sleep + stress + readiness)
    final recovCap = sleepNorm * (1.0 - stressNorm) * prsNorm;

    /// Training Maturity (Israetel MRV progression)
    final maturity = interview.yearsTrainingContinuous * weeksNorm;

    /// Overreaching Risk (Israetel overtraining detection)
    final maxSets =
        interview.maxWeeklySetsBeforeOverreaching ??
        (interview.avgWeeklySetsPerMuscle * 1.5);
    final volProximity = interview.avgWeeklySetsPerMuscle / maxSets;
    final overreachRisk = volProximity * fatigueIdx;

    /// Readiness Score (Helms RPE-RIR composite)
    final readiness = prsNorm * (1.0 - fatigueIdx) * recovCap;

    /// Volume Optimality Index (Schoenfeld dose-response curve)
    /// MEV reference: beginner=10, inter=12, adv=15 sets/muscle/week
    double referenceMEV = 12.0; // intermediate default
    switch (meta.level) {
      case TrainingLevel.beginner:
        referenceMEV = 10.0;
        break;
      case TrainingLevel.intermediate:
        referenceMEV = 12.0;
        break;
      case TrainingLevel.advanced:
        referenceMEV = 15.0;
        break;
      default:
        referenceMEV = 12.0;
    }
    final volOptimality = interview.avgWeeklySetsPerMuscle / referenceMEV;

    return FeatureVector(
      // Biological
      ageYearsNorm: ageNorm.clamp(0.0, 1.0),
      genderMaleEncoded: genderMale,
      heightCmNorm: heightNorm.clamp(0.0, 1.0),
      weightKgNorm: weightNorm.clamp(0.0, 1.0),
      bmiNorm: bmiNorm.clamp(0.0, 1.0),

      // Experience
      yearsTrainingNorm: yearsNorm.clamp(0.0, 1.0),
      consecutiveWeeksNorm: weeksNorm.clamp(0.0, 1.0),
      trainingLevelEncoded: levelEncoded,

      // Volume
      avgWeeklySetsNorm: setsNorm.clamp(0.0, 1.0),
      maxSetsToleratedNorm: maxSetsNorm.clamp(0.0, 1.0),
      volumeToleranceRatio: (volRatio.clamp(0.0, 5.0) / 5.0),

      // Recovery
      avgSleepHoursNorm: sleepNorm.clamp(0.0, 1.0),
      perceivedRecoveryNorm: prsNorm.clamp(0.0, 1.0),
      stressLevelNorm: stressNorm.clamp(0.0, 1.0),
      soreness48hNorm: domsNorm.clamp(0.0, 1.0),
      sessionDurationNorm: sessionNorm.clamp(0.0, 1.0),
      restBetweenSetsNorm: restNorm.clamp(0.0, 1.0),

      // Intensity
      averageRIRNorm: rirNorm.clamp(0.0, 1.0),
      averageSessionRPENorm: rpeNorm.clamp(0.0, 1.0),
      rirOptimalityScore: rirOptimal,

      // Consistency
      deloadFrequencyNorm: deloadNorm.clamp(0.0, 1.0),
      periodBreaksNorm: breaksNorm.clamp(0.0, 1.0),
      adherenceHistorical: adherence.clamp(0.0, 1.0),

      // Performance
      performanceTrendEncoded: trendEncoded,

      // Categorical
      goalOneHot: goalOneHot,
      focusOneHot: focusOneHot,

      // Derived
      fatigueIndex: fatigueIdx.clamp(0.0, 1.0),
      recoveryCapacity: recovCap.clamp(0.0, 1.0),
      trainingMaturity: (maturity.clamp(0.0, 10.0) / 10.0),
      overreachingRisk: overreachRisk.clamp(0.0, 1.0),
      readinessScore: readiness.clamp(0.0, 1.0),
      volumeOptimalityIndex: (volOptimality.clamp(0.0, 3.0) / 3.0),

      // Metadata
      clientId: clientId,
      timestamp: context.asOfDate,
      schemaVersion: 2,
    );
  }
  */

  /// Feature importance weights (para debugging/explicabilidad)
  /// Basado en consenso científico Israetel/Schoenfeld/Helms
  static const Map<String, double> featureImportance = {
    // Top 5 más importantes
    'volumeOptimalityIndex': 1.00, // #1 - Dose-response (Schoenfeld)
    'readinessScore': 0.95, // #2 - Readiness compuesto (Helms)
    'overreachingRisk': 0.90, // #3 - Safety first (Israetel)
    'fatigueIndex': 0.85, // #4 - Fatigue management (Helms)
    'trainingMaturity': 0.80, // #5 - Adaptación acumulada (Israetel)
    // Moderadamente importantes
    'perceivedRecoveryNorm': 0.70,
    'averageRIRNorm': 0.65,
    'avgWeeklySetsNorm': 0.60,
    'avgSleepHoursNorm': 0.55,

    // Contextuales
    'performanceTrendEncoded': 0.50,
    'adherenceHistorical': 0.45,
    'consecutiveWeeksNorm': 0.40,
    'sessionDurationNorm': 0.35,
    'restBetweenSetsNorm': 0.30,

    // Menos críticos (pero útiles)
    'ageYearsNorm': 0.30,
    'stressLevelNorm': 0.25,
    'genderMaleEncoded': 0.20,
  };

  @override
  String toString() {
    return 'FeatureVector(\n'
        '  readiness: ${readinessScore.toStringAsFixed(2)},\n'
        '  fatigue: ${fatigueIndex.toStringAsFixed(2)},\n'
        '  overreachRisk: ${overreachingRisk.toStringAsFixed(2)},\n'
        '  volOptimality: ${volumeOptimalityIndex.toStringAsFixed(2)}\n'
        ')';
  }
}
