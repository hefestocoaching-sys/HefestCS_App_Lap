class ExerciseSetAllocation {
  final int exerciseIndex;
  final int sets;

  const ExerciseSetAllocation({
    required this.exerciseIndex,
    required this.sets,
  });
}

class SetDistributionEngine {
  List<ExerciseSetAllocation> distribute({
    required int totalSetsForThatMuscleOnThatDay,
    required int exerciseCount,
  }) {
    final total = totalSetsForThatMuscleOnThatDay;
    if (total <= 0) return const [];

    if (exerciseCount <= 1 || total <= 3) {
      return [ExerciseSetAllocation(exerciseIndex: 0, sets: total)];
    }

    final split = switch (total) {
      4 => const [2, 2],
      5 => const [3, 2],
      6 => const [4, 2],
      7 => const [4, 3],
      8 => const [5, 3],
      9 => const [5, 4],
      _ => [(total / 2).ceil(), total - (total / 2).ceil()],
    };

    final first = split[0] >= split[1] ? split[0] : split[1];
    final second = split[0] >= split[1] ? split[1] : split[0];

    return [
      ExerciseSetAllocation(exerciseIndex: 0, sets: first),
      ExerciseSetAllocation(exerciseIndex: 1, sets: second),
    ];
  }
}
