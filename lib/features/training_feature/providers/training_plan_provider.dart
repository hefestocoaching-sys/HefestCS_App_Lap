// ignore_for_file: unused_element, dead_code

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/generated_plan.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_evaluation.dart';
import 'package:hcs_app_lap/domain/entities/training_plan.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/exceptions/training_plan_blocked_exception.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';
import 'package:hcs_app_lap/domain/training/models/mev_table.dart';
import 'package:hcs_app_lap/domain/training/validation/vop_validator.dart';
import 'package:hcs_app_lap/domain/training/utils/frequency_inference.dart';
// Legacy UI compatibility imports
import 'package:hcs_app_lap/domain/services/training_plan_mapper.dart';
import 'package:hcs_app_lap/data/datasources/local/exercise_catalog_loader.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/data/repositories/training/training_cycle_repository_impl.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
// ✅ MOTOR V3 REAL - PIPELINE CIENTÍFICO COMPLETO
import 'package:hcs_app_lap/domain/training_v3/orchestrator/training_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/deload_trigger_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/workout_log_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/intensity_split.dart';
import 'package:hcs_app_lap/domain/training_domain/training_evaluation_snapshot_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_progression_state_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_plan_governor.dart';
import 'package:hcs_app_lap/domain/training_domain/training_ssot_v1_service.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
// VopSnapshot SSOT
import 'package:hcs_app_lap/domain/training/vop_snapshot.dart';
import 'package:hcs_app_lap/features/training_feature/context/vop_context.dart';
import 'package:hcs_app_lap/features/training_feature/domain/intensity_distribution_helper.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_pipeline_guard.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training/services/active_cycle_bootstrapper.dart';
import 'package:hcs_app_lap/domain/training/services/training_week_evaluator.dart';
import 'package:hcs_app_lap/domain/training/services/weekly_decision.dart';

/// Estado inmutable para el plan de entrenamiento
/// PARTE 3 A6: Incluye vopByMuscle como SSOT para que UI y motor usen la misma fuente
class TrainingPlanState {
  final bool isLoading;
  final String? error;
  final String? blockReason;
  final List<String>? suggestions;
  final GeneratedPlan? plan;
  final List<String> missingFields;

  /// PARTE 3 A6: VOP Map como SSOT (claves canónicas, valores en series/semana)
  /// Motor V3 usa este mismo Map sin copias
  final Map<String, int> vopByMuscle;

  const TrainingPlanState({
    this.isLoading = false,
    this.error,
    this.blockReason,
    this.suggestions,
    this.plan,
    this.missingFields = const [],
    this.vopByMuscle = const {},
  });

  bool get isBlocked => blockReason != null;

  TrainingPlanState copyWith({
    bool? isLoading,
    String? error,
    String? blockReason,
    List<String>? suggestions,
    GeneratedPlan? plan,
    List<String>? missingFields,
    Map<String, int>? vopByMuscle,
  }) {
    return TrainingPlanState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      blockReason: blockReason,
      suggestions: suggestions,
      plan: plan ?? this.plan,
      missingFields: missingFields ?? this.missingFields,
      vopByMuscle: vopByMuscle ?? this.vopByMuscle,
    );
  }

  factory TrainingPlanState.blocked({
    required String reason,
    List<String> suggestions = const [],
    List<String> missingFields = const [],
  }) {
    return TrainingPlanState(
      blockReason: reason,
      suggestions: suggestions,
      missingFields: missingFields,
    );
  }
}

/// Notifier: Contiene la lógica de negocio (el "cerebro" del provider)
class TrainingPlanNotifier extends Notifier<TrainingPlanState> {
  @override
  TrainingPlanState build() {
    final clientsAsync = ref.watch(clientsProvider);
    final client = clientsAsync.value?.activeClient;
    if (client == null) {
      return const TrainingPlanState();
    }

    // PARTE 3 A6: Extraer VOP canónico desde VopContext
    final vopContext = VopContext.ensure(client.training.extra);
    final vopByMuscle = vopContext?.snapshot.setsByMuscle ?? {};

    debugPrint('[VOP][Provider] VOP cargado: ${vopByMuscle.keys.join(", ")}');

    // El plan se guarda en client.trainingPlans (persistencia local vía Client.toJson()).
    // Por defecto, exponer el plan más reciente para que el UI muestre el último registro.
    if (client.trainingPlans.isEmpty) {
      final activeCycle = _findActiveCycle(client);
      if (activeCycle != null &&
          activeCycle.status == 'active' &&
          activeCycle.freezePlanSnapshot.isNotEmpty) {
        final frozenPlan = _generatedPlanFromCycleSnapshot(activeCycle);
        return TrainingPlanState(plan: frozenPlan, vopByMuscle: vopByMuscle);
      }
      return TrainingPlanState(vopByMuscle: vopByMuscle);
    }

    final activeCycle = _findActiveCycle(client);
    if (activeCycle != null &&
        activeCycle.status == 'active' &&
        activeCycle.freezePlanSnapshot.isNotEmpty) {
      final frozenPlan = _generatedPlanFromCycleSnapshot(activeCycle);
      return TrainingPlanState(plan: frozenPlan, vopByMuscle: vopByMuscle);
    }

    final active = _findActivePlanConfigById(client);
    final chosen =
        active ??
        client.trainingPlans.reduce(
          (a, b) => a.startDate.isAfter(b.startDate) ? a : b,
        );

    final derived = TrainingPlanMapper.toGeneratedPlan(chosen);
    return TrainingPlanState(plan: derived, vopByMuscle: vopByMuscle);
  }

  GeneratedPlan? _readPersistedPlan(dynamic raw) {
    if (raw == null) return null;
    if (raw is GeneratedPlan) return raw;
    if (raw is Map<String, dynamic>) return GeneratedPlan.fromMap(raw);
    if (raw is Map) {
      return GeneratedPlan.fromMap(raw.cast<String, dynamic>());
    }
    return null;
  }

  List<Map<String, dynamic>> _readPlanRecords(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (record) =>
              record.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  Map<String, dynamic>? _recordForDate(
    List<Map<String, dynamic>> records,
    String dateIso,
  ) {
    for (final record in records) {
      final recordDate = record[TrainingExtraKeys.forDateIso]?.toString();
      if (recordDate == dateIso) {
        return record;
      }
    }
    return null;
  }

  Map<String, dynamic>? _latestRecordByDate(
    List<Map<String, dynamic>> records,
  ) {
    if (records.isEmpty) return null;
    var latest = records.first;
    var latestDate = latest[TrainingExtraKeys.forDateIso]?.toString() ?? '';
    for (final record in records.skip(1)) {
      final recordDate = record[TrainingExtraKeys.forDateIso]?.toString() ?? '';
      if (recordDate.compareTo(latestDate) > 0) {
        latest = record;
        latestDate = recordDate;
      }
    }
    return latest;
  }

  GeneratedPlan? _planFromRecord(Map<String, dynamic>? record) {
    if (record == null) return null;
    final rawPlan = record[TrainingExtraKeys.generatedPlan];
    return _readPersistedPlan(rawPlan);
  }

  TrainingPlanConfig? _findActivePlanConfigById(Client client) {
    final extra = client.training.extra;
    final raw = extra[TrainingExtraKeys.activePlanId];
    final planId = raw?.toString().trim();
    if (planId == null || planId.isEmpty) return null;

    for (final p in client.trainingPlans) {
      if (p.id == planId) return p;
    }
    return null;
  }

  TrainingPlanConfig? _findLatestPlan(List<TrainingPlanConfig> plans) {
    if (plans.isEmpty) return null;
    return plans.reduce((a, b) => a.startDate.isAfter(b.startDate) ? a : b);
  }

  TrainingCycle? _findCycleById(Client client, String? cycleId) {
    final normalizedId = cycleId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) return null;

    for (final cycle in client.trainingCycles) {
      if (cycle.cycleId == normalizedId) {
        return cycle;
      }
    }
    return null;
  }

  TrainingCycle? _findCycleByStatus(Client client, String status) {
    for (final cycle in client.trainingCycles) {
      if (cycle.status == status) {
        return cycle;
      }
    }
    return null;
  }

  TrainingCycle? _findActiveCycle(Client client) {
    final activeById = _findCycleById(client, client.activeCycleId);
    if (activeById != null) {
      return activeById;
    }

    return _findCycleByStatus(client, 'active');
  }

  TrainingCycle? _findLatestCycle(List<TrainingCycle> cycles) {
    if (cycles.isEmpty) return null;
    return cycles.reduce((a, b) {
      if (a.updatedAt.isAfter(b.updatedAt)) return a;
      if (b.updatedAt.isAfter(a.updatedAt)) return b;
      return a.startDate.isAfter(b.startDate) ? a : b;
    });
  }

  GeneratedPlan _generatedPlanFromCycleSnapshot(TrainingCycle cycle) {
    final snapshot = cycle.freezePlanSnapshot;
    final rawExerciseMap = snapshot['exerciseMapByDay'];

    final aggregated = <String, double>{};
    if (rawExerciseMap is Map) {
      rawExerciseMap.forEach((_, entries) {
        if (entries is! List) return;
        for (final item in entries) {
          if (item is! Map) continue;
          final muscle = item['muscle']?.toString();
          final sets = item['sets'];
          if (muscle == null || muscle.isEmpty || sets is! num) continue;
          aggregated[muscle] = (aggregated[muscle] ?? 0) + sets.toDouble();
        }
      });
    }

    final volumePlan = <String, dynamic>{};
    aggregated.forEach((muscle, sets) {
      volumePlan[muscle] = {
        'heavySets': 0.0,
        'mediumSets': sets,
        'lightSets': 0.0,
      };
    });

    return GeneratedPlan.fromMap({
      'weeks': 4,
      'volumePlan': volumePlan,
      'audit': {
        'engine': 'freezePlanSnapshot',
        'cycleId': cycle.cycleId,
        'splitType': snapshot['splitType'] ?? cycle.splitType,
        'days': snapshot['days'] ?? const [],
        'exerciseMapByDay': snapshot['exerciseMapByDay'] ?? const {},
        'anchorExercises': snapshot['anchorExercises'] ?? const {},
        'caps': snapshot['caps'] ?? const {},
      },
    });
  }

