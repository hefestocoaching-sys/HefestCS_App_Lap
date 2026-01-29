import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/services/failure_policy_service.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';

void main() {
  group('Failure Policy: Compuestos con pesas libres bloqueados', () {
    late FailurePolicyService service;

    setUp(() {
      service = FailurePolicyService();
    });

    test('Bloquea fallo en compound barbell incluso con advanced level', () {
      final barbellRow = const ExerciseEntry(
        code: 'barbell_row',
        name: 'Barbell Row',
        muscleGroup: MuscleGroup.back,
        equipment: ['barbell'],
        isCompound: true,
      );

      final decision = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: barbellRow,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 1,
        daysPerWeek: 4,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 2,
      );

      expect(
        decision.allowFailureOnLastSet,
        isFalse,
        reason:
            'Fallo debe bloquearse en compuesto barbell, incluso con advanced level',
      );
      expect(
        decision.maxFailureSetsThisSession,
        equals(0),
        reason: 'No debe haber slots de fallo para compuesto libre',
      );
      expect(
        decision.reasons.any((r) => r.contains('compound')),
        isTrue,
        reason: 'Razones deben mencionar bloqueo por compound',
      );
    });

    test('Bloquea fallo en compound dumbbell (pesa libre)', () {
      final dbPress = const ExerciseEntry(
        code: 'dumbbell_press',
        name: 'Dumbbell Press',
        muscleGroup: MuscleGroup.shoulders,
        equipment: ['dumbbell'],
        isCompound: true,
      );

      final decision = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.intensification,
        fatigueExpectation: 'normal',
        exercise: dbPress,
        targetRir: const RirTarget.single(2),
        weekIndex: 3,
        dayIndex: 2,
        daysPerWeek: 3,
        muscleWeeklySets: 10,
        muscleWeeklyFrequency: 3,
      );

      expect(decision.allowFailureOnLastSet, isFalse);
      expect(decision.maxFailureSetsThisSession, equals(0));
    });

    test(
      'Verifica que RIR insuficiente también bloquea (barbell compound)',
      () {
        final benchLowRIR = const ExerciseEntry(
          code: 'bench_barbell',
          name: 'Barbell Bench Press',
          muscleGroup: MuscleGroup.chest,
          equipment: ['barbell'],
          isCompound: true,
        );

        final decision = service.evaluate(
          level: TrainingLevel.advanced,
          phase: TrainingPhase.accumulation,
          fatigueExpectation: 'low',
          exercise: benchLowRIR,
          targetRir: const RirTarget.range(1, 2), // min < 2
          weekIndex: 1,
          dayIndex: 1,
          daysPerWeek: 4,
          muscleWeeklySets: 12,
          muscleWeeklyFrequency: 2,
        );

        expect(
          decision.allowFailureOnLastSet,
          isFalse,
          reason: 'Barbell compound debe bloquearse por tipo de ejercicio',
        );
        expect(
          decision.reasons.any((r) => r.contains('compound')),
          isTrue,
          reason: 'Razones deben mencionar bloqueo por compound',
        );
      },
    );

    test('Bloquea fallo cuando volumen compound es muy alto', () {
      final heavyCompound = const ExerciseEntry(
        code: 'deadlift_barbell',
        name: 'Deadlift',
        muscleGroup: MuscleGroup.hamstrings,
        equipment: ['barbell'],
        isCompound: true,
      );

      final decision = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: heavyCompound,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 1,
        daysPerWeek: 3,
        muscleWeeklySets: 28, // volumen muy alto
        muscleWeeklyFrequency: 3,
      );

      expect(
        decision.allowFailureOnLastSet,
        isFalse,
        reason: 'Volumen muy alto debe bloquear fallo en compound',
      );
    });
  });
}
