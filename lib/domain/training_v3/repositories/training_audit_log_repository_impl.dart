import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/training_audit_log_repository.dart';

/// Implementación de Firestore para TrainingAuditLogRepository.
class TrainingAuditLogRepositoryImpl implements TrainingAuditLogRepository {
  final FirebaseFirestore _firestore;

  TrainingAuditLogRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String _getCollectionPath(String userId) => 'users/$userId/audit_logs';

  @override
  Future<void> saveLogEntry(TrainingAuditLogEntry entry) async {
    try {
      final docRef = _firestore
          .collection(_getCollectionPath(entry.userId))
          .doc();

      // Asignar ID si no tiene (aunque el modelo no tiene ID, Firestore lo genera)
      // El modelo TrainingAuditLogEntry suele no tener ID propio, usamos el de Firestore implícito.

      await docRef.set(entry.toJson());

      debugPrint('[AuditRepo] Saved log: ${entry.eventType} | ${entry.title}');
    } catch (e) {
      debugPrint('[AuditRepo] Error saving log entry: $e');
      rethrow;
    }
  }

  @override
  Future<List<TrainingAuditLogEntry>> getLogsForWeek({
    required String userId,
    required int weekNumber,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_getCollectionPath(userId))
          .where('weekNumber', isEqualTo: weekNumber)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TrainingAuditLogEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[AuditRepo] Error getting logs for week $weekNumber: $e');
      return [];
    }
  }

  @override
  Future<List<TrainingAuditLogEntry>> getLogsForMuscle({
    required String userId,
    required String muscle,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_getCollectionPath(userId))
          .where('muscleAffected', isEqualTo: muscle)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TrainingAuditLogEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[AuditRepo] Error getting logs for muscle $muscle: $e');
      return [];
    }
  }
}
