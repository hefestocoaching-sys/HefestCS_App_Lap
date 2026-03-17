// lib/domain/training_v3/constants/volume_landmarks.dart

import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';

/// Constantes de landmarks de volumen (VME/MAV/MRV)
///
/// FUENTE: Semana 1-2, Israetel et al. (2020)
class VolumeLandmarks {
  /// Volumen Mínimo Efectivo (VME) por músculo y nivel
  static const Map<String, Map<String, int>> vme = {
    MuscleKey.chest: {
      TrainingLevelKey.novice: 10,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 15,
    },
    MuscleKey.lats: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 8,
      TrainingLevelKey.advanced: 10,
    },
    MuscleKey.upperBack: {
      TrainingLevelKey.novice: 4,
      TrainingLevelKey.intermediate: 6,
      TrainingLevelKey.advanced: 8,
    },
    MuscleKey.traps: {
      TrainingLevelKey.novice: 4,
      TrainingLevelKey.intermediate: 6,
      TrainingLevelKey.advanced: 8,
    },
    MuscleKey.quadriceps: {
      TrainingLevelKey.novice: 10,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 15,
    },
    MuscleKey.hamstrings: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 10,
      TrainingLevelKey.advanced: 12,
    },
    MuscleKey.glutes: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 10,
      TrainingLevelKey.advanced: 12,
    },
    'shoulders': {'novice': 10, 'intermediate': 12, 'advanced': 15},
    MuscleKey.biceps: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 8,
      TrainingLevelKey.advanced: 10,
    },
    MuscleKey.triceps: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 8,
      TrainingLevelKey.advanced: 10,
    },
    MuscleKey.calves: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 10,
      TrainingLevelKey.advanced: 12,
    },
    MuscleKey.abs: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 8,
      TrainingLevelKey.advanced: 10,
    },
  };

  /// Volumen Adaptativo Máximo (MAV) por músculo y nivel
  static const Map<String, Map<String, int>> mav = {
    MuscleKey.chest: {
      TrainingLevelKey.novice: 15,
      TrainingLevelKey.intermediate: 18,
      TrainingLevelKey.advanced: 22,
    },
    MuscleKey.lats: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 16,
    },
    MuscleKey.upperBack: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 9,
      TrainingLevelKey.advanced: 12,
    },
    MuscleKey.traps: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 9,
      TrainingLevelKey.advanced: 12,
    },
    MuscleKey.quadriceps: {
      TrainingLevelKey.novice: 15,
      TrainingLevelKey.intermediate: 18,
      TrainingLevelKey.advanced: 22,
    },
    MuscleKey.hamstrings: {
      TrainingLevelKey.novice: 12,
      TrainingLevelKey.intermediate: 15,
      TrainingLevelKey.advanced: 18,
    },
    MuscleKey.glutes: {
      TrainingLevelKey.novice: 12,
      TrainingLevelKey.intermediate: 15,
      TrainingLevelKey.advanced: 18,
    },
    'shoulders': {'novice': 15, 'intermediate': 18, 'advanced': 22},
    MuscleKey.biceps: {
      TrainingLevelKey.novice: 10,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 15,
    },
    MuscleKey.triceps: {
      TrainingLevelKey.novice: 10,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 15,
    },
    MuscleKey.calves: {
      TrainingLevelKey.novice: 12,
      TrainingLevelKey.intermediate: 15,
      TrainingLevelKey.advanced: 18,
    },
    MuscleKey.abs: {
      TrainingLevelKey.novice: 10,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 15,
    },
  };

  /// Volumen Máximo Recuperable (MRV) por músculo y nivel
  static const Map<String, Map<String, int>> mrv = {
    MuscleKey.chest: {
      TrainingLevelKey.novice: 20,
      TrainingLevelKey.intermediate: 24,
      TrainingLevelKey.advanced: 28,
    },
    MuscleKey.lats: {
      TrainingLevelKey.novice: 10,
      TrainingLevelKey.intermediate: 14,
      TrainingLevelKey.advanced: 18,
    },
    MuscleKey.upperBack: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 16,
    },
    MuscleKey.traps: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 16,
    },
    MuscleKey.quadriceps: {
      TrainingLevelKey.novice: 20,
      TrainingLevelKey.intermediate: 24,
      TrainingLevelKey.advanced: 28,
    },
    MuscleKey.hamstrings: {
      TrainingLevelKey.novice: 16,
      TrainingLevelKey.intermediate: 20,
      TrainingLevelKey.advanced: 24,
    },
    MuscleKey.glutes: {
      TrainingLevelKey.novice: 16,
      TrainingLevelKey.intermediate: 20,
      TrainingLevelKey.advanced: 24,
    },
    'shoulders': {'novice': 20, 'intermediate': 24, 'advanced': 28},
    MuscleKey.biceps: {
      TrainingLevelKey.novice: 14,
      TrainingLevelKey.intermediate: 16,
      TrainingLevelKey.advanced: 20,
    },
    MuscleKey.triceps: {
      TrainingLevelKey.novice: 14,
      TrainingLevelKey.intermediate: 16,
      TrainingLevelKey.advanced: 20,
    },
    MuscleKey.calves: {
      TrainingLevelKey.novice: 16,
      TrainingLevelKey.intermediate: 20,
      TrainingLevelKey.advanced: 24,
    },
    MuscleKey.abs: {
      TrainingLevelKey.novice: 14,
      TrainingLevelKey.intermediate: 16,
      TrainingLevelKey.advanced: 20,
    },
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
