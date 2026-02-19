import 'package:flutter/material.dart';

import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';

class DietaryAdjustmentSection extends StatefulWidget {
  /// Stores 0.10..0.25 (Positive = Deficit) OR -0.10..-0.25 (Negative = Surplus)
  final TextEditingController deficitPctController;

  /// Outputs (UI Read-only)
  /// Positive = Deficit (Loss), Negative = Surplus (Gain)
  final double avgDailyDiffKcal;
  final double estimatedKgWeek;
  final double estimatedKgMonth;

  final List<String> days;
  final double Function(String day) calculateDailyGET;
  final int Function(String day) calculateDailyTargetKcal;

  /// Callback when percentage changes
  final void Function(double newPct) onDeficitPctChanged;

  const DietaryAdjustmentSection({
    super.key,
    required this.deficitPctController,
    required this.avgDailyDiffKcal,
    required this.estimatedKgWeek,
    required this.estimatedKgMonth,
    required this.days,
    required this.calculateDailyGET,
    required this.calculateDailyTargetKcal,
    required this.onDeficitPctChanged,
  });

  @override
  State<DietaryAdjustmentSection> createState() =>
      _DietaryAdjustmentSectionState();
}

class _DietaryAdjustmentSectionState extends State<DietaryAdjustmentSection> {
  // Local state for the toggle, synced with controller in build
  // But strictly, we derive it from controller value.

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildDeficitPanel()),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            color: kTextColor.withOpacity(0.1),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: "PROYECCIÓN DE CALORÍAS FINALES",
                  icon: Icons.show_chart_rounded,
                  textColor: kTextColorSecondary,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
                const SizedBox(height: 16),
                _buildWeeklySummaryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeficitPanel() {
    // Logic:
    // rawValue > 0 -> Deficit (0.15)
    // rawValue < 0 -> Surplus (-0.15)
    // rawValue = 0 -> Maintenance
    double rawValue = double.tryParse(widget.deficitPctController.text) ?? 0.15;

    // Determine strict mode
    // 1 = Deficit, 0 = Maintain, -1 = Surplus
    int mode = 0;
    if (rawValue > 0.001)
      mode = 1;
    else if (rawValue < -0.001)
      mode = -1;

    bool isMaintenance = mode == 0;
    bool isSurplus = mode == -1;

    double absPct = rawValue.abs();

    // Safety clamp for UI slider (only if NOT maintenance)
    // If maintenance, we allow 0.
    if (!isMaintenance) {
      if (absPct < 0.05) absPct = 0.05;
      if (absPct > 0.30) absPct = 0.30;
    } else {
      absPct = 0.0;
    }

    final pctLabel = (absPct * 100).toStringAsFixed(0);

    // Determines Styles
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String mainLabel;

    if (isMaintenance) {
      statusColor = Colors.blueGrey.shade200;
      mainLabel = "Mantenimiento";
      statusText = "Normocalórica";
      statusIcon = Icons.balance_rounded;
    } else if (isSurplus) {
      statusColor = Colors.greenAccent.shade400;
      mainLabel = "Superávit aplicado";
      if (absPct >= 0.18) {
        statusText = "Volumen Sucio/Agresivo";
        statusIcon = Icons.rocket_launch_rounded;
      } else if (absPct >= 0.10) {
        statusText = "Volumen Limpio";
        statusIcon = Icons.trending_up_rounded;
      } else {
        statusText = "Mantenimiento Plus";
        statusIcon = Icons.add_circle_outline_rounded;
      }
    } else {
      // Deficit
      statusColor = Colors.amberAccent.shade200;
      mainLabel = "Déficit aplicado";
      if (absPct >= 0.18) {
        statusText = "Agresivo";
        statusIcon = Icons.warning_amber_rounded;
      } else if (absPct >= 0.13) {
        statusText = "Estándar";
        statusIcon = Icons.tune_rounded;
        statusColor = Colors.lightBlueAccent.shade100;
      } else {
        statusText = "Conservador";
        statusIcon = Icons.shield_rounded;
        statusColor = kTextColorSecondary;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // TOGGLE SWITCH (3-way)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: kTextColor.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleOption(
                label: "DÉFICIT",
                isActive: mode == 1,
                activeColor: Colors.amberAccent.shade200,
                onTap: () {
                  // Switch to Deficit default (15%) or keep current mag if was deficit
                  double target = absPct;
                  if (target < 0.05) target = 0.15;
                  widget.onDeficitPctChanged(target);
                },
              ),
              _buildToggleOption(
                label: "MANTENIM.",
                isActive: mode == 0,
                activeColor: Colors.blueGrey.shade200,
                onTap: () {
                  widget.onDeficitPctChanged(0.0);
                },
              ),
              _buildToggleOption(
                label: "SUPERÁVIT",
                isActive: mode == -1,
                activeColor: Colors.greenAccent.shade400,
                onTap: () {
                  // Switch to Surplus default (15%)
                  double target = absPct;
                  if (target < 0.05) target = 0.15;
                  widget.onDeficitPctChanged(-target);
                },
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 8),
              Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          mainLabel,
          style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (isSurplus && !isMaintenance)
              Text(
                "+",
                style: TextStyle(
                  fontSize: 24,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (!isSurplus && !isMaintenance)
              Text(
                "-",
                style: TextStyle(
                  fontSize: 24,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              "$pctLabel%",
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Presets (10/15/20) - Hide if maintenance
        if (!isMaintenance)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _presetChip("10%", 0.10, absPct, isSurplus),
              const SizedBox(width: 10),
              _presetChip(
                isSurplus ? "15%" : "20%",
                isSurplus ? 0.15 : 0.20,
                absPct,
                isSurplus,
              ),
              const SizedBox(width: 10),
              _presetChip(
                isSurplus ? "20%" : "25%",
                isSurplus ? 0.20 : 0.25,
                absPct,
                isSurplus,
              ),
            ],
          ),

        const SizedBox(height: 18),
        // Slider fino - disable if maintenance
        IgnorePointer(
          ignoring: isMaintenance,
          child: Opacity(
            opacity: isMaintenance ? 0.3 : 1.0,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: statusColor,
                thumbColor: statusColor,
                overlayColor: statusColor.withOpacity(0.2),
                inactiveTrackColor: statusColor.withOpacity(0.2),
              ),
              child: Slider(
                value: absPct.clamp(0.05, 0.30),
                min: 0.05,
                max: 0.30,
                divisions: 25,
                onChanged: (v) {
                  double cleanVal = double.parse(v.toStringAsFixed(3));
                  if (isSurplus) cleanVal = -cleanVal;
                  widget.onDeficitPctChanged(cleanVal);
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        // Outputs clínicos
        _metricRow(
          isMaintenance
              ? "Diferencia teórica"
              : (isSurplus
                    ? "Superávit real promedio"
                    : "Déficit real promedio"),
          "${(isSurplus ? -widget.avgDailyDiffKcal : widget.avgDailyDiffKcal).toStringAsFixed(0)} kcal/día",
          statusColor,
        ),
        const SizedBox(height: 8),
        _metricRow(
          isSurplus ? "Ganancia estimada" : "Pérdida estimada",
          "${(isSurplus ? -widget.estimatedKgWeek : widget.estimatedKgWeek).toStringAsFixed(2)} kg/sem",
          statusColor,
        ),
        const SizedBox(height: 8),
        _metricRow(
          "Proyección mensual",
          "${(isSurplus ? -widget.estimatedKgMonth : widget.estimatedKgMonth).toStringAsFixed(2)} kg/mes",
          kTextColor,
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : kTextColorSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _presetChip(
    String label,
    double value,
    double currentAbs,
    bool isSurplus,
  ) {
    // Current is strictly match if abs diff is small
    final selected = (currentAbs - value).abs() < 0.005;
    final color = isSurplus ? Colors.greenAccent.shade400 : kPrimaryColor;

    return GestureDetector(
      onTap: () {
        double v = value;
        if (isSurplus) v = -v;
        widget.onDeficitPctChanged(v);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.45)
                : kTextColor.withOpacity(0.18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : kTextColorSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTextColor.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryList() {
    return Column(
      children: widget.days.map((day) {
        final get = widget.calculateDailyGET(day);
        final target = widget.calculateDailyTargetKcal(day).toDouble();

        // Visual indicator of gap
        // Visual indicator of gap
        final isSurplus = target > get;
        final isMaintenance = (target - get).abs() < 5; // Tolerance
        final color = isMaintenance
            ? Colors.blueGrey.shade200
            : (isSurplus
                  ? Colors.greenAccent.shade400
                  : Colors.amberAccent.shade200);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kTextColor.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  day,
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "${get.toStringAsFixed(0)} kcal",
                  style: const TextStyle(color: kTextColorSecondary),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.28)),
                    ),
                    child: Text(
                      "${target.toStringAsFixed(0)} kcal",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
