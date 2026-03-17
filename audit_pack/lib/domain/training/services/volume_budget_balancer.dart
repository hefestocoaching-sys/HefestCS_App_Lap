import 'effective_sets_calculator.dart';
import 'exercise_contribution_catalog.dart';

class VolumeBudgetBalancer {
  // Reduce sets en ejercicios que contribuyen al músculo excedido.
  // Estrategia B1 (sin swaps):
  // 1) Calcular effectiveSets por músculo.
  // 2) Mientras exista músculo con exceso:
  //    - seleccionar el músculo más excedido (exceso = effective - MRV)
  //    - encontrar ejercicio con mayor contribución a ese músculo y que sea "reducible"
  //    - reducir 1 set y recalcular
  //
  // Para manejar inmutabilidad, trabajamos con mapas de ID → sets y reconstruimos al final.

  static BalancerResult balance({
    required dynamic plan,
    required Map<String, double> mrvByMuscle,
    required Map<String, double> mevByMuscle,
    required String Function(dynamic ex) exerciseKey,
    required double Function(dynamic ex) getSets,
    required dynamic Function(dynamic ex, double newSets) setSets,
    required Iterable<dynamic> Function(dynamic plan) allExercises,
  }) {
    // Construir mapa de ejercicio ID → objeto para reconstrucción inmutable
    final exercises = allExercises(plan).toList();
    final exerciseById = <String, dynamic>{};
    final setsById = <String, double>{};

    for (final ex in exercises) {
      // Usar un ID único: sessionId + exerciseCode + índice si hay duplicados
      final id = '${ex.sessionId}_${exerciseKey(ex)}';
      var uniqueId = id;
      var counter = 0;
      while (exerciseById.containsKey(uniqueId)) {
        counter++;
        uniqueId = '${id}_$counter';
      }
      exerciseById[uniqueId] = ex;
      setsById[uniqueId] = getSets(ex);
    }

    // Helper: calcula effective sets con los sets actuales
    Map<String, double> effective() {
      return EffectiveSetsCalculator.compute(
        allExercisesInPlan: exerciseById.values,
        exerciseKeyExtractor: exerciseKey,
        setsExtractor: (ex) {
          // Buscar el ID y retornar los sets actualizados
          for (final entry in exerciseById.entries) {
            if (entry.value == ex) {
              return setsById[entry.key]!;
            }
          }
          return getSets(ex);
        },
      );
    }

    var eff = effective();

    // Iteraciones máximas para evitar loops infinitos
    const maxIterations = 500;
    var iter = 0;

    while (iter < maxIterations) {
      iter++;

      // Encuentra músculo más excedido
      String? worst;
      double worstExcess = 0.0;

      for (final e in eff.entries) {
        final m = e.key;
        final mrv = mrvByMuscle[m];
        if (mrv == null) continue;
        final excess = e.value - mrv;
        if (excess > worstExcess) {
          worstExcess = excess;
          worst = m;
        }
      }

      // Si no hay exceso, terminado
      if (worst == null || worstExcess <= 0.0) {
        break;
      }

      // Encuentra el mejor candidato a reducir
      String? bestExerciseId;
      double bestContribution = 0.0;

      for (final entry in exerciseById.entries) {
        final id = entry.key;
        final ex = entry.value;
        final key = exerciseKey(ex);
        final contrib = _getContribution(key, worst);
        if (contrib <= 0) continue;

        final sets = setsById[id]!;
        if (sets <= 1) continue; // No bajar de 1 set

        if (contrib > bestContribution) {
          bestContribution = contrib;
          bestExerciseId = id;
        }
      }

      // Si no hay candidato, no podemos corregir más
      if (bestExerciseId == null) {
        return BalancerResult(
          plan: _reconstructPlan(plan, exerciseById, setsById, setSets),
          effectiveSets: eff,
          iterations: iter,
          blocked: true,
        );
      }

      // Reduce 1 set
      final currentSets = setsById[bestExerciseId] ?? 0;
      if (currentSets > 0) {
        setsById[bestExerciseId] = currentSets - 1;
      }

      // Recalcula effective sets
      eff = effective();
    }

    // Reconstruir plan con los sets actualizados
    final updatedPlan = _reconstructPlan(plan, exerciseById, setsById, setSets);

    return BalancerResult(
      plan: updatedPlan,
      effectiveSets: eff,
      iterations: iter,
    );
  }

  /// Reconstruye el plan inmutable aplicando los sets actualizados
  static dynamic _reconstructPlan(
    dynamic plan,
    Map<String, dynamic> exerciseById,
    Map<String, double> setsById,
    dynamic Function(dynamic ex, double newSets) setSets,
  ) {
    // Construir mapa de ejercicio original → ejercicio actualizado
    final updatedExercises = <dynamic, dynamic>{};
    for (final entry in exerciseById.entries) {
      final original = entry.value;
      final newSets = setsById[entry.key]!;
      updatedExercises[original] = setSets(original, newSets);
    }

    // Reconstruir weeks con las prescripciones actualizadas
    final updatedWeeks = plan.weeks.map((week) {
      final updatedSessions = week.sessions.map((session) {
        final updatedPrescriptions = session.prescriptions.map((prescription) {
          return updatedExercises[prescription] ?? prescription;
        }).toList();
        return session.copyWith(prescriptions: updatedPrescriptions);
      }).toList();
      return week.copyWith(sessions: updatedSessions);
    }).toList();

    return plan.copyWith(weeks: updatedWeeks);
  }

  static double _getContribution(String exerciseKey, String muscleKey) {
    final map = ExerciseContributionCatalog.getForExercise(exerciseKey);
    return map[muscleKey] ?? 0.0;
  }
}

class BalancerResult {
  final dynamic plan;
  final Map<String, double> effectiveSets;
  final int iterations;
  final bool blocked;

  BalancerResult({
    required this.plan,
    required this.effectiveSets,
    required this.iterations,
    this.blocked = false,
  });
}
