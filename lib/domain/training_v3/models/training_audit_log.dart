import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_audit_log.freezed.dart';
part 'training_audit_log.g.dart';

/// Entrada del log de AUDITORÍA - registro completo de decisiones
///
/// PROPÓSITO:
/// - Trazabilidad total: quién decidió qué y cuándo
/// - Detectar patrones para ML/IA
/// - Coach puede ver histórico completo y auditar
/// - Exportable para análisis
///
/// EJEMPLOS DE ENTRADAS:
/// 1. "PLAN_GENERATED": Motor V3 generó plan inicial
/// 2. "WEEKLY_PROGRESSION": Procesó progresión semanal
/// 3. "FEEDBACK_SUBMITTED": Usuario envió feedback
/// 4. "VOLUME_ADJUSTED": Motor cambió volumen
/// 5. "DELOAD_TRIGGERED": Deload automático o manual
/// 6. "VMR_DISCOVERED": Encontróó MRV empíricamente
/// 7. "VALIDATION_FAILED": Validación falló, requiere intervención
/// 8. "COACH_OVERRIDE": Coach sobrescribió decisión
/// 9. "EXPORT_INITIATED": Se exportó historial
///
/// VERSIÓN: 1.0.0
@freezed
abstract class TrainingAuditLogEntry with _$TrainingAuditLogEntry {
  const factory TrainingAuditLogEntry({
    /// Identificadores
    required String userId,
    required String eventType, // Ver enum abajo
    @Default(null) String? muscleAffected, // null si es a nivel usuario
    required int weekNumber,

    /// QUÉ pasó
    required String title, // Título breve del evento
    required String description, // Descripción detallada
    required String severity, // 'info', 'warning', 'error', 'critical'
    /// DATOS de la decisión
    @Default(null) int? volumeBefore, // Volumen anterior
    @Default(null) int? volumeAfter, // Volumen nuevo
    @Default(null) String? decisionReason, // Por qué se tomó
    @Default(null)
    String? feedbackContext, // Contexto de feedback que llevó a esto
    /// QUIÉN lo hizo
    required String actorType, // 'motor'|'user'|'system'|'coach'
    @Default('')
    String actorDetails, // ID del coach si aplica, versión del motor, etc.
    /// Validación
    required bool isValid, // ¿Pasó validación?
    @Default([])
    List<String> validationErrors, // Errores de validación si aplica
    /// Metadata
    required DateTime timestamp,
    @Default({})
    Map<String, dynamic> metadata, // Datos extras (lineage, calculations, etc.)
    /// Linkage a otros registros
    @Default(null)
    String? linkedToProgressRecordId, // ID de ProgressRecord si aplica
    @Default(null)
    String? linkedToFeedbackEntryId, // ID de FeedbackEntry si aplica
    @Default(null)
    String? linkedToPreviousLogId, // Log anterior del mismo músculo
  }) = _TrainingAuditLogEntry;

  factory TrainingAuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$TrainingAuditLogEntryFromJson(json);
}

/// Tipos de eventos de auditoría
class AuditEventType {
  static const String planGenerated = 'PLAN_GENERATED';
  static const String weeklyProgression = 'WEEKLY_PROGRESSION';
  static const String feedbackSubmitted = 'FEEDBACK_SUBMITTED';
  static const String volumeAdjusted = 'VOLUME_ADJUSTED';
  static const String deloadTriggered = 'DELOAD_TRIGGERED';
  static const String vmrDiscovered = 'VMR_DISCOVERED';
  static const String phaseTransition = 'PHASE_TRANSITION';
  static const String validationFailed = 'VALIDATION_FAILED';
  static const String coachOverride = 'COACH_OVERRIDE';
  static const String exportInitiated = 'EXPORT_INITIATED';
  static const String microdeloadScheduled = 'MICRODELOAD_SCHEDULED';
  static const String anomalyDetected = 'ANOMALY_DETECTED';

  static const List<String> allTypes = [
    planGenerated,
    weeklyProgression,
    feedbackSubmitted,
    volumeAdjusted,
    deloadTriggered,
    vmrDiscovered,
    phaseTransition,
    validationFailed,
    coachOverride,
    exportInitiated,
    microdeloadScheduled,
    anomalyDetected,
  ];
}

/// Utilidades para TrainingAuditLog
extension TrainingAuditLogEntryExtension on TrainingAuditLogEntry {
  /// ¿Es grave (error o critical)?
  bool get isGrave => severity == 'error' || severity == 'critical';

  /// ¿Requiere intervención (validación fallida)?
  bool get requiresIntervention => !isValid || isGrave;

  /// Cambio de volumen en %
  double? get volumeChangePercent {
    if (volumeBefore == null || volumeAfter == null) return null;
    if (volumeBefore == 0) return 0.0;
    return ((volumeAfter! - volumeBefore!) / volumeBefore!) * 100;
  }

  /// formatted timestamp
  String get formattedTime => timestamp.toLocal().toString().split('.').first;

  /// Display string para UI
  String get displayString {
    final muscle = muscleAffected ?? 'SYSTEM';
    final change = volumeChangePercent;
    final changeStr = change != null
        ? ' (${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%)'
        : '';

    return '[$formattedTime] $title ($actor) $muscle$changeStr';
  }

  /// Actor readable
  String get actor {
    if (actorType == 'coach') return '👨‍🏫 Coach';
    if (actorType == 'user') return '👤 User';
    if (actorType == 'motor') return '⚙️ Motor V3';
    if (actorType == 'system') return '🖥️ System';
    return actorType;
  }

  /// Severity icon
  String get severityIcon {
    if (severity == 'info') return 'ℹ️';
    if (severity == 'warning') return '⚠️';
    if (severity == 'error') return '❌';
    if (severity == 'critical') return '🚨';
    return '•';
  }
}

/// Filtros para queries
class TrainingAuditLogFilter {
  final String? userId;
  final String? muscleAffected;
  final String? eventType;
  final String? actorType;
  final String? severity;
  final bool? onlyInvalid;
  final DateTime? fromDate;
  final DateTime? toDate;

  const TrainingAuditLogFilter({
    this.userId,
    this.muscleAffected,
    this.eventType,
    this.actorType,
    this.severity,
    this.onlyInvalid,
    this.fromDate,
    this.toDate,
  });

  /// Aplicar filtro a una entrada
  bool matches(TrainingAuditLogEntry entry) {
    if (userId != null && entry.userId != userId) return false;
    if (muscleAffected != null && entry.muscleAffected != muscleAffected) {
      return false;
    }
    if (eventType != null && entry.eventType != eventType) return false;
    if (actorType != null && entry.actorType != actorType) return false;
    if (severity != null && entry.severity != severity) return false;
    if (onlyInvalid == true && entry.isValid) return false;
    if (fromDate != null && entry.timestamp.isBefore(fromDate!)) return false;
    if (toDate != null && entry.timestamp.isAfter(toDate!)) return false;

    return true;
  }
}
