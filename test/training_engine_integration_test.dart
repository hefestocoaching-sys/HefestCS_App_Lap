import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart';
import 'package:hcs_app_lap/domain/services/phase_3_volume_capacity_model_service.dart';

/// Test de integración que demuestra el flujo completo de las 3 primeras fases
/// del motor de entrenamiento.
void main() {
  group('Integración Fases 1-2-3', () {
    test('flujo completo: ingestión → readiness → límites de volumen', () {
      // ========== DATOS DE ENTRADA ==========

      // Perfil del cliente
      final profile = TrainingProfile(
        id: 'cliente-123',
        age: 28,
        daysPerWeek: 4,
        timePerSessionMinutes: 75,
        trainingLevel: TrainingLevel.intermediate,
        avgSleepHours: 7.5,
        priorityMusclesPrimary: ['chest', 'back'],
        priorityMusclesSecondary: ['shoulders', 'quads'],
        baseVolumePerMuscle: {
          'chest': 12,
          'back': 14,
          'shoulders': 10,
          'quads': 10,
        },
        globalGoal: TrainingGoal.hypertrophy,
        usesAnabolics: false,
        sorenessLevel: 4.5,
        motivationLevel: 7.5,
      );

      // Historial del cliente
      final history = TrainingHistory(
        firstSessionDate: DateTime.now().subtract(const Duration(days: 180)),
        lastSessionDate: DateTime.now().subtract(const Duration(days: 2)),
        totalSessions: 120,
        completedSessions: 108,
        averageAdherence: 0.9,
        averageRpe: 7.5,
        averageFatigue: 5.5,
        bestLifts: {'squat': 140.0, 'bench': 100.0, 'deadlift': 160.0},
      );

      // Feedback más reciente
      final latestFeedback = TrainingFeedback(
        fatigue: 5.5,
        soreness: 4.5,
        motivation: 7.5,
        adherence: 0.92,
        avgRir: 2.5,
        sleepHours: 7.5,
        stressLevel: 5.0,
      );

      // ========== FASE 1: INGESTIÓN Y VALIDACIÓN ==========

      final phase1Service = Phase1DataIngestionService();
      final phase1Result = phase1Service.ingestAndValidate(
        profile: profile,
        history: history,
        latestFeedback: latestFeedback,
      );

      // Validar que Fase 1 aprobó los datos
      expect(
        phase1Result.isValid,
        true,
        reason: 'Fase 1 debe validar el perfil como correcto',
      );
      expect(
        phase1Result.decisions,
        isNotEmpty,
        reason: 'Fase 1 debe registrar decisiones',
      );

      // Verificar que no hay issues críticos
      expect(phase1Result.hasCriticalIssues, false);

      // Fase 1 validations passed

      // ========== FASE 2: EVALUACIÓN DE READINESS ==========

      final phase2Service = Phase2ReadinessEvaluationService();
      final phase2Result = phase2Service.evaluateReadiness(
        profile: profile,
        history: history,
        latestFeedback: latestFeedback,
      );

      // Validar evaluación de readiness
      expect(phase2Result.readinessScore, greaterThan(0.0));
      expect(phase2Result.readinessScore, lessThanOrEqualTo(1.0));
      expect(phase2Result.volumeAdjustmentFactor, greaterThan(0.5));
      expect(phase2Result.volumeAdjustmentFactor, lessThanOrEqualTo(1.15));

      // Phase 2 validations passed

      // ========== FASE 3: LÍMITES DE VOLUMEN ==========

      final phase3Service = Phase3VolumeCapacityModelService();
      final phase3Result = phase3Service.calculateVolumeCapacity(
        profile: profile,
        history: history,
        readinessAdjustment: phase2Result.volumeAdjustmentFactor,
      );

      // Validar límites de volumen
      expect(phase3Result.volumeLimitsByMuscle, isNotEmpty);

      for (final entry in phase3Result.volumeLimitsByMuscle.entries) {
        final limits = entry.value;

        // Validar que los límites son coherentes
        expect(limits.mev, greaterThan(0));
        expect(limits.mav, greaterThan(limits.mev));
        expect(limits.mrv, greaterThan(limits.mav));
        expect(limits.recommendedStartVolume, greaterThanOrEqualTo(limits.mev));
        expect(limits.recommendedStartVolume, lessThanOrEqualTo(limits.mav));
      }

      // Phase 3 validations passed
    });

    test('flujo con usuario principiante y sin historial', () {
      // Caso: Cliente nuevo, sin experiencia
      final profile = TrainingProfile(
        id: 'nuevo-cliente',
        age: 24,
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        trainingLevel: TrainingLevel.beginner,
        avgSleepHours: 7.0,
        priorityMusclesPrimary: ['chest', 'back', 'quads'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      // Sin historial ni feedback
      final phase1Service = Phase1DataIngestionService();
      final phase1Result = phase1Service.ingestAndValidate(profile: profile);

      expect(phase1Result.isValid, true);
      expect(
        phase1Result.warnings,
        isNotEmpty,
        reason: 'Debe haber warnings por falta de datos',
      );

      final phase2Service = Phase2ReadinessEvaluationService();
      final phase2Result = phase2Service.evaluateReadiness(profile: profile);

      // Debe usar valores conservadores
      expect(phase2Result.readinessScore, greaterThan(0.6));

      final phase3Service = Phase3VolumeCapacityModelService();
      final phase3Result = phase3Service.calculateVolumeCapacity(
        profile: profile,
        readinessAdjustment: phase2Result.volumeAdjustmentFactor,
      );

      // Principiante: MRV nunca debe exceder 16
      for (final limits in phase3Result.volumeLimitsByMuscle.values) {
        expect(
          limits.mrv,
          lessThanOrEqualTo(16),
          reason: 'MRV para principiantes debe ser ≤ 16 sets/semana',
        );
      }
    });

    test('flujo con atleta avanzado usando farmacología', () {
      // Caso: Atleta experimentado con farmacología
      final profile = TrainingProfile(
        id: 'atleta-avanzado',
        age: 32,
        daysPerWeek: 5,
        timePerSessionMinutes: 90,
        trainingLevel: TrainingLevel.advanced,
        usesAnabolics: true,
        pharmacologyProtocol: 'TRT + Anavar',
        avgSleepHours: 8.0,
        priorityMusclesPrimary: ['chest', 'back', 'shoulders', 'quads'],
        globalGoal: TrainingGoal.hypertrophy,
      );

      final history = TrainingHistory(
        totalSessions: 300,
        completedSessions: 285,
        averageAdherence: 0.95,
        averageRpe: 8.0,
      );

      final feedback = TrainingFeedback(
        fatigue: 4.0,
        soreness: 3.5,
        motivation: 9.0,
        adherence: 0.95,
        avgRir: 2.0,
        sleepHours: 8.0,
        stressLevel: 3.0,
      );

      final phase1Service = Phase1DataIngestionService();
      final phase1Result = phase1Service.ingestAndValidate(
        profile: profile,
        history: history,
        latestFeedback: feedback,
      );

      expect(phase1Result.isValid, true);

      final phase2Service = Phase2ReadinessEvaluationService();
      final phase2Result = phase2Service.evaluateReadiness(
        profile: profile,
        history: history,
        latestFeedback: feedback,
      );

      // Alta readiness esperada
      expect(phase2Result.readinessLevel, ReadinessLevel.excellent);
      expect(phase2Result.volumeAdjustmentFactor, greaterThan(1.0));

      final phase3Service = Phase3VolumeCapacityModelService();
      final phase3Result = phase3Service.calculateVolumeCapacity(
        profile: profile,
        history: history,
        readinessAdjustment: phase2Result.volumeAdjustmentFactor,
      );

      // Verificar que se aplicó ajuste por farmacología
      expect(
        phase3Result.metadata['pharmacologyFactor'],
        greaterThan(1.0),
        reason: 'Debe aplicar factor de farmacología',
      );

      // MRV más alto que atleta natural
      final totalMRV = phase3Result.getTotalMRV();
      expect(
        totalMRV,
        greaterThan(60),
        reason: 'Atleta avanzado con farmacología puede manejar alto volumen',
      );
    });
  });
}
