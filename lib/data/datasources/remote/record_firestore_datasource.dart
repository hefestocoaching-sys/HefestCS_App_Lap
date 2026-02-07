// ignore_for_file: avoid_print
import 'dart:async';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/firestore_sanitizer.dart';

/// Dominios de registros soportados en Firestore.
/// Cada dominio tiene su propia subcolección bajo coaches/{coachId}/clients/{clientId}
enum RecordDomain {
  anthropometry('anthropometry_records'),
  biochemistry('biochemistry_records'),
  nutrition('nutrition_records'),
  training('training_records');

  final String collectionName;
  const RecordDomain(this.collectionName);
}

/// Snapshot de un record remoto desde Firestore.
class RemoteRecordSnapshot {
  final String dateKey; // yyyy-MM-dd
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final bool deleted;
  final int schemaVersion;

  RemoteRecordSnapshot({
    required this.dateKey,
    required this.payload,
    required this.updatedAt,
    required this.deleted,
    required this.schemaVersion,
  });
}

/// Contrato abstracto para datasource de records por dominio y fecha.
abstract class RecordRemoteDataSource {
  /// Inserta o actualiza un record por fecha.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/{domain}/{dateKey}
  ///
  /// - [coachId]: ID del coach autenticado
  /// - [clientId]: ID del cliente
  /// - [domain]: Dominio del record (anthropometry, biochemistry, etc.)
  /// - [dateKey]: Fecha en formato yyyy-MM-dd
  /// - [payload]: Datos del record (toJson del entity)
  /// - [deleted]: Si el record está marcado como eliminado (soft delete)
  Future<void> upsertRecordByDate({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    required String dateKey,
    required Map<String, dynamic> payload,
    bool deleted = false,
  });

  /// Obtiene todos los records de un dominio para un cliente.
  ///
  /// - [coachId]: ID del coach autenticado
  /// - [clientId]: ID del cliente
  /// - [domain]: Dominio del record
  /// - [since]: Opcional, solo records actualizados después de esta fecha
  Future<List<RemoteRecordSnapshot>> fetchRecords({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    DateTime? since,
  });

  /// Marca un record como eliminado (soft delete).
  ///
  /// - [coachId]: ID del coach autenticado
  /// - [clientId]: ID del cliente
  /// - [domain]: Dominio del record
  /// - [dateKey]: Fecha en formato yyyy-MM-dd
  Future<void> deleteRecord({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    required String dateKey,
  });
}

/// Implementación Firestore del datasource de records.
class RecordFirestoreDataSource implements RecordRemoteDataSource {
  final FirebaseFirestore _firestore;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  RecordFirestoreDataSource(this._firestore);

  @override
  Future<void> upsertRecordByDate({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    required String dateKey,
    required Map<String, dynamic> payload,
    bool deleted = false,
  }) async {
    final sanitizedPayload = sanitizeForFirestore(payload);

    final ref = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(clientId)
        .collection(domain.collectionName)
        .doc(dateKey);

    try {
      final invalidPath = findInvalidFirestorePath({
        'payload': sanitizedPayload,
        'schemaVersion': 1,
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': deleted,
        'dateKey': dateKey,
      });
      if (invalidPath != null) {
        print('🔥 Record payload invalid at: $invalidPath');
      }

      await ref.set({
        'dateKey': dateKey,
        'schemaVersion': 1,
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': deleted,
        'payload': sanitizedPayload,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error in upsertRecordByDate: $e');
      print(
        'Details - coachId: $coachId, clientId: $clientId, domain: ${domain.collectionName}, dateKey: $dateKey',
      );
      print(
        'Payload snapshot: ${sanitizedPayload.map((k, v) => MapEntry(k, v?.runtimeType))}',
      );
      try {
        print('Payload json: ${jsonEncode(sanitizedPayload)}');
      } catch (_) {
        // ignore json encode failures
      }
      rethrow;
    }
  }

  // Sanitization moved to shared firestore_sanitizer.dart

  @override
  Future<List<RemoteRecordSnapshot>> fetchRecords({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    DateTime? since,
  }) async {
    Query query = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(clientId)
        .collection(domain.collectionName);

    if (since != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(since),
      );
    }

    final snap = await query.get();

    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final ts = data['updatedAt'] as Timestamp?;

      return RemoteRecordSnapshot(
        dateKey: d.id,
        payload: Map<String, dynamic>.from(data['payload'] ?? {}),
        deleted: data['deleted'] == true,
        schemaVersion: data['schemaVersion'] as int? ?? 1,
        updatedAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  @override
  Future<void> deleteRecord({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    required String dateKey,
  }) async {
    final ref = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(clientId)
        .collection(domain.collectionName)
        .doc(dateKey);

    // Verificar si el documento existe antes de actualizar
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      // El documento no existe, no hay nada que borrar
      return;
    }

    await ref.update({
      'deleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Helper: Convierte DateTime a dateKey (yyyy-MM-dd).
  String dateToKey(DateTime date) => _dateFormat.format(date);

  /// Helper: Convierte dateKey (yyyy-MM-dd) a DateTime.
  DateTime keyToDate(String dateKey) => _dateFormat.parse(dateKey);
}
