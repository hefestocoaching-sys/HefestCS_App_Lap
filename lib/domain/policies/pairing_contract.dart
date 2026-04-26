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
    final left = _canonical(firstPrimaryMuscle);
    final right = _canonical(secondPrimaryMuscle);

    if (left.isEmpty || right.isEmpty) {
      return PairingType.none;
    }
    if (left == right) {
      return PairingType.forbiddenSamePrimary;
    }
    if (AntagonistPairingEngine.areAntagonists(left, right)) {
      return PairingType.antagonist;
    }

    final lowL = InterferenceMatrix.lowInterference[left] ?? const <String>[];
    final lowR = InterferenceMatrix.lowInterference[right] ?? const <String>[];
    if (lowL.contains(right) || lowR.contains(left)) {
      return PairingType.lowInterference;
    }

    final synL = _synergy[left] ?? const <String>{};
    final synR = _synergy[right] ?? const <String>{};
    if (synL.contains(right) || synR.contains(left)) {
      return PairingType.synergy;
    }

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

  static String _canonical(String raw) {
    final normalized = muscle_registry.normalize(raw);
    if (normalized != null) {
      return normalized;
    }
    final expanded = muscle_registry.expandGroup(raw);
    if (expanded.isNotEmpty) {
      return expanded.first;
    }
    return raw.trim().toLowerCase();
  }
}
