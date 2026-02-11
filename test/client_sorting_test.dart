import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';

void main() {
  test(
    'Clients sort by updatedAt descending with epoch fallback treated as oldest',
    () {
      const profile = ClientProfile(
        id: 'p1',
        fullName: 'Test',
        email: 't@example.com',
        phone: '000',
        country: 'Nowhere',
        occupation: 'Test',
        objective: 'Test',
      );

      final oldClient = Client(
        id: 'old',
        profile: profile,
        history: const ClinicalHistory(),
        training: TrainingProfile.empty(),
        nutrition: const NutritionSettings(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final newClient = Client(
        id: 'new',
        profile: profile,
        history: const ClinicalHistory(),
        training: TrainingProfile.empty(),
        nutrition: const NutritionSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final clients = [oldClient, newClient];
      clients.sort((a, b) {
        final dateCompare = b.updatedAt.compareTo(a.updatedAt);
        if (dateCompare != 0) return dateCompare;
        return a.id.compareTo(b.id);
      });

      expect(clients.first.id, 'new');
      expect(clients.last.id, 'old');
    },
  );
}
