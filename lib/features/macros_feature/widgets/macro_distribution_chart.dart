import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

const Color _proteinColor = Color(0xFF35D39D);
const Color _fatColor = Color(0xFFF7A33B);
const Color _carbColor = Color(0xFF4EA7FF);
const Color _negativeColor = Color(0xFFFF6B6B);

class MacroDistributionChart extends StatelessWidget {
  final dynamic data;
  final dynamic day;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbsGrams;
  final double? targetCalories;

  const MacroDistributionChart({
    super.key,
    this.data,
    this.day,
    this.proteinGrams,
    this.fatGrams,
    this.carbsGrams,
    this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final protein = proteinGrams ?? 0;
    final fat = fatGrams ?? 0;
    final carbs = carbsGrams ?? 0;
    final kcal = targetCalories ?? 0;

    final proteinKcal = protein * 4;
    final fatKcal = fat * 9;
    final carbKcal = carbs * 4;
    final total = math.max(1, proteinKcal + fatKcal + math.max(0, carbKcal));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kInputFillColor.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución calórica',
            style: TextStyle(
              color: kTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final chart = SizedBox.square(
                dimension: compact ? 132 : 148,
                child: CustomPaint(
                  painter: _MacroDonutPainter(
                    proteinShare: proteinKcal / total,
                    fatShare: fatKcal / total,
                    carbShare: math.max(0, carbKcal) / total,
                    carbsAreNegative: carbs < 0,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          kcal > 0 ? kcal.toStringAsFixed(0) : total.toStringAsFixed(0),
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final legend = Column(
                children: [
                  _LegendRow(
                    color: _proteinColor,
                    label: 'Proteína',
                    grams: protein,
                    kcal: proteinKcal,
                  ),
                  _LegendRow(
                    color: _fatColor,
                    label: 'Grasas',
                    grams: fat,
                    kcal: fatKcal,
                  ),
                  _LegendRow(
                    color: carbs < 0 ? _negativeColor : _carbColor,
                    label: 'Carbohidratos',
                    grams: carbs,
                    kcal: carbKcal,
                  ),
                ],
              );

              if (compact) {
                return Column(
                  children: [
                    Center(child: chart),
                    const SizedBox(height: 16),
                    legend,
                  ],
                );
              }

              return Row(
                children: [
                  chart,
                  const SizedBox(width: 20),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double grams;
  final double kcal;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.grams,
    required this.kcal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${grams.toStringAsFixed(0)} g · ${kcal.toStringAsFixed(0)} kcal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  final double proteinShare;
  final double fatShare;
  final double carbShare;
  final bool carbsAreNegative;

  const _MacroDonutPainter({
    required this.proteinShare,
    required this.fatShare,
    required this.carbShare,
    required this.carbsAreNegative,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.13;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(strokeWidth / 2), -math.pi / 2, math.pi * 2, false, basePaint);

    var start = -math.pi / 2;
    void drawSegment(double share, Color color) {
      if (share <= 0) return;
      paint.color = color;
      final sweep = math.pi * 2 * share;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }

    drawSegment(proteinShare, _proteinColor);
    drawSegment(fatShare, _fatColor);
    drawSegment(carbShare, carbsAreNegative ? _negativeColor : _carbColor);
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter oldDelegate) {
    return proteinShare != oldDelegate.proteinShare ||
        fatShare != oldDelegate.fatShare ||
        carbShare != oldDelegate.carbShare ||
        carbsAreNegative != oldDelegate.carbsAreNegative;
  }
}
