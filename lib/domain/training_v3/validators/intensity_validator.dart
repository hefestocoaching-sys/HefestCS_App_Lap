// lib/domain/training_v3/validators/intensity_validator.dart

import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';

/// Validador científico de distribución de intensidad
///
/// Valida que los programas cumplan con:
/// - Distribución 20% heavy / 60% medium / 20% light (SSOT actual)
/// - Coherencia intensidad-reps (heavy 6-8, medium 8-12, light 16-20)
/// - Descanso apropiado por intensidad
///
/// FUNDAMENTO CIENTÍFICO:
/// - Política SSOT operativa del motor: 20/60/20
/// - Hipertrofia máxima con diversidad de intensidades
///
/// REFERENCIAS:
/// - Schoenfeld et al. (2021): Loading magnitude and hypertrophy
/// - Lasevicius et al. (2018): Muscle growth across intensities
///
/// Versión: 1.0.0
class IntensityValidator {
  static const double _targetHeavyPct = 0.20;
  static const double _targetMediumPct = 0.60;
  static const double _targetLightPct = 0.20;

  static String _normalizeIntensity(String intensity) {
    final normalized = intensity.trim().toLowerCase();
    // Compatibilidad de borde: legacy moderate se traduce al SSOT interno.
    if (normalized == 'moderate') {
      return IntensityZone.medium;
    }
    return normalized;
  }

  /// Valida distribución de intensidades en un programa
  ///
  /// VALIDACIONES:
  /// 1. Porcentajes cerca de 20/60/20 (±15% tolerancia)
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

  /// Valida que la distribución esté cerca de 20/60/20
  static Map<String, dynamic> _validateDistributionPercentages(
    Map<String, String> intensities,
  ) {
    final total = intensities.length;
    final heavyCount = intensities.values
        .map(_normalizeIntensity)
        .where((i) => i == IntensityZone.heavy)
        .length;
    final mediumCount = intensities.values
        .map(_normalizeIntensity)
        .where((i) => i == IntensityZone.medium)
        .length;
    final lightCount = intensities.values
        .map(_normalizeIntensity)
        .where((i) => i == IntensityZone.light)
        .length;

    final heavyPct = heavyCount / total;
    final mediumPct = mediumCount / total;
    final lightPct = lightCount / total;

    // Tolerancia: ±15%
    final heavyOk = (heavyPct - _targetHeavyPct).abs() <= 0.15;
    final mediumOk = (mediumPct - _targetMediumPct).abs() <= 0.15;
    final lightOk = (lightPct - _targetLightPct).abs() <= 0.15;

    final percentages = {
      IntensityZone.heavy: (heavyPct * 100).toStringAsFixed(1),
      IntensityZone.medium: (mediumPct * 100).toStringAsFixed(1),
      IntensityZone.light: (lightPct * 100).toStringAsFixed(1),
    };

    if (!heavyOk || !mediumOk || !lightOk) {
      return {
        'status': 'warning',
        'message':
            'Distribución de intensidad subóptima. '
            'Actual: ${percentages[IntensityZone.heavy]}% heavy / ${percentages[IntensityZone.medium]}% medium / ${percentages[IntensityZone.light]}% light. '
            'Óptimo: 20% / 60% / 20%',
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
  /// - Heavy: 6-8 reps
  /// - Medium: 8-12 reps
  /// - Light: 16-20 reps
  static List<String> _validateIntensityRepCoherence(
    Map<String, String> intensities,
    Map<String, Map<String, dynamic>> prescriptions,
  ) {
    final errors = <String>[];

    intensities.forEach((exerciseId, intensity) {
      final normalizedIntensity = _normalizeIntensity(intensity);
      final prescription = prescriptions[exerciseId];
      if (prescription == null) return;

      final repRange = prescription['rep_range'] as List<int>?;
      if (repRange == null || repRange.length != 2) return;

      final minReps = repRange[0];
      final maxReps = repRange[1];

      switch (normalizedIntensity) {
        case IntensityZone.heavy:
          if (minReps < 6 || maxReps > 8) {
            errors.add(
              '$exerciseId: Heavy con $minReps-$maxReps reps. '
              'Heavy debe ser 6-8 reps.',
            );
          }
          break;
        case IntensityZone.medium:
          if (minReps < 8 || maxReps > 12) {
            errors.add(
              '$exerciseId: Medium con $minReps-$maxReps reps. '
              'Medium debe ser 8-12 reps.',
            );
          }
          break;
        case IntensityZone.light:
          if (minReps < 16 || maxReps > 20) {
            errors.add(
              '$exerciseId: Light con $minReps-$maxReps reps. '
              'Light debe ser 16-20 reps.',
            );
          }
          break;
        default:
          errors.add(
            '$exerciseId: Intensidad inválida ($normalizedIntensity).',
          );
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
      final normalizedIntensity = _normalizeIntensity(intensity);
      final prescription = prescriptions[exerciseId];
      if (prescription == null) return;

      final restSeconds = prescription['rest_seconds'] as int?;
      if (restSeconds == null) return;

      switch (normalizedIntensity) {
        case IntensityZone.heavy:
          if (restSeconds < 180) {
            warnings.add(
              '$exerciseId: Heavy con solo ${restSeconds}s descanso. '
              'Recomendado: 180-300s para recuperación completa.',
            );
          }
          break;
        case IntensityZone.medium:
          if (restSeconds < 90 || restSeconds > 180) {
            warnings.add(
              '$exerciseId: Medium con ${restSeconds}s descanso. '
              'Recomendado: 90-180s.',
            );
          }
          break;
        case IntensityZone.light:
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
