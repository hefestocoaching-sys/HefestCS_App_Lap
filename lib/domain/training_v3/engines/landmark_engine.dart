import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/training/models/supported_muscles.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_volume_landmarks_ssot.dart';

class Landmarks {
  final int vme;
  final int vop;
  final int vmr;
  final int? vmrExtended;

  const Landmarks({
    required this.vme,
    required this.vop,
    required this.vmr,
    this.vmrExtended,
  });

  Map<String, int> toMap() {
    final out = <String, int>{'vme': vme, 'vop': vop, 'vmr': vmr};
    if (vmrExtended != null) {
      out['vmrExtended'] = vmrExtended!;
    }
    return out;
  }

  factory Landmarks.fromMap(Map<String, dynamic> map) {
    return Landmarks(
      vme: (map['vme'] as num?)?.toInt() ?? 0,
      vop: (map['vop'] as num?)?.toInt() ?? 0,
      vmr: (map['vmr'] as num?)?.toInt() ?? 0,
      vmrExtended: (map['vmrExtended'] as num?)?.toInt(),
    );
  }
}

class LandmarkEngine {
  static Map<MuscleGroup, Landmarks> calculateFromProfile(
    TrainingProfile profile,
  ) {
    final persisted = _parsePersistedLandmarks(
      profile.extra[TrainingExtraKeys.muscleLandmarks],
    );
    if (persisted.isNotEmpty) {
      return persisted;
    }

    final level = _resolveLevel(profile);
    final adjustments = GlobalVolumeAdjustments(
      deltaVme:
          _readDouble(profile.extra[TrainingExtraKeys.deltaVmeGlobal]) ??
          _readDouble(profile.extra[TrainingExtraKeys.vmeAdjustTotal]) ??
          0,
      deltaVmr:
          _readDouble(profile.extra[TrainingExtraKeys.deltaVmrGlobal]) ??
          _readDouble(profile.extra[TrainingExtraKeys.vmrAdjustTotal]) ??
          0,
    );
    final out = <MuscleGroup, Landmarks>{};

    for (final muscleKey in SupportedMuscles.keys) {
      final muscle = muscleGroupFromString(muscleKey);
      if (muscle == null) continue;

      final rangeByLevel = MuscleVolumeLandmarksSsot.table[muscleKey];
      final base = rangeByLevel?[level];
      if (base == null) continue;

      final finalLandmarks = computeFinalMuscleLandmarks(
        base: base,
        adjustments: adjustments,
        level: level,
      );

      out[muscle] = Landmarks(
        vme: finalLandmarks.vme,
        vop: finalLandmarks.vop,
        vmr: finalLandmarks.vmr,
        vmrExtended: finalLandmarks.vmrExtended,
      );
    }

    return out;
  }

  static TrainingLevelSsot _resolveLevel(TrainingProfile profile) {
    final extra = profile.extra;
    final raw =
        (extra[TrainingExtraKeys.trainingLevelDerived] ??
                extra[TrainingExtraKeys.effectiveTrainingLevel])
            ?.toString()
            .trim()
            .toLowerCase();

    if (raw == 'beginner') return TrainingLevelSsot.beginner;
    if (raw == 'advanced') return TrainingLevelSsot.advanced;
    if (raw == 'intermediate') return TrainingLevelSsot.intermediate;

    switch (profile.trainingLevel ?? TrainingLevel.intermediate) {
      case TrainingLevel.beginner:
        return TrainingLevelSsot.beginner;
      case TrainingLevel.advanced:
        return TrainingLevelSsot.advanced;
      case TrainingLevel.intermediate:
        return TrainingLevelSsot.intermediate;
    }
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static Map<String, Map<String, int>> serializeByCanonicalKey(
    Map<MuscleGroup, Landmarks> landmarksByMuscle,
  ) {
    final out = <String, Map<String, int>>{};

    for (final entry in landmarksByMuscle.entries) {
      final canonical = tryNormalizeMuscleKey(entry.key.canonicalKey);
      if (canonical == null) continue;
      out[canonical] = entry.value.toMap();
    }

    return out;
  }

  static Map<String, Landmarks> parseByCanonicalKey(dynamic raw) {
    final out = <String, Landmarks>{};
    if (raw is! Map) return out;

    raw.forEach((key, value) {
      if (value is Map) {
        final canonical = tryNormalizeMuscleKey(key.toString());
        if (canonical == null) return;

        final typed = value.map(
          (innerKey, innerValue) => MapEntry(innerKey.toString(), innerValue),
        );
        out[canonical] = Landmarks.fromMap(typed);
      }
    });

    return out;
  }

  static Map<String, int> extractVopByCanonicalKey(dynamic raw) {
    final parsed = parseByCanonicalKey(raw);
    return {for (final entry in parsed.entries) entry.key: entry.value.vop};
  }

  static Map<MuscleGroup, Landmarks> _parsePersistedLandmarks(dynamic raw) {
    final parsed = parseByCanonicalKey(raw);
    final out = <MuscleGroup, Landmarks>{};

    for (final entry in parsed.entries) {
      final muscle = muscleGroupFromString(entry.key);
      if (muscle != null) {
        out[muscle] = entry.value;
      }
    }

    return out;
  }
}
