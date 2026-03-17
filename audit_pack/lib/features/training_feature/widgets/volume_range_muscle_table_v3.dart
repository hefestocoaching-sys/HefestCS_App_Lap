import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training/models/supported_muscles.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Motor V3 - Tabla de volumen semanal por músculo
///
/// VERSIÓN 2.0.0 - Sin dependencias legacy
///
/// Fuente ÚNICA: plan.volumePerMuscle (Map&lt;String, int&gt;)
/// No usa: state['phase2'], state['phase3'], extra
///
/// Renderiza:
/// - Músculo (capitalizado)
/// - Sets semanales
/// - Fase (desde plan.phase)
/// - Color según rango óptimo (12-20 sets)
class VolumeRangeMuscleTableV3 extends StatelessWidget {
  final TrainingPlanConfig plan;

  const VolumeRangeMuscleTableV3({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [VolumeRangeMuscleTableV3] build()');

    // Validación de datos
    if (plan.volumePerMuscle == null || plan.volumePerMuscle!.isEmpty) {
      debugPrint('❌ [VolumeRangeMuscleTableV3] volumePerMuscle vacío');
      return _buildNoDataState();
    }

    final volumePerMuscle = plan.volumePerMuscle!;
    final phaseName = plan.phase.name;

    debugPrint(
      '✅ [VolumeRangeMuscleTableV3] Renderizando ${volumePerMuscle.length} músculos',
    );
    debugPrint('   Fase: $phaseName');

    // Ordenar alfabéticamente
    final sortedMuscles = volumePerMuscle.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          const Text(
            'Volumen Semanal por Músculo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Motor V3 - Volumen calculado según fase $phaseName',
            style: const TextStyle(fontSize: 12, color: kTextColorSecondary),
          ),
          const SizedBox(height: 16),

          // TABLA
          Table(
            border: TableBorder.all(color: Colors.grey.shade700),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(),
            },
            children: [
              // HEADER ROW
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade800),
                children: [
                  _buildHeaderCell('Músculo'),
                  _buildHeaderCell('Sets/Semana'),
                  _buildHeaderCell('Zona'),
                ],
              ),

              // DATA ROWS
              ...sortedMuscles.map((entry) {
                final muscleName = entry.key;
                final weeklyVolume = entry.value;
                final zone = _getVolumeZone(weeklyVolume);

                return TableRow(
                  children: [
                    _buildDataCell(_getMuscleName(muscleName)),
                    _buildDataCell(
                      '$weeklyVolume sets',
                      color: _getVolumeColor(weeklyVolume),
                    ),
                    _buildDataCell(zone, color: _getZoneColor(zone)),
                  ],
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // LEYENDA
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Volumen no disponible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Este plan no contiene datos de volumen Motor V3.',
              style: TextStyle(fontSize: 12, color: kTextColorSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zonas de volumen (basadas en MEV/MAV/MRV):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Óptimo', Colors.green, '6-24 sets'),
              const SizedBox(width: 24),
              _buildLegendItem('Bajo', Colors.orange, '<6 sets'),
              const SizedBox(width: 24),
              _buildLegendItem('Alto', Colors.amber, '>24 sets'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Volumen generado por Motor V3 (VolumeEngine)',
            style: TextStyle(fontSize: 11, color: kTextColorSecondary),
          ),
          const Text(
            '• Respeta landmarks MEV/MAV/MRV científicos',
            style: TextStyle(fontSize: 11, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($range)',
          style: const TextStyle(fontSize: 11, color: kTextColorSecondary),
        ),
      ],
    );
  }

  /// Determina la zona según volumen semanal
  String _getVolumeZone(int sets) {
    if (sets < 6) return 'Bajo';
    if (sets > 24) return 'Alto';
    return 'Óptimo';
  }

  /// Color del volumen numérico
  Color _getVolumeColor(int sets) {
    if (sets < 6) return Colors.orange; // Sub-maintenance
    if (sets > 24) return Colors.amber; // Junk volume risk
    return Colors.green;
  }

  /// Color de la zona
  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'Óptimo':
        return Colors.green;
      case 'Bajo':
        return Colors.orange;
      case 'Alto':
        return Colors.amber;
      default:
        return Colors.white;
    }
  }

  /// Obtiene nombre legible del músculo (usando SSOT)
  String _getMuscleName(String key) {
    return SupportedMuscles.getDisplayLabel(key);
  }
}
