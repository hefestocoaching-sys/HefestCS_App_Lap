import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

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
    debugPrint('🔍 [VolumeTab] build() llamado');
    debugPrint('   plan.state exists: ${plan.state != null}');

    if (plan.state == null) {
      debugPrint('❌ [VolumeTab] plan.state es NULL');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: plan.state es NULL'),
            SizedBox(height: 8),
            Text(
              'Regenera el plan Motor V3',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    debugPrint('   plan.state keys: ${plan.state!.keys.toList()}');

    if (!plan.state!.containsKey('phase3')) {
      debugPrint('❌ [VolumeTab] plan.state NO contiene "phase3"');
      debugPrint('   Claves disponibles: ${plan.state!.keys.toList()}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Error: plan.state sin "phase3"'),
            SizedBox(height: 8),
            Text(
              'Motor V3 no generó datos volumétricos',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final phase3 = plan.state!['phase3'];
    debugPrint('   plan.state[phase3] type: ${phase3.runtimeType}');

    if (phase3 is! Map) {
      debugPrint('❌ [VolumeTab] phase3 NO es Map, es: ${phase3.runtimeType}');
      return Center(child: Text('Error: phase3 no es Map'));
    }

    final phase3Map = phase3 as Map<String, dynamic>;

    if (!phase3Map.containsKey('capacityByMuscle')) {
      debugPrint('❌ [VolumeTab] phase3 NO contiene "capacityByMuscle"');
      debugPrint('   Claves en phase3: ${phase3Map.keys.toList()}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Error: phase3 sin "capacityByMuscle"'),
          ],
        ),
      );
    }

    final capacityByMuscle = phase3Map['capacityByMuscle'];
    debugPrint('   capacityByMuscle type: ${capacityByMuscle.runtimeType}');

    if (capacityByMuscle is! Map) {
      debugPrint('❌ [VolumeTab] capacityByMuscle NO es Map');
      return Center(child: Text('Error: capacityByMuscle no es Map'));
    }

    final capacityMap = capacityByMuscle as Map<String, dynamic>;
    debugPrint(
      '✅ [VolumeTab] Músculos encontrados: ${capacityMap.keys.toList()}',
    );
    debugPrint('   Total músculos: ${capacityMap.length}');

    if (capacityMap.isEmpty) {
      debugPrint('❌ [VolumeTab] capacityByMuscle está VACÍO');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: Sin datos volumétricos'),
            SizedBox(height: 8),
            Text(
              'capacityByMuscle está vacío',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RENDERIZAR TABLA MEV/MAV/MRV
    // ═══════════════════════════════════════════════════════════════════════

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capacidad Volumétrica por Músculo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Basado en landmarks MEV/MAV/MRV (Schoenfeld et al. 2017)',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),

          // TABLA
          Table(
            border: TableBorder.all(color: Colors.grey.shade700),
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              // HEADER
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade800),
                children: [
                  _tableCell('Músculo', isHeader: true),
                  _tableCell('MEV', isHeader: true),
                  _tableCell('MAV', isHeader: true),
                  _tableCell('MRV', isHeader: true),
                  _tableCell('Actual', isHeader: true),
                ],
              ),

              // ROWS
              ...capacityMap.entries.map((entry) {
                final muscleName = entry.key;
                final muscleData = entry.value as Map<String, dynamic>;

                final mev = muscleData['mev'] ?? 0;
                final mav = muscleData['mav'] ?? 0;
                final mrv = muscleData['mrv'] ?? 0;
                final actual = muscleData['recommendedStartVolume'] ?? 0;

                return TableRow(
                  children: [
                    _tableCell(_getMuscleDisplayName(muscleName)),
                    _tableCell('$mev'),
                    _tableCell('$mav'),
                    _tableCell('$mrv'),
                    _tableCell('$actual', isActual: true),
                  ],
                );
              }),
            ],
          ),

          SizedBox(height: 24),

          // LEYENDA
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leyenda:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  '• MEV: Minimum Effective Volume (mínimo para crecimiento)',
                ),
                Text('• MAV: Maximum Adaptive Volume (zona óptima)'),
                Text('• MRV: Maximum Recoverable Volume (límite superior)'),
                Text('• Actual: Volumen inicial recomendado por Motor V3'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isActual = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isActual ? Colors.green : Colors.white,
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
      'deltoide_anterior': 'Deltoides Anterior',
      'deltoide_lateral': 'Deltoides Lateral',
      'deltoide_posterior': 'Deltoides Posterior',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiotibiales',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'abs': 'Abdomen',
      // Legacy compatibility
      'back': 'Espalda',
      'shoulders': 'Hombros',
      'upper_traps': 'Trapecios',
      'back_mid_upper': 'Espalda Media',
    };

    return muscleNames[muscleKey] ?? muscleKey.toUpperCase();
  }
}
