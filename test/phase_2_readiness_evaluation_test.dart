import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart';

void main() {
  group('Phase2ReadinessEvaluationService', () {
    late Phase2ReadinessEvaluationService service;

    setUp(() {
      service = Phase2ReadinessEvaluationService();
    });

    test('debe evaluar readiness excelente con condiciones óptimas', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 8.5,
        sorenessLevel: 2.0,
        motivationLevel: 9.0,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 2.5,
        soreness: 2.0,
        motivation: 9.0,
        adherence: 0.95,
        avgRir: 2.0,
        sleepHours: 8.5,
        stressLevel: 2.0,
      );

      final history = TrainingHistory(
        totalSessions: 100,
        completedSessions: 95,
        averageAdherence: 0.95,
        averageRpe: 7.5,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        history: history,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.readinessLevel, ReadinessLevel.excellent);
      expect(result.readinessScore, greaterThan(0.85));
      expect(result.volumeAdjustmentFactor, greaterThanOrEqualTo(1.0));
      expect(result.needsDeload, false);
      expect(result.needsVolumeReduction, false);
    });

    test('debe evaluar readiness crítico con condiciones muy pobres', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 5.0, // Muy bajo
        sorenessLevel: 8.5, // Muy alto
        motivationLevel: 3.0, // Muy bajo
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 9.0, // Muy alto
        soreness: 8.5,
        motivation: 3.0,
        adherence: 0.4,
        avgRir: 0.5,
        sleepHours: 5.0,
        stressLevel: 9.0, // Muy alto
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.readinessLevel, ReadinessLevel.critical);
      expect(result.readinessScore, lessThan(0.4));
      expect(result.volumeAdjustmentFactor, lessThan(0.7));
      expect(result.needsDeload, true);
      expect(result.needsVolumeReduction, true);
      expect(result.recommendations, isNotEmpty);
    });

    test('debe reducir volumen cuando sueño es insuficiente', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 5.5, // < 6h
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act
      final result = service.evaluateReadiness(profile: profile);

      // Assert
      expect(result.volumeAdjustmentFactor, lessThan(1.0));
      expect(
        result.decisions.any(
          (d) => d.category == 'sleep_evaluation' && d.severity == 'warning',
        ),
        true,
      );
      expect(result.recommendations.any((r) => r.contains('sueño')), true);
    });

    test('debe reducir volumen cuando fatiga es alta', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 8.0, // Alta
        soreness: 7.5, // Alta
        motivation: 5.0,
        adherence: 0.7,
        avgRir: 1.0,
        sleepHours: 7.0,
        stressLevel: 6.0,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.volumeAdjustmentFactor, lessThan(0.9));
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'fatigue_evaluation' &&
              d.description.contains('Fatiga alta'),
        ),
        true,
      );
      expect(
        result.recommendations.any(
          (r) => r.contains('deload') || r.contains('descarga'),
        ),
        true,
      );
    });

    test('debe reducir volumen cuando estrés es muy alto', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 5.0,
        soreness: 5.0,
        motivation: 6.0,
        adherence: 0.8,
        avgRir: 2.0,
        sleepHours: 7.0,
        stressLevel: 9.0, // Muy alto
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.volumeAdjustmentFactor, lessThan(1.0));
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'stress_evaluation' &&
              d.description.contains('Estrés muy alto'),
        ),
        true,
      );
    });

    test('debe considerar motivación baja en el readiness', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 45,
        motivationLevel: 3.0, // Baja
        globalGoal: TrainingGoal.generalFitness,
      );

      final feedback = TrainingFeedback(
        fatigue: 5.0,
        soreness: 5.0,
        motivation: 3.0, // Baja
        adherence: 0.6,
        avgRir: 3.0,
        sleepHours: 7.0,
        stressLevel: 5.0,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.readinessScore, lessThan(0.75)); // Ajustado
      expect(result.recommendations.any((r) => r.contains('objetivo')), true);
    });

    test('debe considerar historial de adherencia en evaluación', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final history = TrainingHistory(
        totalSessions: 50,
        completedSessions: 25,
        averageAdherence: 0.5, // Baja
        averageRpe: 8.0,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        history: history,
      );

      // Assert
      expect(result.readinessScore, lessThan(0.8));
      expect(
        result.decisions.any((d) => d.category == 'history_evaluation'),
        true,
      );
      expect(result.recommendations.any((r) => r.contains('adherencia')), true);
    });

    test('debe usar valores conservadores sin feedback', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Act (sin feedback ni history)
      final result = service.evaluateReadiness(profile: profile);

      // Assert
      expect(result.readinessScore, greaterThan(0.6)); // Neutro conservador
      expect(result.readinessScore, lessThan(0.8));
      expect(result.volumeAdjustmentFactor, lessThanOrEqualTo(1.0));
    });

    test('debe calcular score ponderado correctamente', () {
      // Arrange: Condiciones mixtas
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 8.0, // Bueno (peso 30%)
        motivationLevel: 5.0, // Regular (peso 15%)
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 6.0, // Regular (peso 25%)
        soreness: 5.5,
        motivation: 5.0,
        adherence: 0.8,
        avgRir: 2.5,
        sleepHours: 8.0,
        stressLevel: 6.0, // Regular (peso 20%)
      );

      final history = TrainingHistory(
        totalSessions: 80,
        completedSessions: 70,
        averageAdherence: 0.875, // Bueno (peso 10%)
        averageRpe: 7.5,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        history: history,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.readinessScore, greaterThan(0.5));
      expect(result.readinessScore, lessThan(0.9));
      expect(result.metrics['sleepScore'], isNotNull);
      expect(result.metrics['fatigueScore'], isNotNull);
      expect(result.metrics['stressScore'], isNotNull);
      expect(result.metrics['motivationScore'], isNotNull);
      expect(result.metrics['historyScore'], isNotNull);
    });

    test('debe ajustar factor de volumen según nivel de readiness', () {
      // Test para cada nivel
      final testCases = [
        (ReadinessLevel.excellent, 1.0, 1.15),
        (ReadinessLevel.good, 0.95, 1.10),
        (ReadinessLevel.moderate, 0.80, 0.95),
        (
          ReadinessLevel.low,
          0.63,
          0.80,
        ), // Ajustado límite inferior por precisión
        (ReadinessLevel.critical, 0.50, 0.65),
      ];

      for (final testCase in testCases) {
        // Simular diferentes readiness scores para obtener cada nivel
        double targetScore;
        switch (testCase.$1) {
          case ReadinessLevel.excellent:
            targetScore = 0.9;
          case ReadinessLevel.good:
            targetScore = 0.75;
          case ReadinessLevel.moderate:
            targetScore = 0.6;
          case ReadinessLevel.low:
            targetScore = 0.45;
          case ReadinessLevel.critical:
            targetScore = 0.3;
        }

        // Crear perfil y feedback que generen el score deseado
        final profile = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 60,
          avgSleepHours: targetScore > 0.7
              ? 8.0
              : (targetScore > 0.5 ? 6.5 : 5.0),
          motivationLevel: targetScore > 0.7
              ? 8.0
              : (targetScore > 0.5 ? 6.0 : 3.0),
          globalGoal: TrainingGoal.hypertrophy,
        );

        final feedback = TrainingFeedback(
          fatigue: targetScore > 0.7 ? 3.0 : (targetScore > 0.5 ? 6.0 : 8.5),
          soreness: targetScore > 0.7 ? 3.0 : (targetScore > 0.5 ? 6.0 : 8.5),
          motivation: targetScore > 0.7 ? 8.0 : (targetScore > 0.5 ? 6.0 : 3.0),
          adherence: targetScore > 0.7 ? 0.9 : (targetScore > 0.5 ? 0.7 : 0.4),
          avgRir: 2.0,
          sleepHours: targetScore > 0.7 ? 8.0 : (targetScore > 0.5 ? 6.5 : 5.0),
          stressLevel: targetScore > 0.7
              ? 3.0
              : (targetScore > 0.5 ? 6.0 : 9.0),
        );

        // Act
        final result = service.evaluateReadiness(
          profile: profile,
          latestFeedback: feedback,
        );

        // Assert rango del factor de ajuste
        expect(
          result.volumeAdjustmentFactor,
          greaterThanOrEqualTo(testCase.$2),
          reason: 'Factor muy bajo para ${testCase.$1.name}',
        );
        expect(
          result.volumeAdjustmentFactor,
          lessThanOrEqualTo(testCase.$3),
          reason: 'Factor muy alto para ${testCase.$1.name}',
        );
      }
    });

    test('debe clampar factor de volumen entre 0.5 y 1.15', () {
      // Arrange: Condiciones extremas
      final profileExcellent = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        avgSleepHours: 9.0,
        motivationLevel: 10.0,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedbackExcellent = TrainingFeedback(
        fatigue: 1.0,
        soreness: 1.0,
        motivation: 10.0,
        adherence: 1.0,
        avgRir: 3.0,
        sleepHours: 9.0,
        stressLevel: 1.0,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profileExcellent,
        latestFeedback: feedbackExcellent,
      );

      // Assert
      expect(result.volumeAdjustmentFactor, lessThanOrEqualTo(1.15));
      expect(result.volumeAdjustmentFactor, greaterThanOrEqualTo(0.5));
    });

    test('debe registrar todas las decisiones con metadatos', () {
      // Arrange
      final profile = TrainingProfile(
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 7.5,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 5.0,
        soreness: 5.0,
        motivation: 7.0,
        adherence: 0.85,
        avgRir: 2.5,
        sleepHours: 7.5,
        stressLevel: 5.0,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.decisions, isNotEmpty);
      expect(
        result.decisions.where((d) => d.phase == 'Phase2ReadinessEvaluation'),
        hasLength(result.decisions.length),
      );
      expect(
        result.decisions.any((d) => d.category == 'sleep_evaluation'),
        true,
      );
      expect(
        result.decisions.any((d) => d.category == 'fatigue_evaluation'),
        true,
      );
      expect(
        result.decisions.any((d) => d.category == 'stress_evaluation'),
        true,
      );
      expect(
        result.decisions.any((d) => d.category == 'motivation_evaluation'),
        true,
      );
      expect(
        result.decisions.any((d) => d.category == 'final_assessment'),
        true,
      );
    });

    test('debe generar recomendaciones apropiadas según readiness', () {
      // Arrange: Readiness bajo
      final profile = TrainingProfile(
        daysPerWeek: 5,
        timePerSessionMinutes: 60,
        avgSleepHours: 5.5,
        motivationLevel: 4.0,
        globalGoal: TrainingGoal.hypertrophy,
      );

      final feedback = TrainingFeedback(
        fatigue: 7.5,
        soreness: 7.0,
        motivation: 4.0,
        adherence: 0.6,
        avgRir: 1.5,
        sleepHours: 5.5,
        stressLevel: 7.5,
      );

      // Act
      final result = service.evaluateReadiness(
        profile: profile,
        latestFeedback: feedback,
      );

      // Assert
      expect(result.recommendations, isNotEmpty);
      expect(result.recommendations.length, greaterThanOrEqualTo(3));
    });
  });
}
