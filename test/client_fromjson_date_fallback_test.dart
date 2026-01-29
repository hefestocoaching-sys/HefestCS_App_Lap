import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';

void main() {
  test(
    'Client.fromJson invalid dates fallback to epoch (msSinceEpoch == 0)',
    () {
      final profile = ClientProfile(
        id: 'p1',
        fullName: 'Test',
        email: 't@example.com',
        phone: '000',
        country: 'Nowhere',
        occupation: 'Test',
        objective: 'Test',
      );

      final client = Client(
        id: 'c1',
        profile: profile,
        history: const ClinicalHistory(),
        training: TrainingProfile.empty(),
        nutrition: const NutritionSettings(),
      );

      final json = client.toJson();
      json['createdAt'] = 'not-a-date';
      json['updatedAt'] = '+++invalid+++';

      final parsed = Client.fromJson(json);

      expect(parsed.createdAt.millisecondsSinceEpoch, 0);
      expect(parsed.updatedAt.millisecondsSinceEpoch, 0);
    },
  );
}
