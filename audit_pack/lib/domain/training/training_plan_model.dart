// Modelos para representar un plan de entrenamiento generado.
// El plan es independiente del motor y está pensado para exportación.

class TrainingPlan {
  final String id; // Identificador único
  final String templateId; // ID de la plantilla de split
  final String templateName; // Nombre de la plantilla (ej: "Torso/Pierna")
  final int daysPerWeek; // Días de entrenamiento por semana
  final List<PlanWeek> weeks; // 4 semanas
  final DateTime generatedAt; // Fecha de generación
  final String? adaptationNotes; // Notas sobre adaptación por bitácora

  TrainingPlan({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.daysPerWeek,
    required this.weeks,
    required this.generatedAt,
    this.adaptationNotes,
  });

  /// Obtener la semana actual (1-4)
  PlanWeek getWeek(int weekNumber) {
    if (weekNumber < 1 || weekNumber > weeks.length) {
      throw RangeError('Semana debe estar entre 1 y ${weeks.length}');
    }
    return weeks[weekNumber - 1];
  }

  /// Volumen total del plan
  int getTotalVolume() {
    return weeks.fold(0, (sum, week) => sum + week.getTotalVolume());
  }
}

class PlanWeek {
  final int weekNumber; // 1-4
  final List<PlanDay> days; // Días de entrenamiento
  final String? adaptationReason; // Razón de adaptación si aplica

  PlanWeek({
    required this.weekNumber,
    required this.days,
    this.adaptationReason,
  });

  /// Volumen total de la semana
  int getTotalVolume() {
    return days.fold(0, (sum, day) => sum + day.getTotalSeries());
  }

  /// Obtener un día específico
  PlanDay? getDayByNumber(int dayNumber) {
    try {
      return days[dayNumber - 1];
    } catch (_) {
      return null;
    }
  }
}

class PlanDay {
  final int dayNumber; // 1-6 (número dentro de la semana)
  final String dayLabel; // "Día 1", "Lunes", etc.
  final Map<String, DayMuscleVolume>
  muscleVolumes; // muscleGroup → volumen con distribución H/M/L
  final String? notes; // Notas opcionales del día

  PlanDay({
    required this.dayNumber,
    required this.dayLabel,
    required this.muscleVolumes,
    this.notes,
  });

  /// Series totales del día
  int getTotalSeries() {
    return muscleVolumes.values.fold(0, (sum, vol) => sum + vol.total);
  }

  /// Obtener músculos del día (nombres)
  List<String> getMuscles() {
    return muscleVolumes.keys.toList();
  }

  /// Obtener volumen para un músculo específico
  DayMuscleVolume? getVolumeForMuscle(String muscleName) {
    return muscleVolumes[muscleName];
  }
}

class DayMuscleVolume {
  final String muscleName; // "Pectoral", "Dorsal Ancho", etc.
  final int total; // Series totales
  final int heavy; // Series pesadas (>6 reps)
  final int medium; // Series medias (6-15 reps)
  final int light; // Series ligeras (<15 reps)
  final String source; // "PLAN", "AUTO", "REAL"

  DayMuscleVolume({
    required this.muscleName,
    required this.total,
    required this.heavy,
    required this.medium,
    required this.light,
    required this.source,
  });

  /// Validar distribución H/M/L
  bool isValidDistribution() {
    return (heavy + medium + light) == total;
  }
}
