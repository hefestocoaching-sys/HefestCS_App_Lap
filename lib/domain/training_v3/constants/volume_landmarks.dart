// lib/domain/training_v3/constants/volume_landmarks.dart

/// Constantes de landmarks de volumen (VME/MAV/MRV)
///
/// FUENTE: Semana 1-2, Israetel et al. (2020)
class VolumeLandmarks {
  /// Volumen Mínimo Efectivo (VME) por músculo y nivel
  static const Map<String, Map<String, int>> vme = {
    'chest': {'novice': 10, 'intermediate': 12, 'advanced': 15},
    'back': {'novice': 12, 'intermediate': 15, 'advanced': 18},
    'quads': {'novice': 10, 'intermediate': 12, 'advanced': 15},
    'hamstrings': {'novice': 8, 'intermediate': 10, 'advanced': 12},
    'glutes': {'novice': 8, 'intermediate': 10, 'advanced': 12},
    'shoulders': {'novice': 10, 'intermediate': 12, 'advanced': 15},
    'biceps': {'novice': 6, 'intermediate': 8, 'advanced': 10},
    'triceps': {'novice': 6, 'intermediate': 8, 'advanced': 10},
    'calves': {'novice': 8, 'intermediate': 10, 'advanced': 12},
    'abs': {'novice': 6, 'intermediate': 8, 'advanced': 10},
  };

  /// Volumen Adaptativo Máximo (MAV) por músculo y nivel
  static const Map<String, Map<String, int>> mav = {
    'chest': {'novice': 15, 'intermediate': 18, 'advanced': 22},
    'back': {'novice': 18, 'intermediate': 22, 'advanced': 26},
    'quads': {'novice': 15, 'intermediate': 18, 'advanced': 22},
    'hamstrings': {'novice': 12, 'intermediate': 15, 'advanced': 18},
    'glutes': {'novice': 12, 'intermediate': 15, 'advanced': 18},
    'shoulders': {'novice': 15, 'intermediate': 18, 'advanced': 22},
    'biceps': {'novice': 10, 'intermediate': 12, 'advanced': 15},
    'triceps': {'novice': 10, 'intermediate': 12, 'advanced': 15},
    'calves': {'novice': 12, 'intermediate': 15, 'advanced': 18},
    'abs': {'novice': 10, 'intermediate': 12, 'advanced': 15},
  };

  /// Volumen Máximo Recuperable (MRV) por músculo y nivel
  static const Map<String, Map<String, int>> mrv = {
    'chest': {'novice': 20, 'intermediate': 24, 'advanced': 28},
    'back': {'novice': 24, 'intermediate': 28, 'advanced': 32},
    'quads': {'novice': 20, 'intermediate': 24, 'advanced': 28},
    'hamstrings': {'novice': 16, 'intermediate': 20, 'advanced': 24},
    'glutes': {'novice': 16, 'intermediate': 20, 'advanced': 24},
    'shoulders': {'novice': 20, 'intermediate': 24, 'advanced': 28},
    'biceps': {'novice': 14, 'intermediate': 16, 'advanced': 20},
    'triceps': {'novice': 14, 'intermediate': 16, 'advanced': 20},
    'calves': {'novice': 16, 'intermediate': 20, 'advanced': 24},
    'abs': {'novice': 14, 'intermediate': 16, 'advanced': 20},
  };

  /// Obtiene landmarks para músculo y nivel
  static Map<String, int> getLandmarks(String muscle, String level) {
    return {
      'vme': vme[muscle]?[level] ?? 0,
      'mav': mav[muscle]?[level] ?? 0,
      'mrv': mrv[muscle]?[level] ?? 0,
    };
  }
}
