import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';

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

    // Separar en compuestos vs aislados
    final compuestos = <ExercisePrescription>[];
    final aislados = <ExercisePrescription>[];

    for (final item in items) {
      if (_isCompoundExercise(item)) {
        compuestos.add(item);
      } else {
        aislados.add(item);
      }
    }

    // Ordenar compuestos por rep range (bajos primero = más pesado)
    compuestos.sort((a, b) => a.repRange.max.compareTo(b.repRange.max));

    // Ordenar aislados por músculo
    aislados.sort((a, b) => a.muscleGroup.name.compareTo(b.muscleGroup.name));

    // Concatenar: compuestos luego aislados
    final ordered = <ExercisePrescription>[...compuestos, ...aislados];

    // Aplicar política de intercalado de músculos
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
