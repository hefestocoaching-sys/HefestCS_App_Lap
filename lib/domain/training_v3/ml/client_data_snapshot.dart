import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_tracking_record.dart';
import 'package:hcs_app_lap/domain/entities/strength_assessment.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/volume_tolerance_profile.dart';

/// Snapshot consolidado de todos los datos del cliente desde múltiples fuentes.
///
/// Esta clase representa la CAPA 0 del Motor V3 Unificado.
/// Consolida datos de:
/// - Client (perfil, historia clínica)
/// - AnthropometryRecord (último registro)
/// - TrainingProfile
/// - SessionLogs (últimas 4-8 semanas)
/// - DailyTracking (últimas 4 semanas)
/// - VolumeToleranceProfile
/// - StrengthAssessment
///
/// VERSION: v1.0.0
/// FECHA: 2 de febrero de 2026
///
/// PROPÓSITO:
/// - Unificar recolección de datos de múltiples fuentes
/// - Servir como input para normalización y enriquecimiento (Capa 1)
/// - Mantener trazabilidad de fuentes de datos
///
/// GARANTÍAS:
/// - Inmutable (Equatable)
/// - Todos los campos son opcionales (datos pueden no existir)
/// - Sin lógica de negocio (solo datos)
class ClientDataSnapshot extends Equatable {
  // =========================================================================
  // IDENTIFICACIÓN
  // =========================================================================

  /// Identificador único del cliente
  final String clientId;

  /// Timestamp de cuando se capturó el snapshot
  final DateTime capturedAt;

  // =========================================================================
  // PERFIL BÁSICO
  // =========================================================================

  /// Perfil del cliente (nombre, email, etc.)
  final ClientProfile? clientProfile;

  /// Perfil de entrenamiento completo
  final TrainingProfile? trainingProfile;

  // =========================================================================
  // ANTROPOMETRÍA
  // =========================================================================

  /// Último registro antropométrico
  /// ⭐ CRÍTICO: Contiene heightCm y weightKg que deben sincronizarse
  final AnthropometryRecord? latestAnthropometry;

  /// Todos los registros antropométricos (para tendencias)
  final List<AnthropometryRecord> anthropometryHistory;

  // =========================================================================
  // TRACKING DIARIO (últimas 4 semanas)
  // =========================================================================

  /// Registros de tracking diario (calorías, sueño, HRV, etc.)
  final List<DailyTrackingRecord> recentDailyTracking;

  // =========================================================================
  // LOGS DE ENTRENAMIENTO (últimas 4-8 semanas)
  // =========================================================================

  /// Logs de sesiones de entrenamiento (V2)
  /// Contiene volumen real ejecutado, RIR, RPE, banderas de fatiga
  final List<TrainingSessionLogV2> recentSessionLogs;

  // =========================================================================
  // FUERZA Y TOLERANCIA
  // =========================================================================

  /// Evaluaciones de fuerza (PRs)
  final List<StrengthAssessment> strengthAssessments;

  /// Perfil de tolerancia al volumen por músculo
  final Map<String, VolumeToleranceProfile> volumeToleranceByMuscle;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  const ClientDataSnapshot({
    required this.clientId,
    required this.capturedAt,
    this.clientProfile,
    this.trainingProfile,
    this.latestAnthropometry,
    this.anthropometryHistory = const [],
    this.recentDailyTracking = const [],
    this.recentSessionLogs = const [],
    this.strengthAssessments = const [],
    this.volumeToleranceByMuscle = const {},
  });

  @override
  List<Object?> get props => [
        clientId,
        capturedAt,
        clientProfile,
        trainingProfile,
        latestAnthropometry,
        anthropometryHistory,
        recentDailyTracking,
        recentSessionLogs,
        strengthAssessments,
        volumeToleranceByMuscle,
      ];

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Indica si hay datos antropométricos disponibles
  bool get hasAnthropometry => latestAnthropometry != null;

  /// Indica si hay datos de tracking disponibles
  bool get hasTracking => recentDailyTracking.isNotEmpty;

  /// Indica si hay logs de sesiones disponibles
  bool get hasSessionLogs => recentSessionLogs.isNotEmpty;

  /// Indica si hay evaluaciones de fuerza disponibles
  bool get hasStrengthData => strengthAssessments.isNotEmpty;

  /// Cuenta de semanas de datos de tracking disponibles
  int get trackingWeeksAvailable {
    if (recentDailyTracking.isEmpty) return 0;
    final oldest = recentDailyTracking.first.date;
    final newest = recentDailyTracking.last.date;
    return newest.difference(oldest).inDays ~/ 7;
  }

  /// Cuenta de semanas de datos de logs de sesiones disponibles
  int get sessionLogsWeeksAvailable {
    if (recentSessionLogs.isEmpty) return 0;
    final oldest = recentSessionLogs.first.sessionDate;
    final newest = recentSessionLogs.last.sessionDate;
    return newest.difference(oldest).inDays ~/ 7;
  }
}
