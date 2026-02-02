// lib/domain/training_v3/ml_integration/motor_v3_ml_adapter.dart

import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/feature_extractor_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/ml_config_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/hybrid_strategy.dart';

/// Adaptador entre Motor V3 (científico) y Sistema ML (legacy)
///
/// Responsabilidades:
/// - Convertir UserProfile → FeatureVector legacy
/// - Aplicar ajustes ML al programa científico
/// - Decidir cuándo usar ML vs solo reglas
/// - Logging y explicabilidad
///
/// Versión: 1.0.0
class MotorV3MLAdapter {
  final MLConfigV3 config;
  final DecisionStrategy _strategy;

  MotorV3MLAdapter({MLConfigV3? config, DecisionStrategy? customStrategy})
    : config = config ?? MLConfigV3.hybrid(),
      _strategy =
          customStrategy ??
          (config?.mlWeight == 0.0
              ? RuleBasedStrategy()
              : HybridStrategy(mlWeight: config?.mlWeight ?? 0.3));

  /// Ajusta un programa científico con refinamientos ML
  ///
  /// FLUJO:
  /// 1. Extraer features del usuario
  /// 2. Obtener decisión ML (volumen, readiness)
  /// 3. Validar confianza de la predicción
  /// 4. Aplicar ajustes si es confiable
  /// 5. Retornar programa ajustado + metadata
  ///
  /// PARÁMETROS:
  /// - [scientificProgram]: Programa base generado con reglas científicas
  /// - [userProfile]: Perfil del usuario
  /// - [recentLogs]: Logs recientes (opcional)
  ///
  /// RETORNA:
  /// - Map con programa ajustado + metadata ML
  Future<Map<String, dynamic>> applyMLRefinements({
    required TrainingProgram scientificProgram,
    required UserProfile userProfile,
    List<WorkoutLog>? recentLogs,
  }) async {
    // PASO 1: Decidir si usar ML
    final userSessionCount = recentLogs?.length ?? 0;

    if (!config.shouldUseML(userSessionCount: userSessionCount)) {
      // Insuficientes datos → solo reglas
      return {
        'program': scientificProgram,
        'ml_applied': false,
        'ml_reason':
            'Insuficientes datos históricos ($userSessionCount < ${config.minHistoricalSessions})',
        'strategy_used': 'rules_only',
        'adjustments': <String, dynamic>{},
      };
    }

    // PASO 2: Extraer features
    final features = FeatureExtractorV3.extractFeatures(
      profile: userProfile,
      recentLogs: recentLogs,
    );

    // PASO 3: Convertir a FeatureVector legacy (para compatibilidad)
    final featureVector = _convertToLegacyFeatureVector(features);

    // PASO 4: Obtener decisiones ML
    VolumeDecision volumeDecision;
    ReadinessDecision readinessDecision;

    try {
      volumeDecision = _strategy.decideVolume(featureVector);
      readinessDecision = _strategy.decideReadiness(featureVector);
    } catch (e) {
      // ML falló → fallback a programa sin ajustes
      return {
        'program': scientificProgram,
        'ml_applied': false,
        'ml_reason': 'Error en predicción ML: $e',
        'strategy_used': 'fallback_rules',
        'adjustments': <String, dynamic>{},
      };
    }

    // PASO 5: Validar confianza
    if (!config.isPredictionReliable(confidence: volumeDecision.confidence)) {
      return {
        'program': scientificProgram,
        'ml_applied': false,
        'ml_reason':
            'Confianza ML insuficiente (${volumeDecision.confidence.toStringAsFixed(2)} < ${config.minMLConfidence})',
        'strategy_used': _strategy.name,
        'prediction': {
          'volume': volumeDecision.adjustmentFactor,
          'readiness': readinessDecision.level.name,
          'confidence': volumeDecision.confidence,
        },
        'adjustments': <String, dynamic>{},
      };
    }

    // PASO 6: Aplicar ajustes al programa
    final adjustedProgram = _applyVolumeAdjustment(
      program: scientificProgram,
      volumeDecision: volumeDecision,
      readinessDecision: readinessDecision,
    );

    // PASO 7: Generar metadata
    final adjustments = {
      'volume_adjustment_factor': volumeDecision.adjustmentFactor,
      'volume_change_pct': ((volumeDecision.adjustmentFactor - 1.0) * 100)
          .toStringAsFixed(1),
      'readiness_level': readinessDecision.level.name,
      'readiness_score': readinessDecision.score,
      'ml_reasoning': volumeDecision.reasoning,
      'recommendations': readinessDecision.recommendations,
    };

    return {
      'program': adjustedProgram,
      'ml_applied': true,
      'ml_reason': 'Ajuste ML aplicado exitosamente',
      'strategy_used': _strategy.name,
      'confidence': volumeDecision.confidence,
      'adjustments': adjustments,
      'features_used': features.length,
    };
  }

