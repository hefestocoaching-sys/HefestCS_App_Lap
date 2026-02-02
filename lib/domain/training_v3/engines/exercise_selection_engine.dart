// lib/domain/training_v3/engines/exercise_selection_engine.dart

/// Motor de selección inteligente de ejercicios
///
/// Implementa las reglas científicas de la Semana 5 (26 imágenes):
/// - 6 criterios de scoring: ROM, ángulo, estabilidad, curva de resistencia, fatiga, lesión
/// - Priorizar compounds sobre isolation
/// - Considerar equipamiento disponible
/// - Evitar ejercicios contraindicados por lesiones
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5, Imagen 44-49: Criterios de selección
/// - Semana 5, Imagen 50-55: Scoring de ejercicios
/// - Semana 5, Imagen 56-59: Priorización compound/isolation
///
/// REFERENCIAS:
/// - Schoenfeld (2010): Exercise selection for muscle hypertrophy
/// - Contreras et al. (2020): Exercise variation and muscle activation
///
/// Versión: 1.0.0
class ExerciseSelectionEngine {
  /// Selecciona los mejores ejercicios para un músculo
  ///
  /// ALGORITMO:
  /// 1. Filtrar por equipamiento disponible
  /// 2. Filtrar por historial de lesiones
  /// 3. Scoring con 6 criterios científicos
  /// 4. Ordenar por score descendente
  /// 5. Balancear compounds/isolation
  ///
  /// PARÁMETROS:
  /// - [targetMuscle]: Músculo objetivo ('chest', 'quads', etc.)
  /// - [availableExercises]: Pool de ejercicios disponibles
  /// - [availableEquipment]: Equipamiento disponible
  /// - [injuryHistory]: Historial de lesiones (articulación → descripción)
  /// - [targetExerciseCount]: Número de ejercicios a seleccionar
  ///
  /// RETORNA:
  /// - List<String>: IDs de ejercicios seleccionados
  static List<String> selectExercises({
    required String targetMuscle,
    required Map<String, Map<String, dynamic>> availableExercises,
    required List<String> availableEquipment,
    required Map<String, String> injuryHistory,
    required int targetExerciseCount,
  }) {
    // PASO 1: Filtrar por músculo y equipamiento
    final candidateExercises = availableExercises.entries
        .where((e) => _isExerciseForMuscle(e.value, targetMuscle))
        .where((e) => _hasRequiredEquipment(e.value, availableEquipment))
        .toList();

    // PASO 2: Filtrar por lesiones
    final safeExercises = candidateExercises
        .where((e) => !_isContraindicatedByInjury(e.value, injuryHistory))
        .toList();

    // PASO 3: Scoring científico (6 criterios)
    final scoredExercises = safeExercises.map((e) {
      final score = _calculateExerciseScore(e.value, targetMuscle);
      return {'id': e.key, 'score': score, 'data': e.value};
    }).toList();

    // PASO 4: Ordenar por score
    scoredExercises.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // PASO 5: Balancear compounds/isolation
    final selected = _balanceCompoundsAndIsolation(
      scoredExercises,
      targetExerciseCount,
    );

    return selected.map((e) => e['id'] as String).toList();
  }

