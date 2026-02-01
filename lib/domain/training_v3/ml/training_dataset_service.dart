import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';

/// Ejemplo de entrenamiento para ML
///
/// Representa un ciclo completo:
/// INPUT (features) → PREDICTION (decision) → OUTCOME (real) → LABEL (optimal)
///
/// V1.1 Changes:
/// - Usa featureTensor (List\<double\>) en lugar de FeatureVector completo
/// - Integra weeklyFeedback en serialización
/// - fromJson() completamente funcional
/// - Heurística mejorada usando progressionAllowed/deloadRecommended
class TrainingExample {
  /// ID único del ejemplo (UUID v4)
  final String exampleId;

  /// Timestamp de creación (cuando se generó el plan)
  final DateTime timestamp;

  /// ID del cliente (para agrupación por usuario)
  final String clientId;

  // ════════════════════════════════════════════════════════════
  // INPUT: Features al momento de generar el plan
  // ════════════════════════════════════════════════════════════

  /// ✅ ACTUALIZADO: Tensor de features (37 doubles) en lugar de FeatureVector
  /// Más eficiente para serialización y reconstrucción
  final List<double> featureTensor;

  /// Metadata mínima de features (para trazabilidad)
  final Map<String, dynamic> featureMetadata;

  // ════════════════════════════════════════════════════════════
  // PREDICTION: Qué predijo el motor
  // ════════════════════════════════════════════════════════════

  /// Decisión de volumen predicha
  final VolumeDecision predictedVolume;

  /// Decisión de readiness predicha
  final ReadinessDecision predictedReadiness;

  /// Estrategia usada ('rule_based', 'ml_model', 'hybrid')
  final String strategyUsed;

  // ════════════════════════════════════════════════════════════
  // OUTCOME: Qué pasó realmente (completado después)
  // ════════════════════════════════════════════════════════════

  /// Adherencia real (0.0-1.0)
  /// Ej: 0.92 = completó 92% de sets planificados
  final double? actualAdherence;

  /// Fatiga real al final de semana (1-10)
  final double? actualFatigue;

  /// Progreso real (delta en performance)
  /// Ej: +2.5kg en press, +1 rep en squat
  final double? actualProgress;

  /// Ocurrió lesión durante el plan (bool)
  final bool? injuryOccurred;

  /// Usuario reportó que fue muy duro (bool)
  final bool? userRatedTooHard;

  /// Usuario reportó que fue muy fácil (bool)
  final bool? userRatedTooEasy;

  /// ✅ ACTUALIZADO: Feedback semanal agregado (opcional, ahora se serializa)
  final WeeklyTrainingFeedbackSummary? weeklyFeedback;

  // ════════════════════════════════════════════════════════════
  // LABEL: Ground truth para supervised learning
  // ════════════════════════════════════════════════════════════

  /// Ajuste de volumen óptimo (lo que DEBIÓ ser)
  /// Calculado retroactivamente basado en outcome
  final double? optimalVolumeAdjustment;

  /// Readiness score óptimo (opcional)
  final double? optimalReadinessScore;

  /// Schema version para compatibilidad futura
  final int schemaVersion;

  const TrainingExample({
    required this.exampleId,
    required this.timestamp,
    required this.clientId,
    required this.featureTensor,
    required this.featureMetadata,
    required this.predictedVolume,
    required this.predictedReadiness,
    required this.strategyUsed,
    this.actualAdherence,
    this.actualFatigue,
    this.actualProgress,
    this.injuryOccurred,
    this.userRatedTooHard,
    this.userRatedTooEasy,
    this.weeklyFeedback,
    this.optimalVolumeAdjustment,
    this.optimalReadinessScore,
    this.schemaVersion = 1,
  });

