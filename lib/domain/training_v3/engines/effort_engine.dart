// lib/domain/training_v3/engines/effort_engine.dart

import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';

/// Motor de asignación de RIR (Reps in Reserve) por ejercicio
///
/// Implementa las reglas científicas de la Semana 4 (43 imágenes):
/// - RIR óptimo varía según intensidad y tipo de ejercicio
/// - Heavy compounds: RIR 3-4 (conservador, riesgo de lesión)
/// - Medium: RIR 2-3 (óptimo para hipertrofia)
/// - Light isolation: RIR 0-1 (cerca del fallo)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 4, Imagen 36-40: Relación RIR-RPE
/// - Semana 4, Imagen 41-43: RIR óptimo por ejercicio
///
/// REFERENCIAS:
/// - Helms et al. (2018): RPE-based autoregulation
/// - Zourdos et al. (2016): RIR accuracy and validity
///
/// Versión: 1.0.0
class EffortEngine {
  /// Asigna RIR óptimo a cada ejercicio según intensidad y tipo
  ///
  /// ALGORITMO:
  /// 1. Identificar tipo de ejercicio (compound/isolation)
  /// 2. Obtener intensidad asignada
  /// 3. Aplicar regla RIR según tabla científica
  ///
  /// PARÁMETROS:
  /// - [exerciseId]: ID del ejercicio
  /// - [intensity]: 'heavy'|'medium'|'light'
  /// - [exerciseType]: 'compound'|'isolation'
  ///
  /// RETORNA:
  /// - int: RIR óptimo (0-5)
  static int assignRir({
    required String exerciseId,
    required String intensity,
    required String exerciseType,
    String phase = 'accumulation',
  }) {
    // Tabla científica de RIR
    // Semana 4, Imagen 41-43

    if (exerciseType == 'compound') {
      switch (intensity) {
        case IntensityZone.heavy:
          // RIR 1: Robinson et al. Sports Med 2024 + Refalo et al. J Sports Sci 2024
          // RIR 3 era excesivamente conservador y reducía el estímulo hipertrófico.
          return adjustRirForPhase(baseRir: 1, phase: phase);
        case IntensityZone.medium:
          return adjustRirForPhase(baseRir: 2, phase: phase);
        case IntensityZone.light:
          return adjustRirForPhase(baseRir: 1, phase: phase);
        default:
          throw ArgumentError('Intensidad inválida: $intensity');
      }
    } else if (exerciseType == 'isolation') {
      switch (intensity) {
        case IntensityZone.heavy:
          return adjustRirForPhase(baseRir: 2, phase: phase);
        case IntensityZone.medium:
          return adjustRirForPhase(baseRir: 2, phase: phase);
        case IntensityZone.light:
          return adjustRirForPhase(baseRir: 0, phase: phase);
        default:
          throw ArgumentError('Intensidad inválida: $intensity');
      }
    } else {
      throw ArgumentError('Tipo de ejercicio inválido: $exerciseType');
    }
  }

  /// Convierte RIR a RPE aproximado
  ///
  /// FUENTE: Semana 4, Imagen 36-40
  ///
  /// RELACIÓN:
  /// RIR 0 = RPE 10 (fallo)
  /// RIR 1 = RPE 9
  /// RIR 2 = RPE 8
  /// RIR 3 = RPE 7
  /// RIR 4 = RPE 6
  /// RIR 5 = RPE 5
  static double rirToRpe(int rir) {
    if (rir < 0 || rir > 5) {
      throw ArgumentError('RIR debe estar entre 0-5');
    }
    return (10 - rir).toDouble();
  }

  /// Convierte RPE a RIR aproximado
  static int rpeToRir(double rpe) {
    if (rpe < 5 || rpe > 10) {
      throw ArgumentError('RPE debe estar entre 5-10');
    }
    return (10 - rpe).round().clamp(0, 5);
  }

  /// Ajusta RIR según fase de entrenamiento
  ///
  /// REGLAS:
  /// - Accumulation: RIR normal
  /// - Intensification: RIR -1 (más cerca del fallo)
  /// - Deload: RIR +2 (más conservador)
  static int adjustRirForPhase({required int baseRir, required String phase}) {
    switch (phase) {
      case 'accumulation':
        return baseRir;
      case 'intensification':
        return (baseRir - 1).clamp(0, 5);
      case 'deload':
        return (baseRir + 2).clamp(0, 5);
      default:
        throw ArgumentError('Fase inválida: $phase');
    }
  }
}
