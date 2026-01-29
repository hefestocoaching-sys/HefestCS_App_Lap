import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/effort_intent.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';

void main() {
  group('PR-10 Intensificación intermedia con guardrails', () {
    late Phase7PrescriptionService service;
    late SplitTemplate baseSplit;
    late Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>> selections;
    late Map<String, VolumeLimits> limits;

    setUp(() {
      service = Phase7PrescriptionService();
      baseSplit = SplitTemplate(
        splitId: 'test',
        daysPerWeek: 1,
        dayMuscles: {
          1: ['triceps'],
        },
        dailyVolume: {
          1: {'triceps': 6},
        },
      );
      selections = {
        1: {
          1: {
            MuscleGroup.triceps: [
              const ExerciseEntry(
                code: 'cable_pushdown',
                name: 'Cable Pushdown',
                muscleGroup: MuscleGroup.triceps,
                equipment: ['cable'],
                isCompound: false,
              ),
            ],
          },
        },
      };
      limits = {
        'triceps': const VolumeLimits(
          muscleGroup: 'triceps',
          mev: 6,
          mav: 10,
          mrv: 10,
          recommendedStartVolume: 8,
        ),
      };
    });

    PeriodizedWeek week({
      required TrainingPhase phase,
      required String fatigue,
      int sets = 6,
    }) {
      final intent = phase == TrainingPhase.deload
          ? EffortIntent.deload
          : (phase == TrainingPhase.intensification
                ? EffortIntent.push
                : EffortIntent.base);
      return PeriodizedWeek(
        weekIndex: 1,
        phase: phase,
        volumeFactor: 1.0,
        effortIntent: intent,
        repBias: RepBias.moderate,
        fatigueExpectation: fatigue,
        dailyVolume: {
          1: {'triceps': sets},
        },
      );
    }

    DerivedTrainingContext ctx({bool allow = true, int maxPerWeek = 2}) {
      return DerivedTrainingContext(
        effectiveSleepHours: 7.0,
        effectiveAdherence: 1.0,
        effectiveAvgRir: 2.5,
        contraindicatedPatterns: const {},
        exerciseMustHave: const {},
        exerciseDislikes: const {},
        intensificationAllowed: allow,
        intensificationMaxPerSession: maxPerWeek,
        gluteSpecialization: null,
        referenceDate: DateTime.utc(2025, 12, 20),
      );
    }

    test('Caso A: se aplica técnica y consume budget', () {
      final periodization = Phase5PeriodizationResult(
        weeks: [week(phase: TrainingPhase.intensification, fatigue: 'low')],
        decisions: const [],
      );

      final res = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.intermediate,
        derivedContext: ctx(),
        volumeLimitsByMuscle: limits,
        profile: const TrainingProfile(
          daysPerWeek: 1,
          timePerSessionMinutes: 50,
        ),
      );

      final all = res.weekDayPrescriptions.values
          .expand((d) => d.values)
          .expand((p) => p)
          .toList();

      expect(all.any((p) => p.templateCode != null), isTrue);
      expect(
        res.decisions.any((d) => d.category == 'intensification_applied'),
        isTrue,
      );
    });

    test('Caso B: se bloquea cuando falla alguna condición', () {
      final scenarios = <Map<String, dynamic>>[
        {
          'name': 'fatigue=high',
          'fatigue': 'high',
          'sets': 6,
          'allow': true,
          'phase': TrainingPhase.intensification,
          'reasonContains': 'fatigueExpectation=high',
        },
        {
          'name': 'sets>0.8*MRV',
          'fatigue': 'low',
          'sets': 9, // 0.9*MRV => bloquea
          'allow': true,
          'phase': TrainingPhase.intensification,
          'reasonContains': 'sets=9>0.8*MRV=8',
        },
        {
          'name': 'allowIntensification=false',
          'fatigue': 'low',
          'sets': 6,
          'allow': false,
          'phase': TrainingPhase.intensification,
          'reasonContains': 'allowIntensification=false',
        },
        {
          'name': 'deload',
          'fatigue': 'low',
          'sets': 6,
          'allow': true,
          'phase': TrainingPhase.deload,
          'reasonContains': 'phase=deload',
        },
        {
          'name': 'budget agotado',
          'fatigue': 'low',
          'sets': 6,
          'allow': true,
          'phase': TrainingPhase.intensification,
          'budgetZero': true,
          'reasonContains': 'effortBudget.canApply=false',
        },
      ];

      for (final sc in scenarios) {
        final periodization = Phase5PeriodizationResult(
          weeks: [
            week(
              phase: sc['phase'] as TrainingPhase,
              fatigue: sc['fatigue'] as String,
              sets: sc['sets'] as int,
            ),
          ],
          decisions: const [],
        );

        final res = service.buildPrescriptions(
          baseSplit: baseSplit,
          periodization: periodization,
          selections: selections,
          trainingLevel: TrainingLevel.intermediate,
          derivedContext: ctx(
            allow: sc['allow'] as bool,
            maxPerWeek: sc['budgetZero'] == true ? 0 : 2,
          ),
          volumeLimitsByMuscle: limits,
          profile: const TrainingProfile(
            daysPerWeek: 1,
            timePerSessionMinutes: 50,
          ),
        );

        final all = res.weekDayPrescriptions.values
            .expand((d) => d.values)
            .expand((p) => p)
            .toList();

        final hasTechnique = all.any((p) => p.templateCode != null);

        expect(hasTechnique, isFalse);

        final skippedDecision = res.decisions.any(
          (d) =>
              d.category == 'intensification_skipped_reason' &&
              ((d.context['reasons'] as List?)?.any(
                    (r) =>
                        (r as String).contains(sc['reasonContains'] as String),
                  ) ??
                  false),
        );

        expect(
          skippedDecision,
          isTrue,
          reason:
              'Esperaba skipped con razon=${sc['reasonContains']}, scenario=${sc['name']}',
        );
      }
    });
  });
}
