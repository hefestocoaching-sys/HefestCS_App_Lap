// ignore_for_file: deprecated_member_use_from_same_package, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/engine_audit.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/utils/widgets/record_history_panel.dart';
import 'package:intl/intl.dart';

import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/domain/services/record_deletion_service_provider.dart';
import 'package:hcs_app_lap/features/common_widgets/record_deletion_dialogs.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';

// Widgets visuales
import '../widgets/volume_range_muscle_table.dart';
import '../widgets/intensity_split_table.dart';
import '../widgets/macrocycle_overview_tab.dart';
import '../widgets/weekly_plan_tab.dart';

class TrainingDashboardScreen extends ConsumerStatefulWidget {
  final String activeDateIso;

  const TrainingDashboardScreen({super.key, required this.activeDateIso});

  @override
  ConsumerState createState() => _TrainingDashboardScreenState();
}

class _TrainingDashboardScreenState
    extends ConsumerState<TrainingDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedWeekIndex = 0;
  DateTime? _selectedPlanStartDate;
  bool _hasLoadedPersistedSelection = false;
  DateTime? _selectedSessionLogDate;
  int _selectedTabIndex = 0;
  TabController? _tabController;

  TrainingProfile _resolveProfileForUi(
    TrainingPlanConfig plan,
    TrainingProfile current,
  ) {
    final snap = plan.trainingProfileSnapshot;
    if (snap == null) return current;

    bool snapHasIndiv() {
      final e = snap.extra;
      return (e['mevIndividual'] is num) &&
          (e['mrvIndividual'] is num) &&
          (e['targetSetsByMuscle'] is Map) &&
          (e['targetSetsByMuscle'] as Map).isNotEmpty;
    }

    bool currentHasIndiv() {
      final e = current.extra;
      return (e['mevIndividual'] is num) &&
          (e['mrvIndividual'] is num) &&
          (e['targetSetsByMuscle'] is Map) &&
          (e['targetSetsByMuscle'] as Map).isNotEmpty;
    }

    if (!snapHasIndiv() && currentHasIndiv()) return current;
    return snap;
  }

  TrainingProfile _resolveProfileForVmeUi({
    required TrainingPlanConfig? planConfig,
    required TrainingProfile currentProfile,
  }) {
    if (planConfig == null) return currentProfile;

    final snap = planConfig.trainingProfileSnapshot;
    if (snap == null) return currentProfile;

    final snapExtra = snap.extra;
    final currentExtra = currentProfile.extra;

    final snapHasLocalVolume =
        snapExtra['mevByMuscle'] is Map && snapExtra['mrvByMuscle'] is Map;
    final currentHasLocalVolume =
        currentExtra['mevByMuscle'] is Map &&
        currentExtra['mrvByMuscle'] is Map;

    // Si el snapshot NO tiene los datos nuevos, pero el perfil actual sí → usar actual
    if (!snapHasLocalVolume && currentHasLocalVolume) {
      return currentProfile;
    }

    return snap;
  }

  TrainingPlanConfig? _resolveDisplayedPlanConfig(Client client) {
    final trainingPlans = client.trainingPlans;
    if (trainingPlans.isEmpty) return null;

    // 1) SSOT: activePlanId
    final raw = client.training.extra[TrainingExtraKeys.activePlanId];
    final activeId = raw?.toString().trim();
    if (activeId != null && activeId.isNotEmpty) {
      final byId = trainingPlans.where((p) => p.id == activeId);
      if (byId.isNotEmpty) {
        return byId.first;
      }
    }

    // 2) Si el usuario seleccionó una fecha (historial)
    final latest = trainingPlans.reduce(
      (a, b) => a.startDate.isAfter(b.startDate) ? a : b,
    );

    if (_selectedPlanStartDate == null) return latest;

    final selected = trainingPlans.firstWhere(
      (p) => DateUtils.isSameDay(p.startDate, _selectedPlanStartDate),
      orElse: () => latest,
    );
    return selected;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: clientsAsync.when(
        data: (state) {
          final client = state.activeClient;
          if (client == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Selecciona un cliente o crea uno nuevo",
                    style: TextStyle(color: kTextColorSecondary),
                  ),
                ],
              ),
            );
          }

          return _buildDashboardBody(client);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: _selectedSessionLogDate != null
          ? FloatingActionButton.extended(
              heroTag: 'delete_training',
              onPressed: () {
                final client = ref.read(clientsProvider).value?.activeClient;
                if (client != null) {
                  _deleteSelectedSessionLog(client);
                }
              },
              label: const Text('Borrar'),
              icon: const Icon(Icons.delete_outline),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildDashboardBody(Client client) {
    // Cargar selección persistida una sola vez
    if (!_hasLoadedPersistedSelection) {
      _hasLoadedPersistedSelection = true;
      final persisted =
          client.training.extra[TrainingExtraKeys.selectedPlanStartDateIso];
      if (persisted != null) {
        final date = DateTime.tryParse(persisted.toString());
        if (date != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedPlanStartDate = date;
              });
            }
          });
        }
      }
    }

    // Detectar si hay datos en training.extra (persistidos por facade)
    final trainingExtra = client.training.extra;

    // ═══════════════════════════════════════════════════════════════════════
    // TAB 2/3: Usar extra persistido por facade garantizado
    // ═══════════════════════════════════════════════════════════════════════
    final Map<String, dynamic> effectiveExtra = {...trainingExtra};

    // Default UI para split si falta (NO fuerza guardado aquí)
    effectiveExtra.putIfAbsent(
      TrainingExtraKeys.seriesTypePercentSplit,
      () => {'heavy': 20, 'medium': 60, 'light': 20},
    );

    debugPrint(
      '[DASHBOARD] effectiveExtra split: ${effectiveExtra[TrainingExtraKeys.seriesTypePercentSplit]}',
    );

    return Column(
      children: [
        // TAREA A5 PARTE 1: Botón de generación Motor V2
        Container(
          color: kAppBarColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Plan de Entrenamiento',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  // Botón "Generar" (usa caché si existe)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      await ref
                          .read(trainingPlanProvider.notifier)
                          .generatePlanFromActiveCycle(now);
                      if (mounted && _tabController != null) {
                        _tabController!.animateTo(3);
                      }
                    },
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón "Regenerar" (fuerza nueva generación)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();

                      // Mostrar diálogo de confirmación
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Regenerar Plan'),
                          content: const Text(
                            '¿Estás seguro de regenerar el plan?\n\n'
                            'Esto borrará el plan actual y creará uno nuevo '
                            'con las configuraciones actualizadas.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Regenerar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      // Mostrar feedback: Limpiando
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Limpiando plan y ciclos...'),
                              ],
                            ),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }

                      // PASO 1: Limpiar plan activo y ciclos
                      debugPrint('🔧 [UI] PASO 1: Limpiando plan activo...');
                      await ref
                          .read(trainingPlanProvider.notifier)
                          .clearActivePlan();

                      // PASO 2: ESPERAR sincronización de Firestore (CRÍTICO)
                      debugPrint(
                        '⏳ [UI] PASO 2: Esperando sincronización Firestore (4 segundos)...',
                      );
                      await Future.delayed(const Duration(seconds: 4));
                      debugPrint('✅ [UI] PASO 2: Sincronización completa');

                      // Mostrar feedback: Generando
                      if (mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Generando plan nuevo...'),
                              ],
                            ),
                            duration: Duration(seconds: 20),
                          ),
                        );
                      }

                      // PASO 3: Generar plan nuevo
                      debugPrint(
                        '🔧 [UI] PASO 3: Generando plan desde ciclo activo...',
                      );
                      await ref
                          .read(trainingPlanProvider.notifier)
                          .generatePlanFromActiveCycle(now);

                      // Mostrar feedback: Completado
                      if (mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 16),
                                Text('Plan generado exitosamente'),
                              ],
                            ),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );

                        if (_tabController != null) {
                          _tabController!.animateTo(3);
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Regenerar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // TabBar fija en la parte superior
        Container(
          color: kAppBarColor,
          child: TabBar(
            controller: _tabController!,
            tabs: const [
              Tab(text: 'Volumen'),
              Tab(text: 'Perfiles'),
              Tab(text: 'Macrociclo'),
              Tab(text: 'Semanal'),
            ],
            labelColor: kPrimaryColor,
            unselectedLabelColor: kTextColorSecondary,
            indicatorColor: kPrimaryColor,
          ),
        ),
        // TabBarView ocupa el resto del espacio
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: TabBarView(
              controller: _tabController!,
              children: [
                // Tab 1: Volumen - Tabla de rangos por músculo (VME/VMR/Target)
                VolumeRangeMuscleTable(
                  trainingExtra: trainingExtra,
                  planJson: null,
                  planConfig: null,
                ),
                // Tab 2: Intensidad (Heavy / Medium / Light) - Usa efectiveExtra
                IntensitySplitTable(trainingExtra: effectiveExtra),
                // Tab 3: Macrociclo por músculo (AA/HF) sin dependencia de días
                MacrocycleOverviewTab(trainingExtra: effectiveExtra),
                // Tab 4: Plan semanal según días y split válido
                Builder(
                  builder: (context) {
                    final planConfig = _resolveDisplayedPlanConfig(client);
                    return WeeklyPlanTab(
                      planConfig: planConfig,
                      profile: client.training,
                      vopByMuscle: const {},
                      effectiveExtra: effectiveExtra,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Método legacy - mantener por si se necesita en el futuro
  List<Widget> _buildDashboardSlivers(Client client) {
    // Cargar selección persistida una sola vez
    if (!_hasLoadedPersistedSelection) {
      _hasLoadedPersistedSelection = true;
      final persisted =
          client.training.extra[TrainingExtraKeys.selectedPlanStartDateIso];
      if (persisted != null) {
        final date = DateTime.tryParse(persisted.toString());
        if (date != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedPlanStartDate = date;
              });
            }
          });
        }
      }
    }

    final normalizedProfile = client.training.normalizedFromExtra();
    final displayedPlanConfig = _resolveDisplayedPlanConfig(client);

    final planConfigForUi = displayedPlanConfig?.copyWith(
      trainingProfileSnapshot: _resolveProfileForUi(
        displayedPlanConfig,
        normalizedProfile,
      ),
    );

    // Detectar si hay datos v2 en training.extra (persistidos por facade)
    final trainingExtra = client.training.extra;
    final bool hasV2Volume =
        trainingExtra['targetSetsByMuscle'] is Map &&
        (trainingExtra['targetSetsByMuscle'] as Map).isNotEmpty;

    debugPrint('[DASHBOARD] hasV2Volume=$hasV2Volume');

    return [
      // Contenido pre-TabBar (scroll normal)
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Aquí va contenido pre-TabBar si es necesario
                ],
              ),
            ),
          ),
        ),
      ),
      // TabBar STICKY (pinned al scroll) - SOLO la barra de tabs
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyTabBarDelegate(tabController: _tabController!),
      ),
      // TabBarView como sliver separado (contenido scrollable)
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: TabBarView(
            controller: _tabController!,
            children: [
              // Tab 1: Volumen (VME / VMR / Target por músculo + Rol)
              VolumeRangeMuscleTable(
                trainingExtra: hasV2Volume ? trainingExtra : null,
                planJson: null,
                planConfig: hasV2Volume ? null : planConfigForUi,
              ),
              // Tab 2: Intensidad (Heavy / Medium / Light)
              IntensitySplitTable(trainingExtra: trainingExtra),
            ],
          ),
        ),
      ),
    ];
  }

  // ===================================================================
  // CARD PRINCIPAL DEL DASHBOARD (PESTAÑAS)

  // ===================================================================
  // RUTINA DIARIA (método mantenido para uso futuro)
  // ===================================================================
  Widget _buildDailyRoutineSection(
    Client client,
    TrainingPlanConfig planConfig,
  ) {
    if (planConfig.weeks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("El plan no tiene semanas configuradas."),
        ),
      );
    }

    if (_selectedWeekIndex >= planConfig.weeks.length) {
      _selectedWeekIndex = 0;
    }

    // Mostrar la semana seleccionada
    final currentWeek = planConfig.weeks[_selectedWeekIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de la semana
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kAppBarColor.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semana ${currentWeek.weekNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${currentWeek.sessions.length} sesiones',
                    style: TextStyle(color: kTextColorSecondary, fontSize: 12),
                  ),
                ],
              ),
              Text(
                'Volumen: ${currentWeek.sessions.fold<int>(0, (sum, s) => sum + s.prescriptions.length)} ejercicios',
                style: TextStyle(color: kPrimaryColor, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de sesiones
        ...currentWeek.sessions.map((session) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCardColor.withAlpha(150),
              border: Border.all(color: kPrimaryColor.withAlpha(100)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sesión ${session.dayNumber}: ${session.sessionName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${session.prescriptions.length} ejercicios',
                      style: TextStyle(color: kPrimaryColor, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...session.prescriptions.map((exercise) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Text('•', style: TextStyle(color: kPrimaryColor)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.exerciseName,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${exercise.sets} series × ${exercise.reps} (RIR: ${exercise.rir})',
                                style: TextStyle(
                                  color: kTextColorSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===================================================================
  // SESSION LOGS HISTORY
  // ===================================================================
  Widget _buildSessionLogsHistory(Client client) {
    final sessionLogs = readTrainingSessionLogs(
      client.training.extra[TrainingExtraKeys.trainingSessionLogRecords],
    );

    if (sessionLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return RecordHistoryPanel<TrainingSessionLog>(
      records: sessionLogs,
      selectedDate: _selectedSessionLogDate,
      onSelectDate: (date) {
        final log = trainingSessionLogForDate(
          sessionLogs,
          DateFormat('yyyy-MM-dd').format(date),
        );
        if (log != null) {
          setState(() {
            _selectedSessionLogDate = date;
          });
          _showSessionLogDialog(client, existingLog: log);
        }
      },
      primaryLabel: (log) {
        final exercises = log.entries.length;
        return '$exercises ejercicios registrados';
      },
      dateOf: (log) => DateTime.parse(log.dateIso),
      title: 'Historial de Sesiones',
    );
  }

  Widget _buildWeekNavigator(int totalWeeks, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: kPrimaryColor),
            onPressed: _selectedWeekIndex > 0
                ? () => setState(() => _selectedWeekIndex--)
                : null,
          ),
          Text(
            "SEMANA ${_selectedWeekIndex + 1} DE $totalWeeks",
            style: const TextStyle(
              color: kTextColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: kPrimaryColor),
            onPressed: _selectedWeekIndex < totalWeeks - 1
                ? () => setState(() => _selectedWeekIndex++)
                : null,
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // AUDITORÍA
  // ===================================================================
  Widget _buildAuditBanner(EngineAudit audit) {
    final isGluteEngine = audit.engineUsed == "gluteSpecialization";

    final Color accent = isGluteEngine
        ? Colors.pink.shade300
        : Colors.blue.shade300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Motor utilizado: ${audit.engineUsed}",
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            audit.reason,
            style: const TextStyle(color: kTextColorSecondary),
          ),
          if (audit.details.isNotEmpty) ...[
            const Divider(height: 18, color: kBorderColor),
            const Text(
              "Detalles técnicos:",
              style: TextStyle(
                color: kTextColorSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            for (final entry in audit.details.entries)
              Text(
                "• ${entry.key}: ${entry.value}",
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ===================================================================
  // SESSION LOG DIALOG
  // ===================================================================
  Future<void> _showSessionLogDialog(
    Client client, {
    TrainingSessionLog? existingLog,
  }) async {
    final sessionNameController = TextEditingController(
      text: existingLog?.sessionName ?? '',
    );
    final exerciseNameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final loadController = TextEditingController();
    final rpeController = TextEditingController();
    final parentContext = context;

    TrainingSessionLog? result;
    try {
      result = await showDialog<TrainingSessionLog>(
        context: parentContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: kCardColor,
            title: const Text('Registrar sesion'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sessionNameController,
                    decoration: hcsDecoration(
                      context,
                      labelText: 'Nombre de sesion (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: exerciseNameController,
                    decoration: hcsDecoration(
                      context,
                      labelText: 'Ejercicio (nombre o ID)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: hcsDecoration(context, labelText: 'Sets'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repsController,
                    decoration: hcsDecoration(
                      context,
                      labelText: 'Reps (ej: 10,10,8 o 10)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: loadController,
                    decoration: hcsDecoration(
                      context,
                      labelText: 'Carga (ej: 80,80,75 o 80)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rpeController,
                    decoration: hcsDecoration(
                      context,
                      labelText: 'RPE (opcional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final exerciseName = exerciseNameController.text.trim();
                  final sets = int.tryParse(setsController.text.trim()) ?? 0;
                  final reps = _expandIntList(
                    _parseIntList(repsController.text),
                    sets,
                  );
                  final load = _expandDoubleList(
                    _parseDoubleList(loadController.text),
                    sets,
                  );
                  final rpeValues = _parseDoubleList(rpeController.text);
                  final rpe = rpeValues.isEmpty
                      ? null
                      : _expandDoubleList(rpeValues, sets);

                  if (exerciseName.isEmpty ||
                      sets <= 0 ||
                      reps.isEmpty ||
                      load.isEmpty) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Completa al menos 1 ejercicio valido.'),
                      ),
                    );
                    return;
                  }

                  final entry = ExerciseLogEntry(
                    exerciseIdOrName: exerciseName,
                    sets: sets,
                    reps: reps,
                    load: load,
                    rpe: rpe,
                  );
                  final log = TrainingSessionLog(
                    dateIso: widget.activeDateIso,
                    sessionName: sessionNameController.text.trim().isEmpty
                        ? null
                        : sessionNameController.text.trim(),
                    entries: [entry],
                    createdAtIso: DateTime.now().toIso8601String(),
                  );
                  Navigator.of(context).pop(log);
                },
                child: Text(
                  existingLog != null
                      ? 'Guardar cambios de esta fecha'
                      : 'Guardar nuevo registro',
                ),
              ),
            ],
          );
        },
      );
    } finally {
      sessionNameController.dispose();
      exerciseNameController.dispose();
      setsController.dispose();
      repsController.dispose();
      loadController.dispose();
      rpeController.dispose();
    }

    if (result == null) {
      // Limpiar la selección al cancelar
      setState(() {
        _selectedSessionLogDate = null;
      });
      return;
    }
    final extra = Map<String, dynamic>.from(client.training.extra);
    final logs = readTrainingSessionLogs(
      extra[TrainingExtraKeys.trainingSessionLogRecords],
    );
    final updatedLogs = upsertTrainingSessionLogByDate(logs, result);
    extra[TrainingExtraKeys.trainingSessionLogRecords] = updatedLogs
        .map((log) => log.toJson())
        .toList();
    await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
      final merged = Map<String, dynamic>.from(prev.training.extra);
      merged[TrainingExtraKeys.trainingSessionLogRecords] = updatedLogs
          .map((log) => log.toJson())
          .toList();
      return prev.copyWith(training: prev.training.copyWith(extra: merged));
    });

    if (!parentContext.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      parentContext,
    ).showSnackBar(const SnackBar(content: Text('Sesion registrada.')));
  }

  List<int> _parseIntList(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((value) => int.tryParse(value.trim()) ?? 0)
        .where((value) => value > 0)
        .toList();
  }

  List<double> _parseDoubleList(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((value) => double.tryParse(value.trim()) ?? 0.0)
        .where((value) => value > 0)
        .toList();
  }

  List<int> _expandIntList(List<int> values, int sets) {
    if (values.isEmpty || sets <= 0) return const [];
    if (values.length >= sets) return values.sublist(0, sets);
    if (values.length == 1) {
      return List<int>.filled(sets, values.first);
    }
    return values;
  }

  List<double> _expandDoubleList(List<double> values, int sets) {
    if (values.isEmpty || sets <= 0) return const [];
    if (values.length >= sets) return values.sublist(0, sets);
    if (values.length == 1) {
      return List<double>.filled(sets, values.first);
    }
    return values;
  }

  Future<void> _deleteSelectedSessionLog(Client client) async {
    if (_selectedSessionLogDate == null) return;

    final targetDate = _selectedSessionLogDate!;
    final targetDateIso = DateFormat('yyyy-MM-dd').format(targetDate);

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      date: targetDate,
      recordType: 'Registro de Entrenamiento',
    );

    if (!confirmed || !mounted) return;

    try {
      final deletionService = ref.read(recordDeletionServiceProvider);
      await deletionService.deleteTrainingByDate(
        clientId: client.id,
        date: targetDate,
        onError: (e) {
          // Log error pero no bloquea UI (fire-and-forget)
          // ignore: avoid_print
          print('Error al borrar entrenamiento: $e');
        },
      );

      if (!mounted) return;

      final clientRef = client;
      // Limpiar registro localmente
      final extra = Map<String, dynamic>.from(clientRef.training.extra);
      final logs = readTrainingSessionLogs(
        extra[TrainingExtraKeys.trainingSessionLogRecords],
      );
      final filtered = logs
          .where((log) => log.dateIso != targetDateIso)
          .toList();

      extra[TrainingExtraKeys.trainingSessionLogRecords] = filtered
          .map((log) => log.toJson())
          .toList();

      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        final merged = Map<String, dynamic>.from(prev.training.extra);
        merged[TrainingExtraKeys.trainingSessionLogRecords] = filtered
            .map((log) => log.toJson())
            .toList();
        return prev.copyWith(training: prev.training.copyWith(extra: merged));
      });

      // Limpiar selección
      setState(() {
        _selectedSessionLogDate = null;
      });

      // Mostrar confirmación
      if (mounted) {
        showDeleteSuccessSnackbar(context, targetDate, 'Entrenamiento');
      }
    } catch (e) {
      if (mounted) {
        showDeleteErrorSnackbar(context, Exception('Error: $e'));
      }
    }
  }

  // ===================================================================
  // AUDIT PANEL
  // ===================================================================
  Widget _buildAuditPanel() {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      data: (state) {
        final extra = state.activeClient?.training.extra ?? {};

        // Leer datos de auditoría guardados
        final planConfigMap =
            extra[TrainingExtraKeys.trainingPlanConfig]
                as Map<String, dynamic>?;
        final traceRecords =
            extra[TrainingExtraKeys.decisionTraceRecords] as List?;
        final generatedAtIso =
            extra[TrainingExtraKeys.generatedAtIso] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auditoría del Motor (Fases 1-8)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Botón de exportación
            ElevatedButton.icon(
              onPressed: planConfigMap != null
                  ? () => _exportAuditJson(
                      planConfigMap,
                      traceRecords,
                      generatedAtIso,
                    )
                  : null,
              icon: const Icon(Icons.download),
              label: const Text('Exportar Auditoría JSON'),
            ),

            const SizedBox(height: 16),

            // Panel de auditoría (si hay data)
            if (planConfigMap != null)
              // Por ahora mostrar un resumen simple
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan Config ID: ${planConfigMap['id'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semanas: ${(planConfigMap['weeks'] as List?)?.length ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Items de DecisionTrace: ${traceRecords?.length ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generado: $generatedAtIso',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('Sin datos de auditoría disponibles'),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Future<void> _exportAuditJson(
    Map<String, dynamic> planConfig,
    List? traceRecords,
    String? generatedAtIso,
  ) async {
    try {
      // Crear JSON de auditoría
      final auditJson = {
        'exportedAtIso': DateTime.now().toIso8601String(),
        'generatedAtIso': generatedAtIso,
        'planConfig': planConfig,
        'decisionTrace': traceRecords ?? [],
      };

      // Mostrar SnackBar de éxito (en producción, aquí usarías FilePicker)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auditoría preparada para exportar (${(auditJson.toString().length / 1024).toStringAsFixed(2)} KB)',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Aquí iría la integración con file_picker para guardar en archivo
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exportando auditoría: $e')));
    }
  }
}

// ============================================================================
// DELEGATE PARA TABBAR STICKY (SOLO TabBar, sin contenido)
// ============================================================================
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _StickyTabBarDelegate({required this.tabController});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: kAppBarColor,
      child: TabBar(
        controller: tabController,
        tabs: const [
          Tab(text: 'Volumen'),
          Tab(text: 'Prioridad'),
          Tab(text: 'Intensidad'),
        ],
        labelColor: kPrimaryColor,
        unselectedLabelColor: kTextColorSecondary,
        indicatorColor: kPrimaryColor,
      ),
    );
  }

  @override
  double get maxExtent => 56; // Solo TabBar

  @override
  double get minExtent => 56; // Solo TabBar

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false; // TabBar es estático
  }
}
