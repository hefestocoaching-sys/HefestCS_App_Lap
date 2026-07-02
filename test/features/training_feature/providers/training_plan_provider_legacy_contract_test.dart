import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingPlanProvider legacy contract', () {
    test('generatePlanFromActiveCycle remains the product path', () {
      final source = _read(
        'lib/features/training_feature/providers/training_plan_provider.dart',
      );

      expect(
        source,
        contains('Future<TrainingPlanConfig?> generatePlanFromActiveCycle('),
      );
      final productBody = _extractMethodBody(
        source,
        'Future<TrainingPlanConfig?> generatePlanFromActiveCycle(',
      );
      expect(productBody, isNot(contains('generateTrainingPlan(')));
    });

    test('generateTrainingPlan is a short legacy stub without dead code', () {
      final source = _read(
        'lib/features/training_feature/providers/training_plan_provider.dart',
      );

      final legacyBody = _extractMethodBody(
        source,
        'Future<TrainingPlan> generateTrainingPlan({',
      );

      expect(
        source,
        contains(
          "@Deprecated('Usar generatePlanFromActiveCycle como entrada oficial')",
        ),
      );
      expect(legacyBody, contains('throw StateError('));
      expect(
        legacyBody,
        contains(
          'generateTrainingPlan es legacy. Usa generatePlanFromActiveCycle.',
        ),
      );
      expect(
        legacyBody,
        isNot(contains('No se pudo materializar TrainingPlan legacy')),
      );
      expect(
        legacyBody,
        isNot(contains("[TrainingPlanProvider] Generating plan for client")),
      );
      expect(legacyBody, isNot(contains('debugPrint(')));
      expect(
        legacyBody,
        isNot(contains('MotorV3Orchestrator.generateProgram')),
      );
      expect(legacyBody, isNot(contains('WorkoutLogRepository.getLogsByUser')));
      expect(
        legacyBody,
        isNot(contains('TrainingEvaluationSnapshotV1.fromTrainingEvaluation')),
      );
    });

    test('generatePlanFromActiveCycle does not delegate back to legacy', () {
      final source = _read(
        'lib/features/training_feature/providers/training_plan_provider.dart',
      );
      final productBody = _extractMethodBody(
        source,
        'Future<TrainingPlanConfig?> generatePlanFromActiveCycle(',
      );

      expect(productBody, isNot(contains('generateTrainingPlan(')));
      expect(
        productBody,
        contains(
          'debugPrint(\'🎯 [Motor V3] Generando plan desde ciclo activo...\');',
        ),
      );
    });
  });
}

String _read(String path) => File(path).readAsStringSync();

String _extractMethodBody(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNonNegative);
  final bodyStart = source.indexOf(') async {', start);
  final braceStart = bodyStart >= 0
      ? bodyStart + ') async '.length
      : source.indexOf(') {', start) + ') '.length;
  expect(braceStart, isNonNegative);

  var depth = 0;
  for (var index = braceStart; index < source.length; index++) {
    final char = source[index];
    if (char == '{') depth++;
    if (char == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(braceStart, index + 1);
      }
    }
  }

  fail('Could not extract method body for $signature');
}
