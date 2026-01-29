import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

/// Helpers determinísticos para auditoría del motor de entrenamiento

/// Computa frecuencia semanal de cada músculo basado en plan config
Map<String, int> computeWeeklyMuscleFrequency(TrainingPlanConfig plan) {
  final frequency = <String, int>{};

  for (final week in plan.weeks) {
    for (final session in week.sessions) {
      for (final prescription in session.prescriptions) {
        final muscle = prescription.muscleGroup.name;
        frequency[muscle] = (frequency[muscle] ?? 0) + 1;
      }
    }
  }

  // Normalizar por número de semanas
  if (plan.weeks.isNotEmpty) {
    final weeks = plan.weeks.length;
    frequency.updateAll((k, v) => (v / weeks).round());
  }

  return frequency;
}

/// Computa total de sets por músculo para todo el plan
Map<String, int> computeTotalSetsByMuscle(TrainingPlanConfig plan) {
  final totals = <String, int>{};

  for (final week in plan.weeks) {
    for (final session in week.sessions) {
      for (final prescription in session.prescriptions) {
        final muscle = prescription.muscleGroup.name;
        totals[muscle] = (totals[muscle] ?? 0) + prescription.sets;
      }
    }
  }

  return totals;
}

/// Convierte Decision Trace a formato human-readable
String formatDecisionTrace(Map<String, dynamic> trace) {
  final phase = trace['phase'] ?? 'unknown';
  final category = trace['category'] ?? '';
  final description = trace['description'] ?? '';
  return '$phase / $category: $description';
}

/// Resumen de señales detectadas en la auditoría
String buildSignalsSummary(Map<String, dynamic>? metrics) {
  if (metrics == null) return 'Sin datos de señales';

  final signals = <String>[];
  if (metrics['fatigueSignal'] == true) signals.add('Fatiga detectada');
  if (metrics['progressSignal'] == true) signals.add('Progreso detectado');
  if (metrics['plateauSignal'] == true) signals.add('Plateau detectado');
  if (metrics['lowAdherence'] == true) signals.add('Adherencia baja');

  return signals.isEmpty ? 'Sin señales especiales' : signals.join(', ');
}
