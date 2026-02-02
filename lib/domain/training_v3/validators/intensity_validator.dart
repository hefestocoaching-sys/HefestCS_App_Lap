// lib/domain/training_v3/validators/intensity_validator.dart

/// Validador científico de distribución de intensidad
///
/// Valida que los programas cumplan con:
/// - Distribución 35% heavy / 45% moderate / 20% light
/// - Coherencia intensidad-reps (heavy 5-8, moderate 8-12, light 12-20)
/// - Descanso apropiado por intensidad
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 3, Imagen 27-29: Distribución óptima 35/45/20
/// - Hipertrofia máxima con diversidad de intensidades
///
/// REFERENCIAS:
/// - Schoenfeld et al. (2021): Loading magnitude and hypertrophy
/// - Lasevicius et al. (2018): Muscle growth across intensities
///
/// Versión: 1.0.0
class IntensityValidator {
  /// Valida distribución de intensidades en un programa
  ///
  /// VALIDACIONES:
  /// 1. Porcentajes cerca de 35/45/20 (±15% tolerancia)
  /// 2. Cada ejercicio tiene intensidad asignada
  /// 3. Coherencia intensidad-reps
  /// 4. Descanso apropiado
  ///
  /// PARÁMETROS:
  /// - [exerciseIntensities]: Mapa ejercicioId → intensidad
  /// - [exercisePrescriptions]: Prescripciones completas (para validar coherencia)
  ///
  /// RETORNA:
  /// - Map con resultado de validación
  static Map<String, dynamic> validateDistribution({
    required Map<String, String> exerciseIntensities,
    required Map<String, Map<String, dynamic>> exercisePrescriptions,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (exerciseIntensities.isEmpty) {
      errors.add('No hay ejercicios con intensidad asignada');
      return {'is_valid': false, 'errors': errors, 'warnings': warnings};
    }

    // VALIDACIÓN 1: Distribución porcentual
    final distributionResult = _validateDistributionPercentages(
      exerciseIntensities,
    );
    if (distributionResult['status'] == 'error') {
      errors.add(distributionResult['message'] as String);
    } else if (distributionResult['status'] == 'warning') {
      warnings.add(distributionResult['message'] as String);
    }

    // VALIDACIÓN 2: Coherencia intensidad-reps
    final coherenceErrors = _validateIntensityRepCoherence(
      exerciseIntensities,
      exercisePrescriptions,
    );
    errors.addAll(coherenceErrors);

    // VALIDACIÓN 3: Descanso apropiado
    final restWarnings = _validateRestPeriods(
      exerciseIntensities,
      exercisePrescriptions,
    );
    warnings.addAll(restWarnings);

    return {
      'is_valid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'distribution': distributionResult['percentages'],
    };
  }

  /// Valida que la distribución esté cerca de 35/45/20
  static Map<String, dynamic> _validateDistributionPercentages(
    Map<String, String> intensities,
  ) {
    final total = intensities.length;
    final heavyCount = intensities.values.where((i) => i == 'heavy').length;
    final moderateCount = intensities.values
        .where((i) => i == 'moderate')
        .length;
    final lightCount = intensities.values.where((i) => i == 'light').length;

    final heavyPct = heavyCount / total;
    final moderatePct = moderateCount / total;
    final lightPct = lightCount / total;

    // Tolerancia: ±15%
    final heavyOk = (heavyPct - 0.35).abs() <= 0.15;
    final moderateOk = (moderatePct - 0.45).abs() <= 0.15;
    final lightOk = (lightPct - 0.20).abs() <= 0.15;

    final percentages = {
      'heavy': (heavyPct * 100).toStringAsFixed(1),
      'moderate': (moderatePct * 100).toStringAsFixed(1),
      'light': (lightPct * 100).toStringAsFixed(1),
    };

    if (!heavyOk || !moderateOk || !lightOk) {
      return {
        'status': 'warning',
        'message':
            'Distribución de intensidad subóptima. '
            'Actual: ${percentages['heavy']}% heavy / ${percentages['moderate']}% moderate / ${percentages['light']}% light. '
            'Óptimo: 35% / 45% / 20%',
        'percentages': percentages,
      };
    }

    return {
      'status': 'ok',
      'message': 'Distribución de intensidad óptima',
      'percentages': percentages,
    };
  }

  /// Valida coherencia entre intensidad y rango de reps
  ///
  /// REGLAS:
  /// - Heavy: 5-8 reps
  /// - Moderate: 8-12 reps
  /// - Light: 12-20 reps
  static List<String> _validateIntensityRepCoherence(
    Map<String, String> intensities,
    Map<String, Map<String, dynamic>> prescriptions,
  ) {
    final errors = <String>[];

    intensities.forEach((exerciseId, intensity) {
      final prescription = prescriptions[exerciseId];
      if (prescription == null) return;

      final repRange = prescription['rep_range'] as List<int>?;
      if (repRange == null || repRange.length != 2) return;

      final minReps = repRange[0];
      final maxReps = repRange[1];

      switch (intensity) {
        case 'heavy':
          if (maxReps > 8) {
            errors.add(
              '$exerciseId: Heavy con $minReps-$maxReps reps. '
              'Heavy debe ser 5-8 reps.',
            );
          }
          break;
        case 'moderate':
          if (maxReps < 8 || minReps > 12) {
            errors.add(
              '$exerciseId: Moderate con $minReps-$maxReps reps. '
              'Moderate debe ser 8-12 reps.',
            );
          }
          break;
        case 'light':
          if (minReps < 12) {
            errors.add(
              '$exerciseId: Light con $minReps-$maxReps reps. '
              'Light debe ser 12-20 reps.',
            );
          }
          break;
      }
    });

    return errors;
  }

  /// Valida que el descanso sea apropiado para la intensidad
  static List<String> _validateRestPeriods(
    Map<String, String> intensities,
    Map<String, Map<String, dynamic>> prescriptions,
  ) {
    final warnings = <String>[];

    intensities.forEach((exerciseId, intensity) {
      final prescription = prescriptions[exerciseId];
      if (prescription == null) return;

      final restSeconds = prescription['rest_seconds'] as int?;
      if (restSeconds == null) return;

      switch (intensity) {
        case 'heavy':
          if (restSeconds < 180) {
            warnings.add(
              '$exerciseId: Heavy con solo ${restSeconds}s descanso. '
              'Recomendado: 180-300s para recuperación completa.',
            );
          }
          break;
        case 'moderate':
          if (restSeconds < 90 || restSeconds > 180) {
            warnings.add(
              '$exerciseId: Moderate con ${restSeconds}s descanso. '
              'Recomendado: 90-180s.',
            );
          }
          break;
        case 'light':
          if (restSeconds > 90) {
            warnings.add(
              '$exerciseId: Light con ${restSeconds}s descanso. '
              'Puede reducir a 60-90s para eficiencia.',
            );
          }
          break;
      }
    });

    return warnings;
  }

  /// Calcula score de calidad de intensidad (0.0-1.0)
  static double calculateIntensityQualityScore({
    required Map<String, String> exerciseIntensities,
    required Map<String, Map<String, dynamic>> exercisePrescriptions,
  }) {
    final validation = validateDistribution(
      exerciseIntensities: exerciseIntensities,
      exercisePrescriptions: exercisePrescriptions,
    );

    // Penalizar por errores y warnings
    final errorCount = (validation['errors'] as List).length;
    final warningCount = (validation['warnings'] as List).length;

    double score = 1.0;
    score -= errorCount * 0.2;
    score -= warningCount * 0.1;

    return score.clamp(0.0, 1.0);
  }
}
