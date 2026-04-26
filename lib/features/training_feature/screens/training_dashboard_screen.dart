// ignore_for_file: unused_element, unused_field, prefer_final_fields, unnecessary_to_list_in_spreads
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_workspace_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:intl/intl.dart';

// ENTREVISTA DE ENTRENAMIENTO (SSOT)
import '../tabs/training_interview_tab.dart';

// IMPORTS DE WIDGETS LEGACY (deprecados, mantener por compatibilidad temporal)
import '../widgets/volume_capacity_scientific_view.dart';
import '../widgets/series_distribution_editor.dart';
import '../widgets/weekly_plan_detail_view.dart';

/// Pantalla unificada de entrenamiento Motor V3
///
/// ARQUITECTURA:
/// - Patrón: Workspace full-screen (similar a Historia Clínica)
/// - Contenido: 8 tabs científicas de Motor V3
/// - Reemplaza: TrainingDashboardScreen legacy (5 tabs de versiones anteriores)
///
/// TABS:
/// 1. Overview: Resumen ejecutivo del plan
/// 2. Volumen: MEV/MAV/MRV científico (01-volume.md)
/// 3. Sesiones: Plan semanal detallado
/// 4. Ejercicios: Catálogo con selección científica (04-exercise-selection.md)
/// 5. Progresión: Periodización (06-progression-variation.md)
/// 6. Intensidad: Distribución Heavy/Medium/Light (02-intensity.md)
/// 7. Decisiones: DecisionTrace científico (trazabilidad)
/// 8. Monitoreo: Adherencia y ajustes reactivos
///
/// FUNDAMENTOS CIENTÍFICOS:
/// - docs/scientific-foundation/01-volume.md
/// - docs/scientific-foundation/02-intensity.md
/// - docs/scientific-foundation/03-effort-rir.md
/// - docs/scientific-foundation/04-exercise-selection.md
/// - docs/scientific-foundation/05-configuration-distribution.md
/// - docs/scientific-foundation/06-progression-variation.md
/// - docs/scientific-foundation/07-intensification-techniques.md
class TrainingDashboardScreen extends ConsumerStatefulWidget {
  final String activeDateIso;

  const TrainingDashboardScreen({super.key, required this.activeDateIso});

  @override
  ConsumerState<TrainingDashboardScreen> createState() =>
      _TrainingDashboardScreenState();
}

