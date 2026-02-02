// test/domain/training_v3/engines/intensity_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_engine.dart';

void main() {
  group('IntensityEngine', () {
    group('distributeIntensities', () {
      test('debe asignar heavy a compounds primero', () {
        final exercises = ['bench_press', 'squat', 'curl', 'extension'];
        final types = {
          'bench_press': 'compound',
          'squat': 'compound',
          'curl': 'isolation',
          'extension': 'isolation',
        };

        final intensities = IntensityEngine.distributeIntensities(
          exercises: exercises,
          exerciseTypes: types,
        );

        // Con 4 ejercicios: 35% = 1-2 heavy, 45% = 2 moderate, 20% = 1 light
        expect(intensities['bench_press'], equals('heavy'));
        expect(intensities['squat'], isIn(['heavy', 'moderate']));
      });

      test('debe respetar distribución 35/45/20 aproximada', () {
        final exercises = List.generate(10, (i) => 'ex_$i');
        final types = Map.fromEntries(
          exercises.map((e) => MapEntry(e, 'compound')),
        );

        final intensities = IntensityEngine.distributeIntensities(
          exercises: exercises,
          exerciseTypes: types,
        );

        final heavyCount = intensities.values.where((i) => i == 'heavy').length;
        final moderateCount = intensities.values
            .where((i) => i == 'moderate')
            .length;
        final lightCount = intensities.values.where((i) => i == 'light').length;

        // Con 10 ejercicios: 3-4 heavy, 4-5 moderate, 2 light
        expect(heavyCount, inInclusiveRange(3, 4));
        expect(moderateCount, inInclusiveRange(4, 5));
        expect(lightCount, inInclusiveRange(1, 2));
      });
    });

    group('getRepRangeForIntensity', () {
      test('debe retornar 5-8 para heavy', () {
        final range = IntensityEngine.getRepRangeForIntensity('heavy');
        expect(range, equals([5, 8]));
      });

      test('debe retornar 8-12 para moderate', () {
        final range = IntensityEngine.getRepRangeForIntensity('moderate');
        expect(range, equals([8, 12]));
      });

      test('debe retornar 12-20 para light', () {
        final range = IntensityEngine.getRepRangeForIntensity('light');
        expect(range, equals([12, 20]));
      });
    });
  });
}
