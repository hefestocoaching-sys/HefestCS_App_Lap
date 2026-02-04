import 'package:hcs_app_lap/domain/training_v3/models/performance_metrics.dart';

/// Enum que define las fases de periodización del macrociclo.
///
/// - `accumulation`: Fase de acumulación (semanas 1-4) - énfasis en volumen
/// - `intensification`: Fase de intensificación (semana 5) - énfasis en intensidad
/// - `deload`: Fase de descarga (semanas 6+) - recuperación activa
enum TrainingPhase { accumulation, intensification, deload }

/// Motor científico de periodización para la progresión del entrenamiento.
///
/// Implementa principios científicos de periodización basados en:
/// - Williams et al. (2017) sobre periodización lineal y ondulante
/// - Schoenfeld et al. (2019) sobre volumen progresivo y ganancia muscular
/// - Semana 7 del documento científico de programa progresivo
///
/// La periodización es fundamental para optimizar la progresión manteniendo
/// una recuperación adecuada y evitando plateaus de rendimiento.
class PeriodizationEngine {
  /// Determina la fase de periodización actual basada en la semana del mesociclo
  /// y las métricas de rendimiento del atleta.
  ///
  /// **Algoritmo de determinación de fase:**
  /// - Semanas 1-4: `accumulation` (acumulación de volumen)
  /// - Semana 5: `intensification` (pico de intensidad)
  /// - Semana 6+: `deload` (recuperación)
  ///
  /// **Override condicional:**
  /// Si `metrics.requiresImmediateDeload == true`, retorna `deload`
  /// sin importar la semana actual (permite flexibilidad basada en rendimiento).
  ///
  /// Parámetros:
  /// - `weekInMesocycle`: semana actual dentro del mesociclo (1-6+)
  /// - `metrics`: métricas de rendimiento del atleta (fatiga, dolor, sueño)
  ///
  /// Retorna:
  /// - `TrainingPhase` correspondiente a la semana o estado del atleta
  static TrainingPhase determinePhase(
    int weekInMesocycle,
    PerformanceMetrics metrics,
  ) {
    // Override por fatiga acumulada o lesión
    if (metrics.requiresImmediateDeload) {
      return TrainingPhase.deload;
    }

    // Determinación según semana del mesociclo
    if (weekInMesocycle >= 1 && weekInMesocycle <= 4) {
      return TrainingPhase.accumulation;
    } else if (weekInMesocycle == 5) {
      return TrainingPhase.intensification;
    } else {
      return TrainingPhase.deload;
    }
  }

  /// Calcula el volumen semanal objetivo basado en la fase de periodización.
  ///
  /// **Fórmula por fase:**
  /// - `accumulation`: baselineVolume + (weekInPhase × 2)
  ///   Aumenta 2 sets por semana para acumulación progresiva
  /// - `intensification`: (baselineVolume × 0.9).round()
  ///   Reduce 10% para permitir mayor intensidad
  /// - `deload`: (baselineVolume × 0.5).round()
  ///   Reduce 50% para recuperación activa
  ///
  /// Bases científicas (Schoenfeld et al. 2019):
  /// La progresión de volumen es crucial para hipertrofia muscular,
  /// pero debe balancearse con períodos de intensidad y recuperación.
  ///
  /// Parámetros:
  /// - `phase`: fase de periodización actual
  /// - `baselineVolume`: volumen base para el músculo/ciclo
  /// - `weekInPhase`: semana dentro de la fase actual (1-4 para acumulación)
  ///
  /// Retorna:
  /// - Volumen semanal total en sets
  static int calculateWeeklyVolume(
    TrainingPhase phase,
    int baselineVolume,
    int weekInPhase,
  ) {
    switch (phase) {
      case TrainingPhase.accumulation:
        // Progresión lineal: +2 sets por semana
        return baselineVolume + (weekInPhase * 2);

      case TrainingPhase.intensification:
        // Reducción del 10% para mayor intensidad
        return (baselineVolume * 0.9).round();

      case TrainingPhase.deload:
        // Reducción del 50% para recuperación
        return (baselineVolume * 0.5).round();
    }
  }

  /// Asigna el RIR (Reps in Reserve) objetivo según la fase y semana.
  ///
  /// **RIR por fase:**
  /// - `accumulation`: 2.5 (moderado, enfoque en técnica y volumen)
  /// - `intensification`: 2.0 - weekInPhase (descendente: 1.0, 0.0, etc.)
  ///   Permite llegar más cerca del fallo conforme avanza la semana
  /// - `deload`: 4.0 (conservador, enfoque en recuperación)
  ///
  /// El RIR es la métrica de esfuerzo clave que define cuántas repeticiones
  /// podría completar el atleta antes de fallar. Un RIR menor = mayor intensidad.
  ///
  /// Parámetros:
  /// - `phase`: fase de periodización actual
  /// - `weekInPhase`: semana dentro de la fase actual
  ///
  /// Retorna:
  /// - RIR objetivo como double (puede ser 0.0, 1.5, 2.0, 4.0, etc.)
  static double calculateTargetRIR(TrainingPhase phase, int weekInPhase) {
    switch (phase) {
      case TrainingPhase.accumulation:
        // RIR constante para acumulación segura
        return 2.5;

      case TrainingPhase.intensification:
        // Descenso progresivo: más intenso conforme avanza
        return (2.0 - weekInPhase).clamp(0.0, 2.0);

      case TrainingPhase.deload:
        // RIR alto para recuperación sin estrés
        return 4.0;
    }
  }
}
