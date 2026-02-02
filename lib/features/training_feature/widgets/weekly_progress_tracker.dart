import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';

/// Modelo de datos para una semana de progreso
class WeekProgress {
  final int weekNumber;
  final int sets;
  final String status; // 'progress', 'plateau', 'overreaching', 'deload'
  final double? rpe; // Rating of Perceived Exertion (1-10)
  final double? rir; // Reps in Reserve (0-5)
  final String? notes;

  const WeekProgress({
    required this.weekNumber,
    required this.sets,
    required this.status,
    this.rpe,
    this.rir,
    this.notes,
  });

  Color get statusColor {
    switch (status) {
      case 'progress':
        return Colors.green;
      case 'plateau':
        return Colors.orange;
      case 'overreaching':
        return Colors.red;
      case 'deload':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'progress':
        return Icons.trending_up;
      case 'plateau':
        return Icons.trending_flat;
      case 'overreaching':
        return Icons.warning;
      case 'deload':
        return Icons.restore;
      default:
        return Icons.help_outline;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'progress':
        return 'Progreso';
      case 'plateau':
        return 'Meseta';
      case 'overreaching':
        return 'Sobrecarga';
      case 'deload':
        return 'Descarga';
      default:
        return 'Desconocido';
    }
  }
}

/// Widget que muestra el progreso semanal de volumen por músculo
/// con análisis de respuesta del cliente (progreso/plateau/overreaching)
class WeeklyProgressTracker extends StatefulWidget {
  final Map<String, dynamic> trainingExtra;

  const WeeklyProgressTracker({super.key, required this.trainingExtra});

  @override
  State<WeeklyProgressTracker> createState() => _WeeklyProgressTrackerState();
}

class _WeeklyProgressTrackerState extends State<WeeklyProgressTracker> {
  String _selectedMuscle = 'chest';
  int _weeksToShow = 12; // Mostrar últimas 12 semanas por defecto

