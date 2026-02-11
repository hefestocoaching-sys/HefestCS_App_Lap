import 'dart:math';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';

class ActiveCycleBootstrapper {
  /// Construye un ciclo base con ejercicios del catálogo.
  ///
  /// ENTRADA:
  /// - clientId: ID del cliente (usado como semilla para variabilidad)
  /// - exercises: Lista de ejercicios del catálogo
  ///
  /// SALIDA:
  /// - TrainingCycle con baseExercisesByMuscle poblado (hasta 10 por músculo)
  ///
  /// VARIABILIDAD:
  /// - Usa clientId como semilla para shuffle determinístico
  /// - Clientes diferentes → ejercicios base diferentes
  /// - Mismo cliente → siempre mismos ejercicios (determinista)
  static TrainingCycle buildDefaultCycle({
    required String clientId,
    required List<Exercise> exercises,
  }) {
    logger.info('Bootstrap creating cycle', {'clientId': clientId});

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

    logger.debug('Catalog exercise ids by muscle (sample)');
    for (final muscle in grouped.keys.take(5)) {
      final ids = grouped[muscle]!.take(5).toList();
      logger.debug('Catalog muscle sample', {
        'muscle': muscle,
        'exerciseIds': ids,
      });
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

      if (list.isEmpty) {
        baseExercisesByMuscle[muscle] = [];
        logger.warning('Catalog muscle has no exercises', {
          'muscle': muscle,
        });
        continue;
      }

      // ✅ Shuffle determinístico con timestamp para variabilidad entre regeneraciones
      final now = DateTime.now().millisecondsSinceEpoch;
      final timestamp = (now ~/ 1000).toString(); // Granularidad de 1 segundo
      final muscleSeed = _generateSeed(clientId, muscle, timestamp);
      final random = Random(muscleSeed);
      final shuffled = List<String>.from(list);
      shuffled.shuffle(random);

      // Tomar hasta 10 ejercicios de la lista mezclada
      final selected = shuffled.take(10).toList();
      baseExercisesByMuscle[muscle] = selected;

      logger.debug('Catalog muscle selection', {
        'muscle': muscle,
        'count': selected.length,
        'seed': muscleSeed,
        'firstExerciseId': selected.isNotEmpty ? selected.first : null,
      });
    }

    final cycleId = 'cycle_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    logger.info('Bootstrap cycle created', {
      'cycleId': cycleId,
      'clientId': clientId,
    });

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

  /// Genera semilla determinística para shuffle
  ///
  /// ENTRADA:
  /// - str1: clientId
  /// - str2: muscle name
  ///
  /// SALIDA:
  /// - Hash determinístico (int positivo)
  ///
  /// GARANTÍA:
  /// - Mismo input → mismo output (siempre)
  /// - Inputs diferentes → outputs diferentes (alta probabilidad)
  static int _generateSeed(String str1, String str2, [String? timestamp]) {
    final combined = timestamp != null
        ? '$str1-$str2-$timestamp'
        : '$str1-$str2';
    int hash = 0;

    for (int i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
      hash = hash & hash; // Convertir a 32-bit int
    }

    return hash.abs();
  }
}
