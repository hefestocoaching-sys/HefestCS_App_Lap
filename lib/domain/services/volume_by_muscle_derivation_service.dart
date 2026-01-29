import 'package:hcs_app_lap/domain/training/models/supported_muscles.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SSOT: Derivación de MEV/MRV por músculo canónico (14 keys)
/// ═══════════════════════════════════════════════════════════════════════════
/// Factores clínicos por músculo. Ajustados para garantizar entrenamiento
/// integral incluso con coeficientes bajos (todo músculo recibe al menos MEV).
class VolumeByMuscleDerivationService {
  /// Factores clínicos por músculo (canónicos 14)
  /// Ajusta aquí tu "coeficiente" para asegurar balance integral.
  static const Map<String, double> _factors = {
    'glutes': 1.30,
    'quads': 1.25,
    'lats': 1.15,
    'upper_back': 1.10,
    'traps': 1.05,

    'chest': 1.00,
    'hamstrings': 1.00,

    // Hombro por porción (si quieres más conservador, baja posterior)
    'deltoide_anterior': 0.95,
    'deltoide_lateral': 0.95,
    'deltoide_posterior': 0.90,

    'triceps': 0.85,
    'biceps': 0.80,
    'calves': 0.80,
    'abs': 0.90,
  };

  static Map<String, Map<String, double>> derive({
    required double mevGlobal,
    required double mrvGlobal,
    required Iterable<String> rawMuscleKeys, // debe ser 14 keys
  }) {
    final mevByMuscle = <String, double>{};
    final mrvByMuscle = <String, double>{};

    for (final muscle in rawMuscleKeys) {
      if (!SupportedMuscles.isSupported(muscle)) continue;

      final factor = _factors[muscle] ?? 1.0;

      final mev = (mevGlobal * factor).roundToDouble();
      final mrv = (mrvGlobal * factor)
          .clamp(mev, double.infinity)
          .roundToDouble();

      mevByMuscle[muscle] = mev;
      mrvByMuscle[muscle] = mrv;
    }

    return {'mevByMuscle': mevByMuscle, 'mrvByMuscle': mrvByMuscle};
  }
}
