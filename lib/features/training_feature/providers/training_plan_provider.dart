import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/generated_plan.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
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
import 'package:hcs_app_lap/utils/date_helpers.dart';
// ✅ MOTOR V3 REAL - PIPELINE CIENTÍFICO COMPLETO
import 'package:hcs_app_lap/domain/training_v3/orchestrator/training_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
// VopSnapshot SSOT
import 'package:hcs_app_lap/domain/training/vop_snapshot.dart';
import 'package:hcs_app_lap/features/training_feature/context/vop_context.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training/services/active_cycle_bootstrapper.dart';

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
      return TrainingPlanState(vopByMuscle: vopByMuscle);
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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
        state = const TrainingPlanState();
        return;
      }

      // (A) Priorizar activePlanId
      final activeConfig = _findActivePlanConfigById(client);
      final chosen = activeConfig ?? _findLatestPlan(client.trainingPlans);

      if (chosen == null) {
        state = const TrainingPlanState();
        return;
      }

      final derived = TrainingPlanMapper.toGeneratedPlan(chosen);
      state = TrainingPlanState(plan: derived);
    } catch (e) {
      debugPrint('❌ Error en loadPersistedActivePlanIfAny: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar plan persistido: $e',
      );
    }
  }

  /// Obtiene o crea un TrainingCycle activo para el cliente.
  ///
  /// REGLAS:
  /// (A) Si activeCycleId existe y el ciclo está en trainingCycles → usarlo
  /// (B) Si NO existe → crear uno nuevo basado en perfil + evaluación
  /// (C) Persistir el ciclo en client.trainingCycles y setear activeCycleId
  /// (D) Guardar cliente actualizado en repositorio
  Future<TrainingCycle?> _getOrCreateActiveCycle({
    required Client client,
    required TrainingProfile profile,
    required DateTime startDate,
  }) async {
    try {
      // (A) Buscar ciclo activo existente
      if (client.activeCycleId != null && client.activeCycleId!.isNotEmpty) {
        try {
          final existing = client.trainingCycles.firstWhere(
            (c) => c.cycleId == client.activeCycleId,
          );
          debugPrint(
            '[TrainingPlanProvider] Usando ciclo activo existente: ${client.activeCycleId}',
          );
          return existing;
        } on StateError {
          // activeCycleId no coincide con ningún ciclo existente
          debugPrint(
            '[TrainingPlanProvider] activeCycleId="${client.activeCycleId}" no encontrado en trainingCycles',
          );
        } catch (e) {
          // Ciclo no encontrado, crear uno nuevo
          debugPrint(
            '[TrainingPlanProvider] Ciclo activo no encontrado, creando nuevo',
          );
        }
      }

      // (B) Crear nuevo ciclo
      final cycleId =
          'tc_${client.id}_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';

      // Obtener goal y músculos prioritarios del perfil
      final goal = profile.extra['goal'] as String? ?? 'hipertrofia_general';
      final priorityMuscles = _extractPriorityMuscles(profile);
      final splitType =
          profile.extra['splitType'] as String? ?? 'torso_pierna_4d';

      // Construir mapa base de ejercicios (vacío por ahora, se completará después)
      final baseExercises = <String, List<String>>{};
      for (final muscle in priorityMuscles) {
        baseExercises[muscle] = [];
      }

      final newCycle = TrainingCycle(
        cycleId: cycleId,
        startDate: startDate,
        goal: goal,
        priorityMuscles: priorityMuscles,
        splitType: splitType,
        baseExercisesByMuscle: baseExercises,
        phaseState: 'VME',
        currentWeek: 1,
        createdAt: DateTime.now(),
      );

      // (C) Persistir ciclo
      final updatedCycles = List<TrainingCycle>.from(client.trainingCycles)
        ..add(newCycle);
      final updatedClient = client.copyWith(
        trainingCycles: updatedCycles,
        activeCycleId: cycleId,
      );

      // (D) Guardar en repositorio
      await ref.read(clientRepositoryProvider).saveClient(updatedClient);

      debugPrint('[TrainingPlanProvider] Nuevo ciclo creado: $cycleId');
      return newCycle;
    } catch (e) {
      debugPrint('❌ Error en _getOrCreateActiveCycle: $e');
      return null;
    }
  }

  /// Extrae músculos prioritarios del perfil
  List<String> _extractPriorityMuscles(TrainingProfile profile) {
    final extra = profile.extra;
    final primary = (extra['priorityMusclesPrimary'] as String? ?? '')
        .split(',')
        .where((m) => m.trim().isNotEmpty)
        .toList();
    final secondary = (extra['priorityMusclesSecondary'] as String? ?? '')
        .split(',')
        .where((m) => m.trim().isNotEmpty)
        .toList();
    final tertiary = (extra['priorityMusclesTertiary'] as String? ?? '')
        .split(',')
        .where((m) => m.trim().isNotEmpty)
        .toList();

    final all = <String>{};
    all.addAll(primary);
    all.addAll(secondary);
    all.addAll(tertiary);

    return all.toList();
  }

  /// Genera un plan basado en el perfil de entrenamiento (usa TrainingProgramEngine 1→8)
  Future<void> generatePlan({
    required TrainingProfile profile,
    String? forDateIso,
  }) async {
    state = state.copyWith(isLoading: true, missingFields: const []);
    try {
      // Preparar inputs
      final normalizedProfile = profile.normalizedFromExtra();

      // VALIDACIÓN TEMPRANA Y MENSAJES ESPECÍFICOS
      final missingFields = <String>[];

      if (normalizedProfile.trainingLevel == null) {
        missingFields.add(
          'Selecciona tu nivel de experiencia (Principiante, Intermedio, Avanzado)',
        );
      }

      if (normalizedProfile.daysPerWeek <= 0) {
        missingFields.add('Selecciona cuántos días por semana vas a entrenar');
      }

      if (normalizedProfile.timePerSessionMinutes <= 0) {
        missingFields.add(
          'Selecciona cuánto tiempo por sesión tienes disponible',
        );
      }

      // Verificar si hay ALGÚN dato de volumen/músculos
      final hasPriorityMuscles =
          normalizedProfile.priorityMusclesPrimary.isNotEmpty ||
          normalizedProfile.priorityMusclesSecondary.isNotEmpty ||
          normalizedProfile.priorityMusclesTertiary.isNotEmpty;
      final hasBaseVolume = normalizedProfile.baseVolumePerMuscle.values.any(
        (value) => value > 0,
      );
      final hasSeriesDistribution = normalizedProfile.seriesDistribution.values
          .any((dist) => dist.values.any((value) => value > 0));

      // Solo bloquear si NO hay NINGÚN dato de volumen
      if (!hasBaseVolume && !hasSeriesDistribution && !hasPriorityMuscles) {
        missingFields.add(
          'Define músculos prioritarios: arrastra músculos a Primarios, Secundarios o Terciarios',
        );
      }

      if (missingFields.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🚫 BLOQUEADO - Campos faltantes:');
          for (var i = 0; i < missingFields.length; i++) {
            debugPrint('  ${i + 1}. ${missingFields[i]}');
          }
        }
        state = TrainingPlanState.blocked(
          reason: 'Faltan datos críticos del perfil de entrenamiento',
          suggestions: missingFields,
          missingFields: missingFields,
        );
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ Validación pasada - Generando plan...');
      }

      // PASO 0: Recargar Client desde repositorio para obtener último TrainingProfile
      final clientId = ref.read(clientsProvider).value?.activeClient?.id;
      if (clientId == null) {
        state = state.copyWith(
          isLoading: false,
          error: "No hay cliente activo para recargar.",
        );
        return;
      }

      final freshClient = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      if (freshClient == null) {
        state = state.copyWith(
          isLoading: false,
          error: "No se pudo recargar el cliente desde BD.",
        );
        return;
      }

      // ═══════════════════════════════════════════════════════════════
      // SSOT: Si ya hay activePlanId y existe ese plan, NO regenerar.
      // Esto evita regeneración por entrar/salir si alguna UI dispara generatePlan.
      // ═══════════════════════════════════════════════════════════════
      final activeConfig = _findActivePlanConfigById(freshClient);
      if (activeConfig != null) {
        final derived = TrainingPlanMapper.toGeneratedPlan(activeConfig);
        debugPrint(
          '[TrainingPlanProvider] activePlanId encontrado -> skip regen',
        );
        state = TrainingPlanState(plan: derived);
        return;
      }

      // ─────────────────────────────────────────────────────────────
      // VALIDACIÓN CRÍTICA PARA MOTOR V2 (TrainingContextBuilder)
      // Requiere gender + ageYears (Personal Data).
      // ─────────────────────────────────────────────────────────────
      final resolvedGender =
          freshClient.training.gender ?? freshClient.profile.gender;
      final resolvedAgeYears =
          freshClient.training.age ?? freshClient.profile.age;

      final missingCritical = <String>[];
      if (resolvedGender == null) {
        missingCritical.add('Completa el sexo (gender) en Personal Data');
      }
      if (resolvedAgeYears == null) {
        missingCritical.add('Completa la edad (age) en Personal Data');
      }

      if (missingCritical.isNotEmpty) {
        state = TrainingPlanState.blocked(
          reason: 'Faltan datos críticos para generar el plan (Motor V3)',
          suggestions: missingCritical,
          missingFields: missingCritical,
        );
        return;
      }

      // Usar explícitamente el TrainingProfile del cliente recargado
      final trainingProfile = freshClient.training;
      debugPrint('✅ Cliente recargado: $clientId');
      debugPrint(
        '✅ TrainingProfile extra keys: ${trainingProfile.extra.keys.length}',
      );

      // Fecha activa para el plan
      final activeDateIso =
          forDateIso ?? dateIsoFrom(ref.read(globalDateProvider));
      final startDate = DateTime.parse(activeDateIso);

      // ═══════════════════════════════════════════════════════════════════════
      // GUARDRAIL: Evitar regeneración silenciosa si ya existe plan para esa fecha
      // ═══════════════════════════════════════════════════════════════════════
      final existing = freshClient.trainingPlans.where(
        (p) =>
            p.startDate.year == startDate.year &&
            p.startDate.month == startDate.month &&
            p.startDate.day == startDate.day,
      );

      if (existing.isNotEmpty) {
        final latestSameDay = existing.reduce(
          (a, b) => a.startDate.isAfter(b.startDate) ? a : b,
        );
        final derived = TrainingPlanMapper.toGeneratedPlan(latestSameDay);

        if (kDebugMode) {
          debugPrint(
            '✅ Plan ya existe para $activeDateIso. Usando el persistido (sin regenerar).',
          );
        }

        state = TrainingPlanState(plan: derived);
        return;
      }

      // Generar plan vía Motor V3 (persistencia obligatoria dentro)
      final exercises = await ExerciseCatalogLoader.load();

      // ═══════════════════════════════════════════════════════════════════════
      // PASO 1: Obtener o crear TrainingCycle activo
      // ═══════════════════════════════════════════════════════════════════════
      final activeCycle = await _getOrCreateActiveCycle(
        client: freshClient,
        profile: trainingProfile,
        startDate: startDate,
      );

      if (activeCycle == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo crear el ciclo de entrenamiento',
        );
        return;
      }

      // ═══════════════════════════════════════════════════════════════════════
      // MOTOR V3 REAL - PIPELINE CIENTÍFICO COMPLETO (7 MDs)
      // ═══════════════════════════════════════════════════════════════════════
      debugPrint('🚀 [Motor V3] Generando plan con pipeline científico...');

      // Crear Motor V3 con estrategia científica pura (RuleBasedStrategy)
      final motorV3 = TrainingOrchestratorV3(
        strategy: RuleBasedStrategy(), // 100% científico basado en 7 MDs
      );

      // Generar plan con Motor V3 REAL
      TrainingProgramV3Result resultV3;
      try {
        resultV3 = await motorV3.generatePlan(
          client: freshClient,
          exercises: exercises,
          asOfDate: startDate,
        );
      } catch (e, stackTrace) {
        debugPrint('❌ [Motor V3] Error durante generación: $e');
        debugPrint('Stack trace: $stackTrace');

        state = state.copyWith(
          isLoading: false,
          error: 'Error en Motor V3: $e',
        );
        return;
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
        return;
      }

      // Extraer plan generado
      final planConfig = resultV3.plan!;

      debugPrint(
        '✅ [Motor V3] Plan generado: ${planConfig.weeks.length} semanas, '
        '${planConfig.weeks.fold<int>(0, (sum, w) => sum + w.sessions.length)} sesiones',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // P0-BLOQUEANTE: PERSISTIR PLAN EN client.trainingPlans
      // ═══════════════════════════════════════════════════════════════════════

      debugPrint(
        '💾 [Motor V3][Persistence] Añadiendo plan a client.trainingPlans...',
      );

      // 1. Crear lista actualizada de planes (sin duplicados)
      final updatedPlans = [
        ...freshClient.trainingPlans.where((p) => p.id != planConfig.id),
        planConfig,
      ];

      debugPrint('   Planes antes: ${freshClient.trainingPlans.length}');
      debugPrint('   Planes después: ${updatedPlans.length}');
      debugPrint('   Plan ID: ${planConfig.id}');

      // 2. Actualizar activePlanId en training.extra
      final updatedExtra = Map<String, dynamic>.from(
        freshClient.training.extra,
      );
      updatedExtra[TrainingExtraKeys.activePlanId] = planConfig.id;

      debugPrint(
        '✅ [Motor V3][Persistence] activePlanId actualizado: ${planConfig.id}',
      );

      // 3. Crear cliente actualizado con plan persistido
      final clientWithPlan = freshClient.copyWith(
        trainingPlans: updatedPlans,
        training: freshClient.training.copyWith(extra: updatedExtra),
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

      // ═══════════════════════════════════════════════════════════════════════

      // Mapper de compatibilidad para UI legacy (GeneratedPlan derivado)
      final plan = TrainingPlanMapper.toGeneratedPlan(planConfig);

      // Recargar cliente después de persistencia
      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: "No hay cliente activo después de persistencia.",
        );
        return;
      }

      final now = DateTime.now();

      // =====================================================
      // FIX DEFINITIVO TAB 3 — DERIVAR MAPAS UI
      // =====================================================

      final Map<String, double> targetSetsByMuscleUi = {};
      final Map<String, double> finalTargetSetsByMuscleUi = {};

      // 1️⃣ targetSetsByMuscleUi = copia plana (UI necesita mapa simple)
      final rawTargetSets =
          planConfig.trainingProfileSnapshot?.extra[TrainingExtraKeys
                  .targetSetsByMuscleUi]
              as Map<String, dynamic>?;

      if (rawTargetSets != null) {
        rawTargetSets.forEach((k, v) {
          targetSetsByMuscleUi[k] = (v as num).toDouble();
        });
      }

      // 2️⃣ finalTargetSetsByMuscleUi = suma total por músculo
      final rawPriorityIntensity =
          planConfig.trainingProfileSnapshot?.extra[TrainingExtraKeys
                  .intensityProfiles]
              as Map<String, dynamic>?;

      if (rawPriorityIntensity != null) {
        rawPriorityIntensity.forEach((muscle, priorityMap) {
          double total = 0;

          (priorityMap as Map<String, dynamic>).forEach((_, intensityMap) {
            (intensityMap as Map<String, dynamic>).forEach((_, sets) {
              total += (sets as num).toDouble();
            });
          });

          finalTargetSetsByMuscleUi[muscle] = total;
        });
      }

      // Persist using a merge to avoid clobbering concurrent training.extra changes
      await ref.read(clientsProvider.notifier).updateActiveClient((current) {
        var extra = Map<String, dynamic>.from(current.training.extra);

        // ✅ AGREGAR MAPAS UI DERIVADOS AL EXTRA
        extra[TrainingExtraKeys.targetSetsByMuscleUi] = targetSetsByMuscleUi;
        extra[TrainingExtraKeys.finalTargetSetsByMuscleUi] =
            finalTargetSetsByMuscleUi;

        // Persistir aprendizajes/snapshot del motor al perfil del cliente (extra).
        final snapshotExtra = planConfig.trainingProfileSnapshot?.extra;
        if (snapshotExtra != null && snapshotExtra.isNotEmpty) {
          // ═══════════════════════════════════════════════════════════════
          // BLINDAJE DEFENSIVO: Persistir solo keys críticas para Tab 3
          // Esto evita que futuros refactors rompan Tab 3 silenciosamente
          // ═══════════════════════════════════════════════════════════════
          for (final entry in snapshotExtra.entries) {
            if (entry.key == TrainingExtraKeys.targetSetsByMuscleUi ||
                entry.key == TrainingExtraKeys.finalTargetSetsByMuscleUi ||
                entry.key == 'targetSetsByMuscle' ||
                entry.key == 'finalTargetSetsByMuscle' ||
                entry.key == 'mevByMuscle' ||
                entry.key == 'mrvByMuscle' ||
                entry.key == 'vmrByMuscleRole' ||
                entry.key == TrainingExtraKeys.trainingExtraVersion) {
              extra[entry.key] = entry.value;
            }
          }
        }

        // ═══════════════════════════════════════════════════════════════
        // ✨ NEW: Crear VopSnapshot como SSOT
        // Escrito una sola vez aquí (Tab 2 writer), leído por Tabs 1, 3, 4
        // ═══════════════════════════════════════════════════════════════

        // PASO 1 (SSOT REAL): Normalizar + expandir legacy -> 14 canónicos
        // Esto sí maneja 'back' y 'shoulders' (no solo *_group)
        final canonicalVop = normalizeLegacyVopToCanonical(
          finalTargetSetsByMuscleUi.map((k, v) => MapEntry(k, v.toInt())),
        );

        // PASO 2: Enforce 14 keys como SSOT (con 0 si faltan)
        // Importante para que el snapshot siempre sea estable.
        const all = MuscleKeys.all;
        final stabilized = <String, int>{};
        for (final k in all) {
          stabilized[k] = canonicalVop[k] ?? 0;
        }

        // PASO 3: Validación fuerte (si tus reglas exigen que estén todos >0, cámbialo a >0)
        assert(
          stabilized.length == 14,
          'VOP inválido: deben existir exactamente 14 músculos canónicos, tiene ${stabilized.length}',
        );

        // PASO 4: Persistir snapshot ya estabilizado
        final vopSnapshot = _buildVopSnapshot(
          setsByMuscle: stabilized,
          source: 'auto',
        );
        if (vopSnapshot != null) {
          extra = VopContext.writeSnapshot(extra, vopSnapshot);
          debugPrint(
            '[TRAINING][SSOT] VopSnapshot creado (muscles='
            '${vopSnapshot.setsByMuscle.length}, keys=${vopSnapshot.setsByMuscle.keys.toList()})',
          );
        }

        // ═══════════════════════════════════════════════════════════════
        // CAPA DEFENSIVA: Generar mapas UI localmente si no existen
        // (respaldo por si el motor no los generó correctamente)
        // ═══════════════════════════════════════════════════════════════
        if (!extra.containsKey(TrainingExtraKeys.targetSetsByMuscleUi) ||
            !extra.containsKey(TrainingExtraKeys.finalTargetSetsByMuscleUi)) {
          // 1. targetSetsByMuscleUi: copia directa de targetSetsByMuscle
          final targetSetsByMuscle =
              extra[TrainingExtraKeys.targetSetsByMuscleUi] as Map?;
          if (targetSetsByMuscle != null) {
            final Map<String, double> targetSetsByMuscleUi = {};
            targetSetsByMuscle.forEach((muscle, value) {
              targetSetsByMuscleUi[muscle.toString()] = (value as num)
                  .toDouble();
            });
            extra[TrainingExtraKeys.targetSetsByMuscleUi] =
                targetSetsByMuscleUi;
          }

          // 2. finalTargetSetsByMuscleUi: síntesis de prioridades/intensidades
          // Usa el split final si existe
          final targetSetsByMusclePriorityIntensity =
              extra[TrainingExtraKeys.intensityProfiles] as Map? ?? {};
          final Map<String, Map<String, num>> finalTargetSetsByMuscleUi = {};

          if (targetSetsByMusclePriorityIntensity.isNotEmpty) {
            targetSetsByMusclePriorityIntensity.forEach((muscle, priorityMap) {
              double total = 0;
              if (priorityMap is Map) {
                priorityMap.forEach((_, intensityMap) {
                  if (intensityMap is Map) {
                    intensityMap.forEach((_, sets) {
                      total += (sets as num?)?.toDouble() ?? 0;
                    });
                  }
                });
              }
              finalTargetSetsByMuscleUi[muscle.toString()] = {'total': total};
            });
          } else {
            // Fallback: usar targetSetsByMuscle si prioridad/intensidad no existe
            final targetSetsByMuscle =
                extra[TrainingExtraKeys.targetSetsByMuscleUi] as Map?;
            if (targetSetsByMuscle != null) {
              targetSetsByMuscle.forEach((muscle, value) {
                finalTargetSetsByMuscleUi[muscle.toString()] = {
                  'total': (value as num).toDouble(),
                };
              });
            }
          }

          if (finalTargetSetsByMuscleUi.isNotEmpty) {
            extra[TrainingExtraKeys.finalTargetSetsByMuscleUi] =
                finalTargetSetsByMuscleUi;
          }
        }

        // ═══════════════════════════════════════════════════════════════
        // VALIDACIÓN FINAL: Verificar que los mapas UI existen
        // Si aún no existen, lanzar error informativo
        // ═══════════════════════════════════════════════════════════════
        if (!extra.containsKey(TrainingExtraKeys.targetSetsByMuscleUi) ||
            !extra.containsKey(TrainingExtraKeys.finalTargetSetsByMuscleUi)) {
          final hasUiFinal = extra.containsKey(
            TrainingExtraKeys.finalTargetSetsByMuscleUi,
          );
          final hasUiTarget = extra.containsKey(
            TrainingExtraKeys.targetSetsByMuscleUi,
          );
          debugPrint(
            '[TRAINING][ERROR] Mapas UI no pudieron ser generados:\n'
            '  - targetSetsByMuscleUi: $hasUiTarget\n'
            '  - finalTargetSetsByMuscleUi: $hasUiFinal\n'
            '  - targetSetsByMuscle disponible: ${extra.containsKey('targetSetsByMuscle')}\n'
            '  - targetSetsByMusclePriorityIntensity disponible: ${extra.containsKey('targetSetsByMusclePriorityIntensity')}\n'
            '  Keys en extra: ${extra.keys.toList()}',
          );
        }

        final records = _readPlanRecords(
          extra[TrainingExtraKeys.generatedPlanRecords],
        );
        records.removeWhere(
          (record) =>
              record[TrainingExtraKeys.forDateIso]?.toString() == activeDateIso,
        );
        records.add({
          TrainingExtraKeys.forDateIso: activeDateIso,
          TrainingExtraKeys.generatedAtIso: now.toIso8601String(),
          // Decision traces NO se guardan en Firestore (solo para debugging en memoria)
        });
        records.sort((a, b) {
          final left = a[TrainingExtraKeys.forDateIso]?.toString() ?? '';
          final right = b[TrainingExtraKeys.forDateIso]?.toString() ?? '';
          return left.compareTo(right);
        });
        extra[TrainingExtraKeys.generatedPlanRecords] = records;
        // Decision traces NO se persisten en Firestore (datos de debugging)
        extra[TrainingExtraKeys.generatedAtIso] = now.toIso8601String();
        extra[TrainingExtraKeys.forDateIso] = activeDateIso;
        // Nota: trainingPlanConfig se guarda en client.trainingPlans (colección fuerte),
        // NO en extra (para evitar problemas de serialización con Firestore)
        // plan.toMap() TAMPOCO se guarda en extra - el plan completo ya está en trainingPlans

        // ═══════════════════════════════════════════════════════════════════════
        // ACTUALIZACIÓN DE CLIENTE SOLO PARA EXTRA (mapas UI, metadata)
        // El plan YA FUE persistido en trainingPlans por Motor V3
        // ═══════════════════════════════════════════════════════════════════════
        return current.copyWith(
          training: current.training.copyWith(extra: extra),
        );
      });

      state = state.copyWith(
        isLoading: false,
        plan: plan,
        missingFields: const [],
      );
    } on TrainingPlanBlockedException catch (blocked) {
      // Bloqueo controlado del motor
      state = TrainingPlanState.blocked(
        reason: blocked.reason,
        suggestions: blocked.suggestions,
      );
    } catch (e) {
      // Error técnico inesperado
      state = state.copyWith(
        isLoading: false,
        error: 'Error técnico: ${e.toString()}',
        missingFields: const [],
      );
    }
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
        try {
          currentCycle = workingClient.trainingCycles.firstWhere(
            (c) => c.cycleId == workingClient.activeCycleId,
          );
        } on StateError {
          // activeCycleId no coincide con ningún ciclo existente
          debugPrint(
            '⚠️ activeCycleId="${workingClient.activeCycleId}" no encontrado en ${workingClient.trainingCycles.length} ciclos',
          );
          currentCycle = null;
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

      // Fail-fast si después de bootstrap aún no hay ciclo
      if (workingClient.trainingCycles.isEmpty ||
          workingClient.activeCycleId == null) {
        throw Exception('No hay ciclo activo. No se pudo bootstrapear.');
      }

      TrainingCycle? activeCycle;
      try {
        activeCycle = workingClient.trainingCycles.firstWhere(
          (c) => c.cycleId == workingClient.activeCycleId,
        );
      } on StateError {
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
      final vopContext = VopContext.ensure(workingClient.training.extra);
      final vopMap = vopContext?.snapshot.setsByMuscle ?? {};

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

      // 4.1 Validar VOP con cobertura indirecta (post-plan)
      final directVopByMuscle = <String, double>{};
      vopMap.forEach((k, v) {
        directVopByMuscle[normalizeMuscleKey(k)] = v.toDouble();
      });

      final mevByMuscle = <String, double>{};
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
      state = TrainingPlanState(plan: plan, vopByMuscle: state.vopByMuscle);

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
  Future<void> generatePlanV3({required DateTime selectedDate}) async {
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
  /// 2. Limpiar activePlanId y activeCycleId de training.extra
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

      // Limpiar activePlanId Y activeCycleId
      final updatedExtra = Map<String, dynamic>.from(client.training.extra);
      updatedExtra.remove(TrainingExtraKeys.activePlanId);
      updatedExtra.remove('activeCycleId');

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

      // ✅ CRÍTICO: Esperar sincronización de Firestore
      debugPrint('⏳ Esperando sincronización de Firestore (3 segundos)...');
      await Future.delayed(const Duration(seconds: 3));
      debugPrint('✅ Sincronización completa (asumida)');

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
      debugPrint(
        '   activeCycleId: ${verifyClient?.training.extra['activeCycleId']}',
      );

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
}

/// Provider: Expone el estado y el notificador a la UI
final trainingPlanProvider =
    NotifierProvider<TrainingPlanNotifier, TrainingPlanState>(
      TrainingPlanNotifier.new,
    );
