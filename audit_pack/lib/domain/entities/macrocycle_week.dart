import 'package:equatable/equatable.dart';

/// Modelo de datos para una semana específica dentro de un macrociclo de entrenamiento.
class MacrocycleWeek extends Equatable {
  /// El número de la semana en el plan (ej: 1, 2, ... 52).
  final int weekNumber;

  /// El nombre o identificador del bloque de entrenamiento (ej: "AA1", "HF1", "Deload").
  final String block;

  /// El volumen de entrenamiento objetivo para la semana, medido en series totales.
  final int targetVolume;

  /// El objetivo principal de la semana (ej: "Acumulación", "Intensificación").
  final String goal;

  /// Porcentaje de series pesadas.
  final double heavyPercent;

  /// Porcentaje de series medias.
  final double mediumPercent;

  /// Porcentaje de series ligeras.
  final double lightPercent;

  /// Notas adicionales o enfoque específico para la semana.
  final String? notes;

  const MacrocycleWeek({
    required this.weekNumber,
    required this.block,
    required this.targetVolume,
    required this.goal,
    this.heavyPercent = 0,
    this.mediumPercent = 0,
    this.lightPercent = 0,
    this.notes,
  });

  @override
  List<Object?> get props => [
    weekNumber,
    block,
    targetVolume,
    goal,
    heavyPercent,
    mediumPercent,
    lightPercent,
    notes,
  ];
}
