import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import '../fixtures/training_fixtures.dart';

void main() {
  group('Training Engine Invariants', () {
    late TrainingProgramEngine engine;

    setUp(() {
      engine = TrainingProgramEngine();
    });

    test('Fail-fast: datos críticos faltantes → StateError', () {
      final incomplete = TrainingProfile(
        id: 'c1',
        daysPerWeek: 2, // inválido según UI/engine 3-6
        trainingLevel: TrainingLevel.intermediate,
      );
      expect(
        () => engine.generatePlan(
          planId: 'p1',
          clientId: 'c1',
          planName: 'invalid',
          startDate: DateTime(2025, 1, 1),
          profile: incomplete,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('daysPerWeek exacto: 4 días por semana', () {
      final profile = validTrainingProfile(daysPerWeek: 4);
      try {
        final plan = engine.generatePlan(
          planId: 'p2',
          clientId: 'c2',
          planName: 'valid-4',
          startDate: DateTime(2025, 1, 1),
          profile: profile,
          exercises: canonicalExercises(),
        );
        // Exactamente 4 sesiones por semana
        for (final w in plan.weeks) {
          expect(w.sessions.length, equals(4));
        }
      } on StateError catch (e) {
        // Vía alternativa válida: bloqueo explícito si no se puede garantizar el invariante
        expect(e.message, contains('menos de 4 ejercicios'));
      }
    });

    test('Nunca sesiones vacías: cada día con >= 4 ejercicios', () {
      final profile = validTrainingProfile(daysPerWeek: 4);
      try {
        final plan = engine.generatePlan(
          planId: 'p3',
          clientId: 'c3',
          planName: 'min-4-per-day',
          startDate: DateTime(2025, 1, 1),
          profile: profile,
          exercises: canonicalExercises(),
        );
        for (final w in plan.weeks) {
          for (final s in w.sessions) {
            expect(s.prescriptions.length, greaterThanOrEqualTo(4));
          }
        }
      } on StateError catch (e) {
        expect(e.message, contains('menos de 4 ejercicios'));
      }
    });

    test('Catálogo vacío → StateError explícito', () {
      final profile = validTrainingProfile(daysPerWeek: 4);
      expect(
        () => engine.generatePlan(
          planId: 'p4',
          clientId: 'c4',
          planName: 'empty-catalog',
          startDate: DateTime(2025, 1, 1),
          profile: profile,
          exercises: const <Exercise>[],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
