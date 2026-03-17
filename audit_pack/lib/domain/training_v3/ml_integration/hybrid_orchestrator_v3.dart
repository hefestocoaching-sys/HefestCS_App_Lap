// lib/domain/training_v3/ml_integration/hybrid_orchestrator_v3.dart
//
// ⚠️ EXPERIMENTAL / FUERA DE USO
// Este archivo se conserva solo como referencia histórica.
// No debe usarse en flujos activos ni en producción.

import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/workout_log_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/motor_v3_ml_adapter.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/prediction_recorder_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/ml_config_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml_integration/feature_extractor_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';

/// Orquestador Híbrido del Motor V3
///
/// @deprecated Este orquestador ha sido reemplazado por MotorV3Orchestrator directo.
/// No debe usarse en flujos de producción.
///
/// Combina generación científica pura + refinamientos ML:
///
/// PIPELINE COMPLETO:
/// 1. MotorV3Orchestrator → Programa científico (VME/MAV/MRV)
/// 2. FeatureExtractorV3 → Extrae 45 features
/// 3. MotorV3MLAdapter → Aplica ajustes ML
/// 4. PredictionRecorderV3 → Registra para aprendizaje
/// 5. Retorna programa final + metadata completa
///
/// Versión: 1.0.0 (DEPRECADO)
@Deprecated('EXPERIMENTAL: fuera de uso. Usar MotorV3Orchestrator directamente')
class HybridOrchestratorV3 {
  final MLConfigV3 config;
  final MotorV3MLAdapter _mlAdapter;
  final PredictionRecorderV3 _recorder;
  final Uuid _uuid = const Uuid();

  HybridOrchestratorV3({MLConfigV3? config})
    : config = config ?? MLConfigV3.hybrid(),
      _mlAdapter = MotorV3MLAdapter(config: config),
      _recorder = PredictionRecorderV3();

