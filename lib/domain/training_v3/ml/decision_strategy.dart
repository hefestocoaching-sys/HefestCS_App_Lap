import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';

/// Objeto de decisión que encapsula predicción + confianza + justificación
class TrainingDecision {
  /// Recomendación principal: 'REST', 'LIGHT', 'MODERATE', 'HIGH', 'DELOAD'
  final String recommendation;

  /// Confianza en la recomendación (0.0-1.0)
  final double confidence;

  /// Justificación legible para el usuario
  final String rationale;

  /// Scores de factores clave (para visualización)
  final Map<String, double> factorScores;

  /// Metadata: timestamp, engine version, etc.
  final Map<String, dynamic> metadata;

  TrainingDecision({
    required this.recommendation,
    required this.confidence,
    required this.rationale,
    required this.factorScores,
    this.metadata = const {},
  });

  /// Serializar para persistencia
  Map<String, dynamic> toJson() {
    return {
      'recommendation': recommendation,
      'confidence': confidence,
      'rationale': rationale,
      'factorScores': factorScores,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() =>
      'TrainingDecision(rec=$recommendation, conf=$confidence, rationale=$rationale)';
}

/// Interfaz para estrategias de decisión pluggables
///
/// Soporta múltiples motores:
/// 1. RuleBasedStrategy: Reglas científicas hardcoded (Israetel/Schoenfeld/Helms)
/// 2. MLModelStrategy: TensorFlow Lite model for predicting optimal volume
/// 3. HybridStrategy: Combina reglas + ML con pesos ajustables
/// 4. EnsembleStrategy: Múltiples estrategias votando
abstract class DecisionStrategy {
  /// Nombre de la estrategia (para logging/debugging)
  String get name;

  /// Versión del engine (para reproducibilidad)
  String get version;

  /// Procesar FeatureVector y retornar decisión
  Future<TrainingDecision> decide(FeatureVector features);

  /// Evaluar calidad de predicción contra resultado real (para entrenamiento)
  /// outcome: datos reales post-sesión (RPE realizado, sets completados, etc.)
  Future<void> recordOutcome(
    TrainingDecision decision,
    Map<String, dynamic> outcome,
  );
}

/// Evaluación de predicción para análisis de performance
class PredictionEvaluation {
  /// Número de predicciones evaluadas
  final int sampleCount;

  /// Accuracy: % de predicciones correctas (si es clasificación)
  final double accuracy;

  /// MAE: Mean Absolute Error (si es regresión)
  final double mae;

  /// AUC (si es binaria)
  final double? auc;

  /// Confusion matrix para debugging
  final Map<String, dynamic>? confusionMatrix;

  PredictionEvaluation({
    required this.sampleCount,
    required this.accuracy,
    required this.mae,
    this.auc,
    this.confusionMatrix,
  });

  @override
  String toString() =>
      'PredictionEvaluation(n=$sampleCount, acc=$accuracy, mae=$mae)';
}

/// Estrategia base con helpers comunes
abstract class BaseDecisionStrategy implements DecisionStrategy {
  /// Helper: Normalizar score a recomendación
  /// 0.0-0.2 = REST, 0.2-0.4 = LIGHT, 0.4-0.6 = MODERATE, 0.6-0.8 = HIGH, 0.8-1.0 = DELOAD (invert logic)
  String scoreToRecommendation(double score) {
    if (score < 0.2) return 'REST';
    if (score < 0.4) return 'LIGHT';
    if (score < 0.6) return 'MODERATE';
    if (score < 0.8) return 'HIGH';
    return 'DELOAD'; // Alta fatiga = deload
  }

  /// Helper: Generar rationale basado en factores dominantes
  String generateRationale(Map<String, double> factors) {
    final sorted = factors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = sorted
        .take(3)
        .map((e) => '${e.key}(${e.value.toStringAsFixed(2)})')
        .join(', ');
    return 'Factores principales: $top3';
  }

  /// Helper: Evaluar múltiples scores usando pesos
  double weightedScore(
    Map<String, double> scores,
    Map<String, double> weights,
  ) {
    double total = 0.0;
    double weightSum = 0.0;

    for (final entry in scores.entries) {
      final weight = weights[entry.key] ?? 0.0;
      total += entry.value * weight;
      weightSum += weight;
    }

    return weightSum > 0 ? total / weightSum : 0.5;
  }
}
