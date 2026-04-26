import 'package:hcs_app_lap/core/registry/muscle_registry.dart' as registry;

class Exercise {
  final String id;
  final String externalId;
  final String name;

  // Compatibilidad legacy (aún usado por UI/otros módulos)
  final String muscleKey;

  final String equipment;
  final String difficulty;
  final String gifUrl;

  // V3 (CANÓNICO)
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> tertiaryMuscles;
  final Map<String, double> stimulusContribution;

  // V3 metadata tipada para selector/intensidad determinísticos.
  final String movementPattern;
  final String loadCategory;
  final int fatigueScore;
  final int stimulusScore;
  final Map<String, bool> allowedIntensityZones;
  final String equivalenceGroup;

  Exercise({
    required this.id,
    required this.externalId,
    required this.name,
    required this.muscleKey,
    this.equipment = '',
    this.difficulty = '',
    this.gifUrl = '',
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    List<String>? tertiaryMuscles,
    Map<String, double>? stimulusContribution,
    this.movementPattern = 'unknown',
    this.loadCategory = 'light',
    this.fatigueScore = 5,
    this.stimulusScore = 1,
    Map<String, bool>? allowedIntensityZones,
    this.equivalenceGroup = '',
  }) : primaryMuscles = primaryMuscles ?? const <String>[],
       secondaryMuscles = secondaryMuscles ?? const <String>[],
       tertiaryMuscles = tertiaryMuscles ?? const <String>[],
       stimulusContribution = stimulusContribution ?? const <String, double>{},
       allowedIntensityZones =
           allowedIntensityZones ??
           const <String, bool>{
             'heavy': false,
             'medium': false,
             'light': false,
           };

  bool matchesMuscle(String key) {
    return primaryMuscles.contains(key) ||
        secondaryMuscles.contains(key) ||
        tertiaryMuscles.contains(key) ||
        stimulusContribution.containsKey(key) ||
        muscleKey == key; // fallback legacy
  }

  static String _s(dynamic v) => (v is String) ? v : '';
  static List<String> _sl(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static Map<String, double> _sdm(dynamic v) {
    if (v is Map) {
      final out = <String, double>{};
      v.forEach((k, val) {
        final kk = k?.toString() ?? '';
        if (kk.isEmpty) return;
        if (val is num) {
          out[kk] = val.toDouble();
        } else {
          final p = double.tryParse(val?.toString() ?? '');
          if (p != null) out[kk] = p;
        }
      });
      return out;
    }
    return const <String, double>{};
  }

  static Map<String, bool> _sbm(dynamic v) {
    const restrictive = <String, bool>{
      'heavy': false,
      'medium': false,
      'light': false,
    };
    if (v is! Map) return restrictive;

    bool toBool(dynamic raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      final s = raw?.toString().trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'si';
    }

    return <String, bool>{
      'heavy': toBool(v['heavy']),
      'medium': toBool(v['medium']),
      'light': toBool(v['light']),
    };
  }

  static int _toInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    // Detectar esquema v3
    final isV3 = map.containsKey('primaryMuscles') && map['id'] is String;

    if (isV3) {
      final id = _s(map['id']);

      // name V3: {es,en} o String
      String name = '';
      final rawName = map['name'];
      if (rawName is Map) {
        name = rawName['es']?.toString() ?? '';
      } else {
        name = _s(rawName);
      }

      // equipment V3: List<String> o String legacy
      String equipment = '';
      final rawEq = map['equipment'];
      if (rawEq is List && rawEq.isNotEmpty) {
        equipment = rawEq.first?.toString() ?? '';
      } else {
        equipment = _s(rawEq);
      }

      final movementPattern = _s(map['movementPattern']);
      final loadCategory = _s(map['loadCategory']).toLowerCase();
      final fatigueScore = _toInt(map['fatigueScore'], 5);
      final stimulusScore = _toInt(map['stimulusScore'], 1);
      final allowedZones = _sbm(map['allowedIntensityZones']);
      final equivalenceGroup = _s(map['equivalenceGroup']);

      // Función para normalizar listas de músculos
      List<String> normList(List<String> xs) {
        final out = <String>[];
        for (final x in xs) {
          final n = registry.normalize(x) ?? x.toLowerCase();
          out.add(n);
        }
        return out;
      }

      final primary = normList(_sl(map['primaryMuscles']));
      final secondary = normList(_sl(map['secondaryMuscles']));
      final tertiary = normList(_sl(map['tertiaryMuscles']));

      final contribRaw = _sdm(map['stimulusContribution']);
      final contrib = <String, double>{};
      contribRaw.forEach((k, v) {
        final nk = registry.normalize(k) ?? k.toLowerCase();
        contrib[nk] = v;
      });

      final muscleKey = primary.isNotEmpty ? primary.first : '';

      return Exercise(
        id: id,
        externalId: id,
        name: name,
        muscleKey: muscleKey,
        equipment: equipment,
        difficulty: movementPattern,
        primaryMuscles: primary,
        secondaryMuscles: secondary,
        tertiaryMuscles: tertiary,
        stimulusContribution: contrib,
        movementPattern: movementPattern,
        loadCategory: loadCategory.isEmpty ? 'light' : loadCategory,
        fatigueScore: fatigueScore,
        stimulusScore: stimulusScore,
        allowedIntensityZones: allowedZones,
        equivalenceGroup: equivalenceGroup,
      );
    }

    // Legacy (catálogo antiguo)
    final id = _s(map['id']).isNotEmpty ? _s(map['id']) : _s(map['exerciseId']);
    final externalIdRaw = map['externalId'] ?? map['id'] ?? map['exerciseId'];
    final externalId = _s(externalIdRaw);

    String name;
    final nameRaw = map['name'];
    if (nameRaw is Map) {
      name = _s(nameRaw['es']).isNotEmpty
          ? _s(nameRaw['es'])
          : _s(nameRaw['en']);
    } else {
      name = _s(nameRaw);
    }

    final muscleKey = _s(map['muscleKey']).isNotEmpty
        ? _s(map['muscleKey'])
        : _s(map['group']);
    final equipment = _s(map['equipment']);

    String difficulty = _s(map['difficulty']);
    if (difficulty.isEmpty) {
      final movement = map['movement'];
      if (movement is Map) difficulty = _s(movement['pattern']);
    }

    String gifUrl = _s(map['gifUrl']);
    if (gifUrl.isEmpty) {
      final media = map['media'];
      if (media is Map) gifUrl = _s(media['gifUrl']);
    }

    final pm = muscleKey.isNotEmpty ? <String>[muscleKey] : const <String>[];

    return Exercise(
      id: id.isNotEmpty ? id : externalId,
      externalId: externalId,
      name: name,
      muscleKey: muscleKey,
      equipment: equipment,
      difficulty: difficulty,
      gifUrl: gifUrl,
      primaryMuscles: pm,
      secondaryMuscles: const <String>[],
      tertiaryMuscles: const <String>[],
      stimulusContribution: const <String, double>{},
      movementPattern: difficulty,
      allowedIntensityZones: const <String, bool>{
        'heavy': false,
        'medium': false,
        'light': false,
      },
      equivalenceGroup: id.isNotEmpty ? 'self:$id' : 'self:unknown',
    );
  }

  bool allowsZone(String zone) {
    final z = zone.trim().toLowerCase();
    return allowedIntensityZones[z] == true;
  }
}
