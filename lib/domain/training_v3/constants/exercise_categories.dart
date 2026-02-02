// lib/domain/training_v3/constants/exercise_categories.dart

/// Constantes de categorías de ejercicios
class ExerciseCategories {
  /// Tipos de ejercicio
  static const String compound = 'compound';
  static const String isolation = 'isolation';

  /// Patrones de movimiento
  static const List<String> movementPatterns = [
    'horizontal_push',
    'horizontal_pull',
    'vertical_push',
    'vertical_pull',
    'squat',
    'hinge',
    'lunge',
    'elbow_flexion',
    'elbow_extension',
    'knee_flexion',
    'knee_extension',
    'ankle_plantarflexion',
  ];

  /// Equipamiento común
  static const List<String> equipment = [
    'barbell',
    'dumbbell',
    'machine',
    'cable',
    'bodyweight',
    'bench',
    'rack',
    'pull_up_bar',
  ];

  /// Articulaciones comunes
  static const List<String> joints = [
    'shoulder',
    'elbow',
    'wrist',
    'hip',
    'knee',
    'ankle',
    'lower_back',
  ];

  /// Técnicas de intensificación
  static const List<String> intensificationTechniques = [
    'drop_set',
    'rest_pause',
    'cluster',
    'myo_reps',
    'super_set',
    'giant_set',
  ];

  /// Validaciones
  static bool isValidType(String type) {
    return type == compound || type == isolation;
  }

  static bool isValidMovementPattern(String pattern) {
    return movementPatterns.contains(pattern);
  }

  static bool isValidEquipment(String eq) {
    return equipment.contains(eq);
  }
}
