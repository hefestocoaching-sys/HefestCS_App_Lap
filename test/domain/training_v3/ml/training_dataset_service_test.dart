import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/training_dataset_service.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';

void main() {
  group('TrainingExample Serialization', () {
    test('toJson and fromJson round-trip preserves data', () {
      // Crear ejemplo de prueba
      final volumeDecision = VolumeDecision(
        adjustmentFactor: 1.05,
        confidence: 0.85,
        reasoning: 'Test reasoning',
        metadata: {'strategy': 'rule_based'},
      );

      final readinessDecision = ReadinessDecision(
        level: ReadinessLevel.good,
        score: 0.78,
        confidence: 0.90,
        recommendations: ['Test recommendation'],
      );

      final example = TrainingExample(
        exampleId: 'test-123',
        timestamp: DateTime(2026, 1, 1, 12, 0),
        clientId: 'client-456',
        featureTensor: List.generate(37, (i) => i * 0.1),
        featureMetadata: {'readinessScore': 0.75, 'fatigueIndex': 0.4},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.92,
        actualFatigue: 6.5,
        actualProgress: 2.5,
        injuryOccurred: false,
        userRatedTooHard: false,
        userRatedTooEasy: false,
      );

      // Serializar
      final json = example.toJson();

      // Verificar estructura JSON
      expect(json['exampleId'], 'test-123');
      expect(json['clientId'], 'client-456');
      expect(json['features']['tensor'], isA<List<double>>());
      expect(json['features']['tensor'].length, 37);
      expect(json['prediction']['volume']['adjustmentFactor'], 1.05);
      expect(json['prediction']['readiness']['level'], 'good');
      expect(json['outcome']['adherence'], 0.92);
      expect(json['outcome']['fatigue'], 6.5);

      // Deserializar
      final reconstructed = TrainingExample.fromJson(json);

      // Verificar campos
      expect(reconstructed.exampleId, example.exampleId);
      expect(reconstructed.clientId, example.clientId);
      expect(reconstructed.featureTensor.length, 37);
      expect(reconstructed.predictedVolume.adjustmentFactor, 1.05);
      expect(reconstructed.predictedReadiness.level, ReadinessLevel.good);
      expect(reconstructed.actualAdherence, 0.92);
      expect(reconstructed.actualFatigue, 6.5);
      expect(reconstructed.strategyUsed, 'rule_based');
    });

    test('weeklyFeedback serialization works correctly', () {
      final volumeDecision = VolumeDecision.maintain();
      final readinessDecision = ReadinessDecision(
        level: ReadinessLevel.moderate,
        score: 0.65,
        confidence: 0.80,
        recommendations: [],
      );

      final weeklyFeedback = WeeklyTrainingFeedbackSummary(
        clientId: 'client-789',
        weekStart: DateTime(2026, 1, 8),
        weekEnd: DateTime(2026, 1, 14),
        plannedSetsTotal: 60,
        completedSetsTotal: 53,
        adherenceRatio: 0.88,
        avgReportedRIR: 2.5,
        avgEffort: 7.2,
        painEvents: 0,
        formDegradationEvents: 1,
        stoppedEarlyEvents: 0,
        signal: 'positive',
        fatigueExpectation: 'moderate',
        progressionAllowed: true,
        deloadRecommended: false,
        reasons: ['Good adherence', 'Moderate fatigue'],
        debugContext: {},
      );

      final example = TrainingExample(
        exampleId: 'test-with-feedback',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-789',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.88,
        actualFatigue: 6.0,
        weeklyFeedback: weeklyFeedback,
      );

      // Serializar
      final json = example.toJson();

      // Verificar weeklyFeedback presente
      expect(json['weeklyFeedback'], isNotNull);
      expect(json['weeklyFeedback']['progressionAllowed'], true);
      expect(json['weeklyFeedback']['deloadRecommended'], false);
      expect(json['weeklyFeedback']['signal'], 'positive');

      // Deserializar
      final reconstructed = TrainingExample.fromJson(json);

      // Verificar weeklyFeedback reconstruido
      expect(reconstructed.weeklyFeedback, isNotNull);
      expect(reconstructed.weeklyFeedback!.progressionAllowed, true);
      expect(reconstructed.weeklyFeedback!.deloadRecommended, false);
      expect(reconstructed.weeklyFeedback!.signal, 'positive');
    });

    test('computedOptimalVolume uses weeklyFeedback when available', () {
      final volumeDecision = VolumeDecision(
        adjustmentFactor: 1.0,
        confidence: 0.85,
        reasoning: 'Baseline',
      );

      final readinessDecision = ReadinessDecision(
        level: ReadinessLevel.good,
        score: 0.75,
        confidence: 0.85,
        recommendations: [],
      );

      // CASO 1: deloadRecommended = true
      final feedbackDeload = WeeklyTrainingFeedbackSummary(
        clientId: 'client-test',
        weekStart: DateTime(2026, 1, 8),
        weekEnd: DateTime(2026, 1, 14),
        plannedSetsTotal: 60,
        completedSetsTotal: 39,
        adherenceRatio: 0.65,
        avgReportedRIR: 1.0,
        avgEffort: 8.5,
        painEvents: 2,
        formDegradationEvents: 3,
        stoppedEarlyEvents: 2,
        signal: 'negative',
        fatigueExpectation: 'high',
        progressionAllowed: false,
        deloadRecommended: true,
        reasons: ['High fatigue', 'Low adherence', 'Pain events'],
        debugContext: {},
      );

      final exampleDeload = TrainingExample(
        exampleId: 'test-deload',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.65,
        actualFatigue: 8.5,
        weeklyFeedback: feedbackDeload,
      );

      // Deload recomendado → 0.75 * predicted
      expect(exampleDeload.computedOptimalVolume, closeTo(0.75, 0.01));

      // CASO 2: progressionAllowed = true
      final feedbackProgress = WeeklyTrainingFeedbackSummary(
        clientId: 'client-test',
        weekStart: DateTime(2026, 1, 8),
        weekEnd: DateTime(2026, 1, 14),
        plannedSetsTotal: 60,
        completedSetsTotal: 55,
        adherenceRatio: 0.92,
        avgReportedRIR: 3.0,
        avgEffort: 6.8,
        painEvents: 0,
        formDegradationEvents: 0,
        stoppedEarlyEvents: 0,
        signal: 'positive',
        fatigueExpectation: 'low',
        progressionAllowed: true,
        deloadRecommended: false,
        reasons: ['Excellent adherence', 'Low fatigue', 'Good performance'],
        debugContext: {},
      );

      final exampleProgress = TrainingExample(
        exampleId: 'test-progress',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.92,
        actualFatigue: 4.5,
        weeklyFeedback: feedbackProgress,
      );

      // Progresión permitida → 1.05 * predicted
      expect(exampleProgress.computedOptimalVolume, closeTo(1.05, 0.01));
    });

    test('hasOutcome returns true only with adherence and fatigue', () {
      final volumeDecision = VolumeDecision.maintain();
      final readinessDecision = ReadinessDecision(
        level: ReadinessLevel.moderate,
        score: 0.65,
        confidence: 0.80,
        recommendations: [],
      );

      // Sin outcome
      final exampleNoOutcome = TrainingExample(
        exampleId: 'test-no-outcome',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
      );

      expect(exampleNoOutcome.hasOutcome, false);

      // Con outcome parcial (solo adherencia)
      final examplePartial = TrainingExample(
        exampleId: 'test-partial',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.88,
      );

      expect(examplePartial.hasOutcome, false);

      // Con outcome completo
      final exampleComplete = TrainingExample(
        exampleId: 'test-complete',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.88,
        actualFatigue: 6.5,
      );

      expect(exampleComplete.hasOutcome, true);
    });
  });

  group('TrainingExample Label Heuristics', () {
    late VolumeDecision volumeDecision;
    late ReadinessDecision readinessDecision;

    setUp(() {
      volumeDecision = VolumeDecision(
        adjustmentFactor: 1.0,
        confidence: 0.85,
        reasoning: 'Baseline',
      );

      readinessDecision = ReadinessDecision(
        level: ReadinessLevel.good,
        score: 0.75,
        confidence: 0.85,
        recommendations: [],
      );
    });

    test('CASO 1: Alta adherencia + baja fatiga → volumen bajo', () {
      final example = TrainingExample(
        exampleId: 'test-case1',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.95,
        actualFatigue: 4.0,
        userRatedTooEasy: true,
      );

      // Muy fácil → +15%
      expect(example.computedOptimalVolume, closeTo(1.15, 0.01));
    });

    test('CASO 2: Baja adherencia + alta fatiga → volumen alto', () {
      final example = TrainingExample(
        exampleId: 'test-case2',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.65,
        actualFatigue: 8.5,
        userRatedTooHard: true,
      );

      // Muy duro → -25%
      expect(example.computedOptimalVolume, closeTo(0.75, 0.01));
    });

    test('CASO 3: Lesión → volumen DEFINITIVAMENTE alto', () {
      final example = TrainingExample(
        exampleId: 'test-case3',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.80,
        actualFatigue: 7.0,
        injuryOccurred: true,
      );

      // Lesión → -30%
      expect(example.computedOptimalVolume, closeTo(0.70, 0.01));
    });

    test('CASO 4: Progreso + adherencia + fatiga óptima → PERFECTO', () {
      final example = TrainingExample(
        exampleId: 'test-case4',
        timestamp: DateTime(2026, 1, 1),
        clientId: 'client-test',
        featureTensor: List.generate(37, (i) => 0.5),
        featureMetadata: {},
        predictedVolume: volumeDecision,
        predictedReadiness: readinessDecision,
        strategyUsed: 'rule_based',
        actualAdherence: 0.88,
        actualFatigue: 6.0,
        actualProgress: 2.5,
      );

      // Óptimo → mantener
      expect(example.computedOptimalVolume, closeTo(1.0, 0.01));
    });
  });
}
