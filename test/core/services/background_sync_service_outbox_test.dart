import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/services/background_sync_service.dart';
import 'package:hcs_app_lap/core/services/sync_service.dart';
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
  group('Background sync outbox scheduler', () {
    late LocalClientDataSourceImpl local;
    late _FakeRemoteClientDataSource remote;
    late ClientRepository repository;
    late BackgroundSyncService backgroundService;

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
      backgroundService = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remote,
        currentCoachIdProvider: () => 'coach-1',
      );
      SyncService.instance.setBackgroundSyncServiceForTest(backgroundService);
      SyncService.instance.stop();
    });

    tearDown(() {
      SyncService.instance.clearBackgroundSyncServiceForTest();
    });

    test(
      'queue survives before timer and sync service processes later',
      () async {
        final client = buildClient(id: 'client-bg-1', name: 'BG 1');
        await repository.saveClient(client);
        await Future<void>.delayed(Duration.zero);

        final pendingBefore = await SyncQueueHelper.getPendingItems(limit: 20);
        expect(pendingBefore, hasLength(1));

        await SyncService.instance.processPendingQueueOnce();

        expect(remote.upsertCalls, 1);
        expect(await SyncQueueHelper.getPendingItems(limit: 20), isEmpty);
        expect(
          await DatabaseHelper.instance.getClientById(client.id),
          isNotNull,
        );
      },
    );

    test('stale queued item does not close newer queued operation', () async {
      final clientA = buildClient(id: 'client-bg-2', name: 'BG A');
      final clientB = buildClient(id: 'client-bg-2', name: 'BG B');

      await repository.saveClient(clientA);
      await Future<void>.delayed(Duration.zero);
      final staleItem = (await SyncQueueHelper.getPendingItems(
        limit: 20,
      )).single;
      await repository.saveClient(clientB);
      await Future<void>.delayed(Duration.zero);

      final service = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remote,
        currentCoachIdProvider: () => 'coach-1',
      );

      final outcome = await service.processClientOutboxItem(staleItem);

      expect(outcome, SyncQueueProcessOutcome.pending);
      expect(remote.upsertCalls, 1);
      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final payload = pending.single['payload'] as String;
      expect(payload.contains('BG B'), isTrue);
    });

    test('no auth keeps queue pending', () async {
      final client = buildClient(id: 'client-bg-3', name: 'BG 3');
      await repository.saveClient(client);
      await Future<void>.delayed(Duration.zero);

      final service = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remote,
        currentCoachIdProvider: () => null,
      );

      final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;
      final outcome = await service.processClientOutboxItem(item);

      expect(outcome, SyncQueueProcessOutcome.pending);
      expect(remote.upsertCalls, 0);
      expect(await SyncQueueHelper.getPendingItems(limit: 20), hasLength(1));
    });

    test('invalid remote payload does not close queue as success', () async {
      final client = buildClient(id: 'client-bg-5', name: 'BG 5');
      await repository.saveClient(client);
      await Future<void>.delayed(Duration.zero);
      remote.errorToThrow = StateError(
        '[SAVE][REMOTE_PAYLOAD_INVALID] '
        'clientId=${client.id} invalidPath=payloadRoot.payload.bad',
      );

      final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;
      final outcome = await backgroundService.processClientOutboxItem(item);

      expect(outcome, SyncQueueProcessOutcome.retryableFailure);
      expect(remote.upsertCalls, 1);
      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['id'], item['id']);
      expect(pending.single['retry_count'], 0);
      final unsynced = await local.getUnsyncedClients();
      expect(unsynced.map((client) => client.id), contains(client.id));
    });

    test('delete client produces durable delete outbox', () async {
      final client = buildClient(id: 'client-bg-4', name: 'BG 4');
      await repository.saveClient(client);
      await Future<void>.delayed(Duration.zero);
      await repository.deleteClient(client.id);

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final payload = pending.single['payload'] as String;
      expect(payload.contains('"action":"delete"'), isTrue);
      expect(payload.contains('"deleted":true'), isTrue);
    });
  });
}
