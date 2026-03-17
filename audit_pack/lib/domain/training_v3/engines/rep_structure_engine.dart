class RepRange {
  final int min;
  final int max;

  const RepRange(this.min, this.max);

  @override
  String toString() => '$min-$max';
}

class SessionRepStructure {
  final RepRange firstExercise;
  final RepRange secondExercise;

  const SessionRepStructure({
    required this.firstExercise,
    required this.secondExercise,
  });
}

class RepStructureEngine {
  List<SessionRepStructure> buildForFrequency(int frequency) {
    if (frequency == 2) {
      return const [
        SessionRepStructure(
          firstExercise: RepRange(6, 8),
          secondExercise: RepRange(8, 12),
        ),
        SessionRepStructure(
          firstExercise: RepRange(8, 12),
          secondExercise: RepRange(16, 20),
        ),
      ];
    }

    if (frequency == 3) {
      return const [
        SessionRepStructure(
          firstExercise: RepRange(8, 12),
          secondExercise: RepRange(8, 12),
        ),
        SessionRepStructure(
          firstExercise: RepRange(8, 12),
          secondExercise: RepRange(16, 20),
        ),
        SessionRepStructure(
          firstExercise: RepRange(8, 12),
          secondExercise: RepRange(8, 12),
        ),
      ];
    }

    return const [
      SessionRepStructure(
        firstExercise: RepRange(8, 12),
        secondExercise: RepRange(8, 12),
      ),
    ];
  }
}
