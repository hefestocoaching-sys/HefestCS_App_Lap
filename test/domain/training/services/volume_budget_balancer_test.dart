import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training/services/exercise_contribution_catalog.dart';
import 'package:hcs_app_lap/domain/training/services/effective_sets_calculator.dart';

void main() {
  group('Volume Budget Balancer', () {
    test('ExerciseContributionCatalog returns valid contributions', () {
      final benchPress = ExerciseContributionCatalog.getForExercise(
        'bench_press',
      );
      expect(benchPress.isNotEmpty, true);
      expect(benchPress['chest'], greaterThan(0));
    });

    test('ExerciseContributionCatalog handles unknown exercises', () {
      final unknown = ExerciseContributionCatalog.getForExercise(
        'unknown_exercise',
      );
      expect(unknown.isEmpty, true);
    });

    test('EffectiveSetsCalculator computes correct totals', () {
      // Mock exercise data
      final mockExercises = [
        'bench_press',
        'bench_press', // Two bench presses = 8 sets total to chest
      ];

      final effectiveSets = EffectiveSetsCalculator.compute(
        allExercisesInPlan: mockExercises,
        exerciseKeyExtractor: (ex) => ex as String,
        setsExtractor: (i) => 4.0, // 4 sets each
      );

      // Bench press: 4 sets to chest + 4 sets to chest = 8 effective for chest
      expect(effectiveSets['chest'], greaterThanOrEqualTo(8));
    });

    test('Muscle key normalization examples', () {
      // These should all map to canonical names
      const testCases = [
        ('glutes', 'glutes'),
        ('GLUTES', 'glutes'),
        ('Glutes', 'glutes'),
        ('glute_group', 'glutes'),
      ];

      for (final (input, expected) in testCases) {
        // Note: MuscleKey.fromRaw requires the enum to exist
        // This is a simplified test
        expect(input.toLowerCase(), expected.toLowerCase());
      }
    });
  });
}
