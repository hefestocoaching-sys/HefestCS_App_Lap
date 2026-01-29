import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/local/exercise_catalog_loader.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/exceptions/training_plan_blocked_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Exercise catalog loads and maps without crashing', () async {
    final exercises = await ExerciseCatalogLoader.load();
    expect(exercises, isA<List<Exercise>>());
    expect(exercises.isNotEmpty, true, reason: 'Catalog should not be empty');

    // Sanity check on a few mapped fields
    final ex = exercises.first;
    expect(ex.id.isNotEmpty, true);
    expect(ex.name.isNotEmpty, true);
    expect(ex.muscleKey.isNotEmpty, true);
  });

  test(
    'Engine generatePlan fails fast with missing data, not mapping errors',
    () async {
      final exercises = await ExerciseCatalogLoader.load();
      final engine = TrainingProgramEngine();

      // Use an empty profile to deliberately cause blocked generation
      final profile = TrainingProfile.empty();

      try {
        final TrainingPlanConfig _ = engine.generatePlan(
          planId: 'test-plan',
          clientId: 'test-client',
          planName: 'Test Plan',
          startDate: DateTime.now(),
          profile: profile,
          exercises: exercises,
        );
        fail('Expected TrainingPlanBlockedException due to missing data');
      } on TrainingPlanBlockedException catch (e) {
        // Expected: engine blocks for missing critical data
        final missing = e.context['missingFields'] as List<dynamic>?;
        expect(missing != null && missing.isNotEmpty, true);
      }
    },
  );
}
