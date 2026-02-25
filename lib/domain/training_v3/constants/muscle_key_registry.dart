abstract class MuscleKey {
  static const String chest = 'chest';
  static const String deltoidAnterior = 'deltoide_anterior';
  static const String deltoidLateral = 'deltoide_lateral';
  static const String deltoidPosterior = 'deltoide_posterior';
  static const String triceps = 'triceps';
  static const String lats = 'lats';
  static const String upperBack = 'upper_back';
  static const String traps = 'traps';
  static const String biceps = 'biceps';
  static const String quadriceps = 'quadriceps';
  static const String hamstrings = 'hamstrings';
  static const String glutes = 'glutes';
  static const String calves = 'calves';
  static const String abs = 'abs';

  static const List<String> all = [
    chest,
    deltoidAnterior,
    deltoidLateral,
    deltoidPosterior,
    triceps,
    lats,
    upperBack,
    traps,
    biceps,
    quadriceps,
    hamstrings,
    glutes,
    calves,
    abs,
  ];
  static const List<String> upperBody = [
    chest,
    deltoidAnterior,
    deltoidLateral,
    deltoidPosterior,
    triceps,
    lats,
    upperBack,
    traps,
    biceps,
  ];
  static const List<String> lowerBody = [
    quadriceps,
    hamstrings,
    glutes,
    calves,
  ];
  static const List<String> core = [abs];
}

abstract class IntensityZone {
  static const String heavy = 'heavy';
  static const String medium = 'medium'; // nunca 'moderate'
  static const String light = 'light';
}

abstract class TrainingLevelKey {
  static const String novice = 'novice';
  static const String intermediate = 'intermediate';
  static const String advanced = 'advanced';
}
