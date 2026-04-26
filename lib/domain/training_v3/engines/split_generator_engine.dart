// lib/domain/training_v3/engines/split_generator_engine.dart

import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';

/// Motor generador de splits de entrenamiento
///
/// Implementa las reglas científicas de la Semana 6 (imágenes 64-69):
/// - 3 días → Full Body (frecuencia 3x por músculo)
/// - 4 días → Upper/Lower (frecuencia 2x por músculo)
/// - 5 días → Push/Pull/Legs (frecuencia 1.5-2x por músculo)
/// - 6 días → Push/Pull/Legs 2x (frecuencia 2x por músculo)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 6, Imagen 64: Frecuencia óptima = 2x por semana
/// - Semana 6, Imagen 65-66: Upper/Lower split
/// - Semana 6, Imagen 67-69: Push/Pull/Legs split
///
/// REFERENCIAS:
/// - Schoenfeld et al. (2019): Training frequency for muscle hypertrophy
/// - Grgic et al. (2018): Frequency meta-analysis (2x > 1x)
///
/// Versión: 1.0.0
@Deprecated(
  'Non-canonical split helper. The active Motor V3 runtime resolves split via TrainingPlanProvider -> TrainingOrchestratorV3 -> MotorV3Orchestrator/CycleTemplateBuilder contracts.',
)
class SplitGeneratorEngine {
  /// Genera el split óptimo según días disponibles
  ///
  /// ALGORITMO:
  /// 1. Evaluar días disponibles
  /// 2. Seleccionar plantilla científica
  /// 3. Retornar SplitConfig predefinido
  ///
  /// PARÁMETROS:
  /// - [availableDays]: Días de entrenamiento por semana (3-6)
  /// - [goal]: Objetivo del usuario ('hypertrophy'|'strength'|'general_fitness')
  ///
  /// RETORNA:
  /// - SplitConfig: Configuración del split
  static SplitConfig generateOptimalSplit({
    required int availableDays,
    required String goal,
  }) {
    // Validar días
    if (availableDays < 3 || availableDays > 6) {
      throw ArgumentError('Días disponibles debe estar entre 3-6');
    }

    // Semana 6: Selección basada en frecuencia óptima
    switch (availableDays) {
      case 3:
        // Full Body 3x: Frecuencia 3x por músculo
        // Semana 6, Imagen 64
        return SplitConfig.fullBody3x();

      case 4:
        // Upper/Lower 4x: Frecuencia 2x por músculo (ÓPTIMO)
        // Semana 6, Imagen 65-66
        return SplitConfig.upperLower4x();

      case 5:
        // PPL 5x oficial con día torso intermedio.
        return SplitConfig.pushPullLegs5x();

      case 6:
        // PPL 6x: Frecuencia 2x por músculo (ÓPTIMO)
        // Semana 6, Imagen 67-69
        return SplitConfig.pushPullLegs6x();

      default:
        throw ArgumentError('Días no soportados: $availableDays');
    }
  }

  /// Genera PPL modificado para 5 días (subóptimo)
  static SplitConfig _generatePPL5Days() {
    return SplitConfig.pushPullLegs5x();
  }

  /// Recomienda el split óptimo basado en volumen total
  ///
  /// REGLAS:
  /// - Volumen total < 60 sets/semana → Full Body 3x
  /// - Volumen total 60-100 sets/semana → Upper/Lower 4x
  /// - Volumen total > 100 sets/semana → PPL 6x
  static String recommendSplitForVolume(int totalWeeklyVolume) {
    if (totalWeeklyVolume < 60) {
      return 'full_body_3x';
    } else if (totalWeeklyVolume <= 100) {
      return 'upper_lower_4x';
    } else {
      return 'ppl_6x';
    }
  }

  /// Calcula frecuencia real por músculo en un split
  ///
  /// EJEMPLO:
  /// - Full Body 3 días → 3.0 (cada músculo 3x/semana)
  /// - Upper/Lower 4 días → 2.0 (cada músculo 2x/semana)
  /// - PPL 6 días → 2.0 (cada músculo 2x/semana)
  static double calculateMuscleFrequency({
    required int daysPerWeek,
    required String splitType,
  }) {
    switch (splitType) {
      case 'full_body':
        return daysPerWeek.toDouble(); // Cada día entrena todos los músculos
      case 'upper_lower':
        return (daysPerWeek / 2).toDouble(); // Cada músculo cada 2 días
      case 'push_pull_legs':
        if (daysPerWeek >= 6) return 2.0;
        if (daysPerWeek == 5) return 1.67;
        return (daysPerWeek / 3).toDouble(); // Cada músculo cada 3 días
      default:
        throw ArgumentError('Split type inválido: $splitType');
    }
  }

  /// Valida que el split sea óptimo científicamente
  ///
  /// CRITERIO:
  /// - Frecuencia debe ser >= 2.0 para hipertrofia óptima (Schoenfeld 2019)
  static bool isSplitOptimal(SplitConfig split) {
    // Semana 6, Imagen 64: Frecuencia 2x es óptima
    return split.frequencyPerMuscle >= 2.0;
  }

  /// Genera distribución de músculos por día
  ///
  /// USADO INTERNAMENTE para splits personalizados
  static List<List<String>> distributeMusclesByDays({
    required List<String> muscles,
    required int daysPerWeek,
  }) {
    final distribution = <List<String>>[];

    if (daysPerWeek == 3) {
      // Full Body: Todos los músculos cada día
      for (int i = 0; i < 3; i++) {
        distribution.add(List.from(muscles));
      }
    } else if (daysPerWeek == 4) {
      // Upper/Lower
      final upper = muscles
          .where(
            (m) => [
              MuscleKey.pectorals,
              MuscleKey.lats,
              MuscleKey.upperBack,
              MuscleKey.traps,
              MuscleKey.deltsFront,
              MuscleKey.deltsLateral,
              MuscleKey.deltsRear,
              MuscleKey.biceps,
              MuscleKey.triceps,
            ].contains(m),
          )
          .toList();
      final lower = muscles
          .where(
            (m) => [
              MuscleKey.quads,
              MuscleKey.hamstrings,
              MuscleKey.glutes,
              MuscleKey.calves,
            ].contains(m),
          )
          .toList();
      distribution.addAll([upper, lower, upper, lower]);
    } else if (daysPerWeek == 6) {
      // Push/Pull/Legs
      final push = muscles
          .where(
            (m) => [
              MuscleKey.pectorals,
              MuscleKey.deltsFront,
              MuscleKey.deltsLateral,
              MuscleKey.deltsRear,
              MuscleKey.triceps,
            ].contains(m),
          )
          .toList();
      final pull = muscles
          .where(
            (m) => [
              MuscleKey.lats,
              MuscleKey.upperBack,
              MuscleKey.traps,
              MuscleKey.biceps,
            ].contains(m),
          )
          .toList();
      final legs = muscles
          .where(
            (m) => [
              MuscleKey.quads,
              MuscleKey.hamstrings,
              MuscleKey.glutes,
              MuscleKey.calves,
            ].contains(m),
          )
          .toList();
      distribution.addAll([push, pull, legs, push, pull, legs]);
    }

    return distribution;
  }
}
