/// ═══════════════════════════════════════════════════════════════════════════
/// SSOT: Catálogo de contribuciones de ejercicios a músculos canónicos (14)
/// ═══════════════════════════════════════════════════════════════════════════
/// IMPORTANT: usar SOLO 14 keys canónicas:
/// chest, lats, upper_back, traps, deltoide_anterior, deltoide_lateral, deltoide_posterior,
/// biceps, triceps, quads, hamstrings, glutes, calves, abs
///
/// NO USAR: back, shoulders, forearms (legacy groups)
class ExerciseContributionCatalog {
  static const Map<String, Map<String, double>> contributions = {
    // ═══════════════════════════════════════════════════════════════════════
    // PRESS HORIZONTAL (PECHO)
    // ═══════════════════════════════════════════════════════════════════════
    'bench_press': {'chest': 1.0, 'triceps': 0.6, 'deltoide_anterior': 0.4},
    'db_bench_press': {'chest': 1.0, 'triceps': 0.5, 'deltoide_anterior': 0.4},
    'push_up': {'chest': 0.8, 'triceps': 0.5, 'deltoide_anterior': 0.3},
    'incline_bench_press': {
      'chest': 1.0,
      'deltoide_anterior': 0.5,
      'triceps': 0.5,
    },

    // ═══════════════════════════════════════════════════════════════════════
    // TIRONES VERTICALES (DORSALES + ESPALDA ALTA/TRAPECIO)
    // ═══════════════════════════════════════════════════════════════════════
    'lat_pulldown': {'lats': 1.0, 'upper_back': 0.3, 'biceps': 0.6},
    'pull_up': {'lats': 1.0, 'upper_back': 0.3, 'biceps': 0.7, 'traps': 0.2},
    'chin_up': {'lats': 0.9, 'biceps': 0.9, 'upper_back': 0.3},

    // ═══════════════════════════════════════════════════════════════════════
    // REMO HORIZONTAL (ESPALDA ALTA + DORSALES + TRAPECIO)
    // ═══════════════════════════════════════════════════════════════════════
    'barbell_row': {
      'upper_back': 1.0,
      'lats': 0.7,
      'traps': 0.4,
      'biceps': 0.6,
    },
    'db_row': {'upper_back': 1.0, 'lats': 0.6, 'biceps': 0.5, 'traps': 0.3},
    'seated_cable_row': {
      'upper_back': 1.0,
      'lats': 0.8,
      'biceps': 0.6,
      'traps': 0.4,
    },

    // ═══════════════════════════════════════════════════════════════════════
    // SQUAT / HINGE (PIERNAS)
    // ═══════════════════════════════════════════════════════════════════════
    'back_squat': {'quads': 1.0, 'glutes': 0.7, 'hamstrings': 0.3, 'abs': 0.2},
    'front_squat': {'quads': 1.0, 'glutes': 0.5, 'abs': 0.4},
    'leg_press': {'quads': 1.0, 'glutes': 0.6, 'hamstrings': 0.2},
    'romanian_deadlift': {
      'hamstrings': 1.0,
      'glutes': 0.7,
      'upper_back': 0.2,
      'traps': 0.2,
    },
    'deadlift': {
      'hamstrings': 1.0,
      'glutes': 0.9,
      'upper_back': 0.4,
      'traps': 0.5,
      'lats': 0.3,
    },
    'leg_curl': {'hamstrings': 1.0},
    'leg_extension': {'quads': 1.0},

    // ═══════════════════════════════════════════════════════════════════════
    // HOMBRO (DELTOIDES POR PORCIÓN)
    // ═══════════════════════════════════════════════════════════════════════
    'overhead_press': {
      'deltoide_anterior': 1.0,
      'deltoide_lateral': 0.5,
      'triceps': 0.6,
    },
    'lateral_raise': {'deltoide_lateral': 1.0},
    'front_raise': {'deltoide_anterior': 1.0},
    'rear_delt_fly': {'deltoide_posterior': 1.0, 'upper_back': 0.3},
    'face_pull': {'deltoide_posterior': 0.8, 'traps': 0.6, 'upper_back': 0.4},

    // ═══════════════════════════════════════════════════════════════════════
    // ISOLATION (BRAZOS)
    // ═══════════════════════════════════════════════════════════════════════
    'biceps_curl': {'biceps': 1.0},
    'hammer_curl': {'biceps': 1.0},
    'triceps_pushdown': {'triceps': 1.0},
    'overhead_triceps_extension': {'triceps': 1.0},

    // ═══════════════════════════════════════════════════════════════════════
    // PANTORRILLA + CORE
    // ═══════════════════════════════════════════════════════════════════════
    'calf_raise': {'calves': 1.0},
    'seated_calf_raise': {'calves': 1.0},
    'crunch': {'abs': 1.0},
    'plank': {'abs': 1.0},
    'russian_twist': {'abs': 1.0},
  };

  static Map<String, double> getForExercise(String exerciseKey) {
    return contributions[exerciseKey] ?? const {};
  }
}
