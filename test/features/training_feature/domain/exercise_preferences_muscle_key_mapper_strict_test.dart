import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_muscle_key_mapper.dart';

void main() {
  group('ExercisePreferenceMuscleKeyMapper strict normalization', () {
    test('canonical keys return themselves', () {
      const cases = {
        'pectorals': 'pectorals',
        'quads': 'quads',
        'delts_lateral': 'delts_lateral',
      };

      for (final entry in cases.entries) {
        expect(
          ExercisePreferenceMuscleKeyMapper.toCanonicalKey(entry.key),
          entry.value,
        );
      }
    });

    test('supported aliases return canonical keys', () {
      const cases = {
        'chest': 'pectorals',
        'pectorales': 'pectorals',
        'quadriceps': 'quads',
        'deltoide_anterior': 'delts_front',
        'gluteos': 'glutes',
        'abdomen': 'abs',
      };

      for (final entry in cases.entries) {
        expect(
          ExercisePreferenceMuscleKeyMapper.toCanonicalKey(entry.key),
          entry.value,
        );
      }
    });

    test('unknown keys return null', () {
      const unknownKeys = [
        '',
        ' ',
        'glute',
        'back_mid_upper',
        'unknown_muscle',
      ];

      for (final key in unknownKeys) {
        expect(ExercisePreferenceMuscleKeyMapper.toCanonicalKey(key), isNull);
      }
    });

    test('unknown keys are never passed through as raw values', () {
      expect(
        ExercisePreferenceMuscleKeyMapper.toCanonicalKey('unknown_muscle'),
        isNot('unknown_muscle'),
      );
      expect(
        ExercisePreferenceMuscleKeyMapper.toCanonicalKey('deltoides_random'),
        isNot('deltoides_random'),
      );
    });

    test('set mapper keeps only canonical keys and removes duplicates', () {
      final result = ExercisePreferenceMuscleKeyMapper.toCanonicalKeys([
        'pectorals',
        'chest',
        'quadriceps',
        'quads',
        'deltoide_anterior',
        'unknown_muscle',
        'glute',
        'abdomen',
      ]);

      expect(result, {'pectorals', 'quads', 'delts_front', 'abs'});
      expect(result, isNot(contains('unknown_muscle')));
      expect(result, isNot(contains('glute')));
      expect(result.length, 4);
    });
  });
}
