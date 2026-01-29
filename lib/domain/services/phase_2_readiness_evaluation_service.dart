import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart'
    show DerivedTrainingContext;

/// Nivel de readiness (disposición) del atleta para entrenar
enum ReadinessLevel {
  critical, // Requiere deload o descanso
  low, // Reducir volumen significativamente
  moderate, // Mantener volumen conservador
  good, // Volumen normal
  excellent, // Puede manejar volumen alto
}

/// Resultado de la Fase 2: Evaluación de readiness
class Phase2Result {
  final ReadinessLevel readinessLevel;
  final double readinessScore; // 0.0 - 1.0
  final double
  volumeAdjustmentFactor; // Multiplicador para volumen (0.5 - 1.15)
  final List<DecisionTrace> decisions;
  final Map<String, dynamic> metrics;
  final List<String> recommendations;
  final Map<MuscleGroup, ReadinessLevel> readinessByMuscle;

  const Phase2Result({
    required this.readinessLevel,
    required this.readinessScore,
    required this.volumeAdjustmentFactor,
    required this.decisions,
    required this.metrics,
    this.readinessByMuscle = const {},
    this.recommendations = const [],
  });

  bool get needsDeload => readinessLevel == ReadinessLevel.critical;
  bool get needsVolumeReduction =>
      readinessLevel == ReadinessLevel.low ||
      readinessLevel == ReadinessLevel.critical;
}

/// Fase 2: Evaluación de readiness (disposición física y mental para entrenar).
///
/// Analiza múltiples factores de recuperación para determinar si el atleta
/// está listo para el volumen planificado o necesita ajustes.
///
/// Factores evaluados:
/// - Calidad y cantidad de sueño
/// - Nivel de fatiga acumulada
/// - Dolor muscular (DOMS)
/// - Estrés percibido
/// - Motivación
/// - Adherencia histórica
/// - RPE promedio reciente
///
/// REGLA: En duda, ser conservador. Mejor subestimar que sobreentrenar.
class Phase2ReadinessEvaluationService {
  /// Evalúa el readiness del atleta basándose en datos de perfil, historial y feedback
  Phase2Result evaluateReadiness({
    required TrainingProfile profile,
    TrainingHistory? history,
    TrainingFeedback? latestFeedback,
  }) {
    return evaluateReadinessWithContext(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      derivedContext: null,
    );
  }

