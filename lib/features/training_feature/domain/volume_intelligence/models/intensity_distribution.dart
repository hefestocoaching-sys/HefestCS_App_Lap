import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';

/// Modelo de distribución de intensidad para series pesadas, moderadas y ligeras
///
/// Los porcentajes deben:
/// - Sumar 100% (con tolerancia de 0.01)
/// - Estar dentro de rangos válidos:
///   * Heavy: 15-30%
///   * Moderate: 40-70%
///   * Light: 15-30%
@immutable
class IntensityDistribution {
  /// Porcentaje de series pesadas (0.15 - 0.30)
  final double heavyPct;

  /// Porcentaje de series moderadas (0.40 - 0.70)
  final double moderatePct;

  /// Porcentaje de series ligeras (0.15 - 0.30)
  final double lightPct;

  // Rangos válidos
  static const double minHeavyPct = 0.15;
  static const double maxHeavyPct = 0.30;
  static const double minModeratePct = 0.40;
  static const double maxModeratePct = 0.70;
  static const double minLightPct = 0.15;
  static const double maxLightPct = 0.30;

  const IntensityDistribution({
    required this.heavyPct,
    required this.moderatePct,
    required this.lightPct,
  });

  /// Factory para crear distribución con defaults según nivel de entrenamiento
  factory IntensityDistribution.forLevel(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        // Principiante: Menos pesadas, más énfasis en técnica
        return const IntensityDistribution(
          heavyPct: 0.15,
          moderatePct: 0.55,
          lightPct: 0.30,
        );
      case TrainingLevel.intermediate:
        // Intermedio: Balance equilibrado
        return const IntensityDistribution(
          heavyPct: 0.20,
          moderatePct: 0.60,
          lightPct: 0.20,
        );
      case TrainingLevel.advanced:
        // Avanzado: Más pesadas, menos ligeras
        return const IntensityDistribution(
          heavyPct: 0.30,
          moderatePct: 0.50,
          lightPct: 0.20,
        );
    }
  }

  /// Factory con valores estándar (intermediate)
  factory IntensityDistribution.standard() {
    return IntensityDistribution.forLevel(TrainingLevel.intermediate);
  }

  /// Valida que los porcentajes sumen 100% (con tolerancia)
  bool get isValid {
    final sum = heavyPct + moderatePct + lightPct;
    return (sum - 1.0).abs() < 0.001; // Tolerancia de 0.1%
  }

  /// Valida que todos los porcentajes estén en rangos permitidos
  bool get isWithinRanges {
    return heavyPct >= minHeavyPct &&
        heavyPct <= maxHeavyPct &&
        moderatePct >= minModeratePct &&
        moderatePct <= maxModeratePct &&
        lightPct >= minLightPct &&
        lightPct <= maxLightPct;
  }

  /// Valida que la distribución sea completamente correcta
  bool get isFullyValid => isValid && isWithinRanges;

  /// Calcula el número de series por tipo de intensidad dado un total
  IntensitySetsBreakdown calculateSets(int totalSets) {
    final heavy = (totalSets * heavyPct).round();
    final moderate = (totalSets * moderatePct).round();
    final light = totalSets - heavy - moderate; // Asegurar suma exacta

    return IntensitySetsBreakdown(
      heavy: heavy,
      moderate: moderate,
      light: light,
      total: totalSets,
    );
  }

  /// Copia con modificaciones
  IntensityDistribution copyWith({
    double? heavyPct,
    double? moderatePct,
    double? lightPct,
  }) {
    return IntensityDistribution(
      heavyPct: heavyPct ?? this.heavyPct,
      moderatePct: moderatePct ?? this.moderatePct,
      lightPct: lightPct ?? this.lightPct,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntensityDistribution &&
          heavyPct == other.heavyPct &&
          moderatePct == other.moderatePct &&
          lightPct == other.lightPct;

  @override
  int get hashCode =>
      heavyPct.hashCode ^ moderatePct.hashCode ^ lightPct.hashCode;

  @override
  String toString() {
    return 'IntensityDistribution('
        'heavy: ${(heavyPct * 100).toStringAsFixed(1)}%, '
        'moderate: ${(moderatePct * 100).toStringAsFixed(1)}%, '
        'light: ${(lightPct * 100).toStringAsFixed(1)}%)';
  }
}

/// Resultado del desglose de series por intensidad
@immutable
class IntensitySetsBreakdown {
  final int heavy;
  final int moderate;
  final int light;
  final int total;

  const IntensitySetsBreakdown({
    required this.heavy,
    required this.moderate,
    required this.light,
    required this.total,
  });

  /// Verifica que la suma sea correcta
  bool get isValid => heavy + moderate + light == total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntensitySetsBreakdown &&
          heavy == other.heavy &&
          moderate == other.moderate &&
          light == other.light &&
          total == other.total;

  @override
  int get hashCode =>
      heavy.hashCode ^ moderate.hashCode ^ light.hashCode ^ total.hashCode;

  @override
  String toString() {
    return 'IntensitySetsBreakdown(H: $heavy, M: $moderate, L: $light, Total: $total)';
  }
}
