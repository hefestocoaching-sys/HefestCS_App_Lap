import 'package:hcs_app_lap/domain/entities/client.dart';

class TrainingEvidence {
  final Map<String, double> observedMev;
  final Map<String, double> observedMrv;
  final double evidenceStrength; // 0..1

  const TrainingEvidence({
    required this.observedMev,
    required this.observedMrv,
    required this.evidenceStrength,
  });
}

class TrainingEvidenceExtractor {
  /// En v1: evidencia conservadora basada en adherencia + estabilidad de rendimiento.
  /// En tu v2 real, esto se alimenta de effectiveSetsByMuscle, deload signals, regresión, dolor, etc.
  TrainingEvidence extractFromClient({
    required Client client,
    required Map<String, double> currentMevByMuscle,
    required Map<String, double> currentMrvByMuscle,
  }) {
    // Señales mínimas disponibles en el ZIP: logs/sessions.
    final totalSessions = client.trainingSessions.length;
    final totalLogs = client.trainingLogs.length;

    // Heurística robusta: si no hay bitácora, evidencia baja.
    final baseStrength =
        _clamp((totalSessions / 12.0), 0.0, 1.0) * 0.60 +
        _clamp((totalLogs / 250.0), 0.0, 1.0) * 0.40;

    // En esta primera iteración, usamos el cálculo actual como observación.
    // Lo "probabilístico" vive en el posterior (suaviza, da incertidumbre, y evita saltos).
    return TrainingEvidence(
      observedMev: currentMevByMuscle,
      observedMrv: currentMrvByMuscle,
      evidenceStrength: _clamp(baseStrength, 0.0, 1.0),
    );
  }

  double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}
