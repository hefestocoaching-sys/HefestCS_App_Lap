// Catálogo curado de ejercicios de gimnasio comunes
//
// Propósito:
// - Ofrecer un pool determinista y clínicamente válido de ejercicios
// - Permitir filtrado por equipamiento disponible y restricciones de movimiento
// - Garantizar nombres en español exclusivamente
// - Cubrir todos los grupos musculares principales con movimientos compuestos y accesorios
//

/// Tipos de equipamiento comúnmente disponible en gimnasios
enum EquipmentType {
  barbell('Barra olímpica'),
  dumbbell('Mancuernas'),
  machine('Máquina'),
  cable('Poleas'),
  bodyweight('Peso corporal');

  const EquipmentType(this.displayName);
  final String displayName;

  /// Parsea desde string persistido en profile.equipment
  static EquipmentType? fromString(String value) {
    return EquipmentType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => EquipmentType.bodyweight,
    );
  }
}

/// Patrones de movimiento fundamentales
/// Usado para filtrar ejercicios según movementRestrictions del perfil
enum MovementPattern {
  squat('Sentadilla'),
  hinge('Bisagra/Dominante de cadera'),
  push('Empuje'),
  pull('Tracción'),
  lunge('Zancada/Unilateral'),
  carry('Carga/Transporte'),
  rotation('Rotación');

  const MovementPattern(this.displayName);
  final String displayName;

  /// Parsea desde string persistido en profile.movementRestrictions
  static MovementPattern? fromString(String value) {
    final normalized = value.toLowerCase();
    for (final pattern in MovementPattern.values) {
      if (pattern.name == normalized) return pattern;
    }
    return null;
  }
}

/// Grupos musculares primarios
enum MuscleGroup {
  pectorales,
  dorsales,
  hombros,
  brazos,
  cuadriceps,
  isquiotibiales,
  gluteos,
  pantorrillas,
  abdominales,
  trapecios,
}

/// Clasificación de complejidad/carga
enum ExerciseComplexity {
  compound, // Ejercicios multiarticulares principales
  accessory, // Ejercicios accesorios/aislados
}

/// Ejercicio curado del catálogo
class CuratedExercise {
  const CuratedExercise({
    required this.id,
    required this.nameEs,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.patterns,
    required this.complexity,
  });

  final String id;
  final String nameEs;
  final EquipmentType equipment;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<MovementPattern> patterns;
  final ExerciseComplexity complexity;

  /// Verifica si el ejercicio está disponible dado el equipamiento del perfil
  bool isAvailableWith(Set<EquipmentType> availableEquipment) {
    return availableEquipment.contains(equipment);
  }

  /// Verifica si el ejercicio contiene algún patrón restringido
  bool hasRestrictedPattern(Set<MovementPattern> restrictedPatterns) {
    return patterns.any((p) => restrictedPatterns.contains(p));
  }

  /// Verifica si trabaja el músculo prioritario
  bool targetsMuscle(MuscleGroup muscle) {
    return primaryMuscles.contains(muscle);
  }
}

/// Catálogo completo de ejercicios curados
class ExerciseCatalog {
  ExerciseCatalog._();

