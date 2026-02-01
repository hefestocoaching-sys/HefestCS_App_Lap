// lib/domain/data/split_templates_v2.dart

import 'package:hcs_app_lap/core/enums/muscle_group.dart';

/// Resultado de selección de split
class SplitSelectionResult {
  final SplitTemplateV2 template;
  final String reason;
  final Map<String, dynamic> context;

  const SplitSelectionResult({
    required this.template,
    required this.reason,
    this.context = const {},
  });
}

/// Template de split V2 (científicamente validado)
class SplitTemplateV2 {
  final String id;
  final String nameEs;
  final int daysPerWeek;
  final Map<int, List<MuscleGroup>> dayToMuscles;
  final String description;
  final List<String> idealFor;

  const SplitTemplateV2({
    required this.id,
    required this.nameEs,
    required this.daysPerWeek,
    required this.dayToMuscles,
    required this.description,
    required this.idealFor,
  });

  /// Calcula frecuencia por músculo (cuántas veces entrena por semana)
  Map<MuscleGroup, int> get frequencyByMuscle {
    final freq = <MuscleGroup, int>{};
    for (final muscles in dayToMuscles.values) {
      for (final muscle in muscles) {
        freq[muscle] = (freq[muscle] ?? 0) + 1;
      }
    }
    return freq;
  }

  /// Obtiene músculos del día específico
  List<MuscleGroup> getMusclesForDay(int day) {
    return dayToMuscles[day] ?? [];
  }

  /// Verifica si el split es válido (>=3 músculos por día)
  bool get isValid {
    for (final muscles in dayToMuscles.values) {
      if (muscles.length < 3) return false;
    }
    return true;
  }

  /// Valida el split y lanza excepción si inválido
  void validate() {
    for (final entry in dayToMuscles.entries) {
      final day = entry.key;
      final muscles = entry.value;

      if (muscles.length < 3) {
        throw StateError(
          'Split "$id" inválido: Día $day tiene solo ${muscles.length} músculos. '
          'Mínimo requerido: 3 músculos por día.\n'
          'Músculos asignados: ${muscles.map((m) => m.name).join(", ")}',
        );
      }
    }
  }

  /// Obtiene total de músculos únicos en el split
  int get totalUniqueMuscles {
    final unique = <MuscleGroup>{};
    for (final muscles in dayToMuscles.values) {
      unique.addAll(muscles);
    }
    return unique.length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEs': nameEs,
    'daysPerWeek': daysPerWeek,
    'dayToMuscles': dayToMuscles.map(
      (day, muscles) =>
          MapEntry(day.toString(), muscles.map((m) => m.name).toList()),
    ),
    'description': description,
    'idealFor': idealFor,
    'frequencyByMuscle': frequencyByMuscle.map(
      (muscle, freq) => MapEntry(muscle.name, freq),
    ),
  };
}

/// Catálogo de Split Templates V2 (científicamente validados)
class SplitTemplatesV2 {
  // ════════════════════════════════════════════════════════════════
  // TEMPLATE 1: FULL BODY 3X (Frecuencia 3x por músculo)
  // ════════════════════════════════════════════════════════════════

  /// Full Body 3x - Balanceado (50/50 upper/lower)
  static SplitTemplateV2 fullBody3xBalanced() {
    return const SplitTemplateV2(
      id: 'full_body_3x_balanced',
      nameEs: 'Full Body 3x Balanceado',
      daysPerWeek: 3,
      dayToMuscles: {
        1: [
          MuscleGroup.chest,
          MuscleGroup.quads,
          MuscleGroup.lats,
          MuscleGroup.hamstrings,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.biceps,
        ],
        2: [
          MuscleGroup.upperBack,
          MuscleGroup.glutes,
          MuscleGroup.chest,
          MuscleGroup.shoulderLateral,
          MuscleGroup.triceps,
          MuscleGroup.calves,
        ],
        3: [
          MuscleGroup.lats,
          MuscleGroup.quads,
          MuscleGroup.chest,
          MuscleGroup.hamstrings,
          MuscleGroup.shoulderPosterior,
          MuscleGroup.abs,
        ],
      },
      description:
          'Full Body 3 veces por semana. Frecuencia 3x para todos los grupos musculares principales. '
          'Ideal para principiantes y personas con poco tiempo.',
      idealFor: [
        'Principiantes (0-1 año)',
        'Personas con 3 días disponibles',
        'Prioridad balanceada upper/lower',
      ],
    );
  }

