import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/constants/frequency_by_volume.dart';

void main() {
  test('Volumen ≤20 sets → Frecuencia 2x', () {
    expect(
      FrequencyByVolume.calculateFrequency(
        weeklyVolume: 14,
        maxDaysAvailable: 4,
      ),
      equals(2),
    );

    expect(
      FrequencyByVolume.calculateFrequency(
        weeklyVolume: 20,
        maxDaysAvailable: 4,
      ),
      equals(2),
    );
  });

  test('Volumen ≥21 sets → Frecuencia 3x', () {
    expect(
      FrequencyByVolume.calculateFrequency(
        weeklyVolume: 21,
        maxDaysAvailable: 4,
      ),
      equals(3),
    );

    expect(
      FrequencyByVolume.calculateFrequency(
        weeklyVolume: 22,
        maxDaysAvailable: 4,
      ),
      equals(3),
    );
  });

  test('Si solo hay 2 días disponibles, máximo 2x', () {
    expect(
      FrequencyByVolume.calculateFrequency(
        weeklyVolume: 25,
        maxDaysAvailable: 2,
      ),
      equals(2),
    );
  });

  test('Distribución de sets en 2 sesiones', () {
    final distribution = FrequencyByVolume.distributeSetsAcrossFrequency(
      weeklyVolume: 14,
      frequency: 2,
    );

    expect(distribution, equals([7, 7]));
  });

  test('Distribución de sets en 3 sesiones (con resto)', () {
    final distribution = FrequencyByVolume.distributeSetsAcrossFrequency(
      weeklyVolume: 22,
      frequency: 3,
    );

    // 22 ÷ 3 = 7 con resto 1
    expect(distribution, equals([8, 7, 7]));
  });

  test('Validación de frecuencia suficiente', () {
    // 20 sets ÷ 2 = 10 sets/sesión
    // Límite intermediate = 8
    // → NO suficiente
    expect(
      FrequencyByVolume.isFrequencySufficient(
        weeklyVolume: 20,
        frequency: 2,
        level: 'intermediate',
        muscle: 'chest',
      ),
      isFalse,
    );

    // 20 sets ÷ 3 = 6.7 sets/sesión
    // Límite intermediate = 8
    // → Suficiente
    expect(
      FrequencyByVolume.isFrequencySufficient(
        weeklyVolume: 20,
        frequency: 3,
        level: 'intermediate',
        muscle: 'chest',
      ),
      isTrue,
    );
  });

  test('Cálculo de frecuencia mínima necesaria', () {
    // 20 sets, límite 8 sets/sesión
    // → Necesita 3 sesiones mínimo
    expect(
      FrequencyByVolume.calculateMinimumFrequency(
        weeklyVolume: 20,
        level: 'intermediate',
        muscle: 'chest',
      ),
      equals(3),
    );
  });
}
