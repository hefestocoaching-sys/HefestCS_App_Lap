import 'meal_distribution_config.dart';
import 'meal_targets.dart';

class MealDistributionService {
  static const double _percentTolerance = 0.01; // ±1%

  List<MealTargets> distributeDay({
    required double kcalTarget,
    required double proteinTargetG,
    required double carbTargetG,
    required double fatTargetG,
    required double bodyWeightKg,
    required MealDistributionConfig config,
  }) {
    _validateConfig(config);

    final percents = _resolvePercents(config);

    // Distribución inicial por porcentajes
    final meals = List<_MealAllocation>.generate(config.mealsPerDay, (index) {
      final pct = percents[index];
      return _MealAllocation(
        mealIndex: index,
        kcal: _round0(kcalTarget * pct),
        protein: _round1(proteinTargetG * pct),
        carbs: _round1(carbTargetG * pct),
        fat: _round1(fatTargetG * pct),
      );
    });

    // Ajustar residuos para cerrar sumas exactas (última comida absorbe)
    _reconcileTotals(
      meals,
      kcalTarget: kcalTarget,
      proteinTargetG: proteinTargetG,
      carbTargetG: carbTargetG,
      fatTargetG: fatTargetG,
    );

    final minProteinPerMeal =
        config.minProteinPerMealAbsolute ??
        bodyWeightKg * config.minProteinPerMealPerKg;

    // Umbral de proteína por comida (hipertrofia)
    bool redistributionOk = true;
    if (config.enforceProteinThreshold) {
      redistributionOk = _enforceProteinThreshold(meals, minProteinPerMeal);

      if (!redistributionOk) {
        final note =
            'Proteína diaria insuficiente para cumplir umbral por comida con ${config.mealsPerDay} comidas';
        return meals
            .map((m) => m.toMealTargets(needsReview: true, note: note))
            .toList();
      }
    }

    // Re-redondear y reconciliar tras redistribución
    _reconcileTotals(
      meals,
      kcalTarget: kcalTarget,
      proteinTargetG: proteinTargetG,
      carbTargetG: carbTargetG,
      fatTargetG: fatTargetG,
    );

    return meals
        .map((m) => m.toMealTargets(needsReview: !redistributionOk))
        .toList();
  }

  void _validateConfig(MealDistributionConfig config) {
    if (config.mealsPerDay < 3 || config.mealsPerDay > 6) {
      throw ArgumentError('mealsPerDay debe estar entre 3 y 6');
    }

    if (config.kcalPercentsOverride != null) {
      if (config.kcalPercentsOverride!.length != config.mealsPerDay) {
        throw ArgumentError(
          'kcalPercentsOverride debe tener ${config.mealsPerDay} valores',
        );
      }
      final sum = config.kcalPercentsOverride!.reduce((a, b) => a + b);
      if ((sum - 1.0).abs() > _percentTolerance) {
        throw ArgumentError(
          'kcalPercentsOverride debe sumar aproximadamente 1.0',
        );
      }
    }
  }

  List<double> _resolvePercents(MealDistributionConfig config) {
    if (config.kcalPercentsOverride != null) {
      return config.kcalPercentsOverride!;
    }

    switch (config.mealsPerDay) {
      case 3:
        return const [0.33, 0.34, 0.33];
      case 4:
        return const [0.25, 0.30, 0.25, 0.20];
      case 5:
        return const [0.20, 0.20, 0.25, 0.20, 0.15];
      case 6:
        return const [0.18, 0.18, 0.18, 0.18, 0.16, 0.12];
      default:
        return const [];
    }
  }

  bool _enforceProteinThreshold(
    List<_MealAllocation> meals,
    double minProteinPerMeal,
  ) {
    double totalDeficit = 0;
    for (final meal in meals) {
      if (meal.protein < minProteinPerMeal) {
        totalDeficit += (minProteinPerMeal - meal.protein);
      }
    }

    double totalSurplus = 0;
    for (final meal in meals) {
      if (meal.protein > minProteinPerMeal) {
        totalSurplus += (meal.protein - minProteinPerMeal);
      }
    }

    if (totalDeficit == 0) {
      return true; // todos cumplen
    }

    if (totalSurplus + 1e-6 < totalDeficit) {
      return false; // proteína diaria insuficiente
    }

    // Redistribuir proteína: mover de excedentes a deficitarias
    for (final meal in meals) {
      if (meal.protein < minProteinPerMeal) {
        double needed = minProteinPerMeal - meal.protein;
        for (final donor in meals) {
          if (donor.protein <= minProteinPerMeal) continue;
          final available = donor.protein - minProteinPerMeal;
          if (available <= 0) continue;
          final transfer = available >= needed ? needed : available;

          donor.protein -= transfer;
          meal.protein += transfer;

          donor.kcal -= transfer * 4; // proteína kcal
          meal.kcal += transfer * 4;

          needed -= transfer;
          if (needed <= 0) break;
        }
      }
    }

    return true;
  }

  void _reconcileTotals(
    List<_MealAllocation> meals, {
    required double kcalTarget,
    required double proteinTargetG,
    required double carbTargetG,
    required double fatTargetG,
  }) {
    // Redondear a 1 decimal proteínas/carbs/fat y 0 decimales kcal
    for (final m in meals) {
      m.protein = _round1(m.protein);
      m.carbs = _round1(m.carbs);
      m.fat = _round1(m.fat);
      m.kcal = _round0(m.kcal);
    }

    double proteinResidual =
        proteinTargetG - meals.fold(0, (p, m) => p + m.protein);
    double carbResidual = carbTargetG - meals.fold(0, (p, m) => p + m.carbs);
    double fatResidual = fatTargetG - meals.fold(0, (p, m) => p + m.fat);
    double kcalResidual = kcalTarget - meals.fold(0, (p, m) => p + m.kcal);

    if (meals.isNotEmpty) {
      final last = meals.last;
      last.protein = _round1(last.protein + proteinResidual);
      last.carbs = _round1(last.carbs + carbResidual);
      last.fat = _round1(last.fat + fatResidual);
      last.kcal = _round0(last.kcal + kcalResidual);
    }
  }

  double _round1(double value) => double.parse(value.toStringAsFixed(1));
  double _round0(double value) => double.parse(value.toStringAsFixed(0));
}

class _MealAllocation {
  _MealAllocation({
    required this.mealIndex,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int mealIndex;
  double kcal;
  double protein;
  double carbs;
  double fat;

  MealTargets toMealTargets({required bool needsReview, String? note}) {
    return MealTargets(
      mealIndex: mealIndex,
      kcal: kcal,
      proteinG: protein,
      carbG: carbs,
      fatG: fat,
      needsReview: needsReview,
      note: note,
    );
  }
}
