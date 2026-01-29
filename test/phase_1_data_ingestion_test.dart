import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';

void main() {
  group('Phase1DataIngestionService', () {
    late Phase1DataIngestionService service;

    setUp(() {
      service = Phase1DataIngestionService();
    });

    test('debe validar un perfil completo correctamente', () {
      // Arrange
      final profile = TrainingProfile(
        id: 'test-1',
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        trainingLevel: TrainingLevel.intermediate,
        avgSleepHours: 7.5,
        priorityMusclesPrimary: ['chest', 'back'],
        priorityMusclesSecondary: ['shoulders'],
        baseVolumePerMuscle: {'chest': 12, 'back': 14},
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.isValid, true);
      expect(result.missingData, isEmpty);
      expect(result.decisions, isNotEmpty);
      expect(result.decisions.where((d) => d.severity == 'critical'), isEmpty);
    });

    test('debe detectar perfil inválido (sin días por semana)', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 0,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.generalFitness,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.isValid, false);
      expect(
        result.missingData,
        contains('daysPerWeek o timePerSessionMinutes'),
      );
      expect(result.decisions.any((d) => d.severity == 'critical'), true);
    });

    test('debe advertir cuando falta nivel de entrenamiento', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 45,
        globalGoal: TrainingGoal.strength,
        trainingLevel: null, // Faltante
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(
        result.warnings,
        contains('Nivel de entrenamiento no especificado'),
      );
      expect(result.missingData, contains('trainingLevel'));
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'missing_data' &&
              d.description.contains('Nivel de entrenamiento'),
        ),
        true,
      );
    });

    test('debe advertir cuando el sueño es insuficiente', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 5.5, // < 6h
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.warnings, contains('Sueño insuficiente'));
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'recovery_concern' &&
              d.description.contains('Sueño insuficiente'),
        ),
        true,
      );
    });

    test('debe advertir cuando DOMS es muy alto', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 75,
        sorenessLevel: 8.5, // > 7.0
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.warnings, contains('DOMS alto'));
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'recovery_concern' &&
              d.description.contains('dolor muscular alto'),
        ),
        true,
      );
    });

    test('debe advertir cuando la motivación es baja', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 45,
        motivationLevel: 3.5, // < 5.0
        globalGoal: TrainingGoal.generalFitness,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.warnings, contains('Motivación baja'));
    });

    test('debe procesar historial cuando está disponible', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final history = TrainingHistory(
        totalSessions: 50,
        completedSessions: 45,
        averageAdherence: 0.9,
        averageRpe: 7.5,
      );

      // Act
      final result = service.ingestAndValidate(
        profile: profile,
        history: history,
      );

      // Assert
      expect(result.hasHistory, true);
      expect(
        result.decisions.any((d) => d.category == 'history_analysis'),
        true,
      );
    });

    test('debe advertir cuando adherencia histórica es baja', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final history = TrainingHistory(
        totalSessions: 30,
        completedSessions: 18,
        averageAdherence: 0.6, // < 0.7
      );

      // Act
      final result = service.ingestAndValidate(
        profile: profile,
        history: history,
      );

      // Assert
      expect(result.warnings, contains('Adherencia histórica baja'));
      expect(result.decisions.any((d) => d.category == 'adherence_low'), true);
    });

    test('debe procesar feedback reciente cuando está disponible', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 5.0,
        soreness: 4.5,
        motivation: 8.0,
        adherence: 0.95,
        avgRir: 2.5,
        sleepHours: 8.0,
        stressLevel: 4.0,
      );

      // Act
      final result = service.ingestAndValidate(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.hasFeedback, true);
      expect(
        result.decisions.any((d) => d.category == 'feedback_analysis'),
        true,
      );
    });

    test('debe detectar uso de farmacología', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        usesAnabolics: true,
        pharmacologyProtocol: 'TRT 200mg/week',
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'pharmacology' &&
              d.description.contains('farmacología anabólica'),
        ),
        true,
      );
    });

    test('entrevista con lesiones severas agrega patrones contraindicados', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        extra: {
          TrainingExtraKeys.injuries: [
            {'pattern': 'shoulder_press', 'severity': 3},
          ],
        },
      );

      final result = service.ingestAndValidate(profile: profile);

      expect(
        result.derivedContext.contraindicatedPatterns,
        contains('shoulder_press'),
      );
      expect(
        result.decisions.any((d) => d.category == 'injury_constraints'),
        true,
      );
    });

    test('gluteSpecializationProfile materializa contexto', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        extra: {
          TrainingExtraKeys.gluteSpecializationProfile: {
            'targetFrequencyPerWeek': 3,
            'minSetsPerWeek': 12,
            'maxSetsPerWeek': 18,
          },
        },
      );

      final result = service.ingestAndValidate(profile: profile);

      final ctx = result.derivedContext.gluteSpecialization;
      expect(ctx, isNotNull);
      expect(ctx!.targetFrequencyPerWeek, 3);
      expect(ctx.minSetsPerWeek, 12);
      expect(ctx.maxSetsPerWeek, 18);
      expect(
        result.decisions.any(
          (d) => d.category == 'glute_specialization_detected',
        ),
        true,
      );
    });

    test('sin historial pero con logs deriva adherencia', () {
      final logs = [
        {
          'dateIso': '2025-12-01',
          'sessionName': 'A',
          'entries': const [],
          'createdAtIso': '2025-12-01T00:00:00Z',
        },
        {
          'dateIso': '2025-12-03',
          'sessionName': 'B',
          'entries': const [],
          'createdAtIso': '2025-12-03T00:00:00Z',
        },
      ];

      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        extra: {TrainingExtraKeys.trainingSessionLogRecords: logs},
      );

      final result = service.ingestAndValidate(profile: profile);

      expect(result.derivedContext.effectiveAdherence, closeTo(0.5, 1e-6));
    });

    test('determinismo: mismo input produce mismo contexto derivado', () {
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 7.0,
        globalGoal: TrainingGoal.hypertrophy,
        extra: {
          TrainingExtraKeys.trainingPreferences: {
            'mustHave': ['squat'],
            'dislikes': ['burpees'],
            'intensificationAllowed': false,
            'intensificationMaxPerSession': 2,
          },
        },
      );

      final a = service.ingestAndValidate(profile: profile);
      final b = service.ingestAndValidate(profile: profile);

      expect(
        a.derivedContext.effectiveSleepHours,
        b.derivedContext.effectiveSleepHours,
      );
      expect(
        a.derivedContext.exerciseMustHave,
        b.derivedContext.exerciseMustHave,
      );
      expect(
        a.derivedContext.exerciseDislikes,
        b.derivedContext.exerciseDislikes,
      );
      expect(
        a.derivedContext.intensificationAllowed,
        b.derivedContext.intensificationAllowed,
      );
      expect(
        a.derivedContext.intensificationMaxPerSession,
        b.derivedContext.intensificationMaxPerSession,
      );
    });

    test('debe advertir cuando hay demasiadas prioridades primarias', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        priorityMusclesPrimary: [
          'chest',
          'back',
          'shoulders',
          'quads',
          'hamstrings',
        ], // > 4
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.warnings, contains('Demasiadas prioridades primarias'));
    });

    test('debe advertir cuando volumen excede tiempo disponible', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 45, // 135 min/semana
        baseVolumePerMuscle: {
          'chest': 14,
          'back': 16,
          'shoulders': 12,
          'quads': 12,
          'hamstrings': 10,
          // Total: 64 series * 4 min = ~256 min (excede 135 min)
        },
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.warnings, contains('Volumen excede tiempo disponible'));
      expect(
        result.decisions.any((d) => d.category == 'time_constraint'),
        true,
      );
    });

    test('debe registrar todas las decisiones con timestamps', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.decisions, isNotEmpty);
      for (final decision in result.decisions) {
        expect(decision.timestamp, isNotNull);
        expect(decision.phase, 'Phase1DataIngestion');
        expect(decision.category, isNotEmpty);
        expect(decision.description, isNotEmpty);
      }
    });

    test('debe manejar perfil vacío de forma conservadora', () {
      // Arrange
      final profile = TrainingProfile.empty();

      // Act
      final result = service.ingestAndValidate(profile: profile);

      // Assert
      expect(result.isValid, false);
      expect(result.warnings, isNotEmpty);
      expect(result.hasCriticalIssues, true);
    });
  });
}
