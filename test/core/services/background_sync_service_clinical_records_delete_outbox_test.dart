import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Background sync clinical record delete source contract', () {
    test('SyncService routes clinical delete domains to background processor', () {
      final source = _read('lib/core/services/sync_service.dart');

      expect(source, contains('SyncQueueDomains.anthropometryRecordDelete'));
      expect(source, contains('SyncQueueDomains.biochemistryRecordDelete'));
      expect(source, contains('processClinicalRecordOutboxItem(item)'));
    });

    test('BackgroundSyncService handles delete action with deleteRecord', () {
      final source = _read('lib/core/services/background_sync_service.dart');

      expect(source, contains("action != 'upsert' && action != 'delete'"));
      expect(source, contains("if (action == 'delete')"));
      expect(source, contains('clinicalRecordRemoteRepository.deleteRecord'));
      expect(source, contains('_isClinicalRecordDeleteQueueDomain'));
    });

    test('remote datasource writes idempotent tombstone payload', () {
      final source = _read(
        'lib/data/datasources/remote/record_firestore_datasource.dart',
      );

      expect(source, contains('final tombstonePayload = <String, dynamic>'));
      expect(source, contains("'deleted': true"));
      expect(source, contains("'deletedAt': FieldValue.serverTimestamp()"));
      expect(source, contains('SetOptions(merge: true)'));
    });
  });
}
