import 'package:hcs_app_lap/core/constants/muscle_taxonomy.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

class Phase45SessionStructureResult {
  final SplitTemplate structuredSplit;
  final Map<String, dynamic> debug;

  const Phase45SessionStructureResult({
    required this.structuredSplit,
    required this.debug,
  });
}

/// Fase 4.5 — Estructura de sesión (cap por día)
/// Convierte un split "por músculos" (Phase 4) en un split clínicamente ejecutable:
/// limita músculos por sesión para evitar explosión de ejercicios en Phase 6.
class Phase45SessionStructureService {
  const Phase45SessionStructureService();

  Phase45SessionStructureResult apply({
    required TrainingProfile profile,
    required SplitTemplate baseSplit,
  }) {
    final days = baseSplit.daysPerWeek;
    final cap = _capForDays(days);

    final primary = profile.priorityMusclesPrimary.map(_norm).toList();
    final secondary = profile.priorityMusclesSecondary.map(_norm).toList();
    final tertiary = profile.priorityMusclesTertiary.map(_norm).toList();

    final newDayMuscles = <int, List<String>>{};
    final newDailyVolume = <int, Map<String, int>>{};

    int movedSetsTotal = 0;

    for (var d = 1; d <= days; d++) {
      final rawMuscles = (baseSplit.dayMuscles[d] ?? const <String>[])
          .map(_norm)
          .toList();
      final rawVolume = Map<String, int>.from(
        baseSplit.dailyVolume[d] ?? const <String, int>{},
      )..removeWhere((k, _) => k.trim().isEmpty);

      // Ordenar por prioridad (primario > secundario > terciario > resto)
      final ranked = _rankMuscles(
        rawMuscles: rawMuscles,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
      );

      // Aplicar cap
      final kept = ranked.take(cap).toList();

      // Garantía: si quedara vacío por datos raros, conservar el primero del raw
      if (kept.isEmpty && rawMuscles.isNotEmpty) {
        kept.add(rawMuscles.first);
      }

      newDayMuscles[d] = kept;

      // Reasignación de volumen (no perder sets)
      final keptVolume = <String, int>{};
      for (final m in kept) {
        keptVolume[m] = (rawVolume[m] ?? 0);
      }

      // Músculos removidos → mover sets al primer "macro-grupo" compatible
      final removed = rawMuscles.where((m) => !kept.contains(m)).toList();
      for (final rm in removed) {
        final sets = rawVolume[rm] ?? 0;
        if (sets <= 0) continue;
        movedSetsTotal += sets;

        final target = _findRedistributionTarget(
          removedMuscle: rm,
          keptMuscles: kept,
        );

        keptVolume[target] = (keptVolume[target] ?? 0) + sets;
      }

      // Limpiar volumen: solo claves kept y sets >= 0
      keptVolume.removeWhere((k, v) => v <= 0);
      newDailyVolume[d] = keptVolume;
    }

    final structured = baseSplit.copyWith(
      dayMuscles: newDayMuscles,
      dailyVolume: newDailyVolume,
    );

    return Phase45SessionStructureResult(
      structuredSplit: structured,
      debug: {
        'daysPerWeek': days,
        'cap': cap,
        'movedSetsTotal': movedSetsTotal,
      },
    );
  }

  int _capForDays(int days) {
    if (days <= 3) return 5;
    if (days == 4) return 4;
    return 3; // 5–6
  }

  String _norm(String s) => s.trim().toLowerCase();

  List<String> _rankMuscles({
    required List<String> rawMuscles,
    required List<String> primary,
    required List<String> secondary,
    required List<String> tertiary,
  }) {
    int score(String m) {
      if (primary.contains(m)) return 300;
      if (secondary.contains(m)) return 200;
      if (tertiary.contains(m)) return 100;
      return 0;
    }

    final unique = <String>{};
    final list = <String>[];
    for (final m in rawMuscles) {
      if (m.isEmpty) continue;
      if (unique.add(m)) list.add(m);
    }

    list.sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  bool _isLower(String muscleKey) {
    return MuscleTaxonomy.legs.contains(muscleKey);
  }

  String _findRedistributionTarget({
    required String removedMuscle,
    required List<String> keptMuscles,
  }) {
    final removedIsLower = _isLower(removedMuscle);

    // 1) Preferir primer kept del mismo macro-grupo (lower/upper)
    for (final km in keptMuscles) {
      if (_isLower(km) == removedIsLower) return km;
    }

    // 2) Fallback: el primero kept
    return keptMuscles.isNotEmpty ? keptMuscles.first : removedMuscle;
  }
}
