import 'package:hcs_app_lap/core/constants/muscle_keys.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SSOT: 14 músculos individuales canónicos.
/// NO incluir grupos legacy (back/shoulders).
/// ═══════════════════════════════════════════════════════════════════════════
/// Esta es la ÚNICA lista que el motor debe usar para cálculos volumétricos.
/// Cualquier grupo UI (Espalda, Hombro) debe ser expansión de estos 14.
class SupportedMuscles {
  static const List<String> keys = [
    MuscleKeys.chest,
    MuscleKeys.lats,
    'upper_back',
    MuscleKeys.traps,
    'deltoide_anterior',
    'deltoide_lateral',
    'deltoide_posterior',
    MuscleKeys.biceps,
    MuscleKeys.triceps,
    MuscleKeys.quads,
    MuscleKeys.hamstrings,
    MuscleKeys.glutes,
    MuscleKeys.calves,
    MuscleKeys.abs,
  ];

  static bool isSupported(String key) => keys.contains(key);
}
