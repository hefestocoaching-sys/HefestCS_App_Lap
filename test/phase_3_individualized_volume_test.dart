import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/volume_tolerance_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart';
import 'package:hcs_app_lap/domain/services/phase_3_volume_capacity_model_service.dart';

void main() {
  group('Phase3 individualized volume', () {
    late Phase3VolumeCapacityModelService service;

    setUp(() {
      service = Phase3VolumeCapacityModelService();
    });

    test('mujer vs hombre: glúteo tiene mayor volumen en mujer', () {
      final male = TrainingProfile(
        gender: Gender.male,
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['glutes', 'quads'],
      );

      final female = male.copyWith(gender: Gender.female);

      final resultMale = service.calculateVolumeCapacity(
        profile: male,
        readinessAdjustment: 1.0,
      );

      final resultFemale = service.calculateVolumeCapacity(
        profile: female,
        readinessAdjustment: 1.0,
      );

      final gluteMRVMale = resultMale.volumeLimitsByMuscle['glutes']?.mrv ?? 0;
      final gluteMRVFemale =
          resultFemale.volumeLimitsByMuscle['glutes']?.mrv ?? 0;

      // Mujer debe tener MRV superior en glúteos (+15-25%)
      expect(
        gluteMRVFemale > gluteMRVMale,
        true,
        reason: 'MRV glúteo mujer debe ser > que hombre',
      );
      expect(
        resultFemale.decisions.any(
          (d) => d.category == 'gender_factor_applied',
        ),
        true,
      );
    });

    test('tolerancia histórica > tabla: se respeta historial', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest'],
        pastVolumeTolerance: {
          'chest': VolumeToleranceProfile(tolerance: 1.3), // +30% sobre tabla
        },
      );

      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      final chestLimits = result.volumeLimitsByMuscle['chest']!;
      // Con tolerancia 1.3x, el volumen debería ser notablemente superior a tabla base
      expect(
        chestLimits.mrv >= 18,
        true,
        reason: 'Historial debe aumentar MRV respecto a tabla base',
      );
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'base_volume_source' &&
              d.context['source'] == 'historical',
        ),
        true,
      );
    });

    test('readiness local low en glúteo reduce solo glúteo, no todo', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['glutes', 'chest'],
      );

      final readinessByMuscle = {
        MuscleGroup.glutes: ReadinessLevel.low, // Lesión local
        MuscleGroup.chest: ReadinessLevel.good, // Normal
      };

      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
        readinessByMuscle: readinessByMuscle,
      );

      final gluteVol =
          result.volumeLimitsByMuscle['glutes']!.recommendedStartVolume;
      final chestVol =
          result.volumeLimitsByMuscle['chest']!.recommendedStartVolume;

      // Glúteo debe tener volumen reducido, pecho normal
      expect(
        gluteVol < chestVol,
        true,
        reason:
            'Glúteo con readiness low debe tener menor volumen que pecho good',
      );
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'readiness_local_adjustment' &&
              d.context['muscle'] == 'glutes',
        ),
        true,
      );
    });

    test('beginner nunca excede 16 sets (guardrail absoluto)', () {
      final profile = TrainingProfile(
        gender: Gender.female, // Con boost por sexo
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.beginner,
        priorityMusclesPrimary: ['glutes'],
        usesAnabolics: true, // Con boost farmacológico
        pastVolumeTolerance: {
          'glutes': VolumeToleranceProfile(tolerance: 1.5), // +50% historial
        },
      );

      final readinessByMuscle = {
        MuscleGroup.glutes: ReadinessLevel.excellent, // Máximo readiness
      };

      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.15, // Máximo readiness global
        readinessByMuscle: readinessByMuscle,
      );

      final gluteMRV = result.volumeLimitsByMuscle['glutes']!.mrv;

      // A pesar de todos los boosts, beginner NUNCA > 16
      expect(gluteMRV <= 16, true, reason: 'Beginner MRV NUNCA > 16 sets');
    });

    test('determinismo: mismos inputs generan mismos volúmenes', () {
      final profile = TrainingProfile(
        gender: Gender.female,
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['glutes', 'quads'],
        age: 28,
        avgSleepHours: 7.5,
      );

      final readinessByMuscle = {
        MuscleGroup.glutes: ReadinessLevel.good,
        MuscleGroup.quads: ReadinessLevel.moderate,
      };

      final a = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
        readinessByMuscle: readinessByMuscle,
      );

      final b = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
        readinessByMuscle: readinessByMuscle,
      );

      expect(
        a.volumeLimitsByMuscle['glutes']!.mrv,
        b.volumeLimitsByMuscle['glutes']!.mrv,
      );
      expect(
        a.volumeLimitsByMuscle['glutes']!.recommendedStartVolume,
        b.volumeLimitsByMuscle['glutes']!.recommendedStartVolume,
      );
      expect(
        a.volumeLimitsByMuscle['quads']!.mrv,
        b.volumeLimitsByMuscle['quads']!.mrv,
      );
    });
  });
}
