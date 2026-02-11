// lib/domain/services/v2/longitudinal_state_update_service.dart
import 'package:flutter/foundation.dart';

/// Capa V2: actualizador longitudinal del estado del cliente.
/// En este momento es una fachada mínima para destrabar compilación.
/// Se implementará a fondo cuando cerremos el pipeline longitudinal.
class LongitudinalStateUpdateService {
  const LongitudinalStateUpdateService();

  /// Aplica una actualización longitudinal a partir de un evento (workout log / check-in / etc.)
  /// Devuelve un "patch" serializable (Map) para persistencia offline-first.
  Map<String, Object?> buildStatePatch({
    required String clientId,
    required DateTime occurredAt,
    required Map<String, Object?> payload,
  }) {
    return <String, Object?>{
      'clientId': clientId,
      'occurredAt': occurredAt.toIso8601String(),
      'payload': payload,
      'schemaVersion': 1,
    };
  }

  void debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[LongitudinalStateUpdateService] $message');
    }
  }
}
