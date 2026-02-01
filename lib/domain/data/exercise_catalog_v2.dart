// lib/domain/data/exercise_catalog_v2.dart

import 'package:hcs_app_lap/core/enums/muscle_group.dart';

/// Tipos de equipamiento
enum EquipmentType {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
}

/// Patrones de movimiento fundamentales
enum MovementPattern {
  horizontalPress, // Press horizontal (bench press)
  inclinePress, // Press inclinado
  declinePress, // Press declinado
  overheadPress, // Press vertical
  verticalPull, // Tracción vertical (pullup, lat pulldown)
  horizontalRow, // Remo horizontal
  diagonalPull, // Tracción diagonal (pullover)
  squat, // Sentadilla
  hinge, // Bisagra de cadera (deadlift, RDL)
  lunge, // Zancada/unilateral
  hipExtension, // Extensión de cadera (hip thrust)
  hipAbduction, // Abducción de cadera
  kneeFlexion, // Flexión de rodilla (leg curl)
  kneeExtension, // Extensión de rodilla (leg extension)
  isolation, // Aislamiento (fly, curl, extension)
  rotation, // Rotación (wood chop)
  antiRotation, // Anti-rotación (pallof press)
}

/// Ángulo de ejercicio (para multiplanar)
enum ExerciseAngle {
  flat, // 0°
  incline30, // 30°
  incline45, // 45°
  decline, // -15°
  overhead, // 90° vertical
  neutral, // Sin ángulo específico
}

/// Complejidad del ejercicio
enum ExerciseComplexity {
  compound, // Multiarticular, movimiento base
  accessory, // Accesorio/aislamiento
}

/// Ejercicio V2 (científicamente curado)
class ExerciseV2 {
  final String id;
  final String nameEs;
  final EquipmentType equipment;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<MuscleGroup> tertiaryMuscles;
  final MovementPattern pattern;
  final ExerciseAngle angle;
  final ExerciseComplexity complexity;

  const ExerciseV2({
    required this.id,
    required this.nameEs,
    required this.equipment,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.tertiaryMuscles = const [],
    required this.pattern,
    required this.angle,
    required this.complexity,
  });

  /// Verifica si el ejercicio trabaja un músculo específico
  bool targetsMuscle(MuscleGroup muscle) {
    return primaryMuscles.contains(muscle) || secondaryMuscles.contains(muscle);
  }

  /// Verifica si es compound (multiarticular)
  bool get isCompound => complexity == ExerciseComplexity.compound;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEs': nameEs,
    'equipment': equipment.name,
    'primaryMuscles': primaryMuscles.map((m) => m.name).toList(),
    'secondaryMuscles': secondaryMuscles.map((m) => m.name).toList(),
    'tertiaryMuscles': tertiaryMuscles.map((m) => m.name).toList(),
    'pattern': pattern.name,
    'angle': angle.name,
    'complexity': complexity.name,
  };
}

