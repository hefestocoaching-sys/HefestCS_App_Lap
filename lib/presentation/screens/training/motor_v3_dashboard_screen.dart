// lib/presentation/screens/training/motor_v3_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/presentation/providers/domain/training_providers.dart';
import 'package:hcs_app_lap/presentation/widgets/core/hcs_card.dart';
import 'package:hcs_app_lap/presentation/widgets/core/hcs_section.dart';
import 'package:hcs_app_lap/presentation/widgets/feedback/hcs_loading.dart';
import 'package:hcs_app_lap/presentation/widgets/feedback/hcs_error.dart';
import 'package:hcs_app_lap/presentation/widgets/cards/stat_card.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';

/// Dashboard principal del Motor V3
class MotorV3DashboardScreen extends ConsumerStatefulWidget {
  final String userId;

  const MotorV3DashboardScreen({super.key, required this.userId});

  @override
  ConsumerState<MotorV3DashboardScreen> createState() =>
      _MotorV3DashboardScreenState();
}

class _MotorV3DashboardScreenState extends ConsumerState<MotorV3DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(programGenerationStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Motor V3 - Programa Científico'),
        backgroundColor: const Color(0xFF1A1F2E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00D9FF),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.analytics), text: 'Volumen'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Sesiones'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progresión'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Timeline'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Métricas'),
            Tab(icon: Icon(Icons.description), text: 'Logs'),
            Tab(icon: Icon(Icons.tune), text: 'Ajustes'),
          ],
        ),
      ),
      body: _buildBody(generationState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateProgram(context),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generar Programa'),
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(ProgramGenerationState state) {
    if (state.isLoading) {
      return HcsLoading.fullScreen(
        message:
            'Generando programa científico...\n\n'
            'Aplicando VME/MAV/MRV, distribución 35/45/20, RIR óptimo...',
      );
    }

    if (state.error != null) {
      return HcsError(
        message: state.error!,
        onRetry: () => _generateProgram(context),
        fullScreen: true,
      );
    }

    if (state.result == null) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(state.result!),
        _buildVolumeTab(state.result!),
        _buildSessionsTab(state.result!),
        _buildProgressionTab(state.result!),
        _buildTimelineTab(state.result!),
        _buildMetricsTab(state.result!),
        _buildLogsTab(state.result!),
        _buildAdjustmentsTab(state.result!),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            const Text(
              'Motor V3 - Sistema Científico',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera un programa basado en 7 semanas de investigación científica',
              style: TextStyle(fontSize: 14, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '✓ VME/MAV/MRV landmarks (Israetel 2020)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '✓ Distribución 35/45/20 (Schoenfeld 2021)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '✓ RIR óptimo (Helms 2018)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '✓ Frecuencia 2x (Grgic 2018)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Presiona el botón flotante para comenzar',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 1: OVERVIEW
  // ═══════════════════════════════════════════════════

  Widget _buildOverviewTab(Map<String, dynamic> result) {
    final program = result['program'] as TrainingProgram?;

    if (program == null) {
      return const Center(
        child: Text(
          'No se pudo cargar el programa',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final totalVolume = program.weeklyVolumeByMuscle.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del programa
          HcsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF00D9FF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${program.split.type} • ${program.phase} • ${program.durationWeeks} semanas',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.white12),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgramStat(
                        'Inicio',
                        '${program.startDate.day}/${program.startDate.month}/${program.startDate.year}',
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgramStat(
                        'Fin',
                        '${program.estimatedEndDate.day}/${program.estimatedEndDate.month}/${program.estimatedEndDate.year}',
                        Icons.event,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Volumen Total',
                  value: '${totalVolume.round()} sets',
                  subtitle: '${program.weeklyVolumeByMuscle.length} músculos',
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Frecuencia',
                  value: '${program.split.daysPerWeek}x',
                  subtitle: 'días por semana',
                  icon: Icons.calendar_month,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quality score (si existe)
          if (result['scientific']?['quality_score'] != null)
            HcsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quality Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: result['scientific']['quality_score'] as double,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00D9FF),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((result['scientific']['quality_score'] as double) * 100).toStringAsFixed(0)}% - ${_getQualityLabel(result['scientific']['quality_score'] as double)}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Warnings (si existen)
          if (result['scientific']?['warnings'] != null &&
              (result['scientific']['warnings'] as List).isNotEmpty)
            HcsSection(
              title: 'Advertencias',
              icon: Icons.warning,
              child: HcsCard(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (result['scientific']['warnings'] as List)
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  w.toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgramStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D9FF), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getQualityLabel(double score) {
    if (score >= 0.9) return 'Excelente';
    if (score >= 0.75) return 'Bueno';
    if (score >= 0.6) return 'Aceptable';
    return 'Mejorable';
  }

  // ═══════════════════════════════════════════════════
  // OTROS TABS (PLACEHOLDERS)
  // ═══════════════════════════════════════════════════

  Widget _buildVolumeTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Análisis de Volumen',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'VME/MAV/MRV por músculo - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Sesiones Detalladas',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Programa día a día - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Progresión 52 Semanas',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Timeline anual - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Calendario Interactivo',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Historial y planificación - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Métricas y Validaciones',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Quality scores - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Bitácora de Entrenamientos',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Registros de sesiones - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsTab(Map<String, dynamic> result) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Autoregulación',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Ajustes automáticos - Próximamente',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════

  Future<void> _generateProgram(BuildContext context) async {
    // Usuario demo para testing
    final userProfile = UserProfile(
      id: widget.userId,
      name: 'Carlos Rodríguez',
      email: 'carlos@example.com',
      age: 28,
      gender: 'male',
      heightCm: 178,
      weightKg: 82,
      trainingLevel: 'intermediate',
      yearsTraining: 3,
      availableDays: 4,
      sessionDuration: 90,
      primaryGoal: 'hypertrophy',
      musclePriorities: {
        'chest': 5,
        'back': 5,
        'quads': 4,
        'hamstrings': 3,
        'shoulders': 4,
        'biceps': 3,
        'triceps': 3,
        'calves': 2,
        'abs': 2,
      },
      injuryHistory: {},
      availableEquipment: [
        'barbell',
        'dumbbell',
        'machine',
        'cable',
        'bench',
        'rack',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await generateProgramV3(
      ref: ref,
      userProfile: userProfile,
      phase: 'accumulation',
      durationWeeks: 4,
      useML: true,
    );
  }
}
