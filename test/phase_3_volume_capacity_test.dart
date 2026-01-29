import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/volume_tolerance_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_3_volume_capacity_model_service.dart';

void main() {
  group('Phase3VolumeCapacityModelService', () {
    late Phase3VolumeCapacityModelService service;

    setUp(() {
      service = Phase3VolumeCapacityModelService();
    });

    test('debe calcular límites MEV/MAV/MRV para nivel principiante', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.beginner,
        priorityMusclesPrimary: ['chest', 'back'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(result.volumeLimitsByMuscle, isNotEmpty);

      final chestLimits = result.volumeLimitsByMuscle['chest'];
      expect(chestLimits, isNotNull);
      expect(chestLimits!.mev, greaterThan(0));
      expect(chestLimits.mav, greaterThan(chestLimits.mev));
      expect(chestLimits.mrv, greaterThan(chestLimits.mav));

      // Principiantes: MRV máximo 16 sets/músculo
      expect(chestLimits.mrv, lessThanOrEqualTo(16));
    });

    test('debe calcular límites para nivel intermedio', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 75,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest', 'back', 'shoulders'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      final chestLimits = result.volumeLimitsByMuscle['chest'];
      expect(chestLimits, isNotNull);

      // Intermedios tienen MRV más alto que principiantes
      expect(chestLimits!.mrv, greaterThan(14));
      expect(chestLimits.mrv, lessThanOrEqualTo(22));
    });

    test('debe calcular límites para nivel avanzado', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        trainingLevel: TrainingLevel.advanced,
        priorityMusclesPrimary: ['chest', 'back', 'shoulders', 'quads'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      final chestLimits = result.volumeLimitsByMuscle['chest'];
      expect(chestLimits, isNotNull);

      // Avanzados tienen el MRV más alto
      expect(chestLimits!.mev, greaterThanOrEqualTo(10));
      expect(chestLimits.mrv, greaterThan(18));
    });

    test('debe aplicar +12.5% MRV para usuarios de farmacología', () {
      // Arrange
      final profileNatural = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        usesAnabolics: false,
        priorityMusclesPrimary: ['chest'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      final profileEnhanced = profileNatural.copyWith(
        usesAnabolics: true,
        pharmacologyProtocol: 'TRT',
      );

      // Act
      final resultNatural = service.calculateVolumeCapacity(
        profile: profileNatural,
        readinessAdjustment: 1.0,
      );

      final resultEnhanced = service.calculateVolumeCapacity(
        profile: profileEnhanced,
        readinessAdjustment: 1.0,
      );

      // Assert
      final mrvNatural = resultNatural.volumeLimitsByMuscle['chest']!.mrv;
      final mrvEnhanced = resultEnhanced.volumeLimitsByMuscle['chest']!.mrv;

      expect(mrvEnhanced, greaterThan(mrvNatural));

      // Verificar que el ajuste esté en el rango esperado (~12.5%)
      final adjustment = (mrvEnhanced - mrvNatural) / mrvNatural;
      expect(adjustment, greaterThan(0.10)); // Al menos 10%
      expect(adjustment, lessThan(0.20)); // No más de 20%
    });

    test('debe aplicar ajustes por edad correctamente', () {
      // Arrange: Persona joven
      final profileYoung = TrainingProfile(
        age: 22,
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Persona mayor
      final profileOlder = TrainingProfile(
        age: 52,
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final resultYoung = service.calculateVolumeCapacity(
        profile: profileYoung,
        readinessAdjustment: 1.0,
      );

      final resultOlder = service.calculateVolumeCapacity(
        profile: profileOlder,
        readinessAdjustment: 1.0,
      );

      // Assert: Persona mayor debe tener MRV ligeramente reducido
      final mrvYoung = resultYoung.volumeLimitsByMuscle['chest']!.mrv;
      final mrvOlder = resultOlder.volumeLimitsByMuscle['chest']!.mrv;

      expect(mrvOlder, lessThanOrEqualTo(mrvYoung));
    });

    test('debe inferir nivel de historial cuando no está especificado', () {
      // Arrange: Sin nivel especificado, pero con historial avanzado
      final profile = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        trainingLevel: null, // No especificado
        priorityMusclesPrimary: ['chest'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      final history = TrainingHistory(
        totalSessions: 250, // >= 200 → avanzado
        completedSessions: 240,
        averageAdherence: 0.96,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        history: history,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(result.metadata['effectiveTrainingLevel'], 'advanced');
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'level_determination' &&
              d.description.contains('inferido'),
        ),
        true,
      );
    });

    test('debe asumir principiante cuando no hay nivel ni historial', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 45,
        trainingLevel: null,
        priorityMusclesPrimary: ['chest'],
        globalGoal: TrainingGoal.generalFitness,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(result.metadata['effectiveTrainingLevel'], 'beginner');

      // MRV debe estar limitado para principiantes
      final chestLimits = result.volumeLimitsByMuscle['chest']!;
      expect(chestLimits.mrv, lessThanOrEqualTo(16));
    });

    test('debe ajustar volumen recomendado según readiness', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act con readiness bajo
      final resultLowReadiness = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 0.7, // Readiness bajo
      );

      // Act con readiness alto
      final resultHighReadiness = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.1, // Readiness alto
      );

      // Assert
      final volumeLow = resultLowReadiness
          .volumeLimitsByMuscle['chest']!
          .recommendedStartVolume;
      final volumeHigh = resultHighReadiness
          .volumeLimitsByMuscle['chest']!
          .recommendedStartVolume;

      expect(volumeLow, lessThan(volumeHigh));
    });

    test('debe clampar volumen recomendado entre MEV y MAV', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest', 'back'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act con readiness extremadamente bajo
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 0.5,
      );

      // Assert
      for (final limits in result.volumeLimitsByMuscle.values) {
        expect(limits.recommendedStartVolume, greaterThanOrEqualTo(limits.mev));
        expect(limits.recommendedStartVolume, lessThanOrEqualTo(limits.mav));
      }
    });

    test('debe calcular límites para diferentes grupos musculares', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: [
          'chest',
          'back',
          'shoulders',
          'quads',
          'hamstrings',
          'biceps',
          'triceps',
        ],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(result.volumeLimitsByMuscle.length, 7);

      // Verificar que cada músculo tenga límites válidos
      for (final entry in result.volumeLimitsByMuscle.entries) {
        final muscle = entry.key;
        final limits = entry.value;

        expect(limits.muscleGroup, muscle);
        expect(limits.mev, greaterThan(0));
        expect(limits.mav, greaterThan(limits.mev));
        expect(limits.mrv, greaterThan(limits.mav));
        expect(limits.recommendedStartVolume, greaterThanOrEqualTo(limits.mev));
        expect(limits.recommendedStartVolume, lessThanOrEqualTo(limits.mav));
      }
    });

    test('debe usar grupos musculares estándar cuando no hay prioridades', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: [], // Sin prioridades
        globalGoal: TrainingGoal.generalFitness,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(result.volumeLimitsByMuscle, isNotEmpty);
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'muscle_selection' &&
              d.description.contains('grupos musculares estándar'),
        ),
        true,
      );
    });

    test('debe advertir cuando volumen total excede tiempo disponible', () {
      // Arrange: Poco tiempo, muchos músculos
      final profile = TrainingProfile(
        daysPerWeek: 2, // Solo 2 días
        timePerSessionMinutes: 30, // Solo 30 min (60 min/semana)
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: [
          'chest',
          'back',
          'shoulders',
          'quads',
          'hamstrings',
        ],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(
        result.decisions.any((d) => d.category == 'time_constraint'),
        true,
      );
    });

    test('debe garantizar que MRV nunca se exceda', () {
      // Arrange: Múltiples factores de ajuste
      final profile = TrainingProfile(
        age: 20,
        daysPerWeek: 5,
        timePerSessionMinutes: 120,
        trainingLevel: TrainingLevel.advanced,
        usesAnabolics: true,
        priorityMusclesPrimary: ['chest', 'back', 'quads'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act con readiness muy alto
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.15, // Máximo readiness
      );

      // Assert
      for (final limits in result.volumeLimitsByMuscle.values) {
        // Volumen recomendado NUNCA debe exceder MRV
        expect(limits.recommendedStartVolume, lessThanOrEqualTo(limits.mrv));

        // MRV debe ser el límite absoluto
        expect(limits.isVolumeSafe(limits.mrv), true);
        expect(limits.isVolumeSafe(limits.mrv + 1), false);
      }
    });

    test(
      'debe aplicar límite de 16 sets para principiantes sin importar ajustes',
      () {
        // Arrange: Principiante con farmacología (intento de aumentar MRV)
        final profile = TrainingProfile(
          age: 25,
          daysPerWeek: 5,
          timePerSessionMinutes: 90,
          trainingLevel: TrainingLevel.beginner,
          usesAnabolics: true, // Intentar aumentar MRV
          priorityMusclesPrimary: ['chest'],
          globalGoal: TrainingGoal.hypertrophy,
        );

        // Act
        final result = service.calculateVolumeCapacity(
          profile: profile,
          readinessAdjustment: 1.15, // Readiness excelente
        );

        // Assert: REGLA ABSOLUTA para principiantes
        final chestLimits = result.volumeLimitsByMuscle['chest']!;
        expect(
          chestLimits.mrv,
          lessThanOrEqualTo(16),
          reason: 'MRV para principiantes NUNCA debe exceder 16 sets/semana',
        );
      },
    );

    test('debe calcular volumen total correctamente', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest', 'back', 'shoulders'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      final totalMEV = result.getTotalMEV();
      final totalMAV = result.getTotalMAV();
      final totalMRV = result.getTotalMRV();
      final totalRecommended = result.getTotalRecommendedVolume();

      expect(totalMEV, greaterThan(0));
      expect(totalMAV, greaterThan(totalMEV));
      expect(totalMRV, greaterThan(totalMAV));
      expect(totalRecommended, greaterThanOrEqualTo(totalMEV));
      expect(totalRecommended, lessThanOrEqualTo(totalMAV));
    });

    test('debe registrar todas las decisiones con contexto completo', () {
      // Arrange
      final profile = TrainingProfile(
        age: 30,
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        usesAnabolics: false,
        priorityMusclesPrimary: ['chest', 'back'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 0.95,
      );

      // Assert
      expect(result.decisions, isNotEmpty);
      expect(
        result.decisions.where((d) => d.phase == 'Phase3VolumeCapacity'),
        hasLength(result.decisions.length),
      );
      expect(
        result.decisions.any((d) => d.category == 'level_determination'),
        true,
      );
      expect(result.decisions.any((d) => d.category == 'pharmacology'), true);
      expect(
        result.decisions.any((d) => d.category == 'muscle_selection'),
        true,
      );
      expect(result.decisions.any((d) => d.category == 'final_envelope'), true);
      expect(result.decisions.any((d) => d.category == 'final_result'), true);
    });

    test('debe incluir reasoning en cada VolumeLimits', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['chest', 'back'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 0.9,
      );

      // Assert
      for (final limits in result.volumeLimitsByMuscle.values) {
        expect(limits.reasoning, isNotEmpty);
        expect(limits.reasoning, contains('Source:'));
      }
    });

    test('debe manejar nombres de músculos en español e inglés', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: [
          'pecho', // Español
          'espalda', // Español
          'shoulders', // Inglés
        ],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      expect(result.volumeLimitsByMuscle['pecho'], isNotNull);
      expect(result.volumeLimitsByMuscle['espalda'], isNotNull);
      expect(result.volumeLimitsByMuscle['shoulders'], isNotNull);
    });

    test('debe usar valores conservadores para músculos no reconocidos', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.intermediate,
        priorityMusclesPrimary: ['muscle_unknown_xyz'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: 1.0,
      );

      // Assert
      final unknownLimits = result.volumeLimitsByMuscle['muscle_unknown_xyz'];
      expect(unknownLimits, isNotNull);

      // Debe usar valores genéricos conservadores
      expect(unknownLimits!.mev, greaterThan(0));
      expect(unknownLimits.mrv, lessThanOrEqualTo(20)); // Conservador
    });

    test(
      'pastVolumeTolerance debe afectar MRV para músculo si existe histórico',
      () {
        // Arrange
        // import 'package:hcs_app_lap/domain/entities/volume_tolerance_profile.dart';

        final profile = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 75,
          trainingLevel: TrainingLevel.intermediate,
          priorityMusclesPrimary: ['chest'],
          globalGoal: TrainingGoal.hypertrophy,
          pastVolumeTolerance: {
            'chest': VolumeToleranceProfile(tolerance: 1.2), // +20% MRV
          },
        );

        // Act
        final result = service.calculateVolumeCapacity(
          profile: profile,
          readinessAdjustment: 1.0,
        );

        // Assert
        final chestWithTolerance = result.volumeLimitsByMuscle['chest'];
        expect(chestWithTolerance, isNotNull);

        // Sin tolerancia histórica, intermediate chest MRV ≈ 18
        // Con +20% tolerancia: 18 * 1.2 ≈ 21.6 → 22
        // Verificar que se aplicó ajuste
        expect(
          chestWithTolerance!.mrv,
          greaterThan(18),
          reason: 'MRV debe ser mayor con tolerancia histórica positiva',
        );

        // Verificar que DecisionTrace registró la tolerancia
        expect(
          result.decisions.any(
            (d) =>
                d.category == 'base_volume_source' &&
                d.context['source'] == 'historical' &&
                d.context['muscle'] == 'chest',
          ),
          true,
          reason:
              'DecisionTrace debe registrar aplicación de pastVolumeTolerance',
        );
      },
    );

    test(
      'female debe tener MRV más alto en glutes que male (mismo perfil)',
      () {
        // Arrange
        final profileFemale = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 75,
          trainingLevel: TrainingLevel.intermediate,
          gender: Gender.female,
          priorityMusclesPrimary: ['glutes', 'quads'],
          globalGoal: TrainingGoal.hypertrophy,
        );

        final profileMale = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 75,
          trainingLevel: TrainingLevel.intermediate,
          gender: Gender.male,
          priorityMusclesPrimary: ['glutes', 'quads'],
          globalGoal: TrainingGoal.hypertrophy,
        );

        // Act
        final resultFemale = service.calculateVolumeCapacity(
          profile: profileFemale,
          readinessAdjustment: 1.0,
        );

        final resultMale = service.calculateVolumeCapacity(
          profile: profileMale,
          readinessAdjustment: 1.0,
        );

        // Assert
        final glutesFemale = resultFemale.volumeLimitsByMuscle['glutes'];
        final glutesMale = resultMale.volumeLimitsByMuscle['glutes'];

        expect(glutesFemale, isNotNull);
        expect(glutesMale, isNotNull);

        // Female glutes MRV debe ser +20% mayor que male
        expect(
          glutesFemale!.mrv,
          greaterThan(glutesMale!.mrv),
          reason: 'Female debe tener MRV mayor en glutes que male',
        );

        // Verificar que DecisionTrace registró ajuste de género
        expect(
          resultFemale.decisions.any(
            (d) =>
                d.category == 'gender_factor_applied' &&
                d.context['muscle'] == 'glutes',
          ),
          true,
          reason: 'DecisionTrace debe registrar ajuste específico para mujer',
        );
      },
    );
  });
}
