import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/data/datasources/remote/anthropometry_firestore_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ClinicalRecordOutboxWrite {
  ClinicalRecordOutboxWrite({
    required this.queueItemId,
    required this.operationId,
    required this.domain,
    required this.clientId,
    required this.dateKey,
  });

  final String queueItemId;
  final String operationId;
  final String domain;
  final String clientId;
  final String dateKey;
}

/// Repositorio para push granular de clinical records a Firestore.
///
/// Responsabilidades:
/// - Push fire-and-forget de records individuales por dominio
/// - NO afecta guardado local (local sigue siendo fuente de verdad)
/// - NO falla operaciones si Firestore no está disponible
///
/// Uso:
/// ```dart
/// final repo = ref.read(clinicalRecordsRepositoryProvider);
///
/// // Después de guardar local exitosamente
/// await repo.pushAnthropometryRecord(clientId, record);
/// ```
class ClinicalRecordsRepository {
  final AnthropometryFirestoreDataSource? _anthropometryDataSource;
  final RecordRemoteDataSource? _genericRecordDataSource;
  final FirebaseFirestore? _firestore;
  final String? Function() _currentCoachIdProvider;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  ClinicalRecordsRepository({
    FirebaseFirestore? firestore,
    RecordRemoteDataSource? recordRemoteDataSource,
    String? Function()? currentCoachIdProvider,
  }) : _firestore = firestore,
       _currentCoachIdProvider =
           currentCoachIdProvider ?? _defaultCurrentCoachId,
       _anthropometryDataSource = firestore == null
           ? null
           : AnthropometryFirestoreDataSource(firestore),
       _genericRecordDataSource =
           recordRemoteDataSource ??
           (firestore == null ? null : RecordFirestoreDataSource(firestore));

  /// Push de un registro de antropometría a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/anthropometry_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: Lanza en background sin bloquear
  Future<void> pushAnthropometryRecord(
    String clientId,
    AnthropometryRecord record,
  ) async {
    final outboxWrite = await enqueueAnthropometryRecordUpsert(
      clientId,
      record,
    );
    _pushInBackground(() async {
      final pushed = await _doPushAnthropometryRecord(clientId, record);
      if (pushed) {
        await _markClinicalRecordQueueItemSuccessIfCurrent(outboxWrite);
      }
    });
  }

  Future<ClinicalRecordOutboxWrite> enqueueAnthropometryRecordUpsert(
    String clientId,
    AnthropometryRecord record,
  ) {
    return _enqueueClinicalRecordUpsert(
      domain: SyncQueueDomains.anthropometryRecordUpsert,
      clientId: clientId,
      recordDate: record.date,
      recordJson: record.toJson(),
    );
  }

  Future<void> deleteAnthropometryRecord(
    String clientId,
    DateTime recordDate,
  ) async {
    final outboxWrite = await enqueueAnthropometryRecordDelete(
      clientId,
      recordDate,
    );
    _pushInBackground(() async {
      final pushed = await _doDeleteClinicalRecord(
        clientId: clientId,
        recordDomain: RecordDomain.anthropometry,
        dateKey: outboxWrite.dateKey,
      );
      if (pushed) {
        await _markClinicalRecordQueueItemSuccessIfCurrent(outboxWrite);
      }
    });
  }

  Future<ClinicalRecordOutboxWrite> enqueueAnthropometryRecordDelete(
    String clientId,
    DateTime recordDate,
  ) {
    return _enqueueClinicalRecordDelete(
      domain: SyncQueueDomains.anthropometryRecordDelete,
      clientId: clientId,
      recordDate: recordDate,
    );
  }

