enum TrainingLevelSsot { beginner, intermediate, advanced }

class MuscleVolumeRangeSsot {
  final int vme;
  final int vmrBase;
  final int? vmrExtended;

  const MuscleVolumeRangeSsot({
    required this.vme,
    required this.vmrBase,
    this.vmrExtended,
  });
}

class MuscleVolumeLandmarksSsot {
  static const Map<String, Map<TrainingLevelSsot, MuscleVolumeRangeSsot>>
  table = {
    'pectorals': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 6, vmrBase: 12),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 10,
        vmrBase: 16,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 16,
        vmrBase: 22,
        vmrExtended: 26,
      ),
    },
    'lats': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 12,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 22,
      ),
    },
    'upper_back': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 12,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 22,
      ),
    },
    'traps': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 2, vmrBase: 6),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 6,
        vmrBase: 10,
        vmrExtended: 14,
      ),
    },
    'quads': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 5, vmrBase: 10),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 10,
        vmrBase: 15,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 15,
        vmrBase: 22,
        vmrExtended: 28,
      ),
    },
    'hamstrings': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 12,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 22,
      ),
    },
    'glutes': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 6, vmrBase: 12),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 10,
        vmrBase: 16,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 16,
        vmrBase: 24,
        vmrExtended: 32,
      ),
    },
    'delts_front': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 2, vmrBase: 6),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 6,
        vmrBase: 10,
        vmrExtended: 12,
      ),
    },
    'delts_lateral': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 12,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 22,
      ),
    },
    'delts_rear': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 4, vmrBase: 8),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 12,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 22,
      ),
    },
    'biceps': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 5, vmrBase: 10),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 14,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 22,
      ),
    },
    'triceps': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 5, vmrBase: 10),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 14,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 20,
        vmrExtended: 24,
      ),
    },
    'calves': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 6, vmrBase: 12),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 10,
        vmrBase: 16,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 14,
        vmrBase: 22,
        vmrExtended: 28,
      ),
    },
    'abs': {
      TrainingLevelSsot.beginner: MuscleVolumeRangeSsot(vme: 4, vmrBase: 10),
      TrainingLevelSsot.intermediate: MuscleVolumeRangeSsot(
        vme: 8,
        vmrBase: 14,
      ),
      TrainingLevelSsot.advanced: MuscleVolumeRangeSsot(
        vme: 12,
        vmrBase: 18,
        vmrExtended: 24,
      ),
    },
  };
}

class GlobalVolumeAdjustments {
  final double deltaVme;
  final double deltaVmr;

  const GlobalVolumeAdjustments({
    required this.deltaVme,
    required this.deltaVmr,
  });
}

class FinalMuscleLandmarks {
  final int vme;
  final int vmr;
  final int vop;
  final int? vmrExtended;

  const FinalMuscleLandmarks({
    required this.vme,
    required this.vmr,
    required this.vop,
    required this.vmrExtended,
  });
}

FinalMuscleLandmarks computeFinalMuscleLandmarks({
  required MuscleVolumeRangeSsot base,
  required GlobalVolumeAdjustments adjustments,
  required TrainingLevelSsot level,
}) {
  final int vme = (base.vme + adjustments.deltaVme).round().clamp(1, 999);
  final int vmrRaw = (base.vmrBase + adjustments.deltaVmr).round();
  final int vmr = vmrRaw < vme ? vme : vmrRaw;

  final int vop = switch (level) {
    TrainingLevelSsot.beginner => vme,
    TrainingLevelSsot.intermediate => (vme + 1 > vmr) ? vmr : vme + 1,
    TrainingLevelSsot.advanced => (vme + 2 > vmr) ? vmr : vme + 2,
  };

  return FinalMuscleLandmarks(
    vme: vme,
    vmr: vmr,
    vop: vop,
    vmrExtended: base.vmrExtended,
  );
}
