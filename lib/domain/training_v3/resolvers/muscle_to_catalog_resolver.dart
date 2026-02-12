enum MuscleGroup { chest, back, deltoids, arms, legs, glutes, calves, core }

class MuscleToCatalogResolver {
  static const Map<MuscleGroup, List<String>> map = {
    MuscleGroup.chest: ['pectorals'],

    MuscleGroup.back: ['lats', 'upper_back', 'traps'],

    MuscleGroup.deltoids: [
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
    ],

    MuscleGroup.arms: ['biceps', 'triceps'],

    MuscleGroup.legs: ['quadriceps', 'hamstrings'],

    MuscleGroup.glutes: ['glutes'],

    MuscleGroup.calves: ['calves'],

    MuscleGroup.core: ['abs'],
  };

  static List<String> resolve(MuscleGroup group) {
    return map[group] ?? [];
  }
}
