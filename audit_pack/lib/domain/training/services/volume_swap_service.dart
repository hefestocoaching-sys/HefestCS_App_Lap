import 'effective_sets_calculator.dart';
import 'exercise_contribution_catalog.dart';

/// Servicio que REDISTRIBUYE sets desde músculos no prioritarios hacia prioritarios.
///
/// Estrategia B2:
/// - DESPUÉS de que B1 haya reducido excesos de MRV
/// - Mover sets desde ejercicios que contribuyen a músculos NO prioritarios
/// - Hacia ejercicios que contribuyen a músculos prioritarios con déficit
/// - Mantener volumen total semanal aproximadamente estable
/// - Evitar planes "planos" donde todos los músculos reciben el mismo volumen
///
/// PRINCIPIO CLÍNICO:
/// El cuerpo tolera volumen distinto por músculo. Quitar sets sin reasignar
/// genera estímulo plano. El plan correcto quita estímulo donde sobra y
/// lo reasigna donde se busca adaptación.
class VolumeSwapService {
  /// Aplica swaps de volumen desde músculos no prioritarios a prioritarios.
  ///
  /// Un swap:
  /// 1. Reduce 1 set de un ejercicio que contribuye a músculo no prioritario
  /// 2. Añade 1 set a un ejercicio que contribuya a músculo prioritario con déficit
  /// 3. No viola MRV de ningún músculo
  ///
  /// Orden de prioridad para recibir sets:
  /// 1. Músculos primarios con mayor déficit (MRV - effective)
  /// 2. Músculos secundarios con déficit
  /// 3. Se detiene cuando no hay más donadores o receptores válidos
  static SwapResult apply({
    required dynamic plan,
    required Map<String, double> effectiveSets,
    required Map<String, double> mevByMuscle,
    required Map<String, double> mrvByMuscle,
    required Set<String> primaryMuscles,
    required Set<String> secondaryMuscles,
    required Set<String> tertiaryMuscles,
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
          for (final entry in exerciseById.entries) {
            if (entry.value == ex) {
              return setsById[entry.key]!;
            }
          }
          return getSets(ex);
        },
      );
    }

    var eff = Map<String, double>.from(effectiveSets);
    int swapsExecuted = 0;
    const maxSwaps = 100;

    // 1. Ordenar músculos prioritarios por déficit descendente
    final allPriorityMuscles = <String>{...primaryMuscles, ...secondaryMuscles};

    final priorityOrder = allPriorityMuscles.toList()
      ..sort((a, b) {
        // Priorizar primarios sobre secundarios
        final aIsPrimary = primaryMuscles.contains(a);
        final bIsPrimary = primaryMuscles.contains(b);
        if (aIsPrimary && !bIsPrimary) return -1;
        if (!aIsPrimary && bIsPrimary) return 1;

        // Dentro del mismo nivel, ordenar por déficit
        final da = (mrvByMuscle[a] ?? 0) - (eff[a] ?? 0);
        final db = (mrvByMuscle[b] ?? 0) - (eff[b] ?? 0);
        return db.compareTo(da);
      });

    for (final targetMuscle in priorityOrder) {
      if (swapsExecuted >= maxSwaps) break;

      final deficit =
          (mrvByMuscle[targetMuscle] ?? 0) - (eff[targetMuscle] ?? 0);

      // Solo hacer swap si hay déficit >= 1 set
      if (deficit < 1.0) continue;

      // 2. Buscar ejercicio donador (no prioritario, con >= 2 sets)
      String? donorId;
      double donorContribution = 0;

      for (final entry in exerciseById.entries) {
        final id = entry.key;
        final ex = entry.value;
        final key = exerciseKey(ex);
        final contrib = ExerciseContributionCatalog.getForExercise(key);
        final sets = setsById[id]!;

        if (sets < 2) continue; // Mínimo 1 set debe quedar

        // Buscar músculos NO prioritarios a los que contribuye este ejercicio
        for (final muscleEntry in contrib.entries) {
          final muscle = muscleEntry.key;
          final score = muscleEntry.value;

          // Skip si es músculo prioritario
          if (primaryMuscles.contains(muscle) ||
              secondaryMuscles.contains(muscle) ||
              tertiaryMuscles.contains(muscle)) {
            continue;
          }

          // Preferir donadores con mayor contribución a músculos no prioritarios
          if (score > donorContribution) {
            donorContribution = score;
            donorId = id;
          }
        }
      }

      if (donorId == null) continue;

      // 3. Buscar receptor (ejercicio con mejor contribución al músculo target)
      String? receiverId;
      double receiverContribution = 0;

      for (final entry in exerciseById.entries) {
        final id = entry.key;
        final ex = entry.value;
        final key = exerciseKey(ex);
        final contrib = ExerciseContributionCatalog.getForExercise(key);
        final score = contrib[targetMuscle] ?? 0;

        if (score > receiverContribution) {
          receiverContribution = score;
          receiverId = id;
        }
      }

      if (receiverId == null || receiverContribution <= 0) continue;

      // 4. Verificar que añadir 1 set no viole MRV del músculo target
      final newEffective = (eff[targetMuscle] ?? 0) + receiverContribution;
      final mrv = mrvByMuscle[targetMuscle] ?? double.infinity;

      if (newEffective > mrv) continue;

      // 5. Ejecutar swap
      setsById[donorId] = setsById[donorId]! - 1;
      setsById[receiverId] = setsById[receiverId]! + 1;

      // Actualizar effective sets localmente
      eff = effective();
      swapsExecuted++;
    }

    // Reconstruir plan con los sets actualizados
    final updatedPlan = _reconstructPlan(plan, exerciseById, setsById, setSets);

    return SwapResult(
      plan: updatedPlan,
      effectiveSets: eff,
      swapsExecuted: swapsExecuted,
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
        final updatedPrescriptions = session.prescriptions
            .map<dynamic>((prescription) {
              return updatedExercises[prescription] ?? prescription;
            })
            .toList()
            .cast<dynamic>();
        return session.copyWith(prescriptions: updatedPrescriptions);
      }).toList();
      return week.copyWith(sessions: updatedSessions);
    }).toList();

    return plan.copyWith(weeks: updatedWeeks);
  }
}

/// Resultado de la operación de swaps
class SwapResult {
  final dynamic plan;
  final Map<String, double> effectiveSets;
  final int swapsExecuted;

  SwapResult({
    required this.plan,
    required this.effectiveSets,
    required this.swapsExecuted,
  });
}
