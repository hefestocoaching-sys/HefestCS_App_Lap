// Plantillas canónicas de split para generación de planes de entrenamiento.
// Cada plantilla define la estructura de días y músculos para diferentes
// esquemas de entrenamiento (3, 4, 5, 6 días).

import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart' as canon;

class LegacySplitTemplate {
  final String id;
  final String name;
  final int daysPerWeek;
  final Map<int, List<String>> dayToMuscles; // 1-indexed
  final String description;

  LegacySplitTemplate({
    required this.id,
    required this.name,
    required this.daysPerWeek,
    required this.dayToMuscles,
    required this.description,
  });

  /// Obtener músculos para un día específico
  List<String> getMusclesForDay(int dayNumber) {
    return dayToMuscles[dayNumber] ?? [];
  }
}

/// Colección estática de plantillas canónicas
class LegacySplitTemplates {
  static final Map<int, List<LegacySplitTemplate>> _templates = {
    3: _build3DaySplits(),
    4: _build4DaySplits(),
    5: _build5DaySplits(),
    6: _build6DaySplits(),
  };

  /// Obtener todas las plantillas para un número de días
  static List<LegacySplitTemplate> getTemplatesForDays(int days) {
    return _templates[days] ?? [];
  }

  /// Obtener una plantilla específica por ID
  static LegacySplitTemplate? getTemplateById(String id) {
    for (final list in _templates.values) {
      for (final template in list) {
        if (template.id == id) return template;
      }
    }
    return null;
  }

  // ============================================================
  // PLANTILLAS DE 3 DÍAS
  // ============================================================

