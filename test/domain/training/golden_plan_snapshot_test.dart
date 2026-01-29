import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import '../../fixtures/training_fixtures.dart';

void main() {
  group('PR-10 Golden snapshot del plan', () {
    test('Bloquea explícitamente si no puede garantizar ≥4 ejercicios/día', () {
      final engine = TrainingProgramEngine();
      final profile = validTrainingProfile(
        daysPerWeek: 4,
      ).copyWith(id: 'golden-client-01');

      expect(
        () => engine.generatePlan(
          planId: 'golden-plan-01',
          clientId: 'golden-client-01',
          planName: 'Golden Plan 01',
          startDate: DateTime.utc(2025, 12, 20),
          profile: profile,
          exercises: canonicalExercises(),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
