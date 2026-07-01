// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_domain/pain_rule.dart';
import 'package:hcs_app_lap/domain/training_domain/training_evaluation_migration_service.dart';
import 'package:hcs_app_lap/domain/training_domain/training_evaluation_snapshot_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_plan_decision_service.dart';
import 'package:hcs_app_lap/domain/training_domain/training_plan_governor.dart';
import 'package:hcs_app_lap/domain/training_domain/training_progression_state_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_setup_v1.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_workspace_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_pipeline_guard.dart';
import 'package:hcs_app_lap/features/training_feature/tabs/training_interview_tab.dart';
import 'package:hcs_app_lap/features/training_feature/screens/gym_exercises_stage_screen.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/intensity_split_table.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/volume_capacity_scientific_view.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/weekly_plan_detail_view.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class TrainingWorkspaceScreen extends ConsumerStatefulWidget {
  const TrainingWorkspaceScreen({super.key});

  @override
  ConsumerState<TrainingWorkspaceScreen> createState() =>
      _TrainingWorkspaceScreenState();
}

class _TrainingWorkspaceScreenState
    extends ConsumerState<TrainingWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  String? _lastClientId;
  String? _lastSeedSignature;
  bool _migrationQueued = false;
  String? _dismissedDeloadSnapshotAt;
  late TabController _v3TabController;
  final _interviewTabKey = GlobalKey<TrainingInterviewTabState>();

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _sexController = TextEditingController();

  final _daysController = TextEditingController();
  final _sessionController = TextEditingController();
  final _durationWeeksController = TextEditingController();
  final _primaryMusclesController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();
  final _tertiaryMusclesController = TextEditingController();
  final _heavyController = TextEditingController();
  final _mediumController = TextEditingController();
  final _lightController = TextEditingController();

  final _weeksCompletedController = TextEditingController();
  final _sessionsCompletedController = TextEditingController();
  final _consecutiveWeeksController = TextEditingController();
  final _avgRirController = TextEditingController();
  final _avgRpeController = TextEditingController();
  final _perceivedRecoveryController = TextEditingController();
  final _lastPlanReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 6 tabs principales: Entrevista, Landmarks, Intensidad, Preferencias de ejercicios, Plan, Monitoreo
    _v3TabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    // Dispose TabController primero (antes de los TextEditingControllers)
    // para evitar conflictos con el Ticker
    _v3TabController.dispose();

    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _sexController.dispose();
    _daysController.dispose();
    _sessionController.dispose();
    _durationWeeksController.dispose();
    _primaryMusclesController.dispose();
    _secondaryMusclesController.dispose();
    _tertiaryMusclesController.dispose();
    _heavyController.dispose();
    _mediumController.dispose();
    _lightController.dispose();
    _weeksCompletedController.dispose();
    _sessionsCompletedController.dispose();
    _consecutiveWeeksController.dispose();
    _avgRirController.dispose();
    _avgRpeController.dispose();
    _perceivedRecoveryController.dispose();
    _lastPlanReasonController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      data: (state) {
        final client = state.activeClient;
        if (client == null) {
          return const Center(child: Text('Selecciona un cliente'));
        }

        final workspaceState = ref.watch(trainingWorkspaceProvider);

        _runMigrationIfNeeded(client);

        final setup = _readSetup(client);
        final evaluation = _readEvaluation(client);
        final progression = _readProgression(client);

        _seedControllersIfNeeded(setup, evaluation, progression);

        return WorkspaceScaffold(
          header: _buildHeader(client),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          body: _buildCurrentPlanSection(
            context,
            client,
            progression,
            workspaceState.interviewStatus,
            workspaceState.flowStage,
            workspaceState.canAccessLandmarks,
            workspaceState.landmarksAreCurrent,
            workspaceState.canAccessIntensity,
            workspaceState.isIntensitySplitValid,
            workspaceState.canGeneratePlan,
            workspaceState.isPlanOutdated,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildHeader(Client client) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: kPrimaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace de Entrenamiento',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  client.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: kTextColorSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares de navegación por tabs eliminados (jerarquía aplanada)
  // El workspace ahora muestra directamente el Motor V3 con sus 9 tabs

  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  Widget _buildCurrentPlanSection(
    BuildContext context,
    Client client,
    TrainingProgressionStateV1 progression,
    TrainingInterviewStatus interviewStatus,
    TrainingFlowStage flowStage,
    bool canAccessLandmarks,
    bool landmarksAreCurrent,
    bool canAccessIntensity,
    bool isIntensitySplitValid,
    bool canGeneratePlan,
    bool isPlanOutdated,
  ) {
    final activePlanId = client.training.extra[TrainingExtraKeys.activePlanId]
        ?.toString();
    final totalPlans = client.trainingPlans.length;
    final hasAnyPlan = client.trainingPlans.isNotEmpty;
    final hasActiveId = activePlanId != null && activePlanId.isNotEmpty;

    // E2 GOBERNANZA: acción permitida y rationale delegados al provider
    final planNotifier = ref.read(trainingPlanProvider.notifier);
    final allowedAction = planNotifier.resolveAllowedAction(client);
    final actionTooltip = planNotifier.resolvePlanActionTooltip(
      client,
      allowedAction,
    );

    // Obtener plan activo o más reciente
    TrainingPlanConfig? plan;
    if (hasAnyPlan && hasActiveId) {
      plan = client.trainingPlans
          .where((p) => p.id == activePlanId)
          .firstOrNull;
    }

    if (hasAnyPlan && plan == null) {
      plan =
          (client.trainingPlans.toList()
                ..sort((a, b) => b.startDate.compareTo(a.startDate)))
              .first;
    }

    // Leer estado del motor para mostrar errores
    final motorState = ref.watch(trainingPlanProvider);
    final motorError = motorState.error;
    final motorBlocked = motorState.blockReason;
    final motorSuggestions = motorState.suggestions ?? [];
    final motorLoading = motorState.isLoading;
    final deloadAlert = _resolveDeloadAlertMessage(client);

    if (plan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetTab = switch (flowStage) {
          TrainingFlowStage.interview => 0,
          TrainingFlowStage.landmarks => 1,
          TrainingFlowStage.intensity => 2,
          TrainingFlowStage.gymExercises => 3,
          TrainingFlowStage.plan => 4,
          TrainingFlowStage.monitoring => 5,
        };
        if (_v3TabController.index != targetTab) {
          _v3TabController.animateTo(targetTab);
        }
      });
    }

    String buildGenerateBlockedTooltip() {
      if (interviewStatus != TrainingInterviewStatus.valid) {
        return 'Completa entrevista para habilitar generación';
      }
      if (flowStage != TrainingFlowStage.plan) {
        return 'Sigue el flujo: entrevista -> landmarks -> intensidad -> plan';
      }
      if (!isIntensitySplitValid) {
        return 'El split de intensidad debe sumar 100% y respetar rangos';
      }
      return actionTooltip;
    }

    final generateBlockedTooltip = buildGenerateBlockedTooltip();

    // Mostrar TabBar + TabBarView con los 9 tabs Motor V3
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Banner de carga del motor ──────────────────────────
        if (motorLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: kPrimaryColor.withAlpha(20),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Generando plan Motor V3…',
                  style: TextStyle(color: kPrimaryColor, fontSize: 13),
                ),
              ],
            ),
          ),

        // ── Banner de error del motor ──────────────────────────
        if (!motorLoading && motorError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kErrorColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kErrorColor.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: kErrorColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Error en el motor',
                      style: TextStyle(
                        color: kErrorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          ref.read(trainingPlanProvider.notifier).clearError(),
                      child: const Icon(
                        Icons.close,
                        color: kErrorColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  motorError,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        // ── Banner de plan bloqueado ───────────────────────────
        if (!motorLoading && motorBlocked != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kWarningColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kWarningColor.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: kWarningColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Plan bloqueado',
                      style: TextStyle(
                        color: kWarningColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  motorBlocked,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                ),
                if (motorSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...motorSuggestions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: kWarningColor,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: kTextColorSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // ── Banner de recomendación de deload ─────────────────────
        if (deloadAlert != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Deload recomendado',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  deloadAlert,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _dismissDeloadAlert(client),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Descartar',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextColorSecondary,
                          side: BorderSide(
                            color: kTextColorSecondary.withAlpha(80),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          await ref
                              .read(trainingPlanProvider.notifier)
                              .generatePlanFromActiveCycle(now);
                          await _updateProgressionAfterPlanAction('deload');
                        },
                        icon: const Icon(Icons.spa, size: 16),
                        label: const Text(
                          'Generar con deload',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (plan != null && interviewStatus != TrainingInterviewStatus.valid)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kCardColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              'Plan existente visible. Entrevista en edición: valida para regenerar/adaptar.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        // Header con acciones (Generar/Regenerar/Adaptar)
        Row(
          children: [
            if (!hasAnyPlan)
              Tooltip(
                message: canGeneratePlan
                    ? actionTooltip
                    : generateBlockedTooltip,
                child: ElevatedButton.icon(
                  onPressed:
                      canGeneratePlan &&
                          (allowedAction == TrainingPlanAction.generate ||
                              allowedAction == TrainingPlanAction.regenerate)
                      ? () => _generarPlan()
                      : null,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else ...[
              // Botón Regenerar (solo si permitido)
              Tooltip(
                message: interviewStatus != TrainingInterviewStatus.valid
                    ? 'Completa entrevista para habilitar regeneración/adaptación'
                    : allowedAction == TrainingPlanAction.regenerate
                    ? actionTooltip
                    : '❌ Regeneración bloqueada: $actionTooltip',
                child: ElevatedButton.icon(
                  onPressed:
                      interviewStatus == TrainingInterviewStatus.valid &&
                          allowedAction == TrainingPlanAction.regenerate
                      ? () => _regenerarPlan()
                      : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Regenerar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    disabledForegroundColor: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Adaptar (permitido si not locked)
              Tooltip(
                message: interviewStatus != TrainingInterviewStatus.valid
                    ? 'Completa entrevista para habilitar regeneración/adaptación'
                    : allowedAction == TrainingPlanAction.adapt
                    ? actionTooltip
                    : allowedAction == TrainingPlanAction.locked
                    ? '❌ Adaptación bloqueada: $actionTooltip'
                    : 'Usar regeneración en su lugar',
                child: ElevatedButton.icon(
                  onPressed:
                      interviewStatus == TrainingInterviewStatus.valid &&
                          allowedAction == TrainingPlanAction.adapt
                      ? () => _adaptarPlan()
                      : null,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Adaptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    disabledForegroundColor: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Eliminar Plan (siempre disponible si hay plan)
              Tooltip(
                message: 'Eliminar plan actual y regenerar desde cero',
                child: OutlinedButton.icon(
                  onPressed: () => _eliminarPlan(),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar Plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kErrorColor,
                    side: const BorderSide(color: kErrorColor),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                plan == null
                    ? 'Sin plan | $totalPlans total'
                    : 'Plan: ${plan.id.substring(0, 8)}... | $totalPlans total',
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isPlanOutdated)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kWarningSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kWarningColor.withValues(alpha: 0.8)),
            ),
            child: const Text(
              '⚠️ El plan fue generado con datos de entrevista anteriores.\nValida la entrevista y regenera el plan para aplicar los cambios.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

        // ✅ TabBar + TabBarView con 6 etapas del pipeline oficial
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TabBar con 6 etapas principales
              TabBar(
                controller: _v3TabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Entrevista'),
                  Tab(text: 'Landmarks'),
                  Tab(text: 'Intensidad'),
                  Tab(text: 'Preferencias de ejercicios'),
                  Tab(text: 'Plan'),
                  Tab(text: 'Monitoreo'),
                ],
                labelColor: kPrimaryColor,
                unselectedLabelColor: kTextColorSecondary,
                indicatorColor: kPrimaryColor,
              ),

              // TabBarView con 6 etapas del pipeline oficial
              Expanded(
                child: TabBarView(
                  controller: _v3TabController,
                  children: [
                    // Tab 0: Entrevista (ETAPA 1)
                    TrainingInterviewTab(key: _interviewTabKey),

                    // Tab 1: Landmarks (ETAPA 2)
                    canAccessLandmarks
                        ? _buildLandmarksTab(
                            client: client,
                            plan: plan,
                            flowStage: flowStage,
                            landmarksAreCurrent: landmarksAreCurrent,
                          )
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa la entrevista para habilitar Landmarks.',
                          ),

                    // Tab 2: Intensidad (ETAPA 3)
                    !canAccessIntensity
                        ? _buildLockedTab(
                            title: 'Bloqueado',
                            message: landmarksAreCurrent
                                ? 'Completa la etapa de Landmarks para avanzar a Intensidad.'
                                : 'Landmarks no vigentes. Guarda entrevista y confirma Landmarks.',
                          )
                        : IntensitySplitTable(
                            trainingExtra: client.training.extra,
                          ),

                    // Tab 3: Preferencias de ejercicios (ETAPA 4)
                    GymExercisesStageScreen(
                      isLocked: !canAccessIntensity,
                      onContinue: canAccessIntensity
                          ? () => _v3TabController.animateTo(4)
                          : null,
                    ),

                    // Tab 4: Plan (ETAPA 5)
                    plan != null
                        ? WeeklyPlanDetailView(plan: plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista, Landmarks, Intensidad y Preferencias de ejercicios para generar Plan.',
                          ),

                    // Tab 5: Monitoreo (ETAPA 6) - Absorbe Progresión
                    plan != null
                        ? _buildMonitoringTabPlaceholder(plan, client)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa el plan para acceder a Monitoreo.',
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Métodos auxiliares para etapas del pipeline - Solo contienen lógica para etapas vigentes

  Widget _buildProgressionTabPlaceholder(TrainingPlanConfig plan) {
    final weeks = plan.weeks;
    if (weeks.isEmpty) {
      return const Center(
        child: Text(
          'Sin semanas',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }
    final split = plan.state?['split']?.toString() ?? plan.splitId;
    final totalSesiones = weeks.fold<int>(0, (s, w) => s + w.sessions.length);
    final totalEjercicios = weeks.fold<int>(
      0,
      (s, w) =>
          s +
          w.sessions.fold<int>(0, (s2, sess) => s2 + sess.prescriptions.length),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timeline, color: kPrimaryColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Macrociclo Motor V3',
                      style: TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _wsStat('${weeks.length}', 'Semanas', kInfoColor),
                    const SizedBox(width: 8),
                    _wsStat('$totalSesiones', 'Sesiones', kSuccessColor),
                    const SizedBox(width: 8),
                    _wsStat('$totalEjercicios', 'Ejercicios', kWarningColor),
                    const SizedBox(width: 8),
                    _wsStat(split.toUpperCase(), 'Split', kPrimaryColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Timeline',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...weeks.map((week) {
            final Color phaseColor;
            final String phaseLabel;
            final IconData phaseIcon;
            switch (week.phase) {
              case TrainingPhase.accumulation:
                phaseColor = kInfoColor;
                phaseLabel = 'ACUMULACIÓN';
                phaseIcon = Icons.trending_up;
                break;
              case TrainingPhase.intensification:
                phaseColor = kWarningColor;
                phaseLabel = 'INTENSIFICACIÓN';
                phaseIcon = Icons.bolt;
                break;
              case TrainingPhase.deload:
                phaseColor = kSuccessColor;
                phaseLabel = 'DELOAD';
                phaseIcon = Icons.spa;
                break;
            }
            final totalSets = week.sessions.fold<int>(
              0,
              (s, sess) =>
                  s + sess.prescriptions.fold<int>(0, (s2, p) => s2 + p.sets),
            );
            final maxSets = weeks
                .map(
                  (w) => w.sessions.fold<int>(
                    0,
                    (s, sess) =>
                        s +
                        sess.prescriptions.fold<int>(0, (s2, p) => s2 + p.sets),
                  ),
                )
                .reduce((a, b) => a > b ? a : b);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: phaseColor.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: phaseColor.withAlpha(40),
                    ),
                    child: Center(
                      child: Text(
                        '${week.weekNumber}',
                        style: TextStyle(
                          color: phaseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(phaseIcon, color: phaseColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              phaseLabel,
                              style: TextStyle(
                                color: phaseColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${week.sessions.length} sesiones • $totalSets sets',
                          style: const TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalSets',
                        style: TextStyle(
                          color: phaseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white.withAlpha(15),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: maxSets > 0
                              ? (totalSets / maxSets).clamp(0.05, 1.0)
                              : 0.1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: phaseColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (plan.volumePerMuscle != null &&
              plan.volumePerMuscle!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Volumen por músculo',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ...() {
              final vol = plan.volumePerMuscle!;
              final maxV = vol.values.reduce((a, b) => a > b ? a : b);
              final sorted = vol.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return sorted.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          muscleLabelEs(e.key),
                          style: const TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value / maxV,
                            backgroundColor: Colors.white.withAlpha(15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kPrimaryColor.withAlpha(200),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${e.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  Widget _wsStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionsTabPlaceholder(TrainingPlanConfig plan, Client client) {
    final extra = client.training.extra;
    final rawArtifacts = extra['weeklyDecisionArtifactsV1'] as Map? ?? {};
    final generatedBy = plan.state?['generated_by']?.toString() ?? 'motor_v3';
    final version = plan.state?['scientific_version']?.toString() ?? '2.0.0';
    final model =
        plan.state?['periodization_model']?.toString() ?? 'linear_progressive';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.memory, color: kPrimaryColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Motor V3 — Trazabilidad',
                      style: TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _wsRow('Motor', generatedBy),
                _wsRow('Versión', version),
                _wsRow('Modelo', model),
                _wsRow('Fase', plan.phase.name.toUpperCase()),
                _wsRow('Split', plan.splitId),
                _wsRow('Semanas', '${plan.microcycleLengthInWeeks}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Decisiones por semana',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (rawArtifacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: kInfoColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las decisiones se generan al cerrar cada semana de entrenamiento.',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...rawArtifacts.entries.map((entry) {
              final weekData = entry.value as Map? ?? {};
              final weekNum = weekData['weekNumber'] as int? ?? 0;
              final phase = weekData['phase']?.toString() ?? 'accumulation';
              final actionByMuscle = weekData['actionByMuscle'] as Map? ?? {};
              final insightByMuscle = weekData['insightByMuscle'] as Map? ?? {};
              final newSets = weekData['newDirectSetsByMuscle'] as Map? ?? {};

              final phaseColor = phase == 'deload'
                  ? kSuccessColor
                  : phase == 'intensification'
                  ? kWarningColor
                  : kInfoColor;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: phaseColor.withAlpha(60)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: phaseColor.withAlpha(30),
                    ),
                    child: Center(
                      child: Text(
                        '$weekNum',
                        style: TextStyle(
                          color: phaseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    'Semana $weekNum',
                    style: const TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    phase.toUpperCase(),
                    style: TextStyle(color: phaseColor, fontSize: 11),
                  ),
                  children: actionByMuscle.entries.map((e) {
                    final muscle = e.key.toString();
                    final action = e.value.toString();
                    final insight = insightByMuscle[muscle]?.toString() ?? '';
                    final sets = newSets[muscle]?.toString() ?? '-';
                    final actionColor = action == 'increase'
                        ? kSuccessColor
                        : action == 'deload'
                        ? kInfoColor
                        : kWarningColor;
                    final actionIcon = action == 'increase'
                        ? Icons.arrow_upward
                        : action == 'deload'
                        ? Icons.spa
                        : Icons.remove;

                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: actionColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: actionColor.withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(actionIcon, size: 14, color: actionColor),
                              const SizedBox(width: 6),
                              Text(
                                muscleLabelEs(muscle),
                                style: const TextStyle(
                                  color: kTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$sets sets',
                                style: TextStyle(
                                  color: actionColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (insight.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              insight,
                              style: const TextStyle(
                                color: kTextColorSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _wsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTabPlaceholder(
    TrainingPlanConfig plan,
    Client client,
  ) {
    final extra = client.training.extra;
    final progressionMap =
        extra[TrainingExtraKeys.trainingProgressionStateV1] as Map? ?? {};
    final weeksCompleted =
        (progressionMap['weeksCompleted'] as num?)?.toInt() ?? 0;
    final sessionsCompleted =
        (progressionMap['sessionsCompleted'] as num?)?.toInt() ?? 0;
    final avgRir = (progressionMap['averageRIR'] as num?)?.toDouble() ?? 2.0;
    final avgRpe =
        (progressionMap['averageSessionRPE'] as num?)?.toDouble() ?? 7.0;
    final recovery =
        (progressionMap['perceivedRecovery'] as num?)?.toDouble() ?? 7.0;

    final totalWeeks = plan.weeks.length;
    final totalSessions = plan.weeks.fold<int>(
      0,
      (s, w) => s + w.sessions.length,
    );
    final progressPct = totalWeeks > 0
        ? (weeksCompleted / totalWeeks).clamp(0.0, 1.0)
        : 0.0;

    final accumWeeks = plan.weeks.where((w) => w.phase.isAccumulation).length;
    final intensWeeks = plan.weeks
        .where((w) => w.phase.isIntensification)
        .length;
    final deloadWeeks = plan.weeks.where((w) => w.phase.isDeload).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progreso del ciclo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progreso del ciclo',
                      style: TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$weeksCompleted/$totalWeeks sem',
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressPct,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      kPrimaryColor,
                    ),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progressPct * 100).toStringAsFixed(0)}% completado',
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Métricas
          Row(
            children: [
              _wsMetric(
                '$sessionsCompleted',
                'Sesiones\nregistradas',
                kSuccessColor,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 8),
              _wsMetric(
                '$totalSessions',
                'Sesiones\ndel plan',
                kInfoColor,
                Icons.calendar_today,
              ),
              const SizedBox(width: 8),
              _wsMetric(
                avgRir.toStringAsFixed(1),
                'RIR\npromedio',
                avgRir <= 1.5 ? kWarningColor : kSuccessColor,
                Icons.fitness_center,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _wsMetric(
                '${avgRpe.toStringAsFixed(1)}/10',
                'RPE\npromedio',
                avgRpe >= 8.5 ? kErrorColor : kWarningColor,
                Icons.speed,
              ),
              const SizedBox(width: 8),
              _wsMetric(
                '${recovery.toStringAsFixed(1)}/10',
                'Recuperación',
                recovery >= 7 ? kSuccessColor : kErrorColor,
                Icons.battery_charging_full,
              ),
              const SizedBox(width: 8),
              _wsMetric(
                '$totalWeeks',
                'Duración\n(semanas)',
                kTextColorSecondary,
                Icons.event,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Fases del plan',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _wsPhase(
            'Acumulación',
            accumWeeks,
            totalWeeks,
            kInfoColor,
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _wsPhase(
            'Intensificación',
            intensWeeks,
            totalWeeks,
            kWarningColor,
            Icons.bolt,
          ),
          const SizedBox(height: 8),
          _wsPhase('Deload', deloadWeeks, totalWeeks, kSuccessColor, Icons.spa),
          const SizedBox(height: 20),
          // Nota científica
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kInfoColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kInfoColor.withAlpha(60)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science, color: kInfoColor, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RIR < 1.5 sostenido indica fatiga acumulada. '
                    'RPE > 8.5 por 2+ semanas sin deload aumenta riesgo de lesión '
                    '(Zourdos et al. 2016; Androulakis-Korakakis et al. 2024).',
                    style: TextStyle(color: kTextColorSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wsMetric(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wsPhase(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0.0,
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimaryColor.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimaryColor.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarksTab({
    required Client client,
    required TrainingPlanConfig? plan,
    required TrainingFlowStage flowStage,
    required bool landmarksAreCurrent,
  }) {
    final extra = client.training.extra;
    final detectedLevel =
        extra[TrainingExtraKeys.trainingLevelDerived]?.toString() ??
        extra[TrainingExtraKeys.effectiveTrainingLevel]?.toString() ??
        'n/d';
    final vme = extra[TrainingExtraKeys.vmeCalculated];
    final vmr = extra[TrainingExtraKeys.vmrCalculated];
    final vop = extra[TrainingExtraKeys.vopCalculated];

    final landmarksByMuscle = LandmarkEngine.parseByCanonicalKey(
      client.training.extra[TrainingExtraKeys.muscleLandmarks],
    );
    final rows = landmarksByMuscle.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Landmarks musculares (VME / VOP / VMR)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Paso 2 del flujo. Estos valores se calculan al guardar entrevista.',
            style: TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _metricChip('Nivel detectado', detectedLevel),
                      _metricChip('VME', vme?.toString() ?? 'n/d'),
                      _metricChip('VMR', vmr?.toString() ?? 'n/d'),
                      _metricChip('VOP', vop?.toString() ?? 'n/d'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    landmarksAreCurrent
                        ? 'Estado: válido para continuar a Intensidad.'
                        : 'Estado: inválido para continuar. Guarda entrevista para recalcular.',
                    style: TextStyle(
                      fontSize: 12,
                      color: landmarksAreCurrent
                          ? kSuccessColor
                          : kWarningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            _buildLockedTab(
              title: 'Sin landmarks',
              message:
                  'Guarda entrevista para calcular VME/VOP/VMR por músculo.',
              icon: Icons.analytics_outlined,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Músculo',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'VME',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'VOP',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'VMR',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    for (final entry in rows)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(muscleLabelEs(entry.key)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '${entry.value.vme}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '${entry.value.vop}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '${entry.value.vmr}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          if (rows.isNotEmpty && flowStage == TrainingFlowStage.landmarks) ...[
            if (!landmarksAreCurrent)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWarningSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kWarningColor.withAlpha(140)),
                ),
                child: const Text(
                  'Los landmarks no corresponden a la última entrevista. Guarda entrevista nuevamente antes de continuar.',
                  style: TextStyle(fontSize: 12, color: kTextColorSecondary),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: !landmarksAreCurrent
                    ? null
                    : () async {
                        await ref
                            .read(clientsProvider.notifier)
                            .updateActiveClient((prev) {
                              final extra = Map<String, dynamic>.from(
                                prev.training.extra,
                              );
                              final guardStage =
                                  TrainingPipelineGuard.allowedStage(extra);
                              extra[TrainingExtraKeys.trainingFlowStage] =
                                  guardStage.order >=
                                      TrainingFlowStage.intensity.order
                                  ? TrainingFlowStage.intensity.name
                                  : TrainingFlowStage.landmarks.name;
                              return prev.copyWith(
                                training: prev.training.copyWith(extra: extra),
                              );
                            });
                        if (!mounted) return;
                        _v3TabController.animateTo(2);
                      },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Confirmar Landmarks y pasar a Intensidad'),
              ),
            ),
          ],
          if (plan != null) ...[
            const SizedBox(height: 16),
            VolumeCapacityScientificView(plan: plan),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedTab({
    required String title,
    required String message,
    IconData icon = Icons.lock,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _v3TabController.animateTo(0),
            child: const Text('Ir a Entrevista'),
          ),
        ],
      ),
    );
  }


  Widget _buildFieldRow(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Row(
      children:
          children
              .map(
                (child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: child,
                  ),
                ),
              )
              .toList()
            ..removeLast(),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: hcsDecoration(context, labelText: label, hintText: hint),
    );
  }


  Widget _buildSaveButton({
    required String label,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  // Métodos _setSection y _sectionTitle eliminados (ya no se necesitan con TabBar)

  void _runMigrationIfNeeded(Client client) {
    final needsMigration = TrainingEvaluationMigrationService.needsMigration(
      client.training.extra,
    );

    if (!needsMigration) {
      _migrationQueued = false;
      _lastClientId = client.id;
      return;
    }

    if (_lastClientId == client.id && _migrationQueued) return;
    _lastClientId = client.id;
    _migrationQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(clientsProvider.notifier).updateActiveClient((current) {
        if (current.id != client.id) return current;
        return TrainingEvaluationMigrationService.migrateLegacyToV1(current);
      });
      _migrationQueued = false;
    });
  }

  void _seedControllersIfNeeded(
    TrainingSetupV1 setup,
    TrainingEvaluationSnapshotV1 evaluation,
    TrainingProgressionStateV1 progression,
  ) {
    final signature = [
      setup.heightCm,
      setup.weightKg,
      setup.ageYears,
      setup.sex,
      evaluation.daysPerWeek,
      evaluation.sessionDurationMinutes,
      evaluation.planDurationInWeeks,
      evaluation.primaryMuscles.join(','),
      evaluation.secondaryMuscles.join(','),
      evaluation.tertiaryMuscles.join(','),
      evaluation.intensityDistribution['heavy'] ?? 0,
      evaluation.intensityDistribution['medium'] ?? 0,
      evaluation.intensityDistribution['light'] ?? 0,
      progression.weeksCompleted,
      progression.sessionsCompleted,
      progression.consecutiveWeeksTraining,
      progression.averageRIR,
      progression.averageSessionRPE,
      progression.perceivedRecovery,
      progression.lastPlanChangeReason,
    ].join('|');

    if (_lastSeedSignature == signature) return;
    _lastSeedSignature = signature;

    _heightController.text = _formatDouble(setup.heightCm);
    _weightController.text = _formatDouble(setup.weightKg);
    _ageController.text = setup.ageYears.toString();
    _sexController.text = setup.sex;

    _daysController.text = evaluation.daysPerWeek.toString();
    _sessionController.text = evaluation.sessionDurationMinutes.toString();
    _durationWeeksController.text = evaluation.planDurationInWeeks.toString();
    _primaryMusclesController.text = evaluation.primaryMuscles.join(', ');
    _secondaryMusclesController.text = evaluation.secondaryMuscles.join(', ');
    _tertiaryMusclesController.text = evaluation.tertiaryMuscles.join(', ');
    _heavyController.text = _formatDouble(
      evaluation.intensityDistribution['heavy'] ?? 0,
    );
    _mediumController.text = _formatDouble(
      evaluation.intensityDistribution['medium'] ?? 0,
    );
    _lightController.text = _formatDouble(
      evaluation.intensityDistribution['light'] ?? 0,
    );

    _weeksCompletedController.text = progression.weeksCompleted.toString();
    _sessionsCompletedController.text = progression.sessionsCompleted
        .toString();
    _consecutiveWeeksController.text = progression.consecutiveWeeksTraining
        .toString();
    _avgRirController.text = _formatDouble(progression.averageRIR);
    _avgRpeController.text = _formatDouble(progression.averageSessionRPE);
    _perceivedRecoveryController.text = _formatDouble(
      progression.perceivedRecovery,
    );
    _lastPlanReasonController.text = progression.lastPlanChangeReason;
  }

  TrainingSetupV1 _readSetup(Client client) {
    final raw = client.training.extra[TrainingExtraKeys.trainingSetupV1];
    if (raw is Map<String, dynamic>) {
      return TrainingSetupV1.fromJson(raw);
    }
    if (raw is Map) {
      return TrainingSetupV1.fromJson(raw.cast<String, dynamic>());
    }

    return TrainingSetupV1(
      heightCm:
          (client.training.extra[TrainingExtraKeys.heightCm] as num?)
              ?.toDouble() ??
          0.0,
      weightKg:
          (client.training.extra[TrainingExtraKeys.weightKg] as num?)
              ?.toDouble() ??
          0.0,
      ageYears: client.training.age ?? client.profile.age ?? 0,
      sex: client.training.gender?.name ?? client.profile.gender?.name ?? '',
    );
  }

  Map<String, double> _derivePrioritySplitFromMuscles(
    List<String> primary,
    List<String> secondary,
    List<String> tertiary,
  ) {
    final total = primary.length + secondary.length + tertiary.length;
    if (total == 0) return const {};

    return {
      'primary': primary.length / total,
      'secondary': secondary.length / total,
      'tertiary': tertiary.length / total,
    };
  }

  String _deriveStatus({
    required int daysPerWeek,
    required int sessionDurationMinutes,
    required int planDurationInWeeks,
    required List<String> primary,
    required List<String> secondary,
    required List<String> tertiary,
    required Map<String, double> priorityVolumeSplit,
    required Map<String, double> intensityDistribution,
  }) {
    final hasBasics =
        daysPerWeek > 0 &&
        sessionDurationMinutes > 0 &&
        planDurationInWeeks > 0;
    final hasMuscles =
        primary.isNotEmpty || secondary.isNotEmpty || tertiary.isNotEmpty;

    if (!hasBasics && !hasMuscles) return 'minimal';

    final hasSplit = priorityVolumeSplit.isNotEmpty;
    final hasIntensity = intensityDistribution.isNotEmpty;

    if (hasBasics && hasMuscles && hasSplit && hasIntensity) {
      return 'complete';
    }

    return 'partial';
  }

  TrainingEvaluationSnapshotV1 _readEvaluation(Client client) {
    final raw =
        client.training.extra[TrainingExtraKeys.trainingEvaluationSnapshotV1];
    if (raw is Map<String, dynamic>) {
      final snapshot = TrainingEvaluationSnapshotV1.fromJson(raw);
      // ✅ Normalizar músculos al cargar (por si hay datos legacy)
      return TrainingEvaluationSnapshotV1(
        schemaVersion: snapshot.schemaVersion,
        createdAt: snapshot.createdAt,
        updatedAt: snapshot.updatedAt,
        daysPerWeek: snapshot.daysPerWeek,
        sessionDurationMinutes: snapshot.sessionDurationMinutes,
        planDurationInWeeks: snapshot.planDurationInWeeks,
        primaryMuscles: _normalizeMuscleKeys(snapshot.primaryMuscles),
        secondaryMuscles: _normalizeMuscleKeys(snapshot.secondaryMuscles),
        tertiaryMuscles: _normalizeMuscleKeys(snapshot.tertiaryMuscles),
        priorityVolumeSplit: snapshot.priorityVolumeSplit,
        intensityDistribution: snapshot.intensityDistribution,
        painRules: snapshot.painRules,
        status: snapshot.status,
      );
    }
    if (raw is Map) {
      final snapshot = TrainingEvaluationSnapshotV1.fromJson(
        raw.cast<String, dynamic>(),
      );
      return TrainingEvaluationSnapshotV1(
        schemaVersion: snapshot.schemaVersion,
        createdAt: snapshot.createdAt,
        updatedAt: snapshot.updatedAt,
        daysPerWeek: snapshot.daysPerWeek,
        sessionDurationMinutes: snapshot.sessionDurationMinutes,
        planDurationInWeeks: snapshot.planDurationInWeeks,
        primaryMuscles: _normalizeMuscleKeys(snapshot.primaryMuscles),
        secondaryMuscles: _normalizeMuscleKeys(snapshot.secondaryMuscles),
        tertiaryMuscles: _normalizeMuscleKeys(snapshot.tertiaryMuscles),
        priorityVolumeSplit: snapshot.priorityVolumeSplit,
        intensityDistribution: snapshot.intensityDistribution,
        painRules: snapshot.painRules,
        status: snapshot.status,
      );
    }

    final now = DateTime.now();
    // ✅ Normalizar al construir desde legacy keys
    final primary = _normalizeMuscleKeys(
      _parseMuscleList(
        client.training.extra[TrainingExtraKeys.priorityMusclesPrimary],
      ),
    );
    final secondary = _normalizeMuscleKeys(
      _parseMuscleList(
        client.training.extra[TrainingExtraKeys.priorityMusclesSecondary],
      ),
    );
    final tertiary = _normalizeMuscleKeys(
      _parseMuscleList(
        client.training.extra[TrainingExtraKeys.priorityMusclesTertiary],
      ),
    );

    return TrainingEvaluationSnapshotV1(
      schemaVersion: 1,
      createdAt: now,
      updatedAt: now,
      daysPerWeek:
          (client.training.extra[TrainingExtraKeys.daysPerWeek] as num?)
              ?.toInt() ??
          0,
      sessionDurationMinutes:
          (client.training.extra[TrainingExtraKeys.timePerSessionMinutes]
                  as num?)
              ?.toInt() ??
          0,
      planDurationInWeeks:
          (client.training.extra[TrainingExtraKeys.planDurationInWeeks] as num?)
              ?.toInt() ??
          0,
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      tertiaryMuscles: tertiary,
      priorityVolumeSplit: const {},
      intensityDistribution: const {},
      painRules: const [],
      status: 'minimal',
    );
  }

  TrainingProgressionStateV1 _readProgression(Client client) {
    final raw =
        client.training.extra[TrainingExtraKeys.trainingProgressionStateV1];
    if (raw is Map<String, dynamic>) {
      return TrainingProgressionStateV1.fromJson(raw);
    }
    if (raw is Map) {
      return TrainingProgressionStateV1.fromJson(raw.cast<String, dynamic>());
    }

    return const TrainingProgressionStateV1(
      weeksCompleted: 0,
      sessionsCompleted: 0,
      consecutiveWeeksTraining: 0,
      averageRIR: 0,
      averageSessionRPE: 0,
      perceivedRecovery: 0,
      lastPlanId: '',
      lastPlanChangeReason: '',
    );
  }


  Future<void> _saveSetup(Client client) async {
    final setup = TrainingSetupV1(
      heightCm: _parseDouble(_heightController.text),
      weightKg: _parseDouble(_weightController.text),
      ageYears: _parseInt(_ageController.text),
      sex: _sexController.text.trim(),
    );

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.training.extra);
      extra[TrainingExtraKeys.trainingSetupV1] = setup.toJson();
      return current.copyWith(
        training: current.training.copyWith(extra: extra),
      );
    });
  }

  Future<void> _saveEvaluation(
    Client client,
    TrainingEvaluationSnapshotV1 current,
  ) async {
    final now = DateTime.now();
    // ✅ NORMALIZAR A KEYS CANÓNICAS (evitar labels duplicados)
    final primary = _normalizeMuscleKeys(
      _parseMuscleList(_primaryMusclesController.text),
    );
    final secondary = _normalizeMuscleKeys(
      _parseMuscleList(_secondaryMusclesController.text),
    );
    final tertiary = _normalizeMuscleKeys(
      _parseMuscleList(_tertiaryMusclesController.text),
    );
    final intensity = {
      'heavy': _parseDouble(_heavyController.text),
      'medium': _parseDouble(_mediumController.text),
      'light': _parseDouble(_lightController.text),
    };
    final prioritySplit = current.priorityVolumeSplit.isNotEmpty
        ? current.priorityVolumeSplit
        : _derivePrioritySplitFromMuscles(primary, secondary, tertiary);

    final daysPerWeek = _parseInt(_daysController.text);
    debugPrint(
      '[TrainingWorkspace] Guardando evaluación: daysPerWeek=$daysPerWeek',
    );

    final evaluation = TrainingEvaluationSnapshotV1(
      schemaVersion: current.schemaVersion,
      createdAt: current.createdAt,
      updatedAt: now,
      daysPerWeek: daysPerWeek,
      sessionDurationMinutes: _parseInt(_sessionController.text),
      planDurationInWeeks: _parseInt(_durationWeeksController.text),
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      tertiaryMuscles: tertiary,
      priorityVolumeSplit: prioritySplit,
      intensityDistribution: intensity,
      painRules: current.painRules,
      status: _deriveStatus(
        daysPerWeek: daysPerWeek,
        sessionDurationMinutes: _parseInt(_sessionController.text),
        planDurationInWeeks: _parseInt(_durationWeeksController.text),
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        priorityVolumeSplit: prioritySplit,
        intensityDistribution: intensity,
      ),
    );

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.training.extra);
      // ✅ Guardar en AMBOS keys para compatibilidad con legacy code
      extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] = evaluation
          .toJson();
      extra[TrainingExtraKeys.daysPerWeek] = daysPerWeek;
      extra[TrainingExtraKeys.priorityMusclesPrimary] = primary.join(',');
      extra[TrainingExtraKeys.priorityMusclesSecondary] = secondary.join(',');
      extra[TrainingExtraKeys.priorityMusclesTertiary] = tertiary.join(',');
      return current.copyWith(
        training: current.training.copyWith(extra: extra),
      );
    });
  }

  Future<void> _saveProgression(
    Client client,
    TrainingProgressionStateV1 current,
  ) async {
    final progression = TrainingProgressionStateV1(
      weeksCompleted: _parseInt(_weeksCompletedController.text),
      sessionsCompleted: _parseInt(_sessionsCompletedController.text),
      consecutiveWeeksTraining: _parseInt(_consecutiveWeeksController.text),
      averageRIR: _parseDouble(_avgRirController.text),
      averageSessionRPE: _parseDouble(_avgRpeController.text),
      perceivedRecovery: _parseDouble(_perceivedRecoveryController.text),
      lastPlanId: current.lastPlanId,
      lastPlanChangeReason: _lastPlanReasonController.text.trim(),
    );

    await ref
        .read(trainingPlanProvider.notifier)
        .saveProgressionState(clientId: client.id, progression: progression);
  }

  Future<void> _openPainRuleDialog(
    Client client,
    TrainingEvaluationSnapshotV1 evaluation,
  ) async {
    InjuryRegion selectedRegion = InjuryRegion.shoulder;
    MovementPattern selectedPattern = MovementPattern.overheadPressing;
    int severity = 1;
    bool avoid = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: const Text('Nueva regla de dolor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InjuryRegion>(
                initialValue: selectedRegion,
                decoration: hcsDecoration(context, labelText: 'Region'),
                items: InjuryRegion.values
                    .map(
                      (region) => DropdownMenuItem(
                        value: region,
                        child: Text(region.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  selectedRegion = value;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MovementPattern>(
                initialValue: selectedPattern,
                decoration: hcsDecoration(context, labelText: 'Patron'),
                items: MovementPattern.values
                    .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern,
                        child: Text(pattern.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  selectedPattern = value;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: severity,
                decoration: hcsDecoration(context, labelText: 'Severidad'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0')),
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  severity = value;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: avoid,
                onChanged: (value) => avoid = value,
                title: const Text('Evitar movimientos'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final updatedRules = [
      ...evaluation.painRules,
      PainRule(
        region: selectedRegion,
        pattern: selectedPattern,
        severity: severity,
        avoid: avoid,
      ),
    ];

    final updated = TrainingEvaluationSnapshotV1(
      schemaVersion: evaluation.schemaVersion,
      createdAt: evaluation.createdAt,
      updatedAt: DateTime.now(),
      daysPerWeek: evaluation.daysPerWeek,
      sessionDurationMinutes: evaluation.sessionDurationMinutes,
      planDurationInWeeks: evaluation.planDurationInWeeks,
      primaryMuscles: evaluation.primaryMuscles,
      secondaryMuscles: evaluation.secondaryMuscles,
      tertiaryMuscles: evaluation.tertiaryMuscles,
      priorityVolumeSplit: evaluation.priorityVolumeSplit,
      intensityDistribution: evaluation.intensityDistribution,
      painRules: updatedRules,
      status: evaluation.status,
    );

    try {
      await ref.read(clientsProvider.notifier).updateActiveClient((current) {
        final extra = Map<String, dynamic>.from(current.training.extra);
        extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] = updated
            .toJson();
        return current.copyWith(
          training: current.training.copyWith(extra: extra),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regla de dolor guardada'),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar regla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePlanAction(
    BuildContext context, {
    required PlanAction action,
    required TrainingEvaluationSnapshotV1 evaluation,
    required TrainingProgressionStateV1 progression,
  }) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final errors = ref
        .read(trainingPlanProvider.notifier)
        .validatePlanActionInputs(client: client, evaluation: evaluation);
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.join(' | '))));
      return;
    }

    final previousEvaluation = evaluation;
    final decision = TrainingPlanDecisionService.decide(
      progression: progression,
      evaluation: evaluation,
      previousEvaluation: previousEvaluation,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text('Confirmar ${action.name}'),
          content: Text(
            'Decision sugerida: ${decision.name}.\n'
            'Deseas continuar con ${action.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (action == PlanAction.regenerate) {
      await ref.read(trainingPlanProvider.notifier).clearActivePlan();
    }

    await ref
        .read(trainingPlanProvider.notifier)
        .generatePlanFromActiveCycle(DateTime.now());
    await ref.read(clientsProvider.notifier).refresh();

    final refreshedClient = ref.read(clientsProvider).value?.activeClient;
    final lastPlanId =
        refreshedClient?.training.extra[TrainingExtraKeys.activePlanId]
            ?.toString() ??
        '';

    final resetProgression = action == PlanAction.regenerate;
    if (refreshedClient != null && lastPlanId.isNotEmpty) {
      await ref
          .read(trainingPlanProvider.notifier)
          .recordPlanAction(
            clientId: refreshedClient.id,
            action: action.name,
            resetProgressionCounters: resetProgression,
            appendAdaptationHistory: action == PlanAction.adapt,
          );
    }
  }

  /// ✅ NORMALIZACIÓN A KEYS CANÓNICAS
  /// Convierte labels legacy a keys estándar de Motor V3
  List<String> _normalizeMuscleKeys(List<String> keys) {
    final canonical = <String>{};

    for (final raw in keys) {
      final normalized = muscle_registry.normalize(raw);
      if (normalized != null) {
        canonical.add(normalized);
        continue;
      }

      final expanded = muscle_registry.expandGroup(raw);
      canonical.addAll(expanded);
    }

    final sorted = canonical.toList()..sort();
    return sorted;
  }

  List<String> _parseMuscleList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final text = raw?.toString() ?? '';
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  double _parseDouble(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    final value = double.tryParse(normalized);
    if (value == null) {
      if (normalized.isNotEmpty) {
        debugPrint('[TrainingWorkspace] Invalid double input: "$raw"');
      }
      return 0.0;
    }
    return value;
  }

  int _parseInt(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    final value = int.tryParse(normalized);
    if (value == null) {
      if (normalized.isNotEmpty) {
        debugPrint('[TrainingWorkspace] Invalid int input: "$raw"');
      }
      return 0;
    }
    return value;
  }

  String _formatDouble(num value) {
    return value == 0 ? '' : value.toString();
  }

  Future<bool> _commitInterview() async {
    try {
      await _interviewTabKey.currentState?.commit();
      return true;
    } catch (e) {
      debugPrint('[TrainingWorkspace] commit interview failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la entrevista.'),
            backgroundColor: kErrorColor,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _cerrarSemana({
    required Client client,
    required int weekNumber,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text('Cerrar semana'),
        content: Text(
          '¿Deseas cerrar la semana $weekNumber y avanzar a la siguiente?',
          style: const TextStyle(color: kTextColorSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
            child: const Text('Cerrar semana'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(trainingPlanProvider.notifier)
          .closeWeekExplicit(client.id, weekNumber);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Semana $weekNumber cerrada correctamente'),
            backgroundColor: kSuccessColor,
          ),
        );
      }

      await _updateProgressionAfterPlanAction('week_closed');
      ref.invalidate(clientsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cerrando semana: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  // E2 GOBERNANZA: MÉTODOS PARA PLAN V3 (CON VERIFICACIÓN)
  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  Future<void> _generarPlan() async {
    final workspaceState = ref.read(trainingWorkspaceProvider);
    if (!workspaceState.canGeneratePlan) {
      return;
    }

    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final planNotifier = ref.read(trainingPlanProvider.notifier);
    final allowedAction = planNotifier.resolveAllowedAction(client);
    if (allowedAction == TrainingPlanAction.locked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Plan bloqueado: ${planNotifier.resolvePlanActionTooltip(client, allowedAction)}',
            ),
            backgroundColor: kErrorColor,
          ),
        );
      }
      return;
    }

    try {
      final generated = await ref
          .read(trainingPlanProvider.notifier)
          .generatePlanFromActiveCycle(DateTime.now());

      if (generated == null) {
        final error = ref.read(trainingPlanProvider).error;
        throw Exception(error ?? 'No se pudo generar el plan');
      }

      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        final extra = Map<String, dynamic>.from(prev.training.extra);
        extra[TrainingExtraKeys.trainingFlowStage] =
            TrainingFlowStage.plan.name;
        return prev.copyWith(training: prev.training.copyWith(extra: extra));
      });

      // E2: Actualizar estado de progresión después de generar
      await _updateProgressionAfterPlanAction('generate');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan Motor V3 generado correctamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar plan: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _regenerarPlan() async {
    final committed = await _commitInterview();
    if (!committed) return;
    if (!mounted) return;
    // E2: Verificar que la acción esté permitida
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final planNotifier = ref.read(trainingPlanProvider.notifier);
    final allowedAction = planNotifier.resolveAllowedAction(client);
    if (allowedAction != TrainingPlanAction.regenerate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Regeneración no permitida: ${planNotifier.resolvePlanActionTooltip(client, allowedAction)}',
            ),
            backgroundColor: kErrorColor,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerar Plan'),
        content: const Text(
          '¿Regenerar plan completo Motor V3?\n\nEsto creará un nuevo plan desde cero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generarPlan();
              // E2: Actualizar estado de progresión
              await _updateProgressionAfterPlanAction('regenerate');
            },
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plan Actual'),
        content: const Text(
          '¿Eliminar el plan de entrenamiento actual?\n\n'
          'Esto borrará todos los planes y ciclos del cliente. '
          'Podrás generar uno nuevo desde cero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await ref.read(trainingPlanProvider.notifier).clearActivePlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan eliminado. Puedes generar uno nuevo.'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar plan: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _adaptarPlan() async {
    final committed = await _commitInterview();
    if (!committed) return;
    // E2: Verificar que la acción esté permitida
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final planNotifier = ref.read(trainingPlanProvider.notifier);
    final allowedAction = planNotifier.resolveAllowedAction(client);
    if (allowedAction != TrainingPlanAction.adapt) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Adaptación no permitida: ${planNotifier.resolvePlanActionTooltip(client, allowedAction)}',
            ),
            backgroundColor: kErrorColor,
          ),
        );
      }
      return;
    }

    try {
      final now = DateTime.now();
      await ref
          .read(trainingPlanProvider.notifier)
          .generatePlanFromActiveCycle(now);

      // E2: Actualizar estado de progresión después de adaptar
      await _updateProgressionAfterPlanAction('adapt');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan adaptado correctamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al adaptar plan: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  // E2: Actualizar estado de progresión después de acción de plan
  Future<void> _updateProgressionAfterPlanAction(String action) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    try {
      await ref
          .read(trainingPlanProvider.notifier)
          .recordPlanAction(
            clientId: client.id,
            action: action,
            appendAdaptationHistory: true,
          );
    } catch (e) {
      debugPrint('⚠️ Error al actualizar progresión: $e');
    }
  }

  String? _resolveDeloadAlertMessage(Client client) {
    final snapshotRaw = client.training.extra['lastPhaseResolutionV1'];
    if (snapshotRaw is! Map) {
      return null;
    }

    final snapshot = Map<String, dynamic>.from(snapshotRaw);
    final snapshotAt = snapshot['timestamp']?.toString();
    if (snapshotAt != null && snapshotAt == _dismissedDeloadSnapshotAt) {
      return null;
    }

    if (snapshot['needsDeload'] != true) {
      return null;
    }

    final urgency = snapshot['urgency']?.toString().trim();
    final reasons =
        (snapshot['reasons'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final reasonsText = reasons.isNotEmpty
        ? reasons.join(' | ')
        : 'Fatiga acumulada detectada por el motor.';

    if (urgency != null && urgency.isNotEmpty) {
      return 'Urgencia $urgency: $reasonsText';
    }

    return reasonsText;
  }

  void _dismissDeloadAlert(Client client) {
    final snapshotRaw = client.training.extra['lastPhaseResolutionV1'];
    if (snapshotRaw is! Map) return;
    setState(() {
      _dismissedDeloadSnapshotAt = snapshotRaw['timestamp']?.toString();
    });
  }
}
