import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class FiveCHeaderRow extends StatelessWidget {
  final String labelA;
  final String labelB;

  const FiveCHeaderRow({super.key, required this.labelA, required this.labelB});

  Widget _separator() => Container(width: 1, height: 32, color: kAppBarColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: Text(
            'Componente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
        _separator(),
        const Expanded(
          flex: 2,
          child: Text(
            '%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Kg',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
        _separator(),
        const Expanded(
          flex: 2,
          child: Text(
            '%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Kg',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
        _separator(),
        const Expanded(
          flex: 2,
          child: Text(
            'Diferencia (%)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Diferencia (kg)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColorSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class FiveCRow extends StatelessWidget {
  final String label;
  final String percentTextA;
  final String kgTextA;
  final String percentTextB;
  final String kgTextB;
  final String percentTextDiff;
  final String kgTextDiff;

  const FiveCRow({
    super.key,
    required this.label,
    required this.percentTextA,
    required this.kgTextA,
    required this.percentTextB,
    required this.kgTextB,
    required this.percentTextDiff,
    required this.kgTextDiff,
  });

  Widget _separator() => Container(width: 1, height: 28, color: kAppBarColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: kTextColor, fontSize: 14),
            ),
          ),
          _separator(),
          Expanded(
            flex: 2,
            child: Text(
              percentTextA,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              kgTextA,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _separator(),
          Expanded(
            flex: 2,
            child: Text(
              percentTextB,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              kgTextB,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _separator(),
          Expanded(
            flex: 2,
            child: Text(
              percentTextDiff,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              kgTextDiff,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FiveCCombinedMetric {
  final String label;
  final double? valueA;
  final double? valueB;
  final String displayA;
  final String displayB;
  final Color colorA;
  final Color colorB;

  const FiveCCombinedMetric({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.displayA,
    required this.displayB,
    required this.colorA,
    required this.colorB,
  });
}

class FiveCCombinedBarChart extends StatelessWidget {
  final String title;
  final List<FiveCCombinedMetric> data;

  const FiveCCombinedBarChart({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final usable = data
        .where((d) => d.valueA != null || d.valueB != null)
        .toList();
    if (usable.isEmpty) return const SizedBox.shrink();

    final double maxY =
        usable
            .map(
              (d) => [(d.valueA ?? 0).abs(), (d.valueB ?? 0).abs()].reduce(max),
            )
            .reduce(max) *
        1.2;

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < usable.length; i++) {
      final d = usable[i];
      final rodA = BarChartRodData(
        toY: d.valueA ?? 0,
        width: 26,
        color: d.colorA,
        borderRadius: BorderRadius.circular(8),
      );
      final rodB = BarChartRodData(
        toY: d.valueB ?? 0,
        width: 26,
        color: d.colorB,
        borderRadius: BorderRadius.circular(8),
      );
      barGroups.add(
        BarChartGroupData(x: i, barsSpace: 6, barRods: [rodA, rodB]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextColorSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          width: double.infinity,
          child: BarChart(
            BarChartData(
              maxY: maxY <= 0 ? 1 : maxY,
              gridData: FlGridData(
                horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: kTextColorSecondary.withAlpha(30),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: kTextColorSecondary.withAlpha(24),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              groupsSpace: 16,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY <= 0 ? 1 : maxY / 4,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= usable.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          usable[idx].label,
                          style: const TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => kCardColor,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final comp = usable[groupIndex];
                    final who = rodIndex == 0 ? 'A' : 'B';
                    final display = rodIndex == 0
                        ? comp.displayA
                        : comp.displayB;
                    return BarTooltipItem(
                      '${comp.label} ($who)\n$display',
                      const TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 250),
          ),
        ),
      ],
    );
  }
}
