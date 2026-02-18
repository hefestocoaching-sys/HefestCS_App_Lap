import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

/// Vista de volumen semanal basada en Motor V3
///
/// Muestra el volumen real de sets por músculo calculado por Motor V3.
/// Los datos provienen directamente de TrainingPlanConfig.volumePerMuscle.
///
/// Codificación visual por fase:
/// - Accumulation: Color primario (acumulación de volumen)
/// - Intensification: Warning (intensificación progresiva)
/// - Deload: Neutral (descarga activa)
///
/// Basado en:
/// - Schoenfeld et al. (2017): Dosis-respuesta volumen-hipertrofia
/// - Motor V3: Volume Engine con landmarks MEV/MAV/MRV
///
/// Versión: 2.0.0 - Sin dependencias legacy phase3
class VolumeCapacityScientificView extends ConsumerWidget {
  final TrainingPlanConfig plan;

  const VolumeCapacityScientificView({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🔍 [VolumeTab] build() - Motor V3');
    debugPrint('   volumePerMuscle: ${plan.volumePerMuscle}');
    debugPrint('   state keys: ${plan.state?.keys.toList()}');

    // Validación de datos Motor V3
    if (plan.volumePerMuscle == null || plan.volumePerMuscle!.isEmpty) {
      debugPrint('❌ [VolumeTab] volumePerMuscle vacío o null');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Sin datos de volumen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este plan no contiene datos de volumen del Motor V3.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Genera un nuevo plan para ver la distribución volumétrica.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final volumePerMuscle = plan.volumePerMuscle!;
    final phase = plan.state?['phase']?.toString() ?? 'accumulation';
    final split = plan.state?['split']?.toString() ?? 'upperLower';
    final weeks = plan.state?['duration_weeks'] as int? ?? 4;

    debugPrint('✅ [VolumeTab] Renderizando ${volumePerMuscle.length} músculos');
    debugPrint('   Fase: $phase, Split: $split, Semanas: $weeks');

    // ═══════════════════════════════════════════════════════════════════════
    // RENDERIZAR VOLUMEN MOTOR V3
    // ═══════════════════════════════════════════════════════════════════════

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          const Text(
            'Volumen Semanal por Músculo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Motor V3 - Volumen calculado según fase y split',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 16),

          // METADATA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metadataItem(
                  'Fase',
                  _getPhaseName(phase),
                  _getPhaseColor(phase),
                ),
                _metadataItem('Split', _getSplitName(split), Colors.blue),
                _metadataItem('Duración', '$weeks sem', Colors.grey[400]!),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TABLA
          Table(
            border: TableBorder.all(color: Colors.grey.shade700),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            children: [
              // HEADER
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade800),
                children: [
                  _tableCell('Músculo', isHeader: true),
                  _tableCell('Sets/semana', isHeader: true),
                  _tableCell('Fase', isHeader: true),
                ],
              ),

              // ROWS
              ...volumePerMuscle.entries.map((entry) {
                final muscleName = entry.key;
                final weeklyVolume = entry.value;

                return TableRow(
                  children: [
                    _tableCell(_getMuscleDisplayName(muscleName)),
                    _tableCell(
                      '$weeklyVolume sets',
                      isVolume: true,
                      volumeValue: weeklyVolume,
                    ),
                    _tableCell(
                      _getPhaseBadge(phase),
                      phaseColor: _getPhaseColor(phase),
                    ),
                  ],
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // LEYENDA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Sets/semana: Volumen total calculado por Motor V3',
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
                Text(
                  '• Fase: Determina intensidad y distribución RIR',
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
                Text(
                  '• Split: Determina agrupación de músculos por sesión',
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
                const SizedBox(height: 12),
                Text(
                  'Basado en: Volume Engine (MEV/MAV/MRV landmarks)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isVolume = false,
    int? volumeValue,
    Color? phaseColor,
  }) {
    Color textColor = Colors.white;

    if (isVolume && volumeValue != null) {
      // Codificación por volumen (verde = óptimo)
      if (volumeValue >= 6 && volumeValue <= 24) {
        textColor = Colors.green;
      } else if (volumeValue < 6) {
        textColor = Colors.orange;
      } else {
        textColor = Colors.amber; // High volume risk
      }
    } else if (phaseColor != null) {
      textColor = phaseColor;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : textColor,
          fontSize: isHeader ? 14 : 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getMuscleDisplayName(String muscleKey) {
    const muscleNames = {
      'chest': 'Pecho',
      'lats': 'Dorsales',
      'upper_back': 'Espalda Alta',
      'traps': 'Trapecios',
      'deltoide_anterior': 'Deltoides Ant.',
      'deltoide_lateral': 'Deltoides Lat.',
      'deltoide_posterior': 'Deltoides Post.',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquios',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'abs': 'Abdomen',
    };

    return muscleNames[muscleKey] ?? muscleKey.toUpperCase();
  }

  String _getPhaseName(String phase) {
    const phaseNames = {
      'accumulation': 'Acumulación',
      'intensification': 'Intensificación',
      'deload': 'Descarga',
    };
    return phaseNames[phase] ?? phase;
  }

  String _getPhaseBadge(String phase) {
    const badges = {
      'accumulation': '🔵 Acum',
      'intensification': '🟠 Intens',
      'deload': '⚪ Desc',
    };
    return badges[phase] ?? phase;
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'accumulation':
        return Colors.blue;
      case 'intensification':
        return Colors.orange;
      case 'deload':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  String _getSplitName(String split) {
    const splitNames = {
      'upperLower': 'Torso/Pierna',
      'fullBody': 'Cuerpo Completo',
      'pushPullLegs': 'Push/Pull/Pierna',
    };
    return splitNames[split] ?? split;
  }
}
