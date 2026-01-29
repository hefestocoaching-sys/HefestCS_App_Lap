import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';

void main() {
  group('Phase5PeriodizationService', () {
    late Phase5PeriodizationService service;

    setUp(() {
      service = Phase5PeriodizationService();
    });

    SplitTemplate sampleSplit({int days = 4}) {
      // Split simple determinístico con volumen constante
      final dayMuscles = <int, List<String>>{};
      final dailyVolume = <int, Map<String, int>>{};
      for (var d = 1; d <= days; d++) {
        dayMuscles[d] = ['chest', 'back', 'quads'];
        dailyVolume[d] = {'chest': 4, 'back': 4, 'quads': 4};
      }
      return SplitTemplate(
        splitId: days == 3
            ? 'fullbody_3d'
            : days == 4
            ? 'upper_lower_4d'
            : 'ppl_${days}d',
        daysPerWeek: days,
        dayMuscles: dayMuscles,
        dailyVolume: dailyVolume,
      );
    }

    int weeklySetsTotal(SplitTemplate split) {
      var total = 0;
      for (final day in split.dailyVolume.values) {
        total += day.values.fold<int>(0, (s, v) => s + v);
      }
      return total;
    }

    test('deload cada 3–4 semanas y reducción 40–60%', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        blockLengthWeeks: 4,
      );
      final baseSplit = sampleSplit(days: 4);

      final res = service.periodize(profile: profile, baseSplit: baseSplit);

      expect(res.weeks.length, 4);
      expect(res.weeks[0].phase, TrainingPhase.accumulation);
      expect(res.weeks[1].phase, TrainingPhase.accumulation);
      expect(res.weeks[2].phase, TrainingPhase.intensification);
      expect(res.weeks[3].phase, TrainingPhase.deload);

      // Volumen total por semana
      final baseTotal = weeklySetsTotal(baseSplit);
      final deloadTotal = res.weeks[3].dailyVolume.values.fold<int>(
        0,
        (s, m) => s + m.values.fold<int>(0, (ss, v) => ss + v),
      );

      final reduction = 1.0 - (deloadTotal / baseTotal);
      expect(reduction, greaterThanOrEqualTo(0.40));
      expect(reduction, lessThanOrEqualTo(0.60));
    });

    test('determinismo: mismos inputs → mismo output', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        blockLengthWeeks: 8,
      );
      final baseSplit = sampleSplit(days: 3);

      final a = service.periodize(profile: profile, baseSplit: baseSplit);
      final b = service.periodize(profile: profile, baseSplit: baseSplit);

      expect(a.weeks.length, b.weeks.length);
      for (var i = 0; i < a.weeks.length; i++) {
        expect(a.weeks[i].phase, b.weeks[i].phase);
        expect(a.weeks[i].volumeFactor, b.weeks[i].volumeFactor);
        expect(a.weeks[i].dailyVolume, b.weeks[i].dailyVolume);
      }
    });

    test(
      'week factors explícitos: [0.95, 1.00, 0.90, 0.50] dentro de ciclo de 4 semanas',
      () {
        final profile = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 60,
          blockLengthWeeks: 4,
        );
        final baseSplit = sampleSplit(days: 4);

        final res = service.periodize(profile: profile, baseSplit: baseSplit);

        expect(res.weeks.length, 4);

        // Verificar week factors según el patrón: [0.95, 1.00, 0.90, 0.50]
        // Semana 0: accumulation, factor 0.95
        expect(res.weeks[0].volumeFactor, 0.95);
        expect(res.weeks[0].phase, TrainingPhase.accumulation);

        // Semana 1: accumulation, factor 1.00
        expect(res.weeks[1].volumeFactor, 1.00);
        expect(res.weeks[1].phase, TrainingPhase.accumulation);

        // Semana 2: intensification, factor 0.90
        expect(res.weeks[2].volumeFactor, 0.90);
        expect(res.weeks[2].phase, TrainingPhase.intensification);

        // Semana 3: deload, factor 0.50
        expect(res.weeks[3].volumeFactor, 0.50);
        expect(res.weeks[3].phase, TrainingPhase.deload);

        // Verificar que los volumes están correctos en cada semana
        final baseTotal = weeklySetsTotal(baseSplit);

        final week0Total = res.weeks[0].dailyVolume.values.fold<int>(
          0,
          (s, m) => s + m.values.fold<int>(0, (ss, v) => ss + v),
        );
        expect(week0Total, (baseTotal * 0.95).round());

        final week3Total = res.weeks[3].dailyVolume.values.fold<int>(
          0,
          (s, m) => s + m.values.fold<int>(0, (ss, v) => ss + v),
        );
        expect(week3Total, (baseTotal * 0.50).round());
      },
    );
  });
}
