import 'package:equatable/equatable.dart';

/// Registra las decisiones tomadas por el motor de entrenamiento para trazabilidad.
///
/// Cada fase del motor debe registrar sus decisiones y razonamiento
/// para permitir auditoría, depuración y mejora continua del sistema.
class DecisionTrace extends Equatable {
  /// Fase del motor que generó esta decisión (ej: "Phase1DataIngestion", "Phase2Readiness")
  final String phase;

  /// Timestamp de la decisión
  final DateTime timestamp;

  /// Categoría de la decisión (ej: "data_validation", "volume_adjustment", "safety_limit")
  final String category;

  /// Descripción legible de la decisión tomada
  final String description;

  /// Severidad o nivel de importancia: "info", "warning", "critical"
  final String severity;

  /// Datos contextuales adicionales en formato clave-valor
  final Map<String, dynamic> context;

  /// Acción tomada o recomendación resultante
  final String? action;

  const DecisionTrace({
    required this.phase,
    required this.timestamp,
    required this.category,
    required this.description,
    this.severity = 'info',
    this.context = const {},
    this.action,
  });

  /// Constructor para decisiones informativas
  factory DecisionTrace.info({
    required String phase,
    required String category,
    required String description,
    Map<String, dynamic> context = const {},
    String? action,
    DateTime? timestamp,
  }) {
    return DecisionTrace(
      phase: phase,
      timestamp: timestamp ?? DateTime(2025, 1, 1), // Fallback determinista
      category: category,
      description: description,
      severity: 'info',
      context: context,
      action: action,
    );
  }

  /// Constructor para advertencias (situaciones que requieren ajustes)
  factory DecisionTrace.warning({
    required String phase,
    required String category,
    required String description,
    Map<String, dynamic> context = const {},
    String? action,
    DateTime? timestamp,
  }) {
    return DecisionTrace(
      phase: phase,
      timestamp: timestamp ?? DateTime(2025, 1, 1), // Fallback determinista
      category: category,
      description: description,
      severity: 'warning',
      context: context,
      action: action,
    );
  }

  /// Constructor para situaciones críticas (límites de seguridad)
  factory DecisionTrace.critical({
    required String phase,
    required String category,
    required String description,
    Map<String, dynamic> context = const {},
    String? action,
    DateTime? timestamp,
  }) {
    return DecisionTrace(
      phase: phase,
      timestamp: timestamp ?? DateTime(2025, 1, 1), // Fallback determinista
      category: category,
      description: description,
      severity: 'critical',
      context: context,
      action: action,
    );
  }

  bool get isWarning => severity == 'warning';
  bool get isCritical => severity == 'critical';
  bool get isInfo => severity == 'info';

  DecisionTrace copyWith({
    String? phase,
    DateTime? timestamp,
    String? category,
    String? description,
    String? severity,
    Map<String, dynamic>? context,
    String? action,
  }) {
    return DecisionTrace(
      phase: phase ?? this.phase,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      context: context ?? this.context,
      action: action ?? this.action,
    );
  }

  Map<String, dynamic> toJson() => {
    'phase': phase,
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'description': description,
    'severity': severity,
    'context': context,
    'action': action,
  };

  factory DecisionTrace.fromJson(Map<String, dynamic> json) {
    return DecisionTrace(
      phase: json['phase'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      context: (json['context'] as Map<String, dynamic>?) ?? {},
      action: json['action'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    timestamp,
    category,
    description,
    severity,
    context,
    action,
  ];

  @override
  String toString() {
    return '[$severity] $phase/$category: $description ${action != null ? "→ $action" : ""}';
  }
}
