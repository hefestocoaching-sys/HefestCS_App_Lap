// lib/domain/training_v3/engines/ordering_engine.dart

/// Motor de ordenamiento científico de ejercicios
///
/// Implementa las reglas científicas de la Semana 5 (Imagen 60-63):
/// - Compounds grandes primero (squat, deadlift, bench)
/// - Compounds auxiliares segundo (rows, overhead press)
/// - Aislamiento primario tercero (curls, extensions)
/// - Aislamiento secundario último (calves, abs)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5, Imagen 60-63: Orden óptimo de ejercicios
/// - Regla: Ejercicios que requieren más técnica/fuerza primero
/// - Fatiga acumulada reduce rendimiento en ejercicios tardíos
///
/// REFERENCIAS:
/// - Simão et al. (2012): Exercise order effects
/// - Spiering et al. (2008): Influence of exercise order
///
/// Versión: 1.0.0
class OrderingEngine {
  /// Ordena ejercicios científicamente
  ///
  /// ALGORITMO:
  /// 1. Clasificar por categoría (compound grande/auxiliar/isolation)
  /// 2. Dentro de cada categoría, ordenar por fatiga sistémica (mayor primero)
  /// 3. Retornar lista ordenada
  ///
  /// PARÁMETROS:
  /// - [exercises]: Lista de IDs de ejercicios a ordenar
  /// - [exerciseData]: Metadata de ejercicios (tipo, fatiga, etc.)
  ///
  /// RETORNA:
  /// - List<String>: IDs ordenados científicamente
  static List<String> orderExercises({
    required List<String> exercises,
    required Map<String, Map<String, dynamic>> exerciseData,
  }) {
    // PASO 1: Clasificar por categoría
    final bigCompounds = <String>[];
    final auxCompounds = <String>[];
    final primaryIsolation = <String>[];
    final secondaryIsolation = <String>[];

    for (final exerciseId in exercises) {
      final data = exerciseData[exerciseId];
      if (data == null) continue;

      final category = _categorizeExercise(data);

      switch (category) {
        case 'big_compound':
          bigCompounds.add(exerciseId);
          break;
        case 'aux_compound':
          auxCompounds.add(exerciseId);
          break;
        case 'primary_isolation':
          primaryIsolation.add(exerciseId);
          break;
        case 'secondary_isolation':
          secondaryIsolation.add(exerciseId);
          break;
      }
    }

    // PASO 2: Dentro de cada categoría, ordenar por fatiga
    _sortByFatigue(bigCompounds, exerciseData);
    _sortByFatigue(auxCompounds, exerciseData);
    _sortByFatigue(primaryIsolation, exerciseData);
    _sortByFatigue(secondaryIsolation, exerciseData);

    // PASO 3: Concatenar en orden científico
    return [
      ...bigCompounds,
      ...auxCompounds,
      ...primaryIsolation,
      ...secondaryIsolation,
    ];
  }

  /// Categoriza un ejercicio según criterios científicos
  ///
  /// FUENTE: Semana 5, Imagen 60-63
  ///
  /// CATEGORÍAS:
  /// - big_compound: Squat, deadlift, bench press (alta fatiga, multi-articular)
  /// - aux_compound: Rows, overhead press, lunges (moderada fatiga)
  /// - primary_isolation: Curls, extensions, lateral raises
  /// - secondary_isolation: Calves, abs, forearms
  static String _categorizeExercise(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final fatigue = (data['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
    final primaryMuscles =
        (data['primary_muscles'] as List?)?.cast<String>() ?? [];

    if (type == 'compound') {
      // Big compounds: fatiga alta (>7)
      if (fatigue >= 7.0) {
        return 'big_compound';
      } else {
        return 'aux_compound';
      }
    } else {
      // Isolation: separar por grupo muscular
      if (_isSecondaryMuscle(primaryMuscles)) {
        return 'secondary_isolation';
      } else {
        return 'primary_isolation';
      }
    }
  }

  /// Verifica si es músculo secundario (calves, abs, forearms)
  static bool _isSecondaryMuscle(List<String> muscles) {
    final secondary = ['calves', 'abs', 'forearms'];
    return muscles.any((m) => secondary.contains(m));
  }

  /// Ordena ejercicios por fatiga (mayor primero)
  static void _sortByFatigue(
    List<String> exercises,
    Map<String, Map<String, dynamic>> exerciseData,
  ) {
    exercises.sort((a, b) {
      final fatigueA =
          (exerciseData[a]?['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
      final fatigueB =
          (exerciseData[b]?['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
      return fatigueB.compareTo(fatigueA); // Descendente
    });
  }

  /// Valida que el orden sea científicamente correcto
  ///
  /// REGLA: Compounds deben estar antes de isolation
  static bool isOrderValid({
    required List<String> orderedExercises,
    required Map<String, Map<String, dynamic>> exerciseData,
  }) {
    bool seenIsolation = false;

    for (final exerciseId in orderedExercises) {
      final type = exerciseData[exerciseId]?['type'] as String?;

      if (type == 'isolation') {
        seenIsolation = true;
      } else if (type == 'compound' && seenIsolation) {
        // ERROR: Compound después de isolation
        return false;
      }
    }

    return true;
  }

  /// Obtiene índice de prioridad de un ejercicio (menor = primero)
  ///
  /// USADO PARA: Sorting custom
  static int getPriorityIndex(Map<String, dynamic> exerciseData) {
    final category = _categorizeExercise(exerciseData);

    switch (category) {
      case 'big_compound':
        return 1;
      case 'aux_compound':
        return 2;
      case 'primary_isolation':
        return 3;
      case 'secondary_isolation':
        return 4;
      default:
        return 5;
    }
  }
}
