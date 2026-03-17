class ExerciseSetAllocator {
  static const Map<String, double> _blockWeights = {
    'A': 0.38,
    'B': 0.28,
    'C': 0.22,
    'D': 0.12,
  };

  static const Map<String, double> _minimumShareByBlock = {
    'A': 0.35,
    'B': 0.25,
    'C': 0.20,
    'D': 0.00,
  };

  static Map<String, int> allocateSets(
    int totalSets,
    int exerciseCount, {
    List<String?>? blockLabelsByIndex,
  }) {
    if (exerciseCount <= 0) return const <String, int>{};

    final labels = blockLabelsByIndex;
    if (labels == null || labels.length != exerciseCount) {
      return _allocateUniform(totalSets, exerciseCount);
    }

    return _allocateByBlockWeight(totalSets, labels);
  }

  static Map<String, int> _allocateUniform(int totalSets, int exerciseCount) {
    if (exerciseCount <= 0) return const <String, int>{};

    final base = totalSets ~/ exerciseCount;
    final remainder = totalSets % exerciseCount;
    final map = <String, int>{};

    for (var i = 0; i < exerciseCount; i++) {
      map['ex$i'] = base + (i < remainder ? 1 : 0);
    }

    return map;
  }

  static Map<String, int> _allocateByBlockWeight(
    int totalSets,
    List<String?> blockLabelsByIndex,
  ) {
    final exerciseCount = blockLabelsByIndex.length;
    final blockToIndices = <String, List<int>>{};
    for (var i = 0; i < exerciseCount; i++) {
      final block = _normalizeBlock(blockLabelsByIndex[i]);
      blockToIndices.putIfAbsent(block, () => <int>[]).add(i);
    }

    final presentBlocks = blockToIndices.keys.toList();
    final totalWeight = presentBlocks.fold<double>(
      0,
      (sum, block) => sum + (_blockWeights[block] ?? 0),
    );
    if (totalWeight <= 0) {
      return _allocateUniform(totalSets, exerciseCount);
    }

    final blockTarget = <String, int>{};
    final fractions = <MapEntry<String, double>>[];
    var assigned = 0;

    // First pass: reserve minimum target shares for present blocks.
    for (final block in presentBlocks) {
      final minShare = _minimumShareByBlock[block] ?? 0;
      final minSets = (totalSets * minShare).floor();
      blockTarget[block] = minSets;
      assigned += minSets;
    }

    // Safety: if minimum floors exceed totalSets due to small totals,
    // fallback to weighted allocation without floors.
    if (assigned > totalSets) {
      blockTarget.clear();
      assigned = 0;
    }

    for (final block in presentBlocks) {
      final current = blockTarget[block] ?? 0;
      final raw = totalSets * ((_blockWeights[block] ?? 0) / totalWeight);
      final floored = raw.floor();
      if (floored > current) {
        final delta = floored - current;
        blockTarget[block] = floored;
        assigned += delta;
      }
      fractions.add(MapEntry(block, raw - (blockTarget[block] ?? 0)));
    }

    var remaining = totalSets - assigned;
    fractions.sort((a, b) => b.value.compareTo(a.value));
    var cursor = 0;
    while (remaining > 0 && fractions.isNotEmpty) {
      final block = fractions[cursor % fractions.length].key;
      blockTarget[block] = (blockTarget[block] ?? 0) + 1;
      remaining--;
      cursor++;
    }

    final result = <String, int>{};
    for (final entry in blockToIndices.entries) {
      final block = entry.key;
      final indices = entry.value;
      final blockSets = blockTarget[block] ?? 0;
      final base = blockSets ~/ indices.length;
      final rem = blockSets % indices.length;
      for (var i = 0; i < indices.length; i++) {
        result['ex${indices[i]}'] = base + (i < rem ? 1 : 0);
      }
    }

    return result;
  }

  static String _normalizeBlock(String? label) {
    if (label == null || label.trim().isEmpty) return 'D';
    final raw = label.trim().toUpperCase();
    final first = raw.substring(0, 1);
    if (_blockWeights.containsKey(first)) return first;
    return 'D';
  }
}
