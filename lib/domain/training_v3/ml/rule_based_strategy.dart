import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';

/// Estrategia de decisión basada en reglas científicas.
///
/// Referencias:
/// - Israetel et al. (2024): MEV/MAV/MRV framework, volume landmarks
/// - Schoenfeld et al. (2021): Dose-response relationship, proximity to failure
/// - Helms et al. (2023): RPE-RIR autoregulation, readiness markers
/// - NSCA (2022): Recovery, fatigue management, periodization
///
/// Utiliza un sistema de scoring multi-factor que evalúa:
/// 1. Readiness (sueño, recuperación, estrés)
/// 2. Fatiga (soreness, RIR optimality, trend)
/// 3. Volumen (MEV/MAV/MRV tolerance, histórico)
/// 4. Adherencia (consistencia, breaks, deloads)
/// 5. Fisiología (edad, sexo, nivel)
class RuleBasedStrategy extends BaseDecisionStrategy {
  @override
  String get name => 'RuleBasedStrategy';

  @override
  String get version => '1.0.0-Israetel2024-Schoenfeld2021-Helms2023';

  /// Pesos científicos para factor scoring
  static const readinessWeights = {
    'sleep': 0.35,
    'prs': 0.30,
    'stress': 0.20,
    'doms': 0.15,
  };

  static const fatigueWeights = {
    'soreness': 0.25,
    'rirOptimality': 0.40,
    'trend': 0.20,
    'performanceDecline': 0.15,
  };

  static const volumeWeights = {
    'mrvTolerance': 0.40,
    'volumeOptimality': 0.35,
    'avgWeeklySets': 0.25,
  };

  static const adhereWeights = {
    'consistency': 0.40,
    'deloadFreq': 0.30,
    'breaks': 0.30,
  };

