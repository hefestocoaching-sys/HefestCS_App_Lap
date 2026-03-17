/// Configuración para la distribución de macros entre comidas.
///
/// Permite definir perfiles independientes para proteína, carbohidratos y grasas.
/// Si no se especifica un override, cada macro usa su perfil inteligente por defecto
/// definido en MealDistributionService.
class MealDistributionConfig {
  final int mealsPerDay; // 3..6

  // ── Proteína ──────────────────────────────────────────────────────────
  /// Factor mínimo de proteína por comida en g/kg peso corporal.
  /// Rango objetivo: 1.2–1.6 g/kg distribuido parejo.
  /// Si totalProtein/kg >= 1.8, distribución uniforme entre todas las comidas.
  final double minProteinPerMealPerKg;
  final bool enforceProteinThreshold;
  final double? minProteinPerMealAbsolute;

  // ── Overrides de porcentajes (opcionales) ─────────────────────────────
  /// Si se especifica, reemplaza la distribución inteligente de kcal totales.
  final List<double>? kcalPercentsOverride;

  /// Porcentajes de proteína por comida. Si null, distribución uniforme.
  final List<double>? proteinPercentsOverride;

  /// Porcentajes de carbohidratos por comida.
  /// Si null, usa perfil "carb-front-loaded": más en desayuno/almuerzo, menos en cena.
  final List<double>? carbPercentsOverride;

  /// Porcentajes de grasas por comida.
  /// Si null, usa perfil "fat-front-loaded": más en desayuno/almuerzo, menos en cena.
  final List<double>? fatPercentsOverride;

  const MealDistributionConfig({
    required this.mealsPerDay,
    this.minProteinPerMealPerKg = 0.25,
    this.enforceProteinThreshold = true,
    this.minProteinPerMealAbsolute,
    this.kcalPercentsOverride,
    this.proteinPercentsOverride,
    this.carbPercentsOverride,
    this.fatPercentsOverride,
  });
}
