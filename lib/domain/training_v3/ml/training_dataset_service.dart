import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';

/// Ejemplo de entrenamiento para ML
///
/// Representa un ciclo completo:
/// INPUT (features) → PREDICTION (decision) → OUTCOME (real) → LABEL (optimal)
class TrainingExample {
  /// ID único del ejemplo (UUID)
  final String exampleId;

  /// Timestamp de creación (cuando se generó el plan)
  final DateTime timestamp;

  /// ID del cliente (para agrupación por usuario)
  final String clientId;

  // ════════════════════════════════════════════════════════════
  // INPUT: Features al momento de generar el plan
  // ════════════════════════════════════════════════════════════

  /// Vector de características normalizado (37 features)
  final FeatureVector features;

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

  /// Feedback semanal agregado (opcional)
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
    required this.features,
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

  /// Indica si tiene outcome completo (listo para training)
  bool get hasOutcome => actualAdherence != null && actualFatigue != null;

  /// Indica si tiene label calculado
  bool get hasLabel => optimalVolumeAdjustment != null;

  /// Calcula label automáticamente (heurística científica)
  ///
  /// Basado en:
  /// - Israetel et al. (2024): adherencia + fatiga → ajuste óptimo
  /// - Schoenfeld et al. (2021): progreso + lesiones → validación
  double? get computedOptimalVolume {
    if (!hasOutcome) return null;

    final adherence = actualAdherence!;
    final fatigue = actualFatigue!;
    final predicted = predictedVolume.adjustmentFactor;

    // ════════════════════════════════════════════════════════════
    // HEURÍSTICA: Calcular ajuste óptimo retroactivamente
    // ════════════════════════════════════════════════════════════

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

  /// Serializa a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'exampleId': exampleId,
      'timestamp': Timestamp.fromDate(timestamp),
      'clientId': clientId,
      'schemaVersion': schemaVersion,

      // Input features
      'features': features.toJson(),

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

      // Label (nullable, calculado)
      'label': {
        'optimalVolumeAdjustment':
            optimalVolumeAdjustment ?? computedOptimalVolume,
        'optimalReadinessScore': optimalReadinessScore,
        'hasLabel': hasLabel || computedOptimalVolume != null,
      },
    };
  }

  /// Deserializa desde JSON
  factory TrainingExample.fromJson(Map<String, dynamic> json) {
    final predictionMap = json['prediction'] as Map<String, dynamic>;
    final volumeMap = predictionMap['volume'] as Map<String, dynamic>;
    final readinessMap = predictionMap['readiness'] as Map<String, dynamic>;
    final outcomeMap = json['outcome'] as Map<String, dynamic>? ?? {};
    final labelMap = json['label'] as Map<String, dynamic>? ?? {};

    return TrainingExample(
      exampleId: json['exampleId'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      clientId: json['clientId'] as String,
      features: FeatureVector.fromContext(
        // TODO: Reconstruir TrainingContext desde features JSON
        throw UnimplementedError('Reconstruction from JSON pending'),
        clientId: json['clientId'] as String,
      ),
      predictedVolume: VolumeDecision(
        adjustmentFactor: volumeMap['adjustmentFactor'] as double,
        confidence: volumeMap['confidence'] as double,
        reasoning: volumeMap['reasoning'] as String,
        metadata: volumeMap['metadata'] as Map<String, dynamic>? ?? {},
      ),
      predictedReadiness: ReadinessDecision(
        level: ReadinessLevel.values.firstWhere(
          (e) => e.name == readinessMap['level'],
        ),
        score: readinessMap['score'] as double,
        confidence: readinessMap['confidence'] as double,
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
      optimalVolumeAdjustment: labelMap['optimalVolumeAdjustment'] as double?,
      optimalReadinessScore: labelMap['optimalReadinessScore'] as double?,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }
}

/// Servicio para recolectar y gestionar dataset de entrenamiento ML
class TrainingDatasetService {
  final FirebaseFirestore _firestore;

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

    final example = TrainingExample(
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

  /// Actualiza con outcomes reales (llamar después de 2-4 semanas)
  ///
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

    await docRef.update({
      'outcome.adherence': adherence,
      'outcome.fatigue': fatigue,
      'outcome.progress': progress,
      'outcome.injury': injury,
      'outcome.tooHard': tooHard,
      'outcome.tooEasy': tooEasy,
      'outcome.hasOutcome': true,
      'label.computed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  /// Exporta a CSV para análisis en Python/R
  Future<String> exportToCSV({DateTime? startDate, DateTime? endDate}) async {
    final examples = await exportDataset(
      startDate: startDate,
      endDate: endDate,
      onlyWithLabels: true,
    );

    if (examples.isEmpty) {
      return 'No data available for export';
    }

    // Header
    final header = [
      'exampleId',
      'timestamp',
      'clientId',
      'strategyUsed',
      // Features (37)
      ...List.generate(37, (i) => 'feature_$i'),
      // Prediction
      'predicted_volume',
      'predicted_readiness',
      // Outcome
      'actual_adherence',
      'actual_fatigue',
      'actual_progress',
      'injury',
      // Label
      'optimal_volume',
    ].join(',');

    // Rows
    final rows = examples
        .map((ex) {
          final tensor = ex.features.toTensor();
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
            ex.computedOptimalVolume?.toStringAsFixed(4) ?? '',
          ].join(',');
        })
        .join('\n');

    return '$header\n$rows';
  }

  /// Estadísticas del dataset
  Future<Map<String, dynamic>> getDatasetStats() async {
    final total = await _firestore.collection(collectionName).count().get();

    final withOutcome = await _firestore
        .collection(collectionName)
        .where('outcome.hasOutcome', isEqualTo: true)
        .count()
        .get();

    final withLabels = await _firestore
        .collection(collectionName)
        .where('label.computed', isEqualTo: true)
        .count()
        .get();

    return {
      'totalExamples': total.count,
      'withOutcome': withOutcome.count,
      'withLabels': withLabels.count,
      'readyForTraining': withLabels.count,
      'pendingOutcome': total.count! - withOutcome.count!,
    };
  }

  String _generateUUID() {
    // Simple UUID v4 generator
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'example_$random';
  }
}
