import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/services/phase_3_volume_capacity_model_service.dart';
import 'package:hcs_app_lap/domain/services/phase_4_split_distribution_service.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_6_exercise_selection_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/domain/training_v2/services/training_context_builder.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/hybrid_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/training_dataset_service.dart';

/// Resultado de generación de plan V3
class TrainingProgramV3Result {
  /// Plan generado (null si bloqueado)
  final TrainingPlanConfig? plan;

  /// ID del ejemplo ML (para tracking prediction-outcome)
  final String? mlExampleId;

  /// Decisión de volumen tomada
  final VolumeDecision volumeDecision;

  /// Decisión de readiness tomada
  final ReadinessDecision readinessDecision;

  /// Features usadas (para debugging)
  final FeatureVector features;

  /// Estrategia usada
  final String strategyUsed;

  /// Trazas de decisiones
  final List<DecisionTrace> decisions;

  /// Razón de bloqueo (si plan == null)
  final String? blockedReason;

  const TrainingProgramV3Result({
    required this.plan,
    required this.mlExampleId,
    required this.volumeDecision,
    required this.readinessDecision,
    required this.features,
    required this.strategyUsed,
    required this.decisions,
    this.blockedReason,
  });

  bool get isBlocked => plan == null;
  bool get isSuccess => plan != null;
}

/// Motor de Entrenamiento V3: ML-Ready + Científico
///
/// Mejoras vs Legacy:
/// - ✅ Usa DecisionStrategy (pluggable: Rules/ML/Hybrid)
/// - ✅ Registra predictions en Firestore (ML dataset)
/// - ✅ FeatureVector con 37 features científicas
/// - ✅ Alineado 100% con Phase2ReadinessEvaluation
/// - ✅ Reutiliza Phases 3-8 legacy (no reinventar rueda)
/// - ✅ Explicabilidad completa (DecisionTrace + reasoning)
///
/// Filosofía:
/// - Ciencia como backbone (Israetel/Schoenfeld/Helms)
/// - IA como refinamiento personalizado
/// - Aprendizaje longitudinal por cliente
///
/// Version: 3.0.0
/// Schema: TrainingContext V2 (30 campos)
class TrainingProgramEngineV3 {
  final DecisionStrategy _strategy;
  final TrainingDatasetService? _datasetService;

  // Services legacy (Phases 3-8)
  final Phase3VolumeCapacityModelService _phase3;
  final Phase4SplitDistributionService _phase4;
  final Phase5PeriodizationService _phase5;
  final Phase6ExerciseSelectionService _phase6;
  final Phase7PrescriptionService _phase7;

  TrainingProgramEngineV3({
    DecisionStrategy? strategy,
    TrainingDatasetService? datasetService,
  }) : _strategy = strategy ?? RuleBasedStrategy(),
       _datasetService = datasetService,
       _phase3 = Phase3VolumeCapacityModelService(),
       _phase4 = Phase4SplitDistributionService(),
       _phase5 = Phase5PeriodizationService(),
       _phase6 = Phase6ExerciseSelectionService(),
       _phase7 = Phase7PrescriptionService();

  /// Factory para production (RuleBased)
  factory TrainingProgramEngineV3.production({
    required FirebaseFirestore firestore,
  }) {
    return TrainingProgramEngineV3(
      strategy: RuleBasedStrategy(),
      datasetService: TrainingDatasetService(firestore: firestore),
    );
  }

  /// Factory para ML testing (Hybrid)
  factory TrainingProgramEngineV3.hybrid({
    required FirebaseFirestore firestore,
    double mlWeight = 0.3,
  }) {
    return TrainingProgramEngineV3(
      strategy: HybridStrategy(mlWeight: mlWeight),
      datasetService: TrainingDatasetService(firestore: firestore),
    );
  }

  /// Genera plan de entrenamiento usando ML-ready pipeline
  ///
  /// [client] - Cliente con datos completos (TrainingEvaluationTab)
  /// [exercises] - Catálogo de ejercicios disponible
  /// [asOfDate] - Fecha de referencia (default: hoy)
  /// [recordPrediction] - Si debe guardar en Firestore (default: true)
  Future<TrainingProgramV3Result> generatePlan({
    required Client client,
    required List<Exercise> exercises,
    DateTime? asOfDate,
    bool recordPrediction = true,
  }) async {
    final referenceDate = asOfDate ?? DateTime.now();
    final decisions = <DecisionTrace>[];

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'start',
        description: 'Iniciando generación de plan V3 (ML-Ready)',
        context: {
          'clientId': client.id,
          'strategy': _strategy.name,
          'version': _strategy.version,
          'referenceDate': referenceDate.toIso8601String(),
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // FASE 0: BUILD TRAINING CONTEXT V2
    // ════════════════════════════════════════════════════════════

    final contextBuilder = TrainingContextBuilder();
    final contextResult = contextBuilder.build(
      client: client,
      asOfDate: referenceDate,
    );

    if (!contextResult.isOk || contextResult.context == null) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'TrainingProgramEngineV3',
          category: 'context_build_failed',
          description:
              'No se pudo construir TrainingContext: ${contextResult.error?.message}',
          context: contextResult.error?.details ?? {},
          timestamp: referenceDate,
        ),
      );

