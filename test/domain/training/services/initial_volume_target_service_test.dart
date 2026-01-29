import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training/services/initial_volume_target_service.dart';

void main() {
  group('InitialVolumeTargetService', () {
    test('buildTargets asigna targets diferenciados según prioridad', () {
      // Arrange
      final mevByMuscle = {
        'chest': 10.0,
        'back': 10.0,
        'quads': 10.0,
        'biceps': 8.0,
      };

      final mrvByMuscle = {
        'chest': 20.0,
        'back': 20.0,
        'quads': 20.0,
        'biceps': 15.0,
      };

      final primary = ['chest']; // Prioritario primario
      final secondary = ['back']; // Prioritario secundario
      final tertiary = ['quads']; // Prioritario terciario
      // biceps no priorizado

      // Act
      final targets = InitialVolumeTargetService.buildTargets(
        muscles: mevByMuscle.keys,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
      );

      // Assert
      // Primario: 90% de MRV = 0.90 × 20 = 18
      expect(targets['chest'], 18.0);

      // Secundario: 70% de MRV = 0.70 × 20 = 14
      expect(targets['back'], 14.0);

      // Terciario: 55% de MRV = 0.55 × 20 = 11
      expect(targets['quads'], 11.0);

      // No priorizado: MEV = 8
      expect(targets['biceps'], 8.0);
    });

    test('buildTargets respeta guardrails MEV/MRV', () {
      // Arrange
      final mevByMuscle = {'chest': 15.0};

      final mrvByMuscle = {
        'chest': 16.0, // MRV muy cercano a MEV
      };

      final primary = ['chest'];

      // Act
      final targets = InitialVolumeTargetService.buildTargets(
        muscles: mevByMuscle.keys,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        primary: primary,
        secondary: [],
        tertiary: [],
      );

      // Assert
      // 90% de 16 = 14.4, pero MEV es 15
      // Clamp debe llevarlo a 15 (MEV) como mínimo
      expect(targets['chest'], greaterThanOrEqualTo(15.0));
      expect(targets['chest'], lessThanOrEqualTo(16.0));
    });

    test('buildTargets permite medios sets', () {
      // Arrange
      final mevByMuscle = {'chest': 10.0};

      final mrvByMuscle = {'chest': 20.0};

      final secondary = ['chest'];

      // Act
      final targets = InitialVolumeTargetService.buildTargets(
        muscles: mevByMuscle.keys,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        primary: [],
        secondary: secondary,
        tertiary: [],
      );

      // Assert
      // 70% de 20 = 14.0
      expect(targets['chest'], 14.0);

      // Verificar que permite 0.5 (medios sets)
      final halfSetValue = (targets['chest']! * 2) % 2;
      expect(halfSetValue, isIn([0.0, 1.0])); // Múltiplo de 0.5
    });

    test('buildTargets maneja músculos sin MEV/MRV', () {
      // Arrange
      final mevByMuscle = {'chest': 10.0, 'back': 10.0};

      final mrvByMuscle = {
        'chest': 20.0,
        // back NO tiene MRV (caso edge)
      };

      final primary = ['chest', 'back'];

      // Act
      final targets = InitialVolumeTargetService.buildTargets(
        muscles: ['chest', 'back', 'unknown'],
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        primary: primary,
        secondary: [],
        tertiary: [],
      );

      // Assert
      expect(targets['chest'], 18.0); // 90% de 20
      expect(targets['back'], isNull); // Sin MRV, skip
      expect(targets['unknown'], isNull); // Sin datos, skip
    });

    test('buildTargets prioridades se acercan progresivamente a MRV', () {
      // Arrange
      final mevByMuscle = {
        'primary': 10.0,
        'secondary': 10.0,
        'tertiary': 10.0,
        'none': 10.0,
      };

      final mrvByMuscle = {
        'primary': 20.0,
        'secondary': 20.0,
        'tertiary': 20.0,
        'none': 20.0,
      };

      // Act
      final targets = InitialVolumeTargetService.buildTargets(
        muscles: mevByMuscle.keys,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        primary: ['primary'],
        secondary: ['secondary'],
        tertiary: ['tertiary'],
      );

      // Assert - Orden descendente de volumen
      expect(targets['primary']!, greaterThan(targets['secondary']!));
      expect(targets['secondary']!, greaterThan(targets['tertiary']!));
      expect(targets['tertiary']!, greaterThan(targets['none']!));

      // Primario más cerca de MRV
      expect(targets['primary'], 18.0); // 90% × 20

      // No priorizado igual a MEV
      expect(targets['none'], 10.0); // MEV
    });
  });
}
