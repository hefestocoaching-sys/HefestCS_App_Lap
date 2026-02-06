// ignore_for_file: deprecated_member_use_from_same_package, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
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
/// 6. Intensidad: Distribución Heavy/Moderate/Light (02-intensity.md)
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 9, // 9 tabs Motor V3 (1 entrevista + 8 tabs)
      vsync: this,
      initialIndex: 0,
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

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: clientsAsync.when(
        data: (_) => _buildAppBar(clientsAsync),
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

          // ✅ ACT-001: SSOT - Plan activo por activePlanId (con fallback a más reciente)
          if (client.trainingPlans.isEmpty) {
            debugPrint('❌ TrainingDashboard: No hay planes Motor V3');
            return _buildNoPlanState(client);
          }

          final plans = client.trainingPlans;
          TrainingPlanConfig? plan;

          // 1) Intentar usar activePlanId (SSOT)
          final activePlanId =
              client.training.extra[TrainingExtraKeys.activePlanId] as String?;

          if (activePlanId != null) {
            try {
              plan = plans.firstWhere((p) => p.id == activePlanId);
              debugPrint(
                '✅ TrainingDashboard: Plan activo encontrado por activePlanId',
              );
            } on StateError {
              debugPrint(
                '⚠️ TrainingDashboard: activePlanId no coincide con ningún plan, usando fallback',
              );
            }
          }

          // 2) Fallback: plan más reciente por startDate
          plan ??=
              (plans.toList()
                    ..sort((a, b) => b.startDate.compareTo(a.startDate)))
                  .first;

          debugPrint('✅ TrainingDashboard: Renderizando plan Motor V3:');
          debugPrint('   ID: ${plan.id}');
          debugPrint('   Inicio: ${plan.startDate}');
          debugPrint('   Semanas: ${plan.weeks.length}');
          debugPrint(
            '   Fuente: ${activePlanId != null ? "activePlanId (SSOT)" : "fallback (más reciente)"}',
          );

          // ✅ activePlanId es SSOT del plan activo (post FASE B)
          // ✅ Usar plan.id directamente (ya tenemos objeto completo)
          // ✅ RENDERIZAR TABS MOTOR V3
          return _buildMotorV3Workspace(plan, client);
        },
        loading: () => Center(
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
              Icon(Icons.error_outline, size: 64, color: kErrorColor),
              SizedBox(height: 16),
              Text(
                'Error al cargar entrenamiento',
                style: TextStyle(color: kTextColor, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: kTextColorSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AsyncValue clientsAsync) {
    final clientName =
        clientsAsync.value?.activeClient?.profile.fullName ?? 'Sin cliente';
    final planDate = DateTime.now();

    return AppBar(
      backgroundColor: kAppBarColor,
      elevation: 0,
      title: Column(
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
            'Cliente: $clientName • ${DateFormat('dd/MM/yyyy').format(planDate)}',
            style: TextStyle(
              fontSize: 11,
              color: kTextColorSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: kPrimaryColor),
          tooltip: 'Regenerar plan',
          onPressed: () => _regenerarPlan(),
        ),
        IconButton(
          icon: Icon(Icons.download, color: kPrimaryColor),
          tooltip: 'Exportar PDF',
          onPressed: () => _exportarPDF(),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _buildLoadingAppBar() {
    return AppBar(
      backgroundColor: kAppBarColor,
      elevation: 0,
      title: Column(
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
      title: Column(
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
      icon: Icon(Icons.auto_awesome),
      label: Text('Generar Plan Motor V3'),
      backgroundColor: Color(0xFF00D9FF),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildMotorV3Workspace(TrainingPlanConfig plan, dynamic client) {
    // Verificar si hay plan activo
    final activePlanId =
        client.training.extra[TrainingExtraKeys.activePlanId] as String?;
    final hasPlan = activePlanId != null && activePlanId.isNotEmpty;

    return Column(
      children: [
        // Header con acciones (arriba de tabs)
        Container(
          color: kAppBarColor,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Generar (solo si NO hay plan activo)
              if (!hasPlan)
                ElevatedButton.icon(
                  onPressed: () => _generarPlan(),
                  icon: Icon(Icons.auto_awesome, size: 18),
                  label: Text('Generar Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00D9FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              if (hasPlan) ...[
                // Regenerar
                ElevatedButton.icon(
                  onPressed: () => _regenerarPlan(),
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Regenerar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                // Adaptar
                ElevatedButton.icon(
                  onPressed: () => _adaptarPlan(),
                  icon: Icon(Icons.tune, size: 18),
                  label: Text('Adaptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
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
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                _buildDecisionsTab(plan),
                // Tab 8: Monitoreo (placeholder)
                _buildMonitoringTab(plan),
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: kPrimaryColor,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kTextColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${plan.splitId} • ${plan.microcycleLengthInWeeks} semanas',
                              style: TextStyle(
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
                      SizedBox(width: 16),
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
          SizedBox(height: 24),
          // Stats
          Text(
            'Resumen Ejecutivo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 12),
          Card(
            color: kCardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programa científico basado en:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildBulletPoint('Volumen: MEV/MAV/MRV (Israetel 2020)'),
                  _buildBulletPoint(
                    'Distribución: 25/50/25 Heavy/Moderate/Light',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.white.withAlpha(60),
          ),
          SizedBox(height: 16),
          Text(
            'Catálogo de Ejercicios',
            style: TextStyle(fontSize: 18, color: kTextColorSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Selección científica Motor V3 - Próximamente',
            style: TextStyle(fontSize: 12, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionTab(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.white.withAlpha(60)),
          SizedBox(height: 16),
          Text(
            'Periodización 52 Semanas',
            style: TextStyle(fontSize: 18, color: kTextColorSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Timeline de progresión - Próximamente',
            style: TextStyle(fontSize: 12, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionsTab(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.white.withAlpha(60)),
          SizedBox(height: 16),
          Text(
            'Decisiones Científicas',
            style: TextStyle(fontSize: 18, color: kTextColorSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Trazabilidad Motor V3 - Próximamente',
            style: TextStyle(fontSize: 12, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab(TrainingPlanConfig plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.white.withAlpha(60)),
          SizedBox(height: 16),
          Text(
            'Monitoreo y Ajustes',
            style: TextStyle(fontSize: 18, color: kTextColorSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Adherencia y métricas - Próximamente',
            style: TextStyle(fontSize: 12, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  // EMPTY STATES

  Widget _buildNoClientState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.white.withAlpha(60)),
          SizedBox(height: 24),
          Text(
            'No hay cliente activo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
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
            color: Color(0xFF00D9FF).withAlpha(150),
          ),
          SizedBox(height: 24),
          Text(
            'Sin plan Motor V3 activo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Genera un plan científico basado en 7 fundamentos',
            style: TextStyle(fontSize: 13, color: kTextColorSecondary),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _generarPlan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00D9FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('Generar Plan Motor V3'),
              ],
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
          Icon(Icons.error_outline, size: 80, color: kErrorColor),
          SizedBox(height: 24),
          Text(
            'Plan no encontrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ID: $planId',
            style: TextStyle(
              fontSize: 11,
              color: kTextColorSecondary,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _generarPlan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Row(
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
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: kTextColorSecondary),
            ),
            Text(
              value,
              style: TextStyle(
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
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: kPrimaryColor, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: kTextColor),
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
      await ref
          .read(trainingPlanProvider.notifier)
          .generatePlanFromActiveCycle(now);

      // ✅ ACT-001: El provider ya actualiza activePlanId internamente
      // No duplicar escritura aquí (UI solo consume, no decide)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        title: Text('Regenerar Plan'),
        content: Text('¿Regenerar plan completo Motor V3?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generarPlan();
            },
            child: Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  void _exportarPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando a PDF...'),
        backgroundColor: kPrimaryColor,
      ),
    );
    // TODO: Implementar exportación
  }

  Future<void> _adaptarPlan() async {
    try {
      final now = DateTime.now();
      await ref
          .read(trainingPlanProvider.notifier)
          .generatePlanFromActiveCycle(now);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
}