  Map<String, int> _computeVopByMuscleFromPlan(TrainingPlanConfig planConfig) {
    final week = planConfig.weeks.isNotEmpty ? planConfig.weeks.first : null;
    final vopByMuscle = <String, int>{};
    if (week == null) return vopByMuscle;

    for (final session in week.sessions) {
      for (final prescription in session.prescriptions) {
        final muscle = prescription.muscleGroup.name;
        vopByMuscle[muscle] = (vopByMuscle[muscle] ?? 0) + prescription.sets;
      }
    }

    return vopByMuscle;
  }

  Map<String, int> _computeVmrByMuscle({
    required TrainingPlanConfig planConfig,
    required Map<String, int> vopByMuscle,
  }) {
    final extra = planConfig.trainingProfileSnapshot?.extra;
    final rawByRole = extra?['vmrByMuscleRole'];
    final vmr = <String, int>{};

    if (rawByRole is Map) {
      rawByRole.forEach((key, value) {
        if (value is num) {
          vmr[key.toString()] = value.toInt();
        }
      });
    }

    if (vmr.isNotEmpty) return vmr;

    for (final entry in vopByMuscle.entries) {
      vmr[entry.key] = (entry.value * 0.7).round().clamp(1, 999);
    }
    return vmr;
  }

  Map<String, dynamic> _buildFreezePlanSnapshot({
    required TrainingPlanConfig planConfig,
    required Map<String, int> vopByMuscle,
    required Map<String, int> vmrByMuscle,
    required int availableDays,
    required int sessionDurationMinutes,
  }) {
    final week = planConfig.weeks.isNotEmpty ? planConfig.weeks.first : null;
    if (week == null) {
      return {
        'schemaVersion': 1,
        'splitType': planConfig.splitId,
        'availableDays': availableDays,
        'sessionDurationMinutes': sessionDurationMinutes,
        'days': const <String>[],
        'exerciseMapByDay': const <String, List<Map<String, dynamic>>>{},
        'anchorExercises': const <String, String>{},
        'caps': {'maxExercisesPerDay': 12, 'vmrByMuscle': vmrByMuscle},
        'vopByMuscle': vopByMuscle,
        'vmrByMuscle': vmrByMuscle,
      };
    }

    final days = <String>[];
    final exerciseMapByDay = <String, List<Map<String, dynamic>>>{};
    final anchorExercises = <String, String>{};

    final sessions = [...week.sessions]
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    for (final session in sessions) {
      final dayKey = session.dayNumber.toString();
      final seenByDay = <String>{};
      final entries = <Map<String, dynamic>>[];
      final orderedPrescriptions = [...session.prescriptions]
        ..sort((a, b) => a.order.compareTo(b.order));

      for (final p in orderedPrescriptions) {
        if (!seenByDay.add(p.exerciseCode)) continue;

        entries.add({
          'exerciseCode': p.exerciseCode,
          'exerciseName': p.exerciseName,
          'muscle': p.muscleGroup.name,
          'order': p.order,
          'sets': p.sets,
          'rir': p.rir,
        });

        anchorExercises.putIfAbsent(p.muscleGroup.name, () => p.exerciseCode);
      }

      exerciseMapByDay[dayKey] = entries;
      days.add(session.sessionName.isNotEmpty ? session.sessionName : dayKey);
    }

    return {
      'schemaVersion': 1,
      'splitType': planConfig.splitId,
      'availableDays': availableDays,
      'sessionDurationMinutes': sessionDurationMinutes,
      'days': days,
      'exerciseMapByDay': exerciseMapByDay,
      'anchorExercises': anchorExercises,
      'caps': {'maxExercisesPerDay': 12, 'vmrByMuscle': vmrByMuscle},
      'vopByMuscle': vopByMuscle,
      'vmrByMuscle': vmrByMuscle,
    };
  }

  Map<String, List<String>> _extractBaseExercisesByMuscleFromSnapshot(
    Map<String, dynamic> snapshot,
  ) {
    final raw = snapshot['exerciseMapByDay'];
    final byMuscle = <String, List<String>>{};

    if (raw is Map) {
      raw.forEach((_, entries) {
        if (entries is! List) return;
        for (final item in entries) {
          if (item is! Map) continue;
          final muscle = item['muscle']?.toString();
          final exerciseCode = item['exerciseCode']?.toString();
          if (muscle == null || muscle.isEmpty) continue;
          if (exerciseCode == null || exerciseCode.isEmpty) continue;

          final list = byMuscle.putIfAbsent(muscle, () => <String>[]);
          if (!list.contains(exerciseCode)) {
            list.add(exerciseCode);
          }
        }
      });
    }

    return byMuscle;
  }

  /// Carga el plan persistido (activePlanId o más reciente) sin generar
  ///
  /// REGLAS:
  /// (A) Obtener Client actual desde clientsProvider
  /// (B) Buscar activePlanId en training.extra → si existe y plan encontrado, usar
  /// (C) Si no existe activePlanId, usar plan más reciente por startDate
  /// (D) Si no hay planes, dejar activePlan = null
  /// (E) Actualizar state sin disparar generación
  Future<void> loadPersistedActivePlanIfAny() async {
    try {
      final clientsAsync = ref.read(clientsProvider);
      final client = clientsAsync.value?.activeClient;

      if (client == null) {
        state = const TrainingPlanState();
        return;
      }

      if (client.trainingPlans.isEmpty) {
        final frozenCycle = _findActiveCycle(client);
        if (frozenCycle != null &&
            frozenCycle.status == 'active' &&
            frozenCycle.freezePlanSnapshot.isNotEmpty) {
          state = TrainingPlanState(
            plan: _generatedPlanFromCycleSnapshot(frozenCycle),
          );
          return;
        }
        state = const TrainingPlanState();
        return;
      }

      // (A) Priorizar activePlanId
      final activeConfig = _findActivePlanConfigById(client);
      final chosen = activeConfig ?? _findLatestPlan(client.trainingPlans);

      if (chosen == null) {
        final frozenCycle = _findActiveCycle(client);
        if (frozenCycle != null &&
            frozenCycle.status == 'active' &&
            frozenCycle.freezePlanSnapshot.isNotEmpty) {
          state = TrainingPlanState(
            plan: _generatedPlanFromCycleSnapshot(frozenCycle),
          );
          return;
        }
        state = const TrainingPlanState();
        return;
      }

      final frozenCycle = _findActiveCycle(client);
      final derived =
          (frozenCycle != null &&
              frozenCycle.status == 'active' &&
              frozenCycle.freezePlanSnapshot.isNotEmpty)
          ? _generatedPlanFromCycleSnapshot(frozenCycle)
          : TrainingPlanMapper.toGeneratedPlan(chosen);
      state = TrainingPlanState(plan: derived);
    } catch (e) {
      debugPrint('❌ Error en loadPersistedActivePlanIfAny: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar plan persistido: $e',
      );
    }
  }

  /// Genera un plan basado en MusclePriorities (SSOT) para Motor V3.
  @Deprecated('Usar generatePlanFromActiveCycle como entrada oficial')
  Future<TrainingPlan> generateTrainingPlan({
    required String clientId,
    required TrainingEvaluation evaluation,
  }) async {
    throw StateError(
      'generateTrainingPlan es legacy. Usa generatePlanFromActiveCycle.',
    );
  }

