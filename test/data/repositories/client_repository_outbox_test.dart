import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/services/background_sync_service.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

class _FakeRemoteClientDataSource implements ClientRemoteDataSource {
  int upsertCalls = 0;
  Object? errorToThrow;
  final List<Map<String, dynamic>> requests = [];

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
    requests.add({
      'coachId': coachId,
      'clientId': client.id,
      'deleted': deleted,
      'updatedAt': client.updatedAt.toIso8601String(),
    });
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  }) async {}
}

Future<void> _clearTables() async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('sync_queue');
  await db.delete('training_interviews');
  await db.delete('clients');
}

void main() {
  group('ClientRepository outbox contract', () {
    late LocalClientDataSourceImpl local;
    late _FakeRemoteClientDataSource remote;
    late ClientRepository repository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseHelper.instance.database;
    });

    setUp(() async {
      await _clearTables();
      local = LocalClientDataSourceImpl(DatabaseHelper.instance);
      remote = _FakeRemoteClientDataSource();
      repository = ClientRepository(
        local: local,
        remote: remote,
        currentCoachIdProvider: () => 'coach-1',
        remotePushDebounceDuration: const Duration(hours: 1),
      );
    });

    test('saveClient enqueues durable outbox event', () async {
      final client = buildClient(id: 'client-outbox-1', name: 'Outbox 1');

      await repository.saveClient(client);

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final item = pending.single;
      expect(item['domain'], 'client');
      expect(item['client_id'], client.id);
      expect(item['date_key'], '');
      expect(item['retry_count'], 0);
      expect(item['last_attempt'], isNull);
      expect(item['error_message'], isNull);
      expect(item['payload'], isA<String>());
      expect(item['id'], 'client_${client.id}_');
    });

    test('deleteClient enqueues tombstone outbox event', () async {
      final client = buildClient(id: 'client-outbox-2', name: 'Outbox 2');
      await repository.saveClient(client);

      await repository.deleteClient(client.id);

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final item = pending.single;
      expect(item['domain'], 'client');
      expect(item['client_id'], client.id);
      final payload = item['payload'] as String;
      expect(payload.contains('"action":"delete"'), isTrue);
      expect(payload.contains('"deleted":true'), isTrue);
    });

    test('background success clears queue and marks synced', () async {
      final client = buildClient(id: 'client-outbox-3', name: 'Outbox 3');
      await repository.saveClient(client);
      final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;

      final service = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remote,
        currentCoachIdProvider: () => 'coach-1',
      );

      final outcome = await service.processClientOutboxItem(item);

      expect(outcome, SyncQueueProcessOutcome.success);
      expect(remote.upsertCalls, 1);
      expect((await SyncQueueHelper.getPendingItems(limit: 20)), isEmpty);
      expect((await local.fetchClient(client.id))?.updatedAt, isNotNull);
      final persisted = await local.fetchClient(client.id);
      expect(persisted, isNotNull);
      expect(
        (await DatabaseHelper.instance.getClientById(client.id))?.id,
        client.id,
      );
    });

    test(
      'remote permission-denied keeps queue pending via retry path',
      () async {
        final client = buildClient(id: 'client-outbox-4', name: 'Outbox 4');
        await repository.saveClient(client);
        final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;
        remote.errorToThrow = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'denied',
        );

        final service = BackgroundSyncService.test(
          localRepository: local,
          remoteRepository: remote,
          currentCoachIdProvider: () => 'coach-1',
        );

        final outcome = await service.processClientOutboxItem(item);

        expect(outcome, SyncQueueProcessOutcome.retryableFailure);
        expect(remote.upsertCalls, 1);
        final pending = await SyncQueueHelper.getPendingItems(limit: 20);
        expect(pending, hasLength(1));
        expect(pending.single['retry_count'], 0);
        expect(
          (await DatabaseHelper.instance.getClientById(client.id))?.id,
          client.id,
        );
      },
    );

    test(
      'remote invalid payload keeps queue pending via retry path',
      () async {
        final client = buildClient(id: 'client-outbox-5', name: 'Outbox 5');
        await repository.saveClient(client);
        final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;
        remote.errorToThrow = StateError(
          '[SAVE][REMOTE_PAYLOAD_INVALID] '
          'clientId=${client.id} invalidPath=payloadRoot.payload.bad',
        );

        final service = BackgroundSyncService.test(
          localRepository: local,
          remoteRepository: remote,
          currentCoachIdProvider: () => 'coach-1',
        );

        final outcome = await service.processClientOutboxItem(item);

        expect(outcome, SyncQueueProcessOutcome.retryableFailure);
        expect(remote.upsertCalls, 1);
        final pending = await SyncQueueHelper.getPendingItems(limit: 20);
        expect(pending, hasLength(1));
        expect(pending.single['id'], item['id']);
        expect(pending.single['retry_count'], 0);
        final unsynced = await local.getUnsyncedClients();
        expect(unsynced.map((client) => client.id), contains(client.id));
      },
    );
  });
}