  /// Genera programa completo con pipeline híbrido
  ///
  /// PARÁMETROS:
  /// - [userProfile]: Perfil del usuario
  /// - [phase]: Fase del programa
  /// - [durationWeeks]: Duración en semanas
  ///
  /// RETORNA:
  /// - Map con programa, metadata ML, explicabilidad
  Future<Map<String, dynamic>> generateHybridProgram({
    required UserProfile userProfile,
    required String phase,
    required int durationWeeks,
  }) async {
    final timestamp = DateTime.now();

    // ═══════════════════════════════════════════════════
    // FASE 1: GENERACIÓN CIENTÍFICA PURA
    // ═══════════════════════════════════════════════════

    logger.info('Generating scientific program');

    final scientificResult = await MotorV3Orchestrator.generateProgram(
      userProfile: userProfile,
      phase: phase,
      durationWeeks: durationWeeks,
    );

    if (!scientificResult['success']) {
      // Generación falló
      return {
        'success': false,
        'errors': scientificResult['errors'],
        'warnings': scientificResult['warnings'],
        'program': null,
      };
    }

    final scientificProgram = scientificResult['program'];
    final scientificPlanConfig = scientificResult['planConfig'];

    if (scientificProgram is! TrainingProgram) {
      // Motor científico retornó planConfig en lugar de TrainingProgram.
      // En este caso, saltamos ML y retornamos el plan directo.
      return {
        'success': true,
        'errors': [],
        'warnings': scientificResult['warnings'] ?? [],
        'program': null,
        'planConfig': scientificPlanConfig,
        'ml': {'applied': false, 'reason': 'scientific_program_missing'},
        'scientific': scientificResult,
      };
    }

    logger.info('Scientific program generated', {
      'programId': scientificProgram.id,
      'totalSets': scientificProgram.weeklyVolumeByMuscle.values.fold(
        0.0,
        (sum, v) => sum + v,
      ),
    });

    // ═══════════════════════════════════════════════════
    // FASE 2: OBTENER DATOS HISTÓRICOS
    // ═══════════════════════════════════════════════════

    logger.info('Fetching recent workout logs', {'limit': 20, 'days': 28});

    final recentLogs = await WorkoutLogRepository.getLogsByUser(
      userId: userProfile.id,
      limit: 20,
      startDate: timestamp.subtract(
        const Duration(days: 28),
      ), // Últimas 4 semanas
    );

    logger.info('Recent workout logs fetched', {'count': recentLogs.length});

    // ═══════════════════════════════════════════════════
    // FASE 3: REFINAMIENTO ML
    // ═══════════════════════════════════════════════════

    logger.info('Applying ML refinements');

    final mlResult = await _mlAdapter.applyMLRefinements(
      scientificProgram: scientificProgram,
      userProfile: userProfile,
      recentLogs: recentLogs,
    );

    final mlApplied = mlResult['ml_applied'] as bool;
    final finalProgram = mlResult['program'] as TrainingProgram;

    if (mlApplied) {
      final adjustments = mlResult['adjustments'] as Map<String, dynamic>;
      final confidence = mlResult['confidence'] as double?;
      logger.info('ML refinements applied', {
        'volumeChangePct': adjustments['volume_change_pct'],
        'readinessLevel': adjustments['readiness_level'],
        'confidence': confidence,
      });
    } else {
      logger.warning('ML refinements not applied', {
        'reason': mlResult['ml_reason'],
      });
    }

    // ═══════════════════════════════════════════════════
    // FASE 4: REGISTRO DE PREDICCIÓN (si ML activado)
    // ═══════════════════════════════════════════════════

    String? predictionId;

    if (mlApplied && config.enablePredictionLogging) {
      logger.info('Recording ML prediction');

      predictionId = _uuid.v4();

      // Extraer features para registro
      final features = FeatureExtractorV3.extractFeatures(
        profile: userProfile,
        recentLogs: recentLogs,
      );

      // Por ahora usamos placeholders
      await _recorder.recordPrediction(
        predictionId: predictionId,
        userId: userProfile.id,
        features: features,
        volumeDecision: VolumeDecision.maintain(), // PLACEHOLDER
        readinessDecision: const ReadinessDecision(
          level: ReadinessLevel.good,
          score: 0.7,
          confidence: 0.8,
        ), // PLACEHOLDER
        strategyUsed: mlResult['strategy_used'] as String,
        scientificProgram: scientificProgram,
        finalProgram: finalProgram,
      );

      logger.info('ML prediction recorded', {'predictionId': predictionId});
    }

    // ═══════════════════════════════════════════════════
    // FASE 5: GENERAR EXPLICABILIDAD
    // ═══════════════════════════════════════════════════

    Map<String, dynamic>? explainability;

    if (mlApplied && config.enableExplainability) {
      logger.info('Generating explainability');

      final features = FeatureExtractorV3.extractFeatures(
        profile: userProfile,
        recentLogs: recentLogs,
      );

      explainability = _mlAdapter.generateExplainability(
        features: features,
        volumeDecision: VolumeDecision.maintain(), // PLACEHOLDER
        readinessDecision: const ReadinessDecision(
          level: ReadinessLevel.good,
          score: 0.7,
          confidence: 0.8,
        ), // PLACEHOLDER
      );
    }

    // ═══════════════════════════════════════════════════
    // RESULTADO FINAL
    // ═══════════════════════════════════════════════════

    final result = {
      'success': true,
      'program': finalProgram,
      'prediction_id': predictionId,

      // Metadata científica
      'scientific': {
        'volume_validation': scientificResult['volume_validation'],
        'config_validation': scientificResult['config_validation'],
        'warnings': scientificResult['warnings'],
      },

      // Metadata ML
      'ml': {
        'applied': mlApplied,
        'reason': mlResult['ml_reason'],
        'strategy': mlResult['strategy_used'],
        'confidence': mlResult['confidence'],
        'adjustments': mlResult['adjustments'],
        'features_used': mlResult['features_used'],
      },

      // Explicabilidad
      'explainability': explainability,

      // Comparación científico vs final
      'comparison': {
        'scientific_volume': scientificProgram.weeklyVolumeByMuscle.values.fold(
          0.0,
          (sum, v) => sum + v,
        ),
        'final_volume': finalProgram.weeklyVolumeByMuscle.values.fold(
          0.0,
          (sum, v) => sum + v,
        ),
        'volume_delta':
            finalProgram.weeklyVolumeByMuscle.values.fold(
              0.0,
              (sum, v) => sum + v,
            ) -
            scientificProgram.weeklyVolumeByMuscle.values.fold(
              0.0,
              (sum, v) => sum + v,
            ),
      },

      // Metadata
      'generated_at': timestamp.toIso8601String(),
      'version': 'hybrid_v3_1.0.0',
    };

    logger.info('Hybrid program generated', {
      'programId': finalProgram.id,
      'mlApplied': mlApplied,
      'finalVolume': (result['comparison'] as Map)['final_volume'],
    });

    return result;
  }

  /// Registra outcome de un programa completado
  Future<void> recordProgramOutcome({
    required String predictionId,
    required List<WorkoutLog> completedLogs,
    bool injuryOccurred = false,
  }) async {
    await _recorder.recordOutcome(
      predictionId: predictionId,
      completedLogs: completedLogs,
      injuryOccurred: injuryOccurred,
    );
  }

  /// Obtiene accuracy del sistema ML
  Future<Map<String, dynamic>> getMLAccuracy({required String userId}) async {
    return await _recorder.calculatePredictionAccuracy(userId: userId);
  }
}