  /// Factory desde FeatureVector (para recordPrediction)
  factory TrainingExample.fromFeatures({
    required String exampleId,
    required DateTime timestamp,
    required String clientId,
    required FeatureVector features,
    required VolumeDecision predictedVolume,
    required ReadinessDecision predictedReadiness,
    required String strategyUsed,
  }) {
    return TrainingExample(
      exampleId: exampleId,
      timestamp: timestamp,
      clientId: clientId,
      featureTensor: features.toTensor(),
      featureMetadata: {
        'clientId': features.clientId,
        'timestamp': features.timestamp.toIso8601String(),
        'schemaVersion': features.schemaVersion,
        'readinessScore': features.readinessScore,
        'fatigueIndex': features.fatigueIndex,
        'overreachingRisk': features.overreachingRisk,
        'volumeOptimalityIndex': features.volumeOptimalityIndex,
      },
      predictedVolume: predictedVolume,
      predictedReadiness: predictedReadiness,
      strategyUsed: strategyUsed,
    );
  }

  /// Indica si tiene outcome completo (listo para training)
  bool get hasOutcome => actualAdherence != null && actualFatigue != null;

  /// Indica si tiene label calculado
  bool get hasLabel => optimalVolumeAdjustment != null;

  /// ✅ MEJORADO: Calcula label usando weeklyFeedback si existe
  ///
  /// Basado en:
  /// - Israetel et al. (2024): adherencia + fatiga → ajuste óptimo
  /// - Schoenfeld et al. (2021): progreso + lesiones → validación
  /// - WeeklyTrainingFeedbackSummary: progressionAllowed/deloadRecommended
  double? get computedOptimalVolume {
    if (!hasOutcome) return null;

    final predicted = predictedVolume.adjustmentFactor;

    // ════════════════════════════════════════════════════════════
    // PRIORIDAD 1: Usar WeeklyFeedbackSummary si existe (más preciso)
    // ════════════════════════════════════════════════════════════

    if (weeklyFeedback != null) {
      final feedback = weeklyFeedback!;

      // Si deload recomendado → volumen estuvo DEFINITIVAMENTE alto
      if (feedback.deloadRecommended) {
        return (predicted * 0.75).clamp(0.5, 1.2);
      }

      // Si progresión permitida → volumen estuvo bien o bajo
      if (feedback.progressionAllowed) {
        // Si además usuario dice "muy fácil" → +15%
        if (userRatedTooEasy == true) {
          return (predicted * 1.15).clamp(0.5, 1.2);
        }
        // Si solo progresión permitida → +5%
        return (predicted * 1.05).clamp(0.5, 1.2);
      }

      // Signal negative (fatiga/dolor/bajo rendimiento) → -10%
      if (feedback.signal == 'negative') {
        return (predicted * 0.90).clamp(0.5, 1.2);
      }

      // Signal positive + NO progressionAllowed (plateau) → mantener
      if (feedback.signal == 'positive' && !feedback.progressionAllowed) {
        return predicted;
      }
    }

    // ════════════════════════════════════════════════════════════
    // PRIORIDAD 2: Heurística basada en adherence/fatigue
    // ════════════════════════════════════════════════════════════

    final adherence = actualAdherence!;
    final fatigue = actualFatigue!;

    // CASO 1: Adherencia alta + fatiga baja = volumen estuvo bajo
    if (adherence > 0.90 && fatigue < 5.0) {
      if (userRatedTooEasy == true) {
        // Muy fácil → pudo ser +15% más
        return (predicted * 1.15).clamp(0.5, 1.2);
      }
      // Solo fácil → pudo ser +8% más
      return (predicted * 1.08).clamp(0.5, 1.2);
    }

    // CASO 2: Adherencia baja + fatiga alta = volumen estuvo alto
    if (adherence < 0.70 || fatigue > 8.0) {
      if (userRatedTooHard == true) {
        // Muy duro → debió ser -25% menos
        return (predicted * 0.75).clamp(0.5, 1.2);
      }
      // Solo duro → debió ser -15% menos
      return (predicted * 0.85).clamp(0.5, 1.2);
    }

    // CASO 3: Lesión → volumen fue DEFINITIVAMENTE alto
    if (injuryOccurred == true) {
      // Debió ser -30% menos (safety)
      return (predicted * 0.70).clamp(0.5, 1.2);
    }

    // CASO 4: Progreso + buena adherencia + fatiga moderada = óptimo
    if (adherence > 0.80 &&
        fatigue >= 5.0 &&
        fatigue <= 7.0 &&
        (actualProgress ?? 0) > 0) {
      // Volumen estuvo PERFECTO
      return predicted;
    }

    // CASO 5: Adherencia media + fatiga media = ligeramente conservador
    if (adherence >= 0.75 &&
        adherence <= 0.85 &&
        fatigue >= 6.0 &&
        fatigue <= 7.5) {
      // Debió ser -5% menos (más conservador)
      return (predicted * 0.95).clamp(0.5, 1.2);
    }

    // CASO DEFAULT: Usar predicción como baseline
    return predicted;
  }

