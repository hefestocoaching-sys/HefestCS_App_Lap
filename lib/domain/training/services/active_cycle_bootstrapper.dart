import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';

/// Servicio para crear un ciclo base automáticamente cuando el cliente no tiene ciclos.
///
/// RESPONSABILIDAD:
/// - Generar TrainingCycle inicial con ejercicios del catálogo
/// - Agrupar ejercicios por músculo primario (ya normalizado)
/// - Limitar cantidad de ejercicios por músculo para evitar payload gigante
class ActiveCycleBootstrapper {
  /// Construye un ciclo base con ejercicios del catálogo.
  ///
  /// ENTRADA:
  /// - clientId: ID del cliente
  /// - exercises: Lista de ejercicios del catálogo (normalizado V3)
  ///
  /// SALIDA:
  /// - TrainingCycle con baseExercisesByMuscle poblado
  ///
  /// LÓGICA:
  /// - Agrupa por primaryMuscles[0] (ya canónico)
  /// - Limita a 10 ejercicios por músculo
  /// - Ordena IDs para determinismo
  static TrainingCycle buildDefaultCycle({
    required String clientId,
    required List<Exercise> exercises,
  }) {
    // Agrupar ejercicios por músculo primario (YA normalizado)
    final Map<String, List<String>> grouped = {};

    for (final ex in exercises) {
      final muscle = ex.primaryMuscles.isNotEmpty
          ? ex.primaryMuscles.first
          : ex.muscleKey;

      if (muscle.isEmpty) continue;

      grouped.putIfAbsent(muscle, () => <String>[]);
      grouped[muscle]!.add(ex.id);
    }

    // 🔴 CLAVE: forzar presencia de las 14 keys canónicas
    const canonicalMuscles = [
      'chest',
      'lats',
      'upper_back',
      'traps',
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
      'biceps',
      'triceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
    ];

    final Map<String, List<String>> baseExercisesByMuscle = {};

    for (final muscle in canonicalMuscles) {
      final list = grouped[muscle] ?? [];

      // tomar hasta 10 ejercicios por músculo
      baseExercisesByMuscle[muscle] = list.take(10).toList();
    }

    final cycleId = 'cycle_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    debugPrint(
      '🧩 [BootstrapCycle] created cycle $cycleId with muscles=${baseExercisesByMuscle.keys} '
      'counts=${baseExercisesByMuscle.map((k, v) => MapEntry(k, v.length))}',
    );

    return TrainingCycle(
      cycleId: cycleId,
      startDate: now,
      endDate: null,
      goal: 'hipertrofia_general',
      priorityMuscles: const [],
      splitType: 'torso_pierna_4d',
      baseExercisesByMuscle: baseExercisesByMuscle,
      phaseState: 'VME',
      currentWeek: 1,
      createdAt: now,
    );
  }
}
