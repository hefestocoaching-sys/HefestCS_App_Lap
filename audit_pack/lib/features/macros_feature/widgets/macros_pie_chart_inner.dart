import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MacrosPieChartInner extends StatelessWidget {
  final double proteinKcal;
  final double fatKcal;
  final double carbKcal;
  final double targetKcal;
  final int? touchedIndex;

  const MacrosPieChartInner({
    super.key,
    required this.proteinKcal,
    required this.fatKcal,
    required this.carbKcal,
    required this.targetKcal,
    this.touchedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final total = (proteinKcal + fatKcal + carbKcal).clamp(1, double.infinity);
    final p = proteinKcal / total * 100.0;
    final f = fatKcal / total * 100.0;
    final c = carbKcal / total * 100.0;

    final sections = <PieChartSectionData>[
      _s(0, p, Colors.redAccent),
      _s(1, f, Colors.amber.shade600),
      _s(2, c, Colors.greenAccent.shade400),
    ];

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 0,
        centerSpaceRadius: 56,
        startDegreeOffset: -90,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(enabled: false),
      ),
    );
  }

  PieChartSectionData _s(int i, double value, Color color) {
    final isT = touchedIndex == i;
    return PieChartSectionData(
      value: value,
      color: color,
      radius: isT ? 72 : 64,
      title: '',
    );
  }
}
