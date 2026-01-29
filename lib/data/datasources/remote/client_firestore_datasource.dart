import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';

/// Sanitiza recursivamente un Map para Firestore eliminando tipos no soportados
Map<String, dynamic> _sanitizeForFirestore(Map<String, dynamic> data) {
  final result = <String, dynamic>{};

  for (final entry in data.entries) {
    final value = entry.value;

    if (value == null) {
      result[entry.key] = null;
    } else if (value is String || value is num || value is bool) {
      result[entry.key] = value;
    } else if (value is DateTime) {
      result[entry.key] = Timestamp.fromDate(value);
    } else if (value is List) {
      result[entry.key] = value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _sanitizeForFirestore(item);
            } else if (item is Map) {
              return _sanitizeForFirestore(Map<String, dynamic>.from(item));
            } else if (item is String ||
                item is num ||
                item is bool ||
                item == null) {
              return item;
            } else {
              // Skip non-serializable items
              return null;
            }
          })
          .where((item) => item != null)
          .toList();
    } else if (value is Map<String, dynamic>) {
      result[entry.key] = _sanitizeForFirestore(value);
    } else if (value is Map) {
      result[entry.key] = _sanitizeForFirestore(
        Map<String, dynamic>.from(value),
      );
    } else {
      // Skip non-serializable types (classes, functions, etc.)
      debugPrint(
        '⚠️ Skipping non-serializable field "${entry.key}" of type ${value.runtimeType}',
      );
    }
  }

  return result;
}

class RemoteClientSnapshot {
  final String clientId;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final bool deleted;

  RemoteClientSnapshot({
    required this.clientId,
    required this.payload,
    required this.updatedAt,
    required this.deleted,
  });
}

abstract class ClientRemoteDataSource {
  Future<void> upsertClient({
    required String coachId,
    required Client client,
    required bool deleted,
  });

  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  });

  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
  });
}

class ClientFirestoreDataSource implements ClientRemoteDataSource {
  final FirebaseFirestore _firestore;

  ClientFirestoreDataSource(this._firestore);

  @override
  Future<void> upsertClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    final ref = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(client.id);

    // ESTRUCTURA ESTANDARIZADA: {payload, schemaVersion, updatedAt, deleted}
    // El payload contiene el Client.toJson() completo, sanitizado para Firestore
    final clientJson = client.toJson();
    final sanitizedPayload = _sanitizeForFirestore(clientJson);

    final fullPayload = <String, dynamic>{
      'payload': sanitizedPayload,
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': deleted,
    };

    debugPrint('🔥 Upserting client ${client.id} to Firestore...');
    debugPrint(
      '   training.extra keys: ${client.training.extra.keys.join(', ')}',
    );
    debugPrint(
      '   payload.training.extra is Map: ${(fullPayload['payload'] as Map)['training'] is Map}',
    );

    try {
      // ✅ OBLIGATORIO: SetOptions(merge: true) para no perder datos en concurrencia
      await ref.set(fullPayload, SetOptions(merge: true));
      debugPrint('✅ Client ${client.id} synced to Firestore successfully');
    } on FirebaseException catch (e, st) {
      debugPrint(
        '🔥 Firestore upsert failed for client ${client.id}: ${e.code} ${e.message}',
      );
      debugPrint('Full payload keys: ${fullPayload.keys.join(', ')}');
      debugPrint(st.toString());
      rethrow;
    }
  }

  @override
  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  }) async {
    final ref = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(clientId);

    await ref.set({
      'id': clientId,
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'meta': metaData,
    }, SetOptions(merge: true));
  }

  @override
  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
  }) async {
    Query query = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients');

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

      return RemoteClientSnapshot(
        clientId: d.id,
        payload: Map<String, dynamic>.from(data['payload'] ?? {}),
        deleted: data['deleted'] == true,
        updatedAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }
}
