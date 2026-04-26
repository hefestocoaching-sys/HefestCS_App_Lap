import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

enum WeekStartFocus { torso, leg }

/// Contrato Fase 2 para determinar el inicio de semana.
///
/// Reglas:
/// - predominio torso  -> inicia torso
/// - predominio pierna -> inicia pierna
/// - empate            -> inicia torso (determinístico)
class WeekStartPolicy {
  static const Set<String> _torsoMuscles = {
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
  };

  static const Set<String> _legMuscles = {
    'quads',
    'hamstrings',
    'glutes',
    'calves',
  };

  static WeekStartFocus resolveFromWeeklySets({
    required Map<String, int> weeklySetsByMuscle,
  }) {
    var torsoSets = 0;
    var legSets = 0;

    for (final entry in weeklySetsByMuscle.entries) {
      final canonical = muscle_registry.normalize(entry.key);
      if (canonical == null) {
        continue;
      }
      if (_torsoMuscles.contains(canonical)) {
        torsoSets += entry.value;
      }
      if (_legMuscles.contains(canonical)) {
        legSets += entry.value;
      }
    }

    if (legSets > torsoSets) {
      return WeekStartFocus.leg;
    }
    return WeekStartFocus.torso;
  }
}
