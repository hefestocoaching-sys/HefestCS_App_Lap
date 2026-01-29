import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';

Client buildClient({required String id, required String name}) {
  final profile = ClientProfile(
    id: 'p-$id',
    fullName: name,
    email: '$id@example.com',
    phone: '000',
    country: 'Nowhere',
    occupation: 'Tester',
    objective: 'Test',
  );
  return Client(
    id: id,
    profile: profile,
    history: const ClinicalHistory(),
    training: TrainingProfile.empty(),
    nutrition: const NutritionSettings(),
  );
}

void main() {
  test(
    'PersonalDataTab logic: update client profile preserves other fields',
    () {
      final client = buildClient(id: 'client1', name: 'Before');

      // Simulate the tab modifying the profile
      final updatedProfile = client.profile.copyWith(fullName: 'After');
      final updatedClient = client.copyWith(profile: updatedProfile);

      // Verify the change
      expect(updatedClient.profile.fullName, 'After');
      expect(updatedClient.id, client.id);
      expect(updatedClient.history, client.history);
      expect(updatedClient.training, client.training);
    },
  );

  test('Client copyWith preserves other fields when updating profile', () {
    final client = buildClient(id: 'client1', name: 'Before');

    final newProfile = client.profile.copyWith(
      fullName: 'Updated Name',
      email: 'new@example.com',
    );

    final updated = client.copyWith(profile: newProfile);

    expect(updated.profile.fullName, 'Updated Name');
    expect(updated.profile.email, 'new@example.com');
    expect(updated.profile.phone, client.profile.phone);
    expect(updated.id, client.id);
    expect(updated.history, client.history);
  });
}
