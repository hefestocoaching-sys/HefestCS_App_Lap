// lib/domain/training_v3/repositories/exercise_database_repository.dart

/// Repositorio de acceso a la base de datos de ejercicios
///
/// Proporciona acceso a:
/// - Catálogo completo de ejercicios (exercise_catalog_gym.json)
/// - Filtrado por músculo, equipamiento, tipo
/// - Búsqueda por ID
/// - Variaciones de ejercicios
///
/// NOTA: Este es un repositorio de lectura (read-only).
/// Los ejercicios se almacenan en JSON estático.
///
/// Versión: 1.0.0
class ExerciseDatabaseRepository {
  /// Cache en memoria del catálogo de ejercicios
  static Map<String, Map<String, dynamic>>? _exerciseCache;

  /// Obtiene todos los ejercicios del catálogo
  ///
  /// RETORNA:
  /// - Map&lt;exerciseId, exerciseData&gt;
  static Future<Map<String, Map<String, dynamic>>> getAllExercises() async {
    // Si ya está en cache, retornar
    if (_exerciseCache != null) {
      return _exerciseCache!;
    }

    // PLACEHOLDER: Cargar desde JSON
    // En producción, esto cargará desde assets/data/exercise_catalog_gym.json

    // Mock data por ahora
    _exerciseCache = {
      'bench_press': {
        'id': 'bench_press',
        'name': 'Bench Press',
        'type': 'compound',
        'primary_muscles': ['chest'],
        'secondary_muscles': ['triceps', 'shoulders'],
        'equipment': ['barbell', 'bench'],
        'movement_pattern': 'horizontal_push',
        'rom': 8.0,
        'angle_quality': 9.0,
        'stability_requirement': 6.0,
        'resistance_curve': 7.0,
        'systemic_fatigue': 8.0,
        'injury_risk': 5.0,
        'stressed_joints': ['shoulder', 'elbow'],
      },
      'squat': {
        'id': 'squat',
        'name': 'Back Squat',
        'type': 'compound',
        'primary_muscles': ['quads'],
        'secondary_muscles': ['glutes', 'hamstrings'],
        'equipment': ['barbell', 'rack'],
        'movement_pattern': 'squat',
        'rom': 9.0,
        'angle_quality': 9.0,
        'stability_requirement': 8.0,
        'resistance_curve': 8.0,
        'systemic_fatigue': 9.0,
        'injury_risk': 6.0,
        'stressed_joints': ['knee', 'hip', 'ankle'],
      },
      'deadlift': {
        'id': 'deadlift',
        'name': 'Conventional Deadlift',
        'type': 'compound',
        'primary_muscles': ['back'],
        'secondary_muscles': ['hamstrings', 'glutes'],
        'equipment': ['barbell'],
        'movement_pattern': 'hinge',
        'rom': 8.0,
        'angle_quality': 9.0,
        'stability_requirement': 7.0,
        'resistance_curve': 9.0,
        'systemic_fatigue': 10.0,
        'injury_risk': 7.0,
        'stressed_joints': ['lower_back', 'hip'],
      },
      'pull_up': {
        'id': 'pull_up',
        'name': 'Pull-Up',
        'type': 'compound',
        'primary_muscles': ['back'],
        'secondary_muscles': ['biceps'],
        'equipment': ['pull_up_bar'],
        'movement_pattern': 'vertical_pull',
        'rom': 9.0,
        'angle_quality': 10.0,
        'stability_requirement': 5.0,
        'resistance_curve': 7.0,
        'systemic_fatigue': 6.0,
        'injury_risk': 3.0,
        'stressed_joints': ['shoulder', 'elbow'],
      },
      'overhead_press': {
        'id': 'overhead_press',
        'name': 'Overhead Press',
        'type': 'compound',
        'primary_muscles': ['shoulders'],
        'secondary_muscles': ['triceps'],
        'equipment': ['barbell'],
        'movement_pattern': 'vertical_push',
        'rom': 8.0,
        'angle_quality': 9.0,
        'stability_requirement': 7.0,
        'resistance_curve': 7.0,
        'systemic_fatigue': 7.0,
        'injury_risk': 6.0,
        'stressed_joints': ['shoulder'],
      },
      'bicep_curl': {
        'id': 'bicep_curl',
        'name': 'Barbell Curl',
        'type': 'isolation',
        'primary_muscles': ['biceps'],
        'secondary_muscles': [],
        'equipment': ['barbell'],
        'movement_pattern': 'elbow_flexion',
        'rom': 7.0,
        'angle_quality': 7.0,
        'stability_requirement': 3.0,
        'resistance_curve': 6.0,
        'systemic_fatigue': 2.0,
        'injury_risk': 2.0,
        'stressed_joints': ['elbow'],
      },
      'tricep_extension': {
        'id': 'tricep_extension',
        'name': 'Overhead Tricep Extension',
        'type': 'isolation',
        'primary_muscles': ['triceps'],
        'secondary_muscles': [],
        'equipment': ['dumbbell'],
        'movement_pattern': 'elbow_extension',
        'rom': 8.0,
        'angle_quality': 7.0,
        'stability_requirement': 4.0,
        'resistance_curve': 7.0,
        'systemic_fatigue': 2.0,
        'injury_risk': 3.0,
        'stressed_joints': ['elbow', 'shoulder'],
      },
      'leg_curl': {
        'id': 'leg_curl',
        'name': 'Lying Leg Curl',
        'type': 'isolation',
        'primary_muscles': ['hamstrings'],
        'secondary_muscles': [],
        'equipment': ['machine'],
        'movement_pattern': 'knee_flexion',
        'rom': 8.0,
        'angle_quality': 8.0,
        'stability_requirement': 2.0,
        'resistance_curve': 9.0,
        'systemic_fatigue': 2.0,
        'injury_risk': 2.0,
        'stressed_joints': ['knee'],
      },
      'calf_raise': {
        'id': 'calf_raise',
        'name': 'Standing Calf Raise',
        'type': 'isolation',
        'primary_muscles': ['calves'],
        'secondary_muscles': [],
        'equipment': ['machine'],
        'movement_pattern': 'ankle_plantarflexion',
        'rom': 7.0,
        'angle_quality': 8.0,
        'stability_requirement': 3.0,
        'resistance_curve': 8.0,
        'systemic_fatigue': 1.0,
        'injury_risk': 1.0,
        'stressed_joints': ['ankle'],
      },
    };

    return _exerciseCache!;
  }

