import 'package:collection/collection.dart';

/// Fases macro (agregadas por bloque)
enum PhaseType {
  accumulation,
  intensification,
  realization,
  deload,
  transition,
}

/// Perfil de carga relativa de un bloque
class LoadProfile {
  final double volumeFactor;
  final double intensityFactor;
  final double? rirBase;
  final bool intensificationAllowed;
  final String fatigueExpectation; // e.g. low/medium/high

  const LoadProfile({
    required this.volumeFactor,
    required this.intensityFactor,
    required this.rirBase,
    required this.intensificationAllowed,
    required this.fatigueExpectation,
  });

  Map<String, dynamic> toMap() => {
    'volumeFactor': volumeFactor,
    'intensityFactor': intensityFactor,
    'rirBase': rirBase,
    'intensificationAllowed': intensificationAllowed,
    'fatigueExpectation': fatigueExpectation,
  };

  factory LoadProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const LoadProfile(
        volumeFactor: 1.0,
        intensityFactor: 1.0,
        rirBase: null,
        intensificationAllowed: true,
        fatigueExpectation: 'medium',
      );
    }
    return LoadProfile(
      volumeFactor: (map['volumeFactor'] as num?)?.toDouble() ?? 1.0,
      intensityFactor: (map['intensityFactor'] as num?)?.toDouble() ?? 1.0,
      rirBase: (map['rirBase'] as num?)?.toDouble(),
      intensificationAllowed: map['intensificationAllowed'] == false
          ? false
          : true,
      fatigueExpectation: map['fatigueExpectation']?.toString() ?? 'medium',
    );
  }
}

/// Bloque de entrenamiento dentro del macroplan
class TrainingBlock {
  final String blockId;
  final int startWeekIndex; // 1-based global week index
  final int durationWeeks;
  final PhaseType phaseType;
  final LoadProfile loadProfile;
  final bool autoAdjustEnabled;
  final String status; // planned | active | completed

  const TrainingBlock({
    required this.blockId,
    required this.startWeekIndex,
    required this.durationWeeks,
    required this.phaseType,
    required this.loadProfile,
    required this.autoAdjustEnabled,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'blockId': blockId,
    'startWeekIndex': startWeekIndex,
    'durationWeeks': durationWeeks,
    'phaseType': phaseType.name,
    'loadProfile': loadProfile.toMap(),
    'autoAdjustEnabled': autoAdjustEnabled,
    'status': status,
  };

  factory TrainingBlock.fromMap(Map<String, dynamic> map) {
    final phaseRaw = map['phaseType']?.toString();
    final phase = PhaseType.values.firstWhereOrNull((p) => p.name == phaseRaw);

    return TrainingBlock(
      blockId: map['blockId']?.toString() ?? 'block_${map.hashCode}',
      startWeekIndex: (map['startWeekIndex'] as num?)?.toInt() ?? 1,
      durationWeeks: (map['durationWeeks'] as num?)?.toInt() ?? 4,
      phaseType: phase ?? PhaseType.accumulation,
      loadProfile: LoadProfile.fromMap(
        map['loadProfile'] is Map<String, dynamic>
            ? map['loadProfile'] as Map<String, dynamic>
            : (map['loadProfile'] is Map
                  ? Map<String, dynamic>.from(map['loadProfile'] as Map)
                  : null),
      ),
      autoAdjustEnabled: map['autoAdjustEnabled'] == false ? false : true,
      status: map['status']?.toString() ?? 'planned',
    );
  }
}

/// Plan macro (52 semanas por defecto)
class TrainingMacroPlan {
  final String startDateIso;
  final int totalWeeks;
  final int schemaVersion;
  final String? activeBlockId;
  final List<TrainingBlock> blocks;

  const TrainingMacroPlan({
    required this.startDateIso,
    required this.totalWeeks,
    required this.schemaVersion,
    required this.activeBlockId,
    required this.blocks,
  });

  Map<String, dynamic> toMap() => {
    'startDateIso': startDateIso,
    'totalWeeks': totalWeeks,
    'schemaVersion': schemaVersion,
    'activeBlockId': activeBlockId,
    'blocks': blocks.map((b) => b.toMap()).toList(),
  };

  factory TrainingMacroPlan.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('map cannot be null');
    }
    final blocksRaw = map['blocks'];
    final blocksList = <TrainingBlock>[];
    if (blocksRaw is List) {
      for (final item in blocksRaw) {
        if (item is Map<String, dynamic>) {
          blocksList.add(TrainingBlock.fromMap(item));
        } else if (item is Map) {
          blocksList.add(
            TrainingBlock.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return TrainingMacroPlan(
      startDateIso:
          map['startDateIso']?.toString() ?? DateTime.now().toIso8601String(),
      totalWeeks: (map['totalWeeks'] as num?)?.toInt() ?? 52,
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      activeBlockId: map['activeBlockId']?.toString(),
      blocks: blocksList,
    );
  }

  /// Construye un macroplan default de 52 semanas, bloques de 4 semanas
  /// (3 acumulación + 1 deload repetido).
  factory TrainingMacroPlan.buildDefault({required DateTime startDate}) {
    const totalWeeks = 52;
    final blocks = <TrainingBlock>[];
    var weekCursor = 1;
    var blockIndex = 1;

    while (weekCursor <= totalWeeks) {
      // Bloque de 3 semanas de acumulación
      final accId = 'B$blockIndex';
      blocks.add(
        TrainingBlock(
          blockId: accId,
          startWeekIndex: weekCursor,
          durationWeeks: weekCursor + 2 <= totalWeeks
              ? 3
              : (totalWeeks - weekCursor + 1),
          phaseType: PhaseType.accumulation,
          loadProfile: const LoadProfile(
            volumeFactor: 1.0,
            intensityFactor: 1.0,
            rirBase: 2.0,
            intensificationAllowed: true,
            fatigueExpectation: 'medium',
          ),
          autoAdjustEnabled: true,
          status: blockIndex == 1 ? 'active' : 'planned',
        ),
      );
      weekCursor += 3;
      blockIndex += 1;

      if (weekCursor > totalWeeks) break;

      // Bloque de 1 semana de deload
      final deloadId = 'B$blockIndex';
      blocks.add(
        TrainingBlock(
          blockId: deloadId,
          startWeekIndex: weekCursor,
          durationWeeks: 1,
          phaseType: PhaseType.deload,
          loadProfile: const LoadProfile(
            volumeFactor: 0.6,
            intensityFactor: 0.8,
            rirBase: 3.0,
            intensificationAllowed: false,
            fatigueExpectation: 'low',
          ),
          autoAdjustEnabled: true,
          status: 'planned',
        ),
      );
      weekCursor += 1;
      blockIndex += 1;
    }

    return TrainingMacroPlan(
      startDateIso: startDate.toIso8601String(),
      totalWeeks: totalWeeks,
      schemaVersion: 1,
      activeBlockId: blocks.isNotEmpty ? blocks.first.blockId : null,
      blocks: blocks,
    );
  }
}