  int _resolveAgeForGenerateTrainingPlan(Client? client) {
    if (client?.training.age != null && client!.training.age! > 0) {
      return client.training.age!;
    }
    if (client?.profile.age != null && client!.profile.age! > 0) {
      return client.profile.age!;
    }
    final raw = client?.training.extra['ageYears'];
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw > 0) return raw.toInt();
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed != null && parsed > 0) return parsed;
    return 30;
  }

  Future<String> _resolvePhase({
    required UserProfile profile,
    required List<WorkoutLog> recentLogs,
    required String plannedPhase,
  }) async {
    if (recentLogs.isEmpty) return plannedPhase;
    final eval = DeloadTriggerEngine.evaluateDeloadNeed(
      recentLogs: recentLogs,
      weeksInProgram: profile.consecutiveWeeks,
    );
    final needs = eval['needs_deload'] as bool;
    final urgency = (eval['urgency'] as String?) ?? '';
    if (needs &&
        (urgency == 'high' ||
            urgency == 'moderate' ||
            urgency == 'urgent' ||
            urgency == 'recommended')) {
      return 'deload';
    }
    return plannedPhase;
  }

  Future<void> _saveEvaluationSnapshot({
    required String clientId,
    required TrainingEvaluationSnapshotV1 snapshot,
  }) async {
    final repo = ref.read(clientRepositoryProvider);
    final client = await repo.getClientById(clientId);
    if (client == null) {
      debugPrint(
        '[TrainingPlanProvider] Snapshot save skipped: client not found ($clientId)',
      );
      return;
    }

    final updatedClient = TrainingSsotV1Service.writeEvaluation(
      client,
      snapshot,
    );
    await repo.saveClient(updatedClient);
  }

  /// Genera un plan basado en el perfil de entrenamiento (usa TrainingProgramEngine 1→8)
  @Deprecated('Usar generatePlanFromActiveCycle como entrada oficial')
  Future<void> generatePlan({
    required TrainingProfile profile,
    String? forDateIso,
    Map<String, Landmarks>? muscleLandmarks,
    IntensitySplit? intensitySplit,
  }) async {
    final activeDateIso =
        forDateIso ?? dateIsoFrom(ref.read(globalDateProvider));
    final selectedDate = tryParseDateTime(activeDateIso) ?? DateTime.now();
    await generatePlanFromActiveCycle(selectedDate);
    return;
  }

  /// Helper: Construye snapshot canónico (int, claves internas).
  VopSnapshot? _buildVopSnapshot({
    required Map<String, int> setsByMuscle,
    required String source,
  }) {
    if (setsByMuscle.isEmpty) return null;

    return VopSnapshot(
      setsByMuscle: setsByMuscle,
      updatedAt: DateTime.now(),
      source: source,
    );
  }

  String _resolvePhaseForWeek({required int weekNumber}) {
    if (weekNumber <= 3) return 'adaptation';
    if (weekNumber % 5 == 0) return 'deload';
    return 'accumulation';
  }

  Future<void> _persistWeeklyDecisionArtifact({
    required String clientId,
    required TrainingCycle cycle,
    required int weekNumber,
    required String phase,
    WeeklyLogSnapshot? logSnapshot,
  }) async {
    const evaluator = TrainingWeekEvaluator();
    final WeeklyDecision decision = evaluator.evaluate(
      cycle: cycle,
      log: logSnapshot,
      weekNumber: weekNumber,
      phase: phase,
    );

    final repo = ref.read(clientRepositoryProvider);
    final client = await repo.getClientById(clientId);
    if (client == null) return;

    final extra = Map<String, dynamic>.from(client.training.extra);
    final existing = Map<String, dynamic>.from(
      extra['weeklyDecisionArtifactsV1'] as Map? ?? const {},
    );

    existing['week_$weekNumber'] = {
      'weekNumber': decision.weekNumber,
      'phase': phase,
      'actionByMuscle': decision.actionByMuscle,
      'newDirectSetsByMuscle': decision.newDirectSetsByMuscle,
      'stimulusSetsByMuscle': decision.stimulusSetsByMuscle,
      'rirTargetsByMuscle': decision.rirTargetsByMuscle,
      'insightByMuscle': decision.insightByMuscle,
      'updatedAtIso': DateTime.now().toIso8601String(),
    };

    extra['weeklyDecisionArtifactsV1'] = existing;

    await repo.saveClient(
      client.copyWith(training: client.training.copyWith(extra: extra)),
    );
  }

  /// TAREA A5: Genera plan desde ciclo activo (Motor V3)
  ///
  /// WORKFLOW:
  /// 1. Obtiene cliente + ciclo activo
  /// 2. Ejecuta Motor V3 con TrainingCycle como SSOT
  /// 3. Persiste TrainingPlan en client.trainingPlans
  /// 4. Setea activePlanId en training.extra
  /// 5. notifyListeners() para UI
  ///
  /// SSOT RULE (ACT-001): Unificación del Plan Activo
  /// - Criterio de selección: generatePlanFromActiveCycle siempre actualiza activePlanId
  /// - Retorno: TrainingPlanConfig? para que UI confirme la activación
  /// - El FAB llama updateActivePlanId(newPlan.id) DESPUÉS de generatePlan
  Future<TrainingPlanConfig?> generatePlanFromActiveCycle(
    DateTime selectedDate,
  ) async {
    debugPrint('🎯 [Motor V3] Generando plan desde ciclo activo...');

    const dbTimeout = Duration(seconds: 6);
    const catalogTimeout = Duration(seconds: 8);

    // ─────────────────────────────────────────────
    // FORZAR INVALIDACIÓN DE ESTADO (REGENERACIÓN)
    // ─────────────────────────────────────────────
    state = state.copyWith(isLoading: false, missingFields: const []);

    state = state.copyWith(isLoading: true, missingFields: const []);

    try {
      // 1. Obtener cliente activo
      debugPrint('🧭 [Motor V3][Step] 1/6 read active clientId...');
      final clientId = ref.read(clientsProvider).value?.activeClient?.id;
      if (clientId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No hay cliente activo',
        );
        return null;
      }

      debugPrint(
        '🧭 [Motor V3][Step] 2/6 loading client from repository (DB)...',
      );
      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId)
          .timeout(
            dbTimeout,
            onTimeout: () {
              throw Exception(
                'TIMEOUT DB getClientById($clientId) after ${dbTimeout.inSeconds}s',
              );
            },
          );
      debugPrint(
        '✅ [Motor V3][Step] 2/6 client loaded. cycles=${client?.trainingCycles.length ?? 0}, activeCycleId=${client?.activeCycleId}',
      );

      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Cliente no encontrado',
        );
        return null;
      }

      final flowError = _validateStructuredFlow(client.training.extra);
      if (flowError != null) {
        state = TrainingPlanState.blocked(reason: flowError);
        return null;
      }

      final cycleRepo = ref.read(trainingCycleRepositoryProvider);
      final persistedActiveCycle = await cycleRepo.getActiveCycle(clientId);
      // Si hay ciclo activo CON freeze → cargar plan existente (no regenerar)
      if (persistedActiveCycle != null &&
          persistedActiveCycle.freezePlanSnapshot.isNotEmpty) {
        debugPrint(
          '📦 [Motor V3] Ciclo con freeze detectado → cargando desde snapshot',
        );
        final currentWeek = persistedActiveCycle.currentWeek <= 0
            ? 1
            : persistedActiveCycle.currentWeek;
        final phase = _resolvePhaseForWeek(weekNumber: currentWeek);
        await _persistWeeklyDecisionArtifact(
          clientId: clientId,
          cycle: persistedActiveCycle,
          weekNumber: currentWeek,
          phase: phase,
        );

        state = TrainingPlanState(
          plan: _generatedPlanFromCycleSnapshot(persistedActiveCycle),
          vopByMuscle: state.vopByMuscle,
        );

        await ref.read(clientsProvider.notifier).refresh();
        return _findActivePlanConfigById(client) ??
            _findLatestPlan(client.trainingPlans);
      }

      // Si hay ciclo SIN freeze (bootstrap/ciclo nuevo) o no hay ciclo →
      // caer al flujo de generación normal (bootstrap + Motor V3)
      debugPrint(
        '🔄 [Motor V3] ${persistedActiveCycle != null ? "Ciclo sin freeze → generando plan nuevo" : "Sin ciclo activo → bootstrap"}',
      );

      // 2. Cargar catálogo de ejercicios (necesario para bootstrap Y Motor V3)
      debugPrint('🧭 [Motor V3][Step] 2.5/6 loading exercise catalog...');
      final exercises = await ExerciseCatalogLoader.load().timeout(
        catalogTimeout,
        onTimeout: () {
          throw Exception(
            'TIMEOUT ExerciseCatalogLoader.load() after ${catalogTimeout.inSeconds}s',
          );
        },
      );
      debugPrint(
        '✅ [Motor V3][Step] 2.5/6 catalog loaded. exercises=${exercises.length}',
      );

      // 🔴 FORZAR CICLO ACTIVO NO VACÍO
      var workingClient = client;
      TrainingCycle? currentCycle;
      if (workingClient.activeCycleId != null &&
          workingClient.activeCycleId!.isNotEmpty &&
          workingClient.trainingCycles.isNotEmpty) {
        currentCycle = _findCycleById(
          workingClient,
          workingClient.activeCycleId,
        );
        if (currentCycle == null) {
          // activeCycleId no coincide con ningún ciclo existente
          debugPrint(
            '⚠️ activeCycleId="${workingClient.activeCycleId}" no encontrado en ${workingClient.trainingCycles.length} ciclos',
          );
        }
      }

      if (workingClient.trainingCycles.isEmpty ||
          workingClient.activeCycleId == null ||
          currentCycle == null ||
          currentCycle.baseExercisesByMuscle.isEmpty) {
        debugPrint(
          '🧩 [Bootstrap] activeCycle vacío o inexistente → creando ciclo base',
        );

        final cycle = ActiveCycleBootstrapper.buildDefaultCycle(
          clientId: clientId,
          exercises: exercises,
        );

        workingClient = workingClient.copyWith(
          trainingCycles: [...workingClient.trainingCycles, cycle],
          activeCycleId: cycle.cycleId,
        );

        await ref.read(clientRepositoryProvider).saveClient(workingClient);

        debugPrint('✅ [Bootstrap] Ciclo guardado en SQLite, recargando...');

        // ✅ CRÍTICO: Recargar desde SQLite para sincronizar memoria con BD
        workingClient =
            await ref.read(clientRepositoryProvider).getClientById(clientId) ??
            workingClient;

        debugPrint(
          '🧩 [Bootstrap] ciclo creado y asignado: '
          'id=${cycle.cycleId} muscles=${cycle.baseExercisesByMuscle.keys} '
          'counts=${cycle.baseExercisesByMuscle.map((k, v) => MapEntry(k, v.length))}',
        );
        debugPrint(
          '🔍 [Bootstrap] Verificación: workingClient.trainingCycles.length=${workingClient.trainingCycles.length}',
        );
      }

      debugPrint('🧭 [Motor V3][Step] 3/6 resolving active cycle...');

      // Recuperación defensiva: si activeCycleId llega nulo/desincronizado,
      // intentar reconstruirlo desde ciclos del cliente antes de abortar.
      if (workingClient.trainingCycles.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No hay ciclos disponibles. No se pudo bootstrapear.',
        );
        debugPrint('❌ [Bootstrap] Sin ciclos después de bootstrap');
        return null;
      }

      if (workingClient.activeCycleId == null ||
          workingClient.activeCycleId!.trim().isEmpty) {
        final recovered =
            _findActiveCycle(workingClient) ??
            _findLatestCycle(workingClient.trainingCycles);

        if (recovered == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'No hay ciclo activo. No se pudo bootstrapear.',
          );
          debugPrint('❌ [Bootstrap] No se pudo recuperar activeCycleId');
          return null;
        }

        workingClient = workingClient.copyWith(
          activeCycleId: recovered.cycleId,
        );
        await ref.read(clientRepositoryProvider).saveClient(workingClient);
        debugPrint(
          '♻️ [Bootstrap] activeCycleId recuperado: ${recovered.cycleId}',
        );
      }

      TrainingCycle? activeCycle;
      activeCycle = _findCycleById(workingClient, workingClient.activeCycleId);
      if (activeCycle == null) {
        final recovered =
            _findActiveCycle(workingClient) ??
            _findLatestCycle(workingClient.trainingCycles);
        if (recovered != null) {
          activeCycle = recovered;
          if (workingClient.activeCycleId != recovered.cycleId) {
            workingClient = workingClient.copyWith(
              activeCycleId: recovered.cycleId,
            );
            await ref.read(clientRepositoryProvider).saveClient(workingClient);
          }
          debugPrint(
            '♻️ [Bootstrap] Ciclo activo recuperado por fallback: ${recovered.cycleId}',
          );
        }
      }

      if (activeCycle == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Ciclo activo no encontrado en client.trainingCycles',
        );
        debugPrint(
          '❌ Error crítico: activeCycleId="${workingClient.activeCycleId}" no existe después de bootstrap',
        );
        return null;
      }

      debugPrint(
        '✅ [Motor V3][Step] 3/6 activeCycle found. muscles=${activeCycle.baseExercisesByMuscle.keys.toList()}',
      );

      // ─────────────────────────────────────────────
      // FORZAR REGENERACIÓN DE PLAN DEL CICLO ACTIVO
      // ─────────────────────────────────────────────
      final hasActivePlanId =
          workingClient.training.extra[TrainingExtraKeys.activePlanId] != null;
      if (workingClient.trainingPlans.isNotEmpty || hasActivePlanId) {
        debugPrint(
          '♻️ [Motor V3 P0-2] Regeneración: LIMPIEZA TOTAL datos legacy',
        );

        final updatedExtra = Map<String, dynamic>.from(
          workingClient.training.extra,
        );

        // ✅ P0-2: ELIMINAR TODAS LAS CLAVES LEGACY DE MOTORES ANTERIORES
        const legacyKeys = [
          'activePlanId', // Legacy plan ID
          'mevByMuscle', // Legacy volumen output
          'mrvByMuscle', // Legacy volumen output
          'mavByMuscle', // Legacy volumen output
          'targetSetsByMuscle', // Legacy distribución
          'intensityDistribution', // Legacy intensidad
          'mevTable', // Legacy metadata
          'seriesTypePercentSplit', // Legacy metadata
          'weeklyPlanId', // Legacy semanas
          'finalTargetSetsByMuscleUi', // Legacy UI cache
        ];

        for (final key in legacyKeys) {
          if (updatedExtra.containsKey(key)) {
            updatedExtra.remove(key);
            debugPrint('  🗑️ P0-2: Eliminada clave legacy: $key');
          }
        }

        workingClient = workingClient.copyWith(
          training: workingClient.training.copyWith(extra: updatedExtra),
          trainingPlans: const [],
          trainingWeeks: const [], // ✅ Limpiar semanas legacy
          trainingSessions: const [], // ✅ Limpiar sesiones legacy
        );

        debugPrint('✅ P0-2: training.extra limpiado completamente');
        debugPrint('   Claves restantes: ${updatedExtra.keys.toList()}');

        await ref.read(clientRepositoryProvider).saveClient(workingClient);

        debugPrint('✅ [Motor] Plan limpiado en SQLite, recargando...');

        // ✅ CRÍTICO: Recargar desde SQLite
        workingClient =
            await ref.read(clientRepositoryProvider).getClientById(clientId) ??
            workingClient;

        debugPrint(
          '🔍 [Motor] Verificación post-limpieza: trainingPlans.length=${workingClient.trainingPlans.length}',
        );
      }

      // 3.1 Inferir frecuencia desde VMR y persistir en ciclo
      final rawTargets = workingClient.training.extra['targetSetsByMuscle'];

      final Map<String, double> targets = {};
      if (rawTargets is Map) {
        rawTargets.forEach((k, v) {
          if (v is num) targets[k.toString()] = v.toDouble();
        });
      }

      final inferredFrequency = FrequencyInference.inferFromVmr(targets);

      if (activeCycle.frequency != inferredFrequency) {
        final updatedCycle = activeCycle.copyWith(frequency: inferredFrequency);

        final updatedCycles = [
          for (final c in workingClient.trainingCycles)
            if (c.cycleId == updatedCycle.cycleId) updatedCycle else c,
        ];

        workingClient = workingClient.copyWith(trainingCycles: updatedCycles);

        await ref.read(clientRepositoryProvider).saveClient(workingClient);

        debugPrint('✅ [Motor] Frecuencia guardada en SQLite, recargando...');

        // ✅ CRÍTICO: Recargar desde SQLite
        workingClient =
            await ref.read(clientRepositoryProvider).getClientById(clientId) ??
            workingClient;

        activeCycle = updatedCycle;

        debugPrint(
          '📌 [Motor] Frecuencia inferida y guardada en ciclo: $inferredFrequency',
        );
      }

      // PARTE 4 A6: Validación VOP se hace POST-plan (requiere ejercicios reales)
      debugPrint('🧭 [Motor V3][Step] 4/6 VOP validate (post-plan)');

      // 4. Ejecutar Motor V3 (MotorV3Orchestrator)
      debugPrint(
        '🚀 [Motor V3] Regenerando plan con pipeline científico — timestamp: ${DateTime.now()}',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // MOTOR V3 REAL - PIPELINE CIENTÍFICO COMPLETO
      // ═══════════════════════════════════════════════════════════════════════
      debugPrint('🚀 [Motor V3] Generando plan con pipeline científico...');

      // Crear Motor V3 con estrategia científica pura (sin ML)
      final motorV3 = TrainingOrchestratorV3(
        strategy: RuleBasedStrategy(), // 100% científico basado en 7 MDs
      );

      // Generar plan con Motor V3 REAL
      TrainingProgramV3Result resultV3;
      try {
        resultV3 = await motorV3.generatePlan(
          client: workingClient,
          exercises: exercises,
          asOfDate: selectedDate,
          phase:
              (workingClient.training.extra['phase'] as String?) ??
              'accumulation',
          intensityProfilePercentSplit: _readIntensitySplitPercent(
            workingClient.training.extra,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('❌ [Motor V3] Error durante generación: $e');
        debugPrint('Stack trace: $stackTrace');

        state = state.copyWith(
          isLoading: false,
          error: 'Error en Motor V3: $e',
        );
        return null;
      }

      // Validar resultado Motor V3
      if (resultV3.isBlocked) {
        debugPrint('❌ [Motor V3] Plan bloqueado: ${resultV3.blockReason}');

        state = state.copyWith(
          isLoading: false,
          error: 'Plan bloqueado: ${resultV3.blockReason}',
          blockReason: resultV3.blockReason,
          suggestions: resultV3.suggestions,
        );
        return null;
      }

      // Extraer plan generado
      final planConfig = resultV3.plan!;

      final vopByMuscle = _computeVopByMuscleFromPlan(planConfig);
      final vmrByMuscle = _computeVmrByMuscle(
        planConfig: planConfig,
        vopByMuscle: vopByMuscle,
      );
      final freezePlanSnapshot = _buildFreezePlanSnapshot(
        planConfig: planConfig,
        vopByMuscle: vopByMuscle,
        vmrByMuscle: vmrByMuscle,
        availableDays: workingClient.training.daysPerWeek > 0
            ? workingClient.training.daysPerWeek
            : 4,
        sessionDurationMinutes: workingClient.training.timePerSessionMinutes > 0
            ? workingClient.training.timePerSessionMinutes
            : 60,
      );

      final cycleForFreeze = activeCycle.copyWith(
        status: 'active',
        splitType: planConfig.splitId,
        vopByMuscle: vopByMuscle,
        vmrByMuscle: vmrByMuscle,
        baseExercisesByMuscle: _extractBaseExercisesByMuscleFromSnapshot(
          freezePlanSnapshot,
        ),
        freezePlanSnapshot: freezePlanSnapshot,
        updatedAt: DateTime.now(),
      );

      await cycleRepo.upsertCycle(cycleForFreeze);

      final decisionWeek = cycleForFreeze.currentWeek <= 0
          ? 1
          : cycleForFreeze.currentWeek;
      final phaseForDecision = _resolvePhaseForWeek(weekNumber: decisionWeek);
      await _persistWeeklyDecisionArtifact(
        clientId: clientId,
        cycle: cycleForFreeze,
        weekNumber: decisionWeek,
        phase: phaseForDecision,
      );

      debugPrint(
        '✅ [Motor V3] Plan generado: ${planConfig.weeks.length} semanas, '
        '${planConfig.weeks.fold<int>(0, (sum, w) => sum + w.sessions.length)} sesiones',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // 🔴 MOVIMIENTO 4: VALIDACIONES DURAS PRE-PERSISTENCIA (P0-BLOQUEANTE)
      // ═══════════════════════════════════════════════════════════════════════

      debugPrint('🔒 [VALIDACIÓN P0] Validando plan antes de persistir...');
      debugPrint('  📊 Estado planConfig:');
      debugPrint('     - weeks.length: ${planConfig.weeks.length}');
      debugPrint('     - volumePerMuscle: ${planConfig.volumePerMuscle}');
      debugPrint('     - splitId: ${planConfig.splitId}');

      // ❌ Validación 1: weeks no puede estar vacío
      if (planConfig.weeks.isEmpty) {
        const errorMsg = 'CRÍTICO: Plan generado sin semanas (weeks.isEmpty)';
        debugPrint('❌ $errorMsg');

        state = state.copyWith(
          isLoading: false,
          error: errorMsg,
          blockReason: 'Plan inválido: 0 semanas generadas',
          suggestions: const [
            'Verifica que el split esté configurado correctamente',
            'Contacta soporte si el problema persiste',
          ],
        );

        throw StateError(errorMsg);
      }

      debugPrint('  ✅ Validación weeks: ${planConfig.weeks.length} semanas');

      // ❌ Validación 2: volumePerMuscle no puede estar vacío (Motor V3)
      final volumePerMuscle = planConfig.volumePerMuscle;

      if (volumePerMuscle == null || volumePerMuscle.isEmpty) {
        const errorMsg =
            'CRÍTICO: Plan sin volumen por músculo (volumePerMuscle.isEmpty)';
        debugPrint('❌ $errorMsg');

        state = state.copyWith(
          isLoading: false,
          error: errorMsg,
          blockReason: 'Plan inválido: Sin distribución de volumen',
          suggestions: const [
            'Verifica las prioridades musculares',
            'Configura al menos un músculo prioritario',
          ],
        );

        throw StateError(errorMsg);
      }

      debugPrint(
        '  ✅ Validación volumePerMuscle: ${volumePerMuscle.length} músculos',
      );

      // ❌ Validación 3: split no puede ser null (Motor V3)
      final split = planConfig.splitId;

      if (split.isEmpty) {
        const errorMsg = 'CRÍTICO: Plan sin split definido (split == null)';
        debugPrint('❌ $errorMsg');

        state = state.copyWith(
          isLoading: false,
          error: errorMsg,
          blockReason: 'Plan inválido: Split no determinado',
          suggestions: const [
            'Verifica días disponibles de entrenamiento',
            'El split debe ser fullBody, upperLower o pushPullLegs',
          ],
        );

        throw StateError(errorMsg);
      }

      debugPrint('  ✅ Validación split: $split');
      debugPrint(
        '✅ [VALIDACIÓN P0] Todas las validaciones pasaron. Plan válido para persistir.',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // CRÍTICO P0-BLOQUEANTE: Persistir plan en client.trainingPlans
      // ═══════════════════════════════════════════════════════════════════════

      debugPrint(
        '💾 [Motor V3][Persistence] Añadiendo plan a client.trainingPlans...',
      );

      // 1. Crear lista actualizada de planes (sin duplicados)
      final updatedPlans = [
        ...workingClient.trainingPlans.where((p) => p.id != planConfig.id),
        planConfig,
      ];

      debugPrint('   Planes antes: ${workingClient.trainingPlans.length}');
      debugPrint('   Planes después: ${updatedPlans.length}');
      debugPrint('   Plan ID: ${planConfig.id}');

      // 2. Actualizar activePlanId en training.extra
      final updatedExtra = Map<String, dynamic>.from(
        workingClient.training.extra,
      );
      updatedExtra[TrainingExtraKeys.activePlanId] = planConfig.id;

      debugPrint(
        '✅ [Motor V3][Persistence] activePlanId actualizado: ${planConfig.id}',
      );

      // 3. Crear cliente actualizado con plan persistido
      final clientWithPlan = workingClient.copyWith(
        trainingPlans: updatedPlans,
        training: workingClient.training.copyWith(extra: updatedExtra),
      );

      // 4. Guardar en repositorio
      debugPrint(
        '💾 [Motor V3][Persistence] Guardando cliente en repositorio...',
      );
      await ref.read(clientRepositoryProvider).saveClient(clientWithPlan);

      debugPrint('✅ [Motor V3][Persistence] Cliente guardado exitosamente');
      debugPrint(
        '   trainingPlans.length: ${clientWithPlan.trainingPlans.length}',
      );
      debugPrint(
        '   activePlanId: ${clientWithPlan.training.extra[TrainingExtraKeys.activePlanId]}',
      );

      // 5. Actualizar workingClient para validaciones siguientes
      workingClient = clientWithPlan;

      // ═══════════════════════════════════════════════════════════════════════
      // CONTINUAR CON VALIDACIONES VOP
      // ═══════════════════════════════════════════════════════════════════════

      // ═══════════════════════════════════════════════════════════════════
      // PASO 1: LEER VOP DESDE SSOT (vopSnapshot) - MOTOR V3 EXCLUSIVO
      // ═══════════════════════════════════════════════════════════════════
      // ARQUITECTURA:
      // - vopSnapshot: SSOT único (14 músculos canónicos)
      // - NO usa volumeLimitsByMuscle (legacy Motor V2 - DEPRECADO)
      // - Genera automático si vopSnapshot falta
      // ═══════════════════════════════════════════════════════════════════

      final vopContext = VopContext.ensure(workingClient.training.extra);
      final directVopByMuscle = <String, double>{};

      if (vopContext != null && vopContext.hasData) {
        // ✅ FLUJO PRINCIPAL: VopSnapshot existe
        debugPrint('[Motor V3] ✅ Leyendo VOP desde vopSnapshot (SSOT)');

        vopContext.snapshot.setsByMuscle.forEach((muscle, sets) {
          final normalizedMuscle = normalizeMuscleKey(muscle);
          directVopByMuscle[normalizedMuscle] = sets.toDouble();
        });

        debugPrint(
          '[Motor V3] VOP desde SSOT: ${directVopByMuscle.keys.toList()}',
        );
        debugPrint('[Motor V3] Total músculos: ${directVopByMuscle.length}');
      } else {
        // ⚠️ FLUJO FALLBACK: VopSnapshot NO existe → Generar automático
        debugPrint('[Motor V3] ⚠️ vopSnapshot NO encontrado');
        debugPrint(
          '[Motor V3] 🔧 Generando VOP automático desde baseExercisesByMuscle...',
        );

        final allMuscles = <String>{};
        allMuscles.addAll(
          activeCycle.baseExercisesByMuscle.keys.map(
            (m) => normalizeMuscleKey(m),
          ),
        );

        final resolvedTrainingLevel =
            workingClient.training.trainingLevel?.name == 'beginner'
            ? 'novice'
            : (workingClient.training.trainingLevel?.name ?? 'intermediate');
        final priorityMuscles = activeCycle.priorityMuscles
            .map(normalizeMuscleKey)
            .toSet();

        debugPrint('[Motor V3] Músculos detectados: ${allMuscles.toList()}');

        for (final muscle in allMuscles) {
          try {
            final priority = priorityMuscles.contains(muscle) ? 4 : 3;
            final optimalVolume = VolumeEngine.calculateOptimalVolume(
              muscle: muscle,
              trainingLevel: resolvedTrainingLevel,
              priority: priority,
              age:
                  workingClient.training.age ?? workingClient.profile.age ?? 30,
            );

            directVopByMuscle[muscle] = optimalVolume.toDouble();

            debugPrint('[Motor V3]   ✓ $muscle → $optimalVolume sets/semana');
          } catch (e) {
            debugPrint(
              '[Motor V3]   ⚠️ $muscle no en VolumeEngine, usando fallback',
            );
            directVopByMuscle[muscle] = 12.0;
          }
        }

        debugPrint('[Motor V3] VOP AUTO-GENERADO: $directVopByMuscle');
      }

      if (directVopByMuscle.isEmpty) {
        debugPrint(
          '[Motor V3] ❌ ERROR: directVopByMuscle vacío después de todos los intentos',
        );
        throw StateError(
          'No se pudo obtener VOP: vopSnapshot no existe y no hay músculos en baseExercisesByMuscle',
        );
      }

      debugPrint(
        '[Motor V3] 📊 VOP FINAL: ${directVopByMuscle.length} músculos con volumen asignado',
      );

      final mevByMuscle = <String, double>{};
      final landmarksByMuscle = LandmarkEngine.parseByCanonicalKey(
        workingClient.training.extra[TrainingExtraKeys.muscleLandmarks],
      );
      if (landmarksByMuscle.isNotEmpty) {
        for (final entry in landmarksByMuscle.entries) {
          mevByMuscle[normalizeMuscleKey(entry.key)] = entry.value.vme
              .toDouble();
        }
      } else {
        final mevRaw =
            planConfig.trainingProfileSnapshot?.extra[TrainingExtraKeys
                .mevByMuscle] ??
            planConfig.volumePerMuscle ??
            workingClient.training.extra[TrainingExtraKeys.mevByMuscle];

        if (mevRaw is Map) {
          mevRaw.forEach((k, v) {
            final key = normalizeMuscleKey(k.toString());
            if (v is num) {
              mevByMuscle[key] = v.toDouble();
            } else {
              final parsed = double.tryParse(v?.toString() ?? '');
              if (parsed != null) {
                mevByMuscle[key] = parsed;
              }
            }
          });
        }
      }

      MevTable.seed(mevByMuscle);

      final exerciseByCode = <String, Exercise>{};
      for (final ex in exercises) {
        if (ex.id.isNotEmpty) exerciseByCode[ex.id] = ex;
        if (ex.externalId.isNotEmpty) exerciseByCode[ex.externalId] = ex;
      }

      final plannedExercises = <VopPlannedExercise>[];
      for (final week in planConfig.weeks) {
        for (final session in week.sessions) {
          for (final prescription in session.prescriptions) {
            final catalogExercise = exerciseByCode[prescription.exerciseCode];
            if (catalogExercise == null) continue;

            plannedExercises.add(
              VopPlannedExercise(
                stimulusContribution: catalogExercise.stimulusContribution,
                plannedSets: prescription.sets,
              ),
            );
          }
        }
      }

      VopValidator.validate(
        cycle: activeCycle,
        directVopByMuscle: directVopByMuscle,
        plannedExercises: plannedExercises,
      );

      debugPrint(
        '✅ [Motor V3] Validación VOP: '
        '${activeCycle.baseExercisesByMuscle.keys.length} músculos OK',
      );

      // 4. Convertir a GeneratedPlan para UI
      final plan = TrainingPlanMapper.toGeneratedPlan(planConfig);

      // 5. Actualizar state (reemplazo completo)
      final warningsRaw = resultV3.metadata?['warnings'];
      final warningMessages = warningsRaw is List
          ? warningsRaw.map((e) => e.toString()).toList()
          : const <String>[];

      state = TrainingPlanState(
        plan: plan,
        vopByMuscle: state.vopByMuscle,
        suggestions: warningMessages,
      );

      debugPrint(
        '🎉 [Motor V3] Plan persistido con activePlanId=${planConfig.id}',
      );

      // 6. Refrescar clientsProvider para que UI refleje el plan persistido
      await ref.read(clientsProvider.notifier).refresh();

      // 7. Validar que el plan fue persistido correctamente
      final refreshedClient = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      debugPrint(
        '[Motor V3] after refresh trainingPlans=${refreshedClient?.trainingPlans.length ?? 0}, activePlanId=${refreshedClient?.training.extra[TrainingExtraKeys.activePlanId]}',
      );

      // ✅ FASE B.1: Retornar el plan generado para que FAB lo active
      return planConfig;
    } on VopValidationException catch (e) {
      debugPrint('❌ [Motor V3] Validación VOP fallida: ${e.reason}');
      state = TrainingPlanState.blocked(
        reason: 'Validación VOP',
        suggestions: [e.reason],
        missingFields: e.muscles,
      );
      return null;
    } on TrainingPlanBlockedException catch (blocked) {
      debugPrint('🚫 [Motor V3] Bloqueado: ${blocked.reason}');
      state = TrainingPlanState.blocked(
        reason: blocked.reason,
        suggestions: blocked.suggestions,
      );
      return null;
    } catch (e, s) {
      debugPrint('❌ [Motor V3] Error: $e');
      debugPrint('Stack: $s');
      state = state.copyWith(
        isLoading: false,
        error: 'Motor V3 falló: ${e.toString()}',
      );
      return null;
    }
  }

  String? _validateStructuredFlow(Map<String, dynamic> extra) {
    final stage = TrainingPipelineGuard.allowedStage(extra);
    if (stage != TrainingFlowStage.plan) {
      return 'Flujo incompleto: debes completar entrevista, landmarks e intensidad antes de generar plan.';
    }

    final splitRaw = extra[TrainingExtraKeys.seriesTypePercentSplit];
    final split = splitRaw is Map
        ? IntensitySplit.fromMap(
            splitRaw.map((key, value) => MapEntry(key.toString(), value)),
          )
        : IntensitySplit.defaultSplit;
    if (!split.isValid) {
      return 'Split de intensidad inválido: heavy/light 0-30, medium 0-70 y suma total = 100.';
    }

    final landmarks = LandmarkEngine.parseByCanonicalKey(
      extra[TrainingExtraKeys.muscleLandmarks],
    );
    if (landmarks.isEmpty) {
      return 'No hay landmarks musculares. Guarda entrevista para calcular VME/VOP/VMR.';
    }

    return null;
  }

  /// FASE B.2: Actualizar el plan activo (SSOT)
  ///
  /// Persiste el cambio de activePlanId en training.extra y refresca clientsProvider.
  /// Se llama desde FAB DESPUÉS de generatePlanFromActiveCycle() para:
  /// 1. Confirmar que el nuevo plan existe
  /// 2. Garantizar que activePlanId refleja el plan generado
  /// 3. Permitir que UI lea el nuevo plan como "activo"
  Future<void> updateActivePlanId(String planId) async {
    try {
      final clientId = ref.read(clientsProvider).value?.activeClient?.id;
      if (clientId == null) {
        debugPrint('❌ [updateActivePlanId] No active client');
        return;
      }

      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      if (client == null) {
        debugPrint('❌ [updateActivePlanId] Client not found: $clientId');
        return;
      }

      final updatedExtra = Map<String, dynamic>.from(client.training.extra);
      updatedExtra[TrainingExtraKeys.activePlanId] = planId;

      final updatedClient = client.copyWith(
        training: client.training.copyWith(extra: updatedExtra),
      );

      await ref.read(clientRepositoryProvider).saveClient(updatedClient);

      // Refrescar clientsProvider para que UI refleje cambio
      await ref.read(clientsProvider.notifier).refresh();

      debugPrint('✅ [updateActivePlanId] Activado plan: $planId');
    } catch (e) {
      debugPrint('❌ [updateActivePlanId] Error: $e');
    }
  }

  /// TAREA A5 PARTE 2: Recalcular series sin cambiar ejercicios
  ///
  /// Se llama cuando el usuario mueve los sliders de Tab 2 (H/M/L)
  /// SOLO recalcula distribución de series, NO regenera ejercicios ni split
  Future<void> recalculateSeriesDistribution({
    required int heavyPercent,
    required int mediumPercent,
    required int lightPercent,
  }) async {
    debugPrint(
      '🔄 [Tab 2] Recalculando series: H=$heavyPercent% M=$mediumPercent% L=$lightPercent%',
    );

    try {
      final splitValid = IntensityDistributionHelper.isValidPercentSplit(
        heavy: heavyPercent,
        medium: mediumPercent,
        light: lightPercent,
      );
      if (!splitValid) {
        debugPrint('❌ [Tab 2] Split inválido (rangos o suma)');
        return;
      }

      final clientId = ref.read(clientsProvider).value?.activeClient?.id;
      if (clientId == null) {
        debugPrint('❌ [Tab 2] No active client');
        return;
      }

      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      if (client == null) {
        debugPrint('❌ [Tab 2] Client not found: $clientId');
        return;
      }

      // OPTIMISTIC UPDATE: Actualizar localmente primero
      await ref
          .read(clientsProvider.notifier)
          .updateActiveClient((c) {
            final extra = Map<String, dynamic>.from(c.training.extra);
            extra[TrainingExtraKeys.seriesTypePercentSplit] = {
              'heavy': heavyPercent,
              'medium': mediumPercent,
              'light': lightPercent,
            };

            final landmarksByMuscle = LandmarkEngine.parseByCanonicalKey(
              extra[TrainingExtraKeys.muscleLandmarks],
            );
            final intensitySetsByMuscle = <String, Map<String, int>>{};

            for (final entry in landmarksByMuscle.entries) {
              final vop = entry.value.vop;
              final computed =
                  IntensityDistributionHelper.computeSeriesBreakdown(
                    totalSeries: vop,
                    heavyPercent: heavyPercent,
                    lightPercent: lightPercent,
                  );

              intensitySetsByMuscle[entry.key] = {
                'vop': vop,
                'heavy': computed.heavy,
                'medium': computed.medium,
                'light': computed.light,
              };
            }

            extra[TrainingExtraKeys.intensitySetsByMuscle] =
                intensitySetsByMuscle;
            final allowedStage = TrainingPipelineGuard.allowedStage(extra);
            extra[TrainingExtraKeys.trainingFlowStage] = allowedStage.name;

            debugPrint('✅ [Tab 2] Split actualizado en training.extra (local)');

            return c.copyWith(
              training: c.training.copyWith(extra: extra),
              updatedAt: DateTime.now(),
            );
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint(
                '⚠️  [Tab 2] updateActiveClient timeout (continuando con estado local)',
              );
            },
          );

      debugPrint('✅ [Tab 2] Series recalculadas sin cambiar ejercicios');
    } catch (e, st) {
      debugPrint('❌ [Tab 2] Error al recalcular: $e');
      debugPrint('Stack: ${st.toString()}');
      // No relanzar - permitir que la UI continúe con estado local
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// NUEVO: Generación de plan con Motor V3 (puente de migración)
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Genera plan de entrenamiento usando TrainingOrchestratorV3 directamente,
  /// sin la complejidad de bootstrap de ciclos de generatePlanFromActiveCycle.
  ///
  /// DIFERENCIAS CON generatePlanFromActiveCycle:
  /// - ✅ Usa TrainingOrchestratorV3 directamente (no wrapper)
  /// - ✅ Retorna TrainingProgramV3Result tipado (no Map)
  /// - ✅ Convierte V3 → V2 para compatibilidad con UI actual
  /// - ✅ Más simple: no maneja bootstrap de ciclos
  ///
  /// WORKFLOW:
  /// 1. Obtener cliente activo y catálogo de ejercicios
  /// 2. Crear TrainingOrchestratorV3 con RuleBasedStrategy
  /// 3. Generar plan científico
  /// 4. Convertir TrainingPlanConfig → GeneratedPlan (V2)
  /// 5. Persistir en repositorio
  /// 6. Actualizar state y notifyListeners()
  ///
  /// USO:
  /// ```dart
  /// await ref.read(trainingPlanProvider.notifier).generatePlanV3(
  ///   selectedDate: DateTime.now(),
  /// );
  /// ```
  @Deprecated('Usar generatePlanFromActiveCycle como entrada oficial')
  Future<void> generatePlanV3({required DateTime selectedDate}) async {
    await generatePlanFromActiveCycle(selectedDate);
    return;

    debugPrint('🚀 [generatePlanV3] Iniciando generación Motor V3...');

    state = state.copyWith(isLoading: true);

    try {
      // ─────────────────────────────────────────────
      // PASO 1: OBTENER CLIENTE ACTIVO
      // ─────────────────────────────────────────────
      final clientId = ref.read(clientsProvider).value?.activeClient?.id;
      if (clientId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No hay cliente activo',
        );
        return;
      }

      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);

      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Cliente no encontrado',
        );
        return;
      }

      debugPrint(
        '✅ [generatePlanV3] Cliente cargado: ${client.profile.fullName}',
      );

      // ─────────────────────────────────────────────
      // PASO 2: CARGAR CATÁLOGO DE EJERCICIOS
      // ─────────────────────────────────────────────
      final exercises = await ExerciseCatalogLoader.load();
      debugPrint(
        '✅ [generatePlanV3] Catálogo cargado: ${exercises.length} ejercicios',
      );

      // ─────────────────────────────────────────────
      // PASO 3: CREAR MOTOR V3 Y GENERAR PLAN
      // ─────────────────────────────────────────────
      final motorV3 = TrainingOrchestratorV3(strategy: RuleBasedStrategy());

      debugPrint('🔬 [generatePlanV3] Llamando Motor V3...');

      final resultV3 = await motorV3.generatePlan(
        client: client,
        exercises: exercises,
        asOfDate: selectedDate,
        phase: (client.training.extra['phase'] as String?) ?? 'accumulation',
        intensityProfilePercentSplit: _readIntensitySplitPercent(
          client.training.extra,
        ),
      );

      // ─────────────────────────────────────────────
      // PASO 4: VALIDAR RESULTADO
      // ─────────────────────────────────────────────
      if (resultV3.isBlocked) {
        debugPrint(
          '❌ [generatePlanV3] Plan bloqueado: ${resultV3.blockReason}',
        );

        state = state.copyWith(
          isLoading: false,
          error: 'Plan bloqueado',
          blockReason: resultV3.blockReason,
          suggestions: resultV3.suggestions,
        );
        return;
      }

      final planConfigV3 = resultV3.plan;
      if (planConfigV3 == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Motor V3 no generó plan',
        );
        return;
      }

      debugPrint(
        '✅ [generatePlanV3] Plan V3 generado: ${planConfigV3.weeks.length} semanas, '
        '${planConfigV3.weeks.fold<int>(0, (sum, w) => sum + w.sessions.length)} sesiones',
      );

      // ─────────────────────────────────────────────
      // PASO 5: PERSISTIR PLAN V3 EN REPOSITORIO
      // ─────────────────────────────────────────────
      debugPrint('💾 [generatePlanV3] Persistiendo TrainingPlanConfig V3...');

      final updatedPlans = [
        ...client.trainingPlans.where((p) => p.id != planConfigV3.id),
        planConfigV3,
      ];

      final updatedExtra = Map<String, dynamic>.from(client.training.extra);
      updatedExtra[TrainingExtraKeys.activePlanId] = planConfigV3.id;

      final updatedClient = client.copyWith(
        trainingPlans: updatedPlans,
        training: client.training.copyWith(extra: updatedExtra),
      );

      await ref.read(clientRepositoryProvider).saveClient(updatedClient);

      debugPrint('✅ [generatePlanV3] TrainingPlanConfig V3 persistido');
      debugPrint('   Plan ID: ${planConfigV3.id}');
      debugPrint('   Semanas: ${planConfigV3.weeks.length}');

      // Conversion notes (V3 -> V2): keep mapper until external converter exists.
      final generatedPlanV2 = TrainingPlanMapper.toGeneratedPlan(planConfigV3);

      debugPrint('✅ [generatePlanV3] Conversión V3→V2 completada (mapper)');

      // ─────────────────────────────────────────────
      // PASO 6: ACTUALIZAR STATE CON PLAN V2
      // ─────────────────────────────────────────────
      state = state.copyWith(isLoading: false, plan: generatedPlanV2);

      debugPrint('✅ [generatePlanV3] State actualizado con GeneratedPlan V2');
    } catch (e, stackTrace) {
      debugPrint('❌ [generatePlanV3] Error: $e');
      debugPrint('Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        error: 'Error generando plan V3: $e',
      );
    }
  }

  /// Borra el plan activo Y ciclos para forzar regeneración completa
  ///
  /// PROPÓSITO: Invalidar caché cuando el usuario quiere regenerar
  ///
  /// WORKFLOW:
  /// 1. Obtener cliente activo
  /// 2. Limpiar activePlanId (training.extra) y activeCycleId (top-level)
  /// 3. Limpiar trainingPlans Y trainingCycles (regeneración completa)
  /// 4. Guardar cliente actualizado
  /// 5. Resetear state del provider
  Future<void> clearActivePlan() async {
    try {
      final clientId = ref.read(clientsProvider).value?.activeClient?.id;
      if (clientId == null) {
        debugPrint('⚠️ clearActivePlan: No hay cliente activo');
        return;
      }

      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      if (client == null) {
        debugPrint('⚠️ clearActivePlan: Cliente no encontrado');
        return;
      }

      debugPrint('🗑️ Limpiando plan activo, ciclos y ejercicios base...');

      // Limpiar activePlanId (extra)
      final updatedExtra = Map<String, dynamic>.from(client.training.extra);
      updatedExtra.remove(TrainingExtraKeys.activePlanId);

      // CRÍTICO: También limpiar cualquier snapshot de ejercicios base
      updatedExtra.remove('baseExercisesByMuscle');
      updatedExtra.remove('cycleExercises');

      final updatedTraining = client.training.copyWith(extra: updatedExtra);

      // Borrar TODOS los planes Y ciclos
      final updatedClient = client.copyWith(
        training: updatedTraining,
        trainingPlans: const [],
        trainingCycles: const [],
      );

      // Guardar en repositorio
      await ref.read(clientRepositoryProvider).saveClient(updatedClient);

      debugPrint('✅ Cliente guardado en repositorio local');

      debugPrint('Sync remoto queda en background; refrescando desde SQLite.');

      // Refrescar provider
      await ref.read(clientsProvider.notifier).refresh();

      // ✅ VERIFICAR que el cliente NO tiene ciclos
      final verifyClient = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);

      debugPrint('🔍 Verificación post-limpieza:');
      debugPrint(
        '   trainingCycles.length: ${verifyClient?.trainingCycles.length ?? 0}',
      );
      debugPrint('   activeCycleId(top-level): ${verifyClient?.activeCycleId}');

      if (verifyClient?.trainingCycles.isNotEmpty ?? false) {
        debugPrint(
          '⚠️ WARNING: Cliente TODAVÍA tiene ciclos después de limpiar',
        );
        debugPrint('   Esto indica problema de sincronización de Firestore');
      }

      debugPrint('✅ Plan, ciclos y ejercicios base borrados exitosamente');
      debugPrint(
        '   → Motor generará ciclo nuevo con baseExercisesByMuscle únicos',
      );

      // Resetear state
      state = const TrainingPlanState();
    } catch (e, stackTrace) {
      debugPrint('❌ Error en clearActivePlan: $e');
      debugPrint('Stack: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al limpiar plan: $e',
      );
    }
  }

  void clearError() {
    state = TrainingPlanState(
      isLoading: state.isLoading,
      plan: state.plan,
      missingFields: state.missingFields,
      vopByMuscle: state.vopByMuscle,
    );
  }

  TrainingPlanAction resolveAllowedAction(Client client) {
    final extra = Map<String, dynamic>.from(client.training.extra);
    final progression = _readProgressionFromExtra(extra);
    final evaluation = _readEvaluationFromExtra(extra);
    final hasPlan =
        client.trainingPlans.isNotEmpty || _findActiveCycle(client) != null;

    if (evaluation != null) {
      if (evaluation.peakPhaseWindow ||
          (evaluation.weeksToCompetition != null &&
              evaluation.weeksToCompetition! <= 3)) {
        return TrainingPlanAction.locked;
      }

      if (progression.weeksCompleted == 0 &&
          evaluation.regenerationPolicy == 'allow') {
        return hasPlan
            ? TrainingPlanAction.regenerate
            : TrainingPlanAction.generate;
      }

      if (progression.weeksCompleted >= 1 &&
          progression.weeksCompleted < 3 &&
          evaluation.regenerationPolicy != 'locked') {
        return TrainingPlanAction.adapt;
      }

      if (evaluation.regenerationPolicy == 'adapt_only' ||
          progression.weeksCompleted >= 3) {
        return TrainingPlanAction.adapt;
      }
    }

    if (!hasPlan) {
      return TrainingPlanAction.generate;
    }

    if (progression.weeksCompleted == 0) {
      return TrainingPlanAction.regenerate;
    }

    return TrainingPlanAction.adapt;
  }

  String resolvePlanActionTooltip(Client client, TrainingPlanAction action) {
    final extra = Map<String, dynamic>.from(client.training.extra);
    final progression = _readProgressionFromExtra(extra);
    final evaluation = _readEvaluationFromExtra(extra);

    switch (action) {
      case TrainingPlanAction.generate:
        return evaluation == null
            ? 'Generar plan inicial'
            : 'Generar plan inicial con ${progression.weeksCompleted} semanas completadas';
      case TrainingPlanAction.regenerate:
        return 'Regenerar plan completo desde cero';
      case TrainingPlanAction.adapt:
        return 'Adaptar el plan sin romper la estructura del ciclo';
      case TrainingPlanAction.locked:
        return 'Plan bloqueado por ventana clínica crítica';
    }
  }

  List<String> validatePlanActionInputs({
    required Client client,
    required TrainingEvaluationSnapshotV1 evaluation,
  }) {
    final errors = <String>[];
    if (client.id.isEmpty) {
      errors.add('Cliente inválido');
    }
    if (evaluation.daysPerWeek <= 0) {
      errors.add('daysPerWeek debe ser mayor que 0');
    }
    if (evaluation.planDurationInWeeks <= 0) {
      errors.add('planDurationInWeeks debe ser mayor que 0');
    }
    if (evaluation.sessionDurationMinutes <= 0) {
      errors.add('sessionDurationMinutes debe ser mayor que 0');
    }
    return errors;
  }

  Future<void> saveProgressionState({
    required String clientId,
    required TrainingProgressionStateV1 progression,
  }) async {
    final client = await ref
        .read(clientRepositoryProvider)
        .getClientById(clientId);
    if (client == null) return;

    await _persistProgressionState(
      client: client,
      progression: progression,
      syncCycleWeek: true,
    );
  }

  Future<void> recordPlanAction({
    required String clientId,
    required String action,
    bool resetProgressionCounters = false,
    bool appendAdaptationHistory = false,
  }) async {
    final client = await ref
        .read(clientRepositoryProvider)
        .getClientById(clientId);
    if (client == null) return;

    final extra = Map<String, dynamic>.from(client.training.extra);
    final progression = _readProgressionFromExtra(extra);
    final now = DateTime.now();

    final adaptationHistory = List<Map<String, dynamic>>.from(
      progression.adaptationHistory,
    );
    if (appendAdaptationHistory) {
      adaptationHistory.add({
        'action': action,
        'timestamp': now.toIso8601String(),
        'planId': extra[TrainingExtraKeys.activePlanId]?.toString() ?? '',
        'cycleWeek': _activeCycleWeek(client),
      });
    }

    final updatedProgression = resetProgressionCounters
        ? TrainingProgressionStateV1(
            weeksCompleted: 0,
            sessionsCompleted: 0,
            consecutiveWeeksTraining: 0,
            averageRIR: progression.averageRIR,
            averageSessionRPE: progression.averageSessionRPE,
            perceivedRecovery: progression.perceivedRecovery,
            lastPlanId:
                extra[TrainingExtraKeys.activePlanId]?.toString() ??
                progression.lastPlanId,
            lastPlanChangeReason: action,
            lastAdaptationAt: appendAdaptationHistory
                ? now
                : progression.lastAdaptationAt,
            adaptationHistory: adaptationHistory,
          )
        : TrainingProgressionStateV1(
            weeksCompleted: progression.weeksCompleted,
            sessionsCompleted: progression.sessionsCompleted,
            consecutiveWeeksTraining: progression.consecutiveWeeksTraining,
            averageRIR: progression.averageRIR,
            averageSessionRPE: progression.averageSessionRPE,
            perceivedRecovery: progression.perceivedRecovery,
            lastPlanId:
                extra[TrainingExtraKeys.activePlanId]?.toString() ??
                progression.lastPlanId,
            lastPlanChangeReason: action,
            lastAdaptationAt: appendAdaptationHistory
                ? now
                : progression.lastAdaptationAt,
            adaptationHistory: adaptationHistory,
          );

    await _persistProgressionState(
      client: client,
      progression: updatedProgression,
      syncCycleWeek: true,
    );
  }

  TrainingProgressionStateV1 _readProgressionFromExtra(
    Map<String, dynamic> extra,
  ) {
    final raw = extra[TrainingExtraKeys.trainingProgressionStateV1];
    if (raw is Map<String, dynamic>) {
      return TrainingProgressionStateV1.fromJson(raw);
    }
    if (raw is Map) {
      return TrainingProgressionStateV1.fromJson(raw.cast<String, dynamic>());
    }

    return TrainingProgressionStateV1(
      weeksCompleted: 0,
      sessionsCompleted: 0,
      consecutiveWeeksTraining: 0,
      averageRIR: 0,
      averageSessionRPE: 0,
      perceivedRecovery: 0,
      lastPlanId: extra[TrainingExtraKeys.activePlanId]?.toString() ?? '',
      lastPlanChangeReason: 'default',
    );
  }

  TrainingEvaluationSnapshotV1? _readEvaluationFromExtra(
    Map<String, dynamic> extra,
  ) {
    final raw = extra[TrainingExtraKeys.trainingEvaluationSnapshotV1];
    if (raw is Map<String, dynamic>) {
      return TrainingEvaluationSnapshotV1.fromJson(raw);
    }
    if (raw is Map) {
      return TrainingEvaluationSnapshotV1.fromJson(raw.cast<String, dynamic>());
    }
    return null;
  }

  int _activeCycleWeek(Client client) {
    final cycle = _findActiveCycle(client);
    if (cycle == null || cycle.currentWeek <= 0) {
      return 1;
    }
    return cycle.currentWeek;
  }

  Future<void> _persistProgressionState({
    required Client client,
    required TrainingProgressionStateV1 progression,
    required bool syncCycleWeek,
  }) async {
    final extra = Map<String, dynamic>.from(client.training.extra);
    extra[TrainingExtraKeys.trainingProgressionStateV1] = progression.toJson();

    final updatedClient = syncCycleWeek
        ? _syncClientCycleWeek(
            client: client,
            extra: extra,
            progression: progression,
          )
        : client.copyWith(training: client.training.copyWith(extra: extra));

    await ref.read(clientRepositoryProvider).saveClient(updatedClient);
    await ref.read(clientsProvider.notifier).refresh();
  }

  Client _syncClientCycleWeek({
    required Client client,
    required Map<String, dynamic> extra,
    required TrainingProgressionStateV1 progression,
  }) {
    final cycles = client.trainingCycles;
    final activeIndex = cycles.indexWhere((cycle) => cycle.status == 'active');
    if (activeIndex == -1) {
      return client.copyWith(training: client.training.copyWith(extra: extra));
    }

    final activeCycle = cycles[activeIndex];
    final desiredWeek = progression.weeksCompleted + 1;
    final updatedCycle = activeCycle.copyWith(
      currentWeek: desiredWeek > activeCycle.currentWeek
          ? desiredWeek
          : activeCycle.currentWeek,
      updatedAt: DateTime.now(),
    );

    final updatedCycles = List<TrainingCycle>.from(cycles);
    updatedCycles[activeIndex] = updatedCycle;

    return client.copyWith(
      training: client.training.copyWith(extra: extra),
      trainingCycles: updatedCycles,
    );
  }

  Future<void> closeWeekExplicit(String clientId, int weekNumber) async {
    final client = await ref
        .read(clientRepositoryProvider)
        .getClientById(clientId);
    if (client == null) return;

    final extra = Map<String, dynamic>.from(client.training.extra);
    final progressionRaw = extra[TrainingExtraKeys.trainingProgressionStateV1];

    final progression = progressionRaw is Map
        ? TrainingProgressionStateV1.fromJson(
            Map<String, dynamic>.from(progressionRaw),
          )
        : TrainingProgressionStateV1(
            weeksCompleted: 0,
            sessionsCompleted: 0,
            consecutiveWeeksTraining: 0,
            averageRIR: 3.0,
            averageSessionRPE: 7.0,
            perceivedRecovery: 3.0,
            lastPlanId: extra[TrainingExtraKeys.activePlanId]?.toString() ?? '',
            lastPlanChangeReason: 'week_closed_explicit',
          );

    final targetWeeksCompleted = weekNumber > progression.weeksCompleted
        ? weekNumber
        : progression.weeksCompleted;

    final updatedProgression = TrainingProgressionStateV1(
      weeksCompleted: targetWeeksCompleted,
      sessionsCompleted: progression.sessionsCompleted,
      consecutiveWeeksTraining:
          progression.consecutiveWeeksTraining < targetWeeksCompleted
          ? targetWeeksCompleted
          : progression.consecutiveWeeksTraining,
      averageRIR: progression.averageRIR,
      averageSessionRPE: progression.averageSessionRPE,
      perceivedRecovery: progression.perceivedRecovery,
      lastPlanId: progression.lastPlanId,
      lastPlanChangeReason: 'week_closed_explicit',
    );
    await _persistProgressionState(
      client: client,
      progression: updatedProgression,
      syncCycleWeek: true,
    );
  }

  Map<String, double> _readIntensitySplitPercent(Map<String, dynamic> extra) {
    final raw = extra[TrainingExtraKeys.seriesTypePercentSplit];
    if (raw is! Map) {
      return const {'heavy': 20, 'medium': 60, 'light': 20};
    }

    final heavy = (raw['heavy'] as num?)?.toDouble() ?? 20;
    final medium = (raw['medium'] as num?)?.toDouble() ?? 60;
    final light = (raw['light'] as num?)?.toDouble() ?? 20;
    final total = heavy + medium + light;
    if (total <= 0) {
      return const {'heavy': 20, 'medium': 60, 'light': 20};
    }

    return {
      'heavy': (heavy * 100.0) / total,
      'medium': (medium * 100.0) / total,
      'light': (light * 100.0) / total,
    };
  }

  /// Registra una sesión completada y actualiza weeklyVolumeHistory.
  ///
  /// Llama este método después de guardar un WorkoutLog.
  /// Actualiza en extra:
  ///   - 'weeklyVolumeHistory': List de {muscle, sets, weekNumber, dateIso}
  ///   - 'trainingProgressionStateV1'.sessionsCompleted ++
  Future<void> recordCompletedSession({
    required String clientId,
    required int weekNumber,
    required Map<String, int> setsByMuscle,
    required double sessionRpe,
    required double sessionRir,
    required double perceivedRecovery,
  }) async {
    final client = await ref
        .read(clientRepositoryProvider)
        .getClientById(clientId);
    if (client == null) return;

    final extra = Map<String, dynamic>.from(client.training.extra);

    // 1. Actualizar weeklyVolumeHistory
    final historyRaw = extra[TrainingExtraKeys.weeklyVolumeHistory];
    final history = historyRaw is List
        ? List<Map<String, dynamic>>.from(
            historyRaw.map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];

    for (final entry in setsByMuscle.entries) {
      history.add({
        'muscle': entry.key,
        'sets': entry.value,
        'weekNumber': weekNumber,
        'dateIso': DateTime.now().toIso8601String(),
        'rpe': sessionRpe,
        'rir': sessionRir,
      });
    }
    extra[TrainingExtraKeys.weeklyVolumeHistory] = history;

    // 2. Actualizar trainingProgressionStateV1
    final progressionRaw = extra[TrainingExtraKeys.trainingProgressionStateV1];
    final progression = progressionRaw is Map
        ? TrainingProgressionStateV1.fromJson(
            Map<String, dynamic>.from(progressionRaw),
          )
        : TrainingProgressionStateV1(
            weeksCompleted: 0,
            sessionsCompleted: 0,
            consecutiveWeeksTraining: 0,
            averageRIR: sessionRir,
            averageSessionRPE: sessionRpe,
            perceivedRecovery: perceivedRecovery,
            lastPlanId: '',
            lastPlanChangeReason: 'session_logged',
          );

    final totalSessions = progression.sessionsCompleted + 1;
    // Media móvil simple de RPE/RIR/recovery
    final n = totalSessions.toDouble();
    final updatedProgression = TrainingProgressionStateV1(
      weeksCompleted: progression.weeksCompleted,
      sessionsCompleted: totalSessions,
      consecutiveWeeksTraining: progression.consecutiveWeeksTraining,
      averageRIR: ((progression.averageRIR * (n - 1)) + sessionRir) / n,
      averageSessionRPE:
          ((progression.averageSessionRPE * (n - 1)) + sessionRpe) / n,
      perceivedRecovery:
          ((progression.perceivedRecovery * (n - 1)) + perceivedRecovery) / n,
      lastPlanId: progression.lastPlanId,
      lastPlanChangeReason: progression.lastPlanChangeReason,
    );

    // 3a. Escribir WorkoutLog en workout_logs para DeloadTriggerEngine
    // Construimos un log agregado de la sesión con los datos que tenemos
    final workoutLogId =
        'wl_${clientId}_${DateTime.now().millisecondsSinceEpoch}';
    final workoutLog = WorkoutLog(
      id: workoutLogId,
      userId: clientId,
      programId:
          client.training.extra[TrainingExtraKeys.activePlanId]?.toString() ??
          '',
      plannedSessionId: 'week_${weekNumber}_manual',
      startTime: DateTime.now().subtract(const Duration(minutes: 60)),
      endTime: DateTime.now(),
      exerciseLogs: const [], // Agregado, no por ejercicio
      sessionRpe: sessionRpe,
      perceivedRecoveryStatus: perceivedRecovery,
      muscleSoreness: 3.0, // Default conservador
      adherencePercentage: 100.0,
      completed: true,
      createdAt: DateTime.now(),
    );
    try {
      await WorkoutLogRepository.saveLog(workoutLog);
    } catch (e) {
      debugPrint('⚠️ [Bitácora] No se pudo guardar WorkoutLog: $e');
    }

    // 3b. Auto-incrementar weeksCompleted si sessionsCompleted alcanza
    //     el umbral de sesiones por semana (daysPerWeek)
    final daysPerWeek =
        (client.training.extra[TrainingExtraKeys.daysPerWeek] as num?)
            ?.toInt() ??
        4;
    final newSessionsCompleted = updatedProgression.sessionsCompleted;
    final expectedSessionsForNextWeek =
        (updatedProgression.weeksCompleted + 1) * daysPerWeek;

    final shouldIncrementWeek =
        newSessionsCompleted >= expectedSessionsForNextWeek;

    final finalProgression = shouldIncrementWeek
        ? TrainingProgressionStateV1(
            weeksCompleted: updatedProgression.weeksCompleted + 1,
            sessionsCompleted: newSessionsCompleted,
            consecutiveWeeksTraining:
                updatedProgression.consecutiveWeeksTraining + 1,
            averageRIR: updatedProgression.averageRIR,
            averageSessionRPE: updatedProgression.averageSessionRPE,
            perceivedRecovery: updatedProgression.perceivedRecovery,
            lastPlanId: updatedProgression.lastPlanId,
            lastPlanChangeReason: 'auto_week_advance',
          )
        : updatedProgression;

    extra[TrainingExtraKeys.trainingProgressionStateV1] = finalProgression
        .toJson();

    if (shouldIncrementWeek) {
      debugPrint(
        '📅 [Bitácora] Semana ${finalProgression.weeksCompleted} completada automáticamente',
      );
    }

    // 3. Persistir en SQLite
    await ref
        .read(clientRepositoryProvider)
        .saveClient(
          client.copyWith(training: client.training.copyWith(extra: extra)),
        );
    await ref.read(clientsProvider.notifier).refresh();

    debugPrint(
      '✅ [Bitácora] Semana $weekNumber registrada. '
      'Músculos: ${setsByMuscle.keys.join(", ")}. '
      'Sesiones totales: $totalSessions',
    );
  }
}

/// Provider: Expone el estado y el notificador a la UI
final trainingPlanProvider =
    NotifierProvider<TrainingPlanNotifier, TrainingPlanState>(
      TrainingPlanNotifier.new,
    );
