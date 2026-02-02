// test/domain/training_v3/engines/volume_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_engine.dart';

void main() {
  group('VolumeEngine', () {
    group('calculateOptimalVolume', () {
      test('debe retornar VME para prioridad mínima (1)', () {
        final volume = VolumeEngine.calculateOptimalVolume(
          muscle: 'chest',
          trainingLevel: 'novice',
          priority: 1,
        );

        expect(volume, equals(10)); // VME de chest novice
      });

      test('debe retornar MAV para prioridad máxima (5)', () {
        final volume = VolumeEngine.calculateOptimalVolume(
          muscle: 'chest',
          trainingLevel: 'novice',
          priority: 5,
        );

        expect(volume, equals(15)); // MAV de chest novice
      });

      test('debe aplicar progresión conservadora (+2 sets si < MAV)', () {
        final volume = VolumeEngine.calculateOptimalVolume(
          muscle: 'chest',
          trainingLevel: 'novice',
          priority: 3,
          currentVolume: 10,
        );

        expect(volume, equals(12)); // 10 + 2
      });

      test('debe respetar MRV como límite superior', () {
        final volume = VolumeEngine.calculateOptimalVolume(
          muscle: 'chest',
          trainingLevel: 'novice',
          priority: 5,
          currentVolume: 19,
        );

        expect(volume, equals(20)); // MRV de chest novice
      });

      test('debe lanzar error con músculo inválido', () {
        expect(
          () => VolumeEngine.calculateOptimalVolume(
            muscle: 'invalid_muscle',
            trainingLevel: 'novice',
            priority: 3,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('isVolumeOptimal', () {
      test('debe retornar true si volumen está entre MAV-MRV', () {
        final isOptimal = VolumeEngine.isVolumeOptimal(
          volume: 17,
          muscle: 'chest',
          trainingLevel: 'novice',
        );

        expect(isOptimal, isTrue);
      });

      test('debe retornar false si volumen está por debajo de MAV', () {
        final isOptimal = VolumeEngine.isVolumeOptimal(
          volume: 12,
          muscle: 'chest',
          trainingLevel: 'novice',
        );

        expect(isOptimal, isFalse);
      });
    });
  });
}