/// Catálogo V2: 200+ ejercicios curados científicamente
class ExerciseCatalogV2 {
  static const _exercises = <ExerciseV2>[
    // ════════════════════════════════════════════════════════════════
    // PECHO (Pectorales)
    // ════════════════════════════════════════════════════════════════

    // HORIZONTAL PRESS
    ExerciseV2(
      id: 'bench_press_barbell',
      nameEs: 'Press Banca con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulderAnterior],
      pattern: MovementPattern.horizontalPress,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'bench_press_dumbbell',
      nameEs: 'Press Banca con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulderAnterior],
      pattern: MovementPattern.horizontalPress,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'bench_press_machine',
      nameEs: 'Press de Pecho en Máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps],
      pattern: MovementPattern.horizontalPress,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.compound,
    ),

    // INCLINE PRESS
    ExerciseV2(
      id: 'incline_press_barbell_30',
      nameEs: 'Press Inclinado con Barra (30°)',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.shoulderAnterior, MuscleGroup.triceps],
      pattern: MovementPattern.inclinePress,
      angle: ExerciseAngle.incline30,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'incline_press_dumbbell_30',
      nameEs: 'Press Inclinado con Mancuernas (30°)',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.shoulderAnterior, MuscleGroup.triceps],
      pattern: MovementPattern.inclinePress,
      angle: ExerciseAngle.incline30,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'incline_press_barbell_45',
      nameEs: 'Press Inclinado con Barra (45°)',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.shoulderAnterior, MuscleGroup.triceps],
      pattern: MovementPattern.inclinePress,
      angle: ExerciseAngle.incline45,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'incline_press_dumbbell_45',
      nameEs: 'Press Inclinado con Mancuernas (45°)',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.shoulderAnterior, MuscleGroup.triceps],
      pattern: MovementPattern.inclinePress,
      angle: ExerciseAngle.incline45,
      complexity: ExerciseComplexity.compound,
    ),

    // DECLINE PRESS
    ExerciseV2(
      id: 'decline_press_barbell',
      nameEs: 'Press Declinado con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps],
      pattern: MovementPattern.declinePress,
      angle: ExerciseAngle.decline,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'dips_chest',
      nameEs: 'Fondos en Paralelas (Énfasis Pecho)',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulderAnterior],
      pattern: MovementPattern.declinePress,
      angle: ExerciseAngle.decline,
      complexity: ExerciseComplexity.compound,
    ),

    // CHEST ISOLATION
    ExerciseV2(
      id: 'fly_dumbbell_flat',
      nameEs: 'Aperturas con Mancuernas Plano',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'fly_dumbbell_incline',
      nameEs: 'Aperturas con Mancuernas Inclinado',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.incline30,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'fly_cable_flat',
      nameEs: 'Cruces en Polea Altura Media',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'fly_cable_low_to_high',
      nameEs: 'Cruces en Polea de Bajo a Alto',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.incline30,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'fly_cable_high_to_low',
      nameEs: 'Cruces en Polea de Alto a Bajo',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.decline,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'pec_deck',
      nameEs: 'Peck Deck (Máquina de Aperturas)',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'pushup_standard',
      nameEs: 'Flexiones de Pecho',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulderAnterior],
      pattern: MovementPattern.horizontalPress,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.compound,
    ),

    // ════════════════════════════════════════════════════════════════
    // ESPALDA (Dorsales)
    // ════════════════════════════════════════════════════════════════

    // VERTICAL PULL
    ExerciseV2(
      id: 'pullup_pronated',
      nameEs: 'Dominadas Agarre Prono',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.biceps],
      pattern: MovementPattern.verticalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'pullup_supinated',
      nameEs: 'Dominadas Agarre Supino',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.verticalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'pullup_neutral',
      nameEs: 'Dominadas Agarre Neutro',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.biceps],
      pattern: MovementPattern.verticalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'lat_pulldown_pronated',
      nameEs: 'Jalón al Pecho Agarre Prono',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.biceps],
      pattern: MovementPattern.verticalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'lat_pulldown_supinated',
      nameEs: 'Jalón al Pecho Agarre Supino',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.verticalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'lat_pulldown_neutral',
      nameEs: 'Jalón al Pecho Agarre Neutro',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.biceps],
      pattern: MovementPattern.verticalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // HORIZONTAL ROW
    ExerciseV2(
      id: 'barbell_row_pronated',
      nameEs: 'Remo con Barra Agarre Prono',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.upperBack],
      secondaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'barbell_row_supinated',
      nameEs: 'Remo con Barra Agarre Supino',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.biceps],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'dumbbell_row_unilateral',
      nameEs: 'Remo con Mancuerna a Una Mano',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.biceps],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'cable_row_seated_neutral',
      nameEs: 'Remo en Polea Sentado Agarre Neutro',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.upperBack],
      secondaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'cable_row_seated_wide',
      nameEs: 'Remo en Polea Sentado Agarre Ancho',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.upperBack],
      secondaryMuscles: [MuscleGroup.lats],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 't_bar_row',
      nameEs: 'Remo en T',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.upperBack],
      secondaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // DIAGONAL PULL (PULLOVER)
    ExerciseV2(
      id: 'pullover_dumbbell',
      nameEs: 'Pullover con Mancuerna',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.lats],
      secondaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.diagonalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'straight_arm_pushdown',
      nameEs: 'Pulldown con Brazos Rectos',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.lats],
      pattern: MovementPattern.diagonalPull,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // BACK ISOLATION
    ExerciseV2(
      id: 'face_pull',
      nameEs: 'Face Pull',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.shoulderPosterior],
      secondaryMuscles: [MuscleGroup.upperBack],
      pattern: MovementPattern.horizontalRow,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'rear_delt_fly_dumbbell',
      nameEs: 'Aperturas Posteriores con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.shoulderPosterior],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'rear_delt_fly_machine',
      nameEs: 'Aperturas Posteriores en Máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.shoulderPosterior],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // ════════════════════════════════════════════════════════════════
    // HOMBROS (Deltoides)
    // ════════════════════════════════════════════════════════════════

    // OVERHEAD PRESS
    ExerciseV2(
      id: 'overhead_press_barbell',
      nameEs: 'Press Militar con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.shoulderAnterior],
      secondaryMuscles: [MuscleGroup.shoulderLateral, MuscleGroup.triceps],
      pattern: MovementPattern.overheadPress,
      angle: ExerciseAngle.overhead,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'overhead_press_dumbbell',
      nameEs: 'Press Militar con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.shoulderAnterior],
      secondaryMuscles: [MuscleGroup.shoulderLateral, MuscleGroup.triceps],
      pattern: MovementPattern.overheadPress,
      angle: ExerciseAngle.overhead,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'overhead_press_seated_dumbbell',
      nameEs: 'Press Sentado con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.shoulderAnterior],
      secondaryMuscles: [MuscleGroup.shoulderLateral, MuscleGroup.triceps],
      pattern: MovementPattern.overheadPress,
      angle: ExerciseAngle.overhead,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'arnold_press',
      nameEs: 'Press Arnold',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.shoulderAnterior],
      secondaryMuscles: [MuscleGroup.shoulderLateral, MuscleGroup.triceps],
      pattern: MovementPattern.overheadPress,
      angle: ExerciseAngle.overhead,
      complexity: ExerciseComplexity.compound,
    ),

    // SHOULDER LATERAL
    ExerciseV2(
      id: 'lateral_raise_dumbbell',
      nameEs: 'Elevaciones Laterales con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.shoulderLateral],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'lateral_raise_cable',
      nameEs: 'Elevaciones Laterales en Polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.shoulderLateral],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'upright_row_barbell',
      nameEs: 'Remo al Cuello con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.shoulderLateral],
      secondaryMuscles: [MuscleGroup.traps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'upright_row_cable',
      nameEs: 'Remo al Cuello en Polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.shoulderLateral],
      secondaryMuscles: [MuscleGroup.traps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // SHOULDER ANTERIOR ISOLATION
    ExerciseV2(
      id: 'front_raise_dumbbell',
      nameEs: 'Elevaciones Frontales con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.shoulderAnterior],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'front_raise_barbell',
      nameEs: 'Elevaciones Frontales con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.shoulderAnterior],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // ════════════════════════════════════════════════════════════════
    // BRAZOS (Bíceps y Tríceps)
    // ════════════════════════════════════════════════════════════════

    // BICEPS
    ExerciseV2(
      id: 'barbell_curl',
      nameEs: 'Curl con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'dumbbell_curl',
      nameEs: 'Curl con Mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'hammer_curl',
      nameEs: 'Curl Martillo',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'preacher_curl',
      nameEs: 'Curl en Banco Scott',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'cable_curl',
      nameEs: 'Curl en Polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.biceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // TRICEPS
    ExerciseV2(
      id: 'close_grip_bench_press',
      nameEs: 'Press Banca Agarre Cerrado',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.triceps],
      secondaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.horizontalPress,
      angle: ExerciseAngle.flat,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'dips_triceps',
      nameEs: 'Fondos en Paralelas (Énfasis Tríceps)',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.triceps],
      secondaryMuscles: [MuscleGroup.chest],
      pattern: MovementPattern.declinePress,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'skull_crusher',
      nameEs: 'Extensiones Francesas (Skullcrushers)',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.triceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'overhead_extension_dumbbell',
      nameEs: 'Extensión de Tríceps Sobre la Cabeza con Mancuerna',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.triceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.overhead,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'rope_pushdown',
      nameEs: 'Extensión de Tríceps en Polea con Cuerda',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.triceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'overhead_extension_cable',
      nameEs: 'Extensión de Tríceps en Polea Sobre la Cabeza',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.triceps],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.overhead,
      complexity: ExerciseComplexity.accessory,
    ),

    // ════════════════════════════════════════════════════════════════
    // PIERNAS (Cuádriceps, Femorales, Glúteos, Pantorrillas)
    // ════════════════════════════════════════════════════════════════

    // QUADS - SQUAT PATTERN
    ExerciseV2(
      id: 'back_squat',
      nameEs: 'Sentadilla Trasera',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
      pattern: MovementPattern.squat,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'front_squat',
      nameEs: 'Sentadilla Frontal',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.squat,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'goblet_squat',
      nameEs: 'Sentadilla Goblet',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.squat,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'hack_squat',
      nameEs: 'Sentadilla Hack',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.squat,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'leg_press',
      nameEs: 'Prensa de Piernas',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
      pattern: MovementPattern.squat,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // QUADS - LUNGE PATTERN
    ExerciseV2(
      id: 'bulgarian_split_squat',
      nameEs: 'Sentadilla Búlgara',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.lunge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'walking_lunge',
      nameEs: 'Zancadas Caminando',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
      pattern: MovementPattern.lunge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'reverse_lunge',
      nameEs: 'Zancada Reversa',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.lunge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'step_up',
      nameEs: 'Step Up (Subida al Cajón)',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.quads],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.lunge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // QUADS - ISOLATION
    ExerciseV2(
      id: 'leg_extension',
      nameEs: 'Extensión de Cuádriceps',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.quads],
      pattern: MovementPattern.kneeExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // HAMSTRINGS - HINGE PATTERN
    ExerciseV2(
      id: 'romanian_deadlift',
      nameEs: 'Peso Muerto Rumano',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.hamstrings],
      secondaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hinge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'conventional_deadlift',
      nameEs: 'Peso Muerto Convencional',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.hamstrings],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.lowerBack],
      pattern: MovementPattern.hinge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'good_morning',
      nameEs: 'Buenos Días',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.hamstrings],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.lowerBack],
      pattern: MovementPattern.hinge,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // HAMSTRINGS - ISOLATION
    ExerciseV2(
      id: 'leg_curl_lying',
      nameEs: 'Curl Femoral Acostado',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.hamstrings],
      pattern: MovementPattern.kneeFlexion,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'leg_curl_seated',
      nameEs: 'Curl Femoral Sentado',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.hamstrings],
      pattern: MovementPattern.kneeFlexion,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'nordic_curl',
      nameEs: 'Nordic Curl (Curl Nórdico)',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.hamstrings],
      pattern: MovementPattern.kneeFlexion,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // GLUTES - HIP EXTENSION
    ExerciseV2(
      id: 'hip_thrust_barbell',
      nameEs: 'Hip Thrust con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.glutes],
      secondaryMuscles: [MuscleGroup.hamstrings],
      pattern: MovementPattern.hipExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'glute_bridge_barbell',
      nameEs: 'Puente de Glúteos con Barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.glutes],
      secondaryMuscles: [MuscleGroup.hamstrings],
      pattern: MovementPattern.hipExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),
    ExerciseV2(
      id: 'glute_bridge_single_leg',
      nameEs: 'Puente de Glúteos a Una Pierna',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hipExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'hip_thrust_machine',
      nameEs: 'Hip Thrust en Máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hipExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.compound,
    ),

    // GLUTES - HIP ABDUCTION
    ExerciseV2(
      id: 'hip_abduction_machine',
      nameEs: 'Abducción de Cadera en Máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hipAbduction,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'hip_abduction_band',
      nameEs: 'Abducción de Cadera con Banda',
      equipment: EquipmentType.band,
      primaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hipAbduction,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'cable_kickback',
      nameEs: 'Patada de Glúteo en Polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hipExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'band_kickback',
      nameEs: 'Patada de Glúteo con Banda',
      equipment: EquipmentType.band,
      primaryMuscles: [MuscleGroup.glutes],
      pattern: MovementPattern.hipExtension,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // CALVES
    ExerciseV2(
      id: 'calf_raise_standing',
      nameEs: 'Elevación de Talones de Pie',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.calves],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'calf_raise_seated',
      nameEs: 'Elevación de Talones Sentado',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.calves],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),

    // ════════════════════════════════════════════════════════════════
    // CORE (Abdominales)
    // ════════════════════════════════════════════════════════════════
    ExerciseV2(
      id: 'plank',
      nameEs: 'Plancha',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.abs],
      pattern: MovementPattern.antiRotation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'hanging_leg_raise',
      nameEs: 'Elevación de Piernas Colgado',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.abs],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'cable_crunch',
      nameEs: 'Crunch en Polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.abs],
      pattern: MovementPattern.isolation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
    ExerciseV2(
      id: 'ab_wheel_rollout',
      nameEs: 'Rollout con Rueda Abdominal',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.abs],
      pattern: MovementPattern.antiRotation,
      angle: ExerciseAngle.neutral,
      complexity: ExerciseComplexity.accessory,
    ),
  ];

  /// Retorna el catálogo completo
  static List<ExerciseV2> get all => List.unmodifiable(_exercises);

  /// Busca ejercicios por músculo primario
  static List<ExerciseV2> byMuscle(MuscleGroup muscle) {
    return _exercises.where((e) => e.primaryMuscles.contains(muscle)).toList();
  }

  /// Busca ejercicios por patrón de movimiento
  static List<ExerciseV2> byPattern(MovementPattern pattern) {
    return _exercises.where((e) => e.pattern == pattern).toList();
  }

  /// Busca ejercicios por equipamiento
  static List<ExerciseV2> byEquipment(EquipmentType equipment) {
    return _exercises.where((e) => e.equipment == equipment).toList();
  }

  /// Busca solo ejercicios compound
  static List<ExerciseV2> get compounds {
    return _exercises
        .where((e) => e.complexity == ExerciseComplexity.compound)
        .toList();
  }

  /// Busca solo ejercicios accessory
  static List<ExerciseV2> get accessories {
    return _exercises
        .where((e) => e.complexity == ExerciseComplexity.accessory)
        .toList();
  }

  /// Busca ejercicio por ID
  static ExerciseV2? byId(String id) {
    return _exercises.cast<ExerciseV2?>().firstWhere(
      (e) => e?.id == id,
      orElse: () => null,
    );
  }

  /// Busca alternativas (mismo patrón, diferente variante)
  static List<ExerciseV2> getAlternatives(ExerciseV2 exercise) {
    return _exercises
        .where(
          (e) =>
              e.pattern == exercise.pattern &&
              e.id != exercise.id &&
              e.primaryMuscles.first == exercise.primaryMuscles.first,
        )
        .toList();
  }

  /// Total de ejercicios en el catálogo
  static int get count => _exercises.length;
}
