import 'dart:collection';

/// IMPORTANTE: Todas las keys en ExercisePreferencesByMuscle deben estar
/// normalizadas a claves canónicas del motor usando
/// ExercisePreferenceMuscleKeyMapper.toCanonicalKey() antes de almacenar.
/// Ver exercise_preferences_muscle_key_mapper.dart para detalles.
///
/// FLUJO DE NORMALIZACIÓN:
/// 1. UI/UI recolecta preferencias en keys variantes (ej: 'deltoide_anterior')
/// 2. Mapeo implícito en bucketForGroup ya usa persistMuscleKeys (deben ser canónicas)
/// 3. Persistencia en extra[TrainingExtraKeys.exercisePreferencesByMuscle]
///    almacena SOLO keys canónicas
/// 4. Consumidor (motor) consulta directamente con claves canónicas

class ExercisePreferenceBucket {
  final Set<String> frequent;
  final Set<String> preferred;
  final Set<String> avoid;

  const ExercisePreferenceBucket({
    this.frequent = const <String>{},
    this.preferred = const <String>{},
    this.avoid = const <String>{},
  });

  bool get hasAny =>
      frequent.isNotEmpty || preferred.isNotEmpty || avoid.isNotEmpty;

  Map<String, dynamic> toJson() {
    List<String> sorted(Set<String> values) => (values.toList()..sort());
    return <String, dynamic>{
      'frequent': sorted(frequent),
      'preferred': sorted(preferred),
      'avoid': sorted(avoid),
    };
  }

  factory ExercisePreferenceBucket.fromDynamic(dynamic raw) {
    if (raw is! Map) return const ExercisePreferenceBucket();
    Set<String> toSet(dynamic value) {
      if (value is! List) return <String>{};
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    return ExercisePreferenceBucket(
      frequent: toSet(raw['frequent']),
      preferred: toSet(raw['preferred']),
      avoid: toSet(raw['avoid']),
    );
  }

  ExercisePreferenceBucket copyWith({
    Set<String>? frequent,
    Set<String>? preferred,
    Set<String>? avoid,
  }) {
    return ExercisePreferenceBucket(
      frequent: frequent ?? this.frequent,
      preferred: preferred ?? this.preferred,
      avoid: avoid ?? this.avoid,
    );
  }
}

class ExercisePreferenceGroup {
  final String id;
  final String label;
  final List<String> catalogMuscleKeys;
  final List<String> persistMuscleKeys;

  const ExercisePreferenceGroup({
    required this.id,
    required this.label,
    required this.catalogMuscleKeys,
    required this.persistMuscleKeys,
  });
}

const List<ExercisePreferenceGroup> kExercisePreferenceGroups =
    <ExercisePreferenceGroup>[
      ExercisePreferenceGroup(
        id: 'pectoral',
        label: 'Pectoral',
        catalogMuscleKeys: <String>['pectorals'],
        persistMuscleKeys: <String>['pectorals'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'dorsal',
        label: 'Dorsal',
        catalogMuscleKeys: <String>['lats'],
        persistMuscleKeys: <String>['lats'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'espalda_alta',
        label: 'Espalda alta',
        catalogMuscleKeys: <String>['upper_back'],
        persistMuscleKeys: <String>['upper_back'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'cuadriceps',
        label: 'Cuadriceps',
        catalogMuscleKeys: <String>['quads'],
        persistMuscleKeys: <String>['quads'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'isquios',
        label: 'Isquios',
        catalogMuscleKeys: <String>['hamstrings'],
        persistMuscleKeys: <String>['hamstrings'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'gluteos',
        label: 'Gluteos',
        catalogMuscleKeys: <String>['glutes'],
        persistMuscleKeys: <String>['glutes'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'deltoides',
        label: 'Deltoides',
        catalogMuscleKeys: <String>[
          'delts_front',
          'delts_lateral',
          'delts_rear',
        ],
        persistMuscleKeys: <String>[
          'delts_front',
          'delts_lateral',
          'delts_rear',
        ], // Claves canónicas del motor
      ),
      ExercisePreferenceGroup(
        id: 'biceps',
        label: 'Biceps',
        catalogMuscleKeys: <String>['biceps'],
        persistMuscleKeys: <String>['biceps'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'triceps',
        label: 'Triceps',
        catalogMuscleKeys: <String>['triceps'],
        persistMuscleKeys: <String>['triceps'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'pantorrillas',
        label: 'Pantorrillas',
        catalogMuscleKeys: <String>['calves'],
        persistMuscleKeys: <String>['calves'], // Clave canónica del motor
      ),
      ExercisePreferenceGroup(
        id: 'abdomen',
        label: 'Abdomen',
        catalogMuscleKeys: <String>['abs'],
        persistMuscleKeys: <String>['abs'], // Clave canónica del motor
      ),
    ];

class ExercisePreferencesByMuscle {
  final Map<String, ExercisePreferenceBucket> byMuscle;

  const ExercisePreferencesByMuscle({
    this.byMuscle = const <String, ExercisePreferenceBucket>{},
  });

  bool get hasMinimumData => byMuscle.values.any((bucket) => bucket.hasAny);

  static ExercisePreferencesByMuscle fromDynamic(dynamic raw) {
    if (raw is! Map) return const ExercisePreferencesByMuscle();
    final mapped = <String, ExercisePreferenceBucket>{};
    raw.forEach((key, value) {
      final muscleKey = key.toString().trim();
      if (muscleKey.isEmpty) return;
      final bucket = ExercisePreferenceBucket.fromDynamic(value);
      if (bucket.hasAny) {
        mapped[muscleKey] = bucket;
      }
    });
    return ExercisePreferencesByMuscle(byMuscle: UnmodifiableMapView(mapped));
  }

  ExercisePreferenceBucket bucketForGroup(ExercisePreferenceGroup group) {
    final frequent = <String>{};
    final preferred = <String>{};
    final avoid = <String>{};

    for (final key in group.persistMuscleKeys) {
      final bucket = byMuscle[key];
      if (bucket == null) continue;
      frequent.addAll(bucket.frequent);
      preferred.addAll(bucket.preferred);
      avoid.addAll(bucket.avoid);
    }

    return ExercisePreferenceBucket(
      frequent: frequent,
      preferred: preferred,
      avoid: avoid,
    );
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    final entries = byMuscle.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      if (entry.value.hasAny) {
        out[entry.key] = entry.value.toJson();
      }
    }
    return out;
  }
}
