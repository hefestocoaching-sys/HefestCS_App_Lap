import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:hcs_app_lap/utils/theme.dart';

class MacrosPieChartOuter extends StatefulWidget {
  final double proteinKcal;
  final double fatKcal;
  final double carbKcal;
  final double targetKcal;

  final double proteinGPerKg;
  final double fatGPerKg;
  final double carbGPerKg;

  final String proteinPng;
  final String fatPng;
  final String carbsPng;

  const MacrosPieChartOuter({
    super.key,
    required this.proteinKcal,
    required this.fatKcal,
    required this.carbKcal,
    required this.targetKcal,
    required this.proteinGPerKg,
    required this.fatGPerKg,
    required this.carbGPerKg,
    required this.proteinPng,
    required this.fatPng,
    required this.carbsPng,
  });

  @override
  State<MacrosPieChartOuter> createState() => _MacrosPieChartOuterState();
}

class _MacrosPieChartOuterState extends State<MacrosPieChartOuter> {
  int touchedIndex = -1;

  static const _colors = <Color>[
    Color(0xFF4FC3F7), // protein
    Color(0xFFFFC107), // fat
    Color(0xFF81C784), // carbs
  ];

  @override
  Widget build(BuildContext context) {
    final total = (widget.proteinKcal + widget.fatKcal + widget.carbKcal).clamp(
      1,
      double.infinity,
    );

    final data = [
      _Slice(
        label: 'Proteína',
        kcal: widget.proteinKcal,
        grams: widget.proteinGPerKg,
        asset: widget.proteinPng,
        color: _colors[0],
      ),
      _Slice(
        label: 'Grasa',
        kcal: widget.fatKcal,
        grams: widget.fatGPerKg,
        asset: widget.fatPng,
        color: _colors[1],
      ),
      _Slice(
        label: 'Carbohidratos',
        kcal: widget.carbKcal,
        grams: widget.carbGPerKg,
        asset: widget.carbsPng,
        color: _colors[2],
      ),
    ];

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = response.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 0,
          sections: List.generate(data.length, (i) {
            final slice = data[i];
            final isTouched = i == touchedIndex;
            final pct = (slice.kcal / total * 100).clamp(0, 100);
            final fontSize = isTouched ? 18.0 : 14.0;
            final radius = isTouched ? 90.0 : 70.0;
            final badgeSize = isTouched ? 40.0 : 32.0;
            const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

            return PieChartSectionData(
              color: slice.color,
              value: slice.kcal,
              title: '${pct.toStringAsFixed(0)}%',
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: shadows,
              ),
              badgeWidget: _Badge(
                assetPath: slice.asset,
                size: badgeSize,
                borderColor: kCardColor,
              ),
              badgePositionPercentageOffset: .96,
            );
          }),
        ),
      ),
    );
  }
}

class _Slice {
  final String label;
  final double kcal;
  final double grams;
  final String asset;
  final Color color;

  _Slice({
    required this.label,
    required this.kcal,
    required this.grams,
    required this.asset,
    required this.color,
  });
}

class _Badge extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color borderColor;

  const _Badge({
    required this.assetPath,
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(127),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(child: Image.asset(assetPath, fit: BoxFit.contain)),
    );
  }
}
