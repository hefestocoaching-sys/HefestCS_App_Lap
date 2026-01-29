import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_4_split_distribution_service.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_6_exercise_selection_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';

void main() {
  int rirMin(String rir) {
    final m = RegExp(r'\d+').allMatches(rir).map((e) => e.group(0)!).toList();
    if (m.isEmpty) {
      throw FormatException('RIR inválido: $rir');
    }
    return int.parse(m.first);
  }

  group('Sprint 3 - Fase 6 y 7', () {
    late Phase4SplitDistributionService phase4;
    late Phase5PeriodizationService phase5;
    late Phase6ExerciseSelectionService phase6;
    late Phase7PrescriptionService phase7;

    setUp(() {
      phase4 = Phase4SplitDistributionService();
      phase5 = Phase5PeriodizationService();
      phase6 = Phase6ExerciseSelectionService();
      phase7 = Phase7PrescriptionService();
    });

    ExerciseCatalog catalog() {
      // Carga desde archivo
      return ExerciseCatalog.fromFilePath('lib/data/exercise_catalog.json');
    }

    test('determinismo: misma entrada → misma selección y prescripción', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        equipment: const [
          'barbell',
          'dumbbell',
          'machine',
          'cable',
          'bodyweight',
        ],
      );

      final baseSplit = phase4
          .buildWeeklySplit(
            profile: profile,
            volumeByMuscle: {
              'chest': VolumeLimits(
                muscleGroup: 'chest',
                mev: 8,
                mav: 14,
                mrv: 18,
                recommendedStartVolume: 10,
              ),
              'back': VolumeLimits(
                muscleGroup: 'back',
                mev: 10,
                mav: 16,
                mrv: 20,
                recommendedStartVolume: 12,
              ),
              'shoulders': VolumeLimits(
                muscleGroup: 'shoulders',
                mev: 8,
                mav: 14,
                mrv: 18,
                recommendedStartVolume: 10,
              ),
              'quads': VolumeLimits(
                muscleGroup: 'quads',
                mev: 8,
                mav: 12,
                mrv: 16,
                recommendedStartVolume: 9,
              ),
              'hamstrings': VolumeLimits(
                muscleGroup: 'hamstrings',
                mev: 6,
                mav: 10,
                mrv: 14,
                recommendedStartVolume: 8,
              ),
              'biceps': VolumeLimits(
                muscleGroup: 'biceps',
                mev: 4,
                mav: 10,
                mrv: 14,
                recommendedStartVolume: 6,
              ),
              'triceps': VolumeLimits(
                muscleGroup: 'triceps',
                mev: 4,
                mav: 10,
                mrv: 14,
                recommendedStartVolume: 6,
              ),
            },
          )
          .split;

      final period = phase5.periodize(profile: profile, baseSplit: baseSplit);
      final cat = catalog();

      final selA = phase6.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: cat,
        weeks: 4,
      );
      final selB = phase6.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: cat,
        weeks: 4,
      );

      expect(selA.selections, equals(selB.selections));

      final presA = phase7.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: period,
        selections: selA.selections,
      );
      final presB = phase7.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: period,
        selections: selB.selections,
      );

      expect(presA.weekDayPrescriptions, equals(presB.weekDayPrescriptions));
    });

    test('total de sets por músculo coincide con dailyVolume', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        equipment: const [
          'barbell',
          'dumbbell',
          'machine',
          'cable',
          'bodyweight',
        ],
      );
      final baseSplit = phase4
          .buildWeeklySplit(
            profile: profile,
            volumeByMuscle: {
              'chest': VolumeLimits(
                muscleGroup: 'chest',
                mev: 8,
                mav: 14,
                mrv: 18,
                recommendedStartVolume: 10,
              ),
              'back': VolumeLimits(
                muscleGroup: 'back',
                mev: 10,
                mav: 16,
                mrv: 20,
                recommendedStartVolume: 12,
              ),
              'shoulders': VolumeLimits(
                muscleGroup: 'shoulders',
                mev: 8,
                mav: 14,
                mrv: 18,
                recommendedStartVolume: 10,
              ),
              'quads': VolumeLimits(
                muscleGroup: 'quads',
                mev: 8,
                mav: 12,
                mrv: 16,
                recommendedStartVolume: 9,
              ),
            },
          )
          .split;
      final period = phase5.periodize(profile: profile, baseSplit: baseSplit);
      final cat = catalog();
      final sel = phase6.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: cat,
        weeks: 4,
      );
      final pres = phase7.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: period,
        selections: sel.selections,
      );

      // Semana 1 Día 1: sumar sets por músculo
      final day1Volume = period.weeks[0].dailyVolume[1]!;
      final day1Pres =
          pres.weekDayPrescriptions[period.weeks[0].weekIndex]![1]!;
      final setsByMuscle = <String, int>{};
      for (final p in day1Pres) {
        setsByMuscle[p.muscleGroup.name] =
            (setsByMuscle[p.muscleGroup.name] ?? 0) + p.sets;
      }
      for (final entry in day1Volume.entries) {
        expect(setsByMuscle[entry.key] ?? 0, equals(entry.value));
      }
    });

    test('RIR cambia según fase', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        equipment: const [
          'barbell',
          'dumbbell',
          'machine',
          'cable',
          'bodyweight',
        ],
      );
      final baseSplit = phase4
          .buildWeeklySplit(
            profile: profile,
            volumeByMuscle: {
              'chest': VolumeLimits(
                muscleGroup: 'chest',
                mev: 8,
                mav: 14,
                mrv: 18,
                recommendedStartVolume: 10,
              ),
            },
          )
          .split;
      final period = phase5.periodize(profile: profile, baseSplit: baseSplit);
      final sel = phase6.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog(),
        weeks: 4,
      );
      final pres = phase7.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: period,
        selections: sel.selections,
      );

      final w1d1 = pres.weekDayPrescriptions[period.weeks[0].weekIndex]![1]!;
      final rir1 = rirMin(w1d1.first.rir);
      expect(rir1 >= 1 && rir1 <= 3, true); // accumulation: moderate RIR
      final w3d1 = pres.weekDayPrescriptions[period.weeks[2].weekIndex]![1]!;
      final rir3 = rirMin(w3d1.first.rir);
      expect(rir3 < rir1, true); // intensification: lower RIR than accumulation
      final w4d1 = pres.weekDayPrescriptions[period.weeks[3].weekIndex]![1]!;
      final rir4 = rirMin(w4d1.first.rir);
      expect(rir4 > rir1, true); // deload: higher RIR than accumulation
    });

    test('ninguna sesión excede tiempo disponible', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 30,
        trainingLevel: TrainingLevel.beginner,
        equipment: const ['bodyweight', 'cable'],
      );
      final baseSplit = phase4
          .buildWeeklySplit(
            profile: profile,
            volumeByMuscle: {
              'chest': VolumeLimits(
                muscleGroup: 'chest',
                mev: 8,
                mav: 14,
                mrv: 18,
                recommendedStartVolume: 10,
              ),
              'back': VolumeLimits(
                muscleGroup: 'back',
                mev: 10,
                mav: 16,
                mrv: 20,
                recommendedStartVolume: 12,
              ),
            },
          )
          .split;
      final period = phase5.periodize(profile: profile, baseSplit: baseSplit);
      final sel = phase6.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog(),
        weeks: 4,
      );
      final pres = phase7.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: period,
        selections: sel.selections,
      );

      for (var d = 1; d <= baseSplit.daysPerWeek; d++) {
        final dayPres =
            pres.weekDayPrescriptions[period.weeks[0].weekIndex]![d]!;
        final setsTotal = dayPres.fold<int>(0, (s, p) => s + p.sets);
        expect(setsTotal * 4, lessThanOrEqualTo(profile.timePerSessionMinutes));
      }
    });

    test('DecisionTrace incluye fases 6 y 7', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        equipment: const [
          'barbell',
          'dumbbell',
          'machine',
          'cable',
          'bodyweight',
        ],
      );
      final baseSplit = phase4.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: {
          'chest': VolumeLimits(
            muscleGroup: 'chest',
            mev: 8,
            mav: 14,
            mrv: 18,
            recommendedStartVolume: 10,
          ),
          'back': VolumeLimits(
            muscleGroup: 'back',
            mev: 10,
            mav: 16,
            mrv: 20,
            recommendedStartVolume: 12,
          ),
        },
      );
      final period = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit.split,
      );
      final cat = catalog();
      final sel = phase6.selectExercises(
        profile: profile,
        baseSplit: baseSplit.split,
        catalog: cat,
        weeks: 4,
      );
      final pres = phase7.buildPrescriptions(
        baseSplit: baseSplit.split,
        periodization: period,
        selections: sel.selections,
      );

      expect(
        sel.decisions.any((d) => d.phase == 'Phase6ExerciseSelection'),
        true,
      );
      expect(pres.decisions.any((d) => d.phase == 'Phase7Prescription'), true);
    });

    test(
      'Phase7: en semana de intensification, RIR se ajusta según trainingLevel',
      () {
        final profileAdvanced = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 60,
          trainingLevel: TrainingLevel.advanced,
          equipment: const [
            'barbell',
            'dumbbell',
            'machine',
            'cable',
            'bodyweight',
          ],
        );

        final volumeLimits = {
          'chest': VolumeLimits(
            muscleGroup: 'chest',
            mev: 8,
            mav: 14,
            mrv: 18,
            recommendedStartVolume: 10,
          ),
        };

        final baseSplit = phase4
            .buildWeeklySplit(
              profile: profileAdvanced,
              volumeByMuscle: volumeLimits,
            )
            .split;

        final period = phase5.periodize(
          profile: profileAdvanced,
          baseSplit: baseSplit,
        );
        final cat = catalog();

        // Selecciones determinísticas
        final sel = phase6.selectExercises(
          profile: profileAdvanced,
          baseSplit: baseSplit,
          catalog: cat,
          weeks: 4,
        );

        // Prescripciones para beginner
        final presBeginner = phase7.buildPrescriptions(
          baseSplit: baseSplit,
          periodization: period,
          selections: sel.selections,
          trainingLevel: TrainingLevel.beginner,
        );

        // Prescripciones para advanced
        final presAdvanced = phase7.buildPrescriptions(
          baseSplit: baseSplit,
          periodization: period,
          selections: sel.selections,
          trainingLevel: TrainingLevel.advanced,
        );

        // Semana 2 es intensification (índice 2 en ciclo de 4)
        final intensWeek = 2;
        final periodWeek = period.weeks[intensWeek];
        expect(periodWeek.phase, TrainingPhase.intensification);

        // Extraer prescripciones de semana intensificación
        final wIdx = periodWeek.weekIndex;
        final dayPrescriptionsBeginner =
            presBeginner.weekDayPrescriptions[wIdx]?[1];
        final dayPrescriptionsAdvanced =
            presAdvanced.weekDayPrescriptions[wIdx]?[1];

        expect(dayPrescriptionsBeginner, isNotNull);
        expect(dayPrescriptionsAdvanced, isNotNull);

        // En intensification:
        // Beginner RIR debe ser conservador: '2'
        // Advanced RIR debe ser agresivo: '0' (cerca del fallo)
        final rirBeginner = dayPrescriptionsBeginner!.first.rir;
        final rirAdvanced = dayPrescriptionsAdvanced!.first.rir;

        expect(
          rirMin(rirBeginner),
          greaterThan(rirMin(rirAdvanced)),
          reason: 'Beginner debe tener RIR más alto (conservador) que Advanced',
        );

        // Verificar que DecisionTrace registró el ajuste
        expect(
          presBeginner.decisions.any(
            (d) =>
                d.phase == 'Phase7Prescription' && d.category == 'week_setup',
          ),
          true,
        );

        expect(
          presAdvanced.decisions.any(
            (d) =>
                d.phase == 'Phase7Prescription' && d.category == 'week_setup',
          ),
          true,
        );
      },
    );
  });
}
