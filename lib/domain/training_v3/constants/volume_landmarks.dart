// lib/domain/training_v3/constants/volume_landmarks.dart

import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';

/// Constantes de landmarks de volumen (VME/MAV/MRV)
///
/// FUENTE: Semana 1-2, Israetel et al. (2020)
///
/// DEPRECADO PARA FLUJO ACTIVO DE ENTREVISTA->LANDMARKS:
/// la autoridad oficial es muscle_volume_landmarks_ssot.dart.
@Deprecated('Usar muscle_volume_landmarks_ssot.dart en flujo activo')
class VolumeLandmarks {
  /// Volumen Mínimo Efectivo (VME) por músculo y nivel
  static const Map<String, Map<String, int>> vme = {
    MuscleKey.pectorals: {
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
    MuscleKey.quads: {
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
    MuscleKey.deltsFront: {
      TrainingLevelKey.novice: 4,
      TrainingLevelKey.intermediate: 6,
      TrainingLevelKey.advanced: 8,
    },
    MuscleKey.deltsLateral: {
      TrainingLevelKey.novice: 4,
      TrainingLevelKey.intermediate: 6,
      TrainingLevelKey.advanced: 8,
    },
    MuscleKey.deltsRear: {
      TrainingLevelKey.novice: 4,
      TrainingLevelKey.intermediate: 6,
      TrainingLevelKey.advanced: 8,
    },
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
    MuscleKey.pectorals: {
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
    MuscleKey.quads: {
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
    MuscleKey.deltsFront: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 9,
      TrainingLevelKey.advanced: 12,
    },
    MuscleKey.deltsLateral: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 9,
      TrainingLevelKey.advanced: 12,
    },
    MuscleKey.deltsRear: {
      TrainingLevelKey.novice: 6,
      TrainingLevelKey.intermediate: 9,
      TrainingLevelKey.advanced: 12,
    },
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
    MuscleKey.pectorals: {
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
    MuscleKey.quads: {
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
    MuscleKey.deltsFront: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 16,
    },
    MuscleKey.deltsLateral: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 16,
    },
    MuscleKey.deltsRear: {
      TrainingLevelKey.novice: 8,
      TrainingLevelKey.intermediate: 12,
      TrainingLevelKey.advanced: 16,
    },
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
    final canonical = normalizeMuscleKey(muscle);
    return {
      'vme': vme[canonical]?[level] ?? 0,
      'mav': mav[canonical]?[level] ?? 0,
      'mrv': mrv[canonical]?[level] ?? 0,
    };
  }
}
