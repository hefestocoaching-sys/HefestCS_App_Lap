import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training/split_templates.dart';
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
import 'package:hcs_app_lap/features/training_feature/tabs/training_interview_tab.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/volume_capacity_scientific_view.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/series_distribution_editor.dart';
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
    _v3TabController = TabController(length: 9, vsync: this);
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

  // M├®todos auxiliares de navegaci├│n por tabs eliminados (jerarqu├¡a aplanada)
  // El workspace ahora muestra directamente el Motor V3 con sus 9 tabs

  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  // E2 GOBERNANZA: Verificar acci├│n permitida
  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  TrainingPlanAction _checkPlanActionAllowed(Client client) {
    // Leer SSOT desde extra
    final setupMap =
        client.training.extra[TrainingExtraKeys.trainingSetupV1]
            as Map<String, dynamic>?;
    final snapshotMap =
        client.training.extra[TrainingExtraKeys.trainingEvaluationSnapshotV1]
            as Map<String, dynamic>?;
    final progressionMap =
        client.training.extra[TrainingExtraKeys.trainingProgressionStateV1]
            as Map<String, dynamic>?;

    // Si no hay SSOT, permitir generar
    if (setupMap == null || snapshotMap == null || progressionMap == null) {
      return TrainingPlanAction.generate;
    }

    try {
      final setup = TrainingSetupV1.fromJson(setupMap);
      final snapshot = TrainingEvaluationSnapshotV1.fromJson(snapshotMap);
      final progression = TrainingProgressionStateV1.fromJson(progressionMap);

      return TrainingPlanGovernor.decide(
        setup: setup,
        snapshot: snapshot,
        progression: progression,
      );
    } catch (e) {
      debugPrint('ÔÜá´©Å Error al verificar acci├│n permitida: $e');
      return TrainingPlanAction.adapt; // Fallback seguro
    }
  }

  String _getPlanActionTooltip(TrainingPlanAction action, Client client) {
    // Leer SSOT para obtener rationale
    final snapshotMap =
        client.training.extra[TrainingExtraKeys.trainingEvaluationSnapshotV1]
            as Map<String, dynamic>?;
    final progressionMap =
        client.training.extra[TrainingExtraKeys.trainingProgressionStateV1]
            as Map<String, dynamic>?;

    if (snapshotMap == null || progressionMap == null) {
      return 'Plan inicial sin historial';
    }

    try {
      final snapshot = TrainingEvaluationSnapshotV1.fromJson(snapshotMap);
      final progression = TrainingProgressionStateV1.fromJson(progressionMap);

      return TrainingPlanGovernor.getDecisionRationale(
        action,
        snapshot: snapshot,
        progression: progression,
      );
    } catch (e) {
      return 'Verificar estado del plan';
    }
  }

  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  Widget _buildCurrentPlanSection(
    BuildContext context,
    Client client,
    TrainingProgressionStateV1 progression,
    TrainingInterviewStatus interviewStatus,
    bool canGeneratePlan,
    bool isPlanOutdated,
  ) {
    final activePlanId =
      client.training.extra[TrainingExtraKeys.activePlanId]?.toString();
    final totalPlans = client.trainingPlans.length;
    final hasAnyPlan = client.trainingPlans.isNotEmpty;
    final hasActiveId = activePlanId != null && activePlanId.isNotEmpty;

    // E2 GOBERNANZA: Verificar acci├│n permitida
    final allowedAction = _checkPlanActionAllowed(client);
    final actionTooltip = _getPlanActionTooltip(allowedAction, client);

    // Obtener plan activo o m├ís reciente
    TrainingPlanConfig? plan;
    if (hasAnyPlan && hasActiveId) {
      try {
        plan = client.trainingPlans.firstWhere((p) => p.id == activePlanId);
      } on StateError {
        plan = null;
      }
    }

    if (hasAnyPlan && plan == null) {
      plan =
          (client.trainingPlans.toList()
                ..sort((a, b) => b.startDate.compareTo(a.startDate)))
              .first;
    }

    if (interviewStatus != TrainingInterviewStatus.valid && plan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_v3TabController.index != 0) {
          _v3TabController.animateTo(0);
        }
      });
    }

    final interviewBlockedTooltip =
        'Completa entrevista para habilitar generaci├│n/adaptaci├│n';

    // Mostrar TabBar + TabBarView con los 9 tabs Motor V3
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              'Plan existente visible. Entrevista en edici├│n: valida para regenerar/adaptar.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        // Header con acciones (Generar/Regenerar/Adaptar)
        Row(
          children: [
            if (!hasAnyPlan)
              Tooltip(
                message:
                    interviewStatus == TrainingInterviewStatus.valid
                        ? actionTooltip
                        : interviewBlockedTooltip,
                child: ElevatedButton.icon(
                  onPressed:
                      canGeneratePlan &&
                              (allowedAction == TrainingPlanAction.generate ||
                                  allowedAction ==
                                      TrainingPlanAction.regenerate)
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
              // Bot├│n Regenerar (solo si permitido)
              Tooltip(
              message:
                interviewStatus != TrainingInterviewStatus.valid
                  ? interviewBlockedTooltip
                  : allowedAction == TrainingPlanAction.regenerate
                    ? actionTooltip
                    : 'ÔØî Regeneraci├│n bloqueada: $actionTooltip',
                child: ElevatedButton.icon(
                onPressed:
                  interviewStatus == TrainingInterviewStatus.valid &&
                      allowedAction ==
                        TrainingPlanAction.regenerate
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
              // Bot├│n Adaptar (permitido si not locked)
              Tooltip(
                message:
                  interviewStatus != TrainingInterviewStatus.valid
                    ? interviewBlockedTooltip
                    : allowedAction == TrainingPlanAction.adapt
                      ? actionTooltip
                      : allowedAction == TrainingPlanAction.locked
                        ? 'ÔØî Adaptaci├│n bloqueada: $actionTooltip'
                        : 'Usar regeneraci├│n en su lugar',
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
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                plan == null
                    ? 'Sin plan | $totalPlans total'
                    : 'Plan: ${plan.id.substring(0, 8)}... | $totalPlans total',
                style: TextStyle(color: kTextColorSecondary, fontSize: 12),
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
              'ÔÜá´©Å El plan fue generado con datos de entrevista anteriores.\nValida la entrevista y regenera el plan para aplicar los cambios.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

        // Ô£à TabBar + TabBarView sin Expanded (parent lo maneja via Expanded en _buildMainPanel)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TabBar
              TabBar(
                controller: _v3TabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Entrevista'),
                  Tab(text: 'Overview'),
                  Tab(text: 'Volumen'),
                  Tab(text: 'Sesiones'),
                  Tab(text: 'Ejercicios'),
                  Tab(text: 'Progresi├│n'),
                  Tab(text: 'Intensidad'),
                  Tab(text: 'Decisiones'),
                  Tab(text: 'Monitoreo'),
                ],
                labelColor: kPrimaryColor,
                unselectedLabelColor: kTextColorSecondary,
                indicatorColor: kPrimaryColor,
                indicatorWeight: 2,
              ),

              // TabBarView (ocupa resto espacio en Expanded)
              Expanded(
                child: TabBarView(
                  controller: _v3TabController,
                  children: [
                    // Tab 0: Entrevista
                    TrainingInterviewTab(key: _interviewTabKey),
                    // Tab 1: Overview (placeholder simplificado)
                    plan != null
                        ? _buildOverviewTabPlaceholder(plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 2: Volumen
                    plan != null
                        ? VolumeCapacityScientificView(plan: plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 3: Sesiones
                    plan != null
                        ? WeeklyPlanDetailView(plan: plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 4: Ejercicios (placeholder)
                    plan != null
                        ? _buildExercisesTabPlaceholder(plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 5: Progresi├│n (placeholder)
                    plan != null
                        ? _buildProgressionTabPlaceholder(plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 6: Intensidad
                    plan != null
                        ? SeriesDistributionEditor(
                          trainingExtra: client.training.extra,
                          onDistributionChanged: (distribution) {
                            // Handle distribution change
                          },
                        )
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 7: Decisiones (placeholder)
                    plan != null
                        ? _buildDecisionsTabPlaceholder(plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
                          ),
                    // Tab 8: Monitoreo (placeholder)
                    plan != null
                        ? _buildMonitoringTabPlaceholder(plan)
                        : _buildLockedTab(
                            title: 'Bloqueado',
                            message:
                                'Completa Entrevista y genera plan para habilitar esta secci├│n.',
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

  Widget _buildOverviewTabPlaceholder(TrainingPlanConfig plan) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan ID: ${plan.id}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Semanas: ${plan.weeks.length}'),
          const SizedBox(height: 8),
          Text(
            '${plan.weeks.fold(0, (sum, week) => sum + week.sessions.length)} sesiones totales',
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesTabPlaceholder(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.fitness_center, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Tab de ejercicios (pendiente)'),
        ],
      ),
    );
  }

  Widget _buildProgressionTabPlaceholder(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.trending_up, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Tab de progresi├│n (pendiente)'),
        ],
      ),
    );
  }

  Widget _buildDecisionsTabPlaceholder(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.description, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Tab de decisiones (pendiente)'),
        ],
      ),
    );
  }

  Widget _buildMonitoringTabPlaceholder(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.assessment, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Tab de monitoreo (pendiente)'),
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // M├®todos _setSection y _sectionTitle eliminados (ya no se necesitan con TabBar)

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
      // Ô£à Normalizar m├║sculos al cargar (por si hay datos legacy)
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
    // Ô£à Normalizar al construir desde legacy keys
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

    return TrainingProgressionStateV1(
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

  // ignore: unused_element
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

  // ignore: unused_element
  Future<void> _saveEvaluation(
    Client client,
    TrainingEvaluationSnapshotV1 current,
  ) async {
    final now = DateTime.now();
    // Ô£à NORMALIZAR A KEYS CAN├ôNICAS (evitar labels duplicados)
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
      '[TrainingWorkspace] Guardando evaluaci├│n: daysPerWeek=$daysPerWeek',
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
      // Ô£à Guardar en AMBOS keys para compatibilidad con legacy code
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

  // ignore: unused_element
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

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.training.extra);
      extra[TrainingExtraKeys.trainingProgressionStateV1] = progression
          .toJson();
      return current.copyWith(
        training: current.training.copyWith(extra: extra),
      );
    });
  }

  // ignore: unused_element
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

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.training.extra);
      extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] = updated.toJson();
      return current.copyWith(
        training: current.training.copyWith(extra: extra),
      );
    });
  }

  // ignore: unused_element
  Future<void> _handlePlanAction(
    BuildContext context, {
    required PlanAction action,
    required TrainingEvaluationSnapshotV1 evaluation,
    required TrainingProgressionStateV1 progression,
  }) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final errors = _validateAction(client, evaluation, progression);
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
        .generatePlanV3(selectedDate: DateTime.now());
    await ref.read(clientsProvider.notifier).refresh();

    final refreshedClient = ref.read(clientsProvider).value?.activeClient;
    final lastPlanId =
        refreshedClient?.training.extra[TrainingExtraKeys.activePlanId]
            ?.toString() ??
        '';

    final resetProgression = action == PlanAction.regenerate;
    final updatedProgression = TrainingProgressionStateV1(
      weeksCompleted: resetProgression ? 0 : progression.weeksCompleted,
      sessionsCompleted: resetProgression ? 0 : progression.sessionsCompleted,
      consecutiveWeeksTraining: resetProgression
          ? 0
          : progression.consecutiveWeeksTraining,
      averageRIR: resetProgression ? 0.0 : progression.averageRIR,
      averageSessionRPE: resetProgression ? 0.0 : progression.averageSessionRPE,
      perceivedRecovery: resetProgression ? 0.0 : progression.perceivedRecovery,
      lastPlanId: lastPlanId,
      lastPlanChangeReason: action.name,
    );

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.training.extra);
      extra[TrainingExtraKeys.trainingProgressionStateV1] = updatedProgression
          .toJson();
      return current.copyWith(
        training: current.training.copyWith(extra: extra),
      );
    });
  }

  List<String> _validateAction(
    Client client,
    TrainingEvaluationSnapshotV1 evaluation,
    TrainingProgressionStateV1 progression,
  ) {
    final errors = <String>[];
    final setup = _readSetup(client);

    if (!setup.isValid) {
      errors.add('Setup fisico invalido');
    }

    if (evaluation.daysPerWeek <= 0 ||
        evaluation.sessionDurationMinutes <= 0 ||
        evaluation.planDurationInWeeks <= 0) {
      errors.add('Evaluacion incompleta');
    }

    final allMuscles = <String>{}
      ..addAll(evaluation.primaryMuscles)
      ..addAll(evaluation.secondaryMuscles)
      ..addAll(evaluation.tertiaryMuscles);
    if (allMuscles.isEmpty) {
      errors.add('Prioridades musculares vacias');
    }

    final duplicates = _findPriorityDuplicates(
      evaluation.primaryMuscles,
      evaluation.secondaryMuscles,
      evaluation.tertiaryMuscles,
    );
    if (duplicates.isNotEmpty) {
      errors.add('Prioridades ambiguas: ${duplicates.join(', ')}');
    }

    final splitId = client.training.extra[TrainingExtraKeys.selectedSplitId]
        ?.toString();
    if (splitId != null && splitId.isNotEmpty) {
      final template = LegacySplitTemplates.getTemplateById(splitId);
      if (template != null && template.daysPerWeek != evaluation.daysPerWeek) {
        errors.add('Dias incompatibles con el split seleccionado');
      }
    }

    return errors;
  }

  List<String> _findPriorityDuplicates(
    List<String> primary,
    List<String> secondary,
    List<String> tertiary,
  ) {
    final duplicates = <String>{};
    final seen = <String>{};

    void register(List<String> items) {
      for (final item in items) {
        final key = item.trim();
        if (key.isEmpty) continue;
        if (seen.contains(key)) {
          duplicates.add(key);
        } else {
          seen.add(key);
        }
      }
    }

    register(primary);
    register(secondary);
    register(tertiary);

    return duplicates.toList();
  }

  /// Ô£à NORMALIZACI├ôN A KEYS CAN├ôNICAS
  /// Convierte labels legacy a keys est├índar de Motor V3
  List<String> _normalizeMuscleKeys(List<String> keys) {
    const labelToKeyMap = {
      'Pecho': 'chest',
      'Dorsal ancho': 'lats',
      'Dorsal ancho (Lats)': 'lats',
      'Espalda alta': 'upper_back',
      'Espalda alta / Esc├ípulas': 'upper_back',
      'Espalda alta / Esc├ípulas (Upper back)': 'upper_back',
      'Upper back': 'upper_back',
      'Trapecios': 'traps',
      'Deltoide Anterior': 'deltoide_anterior',
      'Deltoide anterior': 'deltoide_anterior',
      'Deltoide Lateral': 'deltoide_lateral',
      'Deltoide lateral': 'deltoide_lateral',
      'Deltoide Posterior': 'deltoide_posterior',
      'Deltoide posterior': 'deltoide_posterior',
      'B├¡ceps': 'biceps',
      'Tr├¡ceps': 'triceps',
      'Cu├ídriceps': 'quads',
      'Isquiotibiales': 'hamstrings',
      'Gl├║teos': 'glutes',
      'Pantorrillas': 'calves',
      'Abdominales': 'abs',
    };

    final expanded = <String>[];
    for (final k in keys) {
      final trimmed = k.trim();
      final normalized = labelToKeyMap[trimmed] ?? trimmed;
      // Ô£à Handle legacy 'back' expansion
      if (normalized == 'back') {
        expanded.addAll(['lats', 'upper_back', 'traps']);
      } else {
        expanded.add(normalized);
      }
    }

    // Ô£à Filter against canonical 14-muscle set
    const canonicalKeys = {
      'chest',
      'lats',
      'upper_back',
      'traps',
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
      'biceps',
      'triceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
    };

    return expanded.where((k) => canonicalKeys.contains(k)).toSet().toList();
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
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
  }

  int _parseInt(String raw) {
    return int.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }

  String _formatDouble(num value) {
    return value == 0 ? '' : value.toString();
  }

  Future<void> _commitInterview() async {
    try {
      await _interviewTabKey.currentState?.commit();
    } catch (e) {
      debugPrint('[TrainingWorkspace] commit interview failed: $e');
    }
  }

  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  // E2 GOBERNANZA: M├ëTODOS PARA PLAN V3 (CON VERIFICACI├ôN)
  // ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
  Future<void> _generarPlan() async {
    final interviewStatus =
        ref.read(trainingWorkspaceProvider).interviewStatus;
    if (interviewStatus != TrainingInterviewStatus.valid) {
      return;
    }
    // E2: Verificar que la acci├│n est├® permitida
    await _commitInterview();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final allowedAction = _checkPlanActionAllowed(client);
    if (allowedAction == TrainingPlanAction.locked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ÔØî Plan bloqueado: ${_getPlanActionTooltip(allowedAction, client)}',
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

      // E2: Actualizar estado de progresi├│n despu├®s de generar
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

  void _regenerarPlan() {
    unawaited(_commitInterview());
    // E2: Verificar que la acci├│n est├® permitida
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final allowedAction = _checkPlanActionAllowed(client);
    if (allowedAction != TrainingPlanAction.regenerate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ÔØî Regeneraci├│n no permitida: ${_getPlanActionTooltip(allowedAction, client)}',
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
          '┬┐Regenerar plan completo Motor V3?\n\nEsto crear├í un nuevo plan desde cero.',
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
              // E2: Actualizar estado de progresi├│n
              await _updateProgressionAfterPlanAction('regenerate');
            },
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  Future<void> _adaptarPlan() async {
    await _commitInterview();
    // E2: Verificar que la acci├│n est├® permitida
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final allowedAction = _checkPlanActionAllowed(client);
    if (allowedAction != TrainingPlanAction.adapt) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ÔØî Adaptaci├│n no permitida: ${_getPlanActionTooltip(allowedAction, client)}',
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

      // E2: Actualizar estado de progresi├│n despu├®s de adaptar
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

  // E2: Actualizar estado de progresi├│n despu├®s de acci├│n de plan
  Future<void> _updateProgressionAfterPlanAction(String action) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    try {
      final progressionMap =
          client.training.extra[TrainingExtraKeys.trainingProgressionStateV1]
              as Map<String, dynamic>? ??
          {};
      final progression = progressionMap.isNotEmpty
          ? TrainingProgressionStateV1.fromJson(progressionMap)
          : const TrainingProgressionStateV1(
              weeksCompleted: 0,
              sessionsCompleted: 0,
              consecutiveWeeksTraining: 0,
              averageRIR: 2.0,
              averageSessionRPE: 7,
              perceivedRecovery: 7,
              lastPlanId: '',
              lastPlanChangeReason: 'initial',
            );

      // Crear historial de adaptaci├│n
      final adaptationHistoryCopy = List<Map<String, dynamic>>.from(
        progression.adaptationHistory,
      );
      adaptationHistoryCopy.add({
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'weekCompleted': progression.weeksCompleted,
      });

      // Actualizar progresi├│n
      final updatedProgressionMap = {
        ...progression.toJson(),
        'lastAdaptationAt': DateTime.now().toIso8601String(),
        'adaptationHistory': adaptationHistoryCopy,
        'lastPlanChangeReason': action,
      };

      // Persistir
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        return prev.copyWith(
          training: prev.training.copyWith(
            extra: {
              ...prev.training.extra,
              TrainingExtraKeys.trainingProgressionStateV1:
                  updatedProgressionMap,
            },
          ),
        );
      });
    } catch (e) {
      debugPrint('ÔÜá´©Å Error al actualizar progresi├│n: $e');
    }
  }
}
