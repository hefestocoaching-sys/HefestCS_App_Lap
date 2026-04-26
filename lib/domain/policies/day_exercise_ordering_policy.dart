import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/policies/structural_exercise_order_contract.dart';

/// Política de ordenamiento AA (aproximado-alternado) para ejercicios de un día
///
/// Reglas:
/// 1) Primarios (compuestos) primero.
/// 2) Intercalar músculos/patrones si hay más de 1 opción (evitar 2 seguidos del mismo músculo si existe alternativa).
/// 3) Accesorios y aislados al final.
/// 4) Mantener "biseries" por letras si ya existe esa abstracción.
class DayExerciseOrderingPolicy {
  /// Ordena una lista de ejercicios de un día según política AA
  /// Retorna nueva lista ordenada sin modificar la original
  static List<ExercisePrescription> orderDay(List<ExercisePrescription> items) {
    if (items.isEmpty || items.length <= 1) return List.from(items);

    final ordered = List<ExercisePrescription>.from(items)
      ..sort((a, b) {
        final aIndex = StructuralExerciseOrderContract.structuralIndex(
          isLargeMuscle: _isLargeMuscle(a.muscleGroup),
          isCompound: _isCompoundExercise(a),
          intensityZone: _zoneFromRepMax(a.repRange.max),
        );
        final bIndex = StructuralExerciseOrderContract.structuralIndex(
          isLargeMuscle: _isLargeMuscle(b.muscleGroup),
          isCompound: _isCompoundExercise(b),
          intensityZone: _zoneFromRepMax(b.repRange.max),
        );
        return aIndex.compareTo(bIndex);
      });

    return _interleaveMuscles(ordered);
  }

  /// Detecta si un ejercicio es compuesto basado en código/nombre y muscleGroup
  static bool _isCompoundExercise(ExercisePrescription ex) {
    final code = ex.exerciseCode.toLowerCase();
    final name = ex.exerciseName.toLowerCase();

    // Patrones conocidos de compuestos
    const compoundPatterns = [
      'squat',
      'deadlift',
      'rdl',
      'bench',
      'press',
      'row',
      'pull',
      'chinup',
      'dip',
      'thrust',
      'overhead',
      'clean',
      'snatch',
      'curl', // multi-articular
    ];

    final isCompoundPattern = compoundPatterns.any(
      (p) => code.contains(p) || name.contains(p),
    );

    // Heurística adicional: si repRange.max <= 10 y muscleGroup es grande => probably compound
    if (!isCompoundPattern && ex.repRange.max <= 10) {
      final largeMuscles = [
        MuscleGroup.chest,
        MuscleGroup.back,
        MuscleGroup.quads,
        MuscleGroup.glutes,
      ];
      if (largeMuscles.contains(ex.muscleGroup)) {
        return true;
      }
    }

    return isCompoundPattern;
  }

  static bool _isLargeMuscle(MuscleGroup group) {
    return group == MuscleGroup.chest ||
        group == MuscleGroup.back ||
        group == MuscleGroup.quads ||
        group == MuscleGroup.glutes;
  }

  static String _zoneFromRepMax(int repsMax) {
    if (repsMax <= 8) return 'heavy';
    if (repsMax <= 15) return 'medium';
    return 'light';
  }

  /// Intercala ejercicios para evitar músculos consecutivos
  /// Si hay alternativas, rota patrones
  static List<ExercisePrescription> _interleaveMuscles(
    List<ExercisePrescription> ordered,
  ) {
    if (ordered.length <= 2) return ordered;

    final result = <ExercisePrescription>[];
    final remaining = List<ExercisePrescription>.from(ordered);

    // Agregar primero del inicio
    if (remaining.isNotEmpty) {
      result.add(remaining.removeAt(0));
    }

    // Intercalar evitando músculos consecutivos
    while (remaining.isNotEmpty) {
      final lastMuscle = result.isNotEmpty ? result.last.muscleGroup : null;

      // Buscar próximo ejercicio que NO sea del mismo músculo
      int nextIdx = -1;
      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].muscleGroup != lastMuscle) {
          nextIdx = i;
          break;
        }
      }

      // Si todos los restantes son del mismo músculo, tomar el primero
      if (nextIdx < 0 && remaining.isNotEmpty) {
        nextIdx = 0;
      }

      if (nextIdx >= 0) {
        result.add(remaining.removeAt(nextIdx));
      }
    }

    return result;
  }
}
