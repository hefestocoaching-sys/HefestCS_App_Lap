import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/effort_intent.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';

void main() {
  group('Motor: RIR sin decimales + orden', () {
    test('RirTarget nunca produce decimales (label)', () {
      final service = Phase7PrescriptionService();
      final target = service.computeRirTarget(
        reps: const RepRange(8, 10),
        isCompound: false,
        role: 'accessory',
        level: TrainingLevel.intermediate,
        intent: EffortIntent.base,
      );

      expect(target.label.contains('.'), false);
      expect(RegExp(r'^\d( - \d)?$').hasMatch(target.label), true);
    });

    test('RIR varía por rep range (más alto en rangos altos)', () {
      final service = Phase7PrescriptionService();
      final lowReps = service.computeRirTarget(
        reps: const RepRange(5, 6),
        isCompound: true,
        role: 'primary',
        level: TrainingLevel.intermediate,
        intent: EffortIntent.base,
      );
      final highReps = service.computeRirTarget(
        reps: const RepRange(15, 20),
        isCompound: true,
        role: 'primary',
        level: TrainingLevel.intermediate,
        intent: EffortIntent.base,
      );

      expect(lowReps.min >= 2, true);
      expect(highReps.min >= 3, true);
      expect(highReps.min >= lowReps.min, true);
    });

    test('Beginner + push nunca produce RIR < 1', () {
      final service = Phase7PrescriptionService();
      final target = service.computeRirTarget(
        reps: const RepRange(6, 8),
        isCompound: true,
        role: 'primary',
        level: TrainingLevel.beginner,
        intent: EffortIntent.push,
      );

      expect(target.min >= 1, true);
      expect(target.label.contains('.'), false);
    });

    test('Orden: exercise clave primero (priorityExercises)', () {
      final service = Phase7PrescriptionService();

      final baseSplit = SplitTemplate(
        splitId: 't',
        daysPerWeek: 1,
        dayMuscles: {
          1: ['chest'],
        },
        dailyVolume: {
          1: {'chest': 6},
        },
      );

      final periodization = Phase5PeriodizationResult(
        weeks: [
          PeriodizedWeek(
            weekIndex: 1,
            phase: TrainingPhase.accumulation,
            volumeFactor: 1.0,
            effortIntent: EffortIntent.base,
            repBias: RepBias.moderate,
            fatigueExpectation: 'low',
            dailyVolume: {
              1: {'chest': 6},
            },
          ),
        ],
        decisions: const [],
      );

      // Poner el ejercicio clave en la segunda posición para comprobar reordenado.
      final nonPriority = const ExerciseEntry(
        code: 'machine_press',
        name: 'Machine Press',
        muscleGroup: MuscleGroup.chest,
        equipment: ['machine'],
        isCompound: false,
      );
      final priority = const ExerciseEntry(
        code: 'bench_press',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        equipment: ['barbell'],
        isCompound: true,
      );

      final selections = {
        1: {
          1: {
            MuscleGroup.chest: [nonPriority, priority],
          },
        },
      };

      final profile = TrainingProfile(
        daysPerWeek: 1,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        extra: {
          TrainingExtraKeys.priorityExercises: 'bench, banca, bench press',
        },
      );

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.intermediate,
        profile: profile,
      );

      final day = res.weekDayPrescriptions[1]![1]!;
      expect(day.isNotEmpty, true);
      expect(day.first.exerciseCode, 'bench_press');
    });
  });
}
