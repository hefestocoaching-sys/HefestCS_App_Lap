import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_tracking_record.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/client_data_snapshot.dart';

/// Recolector unificado de datos del cliente desde múltiples fuentes.
///
/// Esta clase implementa la CAPA 0 del Motor V3 Unificado.
///
/// VERSION: v1.0.0
/// FECHA: 2 de febrero de 2026
///
/// PROPÓSITO:
/// - Consolidar datos de múltiples fuentes en un solo snapshot
/// - Filtrar datos por ventanas temporales relevantes
/// - Servir como punto de entrada único para normalización
///
/// FUENTES DE DATOS:
/// 1. Client.profile → ClientProfile
/// 2. Client.training → TrainingProfile
/// 3. Client.anthropometry → AnthropometryRecord (último + historial)
/// 4. Client.tracking → DailyTrackingRecord (últimas 4 semanas)
/// 5. Client.sessionLogs → TrainingSessionLogV2 (últimas 4-8 semanas)
/// 6. Client.strengthAssessments → StrengthAssessment
/// 7. Client.training.pastVolumeTolerance → VolumeToleranceProfile
///
/// USO:
/// ```dart
/// final collector = UnifiedDataCollector();
/// final snapshot = await collector.collectClientData('client123');
/// // snapshot contiene todos los datos consolidados
/// ```
class UnifiedDataCollector {
  /// Ventana temporal para datos de tracking diario (días)
  static const int trackingWindowDays = 28; // 4 semanas

  /// Ventana temporal para logs de sesiones (días)
  static const int sessionLogsWindowDays = 56; // 8 semanas

  /// Recolecta todos los datos del cliente en un snapshot unificado.
  ///
  /// PARÁMETROS:
  /// - [client]: Cliente del cual recolectar datos
  /// - [asOfDate]: Fecha opcional de referencia (default: ahora)
  ///
  /// RETORNA:
  /// - [ClientDataSnapshot] con todos los datos consolidados
  ///
  /// LÓGICA:
  /// 1. Extrae último registro antropométrico
  /// 2. Filtra tracking diario por ventana temporal (4 semanas)
  /// 3. Filtra logs de sesiones por ventana temporal (8 semanas)
  /// 4. Extrae evaluaciones de fuerza
  /// 5. Extrae perfiles de tolerancia al volumen
  ///
  /// DETERMINISTA: Mismos inputs → mismo output
  /// SIN SIDE EFFECTS: No modifica el cliente
  static Future<ClientDataSnapshot> collectClientData(
    Client client, {
    DateTime? asOfDate,
  }) async {
    final now = asOfDate ?? DateTime.now();

    // 1. Antropometría: último registro
    final latestAnthro = _getLatestAnthropometry(client.anthropometry);

    // 2. Tracking diario: últimas 4 semanas
    final recentTracking = _filterRecentTracking(
      client.tracking,
      now,
      trackingWindowDays,
    );

    // 3. Session logs: últimas 8 semanas (usar sessionLogs V2)
    final recentLogs = _filterRecentSessionLogsV2(
      client.sessionLogs,
      now,
      sessionLogsWindowDays,
    );

    // 4. Strength assessments
    final strengthData = client.strengthAssessments;

    // 5. Volume tolerance profiles
    final volumeTolerance = client.training.pastVolumeTolerance;

    return ClientDataSnapshot(
      clientId: client.id,
      capturedAt: now,
      clientProfile: client.profile,
      trainingProfile: client.training,
      latestAnthropometry: latestAnthro,
      anthropometryHistory: client.anthropometry,
      recentDailyTracking: recentTracking,
      recentSessionLogs: recentLogs,
      strengthAssessments: strengthData,
      volumeToleranceByMuscle: volumeTolerance,
    );
  }

  // =========================================================================
  // HELPERS PRIVADOS
  // =========================================================================

  /// Obtiene el último registro antropométrico por fecha
  static AnthropometryRecord? _getLatestAnthropometry(
    List<AnthropometryRecord> records,
  ) {
    if (records.isEmpty) return null;

    // Ordenar por fecha descendente y retornar el primero
    final sorted = List<AnthropometryRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sorted.first;
  }

  /// Filtra registros de tracking diario por ventana temporal
  static List<DailyTrackingRecord> _filterRecentTracking(
    List<DailyTrackingRecord> records,
    DateTime referenceDate,
    int windowDays,
  ) {
    final cutoffDate = referenceDate.subtract(Duration(days: windowDays));

    return records
        .where((record) => record.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Ordenar ascendente
  }

  /// Filtra logs de sesiones V2 por ventana temporal
  static List<TrainingSessionLogV2> _filterRecentSessionLogsV2(
    List<SessionSummaryLog> sessionSummaryLogs,
    DateTime referenceDate,
    int windowDays,
  ) {
    // NOTA: La entidad Client tiene sessionLogs de tipo SessionSummaryLog
    // pero necesitamos TrainingSessionLogV2 para ML.
    // 
    // Por ahora, retornamos lista vacía hasta que se implemente
    // la conversión o se almacenen TrainingSessionLogV2 en Client.
    //
    // TODO: Implementar conversión SessionSummaryLog → TrainingSessionLogV2
    // o almacenar TrainingSessionLogV2 directamente en Client
    
    return [];
  }
}
