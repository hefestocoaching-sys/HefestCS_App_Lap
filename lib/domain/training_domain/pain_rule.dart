enum InjuryRegion { shoulder, elbow, wrist, hip, knee, ankle, lowBack, neck }

enum MovementPattern {
  overheadPressing,
  shoulderAbductionElevation,
  horizontalPressing,
  verticalPulling,
  horizontalPulling,
  hipHinge,
  deepKneeFlexion,
  spinalFlexion,
  spinalExtension,
}

class PainRule {
  final InjuryRegion region;
  final MovementPattern pattern;
  final int severity; // 0-3
  final bool avoid;

  const PainRule({
    required this.region,
    required this.pattern,
    required this.severity,
    required this.avoid,
  });

  Map<String, dynamic> toJson() {
    return {
      'region': region.name,
      'pattern': pattern.name,
      'severity': severity,
      'avoid': avoid,
    };
  }

  factory PainRule.fromJson(Map<String, dynamic> json) {
    return PainRule(
      region: InjuryRegion.values.firstWhere(
        (e) => e.name == (json['region'] ?? ''),
        orElse: () => InjuryRegion.shoulder,
      ),
      pattern: MovementPattern.values.firstWhere(
        (e) => e.name == (json['pattern'] ?? ''),
        orElse: () => MovementPattern.overheadPressing,
      ),
      severity: (json['severity'] as num?)?.toInt() ?? 0,
      avoid: json['avoid'] as bool? ?? false,
    );
  }
}
