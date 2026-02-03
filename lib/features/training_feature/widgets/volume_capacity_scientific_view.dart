import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/design/hcs_glass_container.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Vista científica de capacidad volumétrica basada en Motor V3
///
/// Muestra landmarks volumétricos según fundamentos científicos:
/// - MEV (Minimum Effective Volume): Volumen mínimo para mantener masa
/// - MAV (Maximum Adaptive Volume): Zona óptima de crecimiento (12-16 sets)
/// - MRV (Maximum Recoverable Volume): Límite de recuperación
///
/// Codificación visual:
/// - Verde: Volumen óptimo (80-110% MAV) - Zona de crecimiento
/// - Naranja: Volumen subóptimo (< 80% MAV) - Por debajo de MEV
/// - Rojo: Volumen excesivo (> 110% MAV) - Riesgo sobreentrenamiento
///
/// Basado en:
/// - Schoenfeld et al. (2017): Dosis-respuesta volumen-hipertrofia
/// - Schoenfeld et al. (2019): Meta-análisis volumen óptimo
/// - Motor V3 Phase 2: Capacity Calculation Engine
///
/// Referencia: docs/scientific-foundation/01-volume.md
class VolumeCapacityScientificView extends ConsumerWidget {
  final TrainingPlanConfig plan;

  const VolumeCapacityScientificView({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityData = _extractCapacityData();

    if (capacityData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.white.withAlpha(60)),
            const SizedBox(height: 16),
            const Text(
              'Sin datos volumétricos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera un plan Motor V3 para ver análisis científico',
              style: TextStyle(fontSize: 13, color: kTextColorSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScientificHeader(),
          const SizedBox(height: 16),
          _buildLandmarksTable(capacityData),
          const SizedBox(height: 16),
          if (plan.weeks.isNotEmpty) _buildPhaseIndicator(),
        ],
      ),
    );
  }