  /// Calcula score científico del ejercicio (0.0-10.0)
  ///
  /// FUENTE: Semana 5, Imagen 50-55
  ///
  /// CRITERIOS (peso total = 100%):
  /// 1. ROM (25%): Mayor ROM = mejor hipertrofia
  /// 2. Ángulo (20%): Ángulo óptimo de tracción
  /// 3. Estabilidad (15%): Menos estabilización = más foco
  /// 4. Curva de resistencia (15%): Tensión constante
  /// 5. Fatiga (15%): Menor fatiga sistémica = más sets
  /// 6. Riesgo de lesión (10%): Seguridad
  static double _calculateExerciseScore(
    Map<String, dynamic> exercise,
    String targetMuscle,
  ) {
    double score = 0.0;

    // Criterio 1: ROM (0-10, peso 25%)
    final rom = (exercise['rom'] as num?)?.toDouble() ?? 5.0;
    score += rom * 0.25;

    // Criterio 2: Ángulo (0-10, peso 20%)
    final angle = (exercise['angle_quality'] as num?)?.toDouble() ?? 5.0;
    score += angle * 0.20;

    // Criterio 3: Estabilidad (0-10, peso 15%)
    final stability =
        (exercise['stability_requirement'] as num?)?.toDouble() ?? 5.0;
    // Invertir: menor estabilidad = mejor (más foco en músculo)
    score += (10 - stability) * 0.15;

    // Criterio 4: Curva de resistencia (0-10, peso 15%)
    final resistance =
        (exercise['resistance_curve'] as num?)?.toDouble() ?? 5.0;
    score += resistance * 0.15;

    // Criterio 5: Fatiga (0-10, peso 15%)
    final fatigue = (exercise['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
    // Invertir: menor fatiga = mejor
    score += (10 - fatigue) * 0.15;

    // Criterio 6: Riesgo lesión (0-10, peso 10%)
    final injury = (exercise['injury_risk'] as num?)?.toDouble() ?? 5.0;
    // Invertir: menor riesgo = mejor
    score += (10 - injury) * 0.10;

    return score;
  }

  /// Balancea compounds vs isolation (2:1 ratio)
  ///
  /// FUENTE: Semana 5, Imagen 56-59
  ///
  /// REGLA: 2/3 compounds, 1/3 isolation
  static List<Map<String, dynamic>> _balanceCompoundsAndIsolation(
    List<Map<String, dynamic>> scoredExercises,
    int targetCount,
  ) {
    final compounds = scoredExercises
        .where((e) => (e['data'] as Map)['type'] == 'compound')
        .toList();
    final isolation = scoredExercises
        .where((e) => (e['data'] as Map)['type'] == 'isolation')
        .toList();

    // Calcular proporción
    final compoundCount = ((targetCount * 2) / 3).round();
    final isolationCount = targetCount - compoundCount;

    // Seleccionar mejores
    final selectedCompounds = compounds.take(compoundCount).toList();
    final selectedIsolation = isolation.take(isolationCount).toList();

    return [...selectedCompounds, ...selectedIsolation];
  }

  /// Verifica si el ejercicio entrena el músculo objetivo
  static bool _isExerciseForMuscle(
    Map<String, dynamic> exercise,
    String muscle,
  ) {
    final primaryMuscles =
        (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    final secondaryMuscles =
        (exercise['secondary_muscles'] as List?)?.cast<String>() ?? [];

    return primaryMuscles.contains(muscle) || secondaryMuscles.contains(muscle);
  }

  /// Verifica si tiene el equipamiento necesario
  static bool _hasRequiredEquipment(
    Map<String, dynamic> exercise,
    List<String> available,
  ) {
    final required = (exercise['equipment'] as List?)?.cast<String>() ?? [];
    return required.every((eq) => available.contains(eq));
  }

  /// Verifica si el ejercicio está contraindicado por lesión
  ///
  /// EJEMPLO:
  /// - Lesión de hombro → evitar overhead press
  /// - Lesión de rodilla → evitar squats profundos
  static bool _isContraindicatedByInjury(
    Map<String, dynamic> exercise,
    Map<String, String> injuries,
  ) {
    if (injuries.isEmpty) return false;

    final stressedJoints =
        (exercise['stressed_joints'] as List?)?.cast<String>() ?? [];

    // Si el ejercicio estresa una articulación lesionada, contraindicar
    for (final joint in stressedJoints) {
      if (injuries.containsKey(joint)) {
        return true;
      }
    }

    return false;
  }

  /// Obtiene variaciones de un ejercicio
  ///
  /// USADO PARA: Exercise swap cuando hay fatiga o estancamiento
  static List<String> getExerciseVariations(
    String exerciseId,
    Map<String, Map<String, dynamic>> exerciseDatabase,
  ) {
    final baseExercise = exerciseDatabase[exerciseId];
    if (baseExercise == null) return [];

    final baseMuscles =
        (baseExercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    final baseType = baseExercise['type'] as String?;

    // Buscar ejercicios similares (mismo músculo + tipo)
    return exerciseDatabase.entries
        .where((e) => e.key != exerciseId)
        .where((e) => _hasSameMuscles(e.value, baseMuscles))
        .where((e) => e.value['type'] == baseType)
        .map((e) => e.key)
        .take(3)
        .toList();
  }

  static bool _hasSameMuscles(
    Map<String, dynamic> exercise,
    List<String> targetMuscles,
  ) {
    final muscles =
        (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    return muscles.any((m) => targetMuscles.contains(m));
  }
}
