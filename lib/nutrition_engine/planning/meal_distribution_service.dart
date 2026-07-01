import 'package:hcs_app_lap/nutrition_engine/planning/meal_distribution_config.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_targets.dart';

/// Servicio de distribución de macros entre comidas del día.
///
/// Cada macro tiene su propio perfil de distribución:
/// - Proteína : distribución uniforme (cumplir umbral 1.2–1.6 g/kg por comida).
/// - Carbos   : "front-loaded" → más en desayuno y almuerzo, mínimo en cena.
/// - Grasas   : "front-loaded" → más en desayuno y almuerzo, mínimo en cena.
///
/// La última comida absorbe los residuos de redondeo para cerrar sumas exactas.
class MealDistributionService {
  static const double _percentTolerance = 0.01;

  List<MealTargets> distributeDay({
    required double kcalTarget,
    required double proteinTargetG,
    required double carbTargetG,
    required double fatTargetG,
    required double bodyWeightKg,
    required MealDistributionConfig config,
  }) {
    _validateConfig(config);

    final proteinPcts = _resolveProteinPercents(config);
    final carbPcts = _resolveCarbPercents(config);
    final fatPcts = _resolveFatPercents(config);

    // Distribución inicial — cada macro con su propio perfil
    final meals = List<_MealAllocation>.generate(config.mealsPerDay, (i) {
      final prot = _round1(proteinTargetG * proteinPcts[i]);
      final carb = _round1(carbTargetG * carbPcts[i]);
      final fat = _round1(fatTargetG * fatPcts[i]);
      final kcal = _round0((prot * 4) + (carb * 4) + (fat * 9));
      return _MealAllocation(
        mealIndex: i,
        kcal: kcal,
        protein: prot,
        carbs: carb,
        fat: fat,
      );
    });

    // Cerrar residuos de redondeo (la última comida absorbe)
    _reconcileTotals(
      meals,
      kcalTarget: kcalTarget,
      proteinTargetG: proteinTargetG,
      carbTargetG: carbTargetG,
      fatTargetG: fatTargetG,
    );

    // Umbral mínimo de proteína por comida
    // Clamp entre 20 g (mínimo absoluto) y 50 g (techo para no sobrecargar)
    final minProtein =
        config.minProteinPerMealAbsolute ??
        (bodyWeightKg * config.minProteinPerMealPerKg).clamp(20.0, 50.0);

    bool ok = true;
    if (config.enforceProteinThreshold) {
      ok = _enforceProteinThreshold(meals, minProtein);
      if (!ok) {
        const note =
            'Proteína diaria insuficiente para alcanzar el mínimo por comida. '
            'Aumentar proteína total o reducir número de comidas.';
        return meals
            .map((m) => m.toMealTargets(needsReview: true, note: note))
            .toList();
      }
    }

    _reconcileTotals(
      meals,
      kcalTarget: kcalTarget,
      proteinTargetG: proteinTargetG,
      carbTargetG: carbTargetG,
      fatTargetG: fatTargetG,
    );

    return meals.map((m) => m.toMealTargets(needsReview: !ok)).toList();
  }

  // ─── PROTEÍNA — distribución uniforme ─────────────────────────────────
  //
  // Siempre uniforme. El mecanismo _enforceProteinThreshold se encarga
  // de garantizar el piso de 1.2–1.6 g/kg por comida redistribuyendo
  // desde comidas con excedente hacia las deficitarias.
  List<double> _resolveProteinPercents(MealDistributionConfig config) {
    if (config.proteinPercentsOverride != null) {
      return config.proteinPercentsOverride!;
    }
    final eq = 1.0 / config.mealsPerDay;
    return List.filled(config.mealsPerDay, eq);
  }

  // ─── CARBOHIDRATOS — front-loaded ─────────────────────────────────────
  //
  // Principio: la energía de carb se necesita durante la actividad diurna.
  // Las primeras 2/3 comidas reciben la mayor parte.
  // La cena recibe el mínimo (8–10%).
  //
  // Con 3 comidas : [40%, 35%, 25%]
  // Con 4 comidas : [35%, 30%, 25%, 10%]
  // Con 5 comidas : [30%, 25%, 22%, 15%, 8%]
  // Con 6 comidas : [25%, 22%, 20%, 18%, 10%, 5%]
  List<double> _resolveCarbPercents(MealDistributionConfig config) {
    if (config.carbPercentsOverride != null) {
      return config.carbPercentsOverride!;
    }
    switch (config.mealsPerDay) {
      case 3:
        return const [0.40, 0.35, 0.25];
      case 4:
        return const [0.35, 0.30, 0.25, 0.10];
      case 5:
        return const [0.30, 0.25, 0.22, 0.15, 0.08];
      case 6:
        return const [0.25, 0.22, 0.20, 0.18, 0.10, 0.05];
      default:
        final eq = 1.0 / config.mealsPerDay;
        return List.filled(config.mealsPerDay, eq);
    }
  }