  /// Full Body 3x - Énfasis Lower (60/40 lower/upper)
  static SplitTemplateV2 fullBody3xLowerPriority() {
    return const SplitTemplateV2(
      id: 'full_body_3x_lower_priority',
      nameEs: 'Full Body 3x Énfasis Pierna',
      daysPerWeek: 3,
      dayToMuscles: {
        1: [
          MuscleGroup.glutes,
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
        ],
        2: [
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.biceps,
          MuscleGroup.triceps,
        ],
        3: [
          MuscleGroup.glutes,
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderPosterior,
        ],
      },
      description:
          'Full Body con énfasis en pierna/glúteos (60% lower, 40% upper). '
          'Lower entrena con mayor volumen en días 1 y 3.',
      idealFor: [
        'Prioridad glúteos/piernas',
        'Mujeres con objetivo estético lower body',
        '3 días disponibles',
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TEMPLATE 2: UPPER/LOWER 4X (Frecuencia 2x por músculo)
  // ════════════════════════════════════════════════════════════════

  /// Upper/Lower 4x - Balanceado (ULUL)
  static SplitTemplateV2 upperLower4xBalanced() {
    return const SplitTemplateV2(
      id: 'upper_lower_4x_balanced',
      nameEs: 'Torso/Pierna 4x Balanceado',
      daysPerWeek: 4,
      dayToMuscles: {
        1: [
          // UPPER A
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.triceps,
        ],
        2: [
          // LOWER A
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.calves,
        ],
        3: [
          // UPPER B
          MuscleGroup.chest,
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.biceps,
        ],
        4: [
          // LOWER B
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.abs,
        ],
      },
      description:
          'Upper/Lower clásico 4 días. Frecuencia 2x para upper y lower. '
          'Secuencia: Upper A, Lower A, Upper B, Lower B.',
      idealFor: [
        'Intermedios (1-3 años)',
        '4 días disponibles',
        'Prioridad balanceada',
      ],
    );
  }

  /// Upper/Lower 4x - Énfasis Lower (LULU)
  static SplitTemplateV2 upperLower4xLowerPriority() {
    return const SplitTemplateV2(
      id: 'upper_lower_4x_lower_priority',
      nameEs: 'Torso/Pierna 4x Énfasis Pierna',
      daysPerWeek: 4,
      dayToMuscles: {
        1: [
          // LOWER A (Glute-focused)
          MuscleGroup.glutes,
          MuscleGroup.hamstrings,
          MuscleGroup.quads,
        ],
        2: [
          // UPPER A
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
        ],
        3: [
          // LOWER B (Quad-focused)
          MuscleGroup.glutes,
          MuscleGroup.quads,
          MuscleGroup.calves,
        ],
        4: [
          // UPPER B + Glute Accessories
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.biceps,
          MuscleGroup.triceps,
          MuscleGroup.glutes,
        ],
      },
      description:
          'Upper/Lower invertido a Lower/Upper para priorizar pierna/glúteos. '
          'Secuencia: Lower A (glute), Upper A, Lower B (quad), Upper B + glute accessories.',
      idealFor: [
        'Prioridad glúteos/piernas',
        'Mujeres con objetivo estético lower body',
        '4 días disponibles',
      ],
    );
  }

  /// Upper/Lower 4x - Énfasis Upper (UULL)
  static SplitTemplateV2 upperLower4xUpperPriority() {
    return const SplitTemplateV2(
      id: 'upper_lower_4x_upper_priority',
      nameEs: 'Torso/Pierna 4x Énfasis Torso',
      daysPerWeek: 4,
      dayToMuscles: {
        1: [
          // UPPER A (Heavy compounds)
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.triceps,
        ],
        2: [
          // UPPER B (Hypertrophy focus)
          MuscleGroup.chest,
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.shoulderPosterior,
          MuscleGroup.biceps,
        ],
        3: [
          // LOWER A (Maintenance)
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
        ],
        4: [
          // LOWER B (Maintenance)
          MuscleGroup.quads,
          MuscleGroup.glutes,
          MuscleGroup.calves,
        ],
      },
      description:
          'Upper/Lower con énfasis upper (2 días consecutivos upper). '
          'Secuencia: Upper A, Upper B, Lower A, Lower B. '
          'Ideal para priorizar pecho/espalda/hombros.',
      idealFor: [
        'Prioridad pecho/espalda/hombros',
        'Hombres con objetivo estético upper body',
        '4 días disponibles',
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TEMPLATE 3: PPL 6X (Frecuencia 2x por músculo)
  // ════════════════════════════════════════════════════════════════

  /// Push/Pull/Legs 6x - Frecuencia 2x
  static SplitTemplateV2 ppl6xFrequency2() {
    return const SplitTemplateV2(
      id: 'ppl_6x_freq2',
      nameEs: 'Push/Pull/Legs 6x',
      daysPerWeek: 6,
      dayToMuscles: {
        1: [
          // PUSH A
          MuscleGroup.chest,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.shoulderLateral,
          MuscleGroup.triceps,
        ],
        2: [
          // PULL A
          MuscleGroup.lats,
          MuscleGroup.upperBack,
          MuscleGroup.traps,
          MuscleGroup.shoulderPosterior,
          MuscleGroup.biceps,
        ],
        3: [
          // LEGS A
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.calves,
          MuscleGroup.abs,
        ],
        4: [
          // PUSH B
          MuscleGroup.chest,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.shoulderLateral,
          MuscleGroup.triceps,
        ],
        5: [
          // PULL B
          MuscleGroup.lats,
          MuscleGroup.upperBack,
          MuscleGroup.traps,
          MuscleGroup.shoulderPosterior,
          MuscleGroup.biceps,
        ],
        6: [
          // LEGS B
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.calves,
          MuscleGroup.abs,
        ],
      },
      description:
          'Push/Pull/Legs clásico 6 días. Frecuencia 2x para todos los músculos. '
          'Secuencia: Push A, Pull A, Legs A, Push B, Pull B, Legs B.',
      idealFor: [
        'Avanzados (3+ años)',
        '6 días disponibles',
        'Máxima frecuencia y volumen',
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TEMPLATE 4: UPPER/LOWER 5X (Frecuencia 3x Upper O 3x Lower)
  // ════════════════════════════════════════════════════════════════

  /// Upper/Lower 5x - Frecuencia 3x Upper
  static SplitTemplateV2 upperLower5xUpperPriority() {
    return const SplitTemplateV2(
      id: 'upper_lower_5x_upper_priority',
      nameEs: 'Torso/Pierna 5x Énfasis Torso (3x Upper)',
      daysPerWeek: 5,
      dayToMuscles: {
        1: [
          // UPPER A (Heavy)
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.triceps,
        ],
        2: [
          // LOWER A
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.calves,
        ],
        3: [
          // UPPER B (Hypertrophy)
          MuscleGroup.chest,
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.biceps,
        ],
        4: [
          // LOWER B
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.abs,
        ],
        5: [
          // UPPER C (Pump/Accessories)
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderPosterior,
          MuscleGroup.biceps,
          MuscleGroup.triceps,
        ],
      },
      description:
          'Upper/Lower 5 días con frecuencia 3x upper, 2x lower. '
          'Secuencia: U, L, U, L, U. Ideal para priorizar torso.',
      idealFor: [
        'Prioridad pecho/espalda/hombros',
        'Hombres con objetivo estético upper body',
        '5 días disponibles',
      ],
    );
  }

  /// Upper/Lower 5x - Frecuencia 3x Lower
  static SplitTemplateV2 upperLower5xLowerPriority() {
    return const SplitTemplateV2(
      id: 'upper_lower_5x_lower_priority',
      nameEs: 'Torso/Pierna 5x Énfasis Pierna (3x Lower)',
      daysPerWeek: 5,
      dayToMuscles: {
        1: [
          // LOWER A (Glute-focused)
          MuscleGroup.glutes,
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.calves,
        ],
        2: [
          // UPPER A
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
          MuscleGroup.triceps,
        ],
        3: [
          // LOWER B (Quad-focused)
          MuscleGroup.glutes,
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.abs,
        ],
        4: [
          // UPPER B
          MuscleGroup.chest,
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.biceps,
        ],
        5: [
          // LOWER C (Posterior chain)
          MuscleGroup.glutes,
          MuscleGroup.hamstrings,
          MuscleGroup.quads,
          MuscleGroup.calves,
        ],
      },
      description:
          'Upper/Lower 5 días con frecuencia 3x lower, 2x upper. '
          'Secuencia: L, U, L, U, L. Ideal para priorizar pierna/glúteos.',
      idealFor: [
        'Prioridad glúteos/piernas',
        'Mujeres con objetivo estético lower body',
        '5 días disponibles',
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TEMPLATE 5: GLUTE SPECIALIZATION 4X
  // ════════════════════════════════════════════════════════════════

  /// Glute Specialization 4x (Mujeres)
  static SplitTemplateV2 gluteSpecialization4x() {
    return const SplitTemplateV2(
      id: 'glute_specialization_4x',
      nameEs: 'Especialización Glúteos 4x',
      daysPerWeek: 4,
      dayToMuscles: {
        1: [
          // LOWER A (Glute-focused: hip extension)
          MuscleGroup.glutes,
          MuscleGroup.hamstrings,
          MuscleGroup.quads,
        ],
        2: [
          // UPPER A (Maintenance)
          MuscleGroup.chest,
          MuscleGroup.lats,
          MuscleGroup.shoulderAnterior,
        ],
        3: [
          // LOWER B (Glute-focused: hip abduction + squat)
          MuscleGroup.glutes,
          MuscleGroup.quads,
          MuscleGroup.calves,
        ],
        4: [
          // UPPER B + Glute Accessories
          MuscleGroup.upperBack,
          MuscleGroup.shoulderLateral,
          MuscleGroup.biceps,
          MuscleGroup.triceps,
          MuscleGroup.glutes,
        ],
      },
      description:
          'Especialización de glúteos con frecuencia 3-4x por semana. '
          'Día 1: hip extension (hip thrust, RDL). '
          'Día 3: hip abduction + squat pattern. '
          'Día 4: glute accessories (kickbacks, band work). '
          'Upper body en mantenimiento.',
      idealFor: [
        'Prioridad MÁXIMA glúteos',
        'Mujeres con objetivo estético glúteos',
        '4 días disponibles',
        'Mesociclo especialización (4-8 semanas)',
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SELECTOR INTELIGENTE DE SPLIT
  // ════════════════════════════════════════════════════════════════

  /// Selecciona el split óptimo según frecuencia y prioridades
  static SplitSelectionResult selectOptimal({
    required int daysPerWeek,
    required List<MuscleGroup> primaryMuscles,
    List<MuscleGroup> secondaryMuscles = const [],
  }) {
    // Detectar si es especialización de glúteos
    final isGluteSpecialization =
        primaryMuscles.contains(MuscleGroup.glutes) &&
        primaryMuscles.length == 1;

    // Detectar prioridad lower (glutes, quads, hamstrings)
    final lowerMuscles = {
      MuscleGroup.glutes,
      MuscleGroup.quads,
      MuscleGroup.hamstrings,
    };
    final primaryLowerCount = primaryMuscles
        .where((m) => lowerMuscles.contains(m))
        .length;
    final isLowerPriority = primaryLowerCount >= 2;

    // Detectar prioridad upper (chest, lats, shoulders)
    final upperMuscles = {
      MuscleGroup.chest,
      MuscleGroup.lats,
      MuscleGroup.shoulderAnterior,
      MuscleGroup.shoulderLateral,
      MuscleGroup.upperBack,
    };
    final primaryUpperCount = primaryMuscles
        .where((m) => upperMuscles.contains(m))
        .length;
    final isUpperPriority = primaryUpperCount >= 2;

    // LÓGICA DE SELECCIÓN
    switch (daysPerWeek) {
      case 3:
        if (isLowerPriority) {
          return SplitSelectionResult(
            template: fullBody3xLowerPriority(),
            reason: 'Frecuencia 3 días + prioridad lower → Full Body 3x Lower',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        } else {
          return SplitSelectionResult(
            template: fullBody3xBalanced(),
            reason: 'Frecuencia 3 días + prioridad balanceada → Full Body 3x',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        }

      case 4:
        if (isGluteSpecialization) {
          return SplitSelectionResult(
            template: gluteSpecialization4x(),
            reason: 'Prioridad EXCLUSIVA glúteos → Glute Specialization 4x',
            context: {
              'primaryMuscles': ['glutes'],
            },
          );
        } else if (isLowerPriority) {
          return SplitSelectionResult(
            template: upperLower4xLowerPriority(),
            reason:
                'Frecuencia 4 días + prioridad lower → Upper/Lower 4x Lower',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        } else if (isUpperPriority) {
          return SplitSelectionResult(
            template: upperLower4xUpperPriority(),
            reason:
                'Frecuencia 4 días + prioridad upper → Upper/Lower 4x Upper',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        } else {
          return SplitSelectionResult(
            template: upperLower4xBalanced(),
            reason: 'Frecuencia 4 días + prioridad balanceada → Upper/Lower 4x',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        }

      case 5:
        if (isLowerPriority) {
          return SplitSelectionResult(
            template: upperLower5xLowerPriority(),
            reason:
                'Frecuencia 5 días + prioridad lower → Upper/Lower 5x (3x Lower)',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        } else if (isUpperPriority) {
          return SplitSelectionResult(
            template: upperLower5xUpperPriority(),
            reason:
                'Frecuencia 5 días + prioridad upper → Upper/Lower 5x (3x Upper)',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        } else {
          // Default a upper priority si balanceado
          return SplitSelectionResult(
            template: upperLower5xUpperPriority(),
            reason: 'Frecuencia 5 días + prioridad balanceada → Upper/Lower 5x',
            context: {
              'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
            },
          );
        }

      case 6:
        return SplitSelectionResult(
          template: ppl6xFrequency2(),
          reason: 'Frecuencia 6 días → Push/Pull/Legs 6x (frecuencia 2x)',
          context: {
            'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
          },
        );

      default:
        // Fallback: si frecuencia no estándar, usar el más cercano
        if (daysPerWeek <= 3) {
          return SplitSelectionResult(
            template: fullBody3xBalanced(),
            reason:
                'Frecuencia $daysPerWeek días (no estándar) → Full Body 3x (fallback)',
            context: {
              'warning': 'Frecuencia no estándar, usando fallback',
              'requestedDays': daysPerWeek,
            },
          );
        } else {
          return SplitSelectionResult(
            template: upperLower4xBalanced(),
            reason:
                'Frecuencia $daysPerWeek días (no estándar) → Upper/Lower 4x (fallback)',
            context: {
              'warning': 'Frecuencia no estándar, usando fallback',
              'requestedDays': daysPerWeek,
            },
          );
        }
    }
  }

  /// Retorna todos los templates disponibles
  static List<SplitTemplateV2> get all => [
    fullBody3xBalanced(),
    fullBody3xLowerPriority(),
    upperLower4xBalanced(),
    upperLower4xLowerPriority(),
    upperLower4xUpperPriority(),
    ppl6xFrequency2(),
    upperLower5xUpperPriority(),
    upperLower5xLowerPriority(),
    gluteSpecialization4x(),
  ];

  /// Busca template por ID
  static SplitTemplateV2? byId(String id) {
    return all.cast<SplitTemplateV2?>().firstWhere(
      (t) => t?.id == id,
      orElse: () => null,
    );
  }

  /// Retorna templates por frecuencia
  static List<SplitTemplateV2> byFrequency(int daysPerWeek) {
    return all.where((t) => t.daysPerWeek == daysPerWeek).toList();
  }
}