  /// Obtiene un ejercicio por ID
  static Future<Map<String, dynamic>?> getExerciseById(
    String exerciseId,
  ) async {
    final exercises = await getAllExercises();
    return exercises[exerciseId];
  }

  /// Filtra ejercicios por músculo objetivo
  static Future<List<Map<String, dynamic>>> getExercisesByMuscle(
    String muscle,
  ) async {
    final exercises = await getAllExercises();

    return exercises.values.where((exercise) {
      final primaryMuscles =
          (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
      final secondaryMuscles =
          (exercise['secondary_muscles'] as List?)?.cast<String>() ?? [];
      return primaryMuscles.contains(muscle) ||
          secondaryMuscles.contains(muscle);
    }).toList();
  }

  /// Filtra ejercicios por equipamiento disponible
  static Future<List<Map<String, dynamic>>> getExercisesByEquipment(
    List<String> availableEquipment,
  ) async {
    final exercises = await getAllExercises();

    return exercises.values.where((exercise) {
      final required = (exercise['equipment'] as List?)?.cast<String>() ?? [];
      return required.every((eq) => availableEquipment.contains(eq));
    }).toList();
  }

  /// Filtra ejercicios por tipo (compound/isolation)
  static Future<List<Map<String, dynamic>>> getExercisesByType(
    String type,
  ) async {
    final exercises = await getAllExercises();

    return exercises.values
        .where((exercise) => exercise['type'] == type)
        .toList();
  }

  /// Obtiene ejercicios compuestos para un músculo
  static Future<List<Map<String, dynamic>>> getCompoundExercisesForMuscle(
    String muscle,
  ) async {
    final exercises = await getAllExercises();

    return exercises.values.where((exercise) {
      final primaryMuscles =
          (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
      return exercise['type'] == 'compound' && primaryMuscles.contains(muscle);
    }).toList();
  }

  /// Obtiene ejercicios de aislamiento para un músculo
  static Future<List<Map<String, dynamic>>> getIsolationExercisesForMuscle(
    String muscle,
  ) async {
    final exercises = await getAllExercises();

    return exercises.values.where((exercise) {
      final primaryMuscles =
          (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
      return exercise['type'] == 'isolation' && primaryMuscles.contains(muscle);
    }).toList();
  }

  /// Busca ejercicios seguros (evitando articulaciones lesionadas)
  static Future<List<Map<String, dynamic>>> getSafeExercises({
    required String muscle,
    required Map<String, String> injuryHistory,
  }) async {
    final muscleExercises = await getExercisesByMuscle(muscle);

    if (injuryHistory.isEmpty) {
      return muscleExercises;
    }

    return muscleExercises.where((exercise) {
      final stressedJoints =
          (exercise['stressed_joints'] as List?)?.cast<String>() ?? [];

      // Excluir si estresa articulación lesionada
      for (final joint in stressedJoints) {
        if (injuryHistory.containsKey(joint)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Limpia el cache (útil para tests o recargas)
  static void clearCache() {
    _exerciseCache = null;
  }
}
