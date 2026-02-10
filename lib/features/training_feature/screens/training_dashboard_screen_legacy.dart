// ignore_for_file: deprecated_member_use_from_same_package, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hcs_app_lap/data/datasources/local/exercise_catalog_loader.dart'; // No usado
// import 'package:hcs_app_lap/domain/entities/exercise.dart'; // No usado
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
import 'package:hcs_app_lap/features/training_feature/widgets/ml_outcome_feedback_dialog.dart';
// import 'package:hcs_app_lap/features/training_feature/widgets/training_plan_generator_v3_button.dart'; // Eliminado - Motor V3 legacy

// NUEVO: Import Motor V3
import 'package:hcs_app_lap/presentation/screens/training/motor_v3_dashboard_screen.dart';

// Widgets visuales
import '../widgets/volume_range_muscle_table.dart';
import '../widgets/volume_capacity_scientific_view.dart';
import '../widgets/series_distribution_editor.dart';
import '../widgets/weekly_progress_tracker.dart';
import '../widgets/macrocycle_overview_tab.dart';
import '../widgets/weekly_plan_detail_view.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
      appBar: clientsAsync.when(
        data: (state) {
          final client = state.activeClient;
          if (client == null) return null;

          return AppBar(
            title: const Text('Entrenamiento'),
            backgroundColor: kAppBarColor,
            actions: [
              // ═══════════════════════════════════════════
              // NUEVO: BOTÓN MOTOR V3
              // ═══════════════════════════════════════════
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MotorV3DashboardScreen(userId: client.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text('Motor V3'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 2,
                      ),
                    ),
                    // Badge "NUEVO"
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'NUEVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => null,
        error: (e, s) => null,
      ),
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
        // TAREA A5 PARTE 1: Botón de generación Motor V3
        Container(
          color: kAppBarColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildGeneratePlanSection(),
        ),
        // TabBar fija en la parte superior
        Container(
          color: kAppBarColor,
          child: TabBar(
            controller: _tabController!,
            tabs: const [
              Tab(text: 'Volumen'),
              Tab(text: 'Distribución'),
              Tab(text: 'Progreso'),
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
                // Tab 1: Volumen Motor V3
                Consumer(
                  builder: (context, ref, _) {
                    final clientsAsync = ref.watch(clientsProvider);

                    return clientsAsync.when(
                      data: (state) {
                        final client = state.activeClient;
                        if (client == null) {
                          return Center(
                            child: Text(
                              'No hay cliente activo',
                              style: TextStyle(color: kTextColorSecondary),
                            ),
                          );
                        }

                        // Obtener plan activo (Motor V3)
                        final activePlanId =
                            client.training.extra[TrainingExtraKeys
                                    .activePlanId]
                                as String?;

                        if (activePlanId == null) {
                          return _buildNoPlanState(
                            title: 'Sin plan Motor V3',
                            message:
                                'Genera un plan científico para ver análisis volumétrico\nbasado en MEV/MAV/MRV',
                          );
                        }

                        // Buscar plan en client.trainingPlans
                        final plan = client.trainingPlans
                            .cast<TrainingPlanConfig?>()
                            .firstWhere(
                              (p) => p?.id == activePlanId,
                              orElse: () => null,
                            );

                        if (plan == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: kErrorColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Plan no encontrado',
                                  style: TextStyle(
                                    color: kTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ID: $activePlanId',
                                  style: const TextStyle(
                                    color: kTextColorSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // ✅ Vista científica Motor V3
                        return VolumeCapacityScientificView(plan: plan);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: kErrorColor,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error al cargar datos volumétricos',
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
                    );
                  },
                ),
                // Tab 2: Distribución (Heavy / Medium / Light)
                SeriesDistributionEditor(
                  trainingExtra: effectiveExtra,
                  onDistributionChanged: (distribution) {
                    _handleDistributionChanged(distribution);
                  },
                ),
                // Tab 3: Progreso Semanal
                WeeklyProgressTracker(trainingExtra: effectiveExtra),
                // Tab 4: Macrociclo por músculo (AA/HF) sin dependencia de días
                MacrocycleOverviewTab(trainingExtra: effectiveExtra),
                // Tab 5: Plan semanal Motor V3
                Consumer(
                  builder: (context, ref, _) {
                    final clientsAsync = ref.watch(clientsProvider);

                    return clientsAsync.when(
                      data: (state) {
                        final client = state.activeClient;
                        if (client == null) {
                          return Center(
                            child: Text(
                              'No hay cliente activo',
                              style: TextStyle(color: kTextColorSecondary),
                            ),
                          );
                        }

                        // Obtener plan activo desde client.training.extra
                        final activePlanId =
                            client.training.extra[TrainingExtraKeys
                                    .activePlanId]
                                as String?;

                        if (activePlanId == null) {
                          return _buildEmptyPlanState();
                        }

                        // Buscar plan en client.trainingPlans
                        final plan = client.trainingPlans
                            .cast<TrainingPlanConfig?>()
                            .firstWhere(
                              (p) => p?.id == activePlanId,
                              orElse: () => null,
                            );

                        if (plan == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: kErrorColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Plan no encontrado',
                                  style: TextStyle(
                                    color: kTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ID: $activePlanId',
                                  style: const TextStyle(
                                    color: kTextColorSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // ✅ Mostrar plan semana a semana
                        return WeeklyPlanDetailView(plan: plan);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: kErrorColor,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error al cargar plan',
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

  Widget _buildEmptyPlanState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.white.withAlpha(60),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay plan activo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Genera un plan con Motor V3 para verlo aquí',
            style: TextStyle(fontSize: 13, color: kTextColorSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final now = DateTime.now();
                await ref
                    .read(trainingPlanProvider.notifier)
                    .generatePlanFromActiveCycle(now);
                if (!mounted) return;
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Motor V3 en desarrollo: $e'),
                    backgroundColor: kWarningColor,
                  ),
                );
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar Plan Motor V3'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanState({required String title, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.white.withAlpha(60)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: kTextColorSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final now = DateTime.now();
                await ref
                    .read(trainingPlanProvider.notifier)
                    .generatePlanFromActiveCycle(now);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Plan Motor V3 generado correctamente'),
                    backgroundColor: kSuccessColor,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al generar plan: $e'),
                    backgroundColor: kErrorColor,
                  ),
                );
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar Plan Motor V3'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratePlanSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: false,
        backgroundColor: kCardColor.withValues(alpha: 0.5),
        collapsedBackgroundColor: kCardColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: kPrimaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Generar Plan de Entrenamiento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.science, color: Color(0xFF00D9FF), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Motor V3 Científico',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Basado en 151 referencias científicas',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '✓ VME/MAV/MRV (Israetel 2020)\n'
                        '✓ Distribución 35/45/20 (Schoenfeld 2021)\n'
                        '✓ RIR Óptimo (Helms 2018)\n'
                        '✓ ML Híbrido (70% reglas + 30% ML)',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Botón para abrir Motor V3
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usa el botón "Motor V3" en el AppBar'),
                        backgroundColor: Color(0xFF00D9FF),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Ver botón "Motor V3" arriba ↑'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPlanGenerated() {
    // Callback cuando plan V3 es generado exitosamente
    setState(() {
      // Refresh UI
    });

    // ✅ Navegar a tab Semanal para ver plan generado
    if (_tabController != null) {
      _tabController!.animateTo(3); // Tab Semanal
    }

    // ✅ Mostrar snackbar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Plan generado. Revisa la pestaña "Semanal"'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onGeneratePlanLegacy() async {
    final now = DateTime.now();
    await ref
        .read(trainingPlanProvider.notifier)
        .generatePlanFromActiveCycle(now);
    if (mounted && _tabController != null) {
      _tabController!.animateTo(3);
    }
  }

  Future<void> _handleDistributionChanged(Map<String, int> distribution) async {
    await ref.read(clientsProvider.notifier).updateActiveClient((client) {
      final updatedExtra = Map<String, dynamic>.from(client.training.extra);
      updatedExtra[TrainingExtraKeys.seriesTypePercentSplit] = distribution;

      final updatedProfile = client.training.copyWith(extra: updatedExtra);
      return client.copyWith(training: updatedProfile);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Distribución actualizada: ${distribution['heavy']}% pesadas, ${distribution['medium']}% medias, ${distribution['light']}% ligeras',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMLFeedbackDialog(String mlExampleId, String clientId) {
    showDialog(
      context: context,
      builder: (context) =>
          MLOutcomeFeedbackDialog(mlExampleId: mlExampleId, clientId: clientId),
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGeneratePlanSection(),
                // Aquí va contenido pre-TabBar si es necesario
              ],
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
              SeriesDistributionEditor(
                trainingExtra: trainingExtra,
                onDistributionChanged: (distribution) {
                  _handleDistributionChanged(distribution);
                },
              ),
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
          debugPrint('Error al borrar entrenamiento: $e');
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
