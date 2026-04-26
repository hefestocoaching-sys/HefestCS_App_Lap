class FrequencyFeasibilityResult {
  final String muscle;
  final int targetSets;
  final int baseFrequency;
  final int finalFrequency;
  final int effectiveFrequency;
  final int dailyCap;
  final int maxAssignable;
  final bool wasAdjusted;
  final bool isFeasible;
  final String reason;
  final String? blockingError;

  const FrequencyFeasibilityResult({
    required this.muscle,
    required this.targetSets,
    required this.baseFrequency,
    required this.finalFrequency,
    required this.effectiveFrequency,
    required this.dailyCap,
    required this.maxAssignable,
    required this.wasAdjusted,
    required this.isFeasible,
    required this.reason,
    this.blockingError,
  });

  Map<String, dynamic> toMap() {
    return {
      'muscle': muscle,
      'targetSets': targetSets,
      'baseFrequency': baseFrequency,
      'finalFrequency': finalFrequency,
      'effectiveFrequency': effectiveFrequency,
      'dailyCap': dailyCap,
      'maxAssignable': maxAssignable,
      'wasAdjusted': wasAdjusted,
      'isFeasible': isFeasible,
      'reason': reason,
      if (blockingError != null) 'blockingError': blockingError,
    };
  }

  String toLogLine({String tag = 'FREQ_FEAS'}) {
    return '[$tag] muscle=$muscle target=$targetSets base=$baseFrequency '
        'final=$finalFrequency effective=$effectiveFrequency dailyCap=$dailyCap '
        'maxAssignable=$maxAssignable adjusted=$wasAdjusted feasible=$isFeasible '
        'reason=$reason';
  }
}

class FrequencyFeasibilityResolver {
  static FrequencyFeasibilityResult resolveFeasibleFrequency({
    required String muscle,
    required int targetSets,
    required int baseFrequency,
    required int maxFrequency,
    required int dailyCap,
    required int Function(int candidateFrequency)
    effectiveFrequencyForCandidate,
    String errorContext = '',
  }) {
    if (targetSets <= 0) {
      return FrequencyFeasibilityResult(
        muscle: muscle,
        targetSets: targetSets,
        baseFrequency: baseFrequency,
        finalFrequency: 0,
        effectiveFrequency: 0,
        dailyCap: dailyCap,
        maxAssignable: 0,
        wasAdjusted: false,
        isFeasible: true,
        reason: 'target_non_positive',
      );
    }

    final safeBase = baseFrequency < 1 ? 1 : baseFrequency;
    final safeMax = maxFrequency < 1 ? 1 : maxFrequency;

    final candidate = safeBase > safeMax ? safeMax : safeBase;
    final effective = effectiveFrequencyForCandidate(candidate);
    final maxAssignable = effective * dailyCap;
    final feasible = targetSets <= maxAssignable;

    final terminal = FrequencyFeasibilityResult(
      muscle: muscle,
      targetSets: targetSets,
      baseFrequency: safeBase,
      finalFrequency: candidate,
      effectiveFrequency: effective,
      dailyCap: dailyCap,
      maxAssignable: maxAssignable,
      wasAdjusted: false,
      isFeasible: feasible,
      reason: feasible ? 'base_frequency_feasible' : 'insufficient_capacity',
    );

    if (feasible) {
      return terminal;
    }

    final blocking =
        '[V3][P0.2][INFEASIBLE] muscle="$muscle" '
        'target=$targetSets exceeds maxAssignable=${terminal.maxAssignable} '
        '(baseFreq=$safeBase, finalFreq=${terminal.finalFrequency}, '
        'effectiveFreq=${terminal.effectiveFrequency}, dailyCap=$dailyCap'
        '${errorContext.isNotEmpty ? ', context=$errorContext' : ''}).';

    return FrequencyFeasibilityResult(
      muscle: terminal.muscle,
      targetSets: terminal.targetSets,
      baseFrequency: terminal.baseFrequency,
      finalFrequency: terminal.finalFrequency,
      effectiveFrequency: terminal.effectiveFrequency,
      dailyCap: terminal.dailyCap,
      maxAssignable: terminal.maxAssignable,
      wasAdjusted: terminal.wasAdjusted,
      isFeasible: false,
      reason: terminal.reason,
      blockingError: blocking,
    );
  }
}
