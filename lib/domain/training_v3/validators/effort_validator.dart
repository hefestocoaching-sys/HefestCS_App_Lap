// lib/domain/training_v3/validators/effort_validator.dart

/// Validador científico de esfuerzo (RIR/RPE)
///
/// Valida que:
/// - RIR sea coherente con intensidad
/// - RPE calculado desde RIR sea razonable
/// - No haya demasiados ejercicios a fallo (RIR 0)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 4, Imagen 36-43: Relación RIR-RPE
/// - RIR óptimo depende de tipo de ejercicio e intensidad
/// - Exceso de fallo → fatiga sistémica alta
///
/// REFERENCIAS:
/// - Helms et al. (2018): RPE-based autoregulation
/// - Zourdos et al. (2016): RIR validity
///
/// Versión: 1.0.0
class EffortValidator {
  /// Valida RIR de todos los ejercicios en un programa
  ///
  /// VALIDACIONES:
  /// 1. RIR coherente con intensidad
  /// 2. RPE razonable (5-10)
  /// 3. No exceso de ejercicios a fallo
  /// 4. Compounds pesados con RIR conservador (>= 2)
  ///
  /// PARÁMETROS:
  /// - [exercisePrescriptions]: Prescripciones con RIR asignado
  /// - [exerciseTypes]: Tipo de cada ejercicio (compound/isolation)
  /// - [exerciseIntensities]: Intensidad de cada ejercicio
  ///
  /// RETORNA:
  /// - Map con resultado de validación
  static Map<String, dynamic> validateEffort({
    required Map<String, Map<String, dynamic>> exercisePrescriptions,
    required Map<String, String> exerciseTypes,
    required Map<String, String> exerciseIntensities,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    int failureCount = 0;

    exercisePrescriptions.forEach((exerciseId, prescription) {
      final rir = prescription['target_rir'] as int?;
      if (rir == null) {
        errors.add('$exerciseId: RIR no asignado');
        return;
      }

      final type = exerciseTypes[exerciseId] ?? 'unknown';
      final intensity = exerciseIntensities[exerciseId] ?? 'unknown';

      // Validación 1: RIR en rango válido
      if (rir < 0 || rir > 5) {
        errors.add('$exerciseId: RIR inválido ($rir). Debe estar entre 0-5');
        return;
      }

      // Validación 2: Coherencia RIR-intensidad-tipo
      final coherenceResult = _validateRirCoherence(
        exerciseId: exerciseId,
        rir: rir,
        type: type,
        intensity: intensity,
      );

      if (coherenceResult['status'] == 'error') {
        errors.add(coherenceResult['message'] as String);
      } else if (coherenceResult['status'] == 'warning') {
        warnings.add(coherenceResult['message'] as String);
      }

      // Contar ejercicios a fallo
      if (rir == 0) {
        failureCount++;
      }

      // Validación 3: RPE razonable
      final rpe = 10 - rir;
      if (rpe < 5 || rpe > 10) {
        warnings.add('$exerciseId: RPE calculado fuera de rango ($rpe)');
      }
    });

    // Validación 4: No exceso de fallo
    final totalExercises = exercisePrescriptions.length;
    final failureRatio = totalExercises > 0
        ? failureCount / totalExercises
        : 0.0;

    if (failureRatio > 0.3) {
      warnings.add(
        'Exceso de ejercicios a fallo (${(failureRatio * 100).toStringAsFixed(0)}%). '
        'Recomendado: < 30% para evitar fatiga sistémica excesiva.',
      );
    }

    return {
      'is_valid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'failure_count': failureCount,
      'failure_ratio': failureRatio,
    };
  }

  /// Valida coherencia RIR-tipo-intensidad
  ///
  /// REGLAS CIENTÍFICAS:
  /// - Compound heavy: RIR >= 3 (seguridad)
  /// - Compound moderate: RIR >= 2
  /// - Isolation light: RIR 0-1 (seguro a fallo)
  static Map<String, dynamic> _validateRirCoherence({
    required String exerciseId,
    required int rir,
    required String type,
    required String intensity,
  }) {
    // Compound heavy
    if (type == 'compound' && intensity == 'heavy') {
      if (rir < 3) {
        return {
          'status': 'warning',
          'message':
              '$exerciseId: Compound heavy con RIR $rir. '
              'Recomendado: RIR >= 3 para seguridad.',
        };
      }
    }

    // Compound moderate
    if (type == 'compound' && intensity == 'moderate') {
      if (rir < 2) {
        return {
          'status': 'warning',
          'message':
              '$exerciseId: Compound moderate con RIR $rir. '
              'Recomendado: RIR >= 2 para balance hipertrofia/fatiga.',
        };
      }
    }

    // Isolation light con RIR alto
    if (type == 'isolation' && intensity == 'light') {
      if (rir > 2) {
        return {
          'status': 'warning',
          'message':
              '$exerciseId: Isolation light con RIR $rir. '
              'Puede usar RIR 0-1 (fallo seguro en isolation).',
        };
      }
    }

    return {'status': 'ok', 'message': '$exerciseId: RIR coherente'};
  }

  /// Valida relación RIR-RPE
  ///
  /// FUENTE: Semana 4, Imagen 36-40
  ///
  /// RELACIÓN ESPERADA:
  /// RIR 0 = RPE 10
  /// RIR 1 = RPE 9
  /// RIR 2 = RPE 8
  /// RIR 3 = RPE 7
  static bool validateRirRpeRelation(int rir, double rpe) {
    final expectedRpe = 10 - rir;
    // Tolerancia: ±1 RPE
    return (rpe - expectedRpe).abs() <= 1.0;
  }

  /// Calcula score de calidad de esfuerzo (0.0-1.0)
  static double calculateEffortQualityScore({
    required Map<String, Map<String, dynamic>> exercisePrescriptions,
    required Map<String, String> exerciseTypes,
    required Map<String, String> exerciseIntensities,
  }) {
    final validation = validateEffort(
      exercisePrescriptions: exercisePrescriptions,
      exerciseTypes: exerciseTypes,
      exerciseIntensities: exerciseIntensities,
    );

    final errorCount = (validation['errors'] as List).length;
    final warningCount = (validation['warnings'] as List).length;

    double score = 1.0;
    score -= errorCount * 0.2;
    score -= warningCount * 0.1;

    return score.clamp(0.0, 1.0);
  }
}
