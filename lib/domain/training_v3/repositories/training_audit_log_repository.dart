import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';

/// Repositorio para logs de auditoría de entrenamiento.
///
/// Responsabilidades:
/// - Guardar eventos de auditoría (decisiones, cambios, validaciones).
/// - Recuperar historial de auditoría por usuario/semana.
abstract class TrainingAuditLogRepository {
  /// Guarda una entrada de auditoría.
  ///
  /// Persistencia: users/{userId}/audit_logs/{logId}
  Future<void> saveLogEntry(TrainingAuditLogEntry entry);

  /// Recupera logs de auditoría para una semana específica.
  Future<List<TrainingAuditLogEntry>> getLogsForWeek({
    required String userId,
    required int weekNumber,
  });

  /// Recupera logs de auditoría para un músculo específico.
  Future<List<TrainingAuditLogEntry>> getLogsForMuscle({
    required String userId,
    required String muscle,
    int limit = 20,
  });
}
