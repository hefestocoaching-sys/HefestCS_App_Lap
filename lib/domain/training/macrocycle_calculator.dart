// ignore_for_file: dangling_library_doc_comments

/// Utilidad para calcular volumen efectivo desde una semana del macrocycle
///
/// Transforma el VOP base (de Tab 1) aplicando el multiplicador de la semana.
/// El reparto de intensidades (Pesadas/Medias/Ligeras) se reutiliza sin cambios.

import 'package:hcs_app_lap/domain/training/intensity_split_utils.dart';
import 'package:hcs_app_lap/domain/training/macrocycle_week.dart';

/// Calcula el VOP efectivo para una semana del macrocycle.
///
/// NO modifica el reparto de intensidades.
/// NO toca VME/VMR.
///
/// Ejemplo:
/// ```
/// final baseVop = 12.0; // De Tab 1
/// final week = macrocycle[4]; // Semana 5
/// final effectiveVop = calculateEffectiveVopForWeek(baseVop, week);
/// // effectiveVop = 12.0 * 1.1 = 13.2
/// ```
double calculateEffectiveVopForWeek(double baseVop, MacrocycleWeek week) {
  return week.calculateEffectiveVolume(baseVop);
}

/// Calcula la distribución de series (Pesadas/Medias/Ligeras) para una semana
/// manteniendo exactamente el mismo perfil de intensidades.
///
/// El perfil viene de Tab 2 y NO cambia por macrocycle.
///
/// Ejemplo:
/// ```
/// final effectiveVop = 13.2;
/// final intensitySplit = {'heavy': 0.25, 'medium': 0.5, 'light': 0.25};
/// final distribution = calculateIntensityDistributionForWeek(
///   effectiveVop,
///   intensitySplit,
/// );
/// // distribution = {'heavy': 3, 'medium': 7, 'light': 3}
/// ```
Map<String, int> calculateIntensityDistributionForWeek(
  double effectiveVop,
  Map<String, double> intensitySplit,
) {
  return splitByIntensity(
    totalSets: effectiveVop,
    intensitySplit: intensitySplit,
  );
}

/// Información resumida de una semana del macrocycle con volúmenes calculados.
class MacrocycleWeekSummary {
  final MacrocycleWeek week;
  final double baseVop;
  final double effectiveVop;
  final Map<String, double> intensitySplit;
  final Map<String, int> distribution;

  MacrocycleWeekSummary({
    required this.week,
    required this.baseVop,
    required this.effectiveVop,
    required this.intensitySplit,
    required this.distribution,
  });

  /// Factory para crear un resumen a partir de datos base
  factory MacrocycleWeekSummary.calculate({
    required MacrocycleWeek week,
    required double baseVop,
    required Map<String, double> intensitySplit,
  }) {
    final effectiveVop = calculateEffectiveVopForWeek(baseVop, week);
    final distribution = calculateIntensityDistributionForWeek(
      effectiveVop,
      intensitySplit,
    );

    return MacrocycleWeekSummary(
      week: week,
      baseVop: baseVop,
      effectiveVop: effectiveVop,
      intensitySplit: intensitySplit,
      distribution: distribution,
    );
  }

  /// Retorna la información de forma legible
  @override
  String toString() =>
      'W${week.weekNumber}: VOP ${baseVop.toStringAsFixed(1)} → ${effectiveVop.toStringAsFixed(1)} (${week.volumeMultiplier}×) | '
      'H:${distribution['heavy']} M:${distribution['medium']} L:${distribution['light']}';
}