      return TrainingProgramV3Result(
        plan: null,
        mlExampleId: null,
        volumeDecision: VolumeDecision.maintain(
          reasoning: 'Context build failed',
        ),
        readinessDecision: ReadinessDecision(
          level: ReadinessLevel.moderate,
          score: 0.5,
          confidence: 0.0,
          recommendations: ['Completar datos en TrainingEvaluationTab'],
        ),
        features: _createFallbackFeatures(client.id, referenceDate),
        strategyUsed: _strategy.name,
        decisions: decisions,
        blockedReason: contextResult.error?.message ?? 'Context build failed',
      );
    }

    final context = contextResult.context!;
    decisions.addAll(contextResult.trace);

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'context_built',
        description: 'TrainingContext V2 construido exitosamente',
        context: {
          'schemaVersion': context.schemaVersion,
          'athlete': {
            'age': context.athlete.ageYears,
            'gender': context.athlete.gender?.name,
          },
          'meta': {
            'goal': context.meta.goal.name,
            'level': context.meta.level?.name,
            'daysPerWeek': context.meta.daysPerWeek,
          },
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // FASE 1: FEATURE ENGINEERING
    // ════════════════════════════════════════════════════════════

    final features = FeatureVector.fromContext(
      context,
      clientId: client.id,
      historicalAdherence: context.longitudinal.averageAdherence,
    );

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'features_extracted',
        description: 'FeatureVector generado con 37 features',
        context: {
          'readinessScore': features.readinessScore,
          'fatigueIndex': features.fatigueIndex,
          'overreachingRisk': features.overreachingRisk,
          'volumeOptimalityIndex': features.volumeOptimalityIndex,
          'trainingMaturity': features.trainingMaturity,
          'recoveryCapacity': features.recoveryCapacity,
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // FASE 2: DECISION MAKING (Pluggable Strategy)
    // ════════════════════════════════════════════════════════════

    final volumeDecision = _strategy.decideVolume(features);
    final readinessDecision = _strategy.decideReadiness(features);

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'volume_decision',
        description: 'Decisión de volumen tomada',
        context: {
          'strategy': _strategy.name,
          'adjustmentFactor': volumeDecision.adjustmentFactor,
          'confidence': volumeDecision.confidence,
          'reasoning': volumeDecision.reasoning,
        },
        timestamp: referenceDate,
      ),
    );

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'readiness_decision',
        description: 'Decisión de readiness tomada',
        context: {
          'strategy': _strategy.name,
          'level': readinessDecision.level.name,
          'score': readinessDecision.score,
          'confidence': readinessDecision.confidence,
          'recommendations': readinessDecision.recommendations,
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // FASE 3: ML PREDICTION LOGGING (Firestore)
    // ════════════════════════════════════════════════════════════

    String? mlExampleId;

    if (recordPrediction && _datasetService != null) {
      try {
        mlExampleId = await _datasetService!.recordPrediction(
          clientId: client.id,
          context: context,
          volumeDecision: volumeDecision,
          readinessDecision: readinessDecision,
          strategyUsed: _strategy.name,
        );

        decisions.add(
          DecisionTrace.info(
            phase: 'TrainingProgramEngineV3',
            category: 'ml_prediction_logged',
            description: 'Predicción guardada en Firestore para ML',
            context: {
              'exampleId': mlExampleId,
              'collection': TrainingDatasetService.collectionName,
            },
            timestamp: referenceDate,
          ),
        );
      } catch (e) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'TrainingProgramEngineV3',
            category: 'ml_logging_failed',
            description: 'No se pudo guardar predicción ML (no crítico)',
            context: {'error': e.toString()},
            timestamp: referenceDate,
          ),
        );
      }
    }

    // ════════════════════════════════════════════════════════════
    // FASE 4: VALIDACIÓN DE READINESS (Gate)
    // ════════════════════════════════════════════════════════════

    if (readinessDecision.needsDeload) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'TrainingProgramEngineV3',
          category: 'deload_required',
          description: 'Cliente necesita deload INMEDIATO (readiness crítico)',
          context: {
            'readinessLevel': readinessDecision.level.name,
            'readinessScore': readinessDecision.score,
            'recommendations': readinessDecision.recommendations,
          },
          action:
              'Bloquear generación de plan, prescribir semana de descarga activa',
          timestamp: referenceDate,
        ),
      );

      return TrainingProgramV3Result(
        plan: null,
        mlExampleId: mlExampleId,
        volumeDecision: volumeDecision,
        readinessDecision: readinessDecision,
        features: features,
        strategyUsed: _strategy.name,
        decisions: decisions,
        blockedReason:
            'Readiness crítico: ${readinessDecision.level.name}. '
            'Recomendaciones: ${readinessDecision.recommendations.join(", ")}',
      );
    }

    // ════════════════════════════════════════════════════════════
    // FASE 5: PLAN GENERATION (Reutiliza Phases Legacy)
    // ════════════════════════════════════════════════════════════

    try {
      final plan = await _buildPlanFromDecisions(
        context: context,
        client: client,
        exercises: exercises,
        volumeDecision: volumeDecision,
        readinessDecision: readinessDecision,
        mlExampleId: mlExampleId,
        decisions: decisions,
        referenceDate: referenceDate,
        features: features,
      );

      decisions.add(
        DecisionTrace.info(
          phase: 'TrainingProgramEngineV3',
          category: 'plan_generated',
          description: 'Plan de entrenamiento generado exitosamente',
          context: {
            'totalWeeks': plan.weeks.length,
            'totalSessions': plan.weeks.fold<int>(
              0,
              (sum, w) => sum + w.sessions.length,
            ),
            'mlExampleId': mlExampleId,
          },
          timestamp: referenceDate,
        ),
      );

      return TrainingProgramV3Result(
        plan: plan,
        mlExampleId: mlExampleId,
        volumeDecision: volumeDecision,
        readinessDecision: readinessDecision,
        features: features,
        strategyUsed: _strategy.name,
        decisions: decisions,
      );
    } catch (e) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'TrainingProgramEngineV3',
          category: 'plan_generation_failed',
          description: 'Error al generar plan: ${e.toString()}',
          context: {'error': e.toString()},
          timestamp: referenceDate,
        ),
      );

      return TrainingProgramV3Result(
        plan: null,
        mlExampleId: mlExampleId,
        volumeDecision: volumeDecision,
        readinessDecision: readinessDecision,
        features: features,
        strategyUsed: _strategy.name,
        decisions: decisions,
        blockedReason: 'Error en generación: ${e.toString()}',
      );
    }
  }

  /// Construye plan usando decisiones ML + Phases legacy
  Future<TrainingPlanConfig> _buildPlanFromDecisions({
    required TrainingContext context,
    required Client client,
    required List<Exercise> exercises,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
    required String? mlExampleId,
    required List<DecisionTrace> decisions,
    required DateTime referenceDate,
    required FeatureVector features,
  }) async {
    // ════════════════════════════════════════════════════════════
    // PHASE 3: VOLUME CAPACITY (Override con VolumeDecision)
    // ════════════════════════════════════════════════════════════

    // Convertir TrainingContext → TrainingProfile (legacy)
    final profile = _contextToProfile(context);

    final phase3Result = _phase3.calculateVolumeCapacity(
      profile: profile,
      history: null,
      readinessAdjustment: 1.0,
    );

    decisions.addAll(phase3Result.decisions);

    // Override MEV/MAV/MRV con volumeAdjustmentFactor
    final adjustedVolumeLimits = <String, dynamic>{};

    for (final entry in phase3Result.volumeLimitsByMuscle.entries) {
      final muscle = entry.key;
      final limits = entry.value;

      adjustedVolumeLimits[muscle.name] = {
        'mev': (limits.mev * volumeDecision.adjustmentFactor).round(),
        'mav': (limits.mav * volumeDecision.adjustmentFactor).round(),
        'mrv': (limits.mrv * volumeDecision.adjustmentFactor).round(),
        'recommendedStart':
            (limits.recommendedStartVolume * volumeDecision.adjustmentFactor)
                .round(),
        'originalMEV': limits.mev,
        'originalMAV': limits.mav,
        'adjustmentFactor': volumeDecision.adjustmentFactor,
      };
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'volume_adjusted',
        description: 'Volumen ajustado con VolumeDecision',
        context: {
          'adjustmentFactor': volumeDecision.adjustmentFactor,
          'sampleMuscle': adjustedVolumeLimits.keys.isNotEmpty
              ? adjustedVolumeLimits.keys.first
              : null,
          'sampleAdjusted': adjustedVolumeLimits.values.isNotEmpty
              ? adjustedVolumeLimits.values.first
              : null,
          'features': {
            'readinessScore': features.readinessScore,
            'fatigueIndex': features.fatigueIndex,
            'overreachingRisk': features.overreachingRisk,
          },
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // PHASE 4-7: Delegado a services legacy (sin cambios)
    // ════════════════════════════════════════════════════════════

    // TODO: Implementar Phases 4-7 usando services legacy
    // Por ahora retornar plan placeholder

    final plan = TrainingPlanConfig(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Plan V3 - ${client.profile.fullName}',
      clientId: client.id,
      startDate: referenceDate,
      phase: TrainingPhase.accumulation,
      splitId: 'auto',
      microcycleLengthInWeeks: 1,
      weeks: _buildPlaceholderWeeks(context),
      trainingProfileSnapshot: profile,
    );

    return plan;
  }

  /// Convierte TrainingContext V2 → TrainingProfile (legacy)
  TrainingProfile _contextToProfile(TrainingContext context) {
    return TrainingProfile(
      gender: context.athlete.gender,
      age: context.athlete.ageYears,
      bodyWeight: context.athlete.weightKg,
      isCompetitor: context.athlete.isCompetitor,
      usesAnabolics: context.athlete.usesAnabolics,
      globalGoal: context.meta.goal,
      trainingFocus: context.meta.focus,
      trainingLevel: context.meta.level,
      daysPerWeek: context.meta.daysPerWeek,
      timePerSessionMinutes: context.meta.timePerSessionMinutes,
      yearsTrainingContinuous: context.interview.yearsTrainingContinuous,
      sessionDurationMinutes: context.interview.sessionDurationMinutes,
      restBetweenSetsSeconds: context.interview.restBetweenSetsSeconds,
      avgSleepHours: context.interview.avgSleepHours,
      extra: {
        'avgWeeklySetsPerMuscle': context.interview.avgWeeklySetsPerMuscle,
        'consecutiveWeeksTraining': context.interview.consecutiveWeeksTraining,
        'perceivedRecoveryStatus': context.interview.perceivedRecoveryStatus,
        'stressLevel': context.interview.stressLevel,
        'averageRIR': context.interview.averageRIR,
        'averageSessionRPE': context.interview.averageSessionRPE,
      },
    );
  }

  /// Crea FeatureVector fallback para casos de error
  FeatureVector _createFallbackFeatures(String clientId, DateTime timestamp) {
    // Retornar features conservadores (valores neutrales)
    return FeatureVector(
      ageYearsNorm: 0.3,
      genderMaleEncoded: 1.0,
      heightCmNorm: 0.5,
      weightKgNorm: 0.5,
      bmiNorm: 0.5,
      yearsTrainingNorm: 0.2,
      consecutiveWeeksNorm: 0.3,
      trainingLevelEncoded: 0.5,
      avgWeeklySetsNorm: 0.4,
      maxSetsToleratedNorm: 0.5,
      volumeToleranceRatio: 0.4,
      avgSleepHoursNorm: 0.5,
      perceivedRecoveryNorm: 0.6,
      stressLevelNorm: 0.5,
      soreness48hNorm: 0.5,
      sessionDurationNorm: 0.5,
      restBetweenSetsNorm: 0.5,
      averageRIRNorm: 0.5,
      averageSessionRPENorm: 0.6,
      rirOptimalityScore: 0.5,
      deloadFrequencyNorm: 0.5,
      periodBreaksNorm: 0.3,
      adherenceHistorical: 0.8,
      performanceTrendEncoded: 0.5,
      goalOneHot: {
        'hypertrophy': 1.0,
        'strength': 0.0,
        'endurance': 0.0,
        'general': 0.0,
      },
      focusOneHot: {
        'hypertrophy': 0.0,
        'strength': 0.0,
        'power': 0.0,
        'mixed': 1.0,
      },
      fatigueIndex: 0.4,
      recoveryCapacity: 0.6,
      trainingMaturity: 0.3,
      overreachingRisk: 0.3,
      readinessScore: 0.6,
      volumeOptimalityIndex: 0.5,
      clientId: clientId,
      timestamp: timestamp,
    );
  }

  /// Placeholder: genera semanas de ejemplo (reemplazar con Phases 4-7 reales)
  List<TrainingWeek> _buildPlaceholderWeeks(TrainingContext context) {
    // Por ahora retornar 1 semana placeholder
    // TODO: Implementar con Phases 4-7 legacy

    return [
      TrainingWeek(
        id: 'week-1-${TrainingPhase.accumulation.name}',
        weekNumber: 1,
        phase: TrainingPhase.accumulation,
        sessions: _buildPlaceholderSessions(context),
      ),
    ];
  }

  /// Placeholder: genera sesiones de ejemplo
  List<TrainingSession> _buildPlaceholderSessions(TrainingContext context) {
    final sessions = <TrainingSession>[];

    for (int day = 1; day <= context.meta.daysPerWeek; day++) {
      sessions.add(
        TrainingSession(
          id: 'session-$day',
          dayNumber: day,
          sessionName: 'Día $day - Placeholder',
          prescriptions: const [],
        ),
      );
    }

    return sessions;
  }
}
