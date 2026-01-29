import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';

class ExerciseEntry extends Equatable {
  final String code; // identificador único, estable
  final String name;
  final MuscleGroup muscleGroup;
  final List<String>
  equipment; // ej: ['barbell','dumbbell','machine','cable','bodyweight']
  final bool isCompound;

  const ExerciseEntry({
    required this.code,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.isCompound,
  });

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    final mgName = json['muscleGroup']?.toString() ?? 'fullBody';
    final mg = MuscleGroup.values.firstWhere(
      (e) => e.name == mgName,
      orElse: () => MuscleGroup.fullBody,
    );
    final equipment =
        (json['equipment'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    return ExerciseEntry(
      code: json['code']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      muscleGroup: mg,
      equipment: equipment,
      isCompound: json['isCompound'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'muscleGroup': muscleGroup.name,
    'equipment': equipment,
    'isCompound': isCompound,
  };

  @override
  List<Object?> get props => [code, muscleGroup, isCompound];
}

class ExerciseCatalog {
  final List<ExerciseEntry> entries;
  final Map<MuscleGroup, List<ExerciseEntry>> byMuscle;

  ExerciseCatalog._(this.entries, this.byMuscle);

  static ExerciseCatalog fromJsonString(String jsonString) {
    final raw = json.decode(jsonString);
    final list = (raw is List) ? raw : <dynamic>[];
    final entries =
        list
            .whereType<Map>()
            .map((m) => ExerciseEntry.fromJson(m.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.code.compareTo(b.code));
    final byMuscle = <MuscleGroup, List<ExerciseEntry>>{};
    for (final e in entries) {
      byMuscle.putIfAbsent(e.muscleGroup, () => <ExerciseEntry>[]).add(e);
    }
    for (final mg in byMuscle.keys) {
      byMuscle[mg]!.sort((a, b) {
        // Priorizar compuestos y luego por código
        if (a.isCompound != b.isCompound) {
          return a.isCompound ? -1 : 1;
        }
        return a.code.compareTo(b.code);
      });
    }
    return ExerciseCatalog._(entries, byMuscle);
  }

  static ExerciseCatalog fromFilePath(String path) {
    final file = File(path);
    final jsonString = file.readAsStringSync();
    return fromJsonString(jsonString);
  }

  /// Obtiene candidatos por músculo y equipo disponible
  List<ExerciseEntry> candidatesFor(
    MuscleGroup muscle,
    List<String> availableEquipment,
  ) {
    final list = byMuscle[muscle] ?? const <ExerciseEntry>[];
    if (availableEquipment.isEmpty) {
      // Solo bodyweight si no hay equipo
      return list.where((e) => e.equipment.contains('bodyweight')).toList();
    }
    return list
        .where((e) => e.equipment.any((eq) => availableEquipment.contains(eq)))
        .toList();
  }
}
