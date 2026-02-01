import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';

/// Estrategia basada en Machine Learning (PLACEHOLDER)
///
/// Esta clase es un placeholder para futuro desarrollo.
/// Requiere:
/// 1. Dataset de entrenamiento (TrainingExample con labels)
/// 2. Modelo entrenado (TensorFlow Lite .tflite file)
/// 3. Integración con tflite_flutter package
///
/// TODO: Implementar cuando tengamos suficientes datos (>1000 ejemplos)
class MLModelStrategy implements DecisionStrategy {
  // Placeholder para TensorFlow Lite interpreter
  // final Interpreter _interpreter;

  @override
  String get name => 'NeuralNetwork_Placeholder';

  @override
  String get version => '0.0.1-alpha';

  @override
  bool get isTrainable => true;

  @override
  VolumeDecision decideVolume(FeatureVector features) {
    // TODO: Implementar inferencia con TensorFlow Lite
    //
    // Pseudocódigo:
    // 1. final input = features.toTensor();
    // 2. final output = _interpreter.run(input);
    // 3. final adjustment = output[0]; // Primera salida: factor 0.5-1.2
    // 4. final confidence = output[1]; // Segunda salida: confidence 0-1
    // 5. return VolumeDecision(adjustment, confidence, 'ML prediction');

    throw UnimplementedError(
      'MLModelStrategy requiere modelo entrenado. '
      'Usa RuleBasedStrategy o HybridStrategy por ahora.',
    );
  }

  @override
  ReadinessDecision decideReadiness(FeatureVector features) {
    // TODO: Implementar inferencia con TensorFlow Lite
    //
    // Pseudocódigo:
    // 1. final input = features.toTensor();
    // 2. final output = _interpreterReadiness.run(input);
    // 3. final score = output[0]; // Readiness score 0-1
    // 4. final confidence = output[1];
    // 5. final level = _scoreToLevel(score);
    // 6. return ReadinessDecision(level, score, confidence, []);

    throw UnimplementedError(
      'MLModelStrategy requiere modelo entrenado. '
      'Usa RuleBasedStrategy o HybridStrategy por ahora.',
    );
  }
}
