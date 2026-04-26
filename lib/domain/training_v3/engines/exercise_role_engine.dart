import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

enum ExerciseRole { primaryAnchor, secondarySupport, accessory }

class MuscleExerciseRoleMap {
  final List<Exercise> primaryAnchor;
  final List<Exercise> secondarySupport;
  final List<Exercise> accessory;

  const MuscleExerciseRoleMap({
    required this.primaryAnchor,
    required this.secondarySupport,
    required this.accessory,
  });

  List<Exercise> forRole(ExerciseRole role) {
    switch (role) {
      case ExerciseRole.primaryAnchor:
        return primaryAnchor;
      case ExerciseRole.secondarySupport:
        return secondarySupport;
      case ExerciseRole.accessory:
        return accessory;
    }
  }
}

class ExerciseRoleEngine {
  MuscleExerciseRoleMap classify({
    required String muscle,
    required List<Exercise> pool,
  }) {
    final anchors = <Exercise>[];
    final supports = <Exercise>[];
    final accessories = <Exercise>[];

    for (final exercise in pool) {
      final supportsA =
          ExerciseCatalogV3.supportsSlot(exercise.id, 'A') &&
          ExerciseCatalogV3.isAEligible(exercise.id);
      final supportsB =
          ExerciseCatalogV3.supportsSlot(exercise.id, 'B1') ||
          ExerciseCatalogV3.supportsSlot(exercise.id, 'B2');
      final supportsCD =
          ExerciseCatalogV3.supportsSlot(exercise.id, 'C1') ||
          ExerciseCatalogV3.supportsSlot(exercise.id, 'C2') ||
          ExerciseCatalogV3.supportsSlot(exercise.id, 'D1') ||
          ExerciseCatalogV3.supportsSlot(exercise.id, 'D2');

      if (supportsA) {
        anchors.add(exercise);
      } else if (supportsB) {
        supports.add(exercise);
      } else if (supportsCD) {
        accessories.add(exercise);
      } else {
        supports.add(exercise);
      }
    }

    if (anchors.isEmpty && supports.isNotEmpty) {
      anchors.add(supports.removeAt(0));
      debugPrint(
        '[V3][ROLE_FALLBACK] muscle=$muscle reason=no_anchor used=support_as_anchor',
      );
    }

    if (supports.isEmpty && anchors.length > 1) {
      supports.add(anchors.removeLast());
      debugPrint(
        '[V3][ROLE_FALLBACK] muscle=$muscle reason=no_support used=anchor_as_support',
      );
    }

    if (supports.isEmpty && accessories.isNotEmpty) {
      supports.add(accessories.first);
      debugPrint(
        '[V3][ROLE_FALLBACK] muscle=$muscle reason=no_support used=accessory_as_support',
      );
    }

    debugPrint(
      '[V3][ROLE_MAP] muscle=$muscle '
      'anchors=${anchors.map((e) => e.id).toList()} '
      'supports=${supports.map((e) => e.id).toList()} '
      'accessories=${accessories.map((e) => e.id).toList()}',
    );

    return MuscleExerciseRoleMap(
      primaryAnchor: anchors,
      secondarySupport: supports,
      accessory: accessories,
    );
  }
}
