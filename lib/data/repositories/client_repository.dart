import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';

class _PendingRemoteWrite {
  _PendingRemoteWrite({
    required this.persistedClient,
    required this.queueItemId,
    required this.operationId,
    required this.action,
  });

  final Client persistedClient;
  final String queueItemId;
  final String operationId;
  final String action;
}

class ClientRepository {
  final LocalClientDataSource _local;
  final ClientRemoteDataSource _remote;
  final String? Function() _currentCoachIdProvider;
  final Duration _remotePushDebounceDuration;
  final Map<String, Timer> _remotePushDebounce = {};
  final Map<String, _PendingRemoteWrite> _pendingRemotePush = {};
  bool _remoteSyncTemporarilyDisabled = false;

  ClientRepository({
    required LocalClientDataSource local,
    required ClientRemoteDataSource remote,
    String? Function()? currentCoachIdProvider,
    Duration remotePushDebounceDuration = const Duration(milliseconds: 700),
  }) : _local = local,
       _remote = remote,
       _currentCoachIdProvider =
           currentCoachIdProvider ?? _defaultCurrentCoachId,
       _remotePushDebounceDuration = remotePushDebounceDuration;

  // === Local operations with remote push ===
  Future<void> saveClient(Client client) async {
    // 1) Guardado local + outbox durable
    final outboxWrite = await _local.saveClientWithOutbox(client);

    // 2) Push remoto inmediato (fire-and-forget)
    _pendingRemotePush[client.id] = _PendingRemoteWrite(
      persistedClient: outboxWrite.persistedClient,
      queueItemId: outboxWrite.queueItemId,
      operationId: outboxWrite.operationId,
      action: outboxWrite.action,
    );
    _remotePushDebounce[client.id]?.cancel();
    _remotePushDebounce[client.id] = Timer(_remotePushDebounceDuration, () {
      final latest = _pendingRemotePush.remove(client.id);
      if (latest == null) return;
      unawaited(_pushClientRemote(latest, deleted: false).catchError((_) {}));
    });
  }

  Future<List<Client>> getClients() => _local.getAllClients();

  Future<Client?> getClientById(String id) => _local.fetchClient(id);

  Future<void> deleteClient(String id) async {
    // 1) Obtener cliente antes de eliminar (para push con deleted:true)
    final client = await _local.fetchClient(id);
    if (client == null) return;

    // 2) Eliminación local + outbox durable
    final outboxWrite = await _local.deleteClientWithOutbox(client);

    // 3) Push remoto inmediato (marcar como deleted en Firestore)
    _remotePushDebounce[id]?.cancel();
    _pendingRemotePush[id] = _PendingRemoteWrite(
      persistedClient: outboxWrite.persistedClient,
      queueItemId: outboxWrite.queueItemId,
      operationId: outboxWrite.operationId,
      action: outboxWrite.action,
    );
    unawaited(
      _pushClientRemote(
        _pendingRemotePush[id]!,
        deleted: true,
      ).catchError((_) {}),
    );
  }

  // === Remote operations (preparados pero sin activar) ===
  Future<void> upsertRemoteClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    try {
      await _remote.upsertClient(
        coachId: coachId,
        client: client,
        deleted: deleted,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        logger.warning('upsertRemoteClient skipped: permission denied', {
          'coachId': coachId,
          'clientId': client.id,
          'deleted': deleted,
        });
        rethrow;
      }
      rethrow;
    }
  }

  Future<List<RemoteClientSnapshot>> fetchRemoteClients({
    required String coachId,
    DateTime? since,
  }) {
    return _remote.fetchClients(coachId: coachId, since: since).catchError((e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        logger.warning('fetchRemoteClients skipped: permission denied', {
          'coachId': coachId,
        });
        return <RemoteClientSnapshot>[];
      }
      throw e;
    });
  }

  /// Helper privado: push silencioso a Firestore (no rompe flujos locales)
  Future<void> _pushClientRemote(
    _PendingRemoteWrite pendingWrite, {
    required bool deleted,
  }) async {
    if (_remoteSyncTemporarilyDisabled) return;

    final coachId = _resolveCurrentCoachId();
    if (coachId == null) {
      logger.info('Remote client sync pending: no authenticated coach', {
        'clientId': pendingWrite.persistedClient.id,
        'deleted': deleted,
      });
      return;
    }

    try {
      await _remote.upsertClient(
        coachId: coachId,
        client: pendingWrite.persistedClient,
        deleted: deleted,
      );
      await _markClientAsSyncedIfCurrent(
        client: pendingWrite.persistedClient,
        deleted: deleted,
      );
      await _markQueueItemSuccessIfCurrent(pendingWrite);
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        _remoteSyncTemporarilyDisabled = true;
        logger.warning('Remote client sync disabled for this session', {
          'reason': 'firestore_permission_denied',
          'clientId': pendingWrite.persistedClient.id,
          'coachId': coachId,
          'deleted': deleted,
          'errorCode': e.code,
          'errorMessage': e.message,
        });
        return;
      }

      logger.error('Remote client sync failed', e, st);
    } catch (e, st) {
      logger.error('Remote client sync failed', e, st);
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

  Future<void> _markClientAsSyncedIfCurrent({
    required Client client,
    required bool deleted,
  }) async {
    final current = await _local.fetchClientIncludingDeleted(client.id);
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

    await _local.markClientAsSynced(client.id);
  }

  Future<void> _markQueueItemSuccessIfCurrent(
    _PendingRemoteWrite pendingWrite,
  ) async {
    final currentItem = await SyncQueueHelper.getItemById(
      pendingWrite.queueItemId,
    );
    if (currentItem == null) {
      logger.info('[SAVE][REMOTE_QUEUE_ALREADY_RESOLVED]', {
        'queueItemId': pendingWrite.queueItemId,
        'clientId': pendingWrite.persistedClient.id,
      });
      return;
    }

    final payload = currentItem['payload'];
    if (payload is! String) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['operationId'] != pendingWrite.operationId) {
        logger.warning(
          '[SAVE][REMOTE_PUSH_STALE] queue item replaced before success',
          {
            'queueItemId': pendingWrite.queueItemId,
            'clientId': pendingWrite.persistedClient.id,
            'pendingOperationId': pendingWrite.operationId,
            'currentOperationId': decoded['operationId'],
            'action': pendingWrite.action,
          },
        );
        return;
      }

      await SyncQueueHelper.markSuccess(pendingWrite.queueItemId);
    } catch (e, st) {
      logger.warning('Failed to resolve queue success state', {
        'queueItemId': pendingWrite.queueItemId,
        'clientId': pendingWrite.persistedClient.id,
        'error': e.toString(),
        'stackTrace': st.toString(),
      });
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
