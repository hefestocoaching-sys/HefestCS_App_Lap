import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/repositories/transaction_repository.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/utils/firestore_sanitizer.dart';

void main() {
  group('Firestore contracts CI', () {
    test('canary file does not rely on Firebase runtime APIs', () {
      final source = _read('test/integration/firestore_contracts_ci_test.dart');
      final firebaseInit = ['Firebase', '.initializeApp'].join();
      final firestoreInstance = ['FirebaseFirestore', '.instance'].join();
      final authInstance = ['FirebaseAuth', '.instance'].join();
      final skipMarker = ['skip', ':'].join();

      expect(source, isNot(contains(firebaseInit)));
      expect(source, isNot(contains(firestoreInstance)));
      expect(source, isNot(contains(authInstance)));
      expect(source, isNot(contains(skipMarker)));
    });

    test('manual smoke tests stay manual and skipped', () {
      final firestoreSmoke = _read('test/manual/firestore_smoke_test.dart');
      final anthropometrySmoke = _read(
        'test/manual/anthropometry_records_firestore_test.dart',
      );
      final skipMarker = ['skip', ':'].join();
      final firebaseInit = ['Firebase', '.initializeApp'].join();

      expect(firestoreSmoke, contains(skipMarker));
      expect(firestoreSmoke, contains('Manual smoke test'));
      expect(anthropometrySmoke, contains(skipMarker));
      expect(anthropometrySmoke, contains('Manual smoke test'));
      expect(firestoreSmoke, contains(firebaseInit));
      expect(anthropometrySmoke, contains(firebaseInit));
    });

    test('contract tests exist and cover the critical Firestore helpers', () {
      expect(
        File(
          'test/data/repositories/transaction_repository_contract_test.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'test/data/datasources/remote/record_firestore_datasource_contract_test.dart',
        ).existsSync(),
        isTrue,
      );
    });

    test('client payloads are sanitized before Firestore writes', () {
      final client = _clientFixture();
      final payload = sanitizeForFirestore({
        ...client.toJson(),
        'profile': {
          ...client.profile.toJson(),
          'tags': [
            'ci',
            {'nested': true},
          ],
        },
        'createdAt': client.createdAt,
        'updatedAt': client.updatedAt,
        'nonSerializable': Object(),
      });

      expect(payload['id'], client.id);
      expect(payload['profile'], isA<Map<String, dynamic>>());
      expect(payload['training'], isA<Map<String, dynamic>>());
      expect(payload['nutrition'], isA<Map<String, dynamic>>());
      expect(payload['createdAt'], isA<Timestamp>());
      expect(payload['updatedAt'], isA<Timestamp>());
      expect((payload['profile'] as Map<String, dynamic>)['tags'], isA<List>());
      expect(payload.containsKey('trainingPlans'), isTrue);
      expect(payload.containsKey('trainingWeeks'), isTrue);
      expect(payload.containsKey('trainingSessions'), isTrue);
      expect(payload.containsKey('nonSerializable'), isFalse);
    });

    test('transaction totals ignore corrupted amounts without crashing', () {
      expect(readFiniteAmount(99), 99.0);
      expect(readFiniteAmount(12.5), 12.5);
      expect(readFiniteAmount('99'), isNull);
      expect(readFiniteAmount(double.nan), isNull);
    });

    test('record contracts tolerate corrupt Firestore-shaped values', () {
      expect(asStringDynamicMap(<dynamic, dynamic>{1: 'one', 'ok': 2}), {
        'ok': 2,
      });
      expect(readPayload('invalid'), isEmpty);
      expect(readUpdatedAt(null), DateTime.fromMillisecondsSinceEpoch(0));
      expect(readSchemaVersion('bad'), 1);
      expect(readDeleted('false'), isFalse);
    });

    test('rules and firebase config exist and point to the expected files', () {
      final rules = _read('firestore.rules');
      final firebaseJson = _read('firebase.json');

      expect(rules, contains('service cloud.firestore'));
      expect(rules, contains('match /coaches/{coachId}'));
      expect(rules, contains('match /clients/{clientId}'));
      expect(firebaseJson, contains('"firestore":'));
      expect(firebaseJson, contains('"rules": "firestore.rules"'));
      expect(firebaseJson, contains('"indexes": "firestore.indexes.json"'));
    });

    test('smoke tests are not the only protection for the Firestore layer', () {
      final report = _read(
        'lib/audit/AUDIT_GENERAL_POST_P2_LIB_TEST_REPORT.md',
      );

      expect(report, contains('P1-FIRESTORE-CONTRACTS'));
      expect(report, contains('P2-TESTS-FIREBASE-CI'));
      expect(
        report,
        contains(
          'test/data/repositories/transaction_repository_contract_test.dart',
        ),
      );
      expect(
        report,
        contains(
          'test/data/datasources/remote/record_firestore_datasource_contract_test.dart',
        ),
      );
      expect(report, contains('test/manual/firestore_smoke_test.dart'));
      expect(
        report,
        contains('test/manual/anthropometry_records_firestore_test.dart'),
      );
    });
  });
}

String _read(String path) => File(path).readAsStringSync();

Client _clientFixture() {
  final now = DateTime.utc(2026, 7, 2);
  return Client(
    id: 'ci-firestore-client',
    profile: const ClientProfile(
      id: 'profile-ci-firestore-client',
      fullName: 'CI Client',
      email: 'ci@example.com',
      phone: '000',
      country: 'Mexico',
      occupation: 'Coach',
      objective: 'Validate',
    ),
    history: const ClinicalHistory(),
    training: TrainingProfile.empty(),
    nutrition: const NutritionSettings(),
    createdAt: now,
    updatedAt: now,
  );
}
