class AntagonistPairingEngine {
  static bool areAntagonists(String a, String b) {
    const pairs = {
      'pectorals': 'lats',
      'lats': 'pectorals',
      'biceps': 'triceps',
      'triceps': 'biceps',
      'quadriceps': 'hamstrings',
      'hamstrings': 'quadriceps',
    };

    return pairs[a] == b;
  }
}