  /// Aplica ajuste de volumen al programa
  TrainingProgram _applyVolumeAdjustment({
    required TrainingProgram program,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
  }) {
    final adjustmentFactor = volumeDecision.adjustmentFactor;

    // Si ajuste es ~1.0, no cambiar nada
    if ((adjustmentFactor - 1.0).abs() < 0.05) {
      return program;
    }

    // Ajustar volumen por músculo
    final adjustedVolume = program.weeklyVolumeByMuscle.map(
      (muscle, volume) =>
          MapEntry(muscle, (volume * adjustmentFactor).roundToDouble()),
    );

    // Crear programa ajustado
    return program.copyWith(
      weeklyVolumeByMuscle: adjustedVolume,
      notes: _buildAdjustmentNotes(
        originalNotes: program.notes,
        volumeDecision: volumeDecision,
        readinessDecision: readinessDecision,
      ),
    );
  }

  /// Construye notas explicativas del ajuste ML
  String _buildAdjustmentNotes({
    String? originalNotes,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
  }) {
    final buffer = StringBuffer();

    if (originalNotes != null && originalNotes.isNotEmpty) {
      buffer.writeln(originalNotes);
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('AJUSTES ML APLICADOS');
    buffer.writeln('═══════════════════════════════════════════');

    final changePct = ((volumeDecision.adjustmentFactor - 1.0) * 100)
        .toStringAsFixed(1);
    final direction = volumeDecision.adjustmentFactor > 1.0 ? '↑' : '↓';

    buffer.writeln('Volumen: $direction ${changePct.replaceAll('-', '')}%');
    buffer.writeln('Readiness: ${readinessDecision.level.name.toUpperCase()}');
    buffer.writeln(
      'Confianza: ${(volumeDecision.confidence * 100).toStringAsFixed(0)}%',
    );
    buffer.writeln();
    buffer.writeln('Razón: ${volumeDecision.reasoning}');

    if (readinessDecision.recommendations.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Recomendaciones:');
      for (final rec in readinessDecision.recommendations) {
        buffer.writeln('• $rec');
      }
    }

    return buffer.toString();
  }

  /// Convierte features V3 a FeatureVector legacy
  ///
  /// NOTA: Esto es un adapter temporal. Idealmente, el ML legacy
  /// debería migrar al nuevo formato de features.
  dynamic _convertToLegacyFeatureVector(Map<String, double> features) {
    // PLACEHOLDER: Por ahora retornamos el Map
    // En producción, instanciar FeatureVector legacy correctamente

    // TODO: Implementar conversión real cuando integremos con ML legacy
    // final legacyVector = FeatureVector(
    //   ageYearsNorm: features['age_norm']!,
    //   genderMaleEncoded: features['gender_male']!,
    //   ...
    // );

    return features; // Placeholder
  }

  /// Genera explicabilidad detallada del ajuste ML
  Map<String, dynamic> generateExplainability({
    required Map<String, double> features,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
  }) {
    if (!config.enableExplainability) {
      return {'enabled': false};
    }

    // Top 10 features más influyentes (por valor absoluto)
    final sortedFeatures = features.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final topFeatures = sortedFeatures
        .take(10)
        .map(
          (e) => {
            'feature': e.key,
            'value': e.value,
            'normalized': (e.value * 100).toStringAsFixed(1),
          },
        )
        .toList();

    return {
      'enabled': true,
      'strategy': _strategy.name,
      'top_features': topFeatures,
      'volume_decision': {
        'adjustment': volumeDecision.adjustmentFactor,
        'confidence': volumeDecision.confidence,
        'reasoning': volumeDecision.reasoning,
        'metadata': volumeDecision.metadata,
      },
      'readiness_decision': {
        'level': readinessDecision.level.name,
        'score': readinessDecision.score,
        'confidence': readinessDecision.confidence,
        'recommendations': readinessDecision.recommendations,
      },
    };
  }
}
