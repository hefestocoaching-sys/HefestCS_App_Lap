// lib/domain/training_v3/validators/volume_validator.dart

/// Validador científico de volumen de entrenamiento
///
/// Valida que los programas generados cumplan con:
/// - VME (Volumen Mínimo Efectivo): Cada músculo >= VME
/// - MRV (Volumen Máximo Recuperable): Cada músculo <= MRV
/// - Balance entre grupos musculares
/// - Volumen total semanal razonable
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 1-2: Landmarks de volumen (VME/MAV/MRV)
/// - Exceder MRV → sobreentrenamiento
/// - Por debajo de VME → sin estímulo
///
/// REFERENCIAS:
/// - Israetel et al. (2020): Volume landmarks
/// - Schoenfeld et al. (2017): Dose-response relationship
///
/// Versión: 1.0.0
class VolumeValidator {
  /// Valida el volumen de un programa completo
  ///
  /// VALIDACIONES:
  /// 1. Cada músculo entre VME-MRV
  /// 2. Volumen total < 150 sets/semana (límite práctico)
  /// 3. Balance entre grupos antagonistas
  /// 4. No hay músculos omitidos
  ///
  /// PARÁMETROS:
  /// - [volumeByMuscle]: Volumen semanal por músculo (sets)
  /// - [trainingLevel]: Nivel del atleta
  ///
  /// RETORNA:
  /// - Map con resultado de validación
  static Map<String, dynamic> validateProgram({
    required Map<String, int> volumeByMuscle,
    required String trainingLevel,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // VALIDACIÓN 1: Cada músculo entre VME-MRV
    volumeByMuscle.forEach((muscle, volume) {
      final result = validateMuscleVolume(
        muscle: muscle,
        volume: volume,
        trainingLevel: trainingLevel,
      );

      if (result['status'] == 'error') {
        errors.add(result['message'] as String);
      } else if (result['status'] == 'warning') {
        warnings.add(result['message'] as String);
      }
    });

    // VALIDACIÓN 2: Volumen total
    final totalVolume = volumeByMuscle.values.fold(0, (sum, vol) => sum + vol);
    if (totalVolume > 150) {
      errors.add(
        'Volumen total muy alto ($totalVolume sets/semana). '
        'Límite recomendado: 150 sets. Riesgo de sobreentrenamiento.',
      );
    } else if (totalVolume < 40) {
      warnings.add(
        'Volumen total bajo ($totalVolume sets/semana). '
        'Considerar aumentar para optimizar resultados.',
      );
    }

    // VALIDACIÓN 3: Balance antagonistas
    final balanceIssues = _checkMuscleBalance(volumeByMuscle);
    warnings.addAll(balanceIssues);

    // VALIDACIÓN 4: Músculos principales incluidos
    final requiredMuscles = [
      'chest',
      'back',
      'quads',
      'hamstrings',
      'shoulders',
    ];
    final missingMuscles = requiredMuscles
        .where((m) => !volumeByMuscle.containsKey(m))
        .toList();

    if (missingMuscles.isNotEmpty) {
      warnings.add(
        'Músculos principales omitidos: ${missingMuscles.join(", ")}',
      );
    }

    return {
      'is_valid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'total_volume': totalVolume,
      'muscles_validated': volumeByMuscle.length,
    };
  }

  /// Valida volumen de un músculo individual
  ///
  /// RETORNA:
  /// - status: 'ok' | 'warning' | 'error'
  /// - message: Descripción del problema
  static Map<String, dynamic> validateMuscleVolume({
    required String muscle,
    required int volume,
    required String trainingLevel,
  }) {
    final landmarks = _getVolumeLandmarks(muscle, trainingLevel);
    final vme = landmarks['vme']!;
    final mav = landmarks['mav']!;
    final mrv = landmarks['mrv']!;

    // ERROR: Por debajo de VME
    if (volume < vme) {
      return {
        'status': 'error',
        'message':
            '$muscle: Volumen ($volume sets) por debajo de VME ($vme sets). Sin estímulo suficiente.',
        'recommendation': 'Aumentar a mínimo $vme sets',
      };
    }

    // ERROR: Por encima de MRV
    if (volume > mrv) {
      return {
        'status': 'error',
        'message':
            '$muscle: Volumen ($volume sets) excede MRV ($mrv sets). Riesgo de sobreentrenamiento.',
        'recommendation': 'Reducir a máximo $mrv sets',
      };
    }

    // WARNING: Por debajo de MAV
    if (volume < mav) {
      return {
        'status': 'warning',
        'message':
            '$muscle: Volumen ($volume sets) por debajo de MAV ($mav sets). Subóptimo para hipertrofia.',
        'recommendation':
            'Considerar aumentar a $mav sets para resultados óptimos',
      };
    }

    // OK: Entre MAV-MRV (óptimo)
    return {
      'status': 'ok',
      'message': '$muscle: Volumen óptimo ($volume sets entre MAV-MRV)',
      'recommendation': 'Continuar',
    };
  }

  /// Verifica balance entre músculos antagonistas
  ///
  /// REGLAS:
  /// - Chest/Back ratio: 0.8-1.2
  /// - Quads/Hamstrings ratio: 1.0-1.5
  /// - Biceps/Triceps ratio: 0.8-1.2
  static List<String> _checkMuscleBalance(Map<String, int> volumeByMuscle) {
    final warnings = <String>[];

    // Balance 1: Chest/Back
    final chest = volumeByMuscle['chest'] ?? 0;
    final back = volumeByMuscle['back'] ?? 0;

    if (chest > 0 && back > 0) {
      final ratio = chest / back;
      if (ratio < 0.8) {
        warnings.add(
          '⚠️  Desbalance: Pecho muy bajo vs Espalda (${ratio.toStringAsFixed(2)}:1). Riesgo de postura encorvada.',
        );
      } else if (ratio > 1.2) {
        warnings.add(
          '⚠️  Desbalance: Pecho muy alto vs Espalda (${ratio.toStringAsFixed(2)}:1). Riesgo de postura encorvada.',
        );
      }
    }

    // Balance 2: Quads/Hamstrings
    final quads = volumeByMuscle['quads'] ?? 0;
    final hamstrings = volumeByMuscle['hamstrings'] ?? 0;

    if (quads > 0 && hamstrings > 0) {
      final ratio = quads / hamstrings;
      if (ratio < 1.0) {
        warnings.add(
          '⚠️  Desbalance: Cuádriceps bajo vs Isquios (${ratio.toStringAsFixed(2)}:1).',
        );
      } else if (ratio > 1.5) {
        warnings.add(
          '⚠️  Desbalance: Cuádriceps muy alto vs Isquios (${ratio.toStringAsFixed(2)}:1). Riesgo de lesión de rodilla.',
        );
      }
    }

    // Balance 3: Biceps/Triceps
    final biceps = volumeByMuscle['biceps'] ?? 0;
    final triceps = volumeByMuscle['triceps'] ?? 0;

    if (biceps > 0 && triceps > 0) {
      final ratio = biceps / triceps;
      if (ratio < 0.8 || ratio > 1.2) {
        warnings.add(
          '⚠️  Desbalance: Bíceps/Tríceps (${ratio.toStringAsFixed(2)}:1). Recomendado: 0.8-1.2:1',
        );
      }
    }

    return warnings;
  }

  /// Obtiene landmarks de volumen (duplicado del VolumeEngine para independencia)
  static Map<String, int> _getVolumeLandmarks(String muscle, String level) {
    final landmarksByMuscle = {
      'chest': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      'back': {
        'novice': {'vme': 12, 'mav': 18, 'mrv': 24},
        'intermediate': {'vme': 15, 'mav': 22, 'mrv': 28},
        'advanced': {'vme': 18, 'mav': 26, 'mrv': 32},
      },
      'quads': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      'hamstrings': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'glutes': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'shoulders': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      'biceps': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'triceps': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'calves': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'abs': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
    };

    return landmarksByMuscle[muscle]![level]!;
  }

  /// Calcula score de calidad del volumen (0.0-1.0)
  ///
  /// 1.0 = Todos los músculos en MAV-MRV
  /// 0.5 = Algunos músculos subóptimos
  /// 0.0 = Múltiples errores
  static double calculateVolumeQualityScore({
    required Map<String, int> volumeByMuscle,
    required String trainingLevel,
  }) {
    if (volumeByMuscle.isEmpty) return 0.0;

    int totalMuscles = volumeByMuscle.length;
    int optimalMuscles = 0;
    int acceptableMuscles = 0;

    volumeByMuscle.forEach((muscle, volume) {
      final result = validateMuscleVolume(
        muscle: muscle,
        volume: volume,
        trainingLevel: trainingLevel,
      );

      if (result['status'] == 'ok') {
        optimalMuscles++;
      } else if (result['status'] == 'warning') {
        acceptableMuscles++;
      }
    });

    // Score ponderado
    final score =
        (optimalMuscles * 1.0 + acceptableMuscles * 0.5) / totalMuscles;
    return score.clamp(0.0, 1.0);
  }
}
