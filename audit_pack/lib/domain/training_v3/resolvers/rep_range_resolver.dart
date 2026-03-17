import 'package:hcs_app_lap/domain/entities/rep_range.dart';

/// Resultado de resolución de prescripción de reps para un ejercicio.
class ResolvedRepPrescription {
  final String category;
  final RepRange repRange;
  final int rirTarget;

  const ResolvedRepPrescription({
    required this.category,
    required this.repRange,
    required this.rirTarget,
  });
}

/// Resuelve rango de reps y RIR objetivo por tipo de ejercicio para Motor V3.
///
/// Reglas:
/// - compound_press -> heavy (6-8)
/// - compound_pull -> moderate (8-12)
/// - compound_lower -> heavy (6-8)
/// - row -> moderate (8-12)
/// - isolation -> light (16-20)
class RepRangeResolver {
  static const String _heavy = 'heavy';
  static const String _moderate = 'moderate';
  static const String _light = 'light';

  static const Map<String, String> _categoryByExerciseType = {
    'compound_press': _heavy,
    'compound_pull': _moderate,
    'compound_lower': _heavy,
    'row': _moderate,
    'isolation': _light,
  };

  static const Map<String, RepRange> _repRangeByCategory = {
    _heavy: RepRange(6, 8),
    _moderate: RepRange(8, 12),
    _light: RepRange(16, 20),
  };

  static const Map<String, int> _rirByCategory = {
    _heavy: 2,
    _moderate: 2,
    _light: 1,
  };

  static const Set<String> _lowerMuscles = {
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
  };

  static const Set<String> _pressMuscles = {
    'pectorals',
    'triceps',
    'deltoide_anterior',
    'deltoide_lateral',
  };

  static const Set<String> _pullMuscles = {
    'lats',
    'upper_back',
    'traps',
    'biceps',
    'deltoide_posterior',
  };

  static ResolvedRepPrescription resolve({
    required String exerciseName,
    required String muscleKey,
    String? exerciseType,
    String? movementPattern,
  }) {
    final resolvedExerciseType = resolveExerciseType(
      exerciseName: exerciseName,
      muscleKey: muscleKey,
      exerciseType: exerciseType,
      movementPattern: movementPattern,
    );

    final category = _categoryByExerciseType[resolvedExerciseType] ?? _moderate;

    return ResolvedRepPrescription(
      category: category,
      repRange: _repRangeByCategory[category]!,
      rirTarget: _rirByCategory[category]!,
    );
  }

  static String resolveExerciseType({
    required String exerciseName,
    required String muscleKey,
    String? exerciseType,
    String? movementPattern,
  }) {
    final normalizedExplicit = (exerciseType ?? '').trim().toLowerCase();
    if (_categoryByExerciseType.containsKey(normalizedExplicit)) {
      return normalizedExplicit;
    }

    if (normalizedExplicit == 'isolation') {
      return 'isolation';
    }

    final name = exerciseName.toLowerCase();
    if (name.contains('row')) {
      return 'row';
    }

    final pattern = (movementPattern ?? '').trim().toLowerCase();
    if (pattern == 'horizontal_push' || pattern == 'vertical_push') {
      return 'compound_press';
    }
    if (pattern == 'horizontal_pull' || pattern == 'vertical_pull') {
      return 'compound_pull';
    }
    if (pattern == 'squat' ||
        pattern == 'hinge' ||
        pattern == 'lunge' ||
        pattern == 'knee_flexion' ||
        pattern == 'knee_extension' ||
        pattern == 'ankle_plantarflexion') {
      return 'compound_lower';
    }

    final m = muscleKey.trim().toLowerCase();
    if (_lowerMuscles.contains(m)) {
      return 'compound_lower';
    }
    if (_pressMuscles.contains(m)) {
      return 'compound_press';
    }
    if (_pullMuscles.contains(m)) {
      return 'compound_pull';
    }

    return 'compound_pull';
  }
}
