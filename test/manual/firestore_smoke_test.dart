import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'manual firestore smoke test: upsert and fetch client',
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
      final client = _buildClient(
        'smoke-${DateTime.now().millisecondsSinceEpoch}',
      );

      final datasource = ClientFirestoreDataSource(FirebaseFirestore.instance);

      await datasource.upsertClient(
        coachId: coachId,
        client: client,
        deleted: false,
      );

      final snapshots = await datasource.fetchClients(coachId: coachId);
      final match = snapshots.firstWhere(
        (snap) => snap.clientId == client.id,
        orElse: () => throw TestFailure(
          'Client ${client.id} not found in coaches/$coachId/clients',
        ),
      );

      expect(match.deleted, isFalse);
      expect(match.payload['id'], client.id);
      expect(match.updatedAt, isNotNull);
    },
    skip:
        'Manual smoke test. Requires an authenticated coach session before run.',
  );
}

Client _buildClient(String id) {
  final now = DateTime.now();
  return Client(
    id: id,
    profile: ClientProfile(
      id: 'profile-$id',
      fullName: 'Smoke Test User',
      email: 'smoke@test.local',
      phone: '000',
      country: 'N/A',
      occupation: 'Coach',
      objective: 'Validation',
    ),
    history: const ClinicalHistory(),
    training: TrainingProfile.empty(),
    nutrition: const NutritionSettings(),
    createdAt: now,
    updatedAt: now,
  );
}
