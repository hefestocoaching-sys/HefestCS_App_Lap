/// Política de fallos: determina si se permite fallo en último set y límites de técnicas de fallo.
class FailurePolicyDecision {
  /// Si se permite fallo muscular en el último set del ejercicio.
  final bool allowFailureOnLastSet;

  /// Número máximo de sets con fallos permitidos en la sesión actual.
  final int maxFailureSetsThisSession;

  /// Razones que justifican la decisión (ej: 'nivel=intermediate', 'fatigue=low').
  final List<String> reasons;

  /// Contexto de debug para auditoría y trazabilidad.
  final Map<String, dynamic> debugContext;

  const FailurePolicyDecision({
    required this.allowFailureOnLastSet,
    required this.maxFailureSetsThisSession,
    required this.reasons,
    required this.debugContext,
  });

  /// Crea una copia con campos opcionales reemplazados.
  FailurePolicyDecision copyWith({
    bool? allowFailureOnLastSet,
    int? maxFailureSetsThisSession,
    List<String>? reasons,
    Map<String, dynamic>? debugContext,
  }) {
    return FailurePolicyDecision(
      allowFailureOnLastSet:
          allowFailureOnLastSet ?? this.allowFailureOnLastSet,
      maxFailureSetsThisSession:
          maxFailureSetsThisSession ?? this.maxFailureSetsThisSession,
      reasons: reasons ?? this.reasons,
      debugContext: debugContext ?? this.debugContext,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
    'allowFailureOnLastSet': allowFailureOnLastSet,
    'maxFailureSetsThisSession': maxFailureSetsThisSession,
    'reasons': reasons,
    'debugContext': debugContext,
  };

  /// Crea desde JSON.
  factory FailurePolicyDecision.fromJson(Map<String, dynamic> json) {
    return FailurePolicyDecision(
      allowFailureOnLastSet: json['allowFailureOnLastSet'] as bool? ?? false,
      maxFailureSetsThisSession: json['maxFailureSetsThisSession'] as int? ?? 0,
      reasons:
          (json['reasons'] as List<dynamic>?)?.cast<String>().toList() ??
          const [],
      debugContext: (json['debugContext'] as Map<String, dynamic>?) ?? {},
    );
  }

  @override
  String toString() =>
      'FailurePolicyDecision(allowFailure=$allowFailureOnLastSet, '
      'maxFailureSets=$maxFailureSetsThisSession, '
      'reasons=$reasons)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailurePolicyDecision &&
          runtimeType == other.runtimeType &&
          allowFailureOnLastSet == other.allowFailureOnLastSet &&
          maxFailureSetsThisSession == other.maxFailureSetsThisSession &&
          reasons == other.reasons &&
          debugContext == other.debugContext;

  @override
  int get hashCode => Object.hash(
    allowFailureOnLastSet,
    maxFailureSetsThisSession,
    reasons,
    debugContext,
  );
}
