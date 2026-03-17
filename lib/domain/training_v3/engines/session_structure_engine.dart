import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/data/interference_matrix.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/antagonist_pairing_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_ordering_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/fatigue_balancer.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';

class SessionStructure {
  final Exercise mainLift;
  final List<SessionBlock> blocks;

  const SessionStructure({required this.mainLift, required this.blocks});

  List<Exercise> flattenExercises() {
    return [mainLift, for (final block in blocks) ...block.exercises];
  }

  List<StructuredExercisePlacement> placements() {
    final result = <StructuredExercisePlacement>[
      StructuredExercisePlacement(
        exerciseId: mainLift.id,
        blockLabel: 'A',
        slotLabel: 'A',
        isMainLift: true,
      ),
    ];

    for (final block in blocks) {
      result.add(
        StructuredExercisePlacement(
          exerciseId: block.first.id,
          blockLabel: block.blockLabel,
          slotLabel: block.slotFirst,
          pairGroupId: block.pairGroupId,
          isMainLift: false,
        ),
      );
      if (block.second != null && block.slotSecond != null) {
        result.add(
          StructuredExercisePlacement(
            exerciseId: block.second!.id,
            blockLabel: block.blockLabel,
            slotLabel: block.slotSecond!,
            pairGroupId: block.pairGroupId,
            isMainLift: false,
          ),
        );
      }
    }

    return result;
  }

  Map<String, StructuredExercisePlacement> placementByExerciseId() {
    return {
      for (final placement in placements()) placement.exerciseId: placement,
    };
  }
}

class SessionBlock {
  final Exercise first;
  final Exercise? second;
  final String blockLabel;
  final String slotFirst;
  final String? slotSecond;
  final String? pairGroupId;

  const SessionBlock._({
    required this.first,
    required this.second,
    required this.blockLabel,
    required this.slotFirst,
    required this.slotSecond,
    required this.pairGroupId,
  });

  factory SessionBlock.single({
    required Exercise first,
    required String blockLabel,
    required String slotFirst,
  }) {
    return SessionBlock._(
      first: first,
      second: null,
      blockLabel: blockLabel,
      slotFirst: slotFirst,
      slotSecond: null,
      pairGroupId: null,
    );
  }

  factory SessionBlock.biserie({
    required Exercise first,
    required Exercise second,
    required String blockLabel,
    required String slotFirst,
    required String slotSecond,
    required String pairGroupId,
  }) {
    return SessionBlock._(
      first: first,
      second: second,
      blockLabel: blockLabel,
      slotFirst: slotFirst,
      slotSecond: slotSecond,
      pairGroupId: pairGroupId,
    );
  }

  bool get isBiserie => second != null;

  List<Exercise> get exercises => [first, if (second != null) second!];
}

class StructuredExercisePlacement {
  final String exerciseId;
  final String blockLabel;
  final String slotLabel;
  final String? pairGroupId;
  final bool isMainLift;

  const StructuredExercisePlacement({
    required this.exerciseId,
    required this.blockLabel,
    required this.slotLabel,
    this.pairGroupId,
    required this.isMainLift,
  });
}

class SessionStructureEngine {
  /// Refiner mode: preserves any existing structural metadata and only fills
  /// missing slot/block/pair/main fields.
  static List<PlannedExercise> refinePlannedExercises(
    List<PlannedExercise> exercises,
  ) {
    if (exercises.isEmpty) return const <PlannedExercise>[];

    final hasCompleteStructure = exercises.every(
      (exercise) =>
          exercise.blockLabel != null &&
          exercise.slotLabel != null &&
          (exercise.blockLabel != 'A' || exercise.isMainLift),
    );
    if (hasCompleteStructure) {
      return List<PlannedExercise>.from(exercises);
    }

    final dayExercises = <Exercise>[];
    final seen = <String>{};
    for (final planned in exercises) {
      final exercise = ExerciseCatalogV3.getById(planned.exerciseId);
      if (exercise != null && seen.add(exercise.id)) {
        dayExercises.add(exercise);
      }
    }
    if (dayExercises.isEmpty) {
      return List<PlannedExercise>.from(exercises);
    }

    final structure = build(dayExercises);
    final placementById = structure.placementByExerciseId();
    final rank = <String, int>{
      for (var i = 0; i < structure.flattenExercises().length; i++)
        structure.flattenExercises()[i].id: i,
    };

    final sorted = List<PlannedExercise>.from(exercises)
      ..sort((a, b) {
        final rankA = rank[a.exerciseId] ?? 1 << 20;
        final rankB = rank[b.exerciseId] ?? 1 << 20;
        return rankA.compareTo(rankB);
      });

    return sorted.map((current) {
      if (current.blockLabel != null && current.slotLabel != null) {
        return current;
      }
      final placement = placementById[current.exerciseId];
      if (placement == null) return current;
      return current.copyWith(
        blockLabel: placement.blockLabel,
        slotLabel: placement.slotLabel,
        pairGroupId: placement.pairGroupId,
        isMainLift: placement.isMainLift,
      );
    }).toList();
  }

  static SessionStructure build(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      throw StateError('SessionStructureEngine requires at least one exercise');
    }