  Future<bool> _doPushAnthropometryRecord(
    String clientId,
    AnthropometryRecord record,
  ) async {
    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.warning('No authenticated user, skipping Firestore sync', {
        'clientId': clientId,
      });
      return false;
    }
    final firestore = _firestore;
    final anthropometryDataSource = _anthropometryDataSource;
    if (firestore == null || anthropometryDataSource == null) {
      logger.info('Anthropometry fast-path skipped: no remote datasource', {
        'clientId': clientId,
      });
      return false;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = firestore
          .collection('coaches')
          .doc(coachId)
          .collection('clients')
          .doc(clientId);

      // Check if client exists, create stub if not
      // Use timeout to prevent hanging
      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          // Create a stub client document so the subcollections can be written
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
        // If client check/creation fails, continue anyway
        // Local storage will still work
        logger.warning('Failed to ensure client exists in Firestore', {
          'clientId': clientId,
          'error': e,
        });
      }

      // Now push the anthropometry record
      await anthropometryDataSource
          .upsertAnthropometryRecord(
            coachId: coachId,
            clientId: clientId,
            record: record,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
      return true;
    } catch (e, st) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
      logger.error('Firestore sync failed (local save succeeded)', e, st);
      return false;
    }
  }

  /// Push de un registro de bioquímica a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/biochemistry_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: No bloquea (síncrono)
  Future<void> pushBiochemistryRecord(
    String clientId,
    BioChemistryRecord record,
  ) async {
    final outboxWrite = await enqueueBiochemistryRecordUpsert(
      clientId,
      record,
    );
    _pushInBackground(() async {
      final pushed = await _doPushBiochemistryRecord(clientId, record);
      if (pushed) {
        await _markClinicalRecordQueueItemSuccessIfCurrent(outboxWrite);
      }
    });
  }

  Future<ClinicalRecordOutboxWrite> enqueueBiochemistryRecordUpsert(
    String clientId,
    BioChemistryRecord record,
  ) {
    return _enqueueClinicalRecordUpsert(
      domain: SyncQueueDomains.biochemistryRecordUpsert,
      clientId: clientId,
      recordDate: record.date,
      recordJson: record.toJson(),
    );
  }

  Future<void> deleteBiochemistryRecord(
    String clientId,
    DateTime recordDate,
  ) async {
    final outboxWrite = await enqueueBiochemistryRecordDelete(
      clientId,
      recordDate,
    );
    _pushInBackground(() async {
      final pushed = await _doDeleteClinicalRecord(
        clientId: clientId,
        recordDomain: RecordDomain.biochemistry,
        dateKey: outboxWrite.dateKey,
      );
      if (pushed) {
        await _markClinicalRecordQueueItemSuccessIfCurrent(outboxWrite);
      }
    });
  }

  Future<ClinicalRecordOutboxWrite> enqueueBiochemistryRecordDelete(
    String clientId,
    DateTime recordDate,
  ) {
    return _enqueueClinicalRecordDelete(
      domain: SyncQueueDomains.biochemistryRecordDelete,
      clientId: clientId,
      recordDate: recordDate,
    );
  }

  Future<bool> _doPushBiochemistryRecord(
    String clientId,
    BioChemistryRecord record,
  ) async {
    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.warning('No authenticated user, skipping Firestore sync', {
        'clientId': clientId,
      });
      return false;
    }
    final firestore = _firestore;
    final genericRecordDataSource = _genericRecordDataSource;
    if (firestore == null || genericRecordDataSource == null) {
      logger.info('Biochemistry fast-path skipped: no remote datasource', {
        'clientId': clientId,
      });
      return false;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = firestore
          .collection('coaches')
          .doc(coachId)
          .collection('clients')
          .doc(clientId);

      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
        logger.warning('Failed to ensure client exists in Firestore', {
          'clientId': clientId,
          'error': e,
        });
      }

      final dateKey = _dateFormat.format(record.date);
      final payload = record.toJson();
      final hasData = payload.entries.any(
        (e) => e.key != 'date' && e.value != null,
      );

      if (!hasData) {
        // Evita escribir registros vacíos (solo fecha) que disparan errores de reglas
        return false;
      }

      await genericRecordDataSource
          .upsertRecordByDate(
            coachId: coachId,
            clientId: clientId,
            domain: RecordDomain.biochemistry,
            dateKey: dateKey,
            payload: payload,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
      return true;
    } catch (e, st) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
      logger.error('Firestore sync failed (local save succeeded)', e, st);
      return false;
    }
  }

  /// Push de un registro de nutrición a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/nutrition_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: No bloquea (síncrono)
  void pushNutritionRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) {
    _pushInBackground(() => _doPushNutritionRecord(clientId, recordJson, date));
  }

  Future<void> _doPushNutritionRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) async {
    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.warning('No authenticated user, skipping Firestore sync', {
        'clientId': clientId,
      });
      return;
    }
    final firestore = _firestore;
    final genericRecordDataSource = _genericRecordDataSource;
    if (firestore == null || genericRecordDataSource == null) {
      logger.info('Nutrition fast-path skipped: no remote datasource', {
        'clientId': clientId,
      });
      return;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = firestore
          .collection('coaches')
          .doc(coachId)
          .collection('clients')
          .doc(clientId);

      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
        logger.warning('Failed to ensure client exists in Firestore', {
          'clientId': clientId,
          'error': e,
        });
      }

      final dateKey = _dateFormat.format(date);

      await genericRecordDataSource
          .upsertRecordByDate(
            coachId: coachId,
            clientId: clientId,
            domain: RecordDomain.nutrition,
            dateKey: dateKey,
            payload: recordJson,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
    } catch (e, st) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
      logger.error('Firestore sync failed (local save succeeded)', e, st);
    }
  }

  /// Push de un registro de entrenamiento a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/training_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: No bloquea (síncrono)
  void pushTrainingRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) {
    _pushInBackground(() => _doPushTrainingRecord(clientId, recordJson, date));
  }

  // ignore: unused_element
  Future<void> _doPushTrainingRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) async {
    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.warning('No authenticated user, skipping Firestore sync', {
        'clientId': clientId,
      });
      return;
    }
    final firestore = _firestore;
    final genericRecordDataSource = _genericRecordDataSource;
    if (firestore == null || genericRecordDataSource == null) {
      logger.info('Training fast-path skipped: no remote datasource', {
        'clientId': clientId,
      });
      return;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = firestore
          .collection('coaches')
          .doc(coachId)
          .collection('clients')
          .doc(clientId);

      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
        logger.warning('Failed to ensure client exists in Firestore', {
          'clientId': clientId,
          'error': e,
        });
      }

      final dateKey = _dateFormat.format(date);

      await genericRecordDataSource
          .upsertRecordByDate(
            coachId: coachId,
            clientId: clientId,
            domain: RecordDomain.training,
            dateKey: dateKey,
            payload: recordJson,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
    } catch (e, st) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
      logger.error('Firestore sync failed (local save succeeded)', e, st);
    }
  }

  Future<bool> _doDeleteClinicalRecord({
    required String clientId,
    required RecordDomain recordDomain,
    required String dateKey,
  }) async {
    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.warning('No authenticated user, skipping Firestore record delete', {
        'clientId': clientId,
        'domain': recordDomain.collectionName,
        'dateKey': dateKey,
      });
      return false;
    }

    final genericRecordDataSource = _genericRecordDataSource;
    if (genericRecordDataSource == null) {
      logger.info('Clinical record delete fast-path skipped: no remote datasource', {
        'clientId': clientId,
        'domain': recordDomain.collectionName,
        'dateKey': dateKey,
      });
      return false;
    }

    try {
      await genericRecordDataSource
          .deleteRecord(
            coachId: coachId,
            clientId: clientId,
            domain: recordDomain,
            dateKey: dateKey,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record delete timeout'),
          );
      return true;
    } catch (e, st) {
      logger.error('Firestore record delete failed; outbox remains pending', e, st);
      return false;
    }
  }

  Future<ClinicalRecordOutboxWrite> _enqueueClinicalRecordUpsert({
    required String domain,
    required String clientId,
    required DateTime recordDate,
    required Map<String, dynamic> recordJson,
  }) async {
    final dateKey = _dateFormat.format(recordDate);
    final operationId = const Uuid().v4();
    final updatedAt = DateTime.now().toIso8601String();
    final queueItemId = '${domain}_${clientId}_$dateKey';
    final payload = <String, dynamic>{
      'action': 'upsert',
      'operationId': operationId,
      'clientId': clientId,
      'recordDate': recordDate.toIso8601String(),
      'dateKey': dateKey,
      'recordJson': recordJson,
      'updatedAt': updatedAt,
      'domain': domain,
    };

    await SyncQueueHelper.enqueue(
      domain: domain,
      clientId: clientId,
      dateKey: dateKey,
      payload: jsonEncode(payload),
    );

    return ClinicalRecordOutboxWrite(
      queueItemId: queueItemId,
      operationId: operationId,
      domain: domain,
      clientId: clientId,
      dateKey: dateKey,
    );
  }

  Future<ClinicalRecordOutboxWrite> _enqueueClinicalRecordDelete({
    required String domain,
    required String clientId,
    required DateTime recordDate,
  }) async {
    final dateKey = _dateFormat.format(recordDate);
    final operationId = const Uuid().v4();
    final updatedAt = DateTime.now().toIso8601String();
    final queueItemId = '${domain}_${clientId}_$dateKey';
    final payload = <String, dynamic>{
      'action': 'delete',
      'operationId': operationId,
      'clientId': clientId,
      'recordDate': recordDate.toIso8601String(),
      'dateKey': dateKey,
      'recordJson': <String, dynamic>{'deleted': true},
      'deleted': true,
      'deletedAt': updatedAt,
      'updatedAt': updatedAt,
      'domain': domain,
    };

    await SyncQueueHelper.enqueue(
      domain: domain,
      clientId: clientId,
      dateKey: dateKey,
      payload: jsonEncode(payload),
    );

    return ClinicalRecordOutboxWrite(
      queueItemId: queueItemId,
      operationId: operationId,
      domain: domain,
      clientId: clientId,
      dateKey: dateKey,
    );
  }

  Future<void> _markClinicalRecordQueueItemSuccessIfCurrent(
    ClinicalRecordOutboxWrite outboxWrite,
  ) async {
    final currentItem = await SyncQueueHelper.getItemById(
      outboxWrite.queueItemId,
    );
    if (currentItem == null) return;

    final payload = currentItem['payload'];
    if (payload is! String) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['operationId'] != outboxWrite.operationId) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] clinical queue item replaced before success',
          {
            'queueItemId': outboxWrite.queueItemId,
            'clientId': outboxWrite.clientId,
            'domain': outboxWrite.domain,
            'dateKey': outboxWrite.dateKey,
            'pendingOperationId': outboxWrite.operationId,
            'currentOperationId': decoded['operationId'],
          },
        );
        return;
      }

      await SyncQueueHelper.markSuccess(outboxWrite.queueItemId);
    } catch (e, st) {
      logger.warning('Failed to resolve clinical queue success state', {
        'queueItemId': outboxWrite.queueItemId,
        'clientId': outboxWrite.clientId,
        'domain': outboxWrite.domain,
        'dateKey': outboxWrite.dateKey,
        'error': e.toString(),
        'stackTrace': st.toString(),
      });
    }
  }

  String? _resolveCurrentCoachId() {
    try {
      return _currentCoachIdProvider();
    } catch (e, st) {
      logger.error('Failed to resolve current coach id', e, st);
      return null;
    }
  }

  /// Helper para ejecutar operaciones completamente en background
  /// sin conexión con el flujo principal
  void _pushInBackground(Future<void> Function() operation) {
    // Ejecuta en un Future independiente y captura cualquier error
    unawaited(
      Future<void>(() async {
        try {
          await operation();
        } catch (e, st) {
          logger.error('Background push failed', e, st);
        }
      }),
    );
  }
}

String? _defaultCurrentCoachId() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (e, st) {
    logger.error('Failed to resolve current coach id from FirebaseAuth', e, st);
    return null;
  }
}
