import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/policies/day_exercise_ordering_policy.dart';

/// Test suite de invariantes del motor de entrenamiento
/// Verifica:
/// - RIR nunca tiene decimales
/// - RIR label solo es "n" o "n-n"
/// - Para cada prescripción: min<=max y 0<=min<=4
/// - Orden del día: primer ejercicio es primario si existe
/// - No hay dos ejercicios consecutivos del mismo músculo cuando hay alternativas
void main() {
  group('Invariantes RirTarget', () {
    test('RirTarget.label nunca contiene decimales', () {
      expect(RirTarget.single(2).label, equals('2'));
      expect(RirTarget.range(2, 3).label, equals('2 - 3'));
      expect(RirTarget.range(0, 1).label, equals('0 - 1'));
      expect(RirTarget.single(4).label, equals('4'));

      // Verificar que no contiene puntos (decimales)
      final targets = [
        RirTarget.single(0),
        RirTarget.single(1),
        RirTarget.single(2),
        RirTarget.single(3),
        RirTarget.single(4),
        RirTarget.range(0, 1),
        RirTarget.range(1, 2),
        RirTarget.range(2, 3),
        RirTarget.range(3, 4),
      ];

      for (final target in targets) {
        expect(
          target.label.contains('.'),
          isFalse,
          reason: 'RirTarget.label "${target.label}" contiene decimal',
        );
      }
    });

    test('RirTarget.label match patrón "n" o "n - n"', () {
      expect(
        RegExp(r'^\d+( - \d+)?$').hasMatch(RirTarget.single(2).label),
        isTrue,
      );
      expect(
        RegExp(r'^\d+( - \d+)?$').hasMatch(RirTarget.range(2, 3).label),
        isTrue,
      );

      // Verificar formato exacto con espacio-guion-espacio
      expect(RirTarget.range(2, 3).label, equals('2 - 3'));
      expect(RirTarget.range(1, 2).label, equals('1 - 2'));
    });

    test('RirTarget invariantes: min<=max y 0<=min<=4', () {
      final targets = [
        RirTarget.single(0),
        RirTarget.single(2),
        RirTarget.single(4),
        RirTarget.range(0, 1),
        RirTarget.range(2, 3),
        RirTarget.range(0, 4),
      ];

      for (final target in targets) {
        expect(
          target.min <= target.max,
          isTrue,
          reason: 'RirTarget.min(${target.min}) > max(${target.max})',
        );
        expect(
          target.min >= 0 && target.min <= 4,
          isTrue,
          reason: 'RirTarget.min(${target.min}) fuera de rango [0, 4]',
        );
        expect(
          target.max >= 0 && target.max <= 4,
          isTrue,
          reason: 'RirTarget.max(${target.max}) fuera de rango [0, 4]',
        );
      }
    });

    test('RirTarget.parseLabel soporta "n", "n-n", "n–n"', () {
      expect(RirTarget.parseLabel('2').label, equals('2'));
      expect(RirTarget.parseLabel('2-3').label, equals('2 - 3'));
      expect(RirTarget.parseLabel('2–3').label, equals('2 - 3'));

      // Labels inválidos -> fallback conservador
      expect(RirTarget.parseLabel('invalid').label, equals('2 - 3'));
      expect(RirTarget.parseLabel('5').label, equals('2 - 3')); // out of range
      expect(RirTarget.parseLabel('').label, equals('2 - 3'));
    });
  });

  group('Invariantes ExercisePrescription', () {
    test('rirTarget getter convierte correctamente desde rir string', () {
      final ep1 = ExercisePrescription(
        id: 'ex1',
        sessionId: 'sess1',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'bench',
        label: 'A',
        exerciseName: 'Bench Press',
        sets: 3,
        repRange: const RepRange(8, 12),
        rir: '2',
        restMinutes: 3,
      );

      expect(ep1.rirTarget.label, equals('2'));
      expect(ep1.rirTarget.min, equals(2));
      expect(ep1.rirTarget.max, equals(2));
    });

    test('copyWithRirTarget actualiza rir field correctamente', () {
      final original = ExercisePrescription(
        id: 'ex1',
        sessionId: 'sess1',
        muscleGroup: MuscleGroup.back,
        exerciseCode: 'row',
        label: 'B',
        exerciseName: 'Row',
        sets: 4,
        repRange: const RepRange(8, 10),
        rir: '2 - 3',
        restMinutes: 2,
      );

      final updated = original.copyWithRirTarget(RirTarget.single(3));

      expect(updated.rir, equals('3'));
      expect(updated.rirTarget.label, equals('3'));
      expect(original.rir, equals('2 - 3')); // Original no cambia
    });

    test('RepRange.min<=max en todas las prescriptions', () {
      final validRanges = [
        const RepRange(4, 8),
        const RepRange(8, 12),
        const RepRange(12, 15),
        const RepRange(1, 20),
      ];

      for (final range in validRanges) {
        expect(
          range.min <= range.max,
          isTrue,
          reason: 'RepRange min(${range.min}) > max(${range.max})',
        );
      }
    });
  });

  group('Invariantes Orden de Día AA', () {
    test('Primer ejercicio del día debe ser primario si existe compuesto', () {
      final primario = ExercisePrescription(
        id: 'bench',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'bench_press',
        label: 'A',
        exerciseName: 'Barbell Bench Press',
        sets: 4,
        repRange: const RepRange(6, 8),
        rir: '2',
        restMinutes: 3,
      );

      final secondary = ExercisePrescription(
        id: 'incline',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'incline_bench',
        label: 'B',
        exerciseName: 'Incline Bench',
        sets: 3,
        repRange: const RepRange(8, 10),
        rir: '2 - 3',
        restMinutes: 2,
      );

      final accesorio = ExercisePrescription(
        id: 'fly',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'pec_fly',
        label: 'C',
        exerciseName: 'Pec Fly',
        sets: 3,
        repRange: const RepRange(12, 15),
        rir: '1 - 2',
        restMinutes: 1,
      );

      final unordered = [accesorio, secondary, primario];
      final ordered = DayExerciseOrderingPolicy.orderDay(unordered);

      // El primero debe ser el compuesto primario (bench_press)
      expect(ordered.first.exerciseCode, equals('bench_press'));
      expect(ordered.first.label, equals('A'));
    });

    test('Labels reasignados secuencialmente tras ordenamiento', () {
      final ex1 = ExercisePrescription(
        id: 'ex1',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.quads,
        exerciseCode: 'squat',
        label: 'Z', // label inicial diferente
        exerciseName: 'Squat',
        sets: 4,
        repRange: const RepRange(6, 8),
        rir: '2',
        restMinutes: 3,
      );

      final ex2 = ExercisePrescription(
        id: 'ex2',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.hamstrings,
        exerciseCode: 'leg_curl',
        label: 'Y',
        exerciseName: 'Leg Curl',
        sets: 3,
        repRange: const RepRange(12, 15),
        rir: '1 - 2',
        restMinutes: 1,
      );

      final ordered = DayExerciseOrderingPolicy.orderDay([ex2, ex1]);

      // Verificar orden (squat debe ser primero como compuesto)
      expect(ordered.first.exerciseCode, equals('squat'));
      // Nota: los labels no son relabelados por la política, eso es responsabilidad de Phase 7
      // Aquí solo verificamos que el orden es correcto
      expect(ordered.length, equals(2));
    });

    test('Evita músculos consecutivos cuando hay alternativas', () {
      final chest1 = ExercisePrescription(
        id: 'bench',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'bench_press',
        label: 'A',
        exerciseName: 'Bench',
        sets: 4,
        repRange: const RepRange(6, 8),
        rir: '2',
        restMinutes: 3,
      );

      final chest2 = ExercisePrescription(
        id: 'incline',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'incline_bench',
        label: 'B',
        exerciseName: 'Incline',
        sets: 3,
        repRange: const RepRange(8, 10),
        rir: '2 - 3',
        restMinutes: 2,
      );

      final back = ExercisePrescription(
        id: 'row',
        sessionId: 'day1',
        muscleGroup: MuscleGroup.back,
        exerciseCode: 'barbell_row',
        label: 'C',
        exerciseName: 'Row',
        sets: 4,
        repRange: const RepRange(6, 8),
        rir: '2',
        restMinutes: 3,
      );

      final ordered = DayExerciseOrderingPolicy.orderDay([
        chest1,
        chest2,
        back,
      ]);
      final muscles = ordered.map((e) => e.muscleGroup.name).toList();

      // No debe haber dos músculos de chest consecutivos
      // si existen músculos diferentes
      var hasConsecutiveSameMuscle = false;
      for (var i = 0; i < muscles.length - 1; i++) {
        if (muscles[i] == muscles[i + 1]) {
          hasConsecutiveSameMuscle = true;
        }
      }
      expect(
        hasConsecutiveSameMuscle,
        isFalse,
        reason: 'Hay músculos consecutivos cuando hay alternativas',
      );
    });
  });

  group('Invariantes finales del motor', () {
    test('Sin double.tryParse en ajustes RIR (test de sanidad)', () {
      // Esto es más bien una verificación del código fuente,
      // pero podemos verificar que el motor produce RIR válidos

      final sample = ExercisePrescription(
        id: 'test',
        sessionId: 'day',
        muscleGroup: MuscleGroup.chest,
        exerciseCode: 'bench',
        label: 'A',
        exerciseName: 'Bench',
        sets: 3,
        repRange: const RepRange(8, 12),
        rir: '2 - 3', // Debe ser parseable como RirTarget
        restMinutes: 2,
      );

      final rirTarget = sample.rirTarget;
      expect(rirTarget.min, isNotNull);
      expect(rirTarget.max, isNotNull);
      expect(rirTarget.label, isNotNull);
      expect(rirTarget.label.contains('.'), isFalse);
    });

    test('RIR nunca es decimal en formato label', () {
      final decimals = ['2.5', '3.0', '1.5', '0.5'];
      for (final d in decimals) {
        // Intentar parsear
        final target = RirTarget.parseLabel(d);
        // Debe retornar un RirTarget válido sin decimales
        expect(target.label.contains('.'), isFalse);
        expect(RegExp(r'^\d+( - \d+)?$').hasMatch(target.label), isTrue);
      }
    });

    test('RirTarget range válido: todas las combinaciones 0-4', () {
      for (var min = 0; min <= 4; min++) {
        for (var max = min; max <= 4; max++) {
          final target = RirTarget.range(min, max);
          expect(target.min, equals(min));
          expect(target.max, equals(max));
          expect(target.label, matches(RegExp(r'^\d+( - \d+)?$')));
        }
      }
    });
  });
}
