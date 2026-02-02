// lib/domain/training_v3/engines/load_progression_engine.dart

import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';

/// Motor de progresión de carga
///
/// Implementa progresión conservadora basada en RPE/RIR real:
/// - Si RPE < target → aumentar peso
/// - Si RPE = target → mantener peso
/// - Si RPE > target → reducir peso
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Autoregulación de carga
/// - Progresión basada en rendimiento real (no tablas fijas)
/// - Principio de sobrecarga progresiva
///
/// REFERENCIAS:
/// - Helms et al. (2018): RPE-based load progression
/// - Mann et al. (2010): Autoregulatory training
///
/// Versión: 1.0.0
class LoadProgressionEngine {
  /// Calcula nueva carga recomendada para próxima sesión
  ///
  /// ALGORITMO:
  /// 1. Comparar RPE real vs target
  /// 2. Aplicar ajuste porcentual según delta
  /// 3. Validar safety bounds
  ///
  /// PARÁMETROS:
  /// - [exerciseLog]: Log del ejercicio sesión anterior
  /// - [targetRir]: RIR planeado original
  /// - [currentLoad]: Carga usada (kg)
  ///
  /// RETORNA:
  /// - double: Nueva carga recomendada (kg)
  static double calculateNextLoad({
    required ExerciseLog exerciseLog,
    required int targetRir,
    required double currentLoad,
  }) {
    // PASO 1: Calcular target RPE desde RIR
    final targetRpe = 10 - targetRir;

    // PASO 2: Obtener RPE real (promedio de sets)
    final actualRpe = exerciseLog.averageRpe;

    // PASO 3: Calcular delta
    final rpeDelta = actualRpe - targetRpe;

    // PASO 4: Determinar ajuste porcentual
    double adjustment;

    if (rpeDelta > 1.5) {
      // RPE muy alto → reducir carga
      adjustment = -0.05; // -5%
    } else if (rpeDelta > 0.5) {
      // RPE ligeramente alto → mantener
      adjustment = 0.0;
    } else if (rpeDelta > -0.5) {
      // RPE en target → progresión mínima
      adjustment = 0.025; // +2.5%
    } else if (rpeDelta > -1.5) {
      // RPE bajo → progresión moderada
      adjustment = 0.05; // +5%
    } else {
      // RPE muy bajo → progresión agresiva
      adjustment = 0.075; // +7.5%
    }

    // PASO 5: Aplicar ajuste
    final newLoad = currentLoad * (1 + adjustment);

    // PASO 6: Redondear a 2.5kg (placas estándar)
    return _roundToNearestPlate(newLoad);
  }

  /// Redondea a la placa más cercana (2.5kg)
  static double _roundToNearestPlate(double weight) {
    final plateIncrement = 2.5;
    return (weight / plateIncrement).round() * plateIncrement;
  }

  /// Calcula progresión de volumen (reps × sets)
  ///
  /// REGLA: Priorizar aumento de carga sobre aumento de reps
  ///
  /// ESTRATEGIA:
  /// 1. Intentar aumentar peso primero
  /// 2. Si peso no puede subir, aumentar reps
  /// 3. Si reps en límite superior (12+), forzar aumento de peso y bajar reps
  static Map<String, dynamic> calculateVolumetricProgression({
    required ExerciseLog exerciseLog,
    required List<int> targetRepRange,
    required double currentLoad,
  }) {
    final avgReps =
        exerciseLog.sets.fold(0, (sum, s) => sum + s.reps) /
        exerciseLog.sets.length;
    final avgRpe = exerciseLog.averageRpe;

    // Si reps están en límite superior del rango Y RPE < 8
    if (avgReps >= targetRepRange[1] && avgRpe < 8.0) {
      // Aumentar peso y resetear reps al límite inferior
      return {
        'new_load': _roundToNearestPlate(currentLoad * 1.05),
        'new_rep_target': targetRepRange[0],
        'reasoning':
            'Reps en límite superior + RPE bajo → aumentar peso y resetear reps',
      };
    }

    // Si reps están en rango Y RPE en target
    if (avgReps >= targetRepRange[0] &&
        avgReps <= targetRepRange[1] &&
        avgRpe >= 7.0 &&
        avgRpe <= 9.0) {
      // Intentar aumentar 1 rep
      return {
        'new_load': currentLoad,
        'new_rep_target': (avgReps + 1).toInt().clamp(
          targetRepRange[0],
          targetRepRange[1],
        ),
        'reasoning': 'RPE en target → aumentar reps antes de peso',
      };
    }

    // Si RPE muy bajo (< 7)
    if (avgRpe < 7.0) {
      return {
        'new_load': _roundToNearestPlate(currentLoad * 1.05),
        'new_rep_target': avgReps.toInt(),
        'reasoning': 'RPE bajo → aumentar carga',
      };
    }

    // Default: mantener
    return {
      'new_load': currentLoad,
      'new_rep_target': avgReps.toInt(),
      'reasoning': 'Mantener parámetros actuales',
    };
  }

