import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/progress_record.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';

/// Enhanced WeeklyProgressionService con auditoría, validación, y lógica P/S/T explícita
///
/// MEJORAS RESPECTO A LA VERSIÓN ANTERIOR:
/// 1. ✅ Lógica explícita de PRIORIDAD (P/S/T) con topes distintos
/// 2. ✅ Manejo de DELOAD por bitácora vs automático
/// 3. ✅ Auditoría completa (cada decisión registrada)
/// 4. ✅ Validación QA previa y posterior
/// 5. ✅ Cobertura angular tracking
/// 6. ✅ ProgressRecord historial detallado
/// 7. ✅ FeedbackEntry para feedback separado
/// 8. ✅ Exportación de datos para IA/coach
///
/// VERSION: 2.0.0 (Enhanced)
abstract class WeeklyProgressionServiceEnhanced {
  /// Procesa progresión semanal completa para todos los músc (ENHANCED)
  ///
  /// WORKFLOW MEJORADO:
  /// 1. Validate input
  /// 2. Load pre-state (trackers, history)
  /// 3. Para cada músculo:
  ///    a. Process feedback (FeedbackEntry)
  ///    b. Analyze performance (objective data + subjective)
  ///    c. Determine action by PRIORITY:
  ///       - PRIMARY (5): Progress to MRV, deload if needed
  ///       - SECONDARY (3): Progress to 0.8×MRV, deload if needed
  ///       - TERTIARY (1): Always VOP
  ///    d. Validate decision (TrainingValidationEngine)
  ///    e. Create ProgressRecord (historial detallado)
  ///    f. Log audit entry (TrainingAuditLog)
  ///    g. Update tracker
  /// 4. Post-week validation (auditoría semanal completa)
  /// 5. Return decisions + audit report
  ///
  /// RETORNA:
  /// - `Map<String, MuscleDecision>` con decisiones por músculo
  ///  - Metadata con audit report
  ///
  /// REQUERIMIENTOS:
  /// - userId válido
  /// - Trackers ya inicializados
  /// - Logs de ejercicio del ejercicios de la semana
  /// - Feedback del usuario (pueden ser parciales)
  ///
  /// THROWS:
  /// - ArgumentError si datos inválidos
  /// - StateError si trackers no existen
  Future<EnhancedProgressionResult> processWeeklyProgressionEnhanced({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, FeedbackEntry> feedbackByMuscle,
  });

  /// Procesa progresión para UN MÚSCULO (granular)
  ///
  /// LÓGICA DE PRIORIDAD:
  ///
  /// PRIMARY (Priority 5):
  /// - Target: MRV (Maximum Recoverable Volume)
  /// - Can increment: +2 sets/week até reaching MRV
  /// - Deload: After 4-5 weeks IF: high fatigue OR poor recovery OR manual request
  /// - Deload volume: -50% (to below VOP)
  /// - Recovery: Full reset to discovering phase
  ///
  /// SECONDARY (Priority 3):
  /// - Target: 0.8×MRV
  /// - Can increment: +1 set/week until 0.8×MRV
  /// - Deload: After 5-6 weeks IF: high fatigue OR poor recovery OR manual request
  /// - Deload volume: -40% (but ≥ VOP)
  /// - Recovery: Normal progression rules apply
  ///
  /// TERTIARY (Priority 1):
  /// - Target: VOP ALWAYS
  /// - Cannot increment or decrement
  /// - No deload (always maintain VOP)
  /// - Feedback ignored (fixed prescription)
  ///
  /// FEEDBACK OVERRIDE:
  /// - If deloadRequested == true: Apply deload immediately
  /// - If fatigueLevel >= 8.0: May trigger deload
  /// - If recoveryQuality <= 4.0: May trigger deload
  ///
  /// RETORNA:
  /// - MuscleDecision con nueva programación
  /// - ProgressRecord con historial detallado
  /// - TrainingAuditLogEntry con trazabildad
  Future<EnhancedMuscleDDecisionResult> processMuscleProgressionEnhanced({
    required String userId,
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required FeedbackEntry feedback,
    required MuscleProgressionTracker currentTracker,
  });

  /// Get audit trail para una semana
  Future<List<TrainingAuditLogEntry>> getWeeklyAuditTrail({
    required String userId,
    required int weekNumber,
  });

  /// Exportar histórico completo (para coach/IA)
  Future<String> exportTrainingHistory({
    required String userId,
    int? fromWeek,
    int? toWeek,
    String format = 'json', // 'json'|'csv'|'pdf'
  });
}

/// Resultado mejorado de progresión semanal
class EnhancedProgressionResult {
  final Map<String, MuscleDecision> decisions;
  final Map<String, ProgressRecord> progressRecords;
  final List<TrainingAuditLogEntry> auditTrail;
  final String auditReport;
  final bool allValid;
  final List<String> requiresCoachAttention;

  const EnhancedProgressionResult({
    required this.decisions,
    required this.progressRecords,
    required this.auditTrail,
    required this.auditReport,
    required this.allValid,
    required this.requiresCoachAttention,
  });
}

/// Resultado de decisión de un músculo (enhanced)
class EnhancedMuscleDDecisionResult {
  final MuscleDecision decision;
  final ProgressRecord progressRecord;
  final TrainingAuditLogEntry auditEntry;
  final bool isValid;
  final List<String> validationWarnings;

  const EnhancedMuscleDDecisionResult({
    required this.decision,
    required this.progressRecord,
    required this.auditEntry,
    required this.isValid,
    required this.validationWarnings,
  });
}
