import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';

part 'volume_landmarks.freezed.dart';
part 'volume_landmarks.g.dart';

/// Landmarks de volumen individuales por músculo
///
/// Cada músculo tiene:
/// - VME: Volumen Mínimo Efectivo
/// - VOP: Volumen Óptimo Personalizado (punto partida)
/// - VMR: Volumen Máximo Recuperable (teórico)
/// - VMRTarget: VMR objetivo según prioridad
@freezed
abstract class VolumeLandmarks with _$VolumeLandmarks {
  const factory VolumeLandmarks({
    required int vme,
    required int vop,
    required int vmr,
    required int vmrTarget,
  }) = _VolumeLandmarks;

  factory VolumeLandmarks.fromJson(Map<String, dynamic> json) =>
      _$VolumeLandmarksFromJson(json);

  static int calculateVopFromRange({required int vme, required int vmr}) {
    if (vmr <= vme) return vme;
    return (vme + (0.35 * (vmr - vme))).round();
  }

  /// Calcula landmarks para un músculo específico
  static VolumeLandmarks calculate({
    required String muscle,
    required int priority,
    required String trainingLevel,
    required int age,
  }) {
    final vmeBase = _getVMEBase(muscle);
    final vmrBase = _getVMRBase(muscle);
    final levelMultiplier = _getLevelMultiplier(trainingLevel);
    final ageMultiplier = _getAgeMultiplier(age);

    final vme = (vmeBase * levelMultiplier * ageMultiplier).round();
    final vmr = (vmrBase * levelMultiplier * ageMultiplier).round();
    final vop = calculateVopFromRange(vme: vme, vmr: vmr);

    int vmrTarget;
    if (priority == 5) {
      vmrTarget = vmr;
    } else if (priority >= 3) {
      vmrTarget = (vmr * 0.75).round();
    } else {
      vmrTarget = vop;
    }

    return VolumeLandmarks(vme: vme, vop: vop, vmr: vmr, vmrTarget: vmrTarget);
  }

  static int _getVMEBase(String muscle) {
    switch (normalizeMuscleKey(muscle)) {
      case 'pectorals':
        return 8;
      case 'quads':
        return 8;
      case 'lats':
        return 6;
      case 'upper_back':
        return 4;
      case 'traps':
        return 4;
      case 'delts_front':
      case 'delts_lateral':
      case 'delts_rear':
        return 4;
      case 'triceps':
        return 6;
      case 'biceps':
        return 6;
      case 'hamstrings':
        return 6;
      case 'glutes':
        return 6;
      case 'calves':
        return 4;
      case 'abs':
        return 4;
      default:
        return 6;
    }
  }

  static int _getVMRBase(String muscle) {
    switch (normalizeMuscleKey(muscle)) {
      case 'pectorals':
        return 22;
      case 'quads':
        return 24;
      case 'lats':
        return 20;
      case 'upper_back':
        return 14;
      case 'traps':
        return 14;
      case 'delts_front':
      case 'delts_lateral':
      case 'delts_rear':
        return 18;
      case 'triceps':
        return 18;
      case 'biceps':
        return 16;
      case 'hamstrings':
        return 18;
      case 'glutes':
        return 20;
      case 'calves':
        return 12;
      case 'abs':
        return 10;
      default:
        return 18;
    }
  }

  static double _getLevelMultiplier(String level) {
    switch (level) {
      case 'novice':
        return 0.8;
      case 'intermediate':
        return 1.0;
      case 'advanced':
        return 1.2;
      default:
        return 1.0;
    }
  }

  static double _getAgeMultiplier(int age) {
    if (age < 25) return 1.1;
    if (age < 40) return 1.0;
    if (age < 55) return 0.9;
    return 0.8;
  }
}
