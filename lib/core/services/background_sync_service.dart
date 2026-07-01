import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'dart:convert';

enum SyncQueueProcessOutcome { success, retryableFailure, pending }

class BackgroundSyncService {
  static final BackgroundSyncService instance = BackgroundSyncService._();

  final LocalClientDataSource _localRepository;
  final ClientRemoteDataSource _remoteRepository;
  final RecordRemoteDataSource? _clinicalRecordRemoteRepository;
  final String? Function() _currentCoachIdProvider;

  bool _isSyncing = false;

  BackgroundSyncService._({
    LocalClientDataSource? localRepository,
    ClientRemoteDataSource? remoteRepository,
    RecordRemoteDataSource? clinicalRecordRemoteRepository,
    String? Function()? currentCoachIdProvider,
  }) : _currentCoachIdProvider =
           currentCoachIdProvider ?? _defaultCurrentCoachId,
       _localRepository =
           localRepository ??
           LocalClientDataSourceImpl(DatabaseHelper.instance),
       _remoteRepository =
           remoteRepository ??
           ClientFirestoreDataSource(FirebaseFirestore.instance),
       _clinicalRecordRemoteRepository = clinicalRecordRemoteRepository;

  BackgroundSyncService.test({
    LocalClientDataSource? localRepository,
    ClientRemoteDataSource? remoteRepository,
    RecordRemoteDataSource? clinicalRecordRemoteRepository,
    String? Function()? currentCoachIdProvider,
  }) : _currentCoachIdProvider =
           currentCoachIdProvider ?? _defaultCurrentCoachId,
       _localRepository =
           localRepository ??
           LocalClientDataSourceImpl(DatabaseHelper.instance),
       _remoteRepository =
           remoteRepository ??
           ClientFirestoreDataSource(FirebaseFirestore.instance),
       _clinicalRecordRemoteRepository = clinicalRecordRemoteRepository;

  Future<void> trySyncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final coachId = _resolveCurrentCoachId();
      if (coachId == null) {
        logger.info('Background sync pending: no authenticated coach');
        return;
      }

      final pending = await _localRepository.getUnsyncedClients();
      final pendingDeleted = await _localRepository.getUnsyncedDeletedClients();

