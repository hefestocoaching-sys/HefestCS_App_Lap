import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _clearTables() async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('sync_queue');
  await db.delete('training_interviews');
  await db.delete('clients');
}

Map<String, dynamic> _decodePayload(Map<String, dynamic> item) {
  return jsonDecode(item['payload'] as String) as Map<String, dynamic>;
}

void main() {
  group('Clinical records outbox contract', () {
    late ClinicalRecordsRepository repository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseHelper.instance.database;
    });

    setUp(() async {
      await _clearTables();
      repository = ClinicalRecordsRepository(
        currentCoachIdProvider: () => 'coach-1',
      );
    });

    test('anthropometry local success enqueues durable outbox', () async {
      final record = AnthropometryRecord(
        date: DateTime(2026, 6),
        weightKg: 81.5,
        heightCm: 180,
      );

      final write = await repository.enqueueAnthropometryRecordUpsert(
        'client-a',
        record,
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final item = pending.single;
      expect(item['id'], write.queueItemId);
      expect(item['domain'], SyncQueueDomains.anthropometryRecordUpsert);
      expect(item['client_id'], 'client-a');
      expect(item['date_key'], '2026-06-01');
      expect(item['retry_count'], 0);

      final payload = _decodePayload(item);
      expect(payload['action'], 'upsert');
      expect(payload['operationId'], write.operationId);
      expect(payload['clientId'], 'client-a');
      expect(payload['dateKey'], '2026-06-01');
      expect(payload['domain'], SyncQueueDomains.anthropometryRecordUpsert);
      expect(payload['recordJson']['weightKg'], 81.5);
    });

    test('biochemistry local success enqueues durable outbox', () async {
      final record = BioChemistryRecord(
        date: DateTime(2026, 6, 2),
        glucose: 91,
        hba1c: 5.2,
      );

      await repository.enqueueBiochemistryRecordUpsert('client-b', record);

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final item = pending.single;
      expect(item['domain'], SyncQueueDomains.biochemistryRecordUpsert);
      expect(item['client_id'], 'client-b');
      expect(item['date_key'], '2026-06-02');

      final payload = _decodePayload(item);
      expect(payload['recordJson']['glucose'], 91);
      expect(payload['recordJson']['hba1c'], 5.2);
    });

    test('anthropometry delete enqueues durable tombstone outbox', () async {
      final write = await repository.enqueueAnthropometryRecordDelete(
        'client-delete-a',
        DateTime(2026, 6, 7),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final item = pending.single;
      expect(item['id'], write.queueItemId);
      expect(item['domain'], SyncQueueDomains.anthropometryRecordDelete);
      expect(item['client_id'], 'client-delete-a');
      expect(item['date_key'], '2026-06-07');
      expect(item['retry_count'], 0);

      final payload = _decodePayload(item);
      expect(payload['action'], 'delete');
      expect(payload['operationId'], write.operationId);
      expect(payload['clientId'], 'client-delete-a');
      expect(payload['dateKey'], '2026-06-07');
      expect(payload['deleted'], true);
      expect(payload['deletedAt'], isA<String>());
      expect(payload['recordJson']['deleted'], true);
    });

    test('biochemistry delete enqueues durable tombstone outbox', () async {
      await repository.enqueueBiochemistryRecordDelete(
        'client-delete-b',
        DateTime(2026, 6, 8),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      final item = pending.single;
      expect(item['domain'], SyncQueueDomains.biochemistryRecordDelete);
      expect(item['client_id'], 'client-delete-b');
      expect(item['date_key'], '2026-06-08');

      final payload = _decodePayload(item);
      expect(payload['action'], 'delete');
      expect(payload['deleted'], true);
      expect(payload['recordJson']['deleted'], true);
    });

    test('anthropometry delete without remote remains pending', () async {
      await repository.deleteAnthropometryRecord(
        'client-delete-no-remote-a',
        DateTime(2026, 6, 9),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['domain'], SyncQueueDomains.anthropometryRecordDelete);
      expect(pending.single['client_id'], 'client-delete-no-remote-a');
      expect(pending.single['date_key'], '2026-06-09');
      expect(pending.single['retry_count'], 0);
    });

    test('biochemistry delete without remote remains pending', () async {
      await repository.deleteBiochemistryRecord(
        'client-delete-no-remote-b',
        DateTime(2026, 6, 10),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['domain'], SyncQueueDomains.biochemistryRecordDelete);
      expect(pending.single['client_id'], 'client-delete-no-remote-b');
      expect(pending.single['date_key'], '2026-06-10');
      expect(pending.single['retry_count'], 0);
    });

    test('same dateKey updates pending payload instead of duplicating', () async {
      await repository.enqueueAnthropometryRecordUpsert(
        'client-c',
        AnthropometryRecord(
          date: DateTime(2026, 6, 3),
          weightKg: 80,
          heightCm: 179,
        ),
      );

      final latest = await repository.enqueueAnthropometryRecordUpsert(
        'client-c',
        AnthropometryRecord(
          date: DateTime(2026, 6, 3),
          weightKg: 82,
          heightCm: 179,
        ),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['id'], latest.queueItemId);

      final payload = _decodePayload(pending.single);
      expect(payload['operationId'], latest.operationId);
      expect(payload['recordJson']['weightKg'], 82);
    });

    test('different dateKey creates a different outbox event', () async {
      await repository.enqueueBiochemistryRecordUpsert(
        'client-d',
        BioChemistryRecord(date: DateTime(2026, 6, 4), glucose: 88),
      );
      await repository.enqueueBiochemistryRecordUpsert(
        'client-d',
        BioChemistryRecord(date: DateTime(2026, 6, 5), glucose: 92),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(2));
      expect(pending.map((item) => item['date_key']), contains('2026-06-04'));
      expect(pending.map((item) => item['date_key']), contains('2026-06-05'));
    });

    test('fire-and-forget remote is no longer the only guarantee', () async {
      await repository.pushAnthropometryRecord(
        'client-e',
        AnthropometryRecord(
          date: DateTime(2026, 6, 6),
          weightKg: 77,
          heightCm: 176,
        ),
      );

      final pending = await SyncQueueHelper.getPendingItems(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['domain'], SyncQueueDomains.anthropometryRecordUpsert);
      expect(pending.single['date_key'], '2026-06-06');
    });
  });
}
