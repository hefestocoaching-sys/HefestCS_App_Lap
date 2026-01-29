enum ExerciseType { compound, isolation, conditioning, mobility, plyometric }

extension ExerciseTypeX on ExerciseType {
  String get label => switch (this) {
        ExerciseType.compound => 'Compuesto',
        ExerciseType.isolation => 'Aislamiento',
        ExerciseType.conditioning => 'Condicionamiento',
        ExerciseType.mobility => 'Movilidad',
        ExerciseType.plyometric => 'Pliometrico',
      };
}
