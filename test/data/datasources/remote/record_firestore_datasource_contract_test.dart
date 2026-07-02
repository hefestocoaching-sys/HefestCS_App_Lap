import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';

void main() {
  group('RecordFirestoreDataSource parsing contract', () {
    test('keeps payload map when payload is valid', () {
      final payload = readPayload(<String, dynamic>{
        'weight': 72.5,
        'notes': 'ok',
      });

      expect(payload, <String, dynamic>{'weight': 72.5, 'notes': 'ok'});
    });

    test('returns empty payload for invalid shapes', () {
      expect(readPayload(null), isEmpty);
      expect(readPayload('invalid'), isEmpty);
      expect(readPayload([1, 2, 3]), isEmpty);
      expect(readPayload(true), isEmpty);
    });

    test('drops non-string keys when coercing generic maps', () {
      final raw = <dynamic, dynamic>{1: 'one', 'valid': 2};

      expect(asStringDynamicMap(raw), <String, dynamic>{'valid': 2});
      expect(readPayload(raw), <String, dynamic>{'valid': 2});
    });

    test('schemaVersion falls back to 1 when invalid', () {
      expect(readSchemaVersion(3), 3);
      expect(readSchemaVersion('3'), 1);
      expect(readSchemaVersion(null), 1);
    });

    test('updatedAt falls back to epoch when invalid', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);

      expect(
        readUpdatedAt(Timestamp.fromMillisecondsSinceEpoch(1234)),
        isA<DateTime>(),
      );
      expect(readUpdatedAt('not a timestamp'), epoch);
      expect(readUpdatedAt(null), epoch);
    });

    test('deleted contract remains false unless explicitly true', () {
      expect(readDeleted(true), isTrue);
      expect(readDeleted(false), isFalse);
      expect(readDeleted('true'), isFalse);
      expect(readDeleted(null), isFalse);
    });
  });
}