class _TrainingDashboardScreenState
    extends ConsumerState<TrainingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  late VoidCallback _tabListener;
  String? _dismissedDeloadSnapshotAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 9, // 9 tabs Motor V3 (1 entrevista + 8 tabs)
      vsync: this,
    );
    _tabListener = () {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    };
    _tabController.addListener(_tabListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final workspaceState = ref.watch(trainingWorkspaceProvider);
    final interviewStatus = workspaceState.interviewStatus;
    final isPlanOutdated = workspaceState.isPlanOutdated;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: clientsAsync.when(
        data: (_) => _buildAppBar(clientsAsync, interviewStatus),
        loading: () => _buildLoadingAppBar(),
        error: (_, __) => _buildErrorAppBar(),
      ),
      floatingActionButton: _buildFloatingActionButton(clientsAsync),
      body: clientsAsync.when(
        data: (state) {
          final client = state.activeClient;
          if (client == null) {
            return _buildNoClientState();
          }

          // ✅ ACT-001: SSOT estricto - Plan activo solo por activePlanId
          if (client.trainingPlans.isEmpty) {
            debugPrint('❌ TrainingDashboard: No hay planes Motor V3');
            return _buildNoPlanState(client);
          }

          final plans = client.trainingPlans;
          TrainingPlanConfig? plan;

          // 1) Intentar usar activePlanId (SSOT)
          final activePlanId =
              client.training.extra[TrainingExtraKeys.activePlanId] as String?;

          if (activePlanId != null && activePlanId.isNotEmpty) {
            try {
              plan = plans.firstWhere((p) => p.id == activePlanId);
              debugPrint(
                '✅ TrainingDashboard: Plan activo encontrado por activePlanId',
              );
            } on StateError {
              debugPrint(
                '❌ TrainingDashboard: activePlanId no coincide con ningún plan',
              );
            }
          }

          if (plan == null) {
            debugPrint('❌ TrainingDashboard: plan activo inválido o ausente');
            return _buildNoPlanState(client);
          }

          debugPrint('✅ TrainingDashboard: Renderizando plan Motor V3:');
          debugPrint('   ID: ${plan.id}');
          debugPrint('   Inicio: ${plan.startDate}');
          debugPrint('   Semanas: ${plan.weeks.length}');
          debugPrint('   Fuente: activePlanId (SSOT)');

          // ✅ activePlanId es SSOT del plan activo (post FASE B)
          // ✅ Usar plan.id directamente (ya tenemos objeto completo)
          // ✅ RENDERIZAR TABS MOTOR V3
          return _buildMotorV3Workspace(
            plan,
            client,
            interviewStatus,
            isPlanOutdated,
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Text(
                'Cargando plan de entrenamiento...',
                style: TextStyle(color: kTextColorSecondary),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: kErrorColor),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar entrenamiento',
                style: TextStyle(color: kTextColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue clientsAsync,
    TrainingInterviewStatus interviewStatus,
  ) {
    final clientName =
        clientsAsync.value?.activeClient?.profile.fullName ?? 'Sin cliente';
    final planDate = DateTime.now();

    return AppBar(
      backgroundColor: kAppBarColor,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan de Entrenamiento Motor V3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Cliente: $clientName • ${DateFormat('dd/MM/yyyy').format(planDate)}',
            style: const TextStyle(
              fontSize: 11,
              color: kTextColorSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: kPrimaryColor),
          tooltip: 'Regenerar plan',
          onPressed: interviewStatus == TrainingInterviewStatus.valid
              ? () => _regenerarPlan()
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.download, color: kPrimaryColor),
          tooltip: 'Exportar PDF',
          onPressed: () => _exportarPDF(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _buildLoadingAppBar() {
    return AppBar(
      backgroundColor: kAppBarColor,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan de Entrenamiento Motor V3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Cargando...',
            style: TextStyle(
              fontSize: 11,
              color: kTextColorSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildErrorAppBar() {
    return AppBar(
      backgroundColor: kAppBarColor,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan de Entrenamiento Motor V3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Error al cargar datos',
            style: TextStyle(
              fontSize: 11,
              color: kErrorColor,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  FloatingActionButton? _buildFloatingActionButton(AsyncValue clientsAsync) {
    final activePlanId = clientsAsync
        .value
        ?.activeClient
        ?.training
        .extra[TrainingExtraKeys.activePlanId];

    // Solo mostrar botón si NO hay plan activo
    if (activePlanId != null) return null;

    return FloatingActionButton.extended(
      onPressed: () => _generarPlan(),
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Generar Plan Motor V3'),
      backgroundColor: const Color(0xFF00D9FF),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildMotorV3Workspace(
    TrainingPlanConfig plan,
    dynamic client,
    TrainingInterviewStatus interviewStatus,
    bool isPlanOutdated,
  ) {
    final deloadAlert = _resolveDeloadAlertMessage(client);

    // Verificar si hay plan activo
    final activePlanId =
        client.training.extra[TrainingExtraKeys.activePlanId] as String?;
    final hasPlan = activePlanId != null && activePlanId.isNotEmpty;

    final canRegenerate = interviewStatus == TrainingInterviewStatus.valid;

    return Column(
      children: [
        if (deloadAlert != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Alerta de Fatiga',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  deloadAlert,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _dismissDeloadAlert,
                      child: const Text(
                        'Descartar',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () => _generarPlanConDeload(),
                      child: const Text('Generar semana descarga'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        // Header con acciones (arriba de tabs)
        Container(
          color: kAppBarColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Generar (solo si NO hay plan activo)
              if (!hasPlan)
                ElevatedButton.icon(
                  onPressed: () => _generarPlan(),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generar Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              if (hasPlan) ...[
                // Regenerar
                ElevatedButton.icon(
                  onPressed: canRegenerate ? () => _regenerarPlan() : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Regenerar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                // Adaptar
                Tooltip(
                  message: isPlanOutdated
                      ? 'El plan está desactualizado. Regenera antes de adaptar.'
                      : 'Adaptar plan',
                  child: ElevatedButton.icon(
                    onPressed: isPlanOutdated ? null : () => _adaptarPlan(),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Adaptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // TabBar sticky (igual que Historia Clínica)
        Container(
          color: kAppBarColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Entrevista'),
              Tab(text: 'Overview'),
              Tab(text: 'Volumen'),
              Tab(text: 'Sesiones'),
              Tab(text: 'Ejercicios'),
              Tab(text: 'Progresión'),
              Tab(text: 'Intensidad'),
              Tab(text: 'Decisiones'),
              Tab(text: 'Monitoreo'),
            ],
            labelColor: kPrimaryColor,
            unselectedLabelColor: kTextColorSecondary,
            indicatorColor: kPrimaryColor,
            indicatorWeight: 3,
          ),
        ),

        // TabBarView ocupa resto del espacio
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Entrevista (SSOT)
                TrainingInterviewTab(
                  key: GlobalKey<TrainingInterviewTabState>(),
                ),
                // Tab 1: Overview
                _buildOverviewTab(plan),
                // Tab 2: Volumen
                VolumeCapacityScientificView(plan: plan),
                // Tab 3: Sesiones
                WeeklyPlanDetailView(plan: plan),
                // Tab 4: Ejercicios (placeholder)
                _buildExercisesTab(plan),
                // Tab 5: Progresión (placeholder)
                _buildProgressionTab(plan),
                // Tab 6: Intensidad
                SeriesDistributionEditor(
                  trainingExtra: client.training.extra as Map<String, dynamic>,
                  onDistributionChanged: (distribution) {
                    // Handle distribution change
                  },
                ),
                // Tab 7: Decisiones (placeholder)
                _buildDecisionsTab(plan, client),
                // Tab 8: Monitoreo (placeholder)
                _buildMonitoringTab(plan, client),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TABS IMPLEMENTATION

  Widget _buildOverviewTab(TrainingPlanConfig plan) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del programa
          Card(
            color: kCardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: kPrimaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.splitId} • ${plan.microcycleLengthInWeeks} semanas',
                              style: const TextStyle(
                                fontSize: 14,
                                color: kTextColorSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 32, color: kTextColor.withAlpha(20)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProgramStat(
                          'Inicio',
                          DateFormat('dd/MM/yyyy').format(plan.startDate),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProgramStat(
                          'Semanas',
                          '${plan.microcycleLengthInWeeks}',
                          Icons.event,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats
          const Text(
            'Resumen Ejecutivo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: kCardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Programa científico basado en:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Volumen: MEV/MAV/MRV (Israetel 2020)'),
                  _buildBulletPoint(
                    'Distribución: 25/50/25 Heavy/Medium/Light',
                  ),
                  _buildBulletPoint('Periodización: 4 semanas acumulación'),
                  _buildBulletPoint(
                    'RIR óptimo: 2-3 reps en reserva (Helms 2018)',
                  ),
                  _buildBulletPoint('Frecuencia: 2x por músculo (Grgic 2018)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesTab(TrainingPlanConfig plan) {
    if (plan.weeks.isEmpty) {
      return const Center(
        child: Text(
          'Sin semanas en el plan',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    final firstWeek = plan.weeks.first;
    final sessions = firstWeek.sessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'Sin sesiones generadas',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semana 1 — ${sessions.length} sesiones',
            style: const TextStyle(
              color: kTextColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sessions.map((session) => _buildSessionCard(session)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          session.sessionName,
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${session.prescriptions.length} ejercicios • Día ${session.dayNumber}',
          style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
        ),
        children: session.prescriptions
            .map(
              (p) => ListTile(
                dense: true,
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      p.label,
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  p.exerciseName,
                  style: const TextStyle(color: kTextColor, fontSize: 13),
                ),
                subtitle: Text(
                  '${p.sets} series × ${p.repRange} reps • RIR ${p.rir}',
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProgressionTab(TrainingPlanConfig plan) {
    final weeks = plan.weeks;
    if (weeks.isEmpty) {
      return const Center(
        child: Text(
          'Sin semanas en el plan',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    final split = plan.state?['split']?.toString() ?? plan.splitId;
    final totalSesiones = weeks.fold<int>(
      0,
      (sum, w) => sum + w.sessions.length,
    );
    final totalEjercicios = weeks.fold<int>(
      0,
      (sum, w) =>
          sum +
          w.sessions.fold<int>(0, (s2, sess) => s2 + sess.prescriptions.length),
    );
    final maxWeekSets = weeks
        .map(
          (w) => w.sessions.fold<int>(
            0,
            (s, sess) =>
                s + sess.prescriptions.fold<int>(0, (s2, p) => s2 + p.sets),
          ),
        )
        .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                    _progrStat('${weeks.length}', 'Semanas', kInfoColor),
                    const SizedBox(width: 12),
                    _progrStat('$totalSesiones', 'Sesiones', kSuccessColor),
                    const SizedBox(width: 12),
                    _progrStat('$totalEjercicios', 'Ejercicios', kWarningColor),
                    const SizedBox(width: 12),
                    _progrStat(split.toUpperCase(), 'Split', kPrimaryColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Timeline de semanas',
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
              (sum, sess) =>
                  sum + sess.prescriptions.fold<int>(0, (s2, p) => s2 + p.sets),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: phaseColor.withAlpha(80)),
                boxShadow: [
                  BoxShadow(
                    color: phaseColor.withAlpha(20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: phaseColor.withAlpha(40),
                      shape: BoxShape.circle,
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
                          '${week.sessions.length} sesiones • $totalSets sets totales',
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
                        '$totalSets sets',
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
                          widthFactor: (totalSets / maxWeekSets).clamp(
                            0.05,
                            1.0,
                          ),
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
          const SizedBox(height: 20),
          if (plan.volumePerMuscle != null &&
              plan.volumePerMuscle!.isNotEmpty) ...[
            const Text(
              'Distribución de volumen',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ...() {
              final vol = plan.volumePerMuscle!;
              final maxSets = vol.values.reduce((a, b) => a > b ? a : b);
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
                            value: e.value / maxSets,
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

  Widget _progrStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                fontSize: 13,
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

  Widget _buildDecisionsTab(TrainingPlanConfig plan, dynamic client) {
    final extra = client.training.extra as Map<String, dynamic>? ?? {};
    final rawArtifacts = extra['weeklyDecisionArtifactsV1'] as Map? ?? {};

    final generatedBy =
        plan.state?['generated_by']?.toString() ?? 'motor_v3_scientific';
    final scientificVersion =
        plan.state?['scientific_version']?.toString() ?? '2.0.0';
    final periodizationModel =
        plan.state?['periodization_model']?.toString() ?? 'linear_progressive';
    final phaseStr = plan.phase.name;
    final generatedAt = plan.startDate;

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
                _decisionRow('Motor', generatedBy),
                _decisionRow('Versión científica', scientificVersion),
                _decisionRow('Modelo', periodizationModel),
                _decisionRow('Fase detectada', phaseStr.toUpperCase()),
                _decisionRow(
                  'Generado',
                  '${generatedAt.day}/${generatedAt.month}/${generatedAt.year}',
                ),
                _decisionRow('Split', plan.splitId),
                _decisionRow('Semanas', '${plan.microcycleLengthInWeeks}'),
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
                      'Las decisiones semanales se generan automáticamente al cerrar cada semana de entrenamiento.',
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
              final weekKey = entry.key;
              final weekData = entry.value as Map? ?? {};
              final weekNum =
                  weekData['weekNumber'] as int? ??
                  int.tryParse(weekKey.toString().replaceAll('week_', '')) ??
                  0;
              final phase = weekData['phase']?.toString() ?? 'accumulation';
              final actionByMuscle = weekData['actionByMuscle'] as Map? ?? {};
              final insightByMuscle = weekData['insightByMuscle'] as Map? ?? {};
              final newSets = weekData['newDirectSetsByMuscle'] as Map? ?? {};

              Color phaseColor;
              if (phase == 'deload') {
                phaseColor = kSuccessColor;
              } else if (phase == 'intensification') {
                phaseColor = kWarningColor;
              } else {
                phaseColor = kInfoColor;
              }

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
                  title: Text(
                    'Semana $weekNum',
                    style: const TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    phase.toUpperCase(),
                    style: TextStyle(color: phaseColor, fontSize: 11),
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
                  children: [
                    if (actionByMuscle.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Sin decisiones registradas',
                          style: TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ...actionByMuscle.entries.map((e) {
                        final muscle = e.key.toString();
                        final action = e.value.toString();
                        final insight =
                            insightByMuscle[muscle]?.toString() ?? '';
                        final sets = newSets[muscle]?.toString() ?? '-';

                        Color actionColor;
                        IconData actionIcon;
                        if (action == 'increase') {
                          actionColor = kSuccessColor;
                          actionIcon = Icons.arrow_upward;
                        } else if (action == 'deload') {
                          actionColor = kInfoColor;
                          actionIcon = Icons.spa;
                        } else {
                          actionColor = kWarningColor;
                          actionIcon = Icons.remove;
                        }

                        return Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: actionColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: actionColor.withAlpha(50),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    actionIcon,
                                    size: 14,
                                    color: actionColor,
                                  ),
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
                      }),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _decisionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
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

  Widget _buildMonitoringTab(TrainingPlanConfig plan, dynamic client) {
    final extra = client.training.extra as Map<String, dynamic>? ?? {};

    final progressionMap = extra['trainingProgressionStateV1'] as Map? ?? {};
    final weeksCompleted =
        (progressionMap['weeksCompleted'] as num?)?.toInt() ?? 0;
    final sessionsCompleted =
        (progressionMap['sessionsCompleted'] as num?)?.toInt() ?? 0;
    final avgRir = (progressionMap['averageRIR'] as num?)?.toDouble() ?? 2.0;
    final avgRpe = (progressionMap['averageSessionRPE'] as num?)?.toInt() ?? 7;
    final recovery =
        (progressionMap['perceivedRecovery'] as num?)?.toInt() ?? 7;

    final totalWeeks = plan.weeks.length;
    final progressPct = totalWeeks > 0
        ? (weeksCompleted / totalWeeks).clamp(0.0, 1.0)
        : 0.0;

    final totalSessions = plan.weeks.fold<int>(
      0,
      (s, w) => s + w.sessions.length,
    );

    final accumWeeks = plan.weeks
        .where((w) => w.phase == TrainingPhase.accumulation)
        .length;
    final intensWeeks = plan.weeks
        .where((w) => w.phase == TrainingPhase.intensification)
        .length;
    final deloadWeeks = plan.weeks
        .where((w) => w.phase == TrainingPhase.deload)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                      '$weeksCompleted / $totalWeeks sem',
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Row(
            children: [
              _monitorCard(
                '$sessionsCompleted',
                'Sesiones\ncompletadas',
                kSuccessColor,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _monitorCard(
                '$totalSessions',
                'Sesiones\ndel plan',
                kInfoColor,
                Icons.calendar_today,
              ),
              const SizedBox(width: 10),
              _monitorCard(
                avgRir.toStringAsFixed(1),
                'RIR\npromedio',
                avgRir <= 1.5
                    ? kWarningColor
                    : avgRir >= 3
                    ? kSuccessColor
                    : kPrimaryColor,
                Icons.fitness_center,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _monitorCard(
                '$avgRpe / 10',
                'RPE\npromedio',
                avgRpe >= 9
                    ? kErrorColor
                    : avgRpe <= 6
                    ? kSuccessColor
                    : kWarningColor,
                Icons.speed,
              ),
              const SizedBox(width: 10),
              _monitorCard(
                '$recovery / 10',
                'Recuperación\npercibida',
                recovery >= 7
                    ? kSuccessColor
                    : recovery <= 5
                    ? kErrorColor
                    : kWarningColor,
                Icons.battery_charging_full,
              ),
              const SizedBox(width: 10),
              _monitorCard(
                '$totalWeeks sem',
                'Duración\ndel plan',
                kTextColorSecondary,
                Icons.event,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Distribución por fases',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _phaseDistRow(
            'Acumulación',
            accumWeeks,
            totalWeeks,
            kInfoColor,
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _phaseDistRow(
            'Intensificación',
            intensWeeks,
            totalWeeks,
            kWarningColor,
            Icons.bolt,
          ),
          const SizedBox(height: 8),
          _phaseDistRow(
            'Deload / Descarga',
            deloadWeeks,
            totalWeeks,
            kSuccessColor,
            Icons.spa,
          ),
          const SizedBox(height: 20),
          const Text(
            'Indicadores de fatiga',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _fatigueIndicator(
            label: 'RIR promedio',
            value: avgRir,
            min: 0,
            max: 4,
            dangerBelow: 1.5,
            warningBelow: 2.5,
            unit: 'RIR',
            inverseColors: false,
          ),
          const SizedBox(height: 8),
          _fatigueIndicator(
            label: 'RPE promedio',
            value: avgRpe.toDouble(),
            min: 1,
            max: 10,
            dangerAbove: 8.5,
            warningAbove: 7.5,
            unit: '/10',
            inverseColors: true,
          ),
          const SizedBox(height: 8),
          _fatigueIndicator(
            label: 'Recuperación',
            value: recovery.toDouble(),
            min: 1,
            max: 10,
            dangerBelow: 5,
            warningBelow: 7,
            unit: '/10',
            inverseColors: false,
          ),
          const SizedBox(height: 16),
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
                    'Evidencia: RIR < 1.5 sostenido indica acumulación de fatiga. '
                    'RPE > 8.5 por más de 2 semanas sin deload aumenta riesgo de lesión '
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

  Widget _monitorCard(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
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

  Widget _phaseDistRow(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count sem',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _fatigueIndicator({
    required String label,
    required double value,
    required double min,
    required double max,
    double? dangerBelow,
    double? warningBelow,
    double? dangerAbove,
    double? warningAbove,
    required String unit,
    required bool inverseColors,
  }) {
    Color statusColor;
    String statusText;

    if (dangerBelow != null && value < dangerBelow) {
      statusColor = kErrorColor;
      statusText = 'Crítico';
    } else if (warningBelow != null && value < warningBelow) {
      statusColor = kWarningColor;
      statusText = 'Atención';
    } else if (dangerAbove != null && value > dangerAbove) {
      statusColor = kErrorColor;
      statusText = 'Crítico';
    } else if (warningAbove != null && value > warningAbove) {
      statusColor = kWarningColor;
      statusText = 'Atención';
    } else {
      statusColor = kSuccessColor;
      statusText = 'OK';
    }

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((value - min) / (max - min)).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toStringAsFixed(1)}$unit',
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // EMPTY STATES

  Widget _buildNoClientState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.white.withAlpha(60)),
          const SizedBox(height: 24),
          const Text(
            'No hay cliente activo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona un cliente para ver su plan de entrenamiento',
            style: TextStyle(fontSize: 13, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanState(dynamic client) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: const Color(0xFF00D9FF).withAlpha(150),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin plan Motor V3 activo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Genera un plan científico basado en 7 fundamentos',
            style: TextStyle(fontSize: 13, color: kTextColorSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _generarPlan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('Generar Plan Motor V3'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              await ref.read(trainingPlanProvider.notifier).clearActivePlan();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ciclo reiniciado. Genera un nuevo plan.'),
                    backgroundColor: kSuccessColor,
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.refresh,
              size: 16,
              color: kTextColorSecondary,
            ),
            label: const Text(
              'Reiniciar ciclo',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanNotFoundState(String planId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: kErrorColor),
          const SizedBox(height: 24),
          const Text(
            'Plan no encontrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: $planId',
            style: const TextStyle(
              fontSize: 11,
              color: kTextColorSecondary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _generarPlan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('Regenerar Plan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HELPERS

  Widget _buildProgramStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: kTextColorSecondary),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: kPrimaryColor, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // ACTIONS

  Future<void> _generarPlan() async {
    try {
      final now = DateTime.now();
      final generated = await ref
          .read(trainingPlanProvider.notifier)
          .generatePlanFromActiveCycle(now);

      if (generated == null) {
        final error = ref.read(trainingPlanProvider).error;
        throw Exception(error ?? 'No se pudo generar el plan');
      }

      // ✅ ACT-001: El provider ya actualiza activePlanId internamente
      // No duplicar escritura aquí (UI solo consume, no decide)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan Motor V3 generado correctamente'),
            backgroundColor: kSuccessColor,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerar Plan'),
        content: const Text('¿Regenerar plan completo Motor V3?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generarPlan();
            },
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  void _exportarPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando a PDF...'),
        backgroundColor: kPrimaryColor,
      ),
    );
  }

  Future<void> _adaptarPlan() async {
    try {
      final now = DateTime.now();
      final generated = await ref
          .read(trainingPlanProvider.notifier)
          .generatePlanFromActiveCycle(now);

      if (generated == null) {
        final error = ref.read(trainingPlanProvider).error;
        throw Exception(error ?? 'No se pudo adaptar el plan');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan adaptado correctamente'),
            backgroundColor: kSuccessColor,
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

  Future<void> _generarPlanConDeload() async {
    await ref
        .read(trainingPlanProvider.notifier)
        .generatePlanFromActiveCycle(DateTime.now());

    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      await ref
          .read(trainingPlanProvider.notifier)
          .recordPlanAction(
            clientId: client.id,
            action: 'deload',
            appendAdaptationHistory: true,
          );
    }
  }

  String? _resolveDeloadAlertMessage(dynamic client) {
    final snapshotRaw = client.training.extra['lastPhaseResolutionV1'];
    if (snapshotRaw is! Map) {
      return null;
    }

    final snapshot = Map<String, dynamic>.from(snapshotRaw);
    final snapshotAt = snapshot['timestamp']?.toString();
    if (snapshotAt != null && snapshotAt == _dismissedDeloadSnapshotAt) {
      return null;
    }

    final needsDeload = snapshot['needsDeload'] == true;
    if (!needsDeload) {
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

  void _dismissDeloadAlert() {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final snapshotRaw = client.training.extra['lastPhaseResolutionV1'];
    if (snapshotRaw is! Map) return;

    setState(() {
      _dismissedDeloadSnapshotAt = snapshotRaw['timestamp']?.toString();
    });
  }
}
