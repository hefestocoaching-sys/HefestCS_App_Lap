enum TrainingGoal {
  hypertrophy,
  strength,
  power,
  endurance,
  generalFitness,

  // Alias requeridos por el motor
  performance, // Alias de power/strength mixto
  fatLoss, // Alias de hypertrophy (con deficit)
}

extension TrainingGoalX on TrainingGoal {
  String get label {
    switch (this) {
      case TrainingGoal.hypertrophy:
        return 'Hipertrofia';
      case TrainingGoal.strength:
        return 'Fuerza Máxima';
      case TrainingGoal.power:
      case TrainingGoal.performance:
        return 'Rendimiento Deportivo';
      case TrainingGoal.fatLoss:
        return 'Pérdida de Grasa';
      case TrainingGoal.endurance:
        return 'Resistencia';
      default:
        return 'Salud General';
    }
  }
}
