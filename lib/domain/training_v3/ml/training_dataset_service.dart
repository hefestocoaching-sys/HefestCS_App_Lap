import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';

/// Servicio para persistencia de datos de entrenamiento (prediction-outcome pairs)
/// para entrenamiento posterior de modelos ML.
///
/// Estructura Firestore:
/// training_datasets/
///   user_[userID]/
///     decisions/ - decision_[timestamp]/ contains features and decision
///     outcomes/ - outcome_[decisionID]/ contains sessionRPEActual, setsCompleted, reactionScore, soreness48h, timestamp
///     prediction_errors/ - error_[timestamp]/ contains decision, outcome, error_type, feedback
///
class TrainingDatasetService {
  final FirebaseFirestore _firestore;
  final String _userId;

  /// Máximo de registros a mantener por usuario (rotación automática)
  static const _maxRecordsPerUser = 500;

  TrainingDatasetService({required String userId, FirebaseFirestore? firestore})
    : _userId = userId,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Guardar decisión + features para posterior análisis
  Future<String> recordDecision(
    FeatureVector features,
    VolumeDecision volumeDecision,
    ReadinessDecision readinessDecision,
  ) async {
    final timestamp = DateTime.now();
    final docId = 'decision_${timestamp.millisecondsSinceEpoch}';

    final strategy =
        readinessDecision.metadata['strategy'] ??
        volumeDecision.metadata['strategy'] ??
        'unknown';
    final version = readinessDecision.metadata['version'] ?? 'unknown';

    try {
      await _firestore
          .collection('training_datasets')
          .doc('user_$_userId')
          .collection('decisions')
          .doc(docId)
          .set({
            'features': features.toJson(),
            'volumeDecision': volumeDecision.toJson(),
            'readinessDecision': readinessDecision.toJson(),
            'timestamp': timestamp,
            'strategy': strategy,
            'version': version,
          });

      // Limpiar si excedemos límite
      await _rotateIfNeeded();

      return docId;
    } catch (e) {
      throw Exception('Error saving decision: $e');
    }
  }

  /// Registrar resultado real post-sesión
  Future<void> recordOutcome(
    String decisionId, {
    required double sessionRPEActual,
    required int setsCompleted,
    required double reactionScore, // 1-10
    required double soreness48h, // 0-10
    String? notes,
  }) async {
    final timestamp = DateTime.now();

    try {
      await _firestore
          .collection('training_datasets')
          .doc('user_$_userId')
          .collection('outcomes')
          .doc('outcome_$decisionId')
          .set({
            'decisionId': decisionId,
            'sessionRPEActual': sessionRPEActual,
            'setsCompleted': setsCompleted,
            'reactionScore': reactionScore,
            'soreness48h': soreness48h,
            'notes': notes,
            'timestamp': timestamp,
          });
    } catch (e) {
      throw Exception('Error saving outcome: $e');
    }
  }

  /// Registrar error de predicción (para debugging + reentrenamiento)
  Future<void> recordPredictionError(
    VolumeDecision volumeDecision,
    ReadinessDecision readinessDecision,
    Map<String, dynamic> actualOutcome, {
    required String errorType,
    String? feedback,
  }) async {
    final timestamp = DateTime.now();

    try {
      await _firestore
          .collection('training_datasets')
          .doc('user_$_userId')
          .collection('prediction_errors')
          .doc('error_${timestamp.millisecondsSinceEpoch}')
          .set({
            'volumeDecision': volumeDecision.toJson(),
            'readinessDecision': readinessDecision.toJson(),
            'actualOutcome': actualOutcome,
            'errorType': errorType, // WRONG_CALL, WRONG_INTENSITY, etc
            'feedback': feedback,
            'timestamp': timestamp,
          });
    } catch (e) {
      throw Exception('Error saving prediction error: $e');
    }
  }

  /// Obtener dataset completo para análisis/ML training
  Future<List<Map<String, dynamic>>> getDataset() async {
    try {
      final decisionsQuery = await _firestore
          .collection('training_datasets')
          .doc('user_$_userId')
          .collection('decisions')
          .get();

      final decisions = decisionsQuery.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      // Enriquecer con outcomes correspondientes
      final enriched = <Map<String, dynamic>>[];

      for (final decision in decisions) {
        final decisionId = decision['docId'] as String;
        final outcomeDoc = await _firestore
            .collection('training_datasets')
            .doc('user_$_userId')
            .collection('outcomes')
            .doc('outcome_$decisionId')
            .get();

        if (outcomeDoc.exists) {
          enriched.add({...decision, 'outcome': outcomeDoc.data()});
        }
      }

      return enriched;
    } catch (e) {
      throw Exception('Error fetching dataset: $e');
    }
  }

