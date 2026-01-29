import '../entities/exercise.dart';

class ExerciseSelector {
  static List<Exercise> byMuscle(
    List<Exercise> all,
    String muscleKey, {
    int limit = 6,
  }) {
    final filtered = all.where((e) => e.matchesMuscle(muscleKey)).toList();
    if (filtered.isEmpty) return [];

    // Determinista: orden estable por id luego nombre.
    filtered.sort((a, b) {
      final byId = a.id.compareTo(b.id);
      if (byId != 0) return byId;
      return a.name.compareTo(b.name);
    });

    return filtered.take(limit).toList();
  }
}
