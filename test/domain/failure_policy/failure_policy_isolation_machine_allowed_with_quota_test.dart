import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/services/failure_policy_service.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';

void main() {
  group('Failure Policy: Aislados/Máquinas permitidos con cuota', () {
    late FailurePolicyService service;

    setUp(() {
      service = FailurePolicyService();
    });

    test('Permite fallo en aislado machine con cuota limitada', () {
      final legExtensionMachine = const ExerciseEntry(
        code: 'leg_extension_machine',
        name: 'Leg Extension Machine',
        muscleGroup: MuscleGroup.quads,
        equipment: ['machine'],
        isCompound: false,
      );

      final decision = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: legExtensionMachine,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 3, // día 3 de 4 (en los últimos días para slots)
        daysPerWeek: 4,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 2,
      );

      expect(
        decision.allowFailureOnLastSet,
        isTrue,
        reason: 'Aislado en máquina debe permitir fallo',
      );
      expect(
        decision.maxFailureSetsThisSession,
        greaterThan(0),
        reason: 'Debe asignar al menos 1 slot de fallo para máquina aislada',
      );
      expect(
        decision.reasons.contains('allowed'),
        isTrue,
        reason: 'Razones deben indicar que fue permitido',
      );
    });

    test('Permite fallo en cable aislado (intermediate level válido)', () {
      final cableFly = const ExerciseEntry(
        code: 'cable_fly',
        name: 'Cable Fly',
        muscleGroup: MuscleGroup.chest,
        equipment: ['cable'],
        isCompound: false,
      );

      final decision = service.evaluate(
        level: TrainingLevel.intermediate,
        phase: TrainingPhase.intensification,
        fatigueExpectation: 'normal',
        exercise: cableFly,
        targetRir: const RirTarget.single(2),
        weekIndex: 3,
        dayIndex: 3,
        daysPerWeek: 3,
        muscleWeeklySets: 10,
        muscleWeeklyFrequency: 3,
      );

      expect(
        decision.allowFailureOnLastSet,
        isTrue,
        reason: 'Aislado en cable debe permitir fallo para intermediate',
      );
      expect(decision.maxFailureSetsThisSession, greaterThan(0));
    });

    test(
      'Verifica que la cuota de fallo es conservadora: 1-2 slots máximo',
      () {
        final cableAdjustableMultiple = const ExerciseEntry(
          code: 'chest_fly_cable',
          name: 'Cable Pec Deck',
          muscleGroup: MuscleGroup.chest,
          equipment: ['cable'],
          isCompound: false,
        );

        final decision = service.evaluate(
          level: TrainingLevel.advanced,
          phase: TrainingPhase.accumulation,
          fatigueExpectation: 'low',
          exercise: cableAdjustableMultiple,
          targetRir: const RirTarget.range(2, 3),
          weekIndex: 1,
          dayIndex: 1,
          daysPerWeek: 4,
          muscleWeeklySets: 12,
          muscleWeeklyFrequency: 2,
        );

        expect(
          decision.maxFailureSetsThisSession,
          lessThanOrEqualTo(2),
          reason: 'Cuota de fallo debe ser muy conservadora (máximo 1-2)',
        );
      },
    );

    test('Bloquea fallo en aislado si RIR es demasiado bajo', () {
      final dumbbellCurl = const ExerciseEntry(
        code: 'dumbbell_curl',
        name: 'Dumbbell Curl',
        muscleGroup: MuscleGroup.biceps,
        equipment: ['dumbbell'],
        isCompound: false,
      );

      final decision = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: dumbbellCurl,
        targetRir: const RirTarget.single(1), // min < 2
        weekIndex: 2,
        dayIndex: 1,
        daysPerWeek: 4,
        muscleWeeklySets: 10,
        muscleWeeklyFrequency: 2,
      );

      expect(
        decision.allowFailureOnLastSet,
        isFalse,
        reason: 'RIR < 2 debe bloquear fallo incluso en aislado',
      );
      expect(decision.maxFailureSetsThisSession, equals(0));
    });

    test('Permite fallo en aislado con RIR >= 2 (límite inferior)', () {
      final cbBarCurl = const ExerciseEntry(
        code: 'ez_bar_curl',
        name: 'EZ Bar Curl',
        muscleGroup: MuscleGroup.biceps,
        equipment: ['barbell'],
        isCompound: false,
      );

      final decision = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'normal',
        exercise: cbBarCurl,
        targetRir: const RirTarget.single(2),
        weekIndex: 2,
        dayIndex: 3, // día 3 de 4 (en los últimos días)
        daysPerWeek: 4,
        muscleWeeklySets: 8,
        muscleWeeklyFrequency: 2,
      );

      expect(
        decision.allowFailureOnLastSet,
        isTrue,
        reason: 'RIR >= 2 debe permitir fallo en aislado',
      );
    });
  });
}