      for (final client in pending) {
        await _syncClient(coachId: coachId, client: client, deleted: false);
      }
      for (final client in pendingDeleted) {
        await _syncClient(coachId: coachId, client: client, deleted: true);
      }
    } catch (e, st) {
      logger.warning('Background sync skipped', {
        'error': e.toString(),
        'stackTrace': st.toString(),
      });
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    try {
      await _remoteRepository.upsertClient(
        coachId: coachId,
        client: client,
        deleted: deleted,
      );

      final current = await _localRepository.fetchClientIncludingDeleted(
        client.id,
      );
      if (current == null) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] local client missing after remote success',
          {'clientId': client.id, 'deleted': deleted},
        );
        return;
      }

      if (current.updatedAt != client.updatedAt) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] uploaded snapshot older than local current',
          {
            'clientId': client.id,
            'deleted': deleted,
            'uploadedUpdatedAt': client.updatedAt.toIso8601String(),
            'localUpdatedAt': current.updatedAt.toIso8601String(),
          },
        );
        return;
      }

      await _localRepository.markClientAsSynced(client.id);
    } catch (e, st) {
      logger.warning('Background client sync failed', {
        'clientId': client.id,
        'deleted': deleted,
        'error': e.toString(),
        'stackTrace': st.toString(),
      });
    }
  }

  Future<SyncQueueProcessOutcome> processClientOutboxItem(
    Map<String, dynamic> item,
  ) async {
    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.info('Client outbox pending: no authenticated coach', {
        'queueItemId': item['id'],
      });
      return SyncQueueProcessOutcome.pending;
    }

    final payloadRaw = item['payload'];
    if (payloadRaw is! String) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] payload must be string');
    }

    final decoded = jsonDecode(payloadRaw);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] payload must be map');
    }

    final action = decoded['action'] as String? ?? 'upsert';
    final operationId = decoded['operationId'] as String?;
    final clientPayload = decoded['client'];
    if (clientPayload is! Map<String, dynamic>) {
      throw StateError(
        '[SAVE][OUTBOX_PAYLOAD_INVALID] missing client snapshot',
      );
    }

    final client = Client.fromJson(clientPayload);
    final deleted = action == 'delete';

    try {
      await _remoteRepository.upsertClient(
        coachId: coachId,
        client: client,
        deleted: deleted,
      );

      final currentItem = await SyncQueueHelper.getItemById(
        item['id'] as String,
      );
      if (currentItem == null) {
        return SyncQueueProcessOutcome.success;
      }

      final currentPayloadRaw = currentItem['payload'];
      if (currentPayloadRaw is! String) {
        return SyncQueueProcessOutcome.pending;
      }

      final currentDecoded = jsonDecode(currentPayloadRaw);
      if (currentDecoded is! Map<String, dynamic>) {
        return SyncQueueProcessOutcome.pending;
      }

      if (currentDecoded['operationId'] != operationId) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] queue item replaced before background success',
          {
            'queueItemId': item['id'],
            'clientId': client.id,
            'action': action,
            'pendingOperationId': operationId,
            'currentOperationId': currentDecoded['operationId'],
          },
        );
        return SyncQueueProcessOutcome.pending;
      }

      final current = await _localRepository.fetchClientIncludingDeleted(
        client.id,
      );
      if (current == null) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] local client missing after remote success',
          {'clientId': client.id, 'deleted': deleted},
        );
        return SyncQueueProcessOutcome.pending;
      }

      if (current.updatedAt != client.updatedAt) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] uploaded snapshot older than local current',
          {
            'clientId': client.id,
            'deleted': deleted,
            'uploadedUpdatedAt': client.updatedAt.toIso8601String(),
            'localUpdatedAt': current.updatedAt.toIso8601String(),
          },
        );
        return SyncQueueProcessOutcome.pending;
      }

      await _localRepository.markClientAsSynced(client.id);
      await SyncQueueHelper.markSuccess(item['id'] as String);
      return SyncQueueProcessOutcome.success;
    } catch (e, st) {
      logger.warning('Client outbox sync failed', {
        'queueItemId': item['id'],
        'clientId': client.id,
        'deleted': deleted,
        'error': e.toString(),
        'stackTrace': st.toString(),
      });

      final message = e.toString().toLowerCase();
      if (message.contains('firebase not initialized') ||
          message.contains('no authenticated coach') ||
          message.contains('no auth')) {
        return SyncQueueProcessOutcome.pending;
      }

      return SyncQueueProcessOutcome.retryableFailure;
    }
  }

  Future<SyncQueueProcessOutcome> processClinicalRecordOutboxItem(
    Map<String, dynamic> item,
  ) async {
    final queueDomain = item['domain'] as String;
    final recordDomain = _recordDomainFromQueueDomain(queueDomain);
    if (recordDomain == null) {
      logger.warning('Unsupported clinical outbox domain', {
        'queueItemId': item['id'],
        'domain': queueDomain,
      });
      return SyncQueueProcessOutcome.pending;
    }

    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.info('Clinical record outbox pending: no authenticated coach', {
        'queueItemId': item['id'],
        'domain': queueDomain,
      });
      return SyncQueueProcessOutcome.pending;
    }

    final payloadRaw = item['payload'];
    if (payloadRaw is! String) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] payload must be string');
    }

    final decoded = jsonDecode(payloadRaw);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] payload must be map');
    }

    final action = decoded['action'] as String? ?? 'upsert';
    if (action != 'upsert' && action != 'delete') {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] unsupported action');
    }
    if (action == 'upsert' && !_isClinicalRecordUpsertQueueDomain(queueDomain)) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] invalid upsert domain');
    }
    if (action == 'delete' && !_isClinicalRecordDeleteQueueDomain(queueDomain)) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] invalid delete domain');
    }

    final operationId = decoded['operationId'] as String?;
    final clientId = decoded['clientId'] as String? ?? item['client_id'] as String?;
    final dateKey = decoded['dateKey'] as String? ?? item['date_key'] as String?;

    if (clientId == null || dateKey == null) {
      throw StateError('[SAVE][OUTBOX_PAYLOAD_INVALID] missing record key');
    }

    Map<String, dynamic>? recordJson;
    if (action == 'upsert') {
      final recordPayload = decoded['recordJson'];
      if (recordPayload is! Map<String, dynamic>) {
        throw StateError(
          '[SAVE][OUTBOX_PAYLOAD_INVALID] missing record snapshot',
        );
      }

      if (queueDomain == SyncQueueDomains.anthropometryRecordUpsert) {
        recordJson = AnthropometryRecord.fromJson(recordPayload).toJson();
      } else {
        recordJson = BioChemistryRecord.fromJson(recordPayload).toJson();
      }
    }

    try {
      final clinicalRecordRemoteRepository =
          _clinicalRecordRemoteRepository ??
          RecordFirestoreDataSource(FirebaseFirestore.instance);

      if (action == 'delete') {
        await clinicalRecordRemoteRepository.deleteRecord(
          coachId: coachId,
          clientId: clientId,
          domain: recordDomain,
          dateKey: dateKey,
        );
      } else {
        await clinicalRecordRemoteRepository.upsertRecordByDate(
          coachId: coachId,
          clientId: clientId,
          domain: recordDomain,
          dateKey: dateKey,
          payload: recordJson!,
        );
      }

      final currentItem = await SyncQueueHelper.getItemById(
        item['id'] as String,
      );
      if (currentItem == null) {
        return SyncQueueProcessOutcome.success;
      }

      final currentPayloadRaw = currentItem['payload'];
      if (currentPayloadRaw is! String) {
        return SyncQueueProcessOutcome.pending;
      }

      final currentDecoded = jsonDecode(currentPayloadRaw);
      if (currentDecoded is! Map<String, dynamic>) {
        return SyncQueueProcessOutcome.pending;
      }

      if (currentDecoded['operationId'] != operationId) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] clinical queue item replaced before background success',
          {
            'queueItemId': item['id'],
            'clientId': clientId,
            'domain': queueDomain,
            'dateKey': dateKey,
            'pendingOperationId': operationId,
            'currentOperationId': currentDecoded['operationId'],
          },
        );
        return SyncQueueProcessOutcome.pending;
      }

      await SyncQueueHelper.markSuccess(item['id'] as String);
      return SyncQueueProcessOutcome.success;
    } catch (e, st) {
      logger.warning('Clinical record outbox sync failed', {
        'queueItemId': item['id'],
        'clientId': clientId,
        'domain': queueDomain,
        'dateKey': dateKey,
        'error': e.toString(),
        'stackTrace': st.toString(),
      });

      final message = e.toString().toLowerCase();
      if (message.contains('firebase not initialized') ||
          message.contains('no authenticated coach') ||
          message.contains('no auth')) {
        return SyncQueueProcessOutcome.pending;
      }

      return SyncQueueProcessOutcome.retryableFailure;
    }
  }

  RecordDomain? _recordDomainFromQueueDomain(String queueDomain) {
    switch (queueDomain) {
      case SyncQueueDomains.anthropometryRecordUpsert:
      case SyncQueueDomains.anthropometryRecordDelete:
        return RecordDomain.anthropometry;
      case SyncQueueDomains.biochemistryRecordUpsert:
      case SyncQueueDomains.biochemistryRecordDelete:
        return RecordDomain.biochemistry;
      default:
        return null;
    }
  }

  bool _isClinicalRecordUpsertQueueDomain(String queueDomain) {
    return queueDomain == SyncQueueDomains.anthropometryRecordUpsert ||
        queueDomain == SyncQueueDomains.biochemistryRecordUpsert;
  }

  bool _isClinicalRecordDeleteQueueDomain(String queueDomain) {
    return queueDomain == SyncQueueDomains.anthropometryRecordDelete ||
        queueDomain == SyncQueueDomains.biochemistryRecordDelete;
  }

  String? _resolveCurrentCoachId() {
    try {
      return _currentCoachIdProvider();
    } catch (e, st) {
      logger.error(
        'Failed to resolve current coach id for background sync',
        e,
        st,
      );
      return null;
    }
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
