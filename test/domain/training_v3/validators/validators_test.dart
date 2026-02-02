// test/domain/training_v3/validators/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/volume_validator.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/intensity_validator.dart';

void main() {
  group('VolumeValidator', () {
    test('debe validar programa con volumen óptimo', () {
      final volumeByMuscle = {
        'chest': 17, // Entre MAV (15) y MRV (20)
        'back': 20, // Entre MAV (18) y MRV (24)
        'quads': 16, // Entre MAV (15) y MRV (20)
      };

      final result = VolumeValidator.validateProgram(
        volumeByMuscle: volumeByMuscle,
        trainingLevel: 'novice',
      );

      expect(result['is_valid'], isTrue);
      expect(result['errors'], isEmpty);
    });

    test('debe detectar volumen por debajo de VME', () {
      final volumeByMuscle = {
        'chest': 8, // Por debajo de VME (10)
      };

      final result = VolumeValidator.validateProgram(
        volumeByMuscle: volumeByMuscle,
        trainingLevel: 'novice',
      );

      expect(result['is_valid'], isFalse);
      expect(result['errors'], isNotEmpty);
    });

    test('debe detectar volumen por encima de MRV', () {
      final volumeByMuscle = {
        'chest': 25, // Por encima de MRV (20)
      };

      final result = VolumeValidator.validateProgram(
        volumeByMuscle: volumeByMuscle,
        trainingLevel: 'novice',
      );

      expect(result['is_valid'], isFalse);
      expect(result['errors'], isNotEmpty);
    });
  });

  group('IntensityValidator', () {
    test('debe validar distribución 35/45/20 correcta', () {
      final intensities = {
        'ex1': 'heavy',
        'ex2': 'heavy',
        'ex3': 'heavy',
        'ex4': 'heavy', // 35%
        'ex5': 'moderate',
        'ex6': 'moderate',
        'ex7': 'moderate',
        'ex8': 'moderate',
        'ex9': 'moderate', // 45%
        'ex10': 'light',
        'ex11': 'light', // 20%
      };

      final prescriptions = intensities.map((id, intensity) {
        return MapEntry(id, {
          'target_rir': 2,
          'rep_range': [8, 12],
          'rest_seconds': 120,
        });
      });

      final result = IntensityValidator.validateDistribution(
        exerciseIntensities: intensities,
        exercisePrescriptions: prescriptions,
      );

      expect(result['is_valid'], isTrue);
    });
  });
}
