import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

class ExerciseCatalogV3Media {
  final String? gifPath;

  const ExerciseCatalogV3Media({required this.gifPath});

  factory ExerciseCatalogV3Media.fromMap(Map<String, dynamic> map) {
    final raw = map['gifPath']?.toString();
    final normalized = (raw == null || raw.trim().isEmpty) ? null : raw.trim();
    return ExerciseCatalogV3Media(gifPath: normalized);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'gifPath': gifPath};
  }
}

class ExerciseCatalogV3Entry {
  final String id;
  final String name;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> tertiaryMuscles;
  final Map<String, double> stimulusContribution;
  final String movementPattern;
  final List<String> equipment;
  final String category;
  final bool unilateral;
  final Map<String, bool> allowedIntensityZones;
  final Map<String, List<int>> recommendedRepRanges;
  final Map<String, List<int>> recommendedRirRanges;
  final String equivalenceGroup;
  final String muscleSize;
  final String loadCategory;
  final String role;
  final int fatigueScore;
  final int stimulusScore;
  final String muscleLength;
  final String pairingClass;
  final List<String> slotRoles;
  final String heavyRole;
  final String aEligibility;
  final bool secondaryHeavyEligibility;
  final int exerciseOrderClass;
  final List<String> conflictPatterns;
  final String rotationGroup;
  final String angleTag;
  final int variantTier;
  final bool canPromoteToHeavyNextBlock;
  final bool canDemoteToMediumNextBlock;
  final ExerciseCatalogV3Media? media;

  const ExerciseCatalogV3Entry({
    required this.id,
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.tertiaryMuscles,
    required this.stimulusContribution,
    required this.movementPattern,
    required this.equipment,
    required this.category,
    required this.unilateral,
    required this.allowedIntensityZones,
    required this.recommendedRepRanges,
    required this.recommendedRirRanges,
    required this.equivalenceGroup,
    required this.muscleSize,
    required this.loadCategory,
    required this.role,
    required this.fatigueScore,
    required this.stimulusScore,
    required this.muscleLength,
    required this.pairingClass,
    required this.slotRoles,
    required this.heavyRole,
    required this.aEligibility,
    required this.secondaryHeavyEligibility,
    required this.exerciseOrderClass,
    required this.conflictPatterns,
    required this.rotationGroup,
    required this.angleTag,
    required this.variantTier,
    required this.canPromoteToHeavyNextBlock,
    required this.canDemoteToMediumNextBlock,
    required this.media,
  });

  List<String> get allowedZones => allowedIntensityZones.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  static String _requiredString(Map<String, dynamic> map, String key) {
    final raw = map[key];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    throw FormatException('Missing required string field "$key"');
  }

  static String _extractName(Map<String, dynamic> map) {
    final raw = map['name'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is Map) {
      final es = raw['es']?.toString().trim() ?? '';
      final en = raw['en']?.toString().trim() ?? '';
      if (es.isNotEmpty) return es;
      if (en.isNotEmpty) return en;
    }
    throw const FormatException('Missing required field "name"');
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) return const <String, bool>{};
    bool toBool(dynamic raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      final normalized = raw?.toString().trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'si';
    }

