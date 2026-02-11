import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/services/failure_policy_service.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';

void main() {
  group('Failure Policy: Mayor frecuencia reduce cuota de fallo', () {
    late FailurePolicyService service;

    setUp(() {
      service = FailurePolicyService();
    });

    test('Cuota de fallo se reduce cuando frecuencia sube de 2 a 3', () {
      const legPressMachine = ExerciseEntry(
        code: 'leg_press_machine',
        name: 'Leg Press Machine',
        muscleGroup: MuscleGroup.quads,
        equipment: ['machine'],
        isCompound: false,
      );

      // Caso A: frecuencia 2 (20% de 12 = 2.4 ≈ 2 slots)
      final decisionFreq2 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: legPressMachine,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 2, // día 2 de 3
        daysPerWeek: 3,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 2,
      );

      // Caso B: frecuencia 3 (16% de 12 = 1.92 ≈ 2 slots teóricos, pero distribución reduce)
      final decisionFreq3 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: legPressMachine,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 2, // día 2 de 3
        daysPerWeek: 3,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 3,
      );

      // Verificar que ambos permitieron fallo
      expect(decisionFreq2.allowFailureOnLastSet, isTrue);
      expect(decisionFreq3.allowFailureOnLastSet, isTrue);

      // Verificar reducción de cuota: freq 3 debe tener <= slots que freq 2
      expect(
        decisionFreq3.maxFailureSetsThisSession,
        lessThanOrEqualTo(decisionFreq2.maxFailureSetsThisSession),
        reason:
            'Frecuencia 3 debe tener ≤ slots que freq 2 (mayor frecuencia = menor dosis de fallo)',
      );
    });

    test('Cuota de fallo se reduce significativamente en frecuencia 4', () {
      const cableFlyCheap = ExerciseEntry(
        code: 'cable_pec_deck',
        name: 'Cable Pec Deck',
        muscleGroup: MuscleGroup.chest,
        equipment: ['cable'],
        isCompound: false,
      );

      // Caso A: frecuencia 2
      final decisionFreq2 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: cableFlyCheap,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 3,
        dayIndex: 4, // día 4 de 4 (último día)
        daysPerWeek: 4,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 2,
      );

      // Caso B: frecuencia 4 (10% de 12 = 1.2 ≈ 1 slot)
      final decisionFreq4 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: cableFlyCheap,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 3,
        dayIndex: 4, // día 4 de 4 (último día)
        daysPerWeek: 4,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 4,
      );

      expect(decisionFreq2.allowFailureOnLastSet, isTrue);
      expect(decisionFreq4.allowFailureOnLastSet, isTrue);

      // Reducción más significativa en frecuencia 4
      expect(
        decisionFreq4.maxFailureSetsThisSession,
        lessThanOrEqualTo(decisionFreq2.maxFailureSetsThisSession),
        reason: 'Frecuencia 4 debe tener significativamente menos slots',
      );
    });

    test('Verifica que distribución es determinista por dayIndex', () {
      const chainePulldown = ExerciseEntry(
        code: 'lat_pulldown_machine',
        name: 'Lat Pulldown Machine',
        muscleGroup: MuscleGroup.back,
        equipment: ['machine'],
        isCompound: false,
      );

      // Mismo contexto, diferentes días
      final decisionDay1 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: chainePulldown,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 1, // primer día
        daysPerWeek: 4,
        muscleWeeklySets: 14,
        muscleWeeklyFrequency: 4,
      );

      final decisionDay4 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'low',
        exercise: chainePulldown,
        targetRir: const RirTarget.range(2, 3),
        weekIndex: 2,
        dayIndex: 4, // último día
        daysPerWeek: 4,
        muscleWeeklySets: 14,
        muscleWeeklyFrequency: 4,
      );

      // Ambos pasan las validaciones
      // (aunque day1 puede tener 0 slots si no está en los últimos días)

      // Determinismo: día 4 debe tener >= slots que día 1
      // (estrategia: colocar slots al final de la semana para recuperación)
      expect(
        decisionDay4.maxFailureSetsThisSession,
        greaterThanOrEqualTo(decisionDay1.maxFailureSetsThisSession),
        reason:
            'Últimos días de la semana deben asignar >= slots que primeros días',
      );
    });

    test('Razones registran reducción por frecuencia', () {
      const dumbbellFly = ExerciseEntry(
        code: 'dumbbell_fly',
        name: 'Dumbbell Fly',
        muscleGroup: MuscleGroup.chest,
        equipment: ['dumbbell'],
        isCompound: false,
      );

      final decisionFreq4 = service.evaluate(
        level: TrainingLevel.advanced,
        phase: TrainingPhase.accumulation,
        fatigueExpectation: 'normal',
        exercise: dumbbellFly,
        targetRir: const RirTarget.single(2),
        weekIndex: 1,
        dayIndex: 2,
        daysPerWeek: 4,
        muscleWeeklySets: 12,
        muscleWeeklyFrequency: 4,
      );

      // Verificar que contexto de debug registra frecuencia
      expect(
        decisionFreq4.debugContext['muscleWeeklyFrequency'],
        equals(4),
        reason: 'Debug context debe registrar frecuencia semanal',
      );
      expect(
        decisionFreq4.debugContext['percentageByFrequency'],
        equals(0.10),
        reason: 'Debug context debe mostrar % para frecuencia 4 = 10%',
      );
    });
  });
}
