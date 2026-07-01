import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Clinical records delete outbox source contract', () {
    test('repository declares durable delete enqueue methods', () {
      final source = _read(
        'lib/data/repositories/clinical_records_repository.dart',
      );

      expect(source, contains('Future<void> deleteAnthropometryRecord'));
      expect(source, contains('Future<void> deleteBiochemistryRecord'));
      expect(source, contains('enqueueAnthropometryRecordDelete'));
      expect(source, contains('enqueueBiochemistryRecordDelete'));
      expect(source, contains('SyncQueueDomains.anthropometryRecordDelete'));
      expect(source, contains('SyncQueueDomains.biochemistryRecordDelete'));
    });

    test('delete payload is a tombstone outbox event', () {
      final source = _read(
        'lib/data/repositories/clinical_records_repository.dart',
      );

      expect(source, contains("'action': 'delete'"));
      expect(source, contains("'deleted': true"));
      expect(source, contains("'deletedAt': updatedAt"));
      expect(source, contains("'recordJson': <String, dynamic>{'deleted': true}"));
    });

    test('record deletion service routes clinical deletes through repository', () {
      final source = _read('lib/domain/services/record_deletion_service.dart');

      expect(
        source,
        contains('_clinicalRecordsRepository.deleteAnthropometryRecord'),
      );
      expect(
        source,
        contains('_clinicalRecordsRepository.deleteBiochemistryRecord'),
      );
    });
  });
}
