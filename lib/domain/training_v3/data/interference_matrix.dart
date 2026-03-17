class InterferenceMatrix {
  static const Map<String, List<String>> lowInterference = {
    // SSOT-only canonical keys.
    // Hybrid aliases (torso/push/pull) are represented through canonical groups:
    // torso -> pectorals,lats,upper_back,traps,deltoides ;
    // push  -> pectorals,deltoide_anterior,deltoide_lateral,triceps ;
    // pull  -> lats,upper_back,traps,biceps.
    'pectorals': ['calves', 'abs', 'biceps'],
    'lats': ['calves', 'abs', 'triceps'],
    'upper_back': ['pectorals', 'quadriceps', 'abs'],
    'traps': ['calves', 'abs', 'biceps'],
    'biceps': ['quadriceps', 'calves', 'glutes', 'abs'],
    'triceps': ['hamstrings', 'calves', 'glutes', 'abs'],
    'deltoide_anterior': ['calves', 'abs', 'hamstrings'],
    'deltoide_lateral': ['calves', 'abs', 'quadriceps'],
    'deltoide_posterior': ['calves', 'abs', 'quadriceps', 'hamstrings'],
    'quadriceps': ['biceps', 'abs', 'deltoide_lateral', 'calves'],
    'hamstrings': ['triceps', 'abs', 'deltoide_anterior', 'calves'],
    'glutes': ['biceps', 'triceps', 'abs', 'calves'],
    'calves': [
      'pectorals',
      'lats',
      'upper_back',
      'traps',
      'deltoide_anterior',
      'deltoide_lateral',
      'quadriceps',
      'hamstrings',
      'glutes',
    ],
    'abs': [
      'pectorals',
      'lats',
      'upper_back',
      'traps',
      'biceps',
      'triceps',
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
    ],
  };
}
