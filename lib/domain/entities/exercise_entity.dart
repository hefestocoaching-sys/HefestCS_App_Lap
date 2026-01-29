class ExerciseEntity {
  final String id;
  final String nameEs;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String movementPattern;
  final String equivalenceGroup;
  final List<String> equipment;

  ExerciseEntity({
    required this.id,
    required this.nameEs,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.movementPattern,
    required this.equivalenceGroup,
    required this.equipment,
  });

  factory ExerciseEntity.fromJson(Map<String, dynamic> json) {
    // V3: name.es
    String nameEs = '';
    if (json['name'] is Map) {
      nameEs = json['name']['es']?.toString() ?? '';
    } else {
      nameEs = json['name_es']?.toString() ?? json['nameEs']?.toString() ?? '';
    }

    // V3: primaryMuscles[] → tomar el primero
    String primary = '';
    if (json['primaryMuscles'] is List &&
        (json['primaryMuscles'] as List).isNotEmpty) {
      primary = (json['primaryMuscles'] as List).first.toString();
    } else if (json['muscles'] is Map) {
      primary = (json['muscles']['primary']?.toString() ?? '');
    } else {
      primary = json['primaryMuscle']?.toString() ?? '';
    }

    final muscleGroup =
        json['muscleGroup']?.toString() ??
        (json['muscles'] is Map
            ? json['muscles']['group']?.toString() ?? ''
            : '');

    final secondary = <String>[];
    // V3: secondaryMuscles[]
    if (json['secondaryMuscles'] is List) {
      secondary.addAll(
        (json['secondaryMuscles'] as List).whereType<dynamic>().map(
          (e) => e.toString(),
        ),
      );
    } else if (json['muscles'] is Map && json['muscles']['secondary'] is List) {
      secondary.addAll(
        (json['muscles']['secondary'] as List).whereType<dynamic>().map(
          (e) => e.toString(),
        ),
      );
    }

    String movementPattern = '';
    String target = '';
    if (json['movement'] is Map) {
      movementPattern = json['movement']['bodyPart']?.toString() ?? '';
      target = json['movement']['target']?.toString() ?? '';
    } else {
      movementPattern = json['movementPattern']?.toString() ?? '';
    }

    final equipmentStr = json['equipment']?.toString();
    final equipment = <String>[];
    if (equipmentStr != null && equipmentStr.isNotEmpty) {
      equipment.add(equipmentStr);
    } else if (json['equipment'] is List) {
      equipment.addAll(
        (json['equipment'] as List).whereType<dynamic>().map(
          (e) => e.toString(),
        ),
      );
    }

    // Derivar equivalenceGroup: V3 usa primaryMuscle + movementPattern
    final eqRaw = json['equivalenceGroup']?.toString() ?? '';
    final equivalenceGroup = eqRaw.isNotEmpty
        ? eqRaw
        : '${(primary.isNotEmpty ? primary : muscleGroup)}_${movementPattern.isNotEmpty ? movementPattern : target}'
              .toLowerCase();

    // Derivar movimiento si falta: usar target
    if (movementPattern.isEmpty) movementPattern = target;

    return ExerciseEntity(
      id: json['id']?.toString() ?? '',
      nameEs: nameEs,
      primaryMuscle: primary.isNotEmpty ? primary : muscleGroup,
      secondaryMuscles: secondary,
      movementPattern: movementPattern,
      equivalenceGroup: equivalenceGroup,
      equipment: equipment,
    );
  }

  bool isEquivalentTo(ExerciseEntity other) {
    return equivalenceGroup == other.equivalenceGroup &&
        movementPattern == other.movementPattern;
  }
}
