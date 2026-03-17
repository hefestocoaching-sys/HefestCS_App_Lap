import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/remote/anthropometry_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'manual anthropometry records firestore smoke test',
    () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        fail(
          'Sign in with Email/Password in the desktop app before running this test.',
        );
      }

      final coachId = user.uid;
      final clientId = 'smoke-client-${DateTime.now().millisecondsSinceEpoch}';

      final datasource = AnthropometryFirestoreDataSource(
        FirebaseFirestore.instance,
      );

      // Test 1: Upsert anthropometry record
      final record1 = AnthropometryRecord(
        date: DateTime(2025, 1, 15),
        weightKg: 75.5,
        heightCm: 175.0,
        waistCircNarrowest: 85.0,
        hipCircMax: 95.0,
      );

      await datasource.upsertAnthropometryRecord(
        coachId: coachId,
        clientId: clientId,
        record: record1,
      );

      debugPrint('✅ Upserted record for 2025-01-15');

      // Test 2: Upsert another record (different date)
      final record2 = AnthropometryRecord(
        date: DateTime(2025, 1, 20),
        weightKg: 76.0,
        heightCm: 175.0,
        tricipitalFold: 12.5,
        subscapularFold: 15.0,
      );

      await datasource.upsertAnthropometryRecord(
        coachId: coachId,
        clientId: clientId,
        record: record2,
      );

      debugPrint('✅ Upserted record for 2025-01-20');

      // Test 3: Update existing record (same date)
      final record1Updated = AnthropometryRecord(
        date: DateTime(2025, 1, 15),
        weightKg: 76.5, // Changed from 75.5
        heightCm: 175.0,
        waistCircNarrowest: 84.0, // Changed from 85.0
        hipCircMax: 95.0,
      );

      await datasource.upsertAnthropometryRecord(
        coachId: coachId,
        clientId: clientId,
        record: record1Updated,
      );

      debugPrint('✅ Updated record for 2025-01-15');

      // Test 4: Fetch all records
      final records = await datasource.fetchAnthropometryRecords(
        coachId: coachId,
        clientId: clientId,
      );

      expect(records.length, 2, reason: 'Should have 2 records');

      final jan15 = records.firstWhere(
        (r) => r.date.day == 15,
        orElse: () => throw TestFailure('Record for 2025-01-15 not found'),
      );

      expect(jan15.weightKg, 76.5, reason: 'Weight should be updated');
      expect(jan15.waistCircNarrowest, 84.0, reason: 'Waist should be updated');

      final jan20 = records.firstWhere(
        (r) => r.date.day == 20,
        orElse: () => throw TestFailure('Record for 2025-01-20 not found'),
      );

      expect(jan20.weightKg, 76.0);
      expect(jan20.tricipitalFold, 12.5);

      debugPrint('✅ Fetched and verified ${records.length} records');

      // Test 5: Soft delete
      await datasource.deleteAnthropometryRecord(
        coachId: coachId,
        clientId: clientId,
        date: DateTime(2025, 1, 15),
      );

      debugPrint('✅ Soft deleted record for 2025-01-15');

      // Test 6: Verify deleted record is not returned
      final recordsAfterDelete = await datasource.fetchAnthropometryRecords(
        coachId: coachId,
        clientId: clientId,
      );

      expect(
        recordsAfterDelete.length,
        1,
        reason: 'Should have 1 record after soft delete',
      );

      expect(
        recordsAfterDelete.first.date.day,
        20,
        reason: 'Remaining record should be 2025-01-20',
      );

      debugPrint('✅ Verified soft delete works correctly');

      debugPrint('\n🎉 All anthropometry records smoke tests passed!');
      debugPrint(
        'Path: coaches/$coachId/clients/$clientId/anthropometry_records/',
      );
    },
    skip: 'Manual smoke test. Requires an authenticated coach session.',
  );
}
