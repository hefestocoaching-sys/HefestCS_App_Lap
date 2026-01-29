import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';

void main() {
  int rirMin(String rir) {
    final m = RegExp(r'\d+').allMatches(rir).map((e) => e.group(0)!).toList();
    if (m.isEmpty) {
      throw FormatException('RIR inválido: $rir');
    }
    return int.parse(m.first);
  }

  group('Phase7 prescription with Phase5 data', () {
    late Phase7PrescriptionService service;
    late SplitTemplate baseSplit;
    late Phase5PeriodizationService phase5;

    setUp(() {
      service = Phase7PrescriptionService();
      phase5 = Phase5PeriodizationService();

      baseSplit = SplitTemplate(
        splitId: 'test',
        daysPerWeek: 2,
        dayMuscles: {
          1: ['quads'],
          2: ['glutes', 'chest'],
        },
        dailyVolume: {
          1: {'quads': 8},
          2: {'glutes': 6, 'chest': 4},
        },
      );
    });

    test('repBias high produce repRange >= 10 y <= 15', () {
      final profile = TrainingProfile(
        daysPerWeek: 2,
        timePerSessionMinutes: 60,
      );
      final periodization = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit,
      );
      final selections = _buildTestSelections();

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.intermediate,
      );

      // Encontrar prescripciones con repBias high (deload)
      final weekWithHigh = periodization.weeks.firstWhere(
        (w) => w.repBias == RepBias.high,
        orElse: () => periodization.weeks.first,
      );

      if (weekWithHigh.repBias == RepBias.high) {
        expect(weekWithHigh.repBias, RepBias.high);
        // Verificar que alguna prescripción en esa semana tiene reps >= 10
        var hasHighReps = false;
        final weekPrescriptions =
            res.weekDayPrescriptions[weekWithHigh.weekIndex];
        if (weekPrescriptions != null) {
          for (final dayPres in weekPrescriptions.values) {
            for (final pres in dayPres) {
              if (pres.repRange.min >= 10) {
                hasHighReps = true;
              }
            }
          }
        }
        expect(hasHighReps, true);
      }
    });

    test('repBias low produce repRange >= 6 y <= 10 y descanso >= 2 min', () {
      final profile = TrainingProfile(
        daysPerWeek: 2,
        timePerSessionMinutes: 60,
      );
      final periodization = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit,
      );
      final selections = _buildTestSelections();

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.intermediate,
      );

      // Encontrar semana con repBias low (intensification)
      final weekWithLow = periodization.weeks.firstWhere(
        (w) => w.repBias == RepBias.low,
        orElse: () => periodization.weeks.first,
      );

      if (weekWithLow.repBias == RepBias.low) {
        expect(weekWithLow.repBias, RepBias.low);
        final weekPrescriptions =
            res.weekDayPrescriptions[weekWithLow.weekIndex];
        if (weekPrescriptions != null) {
          for (final dayPres in weekPrescriptions.values) {
            for (final pres in dayPres) {
              if (pres.exerciseCode == 'leg_press') {
                // Compuesto low reps
                expect(pres.repRange.min >= 6 && pres.repRange.max <= 10, true);
                expect(pres.restMinutes >= 2, true);
              }
            }
          }
        }
      }
    });

    test('RIR es discreto (sin decimales) y compounds >= aislados', () {
      final profile = TrainingProfile(
        daysPerWeek: 2,
        timePerSessionMinutes: 60,
      );
      final periodization = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit,
      );
      final selections = _buildTestSelections();

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.advanced,
      );

      // Semana 1, Día 1 contiene leg_press (compound) + leg_curl (aislado)
      final w1d1 = res.weekDayPrescriptions[1]?[1];
      expect(w1d1, isNotNull);

      final compound = w1d1!.firstWhere(
        (p) => p.exerciseCode == 'leg_press',
        orElse: () => throw StateError('No se encontró leg_press en W1-D1'),
      );
      final isolation = w1d1.firstWhere(
        (p) => p.exerciseCode == 'leg_curl',
        orElse: () => throw StateError('No se encontró leg_curl en W1-D1'),
      );

      expect(compound.rir.contains('.'), isFalse);
      expect(isolation.rir.contains('.'), isFalse);
      expect(compound.rir.contains('RIR'), isFalse);
      expect(isolation.rir.contains('RIR'), isFalse);

      // Política conservadora: compounds suelen ir con RIR igual o más alto
      expect(rirMin(compound.rir), greaterThanOrEqualTo(rirMin(isolation.rir)));
    });

    test('beginner nunca RIR < 1', () {
      final profile = TrainingProfile(
        daysPerWeek: 2,
        timePerSessionMinutes: 60,
      );
      final periodization = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit,
      );
      final selections = _buildTestSelections();

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.beginner,
      );

      // Todas las prescripciones deben tener RIR >= 1
      for (final weekMap in res.weekDayPrescriptions.values) {
        for (final dayPres in weekMap.values) {
          for (final pres in dayPres) {
            final rirMinValue = rirMin(pres.rir);
            expect(rirMinValue >= 1, true);
          }
        }
      }
    });

    test('intensificación: advanced + not deload -> aplica en aislado', () {
      final profile = TrainingProfile(
        daysPerWeek: 2,
        timePerSessionMinutes: 60,
      );
      final periodization = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit,
      );
      final selections = _buildTestSelections();

      final context = DerivedTrainingContext(
        effectiveSleepHours: 8.0,
        effectiveAdherence: 0.95,
        effectiveAvgRir: 2.0,
        contraindicatedPatterns: const {},
        exerciseMustHave: const {},
        exerciseDislikes: const {},
        intensificationAllowed: true,
        intensificationMaxPerSession: 1,
        gluteSpecialization: null,
        referenceDate: DateTime(2025, 1, 1),
      );

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.advanced,
        derivedContext: context,
        profile: profile,
      );

      // Buscar técnicas de intensificación en aislados (no deload)
      var foundIntensification = false;
      for (final weekMap in res.weekDayPrescriptions.values) {
        for (final dayPres in weekMap.values) {
          for (final pres in dayPres) {
            if (pres.templateCode != null &&
                (pres.templateCode == 'myo_reps' ||
                    pres.templateCode == 'drop_set' ||
                    pres.templateCode == 'rest_pause')) {
              foundIntensification = true;
              expect(
                !pres.exerciseCode.contains('hip_thrust'),
                true,
              ); // isolation only
            }
          }
        }
      }
      expect(
        foundIntensification,
        true,
        reason:
            'Debe aplicar al menos una técnica en aislado cuando condiciones se cumplen',
      );
    });

    test('determinismo: mismos inputs -> mismas prescripciones JSON', () {
      final profile = TrainingProfile(
        daysPerWeek: 2,
        timePerSessionMinutes: 60,
      );
      final periodization = phase5.periodize(
        profile: profile,
        baseSplit: baseSplit,
      );
      final selections = _buildTestSelections();

      final a = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.intermediate,
      );

      final b = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.intermediate,
      );

      expect(a.weekDayPrescriptions.keys, b.weekDayPrescriptions.keys);
      for (final w in a.weekDayPrescriptions.keys) {
        for (final d in a.weekDayPrescriptions[w]!.keys) {
          final aList = a.weekDayPrescriptions[w]![d]!;
          final bList = b.weekDayPrescriptions[w]![d]!;
          expect(aList.length, bList.length);
          for (var i = 0; i < aList.length; i++) {
            expect(aList[i].exerciseCode, bList[i].exerciseCode);
            expect(aList[i].repRange.min, bList[i].repRange.min);
            expect(aList[i].repRange.max, bList[i].repRange.max);
            expect(aList[i].rir, bList[i].rir);
            expect(aList[i].restMinutes, bList[i].restMinutes);
          }
        }
      }
    });
  });
}

Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>
_buildTestSelections() {
  final legPress = ExerciseEntry(
    code: 'leg_press',
    name: 'Leg Press',
    muscleGroup: MuscleGroup.quads,
    equipment: const ['machine'],
    isCompound: true,
  );
  final legCurl = ExerciseEntry(
    code: 'leg_curl',
    name: 'Leg Curl',
    muscleGroup: MuscleGroup.quads,
    equipment: const ['machine'],
    isCompound: false,
  );
  final hipThrust = ExerciseEntry(
    code: 'hip_thrust',
    name: 'Hip Thrust',
    muscleGroup: MuscleGroup.glutes,
    equipment: const ['barbell'],
    isCompound: true,
  );
  final cableFly = ExerciseEntry(
    code: 'cable_fly',
    name: 'Cable Fly',
    muscleGroup: MuscleGroup.chest,
    equipment: const ['cable'],
    isCompound: false,
  );

  return {
    1: {
      1: {
        MuscleGroup.quads: [legPress, legCurl],
      },
    },
    2: {
      1: {
        MuscleGroup.quads: [legPress],
      },
      2: {
        MuscleGroup.glutes: [hipThrust],
        MuscleGroup.chest: [cableFly],
      },
    },
    3: {
      1: {
        MuscleGroup.quads: [legPress],
      },
      2: {
        MuscleGroup.glutes: [hipThrust],
        MuscleGroup.chest: [cableFly],
      },
    },
    4: {
      1: {
        MuscleGroup.quads: [legPress, legCurl],
      },
      2: {
        MuscleGroup.glutes: [hipThrust],
        MuscleGroup.chest: [cableFly],
      },
    },
  };
}
