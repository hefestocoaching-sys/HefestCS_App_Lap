import 'dart:math';

import '../entities/exercise.dart';

class ExerciseSelector {
  /// Selecciona ejercicios para un músculo con variabilidad determinística
  ///
  /// PARÁMETROS:
  /// - all: Lista completa de ejercicios
  /// - muscleKey: Músculo objetivo (ej: 'chest', 'lats')
  /// - limit: Máximo de ejercicios a retornar
  /// - clientSeed: Semilla para variabilidad (OPCIONAL)
  ///
  /// COMPORTAMIENTO:
  /// - Si clientSeed = null: orden alfabético (legacy, retrocompatible)
  /// - Si clientSeed != null: orden basado en hash del clientId
  ///
  /// GARANTÍA DE DETERMINISMO:
  /// - Mismo clientSeed + muscleKey → siempre mismo orden
  /// - Clientes diferentes → orden diferente
  static List<Exercise> byMuscle(
    List<Exercise> all,
    String muscleKey, {
    int limit = 6,
    String? clientSeed,
  }) {
    final filtered = all.where((e) => e.matchesMuscle(muscleKey)).toList();
    if (filtered.isEmpty) return [];

    // NUEVA LÓGICA: Ordenar con variabilidad si hay clientSeed
    if (clientSeed != null && clientSeed.isNotEmpty) {
      // Asignar número aleatorio determinístico a cada ejercicio
      final withRandom = filtered.map((ex) {
        final exSeed = _generateSeed('$clientSeed-$muscleKey', ex.id);
        final exRandom = Random(exSeed).nextDouble();
        return _ExerciseWithRandom(ex, exRandom);
      }).toList()..sort((a, b) => a.randomValue.compareTo(b.randomValue));

      return withRandom.map((e) => e.exercise).take(limit).toList();
    }

    // LÓGICA LEGACY: Orden alfabético (sin clientSeed)
    filtered.sort((a, b) {
      final byId = a.id.compareTo(b.id);
      if (byId != 0) return byId;
      return a.name.compareTo(b.name);
    });

    return filtered.take(limit).toList();
  }

  /// Genera semilla determinística a partir de strings
  ///
  /// ALGORITMO: Hash simple pero determinístico
  /// - Mismo input → mismo output (siempre)
  /// - Inputs diferentes → outputs diferentes (alta probabilidad)
  static int _generateSeed(String str1, String str2) {
    final combined = '$str1-$str2';
    int hash = 0;

    for (int i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
      hash = hash & hash; // Convertir a 32-bit int
    }

    return hash.abs();
  }
}

/// Helper interno para almacenar ejercicio con valor random
class _ExerciseWithRandom {
  final Exercise exercise;
  final double randomValue;

  const _ExerciseWithRandom(this.exercise, this.randomValue);
}
