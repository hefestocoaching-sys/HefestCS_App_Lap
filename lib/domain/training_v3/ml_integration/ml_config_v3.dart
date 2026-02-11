// lib/domain/training_v3/ml_integration/ml_config_v3.dart

/// Configuración del sistema ML para Motor V3
///
/// Define pesos, umbrales y estrategias de combinación.
///
/// Versión: 1.0.0
class MLConfigV3 {
  /// Peso del componente ML (0.0-1.0)
  /// - 0.0 = 100% reglas científicas (baseline)
  /// - 0.3 = 70% reglas + 30% ML (recomendado)
  /// - 1.0 = 100% ML (solo con datos suficientes)
  final double mlWeight;

  /// Mínimo de datos históricos para activar ML
  /// Si el usuario tiene menos datos, usar solo reglas.
  final int minHistoricalSessions;

  /// Confianza mínima para aplicar ajuste ML
  /// Si la predicción ML tiene confianza < threshold, ignorar.
  final double minMLConfidence;

  /// Activar registro de predicciones para entrenamiento futuro
  final bool enablePredictionLogging;

  /// Activar explicabilidad detallada
  final bool enableExplainability;

  const MLConfigV3({
    this.mlWeight = 0.3, // 70% reglas + 30% ML (default)
    this.minHistoricalSessions = 10,
    this.minMLConfidence = 0.6,
    this.enablePredictionLogging = true,
    this.enableExplainability = true,
  });

  /// Configuración conservadora (solo reglas)
  factory MLConfigV3.rulesOnly() {
    return const MLConfigV3(mlWeight: 0.0, enablePredictionLogging: false);
  }

  /// Configuración balanceada (híbrida)
  factory MLConfigV3.hybrid() {
    return const MLConfigV3();
  }

  /// Configuración agresiva (más ML)
  factory MLConfigV3.mlFocused() {
    return const MLConfigV3(
      mlWeight: 0.5,
      minHistoricalSessions: 20,
      minMLConfidence: 0.7,
    );
  }

  /// Valida si se debe usar ML para un usuario
  bool shouldUseML({required int userSessionCount}) {
    return mlWeight > 0.0 && userSessionCount >= minHistoricalSessions;
  }

  /// Valida si una predicción ML es confiable
  bool isPredictionReliable({required double confidence}) {
    return confidence >= minMLConfidence;
  }
}
