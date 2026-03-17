import 'exercise_contribution_catalog.dart';

class EffectiveSetsCalculator {
  // ejercicioKeyExtractor: función para obtener la key canónica del ejercicio (id o name normalized)
  // setsExtractor: función para obtener el número de sets del ejercicio dentro del plan

  static Map<String, double> compute({
    required Iterable<dynamic> allExercisesInPlan,
    required String Function(dynamic ex) exerciseKeyExtractor,
    required double Function(dynamic ex) setsExtractor,
  }) {
    final totals = <String, double>{};

    for (final ex in allExercisesInPlan) {
      final key = exerciseKeyExtractor(ex);
      final sets = setsExtractor(ex);

      final contrib = ExerciseContributionCatalog.getForExercise(key);

      // Si no hay contribución catalogada, asumimos que no afecta (conservador) y NO rompe.
      for (final entry in contrib.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0.0) + sets * entry.value;
      }
    }

    return totals;
  }
}