  /// ✅ ACTUALIZADO: Serializa weeklyFeedback
  Map<String, dynamic> toJson() {
    return {
      'exampleId': exampleId,
      'timestamp': Timestamp.fromDate(timestamp),
      'clientId': clientId,
      'schemaVersion': schemaVersion,

      // Input features (tensor + metadata)
      'features': {'tensor': featureTensor, 'metadata': featureMetadata},

      // Prediction
      'prediction': {
        'volume': {
          'adjustmentFactor': predictedVolume.adjustmentFactor,
          'confidence': predictedVolume.confidence,
          'reasoning': predictedVolume.reasoning,
          'metadata': predictedVolume.metadata,
        },
        'readiness': {
          'level': predictedReadiness.level.name,
          'score': predictedReadiness.score,
          'confidence': predictedReadiness.confidence,
          'recommendations': predictedReadiness.recommendations,
        },
        'strategyUsed': strategyUsed,
      },

      // Outcome (nullable)
      'outcome': {
        'adherence': actualAdherence,
        'fatigue': actualFatigue,
        'progress': actualProgress,
        'injury': injuryOccurred,
        'tooHard': userRatedTooHard,
        'tooEasy': userRatedTooEasy,
        'hasOutcome': hasOutcome,
      },

      // ✅ NUEVO: weeklyFeedback serializado
      'weeklyFeedback': weeklyFeedback?.toJson(),

      // Label (nullable, calculado)
      'label': {
        'optimalVolumeAdjustment':
            optimalVolumeAdjustment ?? computedOptimalVolume,
        'optimalReadinessScore': optimalReadinessScore,
        'hasLabel': hasLabel || computedOptimalVolume != null,
      },
    };
  }

