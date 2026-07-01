import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/services/background_sync_service.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

Client buildClient({required String id, required String name}) {
  final profile = ClientProfile(
    id: 'p-$id',
    fullName: name,
    email: '$id@example.com',
    phone: '000',
    country: 'Nowhere',
    occupation: 'Tester',
    objective: 'Test',
  );

  return Client(
    id: id,
    profile: profile,
    history: const ClinicalHistory(),
    training: TrainingProfile.empty(),
    nutrition: const NutritionSettings(),
  );
}

class _StoredClient {
  _StoredClient({
    required this.client,
    required this.deleted,
    required this.synced,
  });

  final Client client;
  final bool deleted;
  final bool synced;

  _StoredClient copyWith({Client? client, bool? deleted, bool? synced}) {
    return _StoredClient(
      client: client ?? this.client,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
    );
  }
}

class _FakeLocalClientDataSource implements LocalClientDataSource {
  _FakeLocalClientDataSource([List<String>? events])
    : events = events ?? <String>[];

  final List<String> events;
  final Map<String, _StoredClient> _store = {};

  int saveCalls = 0;
  int deleteCalls = 0;
  int markSyncedCalls = 0;

  int get unsyncedActiveCount =>
      _store.values.where((entry) => !entry.deleted && !entry.synced).length;

  int get unsyncedDeletedCount =>
      _store.values.where((entry) => entry.deleted && !entry.synced).length;

  @override
  Future<void> deleteClient(String id) async {
    deleteCalls++;
    events.add('local.delete:$id');
    final current = _store[id];
    if (current == null) return;
    _store[id] = current.copyWith(
      client: current.client.copyWith(updatedAt: DateTime.now()),
      deleted: true,
      synced: false,
    );
  }

  @override
  Future<Client?> fetchClient(String id) async {
    final current = _store[id];
    if (current == null || current.deleted) return null;
    return current.client;
  }

  @override
  Future<Client?> fetchClientIncludingDeleted(String id) async {
    return _store[id]?.client;
  }

  @override
  Future<List<Client>> getAllClients() async {
    return _store.values
        .where((entry) => !entry.deleted)
        .map((entry) => entry.client)
        .toList();
  }

  @override
  Future<List<Client>> getUnsyncedClients() async {
    return _store.values
        .where((entry) => !entry.deleted && !entry.synced)
        .map((entry) => entry.client)
        .toList();
  }

  @override
  Future<List<Client>> getUnsyncedDeletedClients() async {
    return _store.values
        .where((entry) => entry.deleted && !entry.synced)
        .map((entry) => entry.client)
        .toList();
  }

  @override
  Future<void> markClientAsSynced(String id) async {
    markSyncedCalls++;
    events.add('local.mark:$id');
    final current = _store[id];
    if (current == null) return;
    _store[id] = current.copyWith(synced: true);
  }

  @override
  Future<void> saveClient(Client client) async {
    await saveClientWithOutbox(client);
  }

  @override
  Future<ClientOutboxWrite> saveClientWithOutbox(Client client) async {
    saveCalls++;
    events.add('local.save:${client.id}');
    final persisted = client.copyWith(updatedAt: DateTime.now());
    _store[client.id] = _StoredClient(
      client: persisted,
      deleted: false,
      synced: false,
    );
    return ClientOutboxWrite(
      persistedClient: persisted,
      queueItemId: 'client_${client.id}_',
      operationId: 'op_${client.id}_$saveCalls',
      action: 'upsert',
    );
  }

  @override
  Future<ClientOutboxWrite> deleteClientWithOutbox(Client client) async {
    deleteCalls++;
    events.add('local.delete:${client.id}');
    final persisted = client.copyWith(updatedAt: DateTime.now());
    _store[client.id] = _StoredClient(
      client: persisted,
      deleted: true,
      synced: false,
    );
    return ClientOutboxWrite(
      persistedClient: persisted,
      queueItemId: 'client_${client.id}_',
      operationId: 'del_${client.id}_$deleteCalls',
      action: 'delete',
    );
  }
}

class _FakeClientRemoteDataSource implements ClientRemoteDataSource {
  _FakeClientRemoteDataSource([List<String>? events])
    : events = events ?? <String>[];

  final List<String> events;
  int upsertCalls = 0;
  Object? errorToThrow;
  Completer<void>? pendingCompleter;

  @override
  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
    int? limit,
  }) async {
    return const [];
  }

  @override
  Future<void> upsertClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    upsertCalls++;
    events.add('remote.upsert:${client.id}');
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final completer = pendingCompleter;
    if (completer != null) {
      return completer.future;
    }
  }

  @override
  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  }) async {}
}

