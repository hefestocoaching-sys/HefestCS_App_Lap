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

  /// Mapeo de keys canónicas → Labels en español para UI
  static const Map<String, String> displayLabels = {
    MuscleKeys.chest: 'Pecho',
    MuscleKeys.lats: 'Dorsal ancho (Lats)',
    'upper_back': 'Espalda alta / Escápulas (Upper back)',
    MuscleKeys.traps: 'Trapecios',
    'deltoide_anterior': 'Deltoide Anterior',
    'deltoide_lateral': 'Deltoide Lateral',
    'deltoide_posterior': 'Deltoide Posterior',
    MuscleKeys.biceps: 'Bíceps',
    MuscleKeys.triceps: 'Tríceps',
    MuscleKeys.quads: 'Cuádriceps',
    MuscleKeys.hamstrings: 'Isquiotibiales',
    MuscleKeys.glutes: 'Glúteos',
    MuscleKeys.calves: 'Pantorrillas',
    MuscleKeys.abs: 'Abdominales',
  };

  static bool isSupported(String key) => keys.contains(key);

  /// Obtiene el label en español para una key canónica
  static String getDisplayLabel(String key) =>
      displayLabels[key] ?? key.toUpperCase();
}
