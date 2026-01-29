import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart'
    as legacy;
import 'package:hcs_app_lap/domain/services/v2/longitudinal_state_update_service.dart';
import 'package:hcs_app_lap/domain/services/v2/training_evidence_extractor.dart';

class TrainingEngineV2Result {
  final Client updatedClient;
  final AthleteLongitudinalState updatedState;

  const TrainingEngineV2Result({
    required this.updatedClient,
    required this.updatedState,
  });
}

class TrainingEngineV2 {
  final legacy.TrainingProgramEngine _engine = legacy.TrainingProgramEngine();
  final TrainingEvidenceExtractor _evidenceExtractor =
      TrainingEvidenceExtractor();
  final LongitudinalStateUpdateService _updateService =
      LongitudinalStateUpdateService();

  /// Ejecuta:
  /// (A) motor determinístico (tus 8 fases actuales, estabilizadas)
  /// (B) extrae evidencia de bitácora
  /// (C) actualiza estado longitudinal (sin IA)
  /// (D) persiste el estado en training.extra
  TrainingEngineV2Result generate({
    required Client client,
    DateTime? startDate,
  }) {
    startDate ??= DateTime.now();

    // 1) prior longitudinal state
    final prior = AthleteLongitudinalState.fromExtra(
      client.training.extra,
      startDate,
    );

    // 2) ejecutar motor determinista actual (8 fases ya existentes)
    final plan = _engine.generatePlan(
      planId: 'auto_plan_${startDate.millisecondsSinceEpoch}',
      clientId: client.id,
      planName: 'Auto-generated Plan',
      startDate: startDate,
      profile: client.training,
      history: client.trainingHistory,
      logs: const [],
      latestFeedback: null,
      client: client,
    );

    // 3) leer observaciones actuales desde el plan
    final snapshot = plan.trainingProfileSnapshot;
    if (snapshot == null) {
      // Fallback: si no hay snapshot, no actualizamos
      return TrainingEngineV2Result(updatedClient: client, updatedState: prior);
    }

    final extra = snapshot.extra;
    final mevByMuscle = _readDoubleMap(extra['mevByMuscle']);
    final mrvByMuscle = _readDoubleMap(extra['mrvByMuscle']);

    // 4) evidencia (bitácora del cliente)
    final evidence = _evidenceExtractor.extractFromClient(
      client: client,
      currentMevByMuscle: mevByMuscle,
      currentMrvByMuscle: mrvByMuscle,
    );

    // 5) update posterior
    final posterior = _updateService.update(
      prior: prior,
      observedMev: evidence.observedMev,
      observedMrv: evidence.observedMrv,
      evidenceStrength: evidence.evidenceStrength,
      now: startDate,
    );

    // 6) persistir posterior en extra + actualizar client
    final mergedExtra = <String, dynamic>{...extra};
    mergedExtra['athleteLongitudinalState'] = posterior.toExtraValue();
    mergedExtra['athleteEvidenceStrength'] = evidence.evidenceStrength;

    final updatedProfile = client.training.copyWith(extra: mergedExtra);

    final finalClient = client.copyWith(training: updatedProfile);

    return TrainingEngineV2Result(
      updatedClient: finalClient,
      updatedState: posterior,
    );
  }

  Map<String, double> _readDoubleMap(dynamic raw) {
    if (raw is! Map) {
      return {};
    }
    final out = <String, double>{};
    for (final e in raw.entries) {
      final k = e.key.toString();
      final v = e.value;
      if (v is num) {
        out[k] = v.toDouble();
      } else {
        out[k] = double.tryParse('$v') ?? 0.0;
      }
    }
    return out;
  }
}
