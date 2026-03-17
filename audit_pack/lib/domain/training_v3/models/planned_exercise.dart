import 'package:uuid/uuid.dart';

class PlannedExercise {
  final String id;
  final String exerciseId;
  final String name;
  final String muscleKey;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String? slotLabel;
  final String? blockLabel;
  final String? pairGroupId;
  final bool isMainLift;

  final List<SetPrescription> sets;

  final IntensificationRule? intensification;

  PlannedExercise({
    String? id,
    required this.exerciseId,
    required this.name,
    required this.muscleKey,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    this.slotLabel,
    this.blockLabel,
    this.pairGroupId,
    this.isMainLift = false,
    required this.sets,
    this.intensification,
  }) : id = id ?? const Uuid().v4(),
       primaryMuscle = (primaryMuscle == null || primaryMuscle.isEmpty)
           ? muscleKey
           : primaryMuscle,
       secondaryMuscles = secondaryMuscles ?? const <String>[];

  PlannedExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? muscleKey,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? slotLabel,
    bool clearSlotLabel = false,
    String? blockLabel,
    bool clearBlockLabel = false,
    String? pairGroupId,
    bool clearPairGroupId = false,
    bool? isMainLift,
    List<SetPrescription>? sets,
    IntensificationRule? intensification,
    bool clearIntensification = false,
  }) {
    return PlannedExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      muscleKey: muscleKey ?? this.muscleKey,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      slotLabel: clearSlotLabel ? null : (slotLabel ?? this.slotLabel),
      blockLabel: clearBlockLabel ? null : (blockLabel ?? this.blockLabel),
      pairGroupId: clearPairGroupId ? null : (pairGroupId ?? this.pairGroupId),
      isMainLift: isMainLift ?? this.isMainLift,
      sets: sets ?? this.sets,
      intensification: clearIntensification
          ? null
          : (intensification ?? this.intensification),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'muscleKey': muscleKey,
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
      'slotLabel': slotLabel,
      'blockLabel': blockLabel,
      'pairGroupId': pairGroupId,
      'isMainLift': isMainLift,
      'sets': sets.map((set) => set.toMap()).toList(),
      'intensification': intensification?.toMap(),
    };
  }

  factory PlannedExercise.fromMap(Map<String, dynamic> map) {
    final rawSets = map['sets'];
    return PlannedExercise(
      id: map['id'] as String?,
      exerciseId: map['exerciseId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      muscleKey: map['muscleKey'] as String? ?? '',
      primaryMuscle:
          map['primaryMuscle'] as String? ?? map['muscleKey'] as String? ?? '',
      secondaryMuscles: map['secondaryMuscles'] is List
          ? (map['secondaryMuscles'] as List)
                .map((m) => m?.toString() ?? '')
                .where((m) => m.isNotEmpty)
                .toList()
          : const <String>[],
      slotLabel: map['slotLabel'] as String?,
      blockLabel: map['blockLabel'] as String?,
      pairGroupId: map['pairGroupId'] as String?,
      isMainLift: map['isMainLift'] == true,
      sets: rawSets is List
          ? rawSets
                .whereType<Map>()
                .map(
                  (set) =>
                      SetPrescription.fromMap(Map<String, dynamic>.from(set)),
                )
                .toList()
          : const <SetPrescription>[],
      intensification: map['intensification'] is Map
          ? IntensificationRule.fromMap(
              Map<String, dynamic>.from(map['intensification'] as Map),
            )
          : null,
    );
  }
}

class SetPrescription {
  final int repsMin;
  final int repsMax;
  final int rir;

  const SetPrescription({
    required this.repsMin,
    required this.repsMax,
    required this.rir,
  });

  Map<String, dynamic> toMap() {
    return {'repsMin': repsMin, 'repsMax': repsMax, 'rir': rir};
  }

  factory SetPrescription.fromMap(Map<String, dynamic> map) {
    return SetPrescription(
      repsMin: map['repsMin'] as int? ?? 0,
      repsMax: map['repsMax'] as int? ?? 0,
      rir: map['rir'] as int? ?? 0,
    );
  }
}

enum IntensificationType { restPause, dropSet, myoReps, cluster, isometricHold }

class IntensificationRule {
  final IntensificationType type;
  final bool applyToLastSetOnly;
  final bool applyToLastTwoSets;

  const IntensificationRule({
    required this.type,
    this.applyToLastSetOnly = true,
    this.applyToLastTwoSets = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'applyToLastSetOnly': applyToLastSetOnly,
      'applyToLastTwoSets': applyToLastTwoSets,
    };
  }

  factory IntensificationRule.fromMap(Map<String, dynamic> map) {
    final typeName =
        map['type']?.toString() ?? IntensificationType.restPause.name;
    final type = IntensificationType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => IntensificationType.restPause,
    );
    return IntensificationRule(
      type: type,
      applyToLastSetOnly: map['applyToLastSetOnly'] != false,
      applyToLastTwoSets: map['applyToLastTwoSets'] == true,
    );
  }
}
