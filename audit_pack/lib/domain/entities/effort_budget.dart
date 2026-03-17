import 'package:equatable/equatable.dart';

/// Presupuesto de esfuerzo para técnicas de intensificación.
/// Limita cuántas técnicas avanzadas se pueden aplicar por semana y por músculo.
class EffortBudget extends Equatable {
  /// Máximo de técnicas de intensificación permitidas por semana
  final int maxTechniquesPerWeek;

  /// Técnicas restantes disponibles para toda la semana
  final int remainingTechniques;

  /// Técnicas restantes disponibles por músculo específico
  final Map<String, int> perMuscleRemaining;

  const EffortBudget({
    required this.maxTechniquesPerWeek,
    required this.remainingTechniques,
    required this.perMuscleRemaining,
  });

  /// Crea un presupuesto inicial basado en el límite semanal
  factory EffortBudget.initial({
    required int maxTechniquesPerWeek,
    required List<String> muscles,
    int maxPerMuscle = 1,
  }) {
    return EffortBudget(
      maxTechniquesPerWeek: maxTechniquesPerWeek,
      remainingTechniques: maxTechniquesPerWeek,
      perMuscleRemaining: {for (final muscle in muscles) muscle: maxPerMuscle},
    );
  }

  /// Verifica si se puede aplicar una técnica para un músculo dado
  bool canApply(String muscle) {
    // Debe haber presupuesto global y por músculo
    if (remainingTechniques <= 0) return false;
    final muscleRemaining = perMuscleRemaining[muscle] ?? 0;
    return muscleRemaining > 0;
  }

  /// Consume una unidad del presupuesto para un músculo dado
  /// Retorna un nuevo EffortBudget con el presupuesto actualizado
  EffortBudget consume(String muscle) {
    if (!canApply(muscle)) {
      // Si no se puede aplicar, retornar sin cambios
      return this;
    }

    final newPerMuscle = Map<String, int>.from(perMuscleRemaining);
    final currentMuscleRemaining = newPerMuscle[muscle] ?? 0;
    newPerMuscle[muscle] = (currentMuscleRemaining - 1).clamp(0, 999);

    return EffortBudget(
      maxTechniquesPerWeek: maxTechniquesPerWeek,
      remainingTechniques: (remainingTechniques - 1).clamp(0, 999),
      perMuscleRemaining: newPerMuscle,
    );
  }

  /// Crea una copia del presupuesto con valores opcionales modificados
  EffortBudget copyWith({
    int? maxTechniquesPerWeek,
    int? remainingTechniques,
    Map<String, int>? perMuscleRemaining,
  }) {
    return EffortBudget(
      maxTechniquesPerWeek: maxTechniquesPerWeek ?? this.maxTechniquesPerWeek,
      remainingTechniques: remainingTechniques ?? this.remainingTechniques,
      perMuscleRemaining: perMuscleRemaining ?? this.perMuscleRemaining,
    );
  }

  /// Verifica si el presupuesto está agotado
  bool get isExhausted => remainingTechniques <= 0;

  /// Verifica si el presupuesto está completo (sin uso)
  bool get isFull => remainingTechniques == maxTechniquesPerWeek;

  @override
  List<Object?> get props => [
    maxTechniquesPerWeek,
    remainingTechniques,
    perMuscleRemaining,
  ];

  @override
  String toString() {
    return 'EffortBudget(remaining: $remainingTechniques/$maxTechniquesPerWeek, '
        'perMuscle: $perMuscleRemaining)';
  }
}