  @override
  Future<TrainingDecision> decide(FeatureVector features) async {
    // ════════════════════════════════════════════════════════════
    // 1. READINESS SCORE (Helms 2023: sueño es 35% del readiness)
    // ════════════════════════════════════════════════════════════
    final readinessScores = <String, double>{
      'sleep': features.avgSleepHoursNorm, // 0-1
      'prs': features.perceivedRecoveryNorm, // 0-1 (inverted internally)
      'stress': 1.0 - features.stressLevelNorm, // lower stress = better
      'doms': 1.0 - features.soreness48hNorm, // less DOMS = better
    };

    final readinessScore = weightedScore(readinessScores, readinessWeights);

    // ════════════════════════════════════════════════════════════
    // 2. FATIGUE SCORE (Israetel 2024: fatiga es limitador principal)
    // ════════════════════════════════════════════════════════════
    final fatigueScores = <String, double>{
      'soreness': 1.0 - features.soreness48hNorm, // INVERTED
      'rirOptimality': features.rirOptimalityScore,
      'trend': features.performanceTrendEncoded,
      'performanceDecline': features.performanceTrendEncoded == 0.0 ? 1.0 : 0.0,
    };

    final fatigueScore = weightedScore(fatigueScores, fatigueWeights);

    // ════════════════════════════════════════════════════════════
    // 3. VOLUME SCORE (Schoenfeld 2021: dose-response crítico)
    // ════════════════════════════════════════════════════════════
    final volumeScores = <String, double>{
      'mrvTolerance': features.maxSetsToleratedNorm,
      'volumeOptimality': features.volumeOptimalityIndex,
      'avgWeeklySets': features.avgWeeklySetsNorm,
    };

    final volumeScore = weightedScore(volumeScores, volumeWeights);

    // ════════════════════════════════════════════════════════════
    // 4. ADHERENCE SCORE (Consistencia histórica)
    // ════════════════════════════════════════════════════════════
    final adhereScores = <String, double>{
      'consistency': features.adherenceHistorical,
      'deloadFreq': features.deloadFrequencyNorm,
      'breaks': 1.0 - features.periodBreaksNorm, // fewer breaks = better
    };

    final adhereScore = weightedScore(adhereScores, adhereWeights);

    // ════════════════════════════════════════════════════════════
    // 5. AGE-ADJUSTED RECOVERY (Fisiología)
    // ════════════════════════════════════════════════════════════
    // Helms et al.: Recuperación disminuye ~2% por década después de 30
    // features.ageYearsNorm: 0-1 (0=0 años, 1=100 años)
    final ageYears = features.ageYearsNorm * 100.0; // denormalize
    final ageRecoveryFactor = ageYears <= 30
        ? 1.0
        : 1.0 - ((ageYears - 30) * 0.02);

    // ════════════════════════════════════════════════════════════
    // 6. COMPOSITE TRAINING READINESS SCORE
    // ════════════════════════════════════════════════════════════
    // TRS = (Readiness * 0.40 + Fatiga_Inversa * 0.30 + Volumen * 0.20 + Adherencia * 0.10) * Age_Factor
    final trainingReadinessScore =
        (readinessScore * 0.40 +
            (1.0 - fatigueScore) * 0.30 +
            volumeScore * 0.20 +
            adhereScore * 0.10) *
        ageRecoveryFactor;

    // ════════════════════════════════════════════════════════════
    // 7. DECISION LOGIC (Basado en TRS)
    // ════════════════════════════════════════════════════════════
    String recommendation;
    String rationale;

    if (trainingReadinessScore < 0.3) {
      recommendation = 'REST';
      rationale =
          'Recuperación deficiente: readiness=${readinessScore.toStringAsFixed(2)}, fatiga alta (${(1 - fatigueScore).toStringAsFixed(2)})';
    } else if (trainingReadinessScore < 0.5) {
      recommendation = 'LIGHT';
      rationale =
          'Recuperación parcial: mantener movimiento (RPE <5) sin estrés metabólico';
    } else if (trainingReadinessScore < 0.65) {
      recommendation = 'MODERATE';
      rationale =
          'Readiness normal: entrenamiento estándar (RPE 5-7) con volumen histórico';
    } else if (trainingReadinessScore < 0.85) {
      recommendation = 'HIGH';
      rationale =
          'Recuperación óptima: volumen máximo tolerado (MRV target: ${features.volumeOptimalityIndex.toStringAsFixed(2)})';
    } else {
      // Detectar necesidad de deload (exceso crónico de volumen o fatiga acumulada)
      if (features.overreachingRisk > 0.7 &&
          features.deloadFrequencyNorm < 0.3) {
        recommendation = 'DELOAD';
        rationale =
            'Riesgo de overreaching alto: implementar deload (50-70% volumen) - Israetel MRV exceeded';
      } else {
        recommendation = 'HIGH';
        rationale =
            'Máxima capacidad: condiciones óptimas para sesión de volumen máximo';
      }
    }

    // ════════════════════════════════════════════════════════════
    // 8. VALIDACIONES CIENTÍFICAS
    // ════════════════════════════════════════════════════════════

    // Check 1: RIR Optimality (Schoenfeld 2021: 2-3 RIR es óptimo para hipertrofia)
    if (features.rirOptimalityScore < 0.5 && recommendation != 'REST') {
      rationale +=
          '\n⚠️ NOTA: RIR subóptimo (${features.averageRIRNorm.toStringAsFixed(2)}) - ajustar proximidad al fallo';
    }

    // Check 2: Volume-Fatigue Tradeoff
    if (volumeScore > 0.8 && fatigueScore > 0.7 && recommendation != 'REST') {
      rationale +=
          '\n⚠️ ALERTA: Alto volumen + fatiga acumulada - considerar LIGHT/DELOAD';
    }

    // Check 3: Recovery Capacity (Helms et al.)
    if (features.recoveryCapacity < 0.3 && recommendation == 'HIGH') {
      recommendation = 'MODERATE';
      rationale =
          'Capacidad de recuperación limitada (${features.recoveryCapacity.toStringAsFixed(2)}) - reducido a MODERATE';
    }

    // ════════════════════════════════════════════════════════════
    // 9. CONFIDENCE CALCULATION
    // ════════════════════════════════════════════════════════════
    // Mayor confianza cuando factores están alineados
    final readinessFatigueAlignment =
        1.0 - (readinessScore - (1.0 - fatigueScore)).abs();
    final adherenceAlignment =
        1.0 - (adhereScore - volumeScore).abs().clamp(0.0, 0.5) / 0.5;

    final confidence =
        (readinessFatigueAlignment * 0.5 +
                adherenceAlignment * 0.3 +
                features.trainingMaturity * 0.2)
            .clamp(0.5, 1.0); // Min confidence 50%

    // ════════════════════════════════════════════════════════════
    // 10. BUILD DECISION OBJECT
    // ════════════════════════════════════════════════════════════
    final factorScores = <String, double>{
      'trainingReadiness': trainingReadinessScore,
      'readiness': readinessScore,
      'fatigue': fatigueScore,
      'volume': volumeScore,
      'adherence': adhereScore,
      'ageRecoveryFactor': ageRecoveryFactor,
      'confidence': confidence,
    };

    final metadata = <String, dynamic>{
      'strategy': name,
      'version': version,
      'timestamp': DateTime.now().toIso8601String(),
      'subFactors': {
        'readiness': readinessScores,
        'fatigue': fatigueScores,
        'volume': volumeScores,
        'adhere': adhereScores,
      },
    };

    return TrainingDecision(
      recommendation: recommendation,
      confidence: confidence,
      rationale: rationale,
      factorScores: factorScores,
      metadata: metadata,
    );
  }

  @override
  Future<void> recordOutcome(
    TrainingDecision decision,
    Map<String, dynamic> outcome,
  ) async {
    // Placeholder: Aquí iría persistencia a Firestore para posterior reentrenamiento
    // outcome esperado: {
    //   'sessionRPEActual': 7.0,
    //   'setsCompleted': 24,
    //   'reactionScore': 8.0, // 1-10 cómo se sintió post-sesión
    //   'soreness48h': 6.0,
    // }
  }
}