  /// Pool de ejercicios curados, todos con nombres en español
  static final List<CuratedExercise> all = [
    // ========== COMPUESTOS BARRA ==========
    const CuratedExercise(
      id: 'bench_press_bb',
      nameEs: 'Press banca con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [MuscleGroup.hombros, MuscleGroup.brazos],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'squat_bb',
      nameEs: 'Sentadilla con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.cuadriceps],
      secondaryMuscles: [MuscleGroup.gluteos, MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.squat],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'deadlift_bb',
      nameEs: 'Peso muerto con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.isquiotibiales, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.dorsales, MuscleGroup.trapecios],
      patterns: [MovementPattern.hinge],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'row_bb',
      nameEs: 'Remo con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.dorsales],
      secondaryMuscles: [MuscleGroup.trapecios, MuscleGroup.brazos],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'ohp_bb',
      nameEs: 'Press militar con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.hombros],
      secondaryMuscles: [MuscleGroup.brazos, MuscleGroup.pectorales],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'rdl_bb',
      nameEs: 'Peso muerto rumano con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.isquiotibiales, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.dorsales],
      patterns: [MovementPattern.hinge],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'lunge_bb',
      nameEs: 'Zancada con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.cuadriceps, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.lunge],
      complexity: ExerciseComplexity.compound,
    ),

    // ========== COMPUESTOS MANCUERNAS ==========
    const CuratedExercise(
      id: 'bench_press_db',
      nameEs: 'Press banca con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [MuscleGroup.hombros, MuscleGroup.brazos],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'goblet_squat_db',
      nameEs: 'Sentadilla copa con mancuerna',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.cuadriceps],
      secondaryMuscles: [MuscleGroup.gluteos],
      patterns: [MovementPattern.squat],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'rdl_db',
      nameEs: 'Peso muerto rumano con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.isquiotibiales, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.dorsales],
      patterns: [MovementPattern.hinge],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'row_db',
      nameEs: 'Remo con mancuerna',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.dorsales],
      secondaryMuscles: [MuscleGroup.trapecios, MuscleGroup.brazos],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'ohp_db',
      nameEs: 'Press militar con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.hombros],
      secondaryMuscles: [MuscleGroup.brazos],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'lunge_db',
      nameEs: 'Zancada con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.cuadriceps, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.lunge],
      complexity: ExerciseComplexity.compound,
    ),

    // ========== MÁQUINAS COMPUESTAS ==========
    const CuratedExercise(
      id: 'leg_press_machine',
      nameEs: 'Prensa de pierna',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.cuadriceps, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'chest_press_machine',
      nameEs: 'Press de pecho en máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [MuscleGroup.hombros, MuscleGroup.brazos],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'lat_pulldown_machine',
      nameEs: 'Jalón al pecho',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.dorsales],
      secondaryMuscles: [MuscleGroup.brazos],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'seated_row_machine',
      nameEs: 'Remo sentado en máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.dorsales],
      secondaryMuscles: [MuscleGroup.trapecios, MuscleGroup.brazos],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'shoulder_press_machine',
      nameEs: 'Press de hombro en máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.hombros],
      secondaryMuscles: [MuscleGroup.brazos],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),

    // ========== ACCESORIOS MANCUERNAS ==========
    const CuratedExercise(
      id: 'lateral_raise_db',
      nameEs: 'Elevación lateral con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.hombros],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'bicep_curl_db',
      nameEs: 'Curl de bíceps con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.brazos],
      secondaryMuscles: [],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'tricep_extension_db',
      nameEs: 'Extensión de tríceps con mancuerna',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.brazos],
      secondaryMuscles: [],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'chest_fly_db',
      nameEs: 'Aperturas con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'rear_delt_fly_db',
      nameEs: 'Vuelos posteriores con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.hombros],
      secondaryMuscles: [MuscleGroup.dorsales],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.accessory,
    ),

    // ========== ACCESORIOS MÁQUINAS ==========
    const CuratedExercise(
      id: 'leg_extension_machine',
      nameEs: 'Extensión de cuádriceps',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.cuadriceps],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'leg_curl_machine',
      nameEs: 'Curl femoral',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.isquiotibiales],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'calf_raise_machine',
      nameEs: 'Elevación de talones en máquina',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.pantorrillas],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'pec_deck_machine',
      nameEs: 'Peck deck',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'back_extension_machine',
      nameEs: 'Extensión lumbar',
      equipment: EquipmentType.machine,
      primaryMuscles: [MuscleGroup.gluteos, MuscleGroup.isquiotibiales],
      secondaryMuscles: [MuscleGroup.dorsales],
      patterns: [MovementPattern.hinge],
      complexity: ExerciseComplexity.accessory,
    ),

    // ========== ACCESORIOS POLEAS ==========
    const CuratedExercise(
      id: 'tricep_pushdown_cable',
      nameEs: 'Extensión de tríceps en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.brazos],
      secondaryMuscles: [],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'face_pull_cable',
      nameEs: 'Face pull en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.hombros, MuscleGroup.trapecios],
      secondaryMuscles: [MuscleGroup.dorsales],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'chest_fly_cable',
      nameEs: 'Aperturas en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'lateral_raise_cable',
      nameEs: 'Elevación lateral en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.hombros],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'bicep_curl_cable',
      nameEs: 'Curl de bíceps en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.brazos],
      secondaryMuscles: [],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'wood_chop_cable',
      nameEs: 'Leñador en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.abdominales],
      secondaryMuscles: [MuscleGroup.hombros],
      patterns: [MovementPattern.rotation],
      complexity: ExerciseComplexity.accessory,
    ),

    // ========== PESO CORPORAL ==========
    const CuratedExercise(
      id: 'push_up_bw',
      nameEs: 'Flexiones',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.pectorales],
      secondaryMuscles: [MuscleGroup.hombros, MuscleGroup.brazos],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'pull_up_bw',
      nameEs: 'Dominadas',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.dorsales],
      secondaryMuscles: [MuscleGroup.brazos],
      patterns: [MovementPattern.pull],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'dip_bw',
      nameEs: 'Fondos en paralelas',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.pectorales, MuscleGroup.brazos],
      secondaryMuscles: [MuscleGroup.hombros],
      patterns: [MovementPattern.push],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'squat_bw',
      nameEs: 'Sentadilla sin peso',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.cuadriceps, MuscleGroup.gluteos],
      secondaryMuscles: [],
      patterns: [MovementPattern.squat],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'lunge_bw',
      nameEs: 'Zancada sin peso',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.cuadriceps, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.lunge],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'plank_bw',
      nameEs: 'Plancha',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.abdominales],
      secondaryMuscles: [MuscleGroup.hombros],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),

    // ========== ACCESORIOS ESPECÍFICOS GLÚTEO ==========
    const CuratedExercise(
      id: 'hip_thrust_bb',
      nameEs: 'Hip thrust con barra',
      equipment: EquipmentType.barbell,
      primaryMuscles: [MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.hinge],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'bulgarian_split_squat_db',
      nameEs: 'Sentadilla búlgara con mancuernas',
      equipment: EquipmentType.dumbbell,
      primaryMuscles: [MuscleGroup.cuadriceps, MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.lunge],
      complexity: ExerciseComplexity.compound,
    ),
    const CuratedExercise(
      id: 'glute_bridge_bw',
      nameEs: 'Puente de glúteo',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.gluteos],
      secondaryMuscles: [MuscleGroup.isquiotibiales],
      patterns: [MovementPattern.hinge],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'kickback_cable',
      nameEs: 'Patada de glúteo en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.gluteos],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),

    // ========== ACCESORIOS ABDOMINALES ==========
    const CuratedExercise(
      id: 'crunch_bw',
      nameEs: 'Abdominales crunch',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.abdominales],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'leg_raise_bw',
      nameEs: 'Elevación de piernas',
      equipment: EquipmentType.bodyweight,
      primaryMuscles: [MuscleGroup.abdominales],
      secondaryMuscles: [],
      patterns: [],
      complexity: ExerciseComplexity.accessory,
    ),
    const CuratedExercise(
      id: 'pallof_press_cable',
      nameEs: 'Pallof press en polea',
      equipment: EquipmentType.cable,
      primaryMuscles: [MuscleGroup.abdominales],
      secondaryMuscles: [],
      patterns: [MovementPattern.rotation],
      complexity: ExerciseComplexity.accessory,
    ),
  ];

  /// Filtra ejercicios por equipamiento disponible
  static List<CuratedExercise> filterByEquipment(Set<EquipmentType> available) {
    if (available.isEmpty) {
      // Fallback: solo peso corporal y mancuernas si no hay equipamiento especificado
      return all
          .where(
            (e) =>
                e.equipment == EquipmentType.bodyweight ||
                e.equipment == EquipmentType.dumbbell,
          )
          .toList();
    }
    return all.where((e) => e.isAvailableWith(available)).toList();
  }

  /// Filtra ejercicios excluyendo patrones restringidos
  static List<CuratedExercise> filterByRestrictions(
    List<CuratedExercise> exercises,
    Set<MovementPattern> restricted,
  ) {
    if (restricted.isEmpty) return exercises;
    return exercises.where((e) => !e.hasRestrictedPattern(restricted)).toList();
  }

  /// Filtra ejercicios que trabajan el músculo objetivo
  static List<CuratedExercise> filterByMuscle(
    List<CuratedExercise> exercises,
    MuscleGroup muscle,
  ) {
    return exercises.where((e) => e.targetsMuscle(muscle)).toList();
  }

  /// Filtra ejercicios por complejidad
  static List<CuratedExercise> filterByComplexity(
    List<CuratedExercise> exercises,
    ExerciseComplexity complexity,
  ) {
    return exercises.where((e) => e.complexity == complexity).toList();
  }

  /// Método helper para obtener ejercicios compuestos disponibles
  static List<CuratedExercise> getCompounds({
    required Set<EquipmentType> availableEquipment,
    Set<MovementPattern> restrictedPatterns = const {},
  }) {
    final byEquipment = filterByEquipment(availableEquipment);
    final byRestrictions = filterByRestrictions(
      byEquipment,
      restrictedPatterns,
    );
    return filterByComplexity(byRestrictions, ExerciseComplexity.compound);
  }

  /// Método helper para obtener ejercicios accesorios disponibles
  static List<CuratedExercise> getAccessories({
    required Set<EquipmentType> availableEquipment,
    Set<MovementPattern> restrictedPatterns = const {},
  }) {
    final byEquipment = filterByEquipment(availableEquipment);
    final byRestrictions = filterByRestrictions(
      byEquipment,
      restrictedPatterns,
    );
    return filterByComplexity(byRestrictions, ExerciseComplexity.accessory);
  }
}