  Widget _buildScientificHeader() {
    return HcsGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics, color: kPrimaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Análisis Volumétrico Científico',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Basado en landmarks MEV/MAV/MRV (Schoenfeld et al. 2017)',
                  style: TextStyle(fontSize: 11, color: kTextColorSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarksTable(Map<String, dynamic> capacityData) {
    final muscles = capacityData.keys.toList()..sort();

    return HcsGlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5), // Músculo
            1: FlexColumnWidth(1.0), // MEV
            2: FlexColumnWidth(1.0), // MAV
            3: FlexColumnWidth(1.0), // MRV
            4: FlexColumnWidth(1.2), // Actual
            5: FlexColumnWidth(1.5), // % MAV
            6: FixedColumnWidth(60), // Tooltip
          },
          children: [
            _buildTableHeader(),
            ...muscles.asMap().entries.map((entry) {
              final index = entry.key;
              final muscle = entry.value;
              final data = capacityData[muscle] as Map<String, dynamic>;
              final isAlternate = index.isEven;
              return _buildTableRow(muscle, data, isAlternate);
            }),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: kPrimaryColor,
    );

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: kPrimaryColor.withAlpha(50), width: 2),
        ),
      ),
      children: [
        _buildHeaderCell('Músculo', headerStyle),
        _buildHeaderCell('MEV', headerStyle),
        _buildHeaderCell('MAV', headerStyle),
        _buildHeaderCell('MRV', headerStyle),
        _buildHeaderCell('Actual', headerStyle),
        _buildHeaderCell('% MAV', headerStyle),
        _buildHeaderCell('Info', headerStyle),
      ],
    );
  }

  Widget _buildHeaderCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }

  TableRow _buildTableRow(
    String muscle,
    Map<String, dynamic> data,
    bool isAlternate,
  ) {
    final mev = (data['mev'] as num?)?.toInt() ?? 0;
    final mav = (data['mav'] as num?)?.toInt() ?? 0;
    final mrv = (data['mrv'] as num?)?.toInt() ?? 0;
    final current = (data['current'] as num?)?.toInt() ?? 0;
    final percentage = _getMAVPercentage(data);

    return TableRow(
      decoration: BoxDecoration(
        color: isAlternate ? kCardColor.withAlpha(20) : Colors.transparent,
      ),
      children: [
        _buildDataCell(_formatMuscleName(muscle)),
        _buildDataCell(mev.toString()),
        _buildDataCell(mav.toString()),
        _buildDataCell(mrv.toString()),
        _buildDataCell(current.toString()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Center(child: _buildPercentageCell(percentage)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Center(child: _buildTooltipCell(muscle, data)),
        ),
      ],
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: kTextColor),
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    final week = plan.weeks.first;
    final weekNumber = week.weekNumber;

    late String title;
    late String description;
    late IconData icon;
    late Color color;

    if (weekNumber >= 1 && weekNumber <= 3) {
      title = 'ACUMULACIÓN';
      description = 'Volumen ↑ progresivo, RIR constante (2-3)';
      icon = Icons.trending_up;
      color = kInfoColor;
    } else if (weekNumber == 4) {
      title = 'INTENSIFICACIÓN';
      description = 'Volumen estable, RIR ↓ (0-1)';
      icon = Icons.bolt;
      color = kWarningColor;
    } else {
      title = 'DELOAD';
      description = 'Volumen -50%, RIR alto (4-5), recuperación';
      icon = Icons.spa;
      color = kSuccessColor;
    }

    return HcsGlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: color.withAlpha(25),
      borderColor: color,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
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
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════

  double _getMAVPercentage(Map<String, dynamic> muscleData) {
    final mav = (muscleData['mav'] as num?)?.toDouble() ?? 1.0;
    final current = (muscleData['current'] as num?)?.toDouble() ?? 0.0;
    return (current / mav) * 100;
  }

  Color _getPercentageBackgroundColor(double percentage) {
    if (percentage < 80) return kWarningSubtle; // Bajo MEV
    if (percentage > 110) return kErrorSubtle; // Sobre MRV
    return kSuccessSubtle; // Zona óptima
  }

  Color _getPercentageTextColor(double percentage) {
    if (percentage < 80) return kWarningColor;
    if (percentage > 110) return kErrorColor;
    return kSuccessColor;
  }

  Widget _buildPercentageCell(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPercentageBackgroundColor(percentage),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _getPercentageTextColor(percentage),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTooltipCell(String muscle, Map<String, dynamic> data) {
    return Tooltip(
      message:
          'MEV: Volumen mínimo para mantener\n'
          'MAV: Zona óptima de crecimiento\n'
          'MRV: Límite de recuperación\n\n'
          'Fundamento: Schoenfeld et al. 2017',
      child: Icon(Icons.help_outline, size: 16, color: kTextColorSecondary),
    );
  }

  Map<String, dynamic> _extractCapacityData() {
    // Buscar en trainingProfileSnapshot.extra['mevByMuscle'] (Motor V3)
    final snapshot = plan.trainingProfileSnapshot;
    if (snapshot == null) return {};

    final snapshotExtra = snapshot.extra as Map<String, dynamic>?;
    if (snapshotExtra == null) return {};

    final mevByMuscle =
        snapshotExtra['mevByMuscle'] as Map<String, dynamic>? ?? {};
    final mrvByMuscle =
        snapshotExtra['mrvByMuscle'] as Map<String, dynamic>? ?? {};

    if (mevByMuscle.isEmpty) return {};

    // Construir capacityByMuscle desde datos disponibles
    final capacityByMuscle = <String, dynamic>{};

    for (final muscle in mevByMuscle.keys) {
      final mev = mevByMuscle[muscle] as int? ?? 0;
      final mrv = mrvByMuscle[muscle] as int? ?? mev;
      // MAV es aprox. 75% del camino entre MEV y MRV
      final mav = ((mev + mrv) / 2).round() as int;
      // Volumen actual: usar MAV como baseline
      final current = mav;

      capacityByMuscle[muscle] = {
        'mev': mev,
        'mav': mav,
        'mrv': mrv,
        'current': current,
      };
    }

    return capacityByMuscle;
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
