import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';

void main() {
  group('ClientFirestoreDataSource remote payload contract', () {
    test('throws on invalid Firestore payload', () {
      final fullPayload = <String, dynamic>{
        'payload': <String, dynamic>{
          'profile': <String, dynamic>{
            'bad.key': 'value',
          },
        },
        'schemaVersion': 1,
        'updatedAt': '2026-06-28T00:00:00.000Z',
        'deleted': false,
      };

      expect(
        () => validateRemoteClientPayloadOrThrow(
          clientId: 'client-invalid',
          fullPayload: fullPayload,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('[SAVE][REMOTE_PAYLOAD_INVALID]'),
              contains('clientId=client-invalid'),
              contains('invalidPath=payloadRoot.payload.profile.bad.key'),
            ),
          ),
        ),
      );
    });

    test('accepts valid Firestore payload', () {
      final fullPayload = <String, dynamic>{
        'payload': <String, dynamic>{
          'profile': <String, dynamic>{'name': 'Valid Client'},
        },
        'schemaVersion': 1,
        'updatedAt': '2026-06-28T00:00:00.000Z',
        'deleted': false,
      };

      expect(
        () => validateRemoteClientPayloadOrThrow(
          clientId: 'client-valid',
          fullPayload: fullPayload,
        ),
        returnsNormally,
      );
    });
  });
}