void main() {
  group('ClientRepository sync contract', () {
    test(
      'save local success + remote success marks synced only after remote success',
      () {
        final events = <String>[];
        final local = _FakeLocalClientDataSource(events);
        final remote = _FakeClientRemoteDataSource(events);
        final repository = ClientRepository(
          local: local,
          remote: remote,
          currentCoachIdProvider: () => 'coach-1',
        );
        final client = buildClient(id: 'client-1', name: 'Client 1');

        fakeAsync((async) {
          unawaited(repository.saveClient(client));
          async.flushMicrotasks();
          expect(local.saveCalls, 1);
          expect(remote.upsertCalls, 0);

          async.elapse(const Duration(milliseconds: 700));
          async.flushMicrotasks();

          expect(remote.upsertCalls, 1);
          expect(local.markSyncedCalls, 1);
          expect(events, <String>[
            'local.save:client-1',
            'remote.upsert:client-1',
            'local.mark:client-1',
          ]);
        });
      },
    );

    test('permission-denied does not mark synced', () {
      final local = _FakeLocalClientDataSource();
      final remote = _FakeClientRemoteDataSource();
      remote.errorToThrow = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'denied',
      );
      final repository = ClientRepository(
        local: local,
        remote: remote,
        currentCoachIdProvider: () => 'coach-1',
      );
      final client = buildClient(id: 'client-2', name: 'Client 2');

      fakeAsync((async) {
        unawaited(repository.saveClient(client));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 700));
        async.flushMicrotasks();

        expect(local.saveCalls, 1);
        expect(remote.upsertCalls, 1);
        expect(local.markSyncedCalls, 0);
        expect(local.unsyncedActiveCount, 1);
      });
    });

    test('payload invalid does not mark synced', () {
      final local = _FakeLocalClientDataSource();
      final remote = _FakeClientRemoteDataSource();
      remote.errorToThrow = StateError(
        '[SAVE][REMOTE_PAYLOAD_INVALID] '
        'clientId=client-3 invalidPath=payloadRoot.payload.bad',
      );
      final repository = ClientRepository(
        local: local,
        remote: remote,
        currentCoachIdProvider: () => 'coach-1',
      );
      final client = buildClient(id: 'client-3', name: 'Client 3');

      fakeAsync((async) {
        unawaited(repository.saveClient(client));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 700));
        async.flushMicrotasks();

        expect(local.saveCalls, 1);
        expect(remote.upsertCalls, 1);
        expect(local.markSyncedCalls, 0);
        expect(local.unsyncedActiveCount, 1);
      });
    });

    test('no auth user keeps local pending and skips remote push', () {
      final local = _FakeLocalClientDataSource();
      final remote = _FakeClientRemoteDataSource();
      final repository = ClientRepository(
        local: local,
        remote: remote,
        currentCoachIdProvider: () => null,
      );
      final client = buildClient(id: 'client-4', name: 'Client 4');

      fakeAsync((async) {
        unawaited(repository.saveClient(client));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 700));
        async.flushMicrotasks();

        expect(local.saveCalls, 1);
        expect(remote.upsertCalls, 0);
        expect(local.markSyncedCalls, 0);
        expect(local.unsyncedActiveCount, 1);
      });
    });

    test('stale push does not mark synced after a newer local save', () {
      final events = <String>[];
      final local = _FakeLocalClientDataSource(events);
      final remote = _FakeClientRemoteDataSource(events)
        ..pendingCompleter = Completer<void>();
      final repository = ClientRepository(
        local: local,
        remote: remote,
        currentCoachIdProvider: () => 'coach-1',
      );
      final clientA = buildClient(id: 'client-5', name: 'Client 5 A');
      final clientB = buildClient(id: 'client-5', name: 'Client 5 B');

      fakeAsync((async) {
        unawaited(repository.saveClient(clientA));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 700));
        async.flushMicrotasks();

        expect(remote.upsertCalls, 1);

        unawaited(repository.saveClient(clientB));
        async.flushMicrotasks();
        expect(local.saveCalls, 2);

        remote.pendingCompleter!.complete();
        async.flushMicrotasks();

        expect(local.markSyncedCalls, 0);
        expect(events, <String>[
          'local.save:client-5',
          'remote.upsert:client-5',
          'local.save:client-5',
        ]);
      });
    });
  });

  group('BackgroundSyncService sync contract', () {
    test('remote success marks synced', () async {
      final events = <String>[];
      final local = _FakeLocalClientDataSource(events);
      final remote = _FakeClientRemoteDataSource(events);
      final client = buildClient(id: 'client-6', name: 'Client 6');
      await local.saveClient(client);

      final service = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remote,
        currentCoachIdProvider: () => 'coach-1',
      );

      await service.trySyncPendingData();

      expect(remote.upsertCalls, 1);
      expect(local.markSyncedCalls, 1);
      expect(events, <String>[
        'local.save:client-6',
        'remote.upsert:client-6',
        'local.mark:client-6',
      ]);
    });

    test('permission-denied does not mark synced', () async {
      final local = _FakeLocalClientDataSource();
      final remote = _FakeClientRemoteDataSource()
        ..errorToThrow = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'denied',
        );
      final client = buildClient(id: 'client-7', name: 'Client 7');
      await local.saveClient(client);

      final service = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remote,
        currentCoachIdProvider: () => 'coach-1',
      );

      await service.trySyncPendingData();

      expect(remote.upsertCalls, 1);
      expect(local.markSyncedCalls, 0);
      expect(local.unsyncedActiveCount, 1);
    });

    test(
      'no auth user skips background sync and keeps local pending',
      () async {
        final local = _FakeLocalClientDataSource();
        final remote = _FakeClientRemoteDataSource();
        final client = buildClient(id: 'client-8', name: 'Client 8');
        await local.saveClient(client);

        final service = BackgroundSyncService.test(
          localRepository: local,
          remoteRepository: remote,
          currentCoachIdProvider: () => null,
        );

        await service.trySyncPendingData();

        expect(remote.upsertCalls, 0);
        expect(local.markSyncedCalls, 0);
        expect(local.unsyncedActiveCount, 1);
      },
    );
  });
}
