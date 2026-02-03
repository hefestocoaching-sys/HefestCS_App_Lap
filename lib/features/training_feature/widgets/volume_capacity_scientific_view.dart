import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    // Debug: Verificar estado de extracción
    final capacityData = _extractCapacityData();
    final hasSnapshot = plan.trainingProfileSnapshot != null;
    final hasState = plan.state != null;
    final hasPhase2 = (plan.state as Map?)?.containsKey('phase2') ?? false;
    final musclesCount = capacityData.length;

    return HcsGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      style: TextStyle(
                        fontSize: 11,
                        color: kTextColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ✅ DEBUG INFO SIEMPRE VISIBLE
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: musclesCount > 0
                  ? Colors.green.withAlpha(30)
                  : Colors.red.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: musclesCount > 0
                    ? Colors.green.withAlpha(100)
                    : Colors.red.withAlpha(100),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      musclesCount > 0 ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: musclesCount > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      musclesCount > 0
                          ? '✅ DATOS EXTRAÍDOS CORRECTAMENTE'
                          : '❌ ERROR: SIN DATOS',
                      style: TextStyle(
                        fontSize: 10,
                        color: musclesCount > 0
                            ? Colors.green.withAlpha(255)
                            : Colors.red.withAlpha(255),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'plan.state exists: $hasState',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                Text(
                  'plan.state[phase2] exists: $hasPhase2',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                Text(
                  'Músculos extraídos: $musclesCount',
                  style: TextStyle(
                    fontSize: 9,
                    color: musclesCount > 0
                        ? Colors.green.withAlpha(200)
                        : Colors.red.withAlpha(200),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (musclesCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Músculos: ${capacityData.keys.take(5).join(", ")}${capacityData.length > 5 ? "..." : ""}',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withAlpha(150),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '💡 Revisa console para logs detallados (debugPrint)',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.amber.withAlpha(200),
                  ),
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
    // ✅ CORRECCIÓN: Motor V3 guarda en plan.state['phase2']['capacityByMuscle']
    debugPrint(
      '🔍 VolumeCapacityScientificView: Iniciando extracción de datos',
    );

    final state = plan.state as Map<String, dynamic>?;

    if (state == null) {
      debugPrint('❌ VolumeCapacityScientificView: plan.state is NULL');
      debugPrint('   plan.id: ${plan.id}');
      debugPrint('   plan.weeks.length: ${plan.weeks.length}');
      return {};
    }

    debugPrint('✅ plan.state exists, keys: ${state.keys.toList()}');

    final phase2 = state['phase2'] as Map<String, dynamic>?;

    if (phase2 == null) {
      debugPrint(
        '❌ VolumeCapacityScientificView: phase2 NOT FOUND in plan.state',
      );
      debugPrint('   Available state keys: ${state.keys.toList()}');
      return {};
    }

    debugPrint('✅ phase2 exists, keys: ${phase2.keys.toList()}');

    final capacityByMuscle =
        phase2['capacityByMuscle'] as Map<String, dynamic>?;

    if (capacityByMuscle == null || capacityByMuscle.isEmpty) {
      debugPrint(
        '❌ VolumeCapacityScientificView: capacityByMuscle is EMPTY or NULL',
      );
      debugPrint('   phase2 keys: ${phase2.keys.toList()}');
      return {};
    }

    debugPrint(
      '✅ capacityByMuscle found with ${capacityByMuscle.length} muscles',
    );

    // ✅ Convertir formato Motor V3 a formato esperado por widget
    final result = <String, dynamic>{};

    for (final entry in capacityByMuscle.entries) {
      final muscle = entry.key;
      final capacityData = entry.value as Map<String, dynamic>?;

      if (capacityData == null) {
        debugPrint('⚠️ Muscle $muscle has NULL capacity data');
        continue;
      }

      final mev = (capacityData['mev'] as num?)?.toInt() ?? 0;
      final mrv = (capacityData['mrv'] as num?)?.toInt() ?? 0;
      final mav = (capacityData['mav'] as num?)?.toInt() ?? 0;

      debugPrint('   Muscle $muscle: MEV=$mev, MAV=$mav, MRV=$mrv');

      // Solo incluir si tiene datos válidos
      if (mev > 0 || mrv > 0 || mav > 0) {
        // Obtener volumen actual desde phase3 si existe
        final currentVolume = _getCurrentVolume(muscle);

        result[muscle] = {
          'mev': mev,
          'mav': mav,
          'mrv': mrv,
          'current': currentVolume > 0 ? currentVolume : mav,
        };

        debugPrint('✅ Added $muscle to result (current: $currentVolume)');
      } else {
        debugPrint('⚠️ Muscle $muscle has INVALID data (all zeros)');
      }
    }

    debugPrint('✅ FINAL: Extracted ${result.length} muscles with valid data');
    debugPrint('   Muscles: ${result.keys.toList()}');

    return result;
  }

  int _getCurrentVolume(String muscle) {
    // Intentar obtener volumen target desde phase3
    final state = plan.state as Map<String, dynamic>?;
    if (state == null) {
      debugPrint('   _getCurrentVolume($muscle): state is null');
      return 0;
    }

    final phase3 = state['phase3'] as Map<String, dynamic>?;
    if (phase3 == null) {
      debugPrint('   _getCurrentVolume($muscle): phase3 not found');
      return 0;
    }

    final targetWeeklySetsByMuscle =
        phase3['targetWeeklySetsByMuscle'] as Map<String, dynamic>?;
    if (targetWeeklySetsByMuscle == null) {
      debugPrint(
        '   _getCurrentVolume($muscle): targetWeeklySetsByMuscle not found',
      );
      return 0;
    }

    final volume = targetWeeklySetsByMuscle[muscle] as num?;
    final currentVolume = volume?.toInt() ?? 0;

    if (currentVolume > 0) {
      debugPrint(
        '   ✅ Current volume for $muscle from phase3: $currentVolume sets',
      );
    } else {
      debugPrint('   ⚠️ No current volume for $muscle in phase3');
    }

    return currentVolume;
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
