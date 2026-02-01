import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/ml_model_strategy.dart';

/// Estrategia híbrida: Combina reglas científicas + ML
///
/// Filosofía:
/// - Reglas científicas (70%) = baseline confiable y explicable
/// - ML (30%) = refinamiento personalizado basado en datos reales
///
/// Ventajas:
/// ✅ Nunca peor que reglas puras (safety floor)
/// ✅ Mejora incremental con datos (sin romper nada)
/// ✅ Explicabilidad mantenida (reasoning de reglas)
/// ✅ A/B testing fácil (ajustar mlWeight)
///
/// Desventajas:
/// ⚠️ Requiere modelo ML entrenado (fallback a 100% rules)
/// ⚠️ Más complejo que estrategias puras
class HybridStrategy implements DecisionStrategy {
  final RuleBasedStrategy _rules;
  final MLModelStrategy? _ml;
  final double _mlWeight; // 0.0 = solo reglas, 1.0 = solo ML

  /// Constructor
  ///
  /// [mlModel] - Modelo ML opcional (null = fallback a 100% rules)
  /// [mlWeight] - Peso del ML (0.0-1.0), default 0.3 = 70% rules, 30% ML
  HybridStrategy({MLModelStrategy? mlModel, double mlWeight = 0.3})
    : _rules = RuleBasedStrategy(),
      _ml = mlModel,
      _mlWeight = mlWeight.clamp(0.0, 1.0);

  @override
  String get name =>
      'Hybrid_${((1 - _mlWeight) * 100).toInt()}R${(_mlWeight * 100).toInt()}ML';

  @override
  String get version => '1.0.0';

  @override
  bool get isTrainable => true;

  @override
  VolumeDecision decideVolume(FeatureVector features) {
    // Baseline: Reglas científicas (SIEMPRE)
    final rulesDecision = _rules.decideVolume(features);

    // Si no hay ML o peso es 0, retornar solo reglas
    if (_ml == null || _mlWeight == 0.0) {
      return VolumeDecision(
        adjustmentFactor: rulesDecision.adjustmentFactor,
        confidence: rulesDecision.confidence,
        reasoning: '[100% Rules] ${rulesDecision.reasoning}',
        metadata: {'strategy': 'hybrid', 'ml_weight': 0.0, 'rules_only': true},
      );
    }

    // Intentar obtener predicción ML
    VolumeDecision? mlDecision;
    try {
      mlDecision = _ml.decideVolume(features);
    } catch (e) {
      // ML falló, fallback a 100% reglas
      return VolumeDecision(
        adjustmentFactor: rulesDecision.adjustmentFactor,
        confidence: rulesDecision.confidence,
        reasoning:
            '[ML failed, fallback 100% Rules] ${rulesDecision.reasoning}',
        metadata: {
          'strategy': 'hybrid',
          'ml_weight': 0.0,
          'ml_error': e.toString(),
        },
      );
    }

    // Weighted average de ajustes
    final hybridAdjustment =
        rulesDecision.adjustmentFactor * (1 - _mlWeight) +
        mlDecision.adjustmentFactor * _mlWeight;

    // Weighted average de confidence
    final hybridConfidence =
        rulesDecision.confidence * (1 - _mlWeight) +
        mlDecision.confidence * _mlWeight;

    // Combinar reasoning (mantener explicabilidad)
    final hybridReasoning =
        '[Hybrid: ${((1 - _mlWeight) * 100).toInt()}% Rules + ${(_mlWeight * 100).toInt()}% ML]\n'
        'Rules (${rulesDecision.adjustmentFactor.toStringAsFixed(2)}): ${rulesDecision.reasoning}\n'
        'ML adjustment: ${mlDecision.adjustmentFactor.toStringAsFixed(2)} '
        '(confidence: ${mlDecision.confidence.toStringAsFixed(2)})';

    return VolumeDecision(
      adjustmentFactor: hybridAdjustment.clamp(0.5, 1.2),
      confidence: hybridConfidence,
      reasoning: hybridReasoning,
      metadata: {
        'strategy': 'hybrid',
        'ml_weight': _mlWeight,
        'rules_adjustment': rulesDecision.adjustmentFactor,
        'ml_adjustment': mlDecision.adjustmentFactor,
        'hybrid_adjustment': hybridAdjustment,
      },
    );
  }

  @override
  ReadinessDecision decideReadiness(FeatureVector features) {
    // Baseline: Reglas científicas (SIEMPRE)
    final rulesDecision = _rules.decideReadiness(features);

    // Si no hay ML o peso es 0, retornar solo reglas
    if (_ml == null || _mlWeight == 0.0) {
      return ReadinessDecision(
        level: rulesDecision.level,
        score: rulesDecision.score,
        confidence: rulesDecision.confidence,
        recommendations: ['[100% Rules]', ...rulesDecision.recommendations],
        metadata: {'strategy': 'hybrid', 'ml_weight': 0.0, 'rules_only': true},
      );
    }

    // Intentar obtener predicción ML
    ReadinessDecision? mlDecision;
    try {
      mlDecision = _ml.decideReadiness(features);
    } catch (e) {
      // ML falló, fallback a 100% reglas
      return ReadinessDecision(
        level: rulesDecision.level,
        score: rulesDecision.score,
        confidence: rulesDecision.confidence,
        recommendations: [
          '[ML failed, fallback 100% Rules]',
          ...rulesDecision.recommendations,
        ],
        metadata: {
          'strategy': 'hybrid',
          'ml_weight': 0.0,
          'ml_error': e.toString(),
        },
      );
    }

    // Weighted average de scores
    final hybridScore =
        rulesDecision.score * (1 - _mlWeight) + mlDecision.score * _mlWeight;

    // Level derivado del score híbrido
    ReadinessLevel level;
    if (hybridScore < 0.3) {
      level = ReadinessLevel.critical;
    } else if (hybridScore < 0.5) {
      level = ReadinessLevel.low;
    } else if (hybridScore < 0.7) {
      level = ReadinessLevel.moderate;
    } else if (hybridScore < 0.85) {
      level = ReadinessLevel.good;
    } else {
      level = ReadinessLevel.excellent;
    }

    // Combinar confidence
    final hybridConfidence =
        (rulesDecision.confidence + mlDecision.confidence) / 2;

    // Mantener recommendations de reglas (explicabilidad)
    final hybridRecommendations = [
      '[Hybrid: ${((1 - _mlWeight) * 100).toInt()}% Rules + ${(_mlWeight * 100).toInt()}% ML]',
      'Rules score: ${rulesDecision.score.toStringAsFixed(2)} (${rulesDecision.level.name})',
      'ML score: ${mlDecision.score.toStringAsFixed(2)} (${mlDecision.level.name})',
      'Hybrid score: ${hybridScore.toStringAsFixed(2)} (${level.name})',
      '',
      ...rulesDecision.recommendations,
    ];

    return ReadinessDecision(
      level: level,
      score: hybridScore.clamp(0.0, 1.0),
      confidence: hybridConfidence,
      recommendations: hybridRecommendations,
      metadata: {
        'strategy': 'hybrid',
        'ml_weight': _mlWeight,
        'rules_score': rulesDecision.score,
        'ml_score': mlDecision.score,
        'hybrid_score': hybridScore,
      },
    );
  }
}
