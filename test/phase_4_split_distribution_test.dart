import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/services/phase_4_split_distribution_service.dart';

void main() {
  group('Phase4SplitDistributionService', () {
    late Phase4SplitDistributionService service;

    setUp(() {
      service = Phase4SplitDistributionService();
    });

    Map<String, VolumeLimits> basicLimits() {
      return {
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
        'glutes': VolumeLimits(
          muscleGroup: 'glutes',
          mev: 4,
          mav: 10,
          mrv: 14,
          recommendedStartVolume: 6,
        ),
        'calves': VolumeLimits(
          muscleGroup: 'calves',
          mev: 6,
          mav: 10,
          mrv: 14,
          recommendedStartVolume: 8,
        ),
        'abs': VolumeLimits(
          muscleGroup: 'abs',
          mev: 0,
          mav: 8,
          mrv: 12,
          recommendedStartVolume: 6,
        ),
        'core': VolumeLimits(
          muscleGroup: 'core',
          mev: 0,
          mav: 8,
          mrv: 12,
          recommendedStartVolume: 6,
        ),
      };
    }

    test('daysPerWeek=3 → split full body', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
      );
      final res = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: basicLimits(),
      );
      expect(res.split.splitId, 'fullbody_3d');
      expect(res.split.daysPerWeek, 3);
    });

    test('daysPerWeek=4 → upper/lower', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
      );
      final res = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: basicLimits(),
      );
      expect(res.split.splitId, 'upper_lower_4d');
      expect(res.split.dayMuscles.length, 4);
    });

    test('daysPerWeek=5–6 → PPL', () {
      final profile5 = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 60,
      );
      final res5 = service.buildWeeklySplit(
        profile: profile5,
        volumeByMuscle: basicLimits(),
      );
      expect(res5.split.splitId, 'ppl_5d');

      final profile6 = TrainingProfile(
        daysPerWeek: 6,
        timePerSessionMinutes: 60,
      );
      final res6 = service.buildWeeklySplit(
        profile: profile6,
        volumeByMuscle: basicLimits(),
      );
      expect(res6.split.splitId, 'ppl_6d');
    });

    test('respeta tiempo por sesión (escalado si necesario)', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 30,
      ); // 30 min
      final res = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: basicLimits(),
      );

      // Día 1: sets totales * 4 min <= 30 min
      final day1Sets = res.split.dailyVolume[1]!.values.fold<int>(
        0,
        (s, v) => s + v,
      );
      expect(day1Sets * 4, lessThanOrEqualTo(profile.timePerSessionMinutes));
    });

    test('determinismo: mismos inputs → mismo output', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
      );
      final limits = basicLimits();
      final a = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: limits,
      );
      final b = service.buildWeeklySplit(
        profile: profile,
        volumeByMuscle: limits,
      );

      expect(a.split.toJson(), equals(b.split.toJson()));
    });
  });
}
