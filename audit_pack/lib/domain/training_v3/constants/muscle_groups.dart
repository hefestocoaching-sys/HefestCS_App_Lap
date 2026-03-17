// lib/domain/training_v3/constants/muscle_groups.dart

/// Constantes de grupos musculares
class MuscleGroups {
  /// Lista completa de músculos soportados
  static const List<String> all = [
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
  ];

  /// Músculos principales (required)
  static const List<String> primary = [
    'pectorals',
    'lats',
    'upper_back',
    'quads',
    'hamstrings',
    'delts_lateral',
  ];

  /// Músculos accesorios (optional)
  static const List<String> accessory = ['biceps', 'triceps', 'calves', 'abs'];

  /// Nombres en español
  static const Map<String, String> displayNames = {
    'pectorals': 'Pecho',
    'lats': 'Dorsal ancho',
    'upper_back': 'Espalda alta',
    'traps': 'Trapecio',
    'delts_front': 'Deltoide anterior',
    'delts_lateral': 'Deltoide lateral',
    'delts_rear': 'Deltoide posterior',
    'quads': 'Cuádriceps',
    'hamstrings': 'Isquiotibiales',
    'glutes': 'Glúteos',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'calves': 'Pantorrillas',
    'abs': 'Abdominales',
  };

  /// Pares antagonistas (para validación de balance)
  static const Map<String, String> antagonists = {
    'pectorals': 'lats',
    'lats': 'pectorals',
    'quads': 'hamstrings',
    'hamstrings': 'quads',
    'biceps': 'triceps',
    'triceps': 'biceps',
  };

  /// Grupos para splits
  static const Map<String, List<String>> splitGroups = {
    'upper': [
      'pectorals',
      'lats',
      'upper_back',
      'traps',
      'delts_front',
      'delts_lateral',
      'delts_rear',
      'biceps',
      'triceps',
    ],
    'lower': ['quads', 'hamstrings', 'glutes', 'calves'],
    'push': ['pectorals', 'delts_front', 'delts_lateral', 'triceps'],
    'pull': ['lats', 'upper_back', 'traps', 'delts_rear', 'biceps'],
    'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
    'back': ['lats', 'upper_back'],
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
