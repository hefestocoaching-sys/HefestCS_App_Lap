class VolumeFeasibilityNormalizationResult {
  final String muscle;
  final int originalTargetSets;
  final int normalizedTargetSets;
  final bool wasAdjusted;
  final String reason;
  final int maxAssignable;
  final int frequencyUsed;
  final int dailyCap;
  final String splitId;
  final int daysPerWeek;
  final String? blockingError;

  const VolumeFeasibilityNormalizationResult({
    required this.muscle,
    required this.originalTargetSets,
    required this.normalizedTargetSets,
    required this.wasAdjusted,
    required this.reason,
    required this.maxAssignable,
    required this.frequencyUsed,
    required this.dailyCap,
    required this.splitId,
    required this.daysPerWeek,
    this.blockingError,
  });

  Map<String, dynamic> toMap() {
    return {
      'muscle': muscle,
      'originalTargetSets': originalTargetSets,
      'normalizedTargetSets': normalizedTargetSets,
      'wasAdjusted': wasAdjusted,
      'reason': reason,
      'maxAssignable': maxAssignable,
      'frequencyUsed': frequencyUsed,
      'dailyCap': dailyCap,
      'splitId': splitId,
      'daysPerWeek': daysPerWeek,
      if (blockingError != null) 'blockingError': blockingError,
    };
  }

  String toLogLine({String tag = 'V3][P0.3][VOLUME_NORMALIZATION'}) {
    return '[$tag] muscle=$muscle original=$originalTargetSets '
        'final=$normalizedTargetSets maxAssignable=$maxAssignable '
        'adjusted=$wasAdjusted reason=$reason '
        'freq=$frequencyUsed dailyCap=$dailyCap split=$splitId days=$daysPerWeek';
  }
}

class VolumeFeasibilityNormalizer {
  static VolumeFeasibilityNormalizationResult normalizeTargetVolume({
    required String muscle,
    required int targetSets,
    required int baseFrequency,
    required int effectiveFrequency,
    required int dailyCap,
    required int maxAssignable,
    required String splitId,
    required int daysPerWeek,
  }) {
    final safeTarget = targetSets < 0 ? 0 : targetSets;
    final safeCap = dailyCap < 1 ? 1 : dailyCap;
    final safeFrequency = effectiveFrequency < 0 ? 0 : effectiveFrequency;
    final resolvedMaxAssignable = maxAssignable >= 0
        ? maxAssignable
        : safeFrequency * safeCap;

    if (safeTarget <= resolvedMaxAssignable) {
      return VolumeFeasibilityNormalizationResult(
        muscle: muscle,
        originalTargetSets: safeTarget,
        normalizedTargetSets: safeTarget,
        wasAdjusted: false,
        reason: 'pass_through_feasible',
        maxAssignable: resolvedMaxAssignable,
        frequencyUsed: safeFrequency,
        dailyCap: safeCap,
        splitId: splitId,
        daysPerWeek: daysPerWeek,
      );
    }

    final normalized = resolvedMaxAssignable;
    return VolumeFeasibilityNormalizationResult(
      muscle: muscle,
      originalTargetSets: safeTarget,
      normalizedTargetSets: normalized,
      wasAdjusted: true,
      reason:
          'target_exceeds_capacity_contract_frequency_fixed(base=$baseFrequency,effective=$safeFrequency)',
      maxAssignable: resolvedMaxAssignable,
      frequencyUsed: safeFrequency,
      dailyCap: safeCap,
      splitId: splitId,
      daysPerWeek: daysPerWeek,
    );
  }
}
