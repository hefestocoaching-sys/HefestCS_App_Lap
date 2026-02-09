// lib/domain/training_v3/ml_integration/prediction_recorder_v3.dart

import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/utils/firestore_sanitizer.dart';

/// Registrador de predicciones ML para entrenamiento futuro
///
/// Almacena predicciones (input + output) en Firestore para:
/// - Evaluar accuracy del modelo ML
/// - Re-entrenar modelos con datos reales
/// - Detectar drift en predicciones
/// - Auditoría y debugging
///
/// Versión: 1.0.0
class PredictionRecorderV3 {
  final FirebaseFirestore _firestore;
  final String _collection = 'ml_predictions_v3';

  PredictionRecorderV3({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Registra una predicción inicial (sin outcome aún)
  ///
  /// PARÁMETROS:
  /// - [predictionId]: ID único de la predicción
  /// - [userId]: ID del usuario
  /// - [features]: Features usadas para la predicción
  /// - [volumeDecision]: Decisión de volumen predicha
  /// - [readinessDecision]: Decisión de readiness predicha
  /// - [strategyUsed]: Estrategia ML usada
  /// - [scientificProgram]: Programa base (antes de ML)
  /// - [finalProgram]: Programa final (después de ML)
  Future<void> recordPrediction({
    required String predictionId,
    required String userId,
    required Map<String, double> features,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
    required String strategyUsed,
    required TrainingProgram scientificProgram,
    required TrainingProgram finalProgram,
  }) async {
    try {
      final payload = {
        // Metadata
        'prediction_id': predictionId,
        'user_id': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'strategy_used': strategyUsed,

        // Input (features)
        'features': features,
        'features_count': features.length,

        // Prediction (output)
        'prediction': {
          'volume_adjustment': volumeDecision.adjustmentFactor,
          'volume_confidence': volumeDecision.confidence,
          'volume_reasoning': volumeDecision.reasoning,
          'readiness_level': readinessDecision.level.name,
          'readiness_score': readinessDecision.score,
          'readiness_confidence': readinessDecision.confidence,
        },

        // Programas (para comparación)
        'program_scientific': {
          'id': scientificProgram.id,
          'phase': scientificProgram.phase,
          'total_volume': scientificProgram.weeklyVolumeByMuscle.values.fold(
            0.0,
            (total, v) => total + v,
          ),
        },
        'program_final': {
          'id': finalProgram.id,
          'phase': finalProgram.phase,
          'total_volume': finalProgram.weeklyVolumeByMuscle.values.fold(
            0.0,
            (total, v) => total + v,
          ),
        },

        // Outcome (se llenará después)
        'outcome': null,
        'outcome_recorded': false,

        // Status
        'status': 'pending',
      };

      await _firestore
          .collection(_collection)
          .doc(predictionId)
          .set(sanitizeForFirestore(payload));

      developer.log('✅ Predicción ML registrada: $predictionId');
    } catch (e) {
      developer.log('❌ Error al registrar predicción ML: $e');
      // No lanzar error - el registro es opcional
    }
  }

  /// Actualiza una predicción con el outcome real
  ///
  /// PARÁMETROS:
  /// - [predictionId]: ID de la predicción a actualizar
  /// - [completedLogs]: Logs de entrenamientos completados
  /// - [actualAdherence]: Adherencia real promedio
  /// - [actualFatigue]: Fatiga real promedio
  /// - [injuryOccurred]: Si hubo lesión
  Future<void> recordOutcome({
    required String predictionId,
    required List<WorkoutLog> completedLogs,
    double? actualAdherence,
    double? actualFatigue,
    bool injuryOccurred = false,
  }) async {
    try {
      // Calcular métricas del outcome
      final avgAdherence =
          actualAdherence ??
          (completedLogs.isEmpty
              ? 0.0
              : completedLogs.fold(
                      0.0,
                      (total, l) => total + l.adherencePercentage,
                    ) /
                    completedLogs.length);

      final avgRpe = completedLogs.isEmpty
          ? 0.0
          : completedLogs.fold(0.0, (total, l) => total + l.sessionRpe) /
                completedLogs.length;

      final avgPrs = completedLogs.isEmpty
          ? 0.0
          : completedLogs.fold(
                  0.0,
                  (total, l) => total + l.perceivedRecoveryStatus,
                ) /
                completedLogs.length;

      final avgDoms = completedLogs.isEmpty
          ? 0.0
          : completedLogs.fold(0.0, (total, l) => total + l.muscleSoreness) /
                completedLogs.length;

      await _firestore.collection(_collection).doc(predictionId).update({
        'outcome': {
          'adherence': avgAdherence / 100.0,
          'avg_rpe': avgRpe,
          'avg_prs': avgPrs,
          'avg_doms': avgDoms,
          'fatigue': actualFatigue ?? avgDoms,
          'injury_occurred': injuryOccurred,
          'sessions_completed': completedLogs.length,
          'recorded_at': FieldValue.serverTimestamp(),
        },
        'outcome_recorded': true,
        'status': 'completed',
      });

      developer.log('✅ Outcome registrado para predicción: $predictionId');
    } catch (e) {
      developer.log('❌ Error al registrar outcome: $e');
    }
  }

  /// Obtiene predicciones pendientes de outcome para un usuario
  Future<List<Map<String, dynamic>>> getPendingPredictions({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .where('outcome_recorded', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      developer.log('❌ Error al obtener predicciones pendientes: $e');
      return [];
    }
  }

  /// Calcula accuracy de predicciones completadas
  Future<Map<String, dynamic>> calculatePredictionAccuracy({
    required String userId,
    int sampleSize = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .where('outcome_recorded', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(sampleSize)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'has_data': false,
          'message': 'No hay predicciones completadas',
        };
      }

      final predictions = snapshot.docs.map((doc) => doc.data()).toList();

      // Calcular métricas de accuracy
      double totalVolumeError = 0.0;
      // double totalReadinessError = 0.0; // No usado aún
      int correctReadiness = 0;

      for (final pred in predictions) {
        final predicted = pred['prediction'] as Map<String, dynamic>;
        final outcome = pred['outcome'] as Map<String, dynamic>?;

        if (outcome == null) continue;

        // Error de volumen (MAE)
        // final volumeAdjustment = predicted['volume_adjustment'] as double; // No usado aún
        final actualAdherence = outcome['adherence'] as double;
        // Si adherencia alta → volumen fue correcto
        final volumeError = (1.0 - actualAdherence).abs();
        totalVolumeError += volumeError;

        // Accuracy de readiness
        final predictedReadiness = predicted['readiness_level'] as String;
        final actualFatigue = outcome['avg_doms'] as double;
        final actualReadiness = _inferReadinessFromFatigue(actualFatigue);

        if (predictedReadiness == actualReadiness) {
          correctReadiness++;
        }
      }

      final avgVolumeError = totalVolumeError / predictions.length;
      final readinessAccuracy = correctReadiness / predictions.length;

      return {
        'has_data': true,
        'sample_size': predictions.length,
        'volume_mae': avgVolumeError,
        'volume_accuracy': 1.0 - avgVolumeError,
        'readiness_accuracy': readinessAccuracy,
        'overall_accuracy': ((1.0 - avgVolumeError) + readinessAccuracy) / 2,
      };
    } catch (e) {
      developer.log('❌ Error al calcular accuracy: $e');
      return {'has_data': false, 'error': e.toString()};
    }
  }

  /// Infiere readiness level desde fatiga real
  String _inferReadinessFromFatigue(double avgDoms) {
    if (avgDoms >= 8) return 'critical';
    if (avgDoms >= 6) return 'low';
    if (avgDoms >= 4) return 'moderate';
    if (avgDoms >= 2) return 'good';
    return 'excellent';
  }

  /// Limpia predicciones antiguas (>6 meses)
  Future<int> cleanupOldPredictions() async {
    try {
      final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));

      final snapshot = await _firestore
          .collection(_collection)
          .where('timestamp', isLessThan: sixMonthsAgo)
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      developer.log('✅ Limpiadas $deletedCount predicciones antiguas');
      return deletedCount;
    } catch (e) {
      developer.log('❌ Error al limpiar predicciones: $e');
      return 0;
    }
  }
}