  /// Variante extendida que acepta DerivedTrainingContext sin romper la API existente.
  Phase2Result evaluateReadinessWithContext({
    required TrainingProfile profile,
    TrainingHistory? history,
    TrainingFeedback? latestFeedback,
    DerivedTrainingContext? derivedContext,
  }) {
    final decisions = <DecisionTrace>[];
    final metrics = <String, dynamic>{};
    final recommendations = <String>[];

    // Fecha de referencia para determinismo temporal
    final referenceDate = derivedContext?.referenceDate ?? DateTime(2025, 1, 1);

    // 1. Evaluar sueño (peso: 30%)
    final sleepScore = _evaluateSleep(
      profile,
      latestFeedback,
      decisions,
      recommendations,
      referenceDate,
    );
    metrics['sleepScore'] = sleepScore;

    // 2. Evaluar fatiga y recuperación (peso: 25%)
    final fatigueScore = _evaluateFatigue(
      profile,
      latestFeedback,
      decisions,
      recommendations,
      referenceDate,
    );
    metrics['fatigueScore'] = fatigueScore;

    // 3. Evaluar estrés (peso: 20%)
    final stressScore = _evaluateStress(
      profile,
      latestFeedback,
      decisions,
      recommendations,
      referenceDate,
    );
    metrics['stressScore'] = stressScore;

    // 4. Evaluar motivación (peso: 15%)
    final motivationScore = _evaluateMotivation(
      profile,
      latestFeedback,
      decisions,
      recommendations,
      referenceDate,
    );
    metrics['motivationScore'] = motivationScore;

    // 5. Evaluar historial de adherencia y RPE (peso: 10%)
    final historyScore = _evaluateHistory(
      history,
      decisions,
      recommendations,
      referenceDate,
    );
    metrics['historyScore'] = historyScore;

    // 6. Calcular score ponderado de readiness
    final readinessScore =
        (sleepScore * 0.30) +
        (fatigueScore * 0.25) +
        (stressScore * 0.20) +
        (motivationScore * 0.15) +
        (historyScore * 0.10);

    metrics['readinessScore'] = readinessScore;

    // 7. Determinar nivel de readiness
    final readinessLevel = _determineReadinessLevel(readinessScore, decisions);

    // 8. Calcular factor de ajuste de volumen
    final volumeAdjustmentFactor = _calculateVolumeAdjustment(
      readinessLevel,
      readinessScore,
      profile,
      decisions,
    );

    metrics['volumeAdjustmentFactor'] = volumeAdjustmentFactor;

    // 9. Readiness local por músculo/patrón
    final readinessByMuscle = _buildLocalReadiness(
      baseLevel: readinessLevel,
      profile: profile,
      derivedContext: derivedContext,
      decisions: decisions,
    );

    // 10. Decisión final
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase2ReadinessEvaluation',
        category: 'final_assessment',
        description:
            'Readiness: ${readinessLevel.name}, Score: ${(readinessScore * 100).toStringAsFixed(1)}%, '
            'Ajuste volumen: ${(volumeAdjustmentFactor * 100).toStringAsFixed(0)}%',
        context: metrics,
        action: volumeAdjustmentFactor < 0.85
            ? 'Reducir volumen significativamente'
            : (volumeAdjustmentFactor > 1.0
                  ? 'Puede manejar volumen elevado'
                  : 'Mantener volumen estándar'),
      ),
    );

    return Phase2Result(
      readinessLevel: readinessLevel,
      readinessScore: readinessScore,
      volumeAdjustmentFactor: volumeAdjustmentFactor,
      decisions: decisions,
      metrics: metrics,
      readinessByMuscle: readinessByMuscle,
      recommendations: recommendations,
    );
  }

  Map<MuscleGroup, ReadinessLevel> _buildLocalReadiness({
    required ReadinessLevel baseLevel,
    required TrainingProfile profile,
    required DerivedTrainingContext? derivedContext,
    required List<DecisionTrace> decisions,
  }) {
    // Inicial: todos los músculos con el nivel global
    final map = <MuscleGroup, ReadinessLevel>{
      for (final m in MuscleGroup.values) m: baseLevel,
    };

    // Ajuste por lesiones/patrones contraindicados → nivel low
    final affected = <MuscleGroup>{};
    if (derivedContext != null &&
        derivedContext.contraindicatedPatterns.isNotEmpty) {
      for (final pattern in derivedContext.contraindicatedPatterns) {
        final muscles = _mapPatternToMuscles(pattern);
        for (final m in muscles) {
          map[m] = ReadinessLevel.low;
          affected.add(m);
        }
      }
    }
    if (affected.isNotEmpty) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase2ReadinessEvaluation',
          category: 'local_readiness_adjustment',
          description: 'Readiness local reducido por lesiones/patrones',
          context: {'affectedMuscles': affected.map((e) => e.name).toList()},
        ),
      );
    }

    // Ajuste por sexo (mujer tolera ligeramente más en glutes/quads/hamstrings)
    final gender = profile.gender;
    final bumped = <MuscleGroup>{};
    if (gender == Gender.female) {
      for (final m in const [
        MuscleGroup.glutes,
        MuscleGroup.quads,
        MuscleGroup.hamstrings,
      ]) {
        final current = map[m] ?? baseLevel;
        // No sobrescribir una restricción por lesión (low)
        if (current != ReadinessLevel.low) {
          final newLevel = _bumpOne(current);
          if (newLevel != current) {
            map[m] = newLevel;
            bumped.add(m);
          }
        }
      }
    }
    if (bumped.isNotEmpty) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase2ReadinessEvaluation',
          category: 'gender_specific_adjustment',
          description: 'Ajuste local por sexo (mujer)',
          context: {'bumpedMuscles': bumped.map((e) => e.name).toList()},
        ),
      );
    }

    return map;
  }

  List<MuscleGroup> _mapPatternToMuscles(String pattern) {
    final p = pattern.toLowerCase();
    if (p.contains('lumbar') || p.contains('lower_back')) {
      return const [
        MuscleGroup.back,
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
      ];
    }
    if (p.contains('hinge') || p.contains('deadlift')) {
      return const [
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.back,
      ];
    }
    if (p.contains('squat') || p.contains('knee')) {
      return const [
        MuscleGroup.quads,
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
      ];
    }
    if (p.contains('bench') || p.contains('press')) {
      return const [
        MuscleGroup.chest,
        MuscleGroup.shoulders,
        MuscleGroup.triceps,
      ];
    }
    if (p.contains('shoulder')) {
      return const [MuscleGroup.shoulders];
    }
    if (p.contains('pull') || p.contains('row')) {
      return const [MuscleGroup.back, MuscleGroup.lats, MuscleGroup.biceps];
    }
    if (p.contains('hip')) {
      return const [
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
        MuscleGroup.quads,
      ];
    }
    if (p.contains('elbow')) {
      return const [
        MuscleGroup.biceps,
        MuscleGroup.triceps,
        MuscleGroup.forearms,
      ];
    }
    // Fallback: full body o sin mapeo claro
    return const [MuscleGroup.fullBody];
  }

  ReadinessLevel _bumpOne(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.critical:
        return ReadinessLevel.low;
      case ReadinessLevel.low:
        return ReadinessLevel.moderate;
      case ReadinessLevel.moderate:
        return ReadinessLevel.good;
      case ReadinessLevel.good:
        return ReadinessLevel.excellent;
      case ReadinessLevel.excellent:
        return ReadinessLevel.excellent;
    }
  }

  /// Evalúa la calidad y cantidad de sueño
  double _evaluateSleep(
    TrainingProfile profile,
    TrainingFeedback? feedback,
    List<DecisionTrace> decisions,
    List<String> recommendations,
    DateTime referenceDate,
  ) {
    final sleepHours = feedback?.sleepHours ?? profile.avgSleepHours;

    double score;
    String description;
    String? action;

    if (sleepHours >= 8.0) {
      score = 1.0;
      description = 'Sueño óptimo (${sleepHours.toStringAsFixed(1)}h ≥ 8h)';
    } else if (sleepHours >= 7.0) {
      score = 0.8;
      description = 'Sueño adecuado (${sleepHours.toStringAsFixed(1)}h)';
    } else if (sleepHours >= 6.0) {
      score = 0.6;
      description = 'Sueño subóptimo (${sleepHours.toStringAsFixed(1)}h)';
      action = 'Considerar reducir volumen o intensidad';
      recommendations.add('Mejorar higiene del sueño (objetivo: 7-9h)');
    } else {
      score = 0.3;
      description =
          'Sueño insuficiente (${sleepHours.toStringAsFixed(1)}h < 6h)';
      action = 'Reducir volumen 20-30% por mala recuperación';
      recommendations.add('CRÍTICO: Priorizar sueño antes de aumentar volumen');
    }

    decisions.add(
      DecisionTrace(
        phase: 'Phase2ReadinessEvaluation',
        timestamp: referenceDate,
        category: 'sleep_evaluation',
        description: description,
        severity: score < 0.6 ? 'warning' : 'info',
        context: {'sleepHours': sleepHours, 'score': score},
        action: action,
      ),
    );

    return score;
  }

  /// Evalúa la fatiga acumulada y DOMS
  double _evaluateFatigue(
    TrainingProfile profile,
    TrainingFeedback? feedback,
    List<DecisionTrace> decisions,
    List<String> recommendations,
    DateTime referenceDate,
  ) {
    final fatigue = feedback?.fatigue ?? 5.0;
    final soreness = feedback?.soreness ?? profile.sorenessLevel ?? 5.0;

    // Combinar fatiga y dolor muscular
    final combinedFatigue = (fatigue + soreness) / 2.0;

    double score;
    String description;
    String? action;

    if (combinedFatigue <= 3.0) {
      score = 1.0;
      description =
          'Recuperación excelente (fatiga: ${combinedFatigue.toStringAsFixed(1)}/10)';
    } else if (combinedFatigue <= 5.0) {
      score = 0.8;
      description =
          'Recuperación buena (fatiga: ${combinedFatigue.toStringAsFixed(1)}/10)';
    } else if (combinedFatigue <= 7.0) {
      score = 0.6;
      description =
          'Fatiga moderada (${combinedFatigue.toStringAsFixed(1)}/10)';
      action = 'Mantener volumen conservador';
      recommendations.add('Monitorear fatiga semanalmente');
    } else {
      score = 0.3;
      description = 'Fatiga alta (${combinedFatigue.toStringAsFixed(1)}/10)';
      action = 'Reducir volumen 10-20% o incluir semana deload';
      recommendations.add('Considerar semana de descarga activa');
    }

    decisions.add(
      DecisionTrace(
        phase: 'Phase2ReadinessEvaluation',
        timestamp: referenceDate,
        category: 'fatigue_evaluation',
        description: description,
        severity: score < 0.6 ? 'warning' : 'info',
        context: {
          'fatigue': fatigue,
          'soreness': soreness,
          'combined': combinedFatigue,
          'score': score,
        },
        action: action,
      ),
    );

    return score;
  }

  /// Evalúa el nivel de estrés percibido
  double _evaluateStress(
    TrainingProfile profile,
    TrainingFeedback? feedback,
    List<DecisionTrace> decisions,
    List<String> recommendations,
    DateTime referenceDate,
  ) {
    final stressLevel = feedback?.stressLevel ?? 5.0;

    double score;
    String description;
    String? action;

    if (stressLevel <= 3.0) {
      score = 1.0;
      description = 'Estrés bajo (${stressLevel.toStringAsFixed(1)}/10)';
    } else if (stressLevel <= 5.0) {
      score = 0.8;
      description = 'Estrés moderado (${stressLevel.toStringAsFixed(1)}/10)';
    } else if (stressLevel <= 7.0) {
      score = 0.6;
      description = 'Estrés elevado (${stressLevel.toStringAsFixed(1)}/10)';
      action = 'Reducir volumen si se combina con sueño pobre';
      recommendations.add('Considerar técnicas de manejo de estrés');
    } else {
      score = 0.4;
      description = 'Estrés muy alto (${stressLevel.toStringAsFixed(1)}/10)';
      action = 'Reducir volumen e intensidad, priorizar recuperación';
      recommendations.add(
        'CRÍTICO: Estrés afecta recuperación - considerar reducir frecuencia',
      );
    }

    decisions.add(
      DecisionTrace(
        phase: 'Phase2ReadinessEvaluation',
        timestamp: referenceDate,
        category: 'stress_evaluation',
        description: description,
        severity: score < 0.6 ? 'warning' : 'info',
        context: {'stressLevel': stressLevel, 'score': score},
        action: action,
      ),
    );

    return score;
  }

  /// Evalúa la motivación del atleta
  double _evaluateMotivation(
    TrainingProfile profile,
    TrainingFeedback? feedback,
    List<DecisionTrace> decisions,
    List<String> recommendations,
    DateTime referenceDate,
  ) {
    final motivation = feedback?.motivation ?? profile.motivationLevel ?? 7.0;

    double score;
    String description;
    String? action;

    if (motivation >= 8.0) {
      score = 1.0;
      description =
          'Motivación excelente (${motivation.toStringAsFixed(1)}/10)';
    } else if (motivation >= 6.0) {
      score = 0.8;
      description = 'Motivación buena (${motivation.toStringAsFixed(1)}/10)';
    } else if (motivation >= 4.0) {
      score = 0.6;
      description = 'Motivación moderada (${motivation.toStringAsFixed(1)}/10)';
      action = 'Considerar variedad en el plan';
      recommendations.add('Incluir ejercicios preferidos del cliente');
    } else {
      score = 0.4;
      description = 'Motivación baja (${motivation.toStringAsFixed(1)}/10)';
      action = 'Simplificar plan, reducir frecuencia, enfocarse en disfrute';
      recommendations.add('Revisar objetivos y expectativas con el cliente');
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase2ReadinessEvaluation',
        category: 'motivation_evaluation',
        description: description,
        context: {'motivation': motivation, 'score': score},
        action: action,
        timestamp: referenceDate,
      ),
    );

    return score;
  }

  /// Evalúa el historial de adherencia y RPE
  double _evaluateHistory(
    TrainingHistory? history,
    List<DecisionTrace> decisions,
    List<String> recommendations,
    DateTime referenceDate,
  ) {
    if (history == null || !history.hasData) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase2ReadinessEvaluation',
          category: 'history_evaluation',
          description: 'Sin historial disponible',
          action: 'Se usará enfoque conservador',
          timestamp: referenceDate,
        ),
      );
      return 0.7; // Score neutro conservador
    }

    final adherence = history.averageAdherence;
    final avgRpe = history.averageRpe;

    double score;
    String description;

    // Evaluar adherencia
    if (adherence >= 0.85) {
      score = 1.0;
      description =
          'Adherencia excelente (${(adherence * 100).toStringAsFixed(1)}%)';
    } else if (adherence >= 0.7) {
      score = 0.8;
      description =
          'Adherencia buena (${(adherence * 100).toStringAsFixed(1)}%)';
    } else if (adherence >= 0.5) {
      score = 0.6;
      description =
          'Adherencia moderada (${(adherence * 100).toStringAsFixed(1)}%)';
      recommendations.add('Revisar barreras para adherencia');
    } else {
      score = 0.4;
      description =
          'Adherencia baja (${(adherence * 100).toStringAsFixed(1)}%)';
      recommendations.add('CRÍTICO: Simplificar plan o ajustar expectativas');
    }

    // Ajustar por RPE promedio (si RPE muy alto, puede indicar sobreentrenamiento)
    if (avgRpe > 8.5) {
      score *= 0.9;
      recommendations.add(
        'RPE históricamente alto - considerar reducir intensidad',
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase2ReadinessEvaluation',
        category: 'history_evaluation',
        description: description,
        context: {
          'adherence': adherence,
          'avgRpe': avgRpe,
          'totalSessions': history.totalSessions,
          'score': score,
        },
      ),
    );

    return score;
  }

  /// Determina el nivel de readiness basado en el score
  ReadinessLevel _determineReadinessLevel(
    double score,
    List<DecisionTrace> decisions,
  ) {
    ReadinessLevel level;

    if (score >= 0.85) {
      level = ReadinessLevel.excellent;
    } else if (score >= 0.7) {
      level = ReadinessLevel.good;
    } else if (score >= 0.55) {
      level = ReadinessLevel.moderate;
    } else if (score >= 0.4) {
      level = ReadinessLevel.low;
    } else {
      level = ReadinessLevel.critical;
    }

    return level;
  }

  /// Calcula el factor de ajuste de volumen basado en readiness
  double _calculateVolumeAdjustment(
    ReadinessLevel level,
    double score,
    TrainingProfile profile,
    List<DecisionTrace> decisions,
  ) {
    double factor;

    switch (level) {
      case ReadinessLevel.excellent:
        // Puede manejar volumen elevado (105-115% del base)
        factor = 1.0 + (score - 0.85) * 0.5; // 1.0 - 1.15
        break;
      case ReadinessLevel.good:
        // Volumen normal (95-105%)
        factor = 0.95 + (score - 0.7) * 0.33; // 0.95 - 1.0
        break;
      case ReadinessLevel.moderate:
        // Volumen reducido (80-95%)
        factor = 0.8 + (score - 0.55) * 0.5; // 0.8 - 0.95
        break;
      case ReadinessLevel.low:
        // Volumen muy reducido (65-80%)
        factor = 0.65 + (score - 0.4) * 0.5; // 0.65 - 0.8
        break;
      case ReadinessLevel.critical:
        // Volumen mínimo o deload (50-65%)
        factor = 0.5 + score * 0.37; // 0.5 - 0.65
        break;
    }

    // Clamp al rango seguro
    factor = factor.clamp(0.5, 1.15);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase2ReadinessEvaluation',
        category: 'volume_adjustment',
        description:
            'Factor de ajuste calculado: ${(factor * 100).toStringAsFixed(0)}%',
        context: {
          'readinessLevel': level.name,
          'readinessScore': score,
          'adjustmentFactor': factor,
        },
        action: factor < 0.85
            ? 'Reducir volumen planificado'
            : (factor > 1.0 ? 'Puede incrementar volumen' : 'Mantener volumen'),
      ),
    );

    return factor;
  }
}
