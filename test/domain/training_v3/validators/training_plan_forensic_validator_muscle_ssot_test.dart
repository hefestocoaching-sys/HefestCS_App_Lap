import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/training_plan_forensic_validator.dart';

void main() {
  setUpAll(() {
    // ignore: deprecated_member_use_from_same_package
    ExerciseCatalogV3.loadFromExercises([
      Exercise(
        id: 'press_banca_plano_con_barra',
        externalId: 'test_press',
        name: 'Press banca plano con barra',
        muscleKey: 'pectorals',
        primaryMuscles: const ['pectorals'],
        movementPattern: 'horizontal_press',
        loadCategory: 'medium',
        allowedIntensityZones: const {
          'heavy': true,
          'medium': true,
          'light': false,
        },
      ),
    ]);
  });

  group('TrainingPlanForensicValidator muscle SSOT', () {
    test('canonical inputs stay canonical', () {
      final result = TrainingPlanForensicValidator.validate(
        planConfig: _planWithPrimaryMuscle('pectorals'),
      );

      expect(_weeklySets(result), containsPair('pectorals', 3));
      expect(_weeklySets(result), isNot(contains('chest')));
      expect(_unknownMuscleWarnings(result), isEmpty);
    });

    test('valid aliases normalize to canonical keys', () {
      final result = TrainingPlanForensicValidator.validate(
        planConfig: _planWithPrimaryMuscle('chest'),
      );

      expect(_weeklySets(result), containsPair('pectorals', 3));
      expect(_weeklySets(result), isNot(contains('chest')));
      expect(_unknownMuscleWarnings(result), isEmpty);
    });

    test('unknowns are not kept as normalized map keys', () {
      const raw = 'MysteryChest';

      final result = TrainingPlanForensicValidator.validate(
        planConfig: _planWithPrimaryMuscle(raw),
        expectedWeeklyVolumeByMuscle: const {raw: 3},
        musclePriorities: const {raw: 5},
      );

      expect(_weeklySets(result), isNot(contains(raw)));
      expect(_weeklySets(result), isNot(contains(raw.toLowerCase())));
      expect(_serialized(result), isNot(contains('muscle: $raw')));
      expect(
        _serialized(result),
        isNot(contains('muscle: ${raw.toLowerCase()}')),
      );
    });

    test('unknowns create non-blocking forensic warnings', () {
      final result = TrainingPlanForensicValidator.validate(
        planConfig: _planWithPrimaryMuscle('MysteryChest'),
      );

      expect(_unknownMuscleWarnings(result), isNotEmpty);
      expect(
        result.blockingErrors.any((error) {
          return error.contains('Clave muscular desconocida');
        }),
        isFalse,
      );
    });

    test('unknowns are not returned as raw values', () {
      const raw = 'MysteryChest';

      final result = TrainingPlanForensicValidator.validate(
        planConfig: _planWithPrimaryMuscle(raw),
      );

      expect(_serialized(result), isNot(contains(raw)));
    });

    test('unknowns are not returned as raw.toLowerCase values', () {
      const raw = 'MysteryChest';

      final result = TrainingPlanForensicValidator.validate(
        planConfig: _planWithPrimaryMuscle(raw),
      );

      expect(_serialized(result), isNot(contains(raw.toLowerCase())));
    });

    test('forensic validation does not throw for unknown muscle keys', () {
      late TrainingPlanForensicValidationResult result;

      expect(() {
        result = TrainingPlanForensicValidator.validate(
          planConfig: _planWithPrimaryMuscle('MysteryChest'),
        );
      }, returnsNormally);
      expect(
        result.blockingErrors.any((error) {
          return error.contains('Clave muscular desconocida');
        }),
        isFalse,
      );
    });
  });
}

Map<String, dynamic> _planWithPrimaryMuscle(String primaryMuscle) {
  return {
    'volumePerMuscle': const <String, int>{},
    'extra': const {
      'generated_by': 'motor_v3_deterministic',
      'business_phase_by_week': {'1': 'AA'},
    },
    'weeks': [
      {
        'weekNumber': 1,
        'sessions': [
          {
            'dayNumber': 1,
            'exercises': [
              {
                'exerciseId': 'press_banca_plano_con_barra',
                'primaryMuscle': primaryMuscle,
                'blockLabel': 'A',
                'slotLabel': 'A',
                'sets': const [
                  {'repsMin': 8, 'repsMax': 10},
                  {'repsMin': 8, 'repsMax': 10},
                  {'repsMin': 8, 'repsMax': 10},
                ],
              },
            ],
          },
        ],
      },
    ],
  };
}

Map<String, int> _weeklySets(TrainingPlanForensicValidationResult result) {
  final weekly = result.diagnostics['weeklySetsByMuscle'] as Map;
  final weekOne = weekly[1] as Map;
  return Map<String, int>.from(weekOne);
}

List<String> _unknownMuscleWarnings(
  TrainingPlanForensicValidationResult result,
) {
  return result.warnings
      .where((warning) => warning.contains('Clave muscular desconocida'))
      .toList(growable: false);
}

String _serialized(TrainingPlanForensicValidationResult result) {
  return result.toMap().toString();
}
