// lib/domain/training_v3/enums/training_enums.dart

/// Nivel de entrenamiento del atleta
enum TrainingLevel {
  novice,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case TrainingLevel.novice:
        return 'Principiante';
      case TrainingLevel.intermediate:
        return 'Intermedio';
      case TrainingLevel.advanced:
        return 'Avanzado';
    }
  }
}

/// Fase de periodización
enum TrainingPhase {
  accumulation,
  intensification,
  deload;

  String get displayName {
    switch (this) {
      case TrainingPhase.accumulation:
        return 'Acumulación';
      case TrainingPhase.intensification:
        return 'Intensificación';
      case TrainingPhase.deload:
        return 'Deload';
    }
  }

  int get typicalDurationWeeks {
    switch (this) {
      case TrainingPhase.accumulation:
        return 4;
      case TrainingPhase.intensification:
        return 2;
      case TrainingPhase.deload:
        return 1;
    }
  }
}

/// Zona de intensidad
enum IntensityZone {
  heavy,
  medium,
  light;

  String get displayName {
    switch (this) {
      case IntensityZone.heavy:
        return 'Heavy (6-8 reps)';
      case IntensityZone.medium:
        return 'Medium (8-12 reps)';
      case IntensityZone.light:
        return 'Light (16-20 reps)';
    }
  }

  List<int> get repRange {
    switch (this) {
      case IntensityZone.heavy:
        return [6, 8];
      case IntensityZone.medium:
        return [8, 12];
      case IntensityZone.light:
        return [16, 20];
    }
  }

  int get targetRir {
    switch (this) {
      case IntensityZone.heavy:
        return 3;
      case IntensityZone.medium:
        return 2;
      case IntensityZone.light:
        return 1;
    }
  }
}

/// Tipo de split
enum SplitType {
  fullBody,
  upperLower,
  pushPullLegs,
  bodyPart;

  String get displayName {
    switch (this) {
      case SplitType.fullBody:
        return 'Full Body';
      case SplitType.upperLower:
        return 'Upper/Lower';
      case SplitType.pushPullLegs:
        return 'Push/Pull/Legs';
      case SplitType.bodyPart:
        return 'Body Part Split';
    }
  }
}

/// Objetivo principal
enum TrainingGoal {
  hypertrophy,
  strength,
  endurance,
  generalFitness;

  String get displayName {
    switch (this) {
      case TrainingGoal.hypertrophy:
        return 'Hipertrofia';
      case TrainingGoal.strength:
        return 'Fuerza';
      case TrainingGoal.endurance:
        return 'Resistencia';
      case TrainingGoal.generalFitness:
        return 'Fitness General';
    }
  }
}

/// Estado de rendimiento
enum PerformanceStatus {
  improving,
  stable,
  declining,
  overreaching;

  String get displayName {
    switch (this) {
      case PerformanceStatus.improving:
        return 'Mejorando';
      case PerformanceStatus.stable:
        return 'Estable';
      case PerformanceStatus.declining:
        return 'Declinando';
      case PerformanceStatus.overreaching:
        return 'Sobreentrenamiento';
    }
  }

  String get icon {
    switch (this) {
      case PerformanceStatus.improving:
        return '📈';
      case PerformanceStatus.stable:
        return '➡️';
      case PerformanceStatus.declining:
        return '📉';
      case PerformanceStatus.overreaching:
        return '🛑';
    }
  }
}
