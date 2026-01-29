import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/services/phase_4_split_distribution_service.dart';

void main() {
  group('Phase4 frequency & recovery', () {
    late Phase4SplitDistributionService service;

    setUp(() {
      service = Phase4SplitDistributionService();
    });

    Map<String, VolumeLimits> baseLimits() => {
      'glutes': VolumeLimits(
        muscleGroup: 'glutes',
        mev: 8,
        mav: 14,
        mrv: 20,
        recommendedStartVolume: 12,
      ),
      'chest': VolumeLimits(
        muscleGroup: 'chest',
        mev: 8,
        mav: 14,
        mrv: 18,
        recommendedStartVolume: 12,
      ),
    };

    test(
      'Glúteo prioritario aparece ≥2 veces/semana y heavy no consecutivo',
      () {
        final profile = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 60,
          globalGoal: TrainingGoal.hypertrophy,
          trainingLevel: TrainingLevel.intermediate,
          priorityMusclesPrimary: const ['glutes', 'chest'],
        );

        final res = service.buildWeeklySplit(
          profile: profile,
          volumeByMuscle: baseLimits(),
        );

        final gluteDays =
            res.split.dayMuscles.entries
                .where((e) => e.value.contains('glutes'))
                .map((e) => e.key)
                .toList()
              ..sort();

        expect(gluteDays.length >= 2, true);

        // Heavy no consecutivo (indirecto): sets muy altos no aparecen seguidos
        final gluteSets = res.split.dailyVolume.entries
            .map((e) => e.value['glutes'] ?? 0)
            .toList();

        var adjacentHeavy = false;
        for (var i = 1; i < gluteSets.length; i++) {
          if (gluteSets[i] >= (12 * 0.4).round() &&
              gluteSets[i - 1] >= (12 * 0.4).round()) {
            adjacentHeavy = true;
            break;
          }
        }
        expect(adjacentHeavy, false);
      },
    );

    test('No prioritario se reduce antes que prioritario por tiempo', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 20, // Fuerza reducción
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: const ['glutes'],
      );

      final limits = baseLimits();
      // objetivo alto para exceder tiempo
      limits['glutes'] = limits['glutes']!.copyWith(recommendedStartVolume: 14);
      limits['chest'] = limits['chest']!.copyWith(recommendedStartVolume: 14);

      final res = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: limits,
      );

      // Comparar sets en su respectivo día: chest vs glutes
      final dayChest = res.split.dayMuscles.entries
          .firstWhere((e) => e.value.contains('chest'))
          .key;
      final dayGlute = res.split.dayMuscles.entries
          .firstWhere((e) => e.value.contains('glutes'))
          .key;
      final chestSets = res.split.dailyVolume[dayChest]!['chest'] ?? 0;
      final gluteSets = res.split.dailyVolume[dayGlute]!['glutes'] ?? 0;

      // Debe haber menos sets en 'chest' que en 'glutes' tras ajuste
      expect(chestSets <= gluteSets, true);
    });

    test('MEV nunca se viola tras escalado por tiempo', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 16,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.beginner,
        priorityMusclesPrimary: const ['glutes'],
      );

      final limits = baseLimits();
      final res = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: limits,
      );

      // Revisar días con glúteo y validar que no cae por debajo de MEV/día
      final assignedDays = res.split.dailyVolume.entries
          .where((e) => (e.value['glutes'] ?? 0) > 0)
          .length;
      final perDayMin =
          (limits['glutes']!.mev / (assignedDays == 0 ? 1 : assignedDays))
              .ceil();
      for (final day in res.split.dailyVolume.keys) {
        final sets = res.split.dailyVolume[day]!['glutes'] ?? 0;
        if (sets > 0) {
          expect(sets >= perDayMin, true);
        }
      }
    });

    test('Determinismo: mismo input produce misma distribución', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: const ['glutes', 'chest'],
      );

      final a = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: baseLimits(),
      );
      final b = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: baseLimits(),
      );

      expect(a.split.dayMuscles, b.split.dayMuscles);
      expect(a.split.dailyVolume, b.split.dailyVolume);
    });
  });
}
