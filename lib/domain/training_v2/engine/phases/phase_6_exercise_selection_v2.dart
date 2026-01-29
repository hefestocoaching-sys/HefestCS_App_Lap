import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/services/exercise_selector.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_5_intensity_rir.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';

class V2SelectedExercise {
  final String exerciseId;
  final String name;
  final String muscleKey;
  final String equipment;

  const V2SelectedExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleKey,
    required this.equipment,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscleKey': muscleKey,
    'equipment': equipment,
  };
}

class Phase6ExerciseSelectionV2Result {
  /// day -> muscleLabel -> selected exercises
  final Map<int, Map<String, List<V2SelectedExercise>>> selectionsByDay;
  final List<DecisionTrace> decisions;

  const Phase6ExerciseSelectionV2Result({
    required this.selectionsByDay,
    required this.decisions,
  });
}

/// Capa 6 (v2): selección determinista, compatible con tu catálogo actual.
class Phase6ExerciseSelectionV2 {
  Phase6ExerciseSelectionV2Result run({
    required TrainingContext ctx,
    required Map<int, Map<String, V2DayMusclePrescription>> prescriptionsByDay,
    required List<Exercise> exercises,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    // Catálogo vacío: no tronar, pero dejar evidencia.
    if (exercises.isEmpty) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'Phase6ExerciseSelectionV2',
          category: 'empty_catalog',
          description:
              'El catálogo de ejercicios está vacío. Se generarán placeholders.',
          context: const {},
          timestamp: ts,
          action:
              'Revisar ExerciseCatalogLoader y assets/data/exercise_catalog.json.',
        ),
      );
    }

    // Equipo disponible (si existe en ctx). Si tu TrainingContext usa otro nombre,
    // ajusta aquí el getter SIN cambiar el resto de la lógica.
    final availableEquipment = _safeEquipment(ctx);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase6ExerciseSelectionV2',
        category: 'init',
        description: 'Inicializando selección de ejercicios (determinista).',
        context: {
          'days': prescriptionsByDay.length,
          'catalogSize': exercises.length,
          'availableEquipment': availableEquipment,
        },
        timestamp: ts,
      ),
    );

    // Track para rotación: evitar repetir por semana.
    final usedByMuscleKey = <String, Set<String>>{};

    final out = <int, Map<String, List<V2SelectedExercise>>>{};

    for (final dayEntry in prescriptionsByDay.entries) {
      final day = dayEntry.key;
      final muscleMap = dayEntry.value;

      final dayOut = <String, List<V2SelectedExercise>>{};

      for (final mEntry in muscleMap.entries) {
        final muscleLabel = mEntry.key;
        final presc = mEntry.value;

        final keys = _mapMuscleLabelToKeys(muscleLabel);
        final picked = _pickForMuscle(
          muscleLabel: muscleLabel,
          muscleKeys: keys,
          sets: presc.sets,
          exercises: exercises,
          availableEquipment: availableEquipment,
          usedByMuscleKey: usedByMuscleKey,
          decisions: decisions,
          ts: ts,
          day: day,
        );

        dayOut[muscleLabel] = picked;
      }

      out[day] = dayOut;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase6ExerciseSelectionV2',
          category: 'day_summary',
          description: 'Resumen selección de ejercicios del día.',
          context: {
            'day': day,
            'muscles': dayOut.map(
              (k, v) => MapEntry(k, v.map((e) => e.exerciseId).toList()),
            ),
          },
          timestamp: ts,
        ),
      );
    }

    return Phase6ExerciseSelectionV2Result(
      selectionsByDay: out,
      decisions: decisions,
    );
  }

  List<String> _safeEquipment(TrainingContext ctx) {
    // TrainingInterviewSnapshot no tiene availableEquipment campo.
    // Retornar lista vacía: no filtra por equipo, usa todos los ejercicios.
    return const <String>[];
  }

  List<V2SelectedExercise> _pickForMuscle({
    required String muscleLabel,
    required List<String> muscleKeys,
    required int sets,
    required List<Exercise> exercises,
    required List<String> availableEquipment,
    required Map<String, Set<String>> usedByMuscleKey,
    required List<DecisionTrace> decisions,
    required DateTime ts,
    required int day,
  }) {
    // Regla simple:
    // - si sets >= 6 → intentar 2 ejercicios (compuesto+accesorio si hay)
    // - si sets < 6 → 1 ejercicio
    final desiredCount = (sets >= 6) ? 2 : 1;

    // Candidatos por muscleKey (priorizar el primer key, fallback a los demás)
    final candidates = <Exercise>[];
    for (final k in muscleKeys) {
      candidates.addAll(ExerciseSelector.byMuscle(exercises, k, limit: 16));
    }

    // Filtro por equipo (si hay equipo declarado en ejercicios y en el perfil)
    final filtered = _filterByEquipment(candidates, availableEquipment);

    if (filtered.isEmpty) {
      // Placeholder seguro: no rompe UI, deja evidencia para QA.
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase6ExerciseSelectionV2',
          category: 'fallback_placeholder',
          description: 'Sin candidatos para músculo; se genera placeholder.',
          context: {
            'day': day,
            'muscle': muscleLabel,
            'muscleKeys': muscleKeys,
            'desiredCount': desiredCount,
          },
          timestamp: ts,
          action: 'Ampliar catálogo o revisar mapping de muscleKey.',
        ),
      );

      return List.generate(desiredCount, (i) {
        final id = '${muscleKeys.first}_placeholder_${i + 1}';
        return V2SelectedExercise(
          exerciseId: id,
          name: '$muscleLabel (Placeholder)',
          muscleKey: muscleKeys.first,
          equipment: 'bodyweight',
        );
      });
    }

    // Rotación: evitar repetir exerciseId dentro de la semana por muscleKey principal.
    final primaryKey = muscleKeys.first;
    final used = usedByMuscleKey.putIfAbsent(primaryKey, () => <String>{});

    final picked = <V2SelectedExercise>[];

    for (final ex in filtered) {
      if (picked.length >= desiredCount) break;
      if (used.contains(ex.id)) continue;

      picked.add(
        V2SelectedExercise(
          exerciseId: ex.id.isNotEmpty
              ? ex.id
              : (ex.externalId.isNotEmpty ? ex.externalId : ex.name),
          name: ex.name,
          muscleKey: ex.muscleKey,
          equipment: ex.equipment,
        ),
      );
      used.add(ex.id);
    }

    // Si no alcanzó por rotación, rellenar con los primeros disponibles (aunque repitan)
    if (picked.length < desiredCount) {
      for (final ex in filtered) {
        if (picked.length >= desiredCount) break;

        picked.add(
          V2SelectedExercise(
            exerciseId: ex.id.isNotEmpty
                ? ex.id
                : (ex.externalId.isNotEmpty ? ex.externalId : ex.name),
            name: ex.name,
            muscleKey: ex.muscleKey,
            equipment: ex.equipment,
          ),
        );
      }
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase6ExerciseSelectionV2',
        category: 'selected',
        description: 'Ejercicios seleccionados para músculo/día.',
        context: {
          'day': day,
          'muscle': muscleLabel,
          'muscleKeys': muscleKeys,
          'sets': sets,
          'selected': picked.map((e) => e.toJson()).toList(),
          'filteredCandidates': filtered.length,
          'desiredCount': desiredCount,
        },
        timestamp: ts,
      ),
    );

    return picked;
  }

  List<Exercise> _filterByEquipment(
    List<Exercise> list,
    List<String> availableEquipment,
  ) {
    if (availableEquipment.isEmpty) return list;
    final eq = availableEquipment.map((e) => e.toLowerCase()).toSet();

    // Si exercise.equipment está vacío -> no filtrar (compatibilidad)
    final out = list.where((e) {
      final exEq = e.equipment.toLowerCase().trim();
      if (exEq.isEmpty) return true;
      return eq.contains(exEq);
    }).toList();

    // Si filtró demasiado, fallback al original (no dejar sin candidatos)
    return out.isNotEmpty ? out : list;
  }

  List<String> _mapMuscleLabelToKeys(String label) {
    final norm = normalizeMuscleKey(label);

    // 1) Si ya es canónica, devolver directa
    if (MuscleKeys.isCanonical(norm)) return <String>[norm];

    // 2) Grupos legacy
    if (norm == 'back' || norm == 'back_group') {
      return const <String>[
        MuscleKeys.lats,
        MuscleKeys.upperBack,
        MuscleKeys.traps,
      ];
    }
    if (norm == 'shoulders' || norm == 'shoulders_group') {
      return const <String>[
        MuscleKeys.deltoideAnterior,
        MuscleKeys.deltoideLateral,
        MuscleKeys.deltoidePosterior,
      ];
    }

    // 3) Expansión por helper (legs/arms)
    final expanded = MuscleKeys.expandGroup(norm);
    if (expanded.isNotEmpty) return expanded.toList();

    // 4) Fallback: usa norm tal cual para que el selector intente match
    return <String>[norm];
  }
}
