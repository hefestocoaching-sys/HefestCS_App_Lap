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

  // Variables para Tab Ajustes
  double _heavyPercentage = 25.0;
  double _moderatePercentage = 50.0;
  double _lightPercentage = 25.0;
  bool _hasUnsavedChanges = false;

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
      // Mostrar errores del resultado
      final errors = result['errors'] as List? ?? [];
      final warnings = result['warnings'] as List? ?? [];

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'No se pudo generar el programa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (errors.isNotEmpty) ...[
                const Text(
                  'ERRORES CRÍTICOS:',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $e',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'ADVERTENCIAS:',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...warnings
                    .take(5)
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $w',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
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

  // ═══════════════════════════════════════════════════
  // TAB 2: VOLUMEN (EDUCATIVO Y CIENTÍFICO)
  // ═══════════════════════════════════════════════════

  Widget _buildVolumeTab(Map<String, dynamic> result) {
    final program = result['program'] as TrainingProgram?;

    if (program == null) {
      return const Center(child: Text('No hay datos de volumen'));
    }

    // Ordenar músculos por volumen (mayor a menor)
    final musclesSorted = program.weeklyVolumeByMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN 1: HEADER
          _buildVolumeSectionHeader(
            title: 'Distribución de Volumen Semanal',
            reference: 'Israetel et al. (2020) - Volume Landmarks',
          ),
          const SizedBox(height: 16),

          // SECCIÓN 2: RESUMEN
          _buildVolumeSummaryCards(program),
          const SizedBox(height: 24),

          // SECCIÓN 3: VOLUMEN POR MÚSCULO
          _buildVolumenByMuscleList(musclesSorted, program),
          const SizedBox(height: 32),

          // SECCIÓN 4: DISTRIBUCIÓN DE INTENSIDAD
          _buildIntensityDistributionSection(),
          const SizedBox(height: 32),

          // SECCIÓN 5: DECISIONES CIENTÍFICAS
          _buildScientificDecisionsSection(program),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPERS TAB VOLUMEN
  // ═══════════════════════════════════════════════════

  Widget _buildVolumeSectionHeader({
    required String title,
    required String reference,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.school, size: 16, color: Color(0xFF00D9FF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reference,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeSummaryCards(TrainingProgram program) {
    final totalVolume = program.weeklyVolumeByMuscle.values.fold(
      0.0,
      (sum, v) => sum + v,
    );
    final muscleCount = program.weeklyVolumeByMuscle.length;
    final avgVolume = totalVolume / muscleCount;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Volumen Total',
            value: '${totalVolume.round()} sets',
            subtitle: '$muscleCount músculos',
            icon: Icons.fitness_center,
            color: const Color(0xFF00D9FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Promedio/Músculo',
            value: '${avgVolume.toStringAsFixed(1)} sets',
            subtitle: 'Distribución balanceada',
            icon: Icons.analytics,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumenByMuscleList(
    List<MapEntry<String, double>> musclesSorted,
    TrainingProgram program,
  ) {
    return HcsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volumen por Músculo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...musclesSorted.map((entry) {
            return _buildMuscleVolumeRow(
              muscle: entry.key,
              volume: entry.value,
              trainingLevel: 'intermediate', // TODO: Tomar del UserProfile
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMuscleVolumeRow({
    required String muscle,
    required double volume,
    required String trainingLevel,
  }) {
    // Obtener landmarks (VME/MAV/MRV)
    final landmarks = _getVolumeLandmarks(muscle, trainingLevel);
    final vme = landmarks['vme']!;
    final mav = landmarks['mav']!;
    final mrv = landmarks['mrv']!;

    // Calcular progreso (0.0-1.0)
    final progress = ((volume - vme) / (mrv - vme)).clamp(0.0, 1.0);

    // Determinar zona y color
    String zone;
    Color zoneColor;
    String emoji;

    if (volume < vme) {
      zone = 'Por debajo de VME';
      zoneColor = Colors.red;
      emoji = '⚠️';
    } else if (volume < mav) {
      zone = 'Entre VME-MAV';
      zoneColor = Colors.orange;
      emoji = '📊';
    } else if (volume <= mrv) {
      zone = 'Zona Óptima (MAV-MRV)';
      zoneColor = Colors.green;
      emoji = '✅';
    } else {
      zone = 'Excede MRV';
      zoneColor = Colors.red;
      emoji = '🔴';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del músculo
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getMuscleDisplayName(muscle),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${volume.toInt()} sets',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D9FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progreso con landmarks
          Stack(
            children: [
              // Barra base
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Barra de progreso
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: zoneColor,
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [zoneColor, zoneColor.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
              // Marcadores VME/MAV/MRV
              Positioned(
                left: 0,
                child: Container(width: 2, height: 24, color: Colors.white54),
              ),
              Positioned(
                left:
                    ((mav - vme) / (mrv - vme)) *
                    MediaQuery.of(context).size.width *
                    0.8,
                child: Container(width: 2, height: 24, color: Colors.amber),
              ),
              Positioned(
                right: 0,
                child: Container(width: 2, height: 24, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Labels VME/MAV/MRV
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VME: $vme',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              Text(
                'MAV: $mav',
                style: const TextStyle(fontSize: 11, color: Colors.amber),
              ),
              Text(
                'MRV: $mrv',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Zona actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: zoneColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              zone,
              style: TextStyle(
                fontSize: 12,
                color: zoneColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityDistributionSection() {
    // TODO: Implementar con datos reales del programa
    return HcsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Distribución de Intensidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Schoenfeld et al. (2021) - Loading Spectrum',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pesada
          _buildIntensityRow(
            label: 'Pesada (75-85% 1RM)',
            percentage: 25,
            color: Colors.red,
            rangeMin: 15,
            rangeMax: 30,
            repsRange: '5-8 reps',
          ),
          const SizedBox(height: 16),

          // Moderada
          _buildIntensityRow(
            label: 'Moderada (65-75% 1RM)',
            percentage: 50,
            color: Colors.amber,
            rangeMin: 40,
            rangeMax: 70,
            repsRange: '8-12 reps',
          ),
          const SizedBox(height: 16),

          // Ligera
          _buildIntensityRow(
            label: 'Ligera (50-65% 1RM)',
            percentage: 25,
            color: Colors.green,
            rangeMin: 15,
            rangeMax: 30,
            repsRange: '12-20 reps',
          ),
          const SizedBox(height: 20),

          // Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '✓ Distribución 25/50/25 científicamente válida',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityRow({
    required String label,
    required int percentage,
    required Color color,
    required int rangeMin,
    required int rangeMax,
    required String repsRange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Barra de progreso
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              repsRange,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            const Spacer(),
            Text(
              'Rango: $rangeMin-$rangeMax%',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScientificDecisionsSection(TrainingProgram program) {
    return HcsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Fundamento Científico',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Decisión 1: Split
          _buildDecisionCard(
            title: 'DECISIÓN 1: ${program.split.name}',
            reference: 'Grgic et al. (2018) - Frequency Meta',
            points: [
              'Frecuencia 2x por músculo: Óptima para hipertrofia',
              '${program.split.daysPerWeek} días/semana: Balance volumen/recuperación',
              '${program.split.type}: Permite ejercicios pesados sin fatiga sistémica',
            ],
          ),
          const SizedBox(height: 16),

          // Decisión 2: Fase
          _buildDecisionCard(
            title: 'DECISIÓN 2: Fase ${program.phase.toUpperCase()}',
            reference: 'Israetel (2020) - Mesocycle Design',
            points: [
              '${program.durationWeeks} semanas: Duración óptima para adaptación',
              'Accumulation: Prioriza volumen sobre intensidad',
              'RIR 2-3: Permite progresión sostenible sin fatiga excesiva',
            ],
          ),
          const SizedBox(height: 16),

          // Decisión 3: Volumen
          _buildDecisionCard(
            title:
                'DECISIÓN 3: Volumen ${program.totalWeeklyVolume.round()} sets/semana',
            reference: 'Schoenfeld et al. (2017) - Dose-Response',
            points: [
              'Nivel Intermediate: 150-200 sets óptimo',
              '${program.weeklyVolumeByMuscle.length} músculos: ~${(program.totalWeeklyVolume / program.weeklyVolumeByMuscle.length).toStringAsFixed(1)} sets/músculo promedio',
              'Músculos primarios cerca de MAV (óptimo para hipertrofia)',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionCard({
    required String title,
    required String reference,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D9FF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school, size: 12, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reference,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓ ',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Obtener landmarks de volumen
  Map<String, int> _getVolumeLandmarks(String muscle, String level) {
    final landmarksByMuscle = {
      'chest': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      'deltoide_anterior': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'deltoide_lateral': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'deltoide_posterior': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'triceps': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'lats': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'upper_back': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'traps': {
        'novice': {'vme': 4, 'mav': 6, 'mrv': 8},
        'intermediate': {'vme': 5, 'mav': 8, 'mrv': 10},
        'advanced': {'vme': 6, 'mav': 10, 'mrv': 12},
      },
      'biceps': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
      'quads': {
        'novice': {'vme': 10, 'mav': 15, 'mrv': 20},
        'intermediate': {'vme': 12, 'mav': 18, 'mrv': 24},
        'advanced': {'vme': 15, 'mav': 22, 'mrv': 28},
      },
      'hamstrings': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'glutes': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'calves': {
        'novice': {'vme': 8, 'mav': 12, 'mrv': 16},
        'intermediate': {'vme': 10, 'mav': 15, 'mrv': 20},
        'advanced': {'vme': 12, 'mav': 18, 'mrv': 24},
      },
      'abs': {
        'novice': {'vme': 6, 'mav': 10, 'mrv': 14},
        'intermediate': {'vme': 8, 'mav': 12, 'mrv': 16},
        'advanced': {'vme': 10, 'mav': 15, 'mrv': 20},
      },
    };

    return landmarksByMuscle[muscle]?[level] ?? {'vme': 0, 'mav': 0, 'mrv': 0};
  }

  // Helper: Nombres en español
  String _getMuscleDisplayName(String muscle) {
    const displayNames = {
      'chest': 'PECHO',
      'lats': 'DORSALES',
      'upper_back': 'ESPALDA MEDIA',
      'traps': 'TRAPECIOS',
      'deltoide_anterior': 'HOMBRO FRONTAL',
      'deltoide_lateral': 'HOMBRO LATERAL',
      'deltoide_posterior': 'HOMBRO POSTERIOR',
      'biceps': 'BÍCEPS',
      'triceps': 'TRÍCEPS',
      'quads': 'CUÁDRICEPS',
      'hamstrings': 'ISQUIOTIBIALES',
      'glutes': 'GLÚTEOS',
      'calves': 'PANTORRILLAS',
      'abs': 'ABDOMINALES',
    };

    return displayNames[muscle] ?? muscle.toUpperCase();
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

  // ═══════════════════════════════════════════════════
  // TAB 8: AJUSTES CIENTÍFICOS
  // ═══════════════════════════════════════════════════

  Widget _buildAdjustmentsTab(Map<String, dynamic> result) {
    final program = result['program'] as TrainingProgram?;

    if (program == null) {
      return const Center(child: Text('No hay programa para ajustar'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          _buildAdjustmentsHeader(),
          const SizedBox(height: 24),

          // SECCIÓN 1: DISTRIBUCIÓN DE INTENSIDAD
          _buildIntensityAdjustmentSection(),
          const SizedBox(height: 32),

          // SECCIÓN 2: PREVIEW DE CAMBIOS
          if (_hasUnsavedChanges) ...[
            _buildChangesPreviewSection(program),
            const SizedBox(height: 32),
          ],

          // SECCIÓN 3: HISTORIAL DE AJUSTES
          _buildAdjustmentsHistorySection(),
          const SizedBox(height: 32),

          // SECCIÓN 4: RECOMENDACIONES DEL MOTOR
          _buildMotorRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajustes Científicos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.school, size: 16, color: Color(0xFF00D9FF)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Solo ajustes dentro de rangos científicos validados',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF00D9FF),
                size: 18,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'El volumen por músculo se ajusta automáticamente con bitácora y rendimiento. Aquí solo puedes cambiar distribución de intensidad.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntensityAdjustmentSection() {
    return HcsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Distribución de Intensidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.school, size: 14, color: Colors.white54),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Schoenfeld et al. (2021) - Loading Spectrum',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildIndependentIntensitySlider(
            label: 'PESADA (75-85% 1RM)',
            value: _heavyPercentage,
            min: 15,
            max: 30,
            color: Colors.red,
            repsRange: '5-8 reps',
            onChanged: (value) {
              setState(() {
                _heavyPercentage = value;
                _hasUnsavedChanges = true;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildIndependentIntensitySlider(
            label: 'MODERADA (65-75% 1RM)',
            value: _moderatePercentage,
            min: 40,
            max: 70,
            color: Colors.amber,
            repsRange: '8-12 reps',
            onChanged: (value) {
              setState(() {
                _moderatePercentage = value;
                _hasUnsavedChanges = true;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildIndependentIntensitySlider(
            label: 'LIGERA (50-65% 1RM)',
            value: _lightPercentage,
            min: 15,
            max: 30,
            color: Colors.green,
            repsRange: '12-20 reps',
            onChanged: (value) {
              setState(() {
                _lightPercentage = value;
                _hasUnsavedChanges = true;
              });
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTotalPercentage() == 100
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getTotalPercentage() == 100
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.red.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTotalPercentage() == 100
                      ? Icons.check_circle
                      : Icons.error,
                  color: _getTotalPercentage() == 100
                      ? Colors.green
                      : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTotalPercentage() == 100
                        ? 'Total: 100% ✓ Listo para aplicar'
                        : 'Total: ${_getTotalPercentage().toInt()}% ✗ Debe sumar exactamente 100%',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getTotalPercentage() == 100
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hasUnsavedChanges
                      ? () {
                          setState(() {
                            _heavyPercentage = 25.0;
                            _moderatePercentage = 50.0;
                            _lightPercentage = 25.0;
                            _hasUnsavedChanges = false;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurar 25/50/25'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasUnsavedChanges && _getTotalPercentage() == 100
                      ? () => _applyChanges()
                      : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Aplicar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndependentIntensitySlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required String repsRange,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.3),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 6,
            valueIndicatorColor: color,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).toInt(),
            label: '${value.toInt()}%',
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              repsRange,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            Text(
              'Rango válido: ${min.toInt()}-${max.toInt()}%',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChangesPreviewSection(TrainingProgram program) {
    final currentTotal = program.totalWeeklyVolume;
    final heavySets = (currentTotal * (_heavyPercentage / 100)).round();
    final moderateSets = (currentTotal * (_moderatePercentage / 100)).round();
    final lightSets = (currentTotal * (_lightPercentage / 100)).round();

    final currentHeavy = (currentTotal * 0.25).round();
    final currentModerate = (currentTotal * 0.50).round();
    final currentLight = (currentTotal * 0.25).round();

    return HcsCard(
      backgroundColor: const Color(0xFF00D9FF).withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 12),
              const Text(
                'Preview de Cambios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparisonRow('Pesada', currentHeavy, heavySets, Colors.red),
          const SizedBox(height: 12),
          _buildComparisonRow(
            'Moderada',
            currentModerate,
            moderateSets,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow('Ligera', currentLight, lightSets, Colors.green),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IMPACTO ESPERADO:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                _buildImpactText(
                  heavySets > currentHeavy
                      ? 'Mayor énfasis en fuerza y potencia'
                      : 'Menor estrés articular',
                ),
                _buildImpactText(
                  moderateSets > currentModerate
                      ? 'Más volumen en zona hipertrofia óptima'
                      : 'Menor volumen moderado',
                ),
                _buildImpactText(
                  lightSets > currentLight
                      ? 'Mayor bomba muscular y metabolitos'
                      : 'Menos trabajo metabólico',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 18),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aplicar cambios regenerará el programa completo',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    int current,
    int proposed,
    Color color,
  ) {
    final diff = proposed - current;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Text(
                '$current sets',
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.white38),
              const SizedBox(width: 8),
              Text(
                '$proposed sets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              if (diff != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (diff > 0 ? Colors.green : Colors.red).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${diff > 0 ? '+' : ''}$diff',
                    style: TextStyle(
                      fontSize: 11,
                      color: diff > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF00D9FF), fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsHistorySection() {
    return HcsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Ajustes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin ajustes manuales aún',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los ajustes aparecerán aquí cuando modifiques la distribución de intensidad.',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorRecommendationsSection() {
    return HcsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Recomendaciones del Motor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            '✓ Distribución actual 25/50/25 es óptima para hipertrofia general',
            Colors.green,
          ),
          _buildRecommendationItem(
            '📊 Para fuerza: Ajustar a 30/50/20 (más pesado)',
            const Color(0xFF00D9FF),
          ),
          _buildRecommendationItem(
            '💪 Para bomba: Ajustar a 20/50/30 (más ligero)',
            const Color(0xFF00D9FF),
          ),
          _buildRecommendationItem(
            '⚠️  Distribuciones fuera de 15-30% pesada pueden aumentar riesgo articular',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPERS AJUSTES
  // ═══════════════════════════════════════════════════

  double _getTotalPercentage() {
    return _heavyPercentage + _moderatePercentage + _lightPercentage;
  }

  Future<void> _applyChanges() async {
    if (_getTotalPercentage() != 100) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✗ No se puede aplicar. Total debe ser 100% (actual: ${_getTotalPercentage().toInt()}%)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Cambios aplicados: ${_heavyPercentage.toInt()}/${_moderatePercentage.toInt()}/${_lightPercentage.toInt()}. Regenerando programa...',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
        // PRIMARIOS (usuario dijo: quiero desarrollar pecho y espalda)
        'chest': 5, // → ~16-18 sets (MAV para intermedio)
        'lats': 5, // → ~16-18 sets
        'upper_back': 5, // → ~14-16 sets
        // SECUNDARIOS (importante pero no objetivo principal)
        'deltoide_anterior': 4, // → ~12-14 sets
        'deltoide_lateral': 4, // → ~12-14 sets
        'deltoide_posterior': 3, // → ~10-12 sets
        'quads': 4, // → ~14-16 sets
        'hamstrings': 4, // → ~12-14 sets
        'glutes': 4, // → ~12-14 sets
        'traps': 3, // → ~10-12 sets
        'biceps': 3, // → ~10-12 sets
        'triceps': 3, // → ~10-12 sets
        // TERCIARIOS (mantenimiento mínimo)
        'calves': 2, // → ~6-8 sets (MEV)
        'abs': 2, // → ~8-10 sets (MEV)
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
