import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/effort_intent.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';

void main() {
  group('Phase5 periodization intent & bias', () {
    late Phase5PeriodizationService service;

    setUp(() {
      service = Phase5PeriodizationService();
    });

    SplitTemplate baseSplit() {
      final dayMuscles = {
        1: ['chest'],
        2: ['back'],
        3: ['legs'],
        4: ['chest'],
      };
      final dailyVolume = {
        1: {'chest': 6},
        2: {'back': 6},
        3: {'legs': 6},
        4: {'chest': 6},
      };
      return SplitTemplate(
        splitId: 'test',
        daysPerWeek: 4,
        dayMuscles: dayMuscles,
        dailyVolume: dailyVolume,
      );
    }

    test('Semana 3 intensification usa intent=push (no beginner)', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
      );
      final res = service.periodize(profile: profile, baseSplit: baseSplit());
      expect(res.weeks.length, 4);
      expect(res.weeks[2].effortIntent, EffortIntent.push);
      expect(res.weeks[0].effortIntent, isNot(EffortIntent.push));
      expect(res.weeks[2].phase, TrainingPhase.intensification);
    });

    test('Deload tiene intent=deload y volumeFactor 40-60%', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
      );
      final res = service.periodize(profile: profile, baseSplit: baseSplit());
      final deload = res.weeks[3];
      expect(deload.phase, TrainingPhase.deload);
      expect(deload.effortIntent, EffortIntent.deload);
      expect(deload.volumeFactor >= 0.4 && deload.volumeFactor <= 0.6, true);
    });

    test('Beginner nunca recibe intent=push en intensification', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.beginner,
      );
      final res = service.periodize(profile: profile, baseSplit: baseSplit());
      final intens = res.weeks[2];
      expect(intens.phase, TrainingPhase.intensification);
      expect(intens.effortIntent, isNot(EffortIntent.push));
    });

    test('Determinismo absoluto: mismo input mismo JSON', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
      );
      final a = service.periodize(profile: profile, baseSplit: baseSplit());
      final b = service.periodize(profile: profile, baseSplit: baseSplit());
      expect(a.weeks.length, b.weeks.length);
      for (var i = 0; i < a.weeks.length; i++) {
        expect(a.weeks[i].phase, b.weeks[i].phase);
        expect(a.weeks[i].volumeFactor, b.weeks[i].volumeFactor);
        expect(a.weeks[i].effortIntent, b.weeks[i].effortIntent);
        expect(a.weeks[i].repBias, b.weeks[i].repBias);
        expect(a.weeks[i].fatigueExpectation, b.weeks[i].fatigueExpectation);
        expect(a.weeks[i].dailyVolume, b.weeks[i].dailyVolume);
      }
    });

    test('DecisionTrace contiene 4 semanas con campos completos', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
      );
      final res = service.periodize(profile: profile, baseSplit: baseSplit());
      final weekLogs = res.decisions
          .where((d) => d.category == 'week_plan')
          .toList();
      expect(weekLogs.length, 4);
      for (final d in weekLogs) {
        expect(d.context.containsKey('effortIntent'), true);
        expect(d.context.containsKey('repBias'), true);
        expect(d.context.containsKey('fatigueExpectation'), true);
        expect(d.context.containsKey('factor'), true);
      }
    });
  });
}
