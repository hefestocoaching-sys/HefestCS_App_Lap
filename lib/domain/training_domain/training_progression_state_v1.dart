class TrainingProgressionStateV1 {
  final int weeksCompleted;
  final int sessionsCompleted;
  final int consecutiveWeeksTraining;

  final double averageRIR;
  final double averageSessionRPE;
  final double perceivedRecovery;

  final String lastPlanId;
  final String lastPlanChangeReason;

  const TrainingProgressionStateV1({
    required this.weeksCompleted,
    required this.sessionsCompleted,
    required this.consecutiveWeeksTraining,
    required this.averageRIR,
    required this.averageSessionRPE,
    required this.perceivedRecovery,
    required this.lastPlanId,
    required this.lastPlanChangeReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'weeksCompleted': weeksCompleted,
      'sessionsCompleted': sessionsCompleted,
      'consecutiveWeeksTraining': consecutiveWeeksTraining,
      'averageRIR': averageRIR,
      'averageSessionRPE': averageSessionRPE,
      'perceivedRecovery': perceivedRecovery,
      'lastPlanId': lastPlanId,
      'lastPlanChangeReason': lastPlanChangeReason,
    };
  }

  factory TrainingProgressionStateV1.fromJson(Map<String, dynamic> json) {
    return TrainingProgressionStateV1(
      weeksCompleted: (json['weeksCompleted'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (json['sessionsCompleted'] as num?)?.toInt() ?? 0,
      consecutiveWeeksTraining:
          (json['consecutiveWeeksTraining'] as num?)?.toInt() ?? 0,
      averageRIR: (json['averageRIR'] as num?)?.toDouble() ?? 0.0,
      averageSessionRPE: (json['averageSessionRPE'] as num?)?.toDouble() ?? 0.0,
      perceivedRecovery: (json['perceivedRecovery'] as num?)?.toDouble() ?? 0.0,
      lastPlanId: json['lastPlanId']?.toString() ?? '',
      lastPlanChangeReason: json['lastPlanChangeReason']?.toString() ?? '',
    );
  }
}
