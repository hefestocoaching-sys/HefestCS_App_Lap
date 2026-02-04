import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import '../../fixtures/training_fixtures.dart';

@Skip('Legacy test: migración pendiente a training_v3')
void main() {
  group('PR-10 Determinismo total del motor', () {
    test('Mismo input => mismo resultado (plan o StateError idéntico)', () {
      final engine = TrainingProgramEngine();
      final profile = validTrainingProfile(
        daysPerWeek: 4,
      ).copyWith(id: 'client-determinism');
      final startDate = DateTime.utc(2025, 12, 20);
      final exercises = canonicalExercises();

      // Primera ejecución
      StateError? errA;
      var planAJson = const {};
      try {
        final planA = engine.generatePlan(
          planId: 'plan-determinism',
          clientId: 'client-determinism',
          planName: 'Plan Determinista',
          startDate: startDate,
          profile: profile,
          exercises: exercises,
        );
        planAJson = planA.toJson();
      } on StateError catch (e) {
        errA = e;
      }

      // Segunda ejecución (misma entrada)
      StateError? errB;
      var planBJson = const {};
      try {
        final planB = engine.generatePlan(
          planId: 'plan-determinism',
          clientId: 'client-determinism',
          planName: 'Plan Determinista',
          startDate: startDate,
          profile: profile,
          exercises: exercises,
        );
        planBJson = planB.toJson();
      } on StateError catch (e) {
        errB = e;
      }

      // Validación condicional del determinismo
      if (errA != null) {
        expect(errB, isNotNull, reason: 'Segunda ejecución debe fallar igual');
        expect(
          errB is StateError,
          isTrue,
          reason: 'Tipo de excepción debe ser StateError',
        );
        expect(
          errB!.message,
          equals(errA.message),
          reason: 'Mensaje de StateError debe ser idéntico',
        );
      } else {
        expect(errB, isNull, reason: 'Segunda ejecución no debe fallar');
        expect(
          planAJson,
          equals(planBJson),
          reason: 'Plan JSON debe ser idéntico con misma entrada',
        );
      }
    });
  });
}
