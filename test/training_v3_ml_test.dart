import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/rule_based_strategy.dart';

void main() {
  group('FeatureVector Unit Tests', () {
    test('FeatureVector properties are normalized (0-1)', () {
      // Crear un vector con valores de prueba
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        // Biological (5)
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,

        // Experience (3)
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,

        // Volume (3)
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,

        // Recovery (4)
        avgSleepHoursNorm: 0.75,
        perceivedRecoveryNorm: 0.7,
        stressLevelNorm: 0.3,
        soreness48hNorm: 0.4,

        // Intensity (3)
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,

        // Consistency (3)
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,

        // Performance (1)
        performanceTrendEncoded: 1.0,

        // Derived (6)
        fatigueIndex: 0.35,
        recoveryCapacity: 0.75,
        trainingMaturity: 0.6,
        overreachingRisk: 0.25,
        readinessScore: 0.72,
        volumeOptimalityIndex: 0.68,

        // One-hot encodings
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      // Validar que todo está en rango
      expect(vector.ageYearsNorm, inInclusiveRange(0.0, 1.0));
      expect(vector.genderMaleEncoded, inInclusiveRange(0.0, 1.0));
      expect(vector.fatigueIndex, inInclusiveRange(0.0, 1.0));
      expect(vector.readinessScore, inInclusiveRange(0.0, 1.0));
    });

    test('toTensor() returns 36-element list', () {
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,
        avgSleepHoursNorm: 0.75,
        perceivedRecoveryNorm: 0.7,
        stressLevelNorm: 0.3,
        soreness48hNorm: 0.4,
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,
        performanceTrendEncoded: 1.0,
        fatigueIndex: 0.35,
        recoveryCapacity: 0.75,
        trainingMaturity: 0.6,
        overreachingRisk: 0.25,
        readinessScore: 0.72,
        volumeOptimalityIndex: 0.68,
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      final tensor = vector.toTensor();

      expect(tensor.length, equals(36));

      // Validar que no hay valores inválidos
      for (final value in tensor) {
        expect(value.isNaN, isFalse);
        expect(value.isInfinite, isFalse);
      }
    });

    test('One-hot goal encoding sums to 1.0', () {
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,
        avgSleepHoursNorm: 0.75,
        perceivedRecoveryNorm: 0.7,
        stressLevelNorm: 0.3,
        soreness48hNorm: 0.4,
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,
        performanceTrendEncoded: 1.0,
        fatigueIndex: 0.35,
        recoveryCapacity: 0.75,
        trainingMaturity: 0.6,
        overreachingRisk: 0.25,
        readinessScore: 0.72,
        volumeOptimalityIndex: 0.68,
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      final goalSum = vector.goalOneHot.values.reduce((a, b) => a + b);
      expect(goalSum, closeTo(1.0, 0.01));
    });

    test('toJson() includes all expected sections', () {
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,
        avgSleepHoursNorm: 0.75,
        perceivedRecoveryNorm: 0.7,
        stressLevelNorm: 0.3,
        soreness48hNorm: 0.4,
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,
        performanceTrendEncoded: 1.0,
        fatigueIndex: 0.35,
        recoveryCapacity: 0.75,
        trainingMaturity: 0.6,
        overreachingRisk: 0.25,
        readinessScore: 0.72,
        volumeOptimalityIndex: 0.68,
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      final json = vector.toJson();

      expect(json.containsKey('biological'), isTrue);
      expect(json.containsKey('experience'), isTrue);
      expect(json.containsKey('volume'), isTrue);
      expect(json.containsKey('recovery'), isTrue);
      expect(json.containsKey('intensity'), isTrue);
      expect(json.containsKey('consistency'), isTrue);
      expect(json.containsKey('performance'), isTrue);
      expect(json.containsKey('derived'), isTrue);
      expect(json.containsKey('categorical'), isTrue);
    });
  });

  group('RuleBasedStrategy Unit Tests', () {
    test('RuleBasedStrategy has name and version', () {
      final strategy = RuleBasedStrategy();

      expect(strategy.name, equals('RuleBasedStrategy'));
      expect(strategy.version, isNotEmpty);
      expect(strategy.version, contains('Israetel'));
      expect(strategy.version, contains('Schoenfeld'));
      expect(strategy.version, contains('Helms'));
    });

    test('decide() returns TrainingDecision with valid structure', () async {
      final strategy = RuleBasedStrategy();
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,
        avgSleepHoursNorm: 0.75,
        perceivedRecoveryNorm: 0.7,
        stressLevelNorm: 0.3,
        soreness48hNorm: 0.4,
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,
        performanceTrendEncoded: 1.0,
        fatigueIndex: 0.35,
        recoveryCapacity: 0.75,
        trainingMaturity: 0.6,
        overreachingRisk: 0.25,
        readinessScore: 0.72,
        volumeOptimalityIndex: 0.68,
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      final decision = await strategy.decide(vector);

      // Validar estructura básica
      expect(decision.recommendation, isNotEmpty);
      expect([
        'REST',
        'LIGHT',
        'MODERATE',
        'HIGH',
        'DELOAD',
      ], contains(decision.recommendation));

      // Validar confidence
      expect(decision.confidence, greaterThanOrEqualTo(0.5));
      expect(decision.confidence, lessThanOrEqualTo(1.0));

      // Validar factor scores
      expect(decision.factorScores.isNotEmpty, isTrue);
      expect(decision.factorScores.containsKey('trainingReadiness'), isTrue);

      // Validar metadata
      expect(decision.metadata.isNotEmpty, isTrue);
      expect(decision.metadata.containsKey('strategy'), isTrue);
    });

    test('High readiness leads to HIGH/MODERATE', () async {
      final strategy = RuleBasedStrategy();

      // Vector con excelente readiness
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,
        avgSleepHoursNorm: 0.9,
        perceivedRecoveryNorm: 0.9,
        stressLevelNorm: 0.1,
        soreness48hNorm: 0.1,
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,
        performanceTrendEncoded: 1.0,
        fatigueIndex: 0.2,
        recoveryCapacity: 0.85,
        trainingMaturity: 0.6,
        overreachingRisk: 0.1,
        readinessScore: 0.85,
        volumeOptimalityIndex: 0.68,
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      final decision = await strategy.decide(vector);

      expect(['HIGH', 'MODERATE'], contains(decision.recommendation));
    });

    test('Low readiness leads to REST/LIGHT', () async {
      final strategy = RuleBasedStrategy();

      // Vector con pobre readiness
      final vector = FeatureVector(
        clientId: 'test_user',
        timestamp: DateTime(2025, 1, 1),
        schemaVersion: 1,
        ageYearsNorm: 0.3,
        genderMaleEncoded: 1.0,
        heightCmNorm: 0.6,
        weightKgNorm: 0.5,
        bmiNorm: 0.4,
        yearsTrainingNorm: 0.5,
        consecutiveWeeksNorm: 0.8,
        trainingLevelEncoded: 0.5,
        avgWeeklySetsNorm: 0.5,
        maxSetsToleratedNorm: 0.55,
        volumeToleranceRatio: 0.6,
        avgSleepHoursNorm: 0.2,
        perceivedRecoveryNorm: 0.2,
        stressLevelNorm: 0.9,
        soreness48hNorm: 0.9,
        averageRIRNorm: 0.5,
        averageSessionRPENorm: 0.65,
        rirOptimalityScore: 0.8,
        deloadFrequencyNorm: 0.6,
        periodBreaksNorm: 0.7,
        adherenceHistorical: 0.85,
        performanceTrendEncoded: 0.0,
        fatigueIndex: 0.8,
        recoveryCapacity: 0.2,
        trainingMaturity: 0.6,
        overreachingRisk: 0.8,
        readinessScore: 0.2,
        volumeOptimalityIndex: 0.68,
        goalOneHot: {
          'hypertrophy': 1.0,
          'strength': 0.0,
          'endurance': 0.0,
          'general': 0.0,
        },
        focusOneHot: {
          'hypertrophy': 0.0,
          'strength': 1.0,
          'power': 0.0,
          'mixed': 0.0,
        },
      );

      final decision = await strategy.decide(vector);

      expect(['REST', 'LIGHT'], contains(decision.recommendation));
    });
  });
}
