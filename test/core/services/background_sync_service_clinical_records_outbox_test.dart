import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/services/background_sync_service.dart';
import 'package:hcs_app_lap/core/services/sync_service.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeRemoteClientDataSource implements ClientRemoteDataSource {
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
  }) async {}

  @override
  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  }) async {}
}

class _FakeClinicalRecordRemoteDataSource implements RecordRemoteDataSource {
  int upsertCalls = 0;
  int deleteCalls = 0;
  Object? errorToThrow;
  final List<Map<String, dynamic>> requests = [];
  final List<Map<String, dynamic>> deleteRequests = [];
  final Map<String, Map<String, dynamic>> remoteDocuments = {};

  @override
  Future<void> upsertRecordByDate({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    required String dateKey,
    required Map<String, dynamic> payload,
    bool deleted = false,
  }) async {
    upsertCalls++;
    requests.add({
      'coachId': coachId,
      'clientId': clientId,
      'domain': domain,
      'dateKey': dateKey,
      'payload': payload,
      'deleted': deleted,
    });
    final key = '$coachId/$clientId/${domain.collectionName}/$dateKey';
    remoteDocuments[key] = payload;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<List<RemoteRecordSnapshot>> fetchRecords({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    DateTime? since,
  }) async {
    return const [];
  }

  @override
  Future<void> deleteRecord({
    required String coachId,
    required String clientId,
    required RecordDomain domain,
    required String dateKey,
  }) async {
    deleteCalls++;
    deleteRequests.add({
      'coachId': coachId,
      'clientId': clientId,
      'domain': domain,
      'dateKey': dateKey,
    });
    final key = '$coachId/$clientId/${domain.collectionName}/$dateKey';
    remoteDocuments[key] = <String, dynamic>{
      'deleted': true,
      'dateKey': dateKey,
    };
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

Future<void> _clearTables() async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('sync_queue');
  await db.delete('training_interviews');
  await db.delete('clients');
}

void main() {
  group('Background sync clinical records outbox', () {
    late LocalClientDataSourceImpl local;
    late _FakeRemoteClientDataSource remoteClient;
    late _FakeClinicalRecordRemoteDataSource remoteClinical;
    late ClinicalRecordsRepository repository;
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
      remoteClient = _FakeRemoteClientDataSource();
      remoteClinical = _FakeClinicalRecordRemoteDataSource();
      repository = ClinicalRecordsRepository(
        currentCoachIdProvider: () => 'coach-1',
      );
      backgroundService = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remoteClient,
        clinicalRecordRemoteRepository: remoteClinical,
        currentCoachIdProvider: () => 'coach-1',
      );
      SyncService.instance.setBackgroundSyncServiceForTest(backgroundService);
      SyncService.instance.stop();
    });

    tearDown(() {
      SyncService.instance.clearBackgroundSyncServiceForTest();
    });

    test('remote success closes anthropometry queue item', () async {
      await repository.enqueueAnthropometryRecordUpsert(
        'client-a',
        AnthropometryRecord(
          date: DateTime(2026, 6),
          weightKg: 80,
          heightCm: 180,
        ),
      );
      final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;

      final outcome = await backgroundService.processClinicalRecordOutboxItem(
        item,
      );

      expect(outcome, SyncQueueProcessOutcome.success);
      expect(remoteClinical.upsertCalls, 1);
      expect(remoteClinical.requests.single['domain'], RecordDomain.anthropometry);
      expect(remoteClinical.requests.single['dateKey'], '2026-06-01');
      expect(await SyncQueueHelper.getPendingItems(limit: 20), isEmpty);
    });

    test('remote failure keeps item and increments retry', () async {
      await repository.enqueueBiochemistryRecordUpsert(
        'client-b',
        BioChemistryRecord(date: DateTime(2026, 6, 2), glucose: 90),
      );
      remoteClinical.errorToThrow = Exception('network down');

      await SyncService.instance.processPendingQueueOnce();

      expect(remoteClinical.upsertCalls, 1);
      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['retry_count'], 1);
      expect(pending.single['error_message'], 'sync failed');
    });

    test('remote success closes anthropometry delete queue item', () async {
      await repository.enqueueAnthropometryRecordDelete(
        'client-delete-a',
        DateTime(2026, 6, 7),
      );
      final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;

      final outcome = await backgroundService.processClinicalRecordOutboxItem(
        item,
      );

      expect(outcome, SyncQueueProcessOutcome.success);
      expect(remoteClinical.deleteCalls, 1);
      expect(
        remoteClinical.deleteRequests.single['domain'],
        RecordDomain.anthropometry,
      );
      expect(remoteClinical.deleteRequests.single['dateKey'], '2026-06-07');
      expect(await SyncQueueHelper.getPendingItems(limit: 20), isEmpty);
    });

    test('remote failure keeps delete item and increments retry', () async {
      await repository.enqueueBiochemistryRecordDelete(
        'client-delete-b',
        DateTime(2026, 6, 8),
      );
      remoteClinical.errorToThrow = Exception('network down');

      await SyncService.instance.processPendingQueueOnce();

      expect(remoteClinical.deleteCalls, 1);
      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['domain'], SyncQueueDomains.biochemistryRecordDelete);
      expect(pending.single['retry_count'], 1);
      expect(pending.single['error_message'], 'sync failed');
    });

    test('no auth keeps clinical item pending without retry bump', () async {
      await repository.enqueueBiochemistryRecordUpsert(
        'client-c',
        BioChemistryRecord(date: DateTime(2026, 6, 3), glucose: 95),
      );
      final service = BackgroundSyncService.test(
        localRepository: local,
        remoteRepository: remoteClient,
        clinicalRecordRemoteRepository: remoteClinical,
        currentCoachIdProvider: () => null,
      );
      final item = (await SyncQueueHelper.getPendingItems(limit: 20)).single;

      final outcome = await service.processClinicalRecordOutboxItem(item);

      expect(outcome, SyncQueueProcessOutcome.pending);
      expect(remoteClinical.upsertCalls, 0);
      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['retry_count'], 0);
    });

    test('retry of same dateKey overwrites one deterministic remote doc', () async {
      await repository.enqueueAnthropometryRecordUpsert(
        'client-d',
        AnthropometryRecord(
          date: DateTime(2026, 6, 4),
          weightKg: 78,
          heightCm: 177,
        ),
      );
      remoteClinical.errorToThrow = Exception('first attempt down');

      await SyncService.instance.processPendingQueueOnce();
      remoteClinical.errorToThrow = null;
      await SyncService.instance.processPendingQueueOnce();

      expect(remoteClinical.upsertCalls, 2);
      expect(remoteClinical.remoteDocuments, hasLength(1));
      expect(
        remoteClinical.remoteDocuments.keys.single,
        'coach-1/client-d/anthropometry_records/2026-06-04',
      );
      expect(await SyncQueueHelper.getPendingItems(limit: 20), isEmpty);
    });
  });
}