    final ordered = ExerciseOrderingEngine.orderExercises(exercises);
    final balanced = FatigueBalancer.balance(ordered);
    final usable = balanced.isEmpty ? ordered : balanced;
    final mainLift = usable.first;
    final remaining = usable.skip(1).toList();
    final blocks = <SessionBlock>[];
    final mainMuscle = _primaryMuscle(mainLift);

    final antagonists = <Exercise>[];
    final lowInterference = <Exercise>[];
    final complementaries = <Exercise>[];
    final accessories = <Exercise>[];
    final pending = List<Exercise>.from(remaining);

    while (pending.isNotEmpty) {
      final exercise = pending.removeAt(0);
      if (_isAccessory(exercise)) {
        accessories.add(exercise);
        continue;
      }

      final currentMuscle = _primaryMuscle(exercise);
      if (AntagonistPairingEngine.areAntagonists(mainMuscle, currentMuscle)) {
        antagonists.add(exercise);
        continue;
      }

      final lowList =
          InterferenceMatrix.lowInterference[mainMuscle] ?? const <String>[];
      if (lowList.contains(currentMuscle)) {
        lowInterference.add(exercise);
        continue;
      }

      complementaries.add(exercise);
    }

    // Build B first to assess B↔C compatibility before finalizing C and D.
    _appendPaired(
      blocks,
      antagonists,
      blockLabel: 'B',
      preferAntagonists: true,
    );

    final bMuscles = blocks
        .where((block) => block.blockLabel == 'B')
        .expand((block) => block.exercises.map(_primaryMuscle))
        .toSet();

    final blockC = <Exercise>[];
    final blockD = <Exercise>[];

    bool isCompatibleForC(Exercise exercise) {
      final muscle = _primaryMuscle(exercise);
      final lowMain =
          InterferenceMatrix.lowInterference[mainMuscle] ?? const <String>[];
      final withMain =
          lowMain.contains(muscle) ||
          (InterferenceMatrix.lowInterference[muscle] ?? const <String>[])
              .contains(mainMuscle);
      if (!withMain) return false;

      for (final bMuscle in bMuscles) {
        final lowB =
            InterferenceMatrix.lowInterference[bMuscle] ?? const <String>[];
        final reverseLowB =
            InterferenceMatrix.lowInterference[muscle] ?? const <String>[];
        if (!lowB.contains(muscle) && !reverseLowB.contains(bMuscle)) {
          return false;
        }
      }
      return true;
    }

    for (final exercise in [...lowInterference, ...complementaries]) {
      if (isCompatibleForC(exercise)) {
        blockC.add(exercise);
      } else {
        blockD.add(exercise);
      }
    }

    // D favors low systemic-cost accessories.
    accessories.sort((a, b) => _fatigueScore(a).compareTo(_fatigueScore(b)));
    blockD.addAll(accessories);

    _appendPaired(blocks, blockC, blockLabel: 'C');
    _appendPaired(blocks, blockD, blockLabel: 'D');

    return SessionStructure(mainLift: mainLift, blocks: blocks);
  }

  static void _appendPaired(
    List<SessionBlock> blocks,
    List<Exercise> bucket, {
    required String blockLabel,
    bool preferAntagonists = false,
  }) {
    final working = List<Exercise>.from(bucket);
    var slotIndex = 1;
    while (working.isNotEmpty) {
      final first = working.removeAt(0);
      final partnerIndex = working.indexWhere((candidate) {
        if (preferAntagonists) {
          return AntagonistPairingEngine.areAntagonists(
            _primaryMuscle(first),
            _primaryMuscle(candidate),
          );
        }
        final firstMuscle = _primaryMuscle(first);
        final candidateMuscle = _primaryMuscle(candidate);
        final lowA =
            InterferenceMatrix.lowInterference[firstMuscle] ?? const <String>[];
        final lowB =
            InterferenceMatrix.lowInterference[candidateMuscle] ??
            const <String>[];
        return lowA.contains(candidateMuscle) || lowB.contains(firstMuscle);
      });

      if (partnerIndex >= 0) {
        final second = working.removeAt(partnerIndex);
        final slotFirst = '$blockLabel$slotIndex';
        final slotSecond = '$blockLabel${slotIndex + 1}';
        final pairId = '${blockLabel}_${((slotIndex + 1) / 2).ceil()}';
        blocks.add(
          SessionBlock.biserie(
            first: first,
            second: second,
            blockLabel: blockLabel,
            slotFirst: slotFirst,
            slotSecond: slotSecond,
            pairGroupId: pairId,
          ),
        );
        slotIndex += 2;
      } else {
        blocks.add(
          SessionBlock.single(
            first: first,
            blockLabel: blockLabel,
            slotFirst: '$blockLabel$slotIndex',
          ),
        );
        slotIndex += 1;
      }
    }
  }

  static bool _isAccessory(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    return metadata['category']?.toString() == 'isolation';
  }

  static String _primaryMuscle(Exercise exercise) {
    String normalize(String raw) {
      switch (raw.toLowerCase()) {
        case 'chest':
          return 'pectorals';
        case 'quads':
          return 'quadriceps';
        case 'shoulders':
        case 'deltoids':
          return 'deltoide_lateral';
        default:
          return raw.toLowerCase();
      }
    }

    if (exercise.primaryMuscles.isNotEmpty) {
      return normalize(exercise.primaryMuscles.first);
    }
    return normalize(exercise.muscleKey);
  }

  static int _fatigueScore(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    final raw = metadata['fatigueScore'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 2;
  }
}