  /// Obtener estadísticas de precisión por estrategia
  Future<Map<String, dynamic>> getStrategyStats() async {
    try {
      final dataset = await getDataset();

      final statsByStrategy = <String, List<Map<String, dynamic>>>{};

      for (final record in dataset) {
        if (record['outcome'] != null) {
          final strategy = record['strategy'] ?? 'unknown';
          statsByStrategy.putIfAbsent(strategy, () => []).add(record);
        }
      }

      final stats = <String, dynamic>{};

      for (final entry in statsByStrategy.entries) {
        final strategy = entry.key;
        final records = entry.value;

        // Calcular accuracy (si recomendación fue correcta)
        int correctPredictions = 0;

        for (final record in records) {
          final adjustment =
              record['volumeDecision']['adjustmentFactor'] as num? ?? 1.0;
          final rpeActual =
              record['outcome']['sessionRPEActual'] as num? ?? 0.0;

          // Heurística simple: alinear ajuste de volumen con RPE real
          bool isCorrect = false;
          if (adjustment < 0.85 && rpeActual < 5) {
            isCorrect = true;
          }
          if (adjustment >= 0.85 &&
              adjustment <= 1.05 &&
              rpeActual >= 5 &&
              rpeActual < 7) {
            isCorrect = true;
          }
          if (adjustment > 1.05 && rpeActual >= 7) {
            isCorrect = true;
          }

          if (isCorrect) {
            correctPredictions++;
          }
        }

        stats[strategy] = {
          'totalPredictions': records.length,
          'accuracy': records.isNotEmpty
              ? correctPredictions / records.length
              : 0.0,
          'avgConfidence': records.isNotEmpty
              ? records
                        .map((r) => r['volumeDecision']['confidence'] as double)
                        .reduce((a, b) => a + b) /
                    records.length
              : 0.0,
        };
      }

      return stats;
    } catch (e) {
      throw Exception('Error calculating strategy stats: $e');
    }
  }

  /// Limpiar registros antiguos si excedemos límite
  Future<void> _rotateIfNeeded() async {
    try {
      final decisionsQuery = await _firestore
          .collection('training_datasets')
          .doc('user_$_userId')
          .collection('decisions')
          .orderBy('timestamp', descending: true)
          .limit(_maxRecordsPerUser + 1)
          .get();

      if (decisionsQuery.docs.length > _maxRecordsPerUser) {
        final batch = _firestore.batch();

        // Borrar los más antiguos
        for (var i = _maxRecordsPerUser; i < decisionsQuery.docs.length; i++) {
          batch.delete(decisionsQuery.docs[i].reference);
        }

        await batch.commit();
      }
    } catch (e) {
      // Log error pero no fallar la operación
      // Usar logger en lugar de print en producción
      // logger.warning('Error rotating dataset: $e');
    }
  }

  /// Exportar dataset a CSV para análisis externo
  Future<String> exportToCSV() async {
    try {
      final dataset = await getDataset();

      final buffer = StringBuffer();

      // Header
      buffer.writeln(
        'timestamp,strategy,adjustmentFactor,confidence,readinessScore,sessionRPEActual,setsCompleted,reactionScore,features_json',
      );

      // Rows
      for (final record in dataset) {
        if (record['outcome'] != null) {
          final timestamp = record['timestamp'];
          final strategy = record['strategy'] ?? 'unknown';
          final adjustment = record['volumeDecision']['adjustmentFactor'];
          final confidence = record['volumeDecision']['confidence'];
          final readinessScore = record['readinessDecision']['score'];
          final rpe = record['outcome']['sessionRPEActual'];
          final sets = record['outcome']['setsCompleted'];
          final reaction = record['outcome']['reactionScore'];

          // Features como JSON escapado
          final featuresJson = record['features'].toString().replaceAll(
            '"',
            '\\"',
          );

          buffer.writeln(
            '$timestamp,$strategy,$adjustment,$confidence,$readinessScore,$rpe,$sets,$reaction,"$featuresJson"',
          );
        }
      }

      return buffer.toString();
    } catch (e) {
      throw Exception('Error exporting to CSV: $e');
    }
  }
}
