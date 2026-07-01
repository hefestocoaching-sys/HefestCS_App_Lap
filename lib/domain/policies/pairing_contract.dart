import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/data/interference_matrix.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/antagonist_pairing_engine.dart';

enum PairingType {
  antagonist,
  lowInterference,
  synergy,
  forbiddenSamePrimary,
  none,
}

/// Contrato de pairing Fase 2.
///
/// Permitido:
/// - antagonist
/// - low_interference
/// - synergy
///
/// Prohibido:
/// - same primary muscle en biserie
class PairingContract {
  static const Map<String, Set<String>> _synergy = {
    'pectorals': {'triceps', 'delts_front'},
    'lats': {'biceps', 'delts_rear'},
    'upper_back': {'biceps', 'delts_rear'},
    'quads': {'glutes', 'calves'},
    'hamstrings': {'glutes', 'calves'},
    'glutes': {'hamstrings', 'quads'},
    'delts_front': {'triceps', 'pectorals'},
    'delts_rear': {'upper_back', 'lats'},
  };

  static PairingType classify({
    required String firstPrimaryMuscle,
    required String secondPrimaryMuscle,
  }) {
    final leftMuscles = _resolveMusclesStrict(firstPrimaryMuscle);
    final rightMuscles = _resolveMusclesStrict(secondPrimaryMuscle);

    if (leftMuscles.isEmpty || rightMuscles.isEmpty) {
      return PairingType.none;
    }

    var hasSamePrimary = false;
    var hasAntagonist = false;
    var hasSynergy = false;
    var hasLowInterference = false;

    for (final left in leftMuscles) {
      for (final right in rightMuscles) {
        if (left == right) {
          hasSamePrimary = true;
          continue;
        }
        if (AntagonistPairingEngine.areAntagonists(left, right)) {
          hasAntagonist = true;
        }
        if (_isSynergy(left, right)) {
          hasSynergy = true;
        }
        if (_isLowInterference(left, right)) {
          hasLowInterference = true;
        }
      }
    }

    if (hasSamePrimary) return PairingType.forbiddenSamePrimary;
    if (hasAntagonist) return PairingType.antagonist;
    if (hasSynergy) return PairingType.synergy;
    if (hasLowInterference) return PairingType.lowInterference;

    return PairingType.none;
  }

  static bool isAllowedBiserie({
    required String firstPrimaryMuscle,
    required String secondPrimaryMuscle,
  }) {
    final type = classify(
      firstPrimaryMuscle: firstPrimaryMuscle,
      secondPrimaryMuscle: secondPrimaryMuscle,
    );
    return type == PairingType.antagonist ||
        type == PairingType.lowInterference ||
        type == PairingType.synergy;
  }

  static List<String> _resolveMusclesStrict(String raw) {
    final canonical = muscle_registry.tryNormalizeMuscleKey(raw);
    if (canonical != null) {
      return [canonical];
    }

    final expanded = muscle_registry.expandMuscleGroupStrict(raw);
    if (expanded != null) {
      return expanded;
    }

    return const [];
  }

  static bool _isLowInterference(String left, String right) {
    final lowL = InterferenceMatrix.lowInterference[left] ?? const <String>[];
    final lowR = InterferenceMatrix.lowInterference[right] ?? const <String>[];
    return lowL.contains(right) || lowR.contains(left);
  }

  static bool _isSynergy(String left, String right) {
    final synL = _synergy[left] ?? const <String>{};
    final synR = _synergy[right] ?? const <String>{};
    return synL.contains(right) || synR.contains(left);
  }
}
