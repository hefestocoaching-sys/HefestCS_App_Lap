import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
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
      historicalAdherence: context.longitudinal.adherence,
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
        mlExampleId = await _datasetService.recordPrediction(
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
              (total, w) => total + w.sessions.length,
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

    // Aplicar ajuste de volumen basado en VolumeDecision
    final phase3Result = _phase3.calculateVolumeCapacity(
      profile: profile,
      history: null,
      readinessAdjustment: volumeDecision.adjustmentFactor,
    );

    decisions.addAll(phase3Result.decisions);

    // Aplicar volumeAdjustmentFactor a los límites calculados
    final adjustedVolumeLimits = <String, VolumeLimits>{};

    for (final entry in phase3Result.volumeLimitsByMuscle.entries) {
      final muscle = entry.key;
      final limits = entry.value;

      adjustedVolumeLimits[muscle] = VolumeLimits(
        muscleGroup: muscle,
        mev: (limits.mev * volumeDecision.adjustmentFactor).round(),
        mav: (limits.mav * volumeDecision.adjustmentFactor).round(),
        mrv: (limits.mrv * volumeDecision.adjustmentFactor).round(),
        recommendedStartVolume:
            (limits.recommendedStartVolume * volumeDecision.adjustmentFactor)
                .round(),
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'volume_adjusted',
        description: 'Volumen ajustado con VolumeDecision',
        context: {
          'adjustmentFactor': volumeDecision.adjustmentFactor,
          'reasoning': volumeDecision.reasoning,
          'sampleMuscle': adjustedVolumeLimits.keys.isNotEmpty
              ? adjustedVolumeLimits.keys.first
              : null,
          'features': {
            'readinessScore': features.readinessScore,
            'fatigueIndex': features.fatigueIndex,
            'overreachingRisk': features.overreachingRisk,
            'volumeOptimalityIndex': features.volumeOptimalityIndex,
          },
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // PHASE 4: SPLIT DISTRIBUTION
    // ════════════════════════════════════════════════════════════

    final readinessMode = readinessDecision.level == ReadinessLevel.excellent
        ? 'normal'
        : 'conservative';

    final phase4Result = _phase4.buildWeeklySplit(
      profile: profile,
      volumeByMuscle: adjustedVolumeLimits,
      readinessAdjustment: volumeDecision.adjustmentFactor,
      readinessMode: readinessMode,
    );

    decisions.addAll(phase4Result.decisions);

    final baseSplit = phase4Result.split;

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'split_generated',
        description: 'Split semanal generado',
        context: {
          'splitId': baseSplit.splitId,
          'daysPerWeek': baseSplit.daysPerWeek,
          'readinessMode': readinessMode,
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // PHASE 5: PERIODIZATION
    // ════════════════════════════════════════════════════════════

    final phase5Result = _phase5.periodize(
      profile: profile,
      baseSplit: baseSplit,
    );

    decisions.addAll(phase5Result.decisions);

    final periodizedWeeks = phase5Result.weeks;

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'periodization_applied',
        description: 'Periodización aplicada',
        context: {
          'totalWeeks': periodizedWeeks.length,
          'phases': periodizedWeeks
              .map((w) => '${w.weekIndex}:${w.phase.name}')
              .toList(),
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // PHASE 6: EXERCISE SELECTION
    // ════════════════════════════════════════════════════════════

    final phase6Result = _phase6.selectExercises(
      profile: profile,
      baseSplit: baseSplit,
      catalog: exercises,
      weeks: periodizedWeeks.length,
    );

    decisions.addAll(phase6Result.decisions);

    final exerciseSelections = phase6Result.selections;

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'exercises_selected',
        description: 'Ejercicios seleccionados para todas las semanas',
        context: {
          'totalWeeks': exerciseSelections.keys.length,
          'totalExercises': exerciseSelections.values
              .expand((w) => w.values)
              .expand((d) => d.values)
              .expand((e) => e)
              .length,
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // PHASE 7: PRESCRIPTION
    // ════════════════════════════════════════════════════════════

    final phase7Result = _phase7.buildPrescriptions(
      baseSplit: baseSplit,
      periodization: phase5Result,
      selections: exerciseSelections,
      volumeLimitsByMuscle: adjustedVolumeLimits,
      trainingLevel: profile.trainingLevel,
      profile: profile,
    );

    decisions.addAll(phase7Result.decisions);

    final prescriptions = phase7Result.weekDayPrescriptions;

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'prescriptions_generated',
        description: 'Prescripciones generadas para todas las semanas',
        context: {
          'totalWeeks': prescriptions.keys.length,
          'totalPrescriptions': prescriptions.values
              .expand((d) => d.values)
              .expand((p) => p)
              .length,
        },
        timestamp: referenceDate,
      ),
    );

    // ════════════════════════════════════════════════════════════
    // ASSEMBLY: Construir TrainingPlanConfig final
    // ════════════════════════════════════════════════════════════

    final weeks = <TrainingWeek>[];

    for (final periodizedWeek in periodizedWeeks) {
      final weekIndex = periodizedWeek.weekIndex;
      final weekPrescriptions = prescriptions[weekIndex] ?? {};
      final sessions = <TrainingSession>[];

      // Ordenar días
      final sortedDays = weekPrescriptions.keys.toList()..sort();

      for (final dayNumber in sortedDays) {
        final dayPrescriptions = weekPrescriptions[dayNumber] ?? [];

        if (dayPrescriptions.isEmpty) continue;

        // Crear TrainingSession
        final session = TrainingSession(
          id: 'w${weekIndex}_d${dayNumber}_${DateTime.now().millisecondsSinceEpoch}',
          dayNumber: dayNumber,
          sessionName: _buildSessionName(
            weekIndex: weekIndex,
            dayNumber: dayNumber,
            phase: periodizedWeek.phase,
            baseSplit: baseSplit,
          ),
          prescriptions: dayPrescriptions,
        );

        sessions.add(session);
      }

      // Crear TrainingWeek
      final week = TrainingWeek(
        id: 'week_${weekIndex}_${periodizedWeek.phase.name}',
        weekNumber: weekIndex,
        phase: periodizedWeek.phase,
        sessions: sessions,
      );

      weeks.add(week);
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV3',
        category: 'assembly_complete',
        description: 'Plan completo ensamblado',
        context: {
          'totalWeeks': weeks.length,
          'totalSessions': weeks.fold<int>(
            0,
            (total, w) => total + w.sessions.length,
          ),
          'totalPrescriptions': weeks
              .expand((w) => w.sessions)
              .expand((s) => s.prescriptions)
              .length,
          'mlExampleId': mlExampleId,
        },
        timestamp: referenceDate,
      ),
    );

    // Crear TrainingPlanConfig final
    final plan = TrainingPlanConfig(
      id: 'plan_v3_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Plan V3 - ${client.profile.fullName}',
      clientId: client.id,
      startDate: referenceDate,
      phase: periodizedWeeks.first.phase,
      splitId: baseSplit.splitId,
      microcycleLengthInWeeks: periodizedWeeks.length,
      weeks: weeks,
      trainingProfileSnapshot: profile,
    );

    return plan;
  }

  /// Construye nombre de sesión basado en split y fase
  String _buildSessionName({
    required int weekIndex,
    required int dayNumber,
    required TrainingPhase phase,
    required SplitTemplate baseSplit,
  }) {
    final dayMuscles = baseSplit.dayMuscles[dayNumber] ?? [];
    final muscleNames = dayMuscles.take(2).join('+');

    return 'S${weekIndex}D${dayNumber} - $muscleNames (${phase.name})';
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
}
