import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';

void main() {
  group('ManualOverride', () {
    test('parseFromMap con null retorna override vacío', () {
      final override = ManualOverride.fromMap(null);
      expect(override.hasAnyOverride, false);
      expect(override.volumeOverrides, isNull);
      expect(override.priorityOverrides, isNull);
      expect(override.allowIntensification, false);
      expect(override.rirTargetOverride, isNull);
    });

    test('parseFromMap con map vacío retorna override vacío', () {
      final override = ManualOverride.fromMap({});
      expect(override.hasAnyOverride, false);
    });

    test('validate: override válido sin warnings', () {
      const override = ManualOverride(
        volumeOverrides: {
          'chest': VolumeOverride(mev: 6, mav: 12, mrv: 18),
          'back': VolumeOverride(mrv: 20),
        },
        priorityOverrides: {'chest': 'primary', 'back': 'secondary'},
        rirTargetOverride: 2.0,
        allowIntensification: true,
        intensificationMaxPerWeek: 2,
      );

      final warnings = override.validate();
      expect(warnings, isEmpty);
    });

    test('validate: MEV inválido < 0 registra warning', () {
      const override = ManualOverride(
        volumeOverrides: {'chest': VolumeOverride(mev: -5, mav: 12, mrv: 18)},
      );

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(warnings.any((w) => w.contains('MEV debe ser > 0')), true);
    });

    test('validate: MEV > MAV registra warning', () {
      const override = ManualOverride(
        volumeOverrides: {'chest': VolumeOverride(mev: 15, mav: 12, mrv: 18)},
      );

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(warnings.any((w) => w.contains('MEV > MAV')), true);
    });

    test('validate: MAV > MRV registra warning', () {
      const override = ManualOverride(
        volumeOverrides: {'chest': VolumeOverride(mev: 6, mav: 20, mrv: 18)},
      );

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(warnings.any((w) => w.contains('MAV > MRV')), true);
    });

    test('validate: músculo inválido registra warning', () {
      const override = ManualOverride(
        volumeOverrides: {
          'invalid_muscle': VolumeOverride(mev: 6, mav: 12, mrv: 18),
        },
      );

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(warnings.any((w) => w.contains('músculo inválido')), true);
    });

    test('validate: prioridad inválida registra warning', () {
      const override = ManualOverride(
        priorityOverrides: {'chest': 'invalid_priority'},
      );

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(warnings.any((w) => w.contains('prioridad inválida')), true);
    });

    test('validate: RIR > 4.0 registra warning', () {
      const override = ManualOverride(rirTargetOverride: 5.0);

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(warnings.any((w) => w.contains('rirTargetOverride')), true);
    });

    test('validate: RIR < 0 registra warning', () {
      const override = ManualOverride(rirTargetOverride: -1.0);

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
    });

    test('validate: intensificationMaxPerWeek < 0 registra warning', () {
      const override = ManualOverride(intensificationMaxPerWeek: -5);

      final warnings = override.validate();
      expect(warnings.length, greaterThan(0));
      expect(
        warnings.any((w) => w.contains('intensificationMaxPerWeek')),
        true,
      );
    });

    test('hasAnyOverride: false cuando todo es nulo/defaults', () {
      const override = ManualOverride(intensificationMaxPerWeek: 0);
      expect(override.hasAnyOverride, false);
    });

    test('hasAnyOverride: true cuando hay volumeOverrides', () {
      const override = ManualOverride(
        volumeOverrides: {'chest': VolumeOverride(mrv: 20)},
      );
      expect(override.hasAnyOverride, true);
    });

    test('hasAnyOverride: true cuando hay rirTargetOverride', () {
      const override = ManualOverride(rirTargetOverride: 2.0);
      expect(override.hasAnyOverride, true);
    });

    test('parseFromMap con estructura compleja', () {
      final raw = {
        'volumeOverrides': {
          'chest': {'mev': 6, 'mav': 12, 'mrv': 18},
          'back': {'mrv': 20},
        },
        'priorityOverrides': {'chest': 'primary'},
        'rirTargetOverride': 1.5,
        'allowIntensification': true,
        'intensificationMaxPerWeek': 3,
      };

      final override = ManualOverride.fromMap(raw);
      expect(override.volumeOverrides!['chest']!.mev, 6);
      expect(override.volumeOverrides!['chest']!.mrv, 18);
      expect(override.volumeOverrides!['back']!.mrv, 20);
      expect(override.priorityOverrides!['chest'], 'primary');
      expect(override.rirTargetOverride, 1.5);
      expect(override.allowIntensification, true);
      expect(override.intensificationMaxPerWeek, 3);
    });

    test(
      'determinismo: múltiples validaciones con mismos datos → mismos warnings',
      () {
        const override = ManualOverride(
          volumeOverrides: {'chest': VolumeOverride(mev: 15, mav: 10)},
        );

        final w1 = override.validate();
        final w2 = override.validate();
        expect(w1, equals(w2));
      },
    );

    test('VolumeOverride.isEmpty: true cuando todo es null', () {
      const vol = VolumeOverride();
      expect(vol.isEmpty, true);
    });

    test('VolumeOverride.isEmpty: false cuando hay algún valor', () {
      const vol = VolumeOverride(mrv: 20);
      expect(vol.isEmpty, false);
    });
  });
}