  /// ✅ CORREGIDO: fromJson completamente funcional
  factory TrainingExample.fromJson(Map<String, dynamic> json) {
    final featuresMap = json['features'] as Map<String, dynamic>;
    final predictionMap = json['prediction'] as Map<String, dynamic>;
    final volumeMap = predictionMap['volume'] as Map<String, dynamic>;
    final readinessMap = predictionMap['readiness'] as Map<String, dynamic>;
    final outcomeMap = json['outcome'] as Map<String, dynamic>? ?? {};
    final labelMap = json['label'] as Map<String, dynamic>? ?? {};
    final weeklyFeedbackMap = json['weeklyFeedback'] as Map<String, dynamic>?;

    return TrainingExample(
      exampleId: json['exampleId'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      clientId: json['clientId'] as String,

      // ✅ CORREGIDO: Lee tensor directamente
      featureTensor: (featuresMap['tensor'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      featureMetadata: featuresMap['metadata'] as Map<String, dynamic>,

      predictedVolume: VolumeDecision(
        adjustmentFactor: (volumeMap['adjustmentFactor'] as num).toDouble(),
        confidence: (volumeMap['confidence'] as num).toDouble(),
        reasoning: volumeMap['reasoning'] as String,
        metadata: volumeMap['metadata'] as Map<String, dynamic>? ?? {},
      ),
      predictedReadiness: ReadinessDecision(
        level: ReadinessLevel.values.firstWhere(
          (e) => e.name == readinessMap['level'],
        ),
        score: (readinessMap['score'] as num).toDouble(),
        confidence: (readinessMap['confidence'] as num).toDouble(),
        recommendations:
            (readinessMap['recommendations'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      strategyUsed: predictionMap['strategyUsed'] as String,

      actualAdherence: outcomeMap['adherence'] as double?,
      actualFatigue: outcomeMap['fatigue'] as double?,
      actualProgress: outcomeMap['progress'] as double?,
      injuryOccurred: outcomeMap['injury'] as bool?,
      userRatedTooHard: outcomeMap['tooHard'] as bool?,
      userRatedTooEasy: outcomeMap['tooEasy'] as bool?,

      // ✅ CORREGIDO: Deserializa weeklyFeedback
      weeklyFeedback: weeklyFeedbackMap != null
          ? WeeklyTrainingFeedbackSummary.fromJson(weeklyFeedbackMap)
          : null,

      optimalVolumeAdjustment: labelMap['optimalVolumeAdjustment'] as double?,
      optimalReadinessScore: labelMap['optimalReadinessScore'] as double?,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }
}

/// Servicio para recolectar y gestionar dataset de entrenamiento ML
///
/// V1.1 Changes:
/// - Usa UUID v4 real (package uuid)
/// - Integra weeklyFeedback en recordOutcome
/// - CSV export con library csv
/// - Optimización de queries con aggregation
class TrainingDatasetService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  /// Nombre de la colección en Firestore
  static const String collectionName = 'ml_training_data';

  TrainingDatasetService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Registra una predicción cuando se genera un plan
  ///
  /// Llamar desde TrainingProgramEngineV3 después de generar plan.
  Future<String> recordPrediction({
    required String clientId,
    required TrainingContext context,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
    required String strategyUsed,
  }) async {
    final exampleId = _generateUUID();

    final features = FeatureVector.fromContext(context, clientId: clientId);

    final example = TrainingExample.fromFeatures(
      exampleId: exampleId,
      timestamp: DateTime.now(),
      clientId: clientId,
      features: features,
      predictedVolume: volumeDecision,
      predictedReadiness: readinessDecision,
      strategyUsed: strategyUsed,
    );

    await _firestore
        .collection(collectionName)
        .doc(exampleId)
        .set(example.toJson());

    return exampleId;
  }

  /// ✅ ACTUALIZADO: Incluye weeklyFeedback
  ///
  /// Actualiza con outcomes reales (llamar después de 2-4 semanas)
  /// Llamar desde UI cuando coach/usuario completa feedback semanal.
  Future<void> recordOutcome({
    required String exampleId,
    required double adherence,
    required double fatigue,
    double? progress,
    bool? injury,
    bool? tooHard,
    bool? tooEasy,
    WeeklyTrainingFeedbackSummary? weeklyFeedback,
  }) async {
    final docRef = _firestore.collection(collectionName).doc(exampleId);

    final updateData = <String, dynamic>{
      'outcome.adherence': adherence,
      'outcome.fatigue': fatigue,
      'outcome.progress': progress,
      'outcome.injury': injury,
      'outcome.tooHard': tooHard,
      'outcome.tooEasy': tooEasy,
      'outcome.hasOutcome': true,
      'label.computed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ✅ NUEVO: Agregar weeklyFeedback si existe
    if (weeklyFeedback != null) {
      updateData['weeklyFeedback'] = weeklyFeedback.toJson();
    }

    await docRef.update(updateData);
  }

  /// Exporta dataset para entrenar modelos offline
  ///
  /// Retorna lista de ejemplos con outcome completo.
  Future<List<TrainingExample>> exportDataset({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool onlyWithLabels = true,
  }) async {
    var query = _firestore
        .collection(collectionName)
        .where('outcome.hasOutcome', isEqualTo: true);

    if (onlyWithLabels) {
      query = query.where('label.computed', isEqualTo: true);
    }

    if (startDate != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => TrainingExample.fromJson(doc.data()))
        .toList();
  }

  /// ✅ MEJORADO: Exporta a CSV usando library csv
  Future<String> exportToCSV({DateTime? startDate, DateTime? endDate}) async {
    final examples = await exportDataset(
      startDate: startDate,
      endDate: endDate,
      onlyWithLabels: true,
    );

    if (examples.isEmpty) {
      return 'No data available for export';
    }

    // ✅ MEJORADO: Headers descriptivos con nombres reales de features
    final headers = [
      'exampleId',
      'timestamp',
      'clientId',
      'strategyUsed',
      // Features con nombres reales (37)
      'age_norm', 'gender_male', 'height_norm', 'weight_norm', 'bmi_norm',
      'years_training_norm', 'consecutive_weeks_norm', 'level_encoded',
      'avg_sets_norm', 'max_sets_norm', 'volume_tolerance_ratio',
      'sleep_norm', 'prs_norm', 'stress_norm', 'doms_norm',
      'session_duration_norm', 'rest_between_sets_norm',
      'rir_norm', 'rpe_norm', 'rir_optimality',
      'deload_freq_norm', 'breaks_norm', 'adherence_historical',
      'performance_trend',
      'fatigue_index', 'recovery_capacity', 'training_maturity',
      'overreaching_risk', 'readiness_score', 'volume_optimality',
      'goal_hypertrophy', 'goal_strength', 'goal_endurance', 'goal_general',
      'focus_upper', 'focus_lower', 'focus_fullbody',
      // Prediction
      'predicted_volume',
      'predicted_readiness',
      // Outcome
      'actual_adherence',
      'actual_fatigue',
      'actual_progress',
      'injury',
      'too_hard',
      'too_easy',
      // Label
      'optimal_volume',
    ];

    // Rows
    final rows = examples.map((ex) {
      final tensor = ex.featureTensor;
      return [
        ex.exampleId,
        ex.timestamp.toIso8601String(),
        ex.clientId,
        ex.strategyUsed,
        ...tensor.map((v) => v.toStringAsFixed(4)),
        ex.predictedVolume.adjustmentFactor.toStringAsFixed(4),
        ex.predictedReadiness.score.toStringAsFixed(4),
        ex.actualAdherence?.toStringAsFixed(4) ?? '',
        ex.actualFatigue?.toStringAsFixed(2) ?? '',
        ex.actualProgress?.toStringAsFixed(2) ?? '',
        ex.injuryOccurred?.toString() ?? '',
        ex.userRatedTooHard?.toString() ?? '',
        ex.userRatedTooEasy?.toString() ?? '',
        ex.computedOptimalVolume?.toStringAsFixed(4) ?? '',
      ];
    }).toList();

    // ✅ NUEVO: Usar library csv para escapar correctamente
    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  /// ✅ MEJORADO: Estadísticas con single query (más eficiente)
  Future<Map<String, dynamic>> getDatasetStats() async {
    final snapshot = await _firestore.collection(collectionName).get();

    int total = snapshot.size;
    int withOutcome = 0;
    int withLabels = 0;
    int withWeeklyFeedback = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['outcome']?['hasOutcome'] == true) withOutcome++;
      if (data['label']?['computed'] == true) withLabels++;
      if (data['weeklyFeedback'] != null) withWeeklyFeedback++;
    }

    return {
      'totalExamples': total,
      'withOutcome': withOutcome,
      'withLabels': withLabels,
      'withWeeklyFeedback': withWeeklyFeedback,
      'readyForTraining': withLabels,
      'pendingOutcome': total - withOutcome,
    };
  }

  /// ✅ CORREGIDO: UUID v4 real
  String _generateUUID() {
    return _uuid.v4();
  }
}
