@Deprecated('Legacy no activo. No usar. Mantener solo por compatibilidad.')
class VolumeIndividualizationService {
  // Factores derivados de evidencia:
  // tamaño muscular, tolerancia al volumen, solapamiento, fatiga local
  static const Map<String, double> _muscleFactors = {
    // grandes / alta tolerancia
    'glutes': 1.30,
    'quads': 1.25,
    'back': 1.20,

    // medios
    'chest': 1.00,
    'hamstrings': 1.00,

    // pequeños / alta fatiga
    'shoulders': 0.90,
    'triceps': 0.85,
    'biceps': 0.80,
    'calves': 0.80,
    'abs': 0.90,
  };

  /// Deriva VME y VMR por músculo a partir del rango global del sujeto.
  /// No reemplaza el rango global, solo lo desagrega localmente.
  static Map<String, Map<String, double>> derive({
    required double mevGlobal,
    required double mrvGlobal,
    required Iterable<String> muscles,
  }) {
    final Map<String, double> mevByMuscle = {};
    final Map<String, double> mrvByMuscle = {};

    for (final muscle in muscles) {
      final factor = _muscleFactors[muscle] ?? 1.0;

      final mev = (mevGlobal * factor)
          .clamp(1.0, double.infinity)
          .roundToDouble();

      final mrv = (mrvGlobal * factor)
          .clamp(mev, double.infinity)
          .roundToDouble();

      mevByMuscle[muscle] = mev;
      mrvByMuscle[muscle] = mrv;
    }

    return {'mevByMuscle': mevByMuscle, 'mrvByMuscle': mrvByMuscle};
  }
}
