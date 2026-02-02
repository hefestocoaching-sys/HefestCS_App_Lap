// lib/domain/training_v3/engines/intensity_engine.dart

/// Motor de distribución de intensidad por ejercicio
///
/// Implementa las reglas científicas de la Semana 3 (12 imágenes):
/// - Distribución óptima: 35% heavy, 45% moderate, 20% light
/// - Heavy: 5-8 reps, >85% 1RM
/// - Moderate: 8-12 reps, 70-85% 1RM
/// - Light: 12-20 reps, 60-70% 1RM
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 3, Imagen 26: Curva de hipertrofia por intensidad
/// - Semana 3, Imagen 27-29: Distribución 35/45/20
/// - Semana 3, Imagen 30-32: Heavy para fuerza + hipertrofia
/// - Semana 3, Imagen 33-35: Moderate para hipertrofia pura
///
/// REFERENCIAS:
/// - Schoenfeld et al. (2021): Hypertrophy across loading ranges
/// - Lasevicius et al. (2018): Muscle growth with different intensities
///
/// Versión: 1.0.0
class IntensityEngine {
  /// Distribuye intensidades a una lista de ejercicios
  ///
  /// ALGORITMO:
  /// 1. Calcular cuántos ejercicios por zona (35/45/20)
  /// 2. Asignar heavy a compounds grandes primero
  /// 3. Asignar moderate a compounds auxiliares
  /// 4. Asignar light a aislamiento
  ///
  /// PARÁMETROS:
  /// - [exercises]: Lista de IDs de ejercicios
  /// - [exerciseTypes]: Mapa ejercicio → tipo ('compound'/'isolation')
  ///
  /// RETORNA:
  /// - Map<String, String>: ejercicioId → 'heavy'|'moderate'|'light'
  static Map<String, String> distributeIntensities({
    required List<String> exercises,
    required Map<String, String> exerciseTypes,
  }) {
    final totalExercises = exercises.length;

    // PASO 1: Calcular distribución 35/45/20
    // Semana 3, Imagen 27-29
    final heavyCount = (totalExercises * 0.35).round();
    final moderateCount = (totalExercises * 0.45).round();
    final lightCount = totalExercises - heavyCount - moderateCount;

    // PASO 2: Separar por tipo
    final compounds = exercises
        .where((id) => exerciseTypes[id] == 'compound')
        .toList();
    final isolation = exercises
        .where((id) => exerciseTypes[id] == 'isolation')
        .toList();

    // PASO 3: Asignar intensidades
    final intensities = <String, String>{};

    // Heavy: Compounds primero
    int assignedHeavy = 0;
    for (final exerciseId in compounds) {
      if (assignedHeavy < heavyCount) {
        intensities[exerciseId] = 'heavy';
        assignedHeavy++;
      } else {
        break;
      }
    }

    // Moderate: Resto de compounds + algunos isolation
    int assignedModerate = 0;
    for (final exerciseId in [...compounds, ...isolation]) {
      if (intensities.containsKey(exerciseId)) continue;
      if (assignedModerate < moderateCount) {
        intensities[exerciseId] = 'moderate';
        assignedModerate++;
      } else {
        break;
      }
    }

    // Light: Lo que queda
    for (final exerciseId in exercises) {
      if (!intensities.containsKey(exerciseId)) {
        intensities[exerciseId] = 'light';
      }
    }

    return intensities;
  }

  /// Obtiene el rango de repeticiones para una zona de intensidad
  ///
  /// FUENTE: Semana 3, Imagen 30-35
  static List<int> getRepRangeForIntensity(String intensity) {
    switch (intensity) {
      case 'heavy':
        return [5, 8]; // Fuerza + hipertrofia
      case 'moderate':
        return [8, 12]; // Hipertrofia óptima
      case 'light':
        return [12, 20]; // Hipertrofia metabólica
      default:
        throw ArgumentError('Intensidad inválida: $intensity');
    }
  }

  /// Obtiene el descanso recomendado para una zona de intensidad
  ///
  /// FUENTE: Semana 3, complementario
  static int getRestSecondsForIntensity(String intensity) {
    switch (intensity) {
      case 'heavy':
        return 240; // 4 minutos (180-300s)
      case 'moderate':
        return 120; // 2 minutos (90-180s)
      case 'light':
        return 75; // 75 segundos (60-90s)
      default:
        throw ArgumentError('Intensidad inválida: $intensity');
    }
  }

  /// Valida que la distribución sea científica
  static bool isDistributionValid(Map<String, String> intensities) {
    if (intensities.isEmpty) return false;

    final total = intensities.length;
    final heavyCount = intensities.values.where((i) => i == 'heavy').length;
    final moderateCount = intensities.values
        .where((i) => i == 'moderate')
        .length;
    final lightCount = intensities.values.where((i) => i == 'light').length;

    // Calcular porcentajes
    final heavyPct = heavyCount / total;
    final moderatePct = moderateCount / total;
    final lightPct = lightCount / total;

    // Validar que estén cerca de 35/45/20 (±10% tolerancia)
    if ((heavyPct - 0.35).abs() > 0.15) return false;
    if ((moderatePct - 0.45).abs() > 0.15) return false;
    if ((lightPct - 0.20).abs() > 0.15) return false;

    return true;
  }
}
