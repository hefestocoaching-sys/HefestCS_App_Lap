// test/domain/training_v3/engines/volume_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_engine.dart';

void main() {
  group('VolumeEngine', () {
    group('calculateOptimalVolume', () {
      test('debe retornar VOP para inicio (novice, pectorals)', () {
        final volume = VolumeEngine.calculateOptimalVolume(
          muscle: 'pectorals',
          trainingLevel: 'novice',
          priority: 1,
        );

        expect(volume, equals(10));
      });

      test('VOP no cambia con la prioridad', () {
        final volumeLow = VolumeEngine.calculateOptimalVolume(
          muscle: 'pectorals',
          trainingLevel: 'novice',
          priority: 1,
        );
        final volumeHigh = VolumeEngine.calculateOptimalVolume(
          muscle: 'pectorals',
          trainingLevel: 'novice',
          priority: 5,
        );

        expect(volumeLow, equals(volumeHigh));
      });
    });

    group('isVolumeOptimal', () {
      test('debe retornar true si volumen está entre VOP y VMR target', () {
        final landmarks = VolumeEngine.calculateLandmarks(
          muscle: 'pectorals',
          trainingLevel: 'novice',
          priority: 5,
          age: 30,
        );

        final isOptimal = VolumeEngine.isVolumeOptimal(
          volume: 12,
          landmarks: landmarks,
        );

        expect(isOptimal, isTrue);
      });

      test('debe retornar false si volumen está por debajo de VOP', () {
        final landmarks = VolumeEngine.calculateLandmarks(
          muscle: 'pectorals',
          trainingLevel: 'novice',
          priority: 5,
          age: 30,
        );

        final isOptimal = VolumeEngine.isVolumeOptimal(
          volume: 8,
          landmarks: landmarks,
        );

        expect(isOptimal, isFalse);
      });
    });
  });
}