  @override
  Widget build(BuildContext context) {
    final availableMuscles = _getAvailableMuscles();

    if (availableMuscles.isEmpty) {
      return _buildEmptyState();
    }

    // Asegurar que músculo seleccionado existe
    if (!availableMuscles.contains(_selectedMuscle)) {
      _selectedMuscle = availableMuscles.first;
    }

    final weeklyData = _getWeeklyDataForMuscle(_selectedMuscle);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMuscleSelector(availableMuscles),
          const SizedBox(height: 24),
          _buildWeeksSelector(),
          const SizedBox(height: 24),
          if (weeklyData.isEmpty)
            _buildNoDataForMuscle()
          else ...[
            _buildSummaryCards(weeklyData),
            const SizedBox(height: 24),
            _buildProgressChart(weeklyData),
            const SizedBox(height: 24),
            _buildWeeklyTimeline(weeklyData),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: kPrimaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso Semanal de Volumen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Seguimiento semana a semana por grupo muscular',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAppBarColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kPrimaryColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta tabla muestra cómo respondió el cliente al volumen programado. '
                    'Verde = progreso, Naranja = meseta, Rojo = sobrecarga, Azul = descarga.',
                    style: TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 11,
                      height: 1.4,
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

  Widget _buildMuscleSelector(List<String> muscles) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Grupo Muscular',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: muscles.map((muscle) {
              final isSelected = muscle == _selectedMuscle;
              return FilterChip(
                selected: isSelected,
                label: Text(_formatMuscleName(muscle)),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedMuscle = muscle);
                  }
                },
                selectedColor: kPrimaryColor.withValues(alpha: 0.3),
                checkmarkColor: kPrimaryColor,
                backgroundColor: kAppBarColor.withValues(alpha: 0.5),
                labelStyle: TextStyle(
                  color: isSelected ? kPrimaryColor : kTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeksSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text(
            'Mostrar últimas:',
            style: TextStyle(color: kTextColor, fontSize: 13),
          ),
          const SizedBox(width: 12),
          _weekButton(8),
          const SizedBox(width: 8),
          _weekButton(12),
          const SizedBox(width: 8),
          _weekButton(26),
          const SizedBox(width: 8),
          _weekButton(52),
        ],
      ),
    );
  }

  Widget _weekButton(int weeks) {
    final isSelected = _weeksToShow == weeks;
    return OutlinedButton(
      onPressed: () => setState(() => _weeksToShow = weeks),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? kPrimaryColor.withValues(alpha: 0.2)
            : null,
        side: BorderSide(
          color: isSelected
              ? kPrimaryColor
              : kPrimaryColor.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        '$weeks sem',
        style: TextStyle(
          color: isSelected ? kPrimaryColor : kTextColor,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<WeekProgress> weeklyData) {
    final progressWeeks = weeklyData
        .where((w) => w.status == 'progress')
        .length;
    final plateauWeeks = weeklyData.where((w) => w.status == 'plateau').length;
    final overreachingWeeks = weeklyData
        .where((w) => w.status == 'overreaching')
        .length;
    final avgSets =
        weeklyData.map((w) => w.sets).reduce((a, b) => a + b) /
        weeklyData.length;
    final avgRPE =
        weeklyData.where((w) => w.rpe != null).map((w) => w.rpe!).isNotEmpty
        ? weeklyData
                  .where((w) => w.rpe != null)
                  .map((w) => w.rpe!)
                  .reduce((a, b) => a + b) /
              weeklyData.where((w) => w.rpe != null).length
        : null;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Semanas Progresando',
            '$progressWeeks',
            Colors.green,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Semanas en Meseta',
            '$plateauWeeks',
            Colors.orange,
            Icons.trending_flat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Sobrecarga',
            '$overreachingWeeks',
            Colors.red,
            Icons.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Promedio Series',
            avgSets.toStringAsFixed(1),
            kPrimaryColor,
            Icons.bar_chart,
          ),
        ),
        if (avgRPE != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              'RPE Promedio',
              avgRPE.toStringAsFixed(1),
              Colors.purple,
              Icons.fitness_center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(List<WeekProgress> weeklyData) {
    final displayData = weeklyData.take(_weeksToShow).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Gráfica de Volumen Semanal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: _buildSimpleChart(displayData)),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<WeekProgress> data) {
    if (data.isEmpty) return const SizedBox();

    final maxSets = data.map((w) => w.sets).reduce((a, b) => a > b ? a : b);
    final minSets = data.map((w) => w.sets).reduce((a, b) => a < b ? a : b);
    final range = maxSets - minSets;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final barWidth = (width / data.length) - 8;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((week) {
            final normalizedHeight = range > 0
                ? ((week.sets - minSets) / range) * (height - 40) + 20
                : height / 2;

            return Tooltip(
              message:
                  'Semana ${week.weekNumber}\n${week.sets} series\n${week.statusLabel}',
              child: Container(
                width: barWidth,
                height: normalizedHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      week.statusColor,
                      week.statusColor.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  border: Border.all(color: week.statusColor, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${week.sets}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'S${week.weekNumber}',
                        style: TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWeeklyTimeline(List<WeekProgress> weeklyData) {
    final displayData = weeklyData.take(_weeksToShow).toList();

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.timeline, color: kPrimaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Detalle Semana por Semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayData.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: kPrimaryColor.withValues(alpha: 0.1)),
            itemBuilder: (context, index) {
              final week = displayData[index];
              return _buildWeekRow(week);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(WeekProgress week) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Semana
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'S${week.weekNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Series
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: week.statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: week.statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${week.sets} sets',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: week.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: week.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: week.statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(week.statusIcon, size: 16, color: week.statusColor),
                const SizedBox(width: 6),
                Text(
                  week.statusLabel,
                  style: TextStyle(
                    color: week.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // RPE/RIR
          if (week.rpe != null || week.rir != null)
            Expanded(
              child: Row(
                children: [
                  if (week.rpe != null) ...[
                    _buildMetricChip(
                      'RPE',
                      week.rpe!.toStringAsFixed(1),
                      Colors.purple,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (week.rir != null)
                    _buildMetricChip(
                      'RIR',
                      week.rir!.toStringAsFixed(1),
                      Colors.teal,
                    ),
                ],
              ),
            )
          else
            const Expanded(
              child: Text(
                'Sin datos de esfuerzo',
                style: TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Notas
          if (week.notes != null && week.notes!.isNotEmpty)
            Tooltip(
              message: week.notes!,
              child: const Icon(Icons.note, size: 16, color: kPrimaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 64,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin datos de progreso',
              style: TextStyle(
                color: kTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera un plan y registra sesiones desde la app del cliente\npara ver el progreso semana a semana',
              style: TextStyle(color: kTextColorSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataForMuscle() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos para ${_formatMuscleName(_selectedMuscle)}',
              style: const TextStyle(
                color: kTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aún no hay registros de entrenamiento para este músculo',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  List<String> _getAvailableMuscles() {
    final volumeHistory =
        widget.trainingExtra[TrainingExtraKeys.weeklyVolumeHistory] as Map?;
    if (volumeHistory == null) return [];

    return volumeHistory.keys.whereType<String>().toList()..sort();
  }

  List<WeekProgress> _getWeeklyDataForMuscle(String muscle) {
    final volumeHistory =
        widget.trainingExtra[TrainingExtraKeys.weeklyVolumeHistory] as Map?;
    if (volumeHistory == null) return [];

    final muscleData = volumeHistory[muscle] as List?;
    if (muscleData == null) return [];

    final List<WeekProgress> weeks = [];

    for (int i = 0; i < muscleData.length; i++) {
      final weekData = muscleData[i];
      if (weekData is! Map) continue;

      final sets = (weekData['sets'] as num?)?.toInt() ?? 0;
      final status = weekData['status']?.toString() ?? 'progress';
      final rpe = (weekData['rpe'] as num?)?.toDouble();
      final rir = (weekData['rir'] as num?)?.toDouble();
      final notes = weekData['notes']?.toString();

      weeks.add(
        WeekProgress(
          weekNumber: i + 1,
          sets: sets,
          status: status,
          rpe: rpe,
          rir: rir,
          notes: notes,
        ),
      );
    }

    return weeks.reversed.toList(); // Más reciente primero
  }

  String _formatMuscleName(String muscle) {
    final names = {
      'chest': 'Pecho',
      'lats': 'Dorsales',
      'midBack': 'Espalda Media',
      'lowBack': 'Lumbar',
      'traps': 'Trapecios',
      'frontDelts': 'Hombro Frontal',
      'sideDelts': 'Hombro Lateral',
      'rearDelts': 'Hombro Posterior',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiosurales',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'abs': 'Abdominales',
    };
    return names[muscle.toLowerCase()] ?? muscle;
  }
}
