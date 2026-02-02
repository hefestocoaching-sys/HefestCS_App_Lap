// lib/domain/training_v3/constants/muscle_groups.dart

/// Constantes de grupos musculares
class MuscleGroups {
  /// Lista completa de músculos soportados
  static const List<String> all = [
    'chest',
    'back',
    'quads',
    'hamstrings',
    'glutes',
    'shoulders',
    'biceps',
    'triceps',
    'calves',
    'abs',
  ];

  /// Músculos principales (required)
  static const List<String> primary = [
    'chest',
    'back',
    'quads',
    'hamstrings',
    'shoulders',
  ];

  /// Músculos accesorios (optional)
  static const List<String> accessory = ['biceps', 'triceps', 'calves', 'abs'];

  /// Nombres en español
  static const Map<String, String> displayNames = {
    'chest': 'Pecho',
    'back': 'Espalda',
    'quads': 'Cuádriceps',
    'hamstrings': 'Isquiotibiales',
    'glutes': 'Glúteos',
    'shoulders': 'Hombros',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'calves': 'Pantorrillas',
    'abs': 'Abdominales',
  };

  /// Pares antagonistas (para validación de balance)
  static const Map<String, String> antagonists = {
    'chest': 'back',
    'back': 'chest',
    'quads': 'hamstrings',
    'hamstrings': 'quads',
    'biceps': 'triceps',
    'triceps': 'biceps',
  };

  /// Grupos para splits
  static const Map<String, List<String>> splitGroups = {
    'upper': ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
    'lower': ['quads', 'hamstrings', 'glutes', 'calves'],
    'push': ['chest', 'shoulders', 'triceps'],
    'pull': ['back', 'biceps'],
    'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
  };

  /// Valida si un músculo es válido
  static bool isValid(String muscle) {
    return all.contains(muscle);
  }

  /// Obtiene nombre en español
  static String getDisplayName(String muscle) {
    return displayNames[muscle] ?? muscle;
  }

  /// Obtiene antagonista
  static String? getAntagonist(String muscle) {
    return antagonists[muscle];
  }
}
