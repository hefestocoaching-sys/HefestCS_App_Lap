class MealDistributionConfig {
  final int mealsPerDay; // 3..6
  final double minProteinPerMealPerKg; // default 0.25
  final bool enforceProteinThreshold; // default true
  final double? minProteinPerMealAbsolute; // optional override
  final List<double>? kcalPercentsOverride; // optional

  const MealDistributionConfig({
    required this.mealsPerDay,
    this.minProteinPerMealPerKg = 0.25,
    this.enforceProteinThreshold = true,
    this.minProteinPerMealAbsolute,
    this.kcalPercentsOverride,
  });
}
