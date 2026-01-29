class MealTargets {
  final int mealIndex;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final bool needsReview;
  final String? note;

  const MealTargets({
    required this.mealIndex,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.needsReview,
    this.note,
  });
}
