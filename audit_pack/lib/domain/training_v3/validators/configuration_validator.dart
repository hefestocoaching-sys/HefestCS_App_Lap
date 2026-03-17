// lib/domain/training_v3/validators/configuration_validator.dart

import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';

/// Validador de configuración general del programa
///
/// Valida:
/// - Split coherente (días, frecuencia, distribución)
/// - Fase válida (accumulation/intensification/deload)
/// - Duración apropiada por fase
/// - Número de ejercicios razonable
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 6: Split óptimo según días
/// - Semana 7: Periodización por fases
///
/// Versión: 1.0.0
class ConfigurationValidator {
  /// Valida configuración completa de un programa
  ///
  /// PARÁMETROS:
  /// - [split]: Configuración del split
  /// - [phase]: Fase ('accumulation'|'intensification'|'deload')
  /// - [durationWeeks]: Duración en semanas
  /// - [totalExercises]: Número total de ejercicios
  ///
  /// RETORNA:
  /// - Map con resultado de validación
  static Map<String, dynamic> validateConfiguration({
    required SplitConfig split,
    required String phase,
    required int durationWeeks,
    required int totalExercises,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // VALIDACIÓN 1: Split válido
    if (!split.isValid) {
      errors.add('Split inválido: ${split.name}');
    }

    // VALIDACIÓN 2: Fase válida
    if (!['accumulation', 'intensification', 'deload'].contains(phase)) {
      errors.add('Fase inválida: $phase');
    }

    // VALIDACIÓN 3: Duración apropiada por fase
    final durationResult = _validatePhaseDuration(phase, durationWeeks);
    if (durationResult['status'] == 'error') {
      errors.add(durationResult['message'] as String);
    } else if (durationResult['status'] == 'warning') {
      warnings.add(durationResult['message'] as String);
    }

    // VALIDACIÓN 4: Número de ejercicios razonable
    final exerciseResult = _validateExerciseCount(
      totalExercises,
      split.daysPerWeek,
    );
    if (exerciseResult['status'] == 'warning') {
      warnings.add(exerciseResult['message'] as String);
    }

    // VALIDACIÓN 5: Frecuencia óptima
    if (split.frequencyPerMuscle < 2.0) {
      warnings.add(
        'Frecuencia subóptima (${split.frequencyPerMuscle}x por músculo). '
        'Recomendado: >= 2x para hipertrofia.',
      );
    }

    return {'is_valid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  /// Valida duración por fase
  ///
  /// REGLAS:
  /// - Accumulation: 4-6 semanas
  /// - Intensification: 2-3 semanas
  /// - Deload: 1 semana
  static Map<String, dynamic> _validatePhaseDuration(String phase, int weeks) {
    switch (phase) {
      case 'accumulation':
        if (weeks < 4) {
          return {
            'status': 'warning',
            'message':
                'Accumulation muy corto ($weeks semanas). Recomendado: 4-6 semanas.',
          };
        } else if (weeks > 6) {
          return {
            'status': 'warning',
            'message':
                'Accumulation muy largo ($weeks semanas). Recomendado: 4-6 semanas.',
          };
        }
        break;

      case 'intensification':
        if (weeks < 2 || weeks > 3) {
          return {
            'status': 'warning',
            'message':
                'Intensification debe ser 2-3 semanas. Actual: $weeks semanas.',
          };
        }
        break;

      case 'deload':
        if (weeks != 1) {
          return {
            'status': 'error',
            'message':
                'Deload debe ser exactamente 1 semana. Actual: $weeks semanas.',
          };
        }
        break;
    }

    return {'status': 'ok', 'message': 'Duración apropiada para fase $phase'};
  }

  /// Valida número de ejercicios
  ///
  /// REGLAS:
  /// - Por sesión: 4-8 ejercicios (óptimo)
  /// - Total: 20-50 ejercicios
  static Map<String, dynamic> _validateExerciseCount(
    int total,
    int daysPerWeek,
  ) {
    final avgPerSession = total / daysPerWeek;

    if (avgPerSession < 4) {
      return {
        'status': 'warning',
        'message':
            'Pocos ejercicios por sesión (${avgPerSession.toStringAsFixed(1)}). Recomendado: 4-8.',
      };
    } else if (avgPerSession > 8) {
      return {
        'status': 'warning',
        'message':
            'Muchos ejercicios por sesión (${avgPerSession.toStringAsFixed(1)}). Recomendado: 4-8.',
      };
    }

    return {'status': 'ok', 'message': 'Número de ejercicios apropiado'};
  }

  /// Calcula score de calidad total del programa (0.0-1.0)
  ///
  /// Combina todos los validadores
  static double calculateOverallQualityScore({
    required SplitConfig split,
    required String phase,
    required int durationWeeks,
    required int totalExercises,
    required double volumeScore,
    required double intensityScore,
    required double effortScore,
  }) {
    final configValidation = validateConfiguration(
      split: split,
      phase: phase,
      durationWeeks: durationWeeks,
      totalExercises: totalExercises,
    );

    // Score de configuración
    final errorCount = (configValidation['errors'] as List).length;
    final warningCount = (configValidation['warnings'] as List).length;

    double configScore = 1.0;
    configScore -= errorCount * 0.2;
    configScore -= warningCount * 0.1;
    configScore = configScore.clamp(0.0, 1.0);

    // Score total ponderado
    final totalScore =
        (volumeScore * 0.30) +
        (intensityScore * 0.25) +
        (effortScore * 0.25) +
        (configScore * 0.20);

    return totalScore.clamp(0.0, 1.0);
  }
}