  /// Detecta estancamiento (plateau)
  ///
  /// CRITERIO: Misma carga por 3+ sesiones sin mejorar reps
  static bool detectPlateau({
    required List<ExerciseLog> historicalLogs,
    required int minSessions,
  }) {
    if (historicalLogs.length < minSessions) return false;

    final recentLogs = historicalLogs.take(minSessions).toList();

    // Verificar si todas las sesiones tienen carga/reps similares
    final firstLog = recentLogs.first;
    final firstAvgReps =
        firstLog.sets.fold(0, (sum, s) => sum + s.reps) / firstLog.sets.length;
    final firstAvgWeight =
        firstLog.sets.fold(0.0, (sum, s) => sum + s.weight) /
        firstLog.sets.length;

    for (final log in recentLogs.skip(1)) {
      final avgReps =
          log.sets.fold(0, (sum, s) => sum + s.reps) / log.sets.length;
      final avgWeight =
          log.sets.fold(0.0, (sum, s) => sum + s.weight) / log.sets.length;

      // Si hay variación, no es plateau
      if ((avgReps - firstAvgReps).abs() > 1 ||
          (avgWeight - firstAvgWeight).abs() > 5) {
        return false;
      }
    }

    return true; // Mismo peso/reps por minSessions
  }

  /// Sugiere variación para romper plateau
  ///
  /// ESTRATEGIAS:
  /// 1. Cambiar rango de reps (heavy → moderate, etc.)
  /// 2. Cambiar ejercicio (variación)
  /// 3. Técnica de intensificación (drop sets, rest-pause)
  static Map<String, dynamic> suggestPlateauBreaker({
    required String currentIntensity,
    required String exerciseId,
  }) {
    final strategies = <String>[];

    // Estrategia 1: Cambiar zona de intensidad
    if (currentIntensity == 'heavy') {
      strategies.add('Cambiar a moderate (8-12 reps) por 2-3 semanas');
    } else if (currentIntensity == 'moderate') {
      strategies.add('Alternar: 1 semana heavy (5-8 reps), 1 semana moderate');
    }

    // Estrategia 2: Variación de ejercicio
    strategies.add(
      'Cambiar a variación del ejercicio por 2-3 semanas, luego volver',
    );

    // Estrategia 3: Técnicas avanzadas
    strategies.add('Aplicar drop sets en última serie');
    strategies.add('Aplicar rest-pause en última serie');

    return {
      'plateau_detected': true,
      'strategies': strategies,
      'recommended_duration': '2-3 semanas',
    };
  }

  /// Calcula 1RM estimado desde peso × reps × RPE
  ///
  /// FÓRMULA: Epley modificada con factor RPE
  static double estimate1RM({
    required double weight,
    required int reps,
    required double rpe,
  }) {
    if (reps == 1) return weight;

    // Epley: 1RM = weight × (1 + reps/30)
    var estimated1RM = weight * (1 + reps / 30);

    // Ajustar por RPE (si RPE < 10, había reps en reserva)
    final rir = (10 - rpe).round();
    if (rir > 0) {
      // Aumentar estimación proporcionalmente
      estimated1RM = estimated1RM * (1 + rir * 0.025);
    }

    return estimated1RM;
  }
}