    return <String, bool>{
      'heavy': toBool(value['heavy']),
      'medium': toBool(value['medium']),
      'light': toBool(value['light']),
    };
  }

  static Map<String, double> _doubleMap(dynamic value) {
    if (value is! Map) return const <String, double>{};
    final out = <String, double>{};
    value.forEach((key, raw) {
      final k = key?.toString().trim() ?? '';
      if (k.isEmpty) return;
      if (raw is num) {
        out[k] = raw.toDouble();
      } else {
        final parsed = double.tryParse(raw?.toString() ?? '');
        if (parsed != null) out[k] = parsed;
      }
    });
    return out;
  }

  static Map<String, List<int>> _intRangeMap(dynamic value) {
    if (value is! Map) return const <String, List<int>>{};
    final out = <String, List<int>>{};
    value.forEach((key, raw) {
      final zone = key?.toString().trim().toLowerCase() ?? '';
      if (zone.isEmpty || raw is! List || raw.length < 2) return;
      final min = _toInt(raw[0], 0);
      final max = _toInt(raw[1], 0);
      if (min <= 0 || max <= 0 || min > max) return;
      out[zone] = <int>[min, max];
    });
    return out;
  }

  static int _toInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static bool _toBool(dynamic raw, {required bool fallback}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final normalized = raw?.toString().trim().toLowerCase();
    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'si') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }

  static String _normalizeMuscle(String raw) {
    final normalized = muscle_registry.normalize(raw);
    if (normalized != null) return normalized;
    throw FormatException('Unknown muscle key "$raw" in catalog entry');
  }

  factory ExerciseCatalogV3Entry.fromMap(Map<String, dynamic> map) {
    final id = _requiredString(map, 'id');
    final name = _extractName(map);
    final primaryRaw = _stringList(map['primaryMuscles']);
    if (primaryRaw.isEmpty) {
      throw FormatException('Entry "$id" missing primaryMuscles');
    }

    final primary = primaryRaw.map(_normalizeMuscle).toList(growable: false);
    final secondary = _stringList(
      map['secondaryMuscles'],
    ).map(_normalizeMuscle).toList(growable: false);
    final tertiary = _stringList(
      map['tertiaryMuscles'],
    ).map(_normalizeMuscle).toList(growable: false);

    final movementPattern = _requiredString(
      map,
      'movementPattern',
    ).toLowerCase();
    final category = _requiredString(map, 'category').toLowerCase();
    final allowedZones = _boolMap(map['allowedIntensityZones']);
    if (allowedZones.isEmpty) {
      throw FormatException('Entry "$id" missing allowedIntensityZones');
    }

    final slotRoles = _stringList(
      map['slotRoles'],
    ).map((role) => role.toUpperCase()).toList(growable: false);
    if (slotRoles.isEmpty) {
      throw FormatException('Entry "$id" missing slotRoles');
    }

    final exerciseOrderClass = _toInt(map['exerciseOrderClass'], -1);
    if (exerciseOrderClass <= 0) {
      throw FormatException('Entry "$id" has invalid exerciseOrderClass');
    }

    final repRanges = _intRangeMap(map['recommendedRepRanges']);
    final rirRanges = _intRangeMap(map['recommendedRirRanges']);

    return ExerciseCatalogV3Entry(
      id: id,
      name: name,
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      tertiaryMuscles: tertiary,
      stimulusContribution: _doubleMap(map['stimulusContribution']),
      movementPattern: movementPattern,
      equipment: _stringList(
        map['equipment'],
      ).map((equipment) => equipment.toLowerCase()).toList(growable: false),
      category: category,
      unilateral: _toBool(map['unilateral'], fallback: false),
      allowedIntensityZones: allowedZones,
      recommendedRepRanges: repRanges,
      recommendedRirRanges: rirRanges,
      equivalenceGroup: _requiredString(map, 'equivalenceGroup'),
      muscleSize: (map['muscleSize']?.toString().trim().toLowerCase() ?? ''),
      loadCategory:
          (map['loadCategory']?.toString().trim().toLowerCase() ?? ''),
      role: (map['role']?.toString().trim().toLowerCase() ?? ''),
      fatigueScore: _toInt(map['fatigueScore'], 0),
      stimulusScore: _toInt(map['stimulusScore'], 0),
      muscleLength:
          (map['muscleLength']?.toString().trim().toLowerCase() ?? ''),
      pairingClass:
          (map['pairingClass']?.toString().trim().toLowerCase() ?? ''),
      slotRoles: slotRoles,
      heavyRole: _requiredString(map, 'heavyRole').toLowerCase(),
      aEligibility: _requiredString(map, 'aEligibility').toLowerCase(),
      secondaryHeavyEligibility: _toBool(
        map['secondaryHeavyEligibility'],
        fallback: false,
      ),
      exerciseOrderClass: exerciseOrderClass,
      conflictPatterns: _stringList(
        map['conflictPatterns'],
      ).map((pattern) => pattern.toLowerCase()).toList(growable: false),
      rotationGroup: _requiredString(map, 'rotationGroup').toLowerCase(),
      angleTag: (map['angleTag']?.toString().trim().toLowerCase() ?? ''),
      variantTier: _toInt(map['variantTier'], 1),
      canPromoteToHeavyNextBlock: _toBool(
        map['canPromoteToHeavyNextBlock'],
        fallback: false,
      ),
      canDemoteToMediumNextBlock: _toBool(
        map['canDemoteToMediumNextBlock'],
        fallback: false,
      ),
      media: map['media'] is Map<String, dynamic>
          ? ExerciseCatalogV3Media.fromMap(map['media'] as Map<String, dynamic>)
          : (map['media'] is Map
                ? ExerciseCatalogV3Media.fromMap(
                    Map<String, dynamic>.from(map['media'] as Map),
                  )
                : null),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'tertiaryMuscles': tertiaryMuscles,
      'stimulusContribution': stimulusContribution,
      'movementPattern': movementPattern,
      'equipment': equipment,
      'category': category,
      'unilateral': unilateral,
      'allowedIntensityZones': allowedIntensityZones,
      'recommendedRepRanges': recommendedRepRanges,
      'recommendedRirRanges': recommendedRirRanges,
      'equivalenceGroup': equivalenceGroup,
      'muscleSize': muscleSize,
      'loadCategory': loadCategory,
      'role': role,
      'fatigueScore': fatigueScore,
      'stimulusScore': stimulusScore,
      'muscleLength': muscleLength,
      'pairingClass': pairingClass,
      'slotRoles': slotRoles,
      'heavyRole': heavyRole,
      'aEligibility': aEligibility,
      'secondaryHeavyEligibility': secondaryHeavyEligibility,
      'exerciseOrderClass': exerciseOrderClass,
      'conflictPatterns': conflictPatterns,
      'rotationGroup': rotationGroup,
      'angleTag': angleTag,
      'variantTier': variantTier,
      'canPromoteToHeavyNextBlock': canPromoteToHeavyNextBlock,
      'canDemoteToMediumNextBlock': canDemoteToMediumNextBlock,
      'media': media?.toMap(),
    };
  }
}
