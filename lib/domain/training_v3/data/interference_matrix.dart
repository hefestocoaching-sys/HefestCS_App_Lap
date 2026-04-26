class InterferenceMatrix {
  static const Map<String, List<String>> lowInterference = {
    // SSOT-only canonical keys.
    // Hybrid aliases (torso/push/pull) are represented through canonical groups:
    // torso -> pectorals,lats,upper_back,traps,delts_* ;
    // push  -> pectorals,delts_front,delts_lateral,triceps ;
    // pull  -> lats,upper_back,traps,biceps.
    'pectorals': ['calves', 'abs', 'biceps'],
    'lats': ['calves', 'abs', 'triceps'],
    'upper_back': ['pectorals', 'quads', 'abs'],
    'traps': ['calves', 'abs', 'biceps'],
    'biceps': ['quads', 'calves', 'glutes', 'abs'],
    'triceps': ['hamstrings', 'calves', 'glutes', 'abs'],
    'delts_front': ['calves', 'abs', 'hamstrings'],
    'delts_lateral': ['calves', 'abs', 'quads'],
    'delts_rear': ['calves', 'abs', 'quads', 'hamstrings'],
    'quads': ['biceps', 'abs', 'delts_lateral', 'calves'],
    'hamstrings': ['triceps', 'abs', 'delts_front', 'calves'],
    'glutes': ['biceps', 'triceps', 'abs', 'calves'],
    'calves': [
      'pectorals',
      'lats',
      'upper_back',
      'traps',
      'delts_front',
      'delts_lateral',
      'quads',
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
      'delts_front',
      'delts_lateral',
      'delts_rear',
    ],
  };
}
