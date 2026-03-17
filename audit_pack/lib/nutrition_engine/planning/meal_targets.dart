class MealTargets {
  final int mealIndex;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double minProteinPerMeal;
  final bool needsReview;
  final String? note;

  const MealTargets({
    required this.mealIndex,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.minProteinPerMeal = 0.0,
    required this.needsReview,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealIndex': mealIndex,
      'kcal': kcal,
      'proteinG': proteinG,
      'carbG': carbG,
      'fatG': fatG,
      'minProteinPerMeal': minProteinPerMeal,
      'needsReview': needsReview,
      if (note != null) 'note': note,
    };
  }

  factory MealTargets.fromJson(Map<String, dynamic> json) {
    return MealTargets(
      mealIndex: json['mealIndex'] as int? ?? 0,
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbG: (json['carbG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      minProteinPerMeal:
          (json['minProteinPerMeal'] as num?)?.toDouble() ?? 0.0,
      needsReview: json['needsReview'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