  // ─── GRASAS — front-loaded ────────────────────────────────────────────
  //
  // Principio: las grasas aportan saciedad y acompañan la actividad diurna.
  // La cena recibe mínimo de grasa para facilitar digestión nocturna.
  //
  // Con 3 comidas : [40%, 35%, 25%]
  // Con 4 comidas : [35%, 30%, 25%, 10%]
  // Con 5 comidas : [30%, 25%, 22%, 15%, 8%]
  // Con 6 comidas : [25%, 22%, 20%, 18%, 10%, 5%]
  List<double> _resolveFatPercents(MealDistributionConfig config) {
    if (config.fatPercentsOverride != null) {
      return config.fatPercentsOverride!;
    }
    switch (config.mealsPerDay) {
      case 3:
        return const [0.40, 0.35, 0.25];
      case 4:
        return const [0.35, 0.30, 0.25, 0.10];
      case 5:
        return const [0.30, 0.25, 0.22, 0.15, 0.08];
      case 6:
        return const [0.25, 0.22, 0.20, 0.18, 0.10, 0.05];
      default:
        final eq = 1.0 / config.mealsPerDay;
        return List.filled(config.mealsPerDay, eq);
    }
  }

  // ─── UMBRAL MÍNIMO DE PROTEÍNA ─────────────────────────────────────────
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

    if (totalDeficit == 0) return true;

    double totalSurplus = 0;
    for (final meal in meals) {
      if (meal.protein > minProteinPerMeal) {
        totalSurplus += (meal.protein - minProteinPerMeal);
      }
    }

    if (totalSurplus + 1e-6 < totalDeficit) return false;

    // Redistribuir proteína: mover excedente a comidas deficitarias
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
          donor.kcal -= transfer * 4;
          meal.kcal += transfer * 4;
          needed -= transfer;
          if (needed <= 0) break;
        }
      }
    }

    return true;
  }

  // ─── RECONCILIACIÓN DE RESIDUOS ────────────────────────────────────────
  void _reconcileTotals(
    List<_MealAllocation> meals, {
    required double kcalTarget,
    required double proteinTargetG,
    required double carbTargetG,
    required double fatTargetG,
  }) {
    for (final m in meals) {
      m.protein = _round1(m.protein);
      m.carbs = _round1(m.carbs);
      m.fat = _round1(m.fat);
      m.kcal = _round0(m.kcal);
    }

    if (meals.isEmpty) return;
    final last = meals.last;
    last.protein = _round1(
      last.protein +
          (proteinTargetG - meals.fold(0.0, (p, m) => p + m.protein)),
    );
    last.carbs = _round1(
      last.carbs + (carbTargetG - meals.fold(0.0, (p, m) => p + m.carbs)),
    );
    last.fat = _round1(
      last.fat + (fatTargetG - meals.fold(0.0, (p, m) => p + m.fat)),
    );
    last.kcal = _round0(
      last.kcal + (kcalTarget - meals.fold(0.0, (p, m) => p + m.kcal)),
    );
  }

  // ─── VALIDACIÓN ───────────────────────────────────────────────────────
  void _validateConfig(MealDistributionConfig config) {
    if (config.mealsPerDay < 3 || config.mealsPerDay > 6) {
      throw ArgumentError('mealsPerDay debe estar entre 3 y 6');
    }
    _validatePercents(
      config.kcalPercentsOverride,
      'kcalPercentsOverride',
      config.mealsPerDay,
    );
    _validatePercents(
      config.proteinPercentsOverride,
      'proteinPercentsOverride',
      config.mealsPerDay,
    );
    _validatePercents(
      config.carbPercentsOverride,
      'carbPercentsOverride',
      config.mealsPerDay,
    );
    _validatePercents(
      config.fatPercentsOverride,
      'fatPercentsOverride',
      config.mealsPerDay,
    );
  }

  void _validatePercents(List<double>? percents, String name, int mealsPerDay) {
    if (percents == null) return;
    if (percents.length != mealsPerDay) {
      throw ArgumentError('$name debe tener $mealsPerDay valores');
    }
    final sum = percents.reduce((a, b) => a + b);
    if ((sum - 1.0).abs() > _percentTolerance) {
      throw ArgumentError(
        '$name debe sumar aproximadamente 1.0 (suma actual: $sum)',
      );
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
