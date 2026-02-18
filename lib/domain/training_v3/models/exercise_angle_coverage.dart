import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_angle_coverage.freezed.dart';
part 'exercise_angle_coverage.g.dart';

/// Cobertura de ÁNGULOS/PLANOS para un músculo en un CICLO
///
/// PROPÓSITO:
/// - Asegurar variedad de estímulo (angular variety)
/// - Primarios DEBEN variar ángulo cada semana o bloque
/// - Secundarios/terciarios menor énfasis
/// - Exportable para coach y auditoría
///
/// EJEMPLOS:
/// PECTORALES:
///   - Plano: press plano, peck deck plano
///   - Inclinado: press inclinado, flies inclinado
///   - Declinado: press declinado (menos común)
///   - Vertical: dips, chest dips
///
/// DORSALES (LATS):
///   - Horizontal: remo horizontal, máquina
///   - Vertical: pulldown, dominadas
///   - Unilateral: remo unilateral
///
/// CUÁDRICEPS:
///   - Frontal: leg press, hack squat
///   - Centro: squat, leg extension
///   - Medial: sissy squat, bulgarian split squat
///
/// VERSIÓN: 1.0.0
@freezed
abstract class ExerciseAngleCoverage with _$ExerciseAngleCoverage {
  const factory ExerciseAngleCoverage({
    /// Identificación
    required String userId,
    required String muscle,
    required int weekNumber,
    required String cycleId, // ID del ciclo (macrocycle/mesocycle)
    /// Ángulos/planos usados ESTA SEMANA
    /// Map: angleKey (ej: 'horizontal', 'vertical', 'incline')
    ///      -> List de exercise IDs que cubren ese ángulo
    required Map<String, List<String>> angleExerciseMap,

    /// Cobertura general (qué porcentaje de ángulos se cubrieron)
    /// 0.0 = ningún ángulo, 1.0 = todos los ángulos
    required double coverageRatio,

    /// Ángulos identificados para este músculo
    @Default([])
    List<String> knownAngles, // 'horizontal', 'vertical', 'incline', etc.
    /// Ángulos cubiertos esta semana
    @Default([]) List<String> coveredAngles,

    /// Ángulos NO cubiertos (auditoría)
    @Default([]) List<String> missingAngles,

    /// Variedad: ¿Cambió con respecto a semana anterior?
    required bool changedFromLastWeek, // ¿Usamos ángulos diferentes?
    /// Timestamp
    required DateTime recordedAt,

    /// Metadata
    @Default({}) Map<String, dynamic> metadata,
  }) = _ExerciseAngleCoverage;

  factory ExerciseAngleCoverage.fromJson(Map<String, dynamic> json) =>
      _$ExerciseAngleCoverageFromJson(json);
}

/// Utilidades para cobertura angular
extension ExerciseAngleCoverageExtension on ExerciseAngleCoverage {
  /// ¿Tiene buena cobertura (≥70%)?
  bool get hasGoodCoverage => coverageRatio >= 0.70;

  /// ¿Tiene cobertura deficiente (<50%)?
  bool get hasInsufficientCoverage => coverageRatio < 0.50;

  /// Número de ángulos únicos cubiertos
  int get uniqueAnglesCovered => coveredAngles.length;

  /// Número total de ángulos posibles
  int get totalAngles => knownAngles.length;

  /// ¿Varió con respecto a la semana anterior?
  bool get hasVariety => changedFromLastWeek;

  /// Mensaje para auditoría
  String get auditMessage {
    if (hasInsufficientCoverage) {
      return '⚠️ Cobertura insuficiente ($coverageRatio): $missingAngles no cubiertos';
    }
    if (!hasGoodCoverage) {
      return '⚓ Cobertura moderada ($coverageRatio): considera $missingAngles';
    }
    if (!hasVariety) {
      return '📊 Mismos ángulos que la semana anterior: varía para mejor estímulo';
    }
    return '✅ Excelente cobertura y variedad (${coverageRatio.toStringAsFixed(1)})';
  }

  /// List de recommended ángulos para siguiente semana
  List<String> get recommendedNextWeekAngles {
    // Prioridad: ángulos NO cubiertos + ángulos menos recientes
    return missingAngles;
  }
}

/// Datos predefinidos de ángulos por músculo
class MuscleAngleRegistry {
  static const Map<String, List<String>> anglesByMuscle = {
    // PUSH MUSCLES
    'pectorals': ['horizontal', 'incline', 'decline', 'vertical'],
    'anterior_deltoids': [
      'vertical',
      'horizontal',
      'lean_forward',
    ], // Press vertical, pike push, etc.
    'triceps': [
      'elbow_extended',
      'elbow_flexed',
      'neutral',
    ], // Press, rope, pushdown
    // PULL MUSCLES
    'lats': ['horizontal', 'vertical', 'unilateral'],
    'mid_back': ['horizontal', 'vertical', 'neutral'],
    'rear_deltoids': ['horizontal', 'fly', 'row'],

    // LEG MUSCLES - EXTENSORS
    'quadriceps': ['narrow_stance', 'wide_stance', 'single_leg'],
    'vastus_medialis': ['high_foot', 'leg_extension'],
    'vastus_lateralis': ['low_foot', 'sissy_squat'],

    // LEG MUSCLES - FLEXORS
    'hamstrings': ['hip_extension', 'knee_flexion', 'unilateral'],
    'biceps_femoris': ['horizontal_abduction', 'vertical'],

    // LEG MUSCLES - OTHER
    'glutes': ['horizontal_abduction', 'hip_extension', 'unilateral'],
    'adductors': ['horizontal_adduction', 'seated', 'standing'],
    'abductors': ['horizontal_abduction', 'seated', 'standing'],
    'calves': ['straight_leg', 'bent_leg', 'single_leg'],

    // ARMS
    'biceps': ['horizontal', 'vertical', 'neutral'],
  };

  /// Obtiene ángulos conocidos para un músculo
  static List<String> getAnglesForMuscle(String muscle) {
    return anglesByMuscle[muscle] ?? const [];
  }

  /// DistInt si los ejercicios datos usan suficiente variedad
  static double calculateCoverageRatio({
    required String muscle,
    required List<String> exerciseAngles,
  }) {
    final knownAngles = getAnglesForMuscle(muscle);
    if (knownAngles.isEmpty) return 0.0;

    final uniqueAngles = exerciseAngles.toSet();
    if (uniqueAngles.isEmpty) return 0.0;

    return (uniqueAngles.length / knownAngles.length).clamp(0.0, 1.0);
  }
}
