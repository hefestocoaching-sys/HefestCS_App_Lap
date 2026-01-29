class MuscleKeys {
  // Canónico: 14 músculos individuales (SSOT para VOP)
  static const chest = 'chest';
  static const lats = 'lats';
  static const upperBack = 'upper_back'; // Valor interno: upper_back
  static const traps = 'traps';
  static const deltoideAnterior = 'deltoide_anterior';
  static const deltoideLateral = 'deltoide_lateral';
  static const deltoidePosterior = 'deltoide_posterior';
  static const biceps = 'biceps';
  static const triceps = 'triceps';
  static const quads = 'quads';
  static const hamstrings = 'hamstrings';
  static const glutes = 'glutes';
  static const calves = 'calves';
  static const abs = 'abs';

  // Compatibilidad legacy (no canónico, para UI/grupos)
  static const back = 'back'; // Usa: back_group en normalizer
  static const shoulders = 'shoulders'; // Usa: shoulders_group en normalizer

  static const all = <String>{
    chest,
    lats,
    'upper_back', // upperBack valor
    traps,
    'deltoide_anterior', // deltoideAnterior valor
    'deltoide_lateral', // deltoideLateral valor
    'deltoide_posterior', // deltoidePosterior valor
    biceps,
    triceps,
    quads,
    hamstrings,
    glutes,
    calves,
    abs,
  };

  /// Valida si una key es canónica (14 músculos individuales)
  static bool isCanonical(String k) => all.contains(k);

  /// Expande un grupo a músculos canónicos
  static Set<String> expandGroup(String groupName) {
    switch (groupName) {
      case 'back_group':
        return const {'lats', 'upper_back', 'traps'};
      case 'shoulders_group':
        return const {
          'deltoide_anterior',
          'deltoide_lateral',
          'deltoide_posterior',
        };
      case 'legs_group':
        return const {'quads', 'hamstrings', 'glutes', 'calves'};
      case 'arms_group':
        return const {'biceps', 'triceps'};
      default:
        return const {};
    }
  }

  const MuscleKeys._();
}
