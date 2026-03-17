import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

class Landmarks {
  final int vme;
  final int vop;
  final int vmr;

  const Landmarks({required this.vme, required this.vop, required this.vmr});

  Map<String, int> toMap() => {'vme': vme, 'vop': vop, 'vmr': vmr};

  factory Landmarks.fromMap(Map<String, dynamic> map) {
    return Landmarks(
      vme: (map['vme'] as num?)?.toInt() ?? 0,
      vop: (map['vop'] as num?)?.toInt() ?? 0,
      vmr: (map['vmr'] as num?)?.toInt() ?? 0,
    );
  }
}

class LandmarkEngine {
  static Map<MuscleGroup, Landmarks> calculateFromProfile(
    TrainingProfile profile,
  ) {
    final targetByMuscle = _resolveTargetVolumeByMuscle(profile);
    final out = <MuscleGroup, Landmarks>{};

    for (final entry in targetByMuscle.entries) {
      final muscle = muscleGroupFromString(entry.key);
      if (muscle == null) continue;

      final vop = entry.value.clamp(0, 999);
      final vme = _resolveVme(vop);
      final vmr = _resolveVmr(vop);

      out[muscle] = Landmarks(vme: vme, vop: vop, vmr: vmr);
    }

    return out;
  }

  static Map<String, Map<String, int>> serializeByCanonicalKey(
    Map<MuscleGroup, Landmarks> landmarksByMuscle,
  ) {
    return {
      for (final entry in landmarksByMuscle.entries)
        normalizeMuscleKey(entry.key.canonicalKey): entry.value.toMap(),
    };
  }

  static Map<String, Landmarks> parseByCanonicalKey(dynamic raw) {
    final out = <String, Landmarks>{};
    if (raw is! Map) return out;

    raw.forEach((key, value) {
      if (value is Map) {
        final typed = value.map(
          (innerKey, innerValue) => MapEntry(innerKey.toString(), innerValue),
        );
        out[normalizeMuscleKey(key.toString())] = Landmarks.fromMap(typed);
      }
    });

    return out;
  }

  static Map<String, int> extractVopByCanonicalKey(dynamic raw) {
    final parsed = parseByCanonicalKey(raw);
    return {
      for (final entry in parsed.entries)
        normalizeMuscleKey(entry.key): entry.value.vop,
    };
  }

  static Map<String, int> _resolveTargetVolumeByMuscle(
    TrainingProfile profile,
  ) {
    final source = <String, int>{};

    final targetSetsByMuscle = profile.extra['targetSetsByMuscle'];
    if (targetSetsByMuscle is Map) {
      targetSetsByMuscle.forEach((key, value) {
        if (value is num) {
          source[normalizeMuscleKey(key.toString())] = value.round();
        }
      });
    }

    if (source.isEmpty) {
      for (final entry in profile.baseVolumePerMuscle.entries) {
        source[normalizeMuscleKey(entry.key)] = entry.value;
      }
    }

    final prioritized = [
      ...profile.priorityMusclesPrimary,
      ...profile.priorityMusclesSecondary,
      ...profile.priorityMusclesTertiary,
    ];

    for (final rawMuscle in prioritized) {
      final muscle = normalizeMuscleKey(rawMuscle);
      source.putIfAbsent(muscle, () => 8);
    }

    return source;
  }

  static int _resolveVme(int vop) {
    if (vop <= 0) return 0;
    return (vop * 0.6).round().clamp(1, 999);
  }

  static int _resolveVmr(int vop) {
    if (vop <= 0) return 0;
    final vmr = (vop * 1.4).round();
    return vmr < vop ? vop : vmr;
  }
}
