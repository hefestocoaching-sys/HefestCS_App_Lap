import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';

Client _buildClient({
  required String id,
  required String name,
  Map<String, dynamic>? trainingExtra,
}) {
  final profile = ClientProfile(
    id: 'p-$id',
    fullName: name,
    email: '$id@example.com',
    phone: '000',
    country: 'Test Country',
    occupation: 'Tester',
    objective: 'Test Objective',
  );

  return Client(
    id: id,
    profile: profile,
    history: const ClinicalHistory(),
    training: TrainingProfile(extra: trainingExtra ?? {}),
    nutrition: const NutritionSettings(),
  );
}

void main() {
  group('Training Interview Fields Persistence', () {
    late DatabaseHelper dbHelper;

    setUpAll(() async {
      // Inicializar sqflite FFI para tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      dbHelper = DatabaseHelper.instance;
      // La BD se inicializa automáticamente cuando se accede a 'database'
      await dbHelper.database;
    });

    test(
      'Should persist new training interview fields through save and reload',
      () async {
        // Arrange
        final testClient = _buildClient(
          id: 'test_interview_persist_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Test Interview Persistence',
          trainingExtra: {
            TrainingInterviewKeys.yearsTrainingContinuous: 5,
            TrainingInterviewKeys.avgSleepHours: 7.5,
            TrainingInterviewKeys.sessionDurationMinutes: 60,
            TrainingInterviewKeys.restBetweenSetsSeconds: 90,
            TrainingInterviewKeys.workCapacity: 'Alto',
            TrainingInterviewKeys.recoveryHistory: 'Buena',
            TrainingInterviewKeys.externalRecovery: true,
            TrainingInterviewKeys.programNovelty: 'Variado',
            TrainingInterviewKeys.physicalStress: 'Moderado',
            TrainingInterviewKeys.dietQuality: 'Excelente',
          },
        );

        // Act - Save to database
        await dbHelper.upsertClient(testClient);

        // Assert - Reload from database
        final reloadedClient = await dbHelper.getClientById(testClient.id);

        expect(reloadedClient, isNotNull);
        expect(
          reloadedClient!.training.extra[TrainingInterviewKeys
              .yearsTrainingContinuous],
          equals(5),
          reason:
              'yearsTrainingContinuous should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.avgSleepHours],
          equals(7.5),
          reason: 'avgSleepHours should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys
              .sessionDurationMinutes],
          equals(60),
          reason: 'sessionDurationMinutes should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys
              .restBetweenSetsSeconds],
          equals(90),
          reason: 'restBetweenSetsSeconds should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.workCapacity],
          equals('Alto'),
          reason: 'workCapacity should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.recoveryHistory],
          equals('Buena'),
          reason: 'recoveryHistory should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.externalRecovery],
          equals(true),
          reason: 'externalRecovery should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.programNovelty],
          equals('Variado'),
          reason: 'programNovelty should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.physicalStress],
          equals('Moderado'),
          reason: 'physicalStress should persist after save and reload',
        );
        expect(
          reloadedClient.training.extra[TrainingInterviewKeys.dietQuality],
          equals('Excelente'),
          reason: 'dietQuality should persist after save and reload',
        );
      },
    );

    test(
      'Should preserve existing training fields when updating interview data',
      () async {
        // Arrange - Create a client with BOTH existing and new fields
        final originalExtra = {
          // Existing fields
          'strengthLevelClass': 'M',
          'workCapacityScore': 3,
          'recoveryHistoryScore': 3,
          // New interview fields
          TrainingInterviewKeys.yearsTrainingContinuous: 10,
          TrainingInterviewKeys.avgSleepHours: 8.0,
        };

        final testClient = _buildClient(
          id: 'test_preserve_extra_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Test Preserve Extra',
          trainingExtra: originalExtra,
        );

        // Act - Save to database
        await dbHelper.upsertClient(testClient);

        // Now update with new data while preserving old
        final updatedExtra = {...originalExtra};
        updatedExtra[TrainingInterviewKeys.workCapacity] = 'Muy Alto';
        updatedExtra[TrainingInterviewKeys.dietQuality] = 'Buena';

        final updatedClient = testClient.copyWith(
          training: testClient.training.copyWith(extra: updatedExtra),
        );

        await dbHelper.upsertClient(updatedClient);

        // Assert - All fields should be present after update
        final finalClient = await dbHelper.getClientById(testClient.id);

        expect(finalClient, isNotNull);
        // Original fields should still exist
        expect(
          finalClient!.training.extra['strengthLevelClass'],
          equals('M'),
          reason: 'Original strengthLevelClass should be preserved',
        );
        expect(
          finalClient.training.extra['workCapacityScore'],
          equals(3),
          reason: 'Original workCapacityScore should be preserved',
        );
        // Original interview fields should still exist
        expect(
          finalClient.training.extra[TrainingInterviewKeys
              .yearsTrainingContinuous],
          equals(10),
          reason: 'Original yearsTrainingContinuous should be preserved',
        );
        expect(
          finalClient.training.extra[TrainingInterviewKeys.avgSleepHours],
          equals(8.0),
          reason: 'Original avgSleepHours should be preserved',
        );
        // New fields should be added
        expect(
          finalClient.training.extra[TrainingInterviewKeys.workCapacity],
          equals('Muy Alto'),
          reason: 'Updated workCapacity should be saved',
        );
        expect(
          finalClient.training.extra[TrainingInterviewKeys.dietQuality],
          equals('Buena'),
          reason: 'New dietQuality should be saved',
        );
      },
    );
  });
}
