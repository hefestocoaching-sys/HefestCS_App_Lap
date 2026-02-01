import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';

/// Nivel de readiness (disposición) del atleta para entrenar
enum ReadinessLevel {
  /// Requiere deload o descanso activo
  critical,

  /// Reducir volumen significativamente
  low,

  /// Mantener volumen conservador
  moderate,

  /// Volumen normal
  good,

  /// Puede manejar volumen alto
  excellent,
}

/// Decisión de ajuste de volumen
///
/// Contiene el factor de ajuste (multiplicador) y metadata
/// para trazabilidad y explicabilidad.
class VolumeDecision {
  /// Factor de ajuste para volumen (0.5 - 1.2)
  /// - 0.5 = reducir 50% (deload crítico)
  /// - 0.7 = reducir 30% (fatiga alta)
  /// - 0.85 = reducir 15% (fatiga moderada)
  /// - 1.0 = mantener volumen
  /// - 1.05 = aumentar 5% (progresión conservadora)
  /// - 1.08 = aumentar 8% (progresión normal)
  /// - 1.1 = aumentar 10% (progresión agresiva)
  /// - 1.2 = aumentar 20% (atleta avanzado con capacidad)
  final double adjustmentFactor;

  /// Confianza en la decisión (0.0 - 1.0)
  /// - Reglas científicas: 0.80-0.90 (alta confianza)
  /// - ML con poco datos: 0.40-0.60 (baja confianza)
  /// - Hybrid: combinación ponderada
  final double confidence;

  /// Explicación textual de la decisión (para coach)
  /// Ej: "PRS bajo (4/10) + RPE alto (8/10) → reducir volumen 30%"
  final String reasoning;

  /// Metadata adicional (para debugging, audit logs)
  final Map<String, dynamic> metadata;

  const VolumeDecision({
    required this.adjustmentFactor,
    required this.confidence,
    required this.reasoning,
    this.metadata = const {},
  });

  /// Crea decisión de mantener volumen (baseline)
  factory VolumeDecision.maintain({String? reasoning}) {
    return VolumeDecision(
      adjustmentFactor: 1.0,
      confidence: 0.85,
      reasoning: reasoning ?? 'Mantener volumen actual',
      metadata: const {'type': 'maintain'},
    );
  }

  /// Crea decisión de deload (reducción significativa)
  factory VolumeDecision.deload({
    required String reasoning,
    double factor = 0.7,
  }) {
    return VolumeDecision(
      adjustmentFactor: factor,
      confidence: 0.90, // Alta confianza en deloads (seguridad)
      reasoning: reasoning,
      metadata: {'type': 'deload', 'factor': factor},
    );
  }

  /// Crea decisión de progresión (aumento conservador)
  factory VolumeDecision.progress({
    required String reasoning,
    double factor = 1.05,
  }) {
    return VolumeDecision(
      adjustmentFactor: factor,
      confidence: 0.85,
      reasoning: reasoning,
      metadata: {'type': 'progress', 'factor': factor},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adjustmentFactor': adjustmentFactor,
      'confidence': confidence,
      'reasoning': reasoning,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'VolumeDecision(factor: ${adjustmentFactor.toStringAsFixed(2)}, '
        'confidence: ${confidence.toStringAsFixed(2)})';
  }
}

/// Decisión de readiness (estado de preparación)
class ReadinessDecision {
  /// Nivel de readiness categórico
  final ReadinessLevel level;

  /// Score numérico de readiness (0.0 - 1.0)
  /// Calculado desde features (PRS, sleep, fatigue, etc.)
  final double score;

  /// Confianza en la evaluación (0.0 - 1.0)
  final double confidence;

  /// Recomendaciones para el coach/atleta
  /// Ej: ["Mejorar higiene del sueño", "Reducir estrés laboral"]
  final List<String> recommendations;

  /// Metadata adicional
  final Map<String, dynamic> metadata;

  const ReadinessDecision({
    required this.level,
    required this.score,
    required this.confidence,
    this.recommendations = const [],
    this.metadata = const {},
  });

  /// Indica si necesita deload inmediato
  bool get needsDeload => level == ReadinessLevel.critical;

  /// Indica si necesita reducir volumen
  bool get needsVolumeReduction =>
      level == ReadinessLevel.low || level == ReadinessLevel.critical;

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'score': score,
      'confidence': confidence,
      'recommendations': recommendations,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'ReadinessDecision(level: ${level.name}, score: ${score.toStringAsFixed(2)})';
  }
}

/// Interfaz para estrategias de decisión (Rules, ML, Hybrid)
///
/// Implementa el patrón Strategy para permitir intercambiar
/// algoritmos de decisión sin cambiar el motor.
abstract class DecisionStrategy {
  /// Nombre de la estrategia
  /// Ej: "RuleBased_Israetel_v1", "NeuralNetwork_v2", "Hybrid_70R30ML"
  String get name;

  /// Versión de la estrategia
  String get version;

  /// Indica si esta estrategia puede entrenarse con datos
  bool get isTrainable;

  /// Decide ajuste de volumen basado en features
  VolumeDecision decideVolume(FeatureVector features);

  /// Evalúa readiness basado en features
  ReadinessDecision decideReadiness(FeatureVector features);
}