  static List<LegacySplitTemplate> _build3DaySplits() {
    return [
      LegacySplitTemplate(
        id: '3d_full_body',
        name: 'Full Body',
        daysPerWeek: 3,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
          2: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
          3: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
        },
        description:
            'Cuerpo completo en cada sesión. Ideal para principiantes.',
      ),
      LegacySplitTemplate(
        id: '3d_upper_lower_full',
        name: 'Upper / Lower / Full',
        daysPerWeek: 3,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          2: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          3: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
        },
        description:
            'Alternancia entre tren superior, inferior y cuerpo completo.',
      ),
    ];
  }

  // ============================================================
  // PLANTILLAS DE 4 DÍAS
  // ============================================================

  static List<LegacySplitTemplate> _build4DaySplits() {
    return [
      LegacySplitTemplate(
        id: '4d_torso_pierna',
        name: 'Torso / Pierna',
        daysPerWeek: 4,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.lats,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ], // Torso
          2: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ], // Pierna
          3: [
            MuscleKeys.chest,
            MuscleKeys.lats,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ], // Torso
          4: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ], // Pierna
        },
        description: 'Alternancia 2x2 entre tren superior e inferior.',
      ),
      LegacySplitTemplate(
        id: '4d_upper_lower_upper_lower',
        name: 'UL UL',
        daysPerWeek: 4,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          2: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
            MuscleKeys.abs,
          ],
          3: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          4: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
            MuscleKeys.abs,
          ],
        },
        description: 'Upper/Lower tradicional con distribución equilibrada.',
      ),
      LegacySplitTemplate(
        id: '4d_ppl_rest',
        name: 'Push / Pull / Legs / Rest',
        daysPerWeek: 4,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.deltoideLateral,
            MuscleKeys.triceps,
          ], // Push (empuje)
          2: [MuscleKeys.upperBack, MuscleKeys.biceps], // Pull (tracción)
          3: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ], // Legs
          4: [], // Rest (descanso)
        },
        description: 'Push/Pull/Legs clásico con un día de descanso.',
      ),
      LegacySplitTemplate(
        id: '4d_fb_pierna_fb_torso',
        name: 'FB / Pierna / FB / Torso',
        daysPerWeek: 4,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ], // Fullbody
          2: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
            MuscleKeys.abs,
          ], // Pierna
          3: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ], // Fullbody enfatizando básicos
          4: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
            MuscleKeys.abs,
          ], // Torso
        },
        description: 'Fullbody, pierna, fullbody, torso (4d).',
      ),
    ];
  }

  // ============================================================
  // PLANTILLAS DE 5 DÍAS
  // ============================================================

  static List<LegacySplitTemplate> _build5DaySplits() {
    return [
      LegacySplitTemplate(
        id: '5d_ppl_xl',
        name: 'Push / Pull / Legs X2',
        daysPerWeek: 5,
        dayToMuscles: {
          1: [MuscleKeys.chest, MuscleKeys.deltoideLateral, MuscleKeys.triceps],
          2: [MuscleKeys.upperBack, MuscleKeys.biceps],
          3: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          4: [MuscleKeys.chest, MuscleKeys.deltoideLateral, MuscleKeys.triceps],
          5: [MuscleKeys.upperBack, MuscleKeys.biceps],
        },
        description: 'PPL repetido 1.67 veces en la semana.',
      ),
      LegacySplitTemplate(
        id: '5d_upper_lower_full',
        name: 'Upper / Lower / Upper / Lower / Full',
        daysPerWeek: 5,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          2: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          3: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          4: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          5: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
        },
        description: 'Upper/Lower con un día de cuerpo completo.',
      ),
      LegacySplitTemplate(
        id: '5d_ppl_full',
        name: 'Push / Pull / Legs / Full / Full',
        daysPerWeek: 5,
        dayToMuscles: {
          1: [MuscleKeys.chest, MuscleKeys.deltoideLateral, MuscleKeys.triceps],
          2: [MuscleKeys.upperBack, MuscleKeys.biceps],
          3: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          4: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
          5: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
          ],
        },
        description: 'PPL con dos días adicionales de cuerpo completo.',
      ),
    ];
  }

  // ============================================================
  // PLANTILLAS DE 6 DÍAS
  // ============================================================

  static List<LegacySplitTemplate> _build6DaySplits() {
    return [
      LegacySplitTemplate(
        id: '6d_ppl',
        name: 'Push / Pull / Legs X2',
        daysPerWeek: 6,
        dayToMuscles: {
          1: [MuscleKeys.chest, MuscleKeys.deltoideLateral, MuscleKeys.triceps],
          2: [MuscleKeys.upperBack, MuscleKeys.biceps],
          3: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          4: [MuscleKeys.chest, MuscleKeys.deltoideLateral, MuscleKeys.triceps],
          5: [MuscleKeys.upperBack, MuscleKeys.biceps],
          6: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
        },
        description: 'PPL doble: máxima frecuencia y volumen.',
      ),
      LegacySplitTemplate(
        id: '6d_upper_lower_x3',
        name: 'Upper / Lower X3',
        daysPerWeek: 6,
        dayToMuscles: {
          1: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          2: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          3: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          4: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
          5: [
            MuscleKeys.chest,
            MuscleKeys.upperBack,
            MuscleKeys.deltoideLateral,
            MuscleKeys.biceps,
            MuscleKeys.triceps,
          ],
          6: [
            MuscleKeys.quads,
            MuscleKeys.hamstrings,
            MuscleKeys.glutes,
            MuscleKeys.calves,
          ],
        },
        description: 'Upper/Lower triple: frecuencia muy alta.',
      ),
    ];
  }
}

/// Adapter que convierte plantillas legacy a canon.SplitTemplate para SSOT
class SplitTemplateCatalog {
  /// Obtiene plantillas en formato canónico (domain/entities/split_template.dart)
  static List<canon.SplitTemplate> getTemplatesForDays(int days) {
    final legacy = LegacySplitTemplates.getTemplatesForDays(days);
    return legacy.map((t) {
      // dayMuscles YA deben venir como muscle keys canónicas (por D1)
      final dayMuscles = t.dayToMuscles;

      // dailyVolume: inicial vacío (el motor lo calcula después)
      final dailyVolume = <int, Map<String, int>>{};
      for (final day in dayMuscles.keys) {
        dailyVolume[day] = <String, int>{};
      }

      return canon.SplitTemplate(
        splitId: t.id,
        daysPerWeek: t.daysPerWeek,
        dayMuscles: dayMuscles,
        dailyVolume: dailyVolume,
      );
    }).toList();
  }
}
