abstract class MuscleKey {
  static const String pectorals = 'pectorals';
  static const String lats = 'lats';
  static const String upperBack = 'upper_back';
  static const String traps = 'traps';
  static const String deltsFront = 'delts_front';
  static const String deltsLateral = 'delts_lateral';
  static const String deltsRear = 'delts_rear';

  static const String biceps = 'biceps';
  static const String triceps = 'triceps';

  static const String quads = 'quads';
  static const String hamstrings = 'hamstrings';
  static const String glutes = 'glutes';
  static const String calves = 'calves';
  static const String abs = 'abs';

  static const List<String> all = [
    pectorals,
    lats,
    upperBack,
    traps,
    deltsFront,
    deltsLateral,
    deltsRear,
    biceps,
    triceps,
    quads,
    hamstrings,
    glutes,
    calves,
    abs,
  ];
  static const List<String> upperBody = [
    pectorals,
    lats,
    upperBack,
    traps,
    deltsFront,
    deltsLateral,
    deltsRear,
    biceps,
    triceps,
  ];
  static const List<String> lowerBody = [quads, hamstrings, glutes, calves];
  static const List<String> core = [abs];

  // Alias legacy de entrada (NO canónicos)
  static const String chest = pectorals;
  static const String deltoidAnterior = deltsFront;
  static const String deltoidLateral = deltsLateral;
  static const String deltoidPosterior = deltsRear;
  static const String quadriceps = quads;
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
