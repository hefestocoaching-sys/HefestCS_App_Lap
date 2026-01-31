/// Rest Period Calculator - Calculadora de descanso entre series
///
/// Referencias científicas:
/// - Schoenfeld et al. (2016) J Strength Cond Res 30(7):1805-1812
/// - NSCA (2024) Essentials Chapter 17
/// - ACSM (2022) Quantity and Quality of Exercise
class RestPeriodCalculator {
  /// Tabla de referencia de descanso por objetivo de entrenamiento
  static const Map<String, Map<String, int>> referenceTable = {
    'strength': {
      'compound': 240, // 4:00
      'isolation': 180, // 3:00
    },
    'hypertrophy': {
      'compound': 150, // 2:30
      'isolation': 90, // 1:30
    },
    'endurance': {
      'compound': 90, // 1:30
      'isolation': 60, // 1:00
    },
  };

  /// Calcula el descanso óptimo entre series en segundos
  ///
  /// [targetReps]: Número de repeticiones objetivo
  /// [isCompound]: true si es ejercicio compuesto, false si es aislamiento
  /// [intensityPercent]: Porcentaje de 1RM (opcional, toma prioridad sobre reps)
  ///
  /// Retorna el tiempo de descanso en segundos
  static int getRestSeconds(
    int targetReps,
    bool isCompound, [
    double? intensityPercent,
  ]) {
    // Si se proporciona intensidad, usarla como prioridad
    if (intensityPercent != null) {
      return _getRestByIntensity(intensityPercent, isCompound);
    }

    // Caso contrario, usar las repeticiones
    return _getRestByReps(targetReps, isCompound);
  }

  /// Calcula descanso basado en intensidad (%1RM)
  static int _getRestByIntensity(double intensity, bool isCompound) {
    // Fuerza: >= 85% 1RM
    if (intensity >= 0.85) {
      return isCompound ? 240 : 180;
    }

    // Hipertrofia: 65-85% 1RM
    if (intensity >= 0.65) {
      return isCompound ? 150 : 90;
    }

    // Resistencia: < 65% 1RM
    return isCompound ? 90 : 60;
  }

  /// Calcula descanso basado en repeticiones
  static int _getRestByReps(int reps, bool isCompound) {
    // Fuerza: 1-5 reps
    if (reps <= 5) {
      return isCompound ? 240 : 180;
    }

    // Hipertrofia: 6-12 reps
    if (reps <= 12) {
      return isCompound ? 150 : 90;
    }

    // Resistencia: 12-15+ reps
    return isCompound ? 90 : 60;
  }

  /// Formatea el tiempo de descanso en formato MM:SS
  ///
  /// Ejemplo: 150 segundos → "2:30"
  static String formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Obtiene el descanso con formato para un objetivo específico
  static String getFormattedRest(
    int targetReps,
    bool isCompound, [
    double? intensityPercent,
  ]) {
    final seconds = getRestSeconds(targetReps, isCompound, intensityPercent);
    return formatRestTime(seconds);
  }

  /// Obtiene el rango de descanso recomendado (min, max) en segundos
  ///
  /// Retorna un rango de ±15 segundos del valor calculado
  static (int, int) getRestRange(
    int targetReps,
    bool isCompound, [
    double? intensityPercent,
  ]) {
    final base = getRestSeconds(targetReps, isCompound, intensityPercent);
    return (base - 15, base + 15);
  }

  /// Obtiene recomendaciones detalladas de descanso
  static Map<String, dynamic> getRestRecommendations(
    int targetReps,
    bool isCompound, [
    double? intensityPercent,
  ]) {
    final seconds = getRestSeconds(targetReps, isCompound, intensityPercent);
    final formatted = formatRestTime(seconds);
    final (minRange, maxRange) = getRestRange(
      targetReps,
      isCompound,
      intensityPercent,
    );

    String goal;
    if (intensityPercent != null) {
      if (intensityPercent >= 0.85) {
        goal = 'strength';
      } else if (intensityPercent >= 0.65) {
        goal = 'hypertrophy';
      } else {
        goal = 'endurance';
      }
    } else {
      if (targetReps <= 5) {
        goal = 'strength';
      } else if (targetReps <= 12) {
        goal = 'hypertrophy';
      } else {
        goal = 'endurance';
      }
    }

    return {
      'seconds': seconds,
      'formatted': formatted,
      'minSeconds': minRange,
      'maxSeconds': maxRange,
      'minFormatted': formatRestTime(minRange),
      'maxFormatted': formatRestTime(maxRange),
      'goal': goal,
      'exerciseType': isCompound ? 'compound' : 'isolation',
    };
  }
}
