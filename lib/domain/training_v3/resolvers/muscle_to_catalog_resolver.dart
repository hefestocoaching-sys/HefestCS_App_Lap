enum MuscleGroup { chest, back, deltoids, arms, legs, glutes, calves, core }

class MuscleToCatalogResolver {
  static const Map<MuscleGroup, List<String>> map = {
    MuscleGroup.chest: [
      'pectoral_superior',
      'pectoral_medio',
      'pectoral_inferior',
    ],
    MuscleGroup.deltoids: [
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
    ],
    MuscleGroup.back: [
      'dorsal_ancho',
      'dorsal_superior',
      'trapecio_superior',
      'trapecio_medio',
      'trapecio_inferior',
    ],
    MuscleGroup.arms: [
      'biceps_braquial',
      'triceps_cabeza_larga',
      'triceps_cabeza_lateral',
    ],
    MuscleGroup.legs: [
      'cuadriceps_recto_femoral',
      'cuadriceps_vasto_lateral',
      'isquiotibiales_biceps_femoral',
    ],
    MuscleGroup.glutes: ['gluteo_mayor', 'gluteo_medio'],
    MuscleGroup.calves: ['gemelo_gastrocnemio'],
    MuscleGroup.core: [
      'abdominales_recto_abdominal',
      'oblicuos_externos',
      'lumbar_erectores',
    ],
  };

  static List<String> resolve(MuscleGroup group) {
    return map[group] ?? [];
  }
}
