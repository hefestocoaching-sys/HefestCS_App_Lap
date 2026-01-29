import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';

class DietaryAdjustmentSection extends StatelessWidget {
  /// NEW: deficitPctController guarda 0.10..0.25 (double string)
  final TextEditingController deficitPctController;

  /// Outputs (solo lectura en UI)
  final double avgDailyDeficitKcal;
  final double estimatedKgWeek;
  final double estimatedKgMonth;

  final List<String> days;
  final double Function(String day) calculateDailyGET;
  final int Function(String day) calculateDailyTargetKcal;

  /// Callback al cambiar el porcentaje
  final void Function(double newPct) onDeficitPctChanged;

  const DietaryAdjustmentSection({
    super.key,
    required this.deficitPctController,
    required this.avgDailyDeficitKcal,
    required this.estimatedKgWeek,
    required this.estimatedKgMonth,
    required this.days,
    required this.calculateDailyGET,
    required this.calculateDailyTargetKcal,
    required this.onDeficitPctChanged,
  });

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
            color: kTextColor.withAlpha((255 * 0.1).round()),
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
    final pct = double.tryParse(deficitPctController.text) ?? 0.15;
    final pctLabel = (pct * 100).toStringAsFixed(0);

    // Semáforo clínico simple
    Color statusColor = kTextColorSecondary;
    String statusText = "Conservador";
    IconData statusIcon = Icons.shield_rounded;

    if (pct >= 0.18) {
      statusText = "Agresivo";
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.amberAccent.shade200;
    } else if (pct >= 0.13) {
      statusText = "Estándar";
      statusIcon = Icons.tune_rounded;
      statusColor = Colors.lightBlueAccent.shade100;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withAlpha((255 * 0.12).round()),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withAlpha((255 * 0.25).round()),
            ),
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
        const SizedBox(height: 28),
        const Text(
          "Déficit aplicado",
          style: TextStyle(color: kTextColorSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          "$pctLabel%",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 10),

        // Presets (10/15/20)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _presetChip("10%", 0.10, pct),
            const SizedBox(width: 10),
            _presetChip("15%", 0.15, pct),
            const SizedBox(width: 10),
            _presetChip("20%", 0.20, pct),
          ],
        ),

        const SizedBox(height: 18),
        // Slider fino
        Slider(
          value: pct.clamp(0.05, 0.30),
          min: 0.05,
          max: 0.30,
          divisions: 25,
          onChanged: (v) =>
              onDeficitPctChanged(double.parse(v.toStringAsFixed(3))),
        ),

        const SizedBox(height: 16),
        // Outputs clínicos
        _metricRow(
          "Déficit real promedio",
          "${avgDailyDeficitKcal.toStringAsFixed(0)} kcal/día",
        ),
        const SizedBox(height: 8),
        _metricRow(
          "Pérdida estimada",
          "${estimatedKgWeek.toStringAsFixed(2)} kg/sem",
        ),
        const SizedBox(height: 8),
        _metricRow(
          "Proyección mensual",
          "${estimatedKgMonth.toStringAsFixed(2)} kg/mes",
        ),
      ],
    );
  }

  Widget _presetChip(String label, double value, double current) {
    final selected = (current - value).abs() < 0.005;
    return GestureDetector(
      onTap: () => onDeficitPctChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? kPrimaryColor.withAlpha((255 * 0.18).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? kPrimaryColor.withAlpha((255 * 0.45).round())
                : kTextColor.withAlpha((255 * 0.18).round()),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kPrimaryColor : kTextColorSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor.withAlpha((255 * 0.22).round()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTextColor.withAlpha((255 * 0.10).round())),
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
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryList() {
    return Column(
      children: days.map((day) {
        final get = calculateDailyGET(day);
        final target = calculateDailyTargetKcal(day).toDouble();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardColor.withAlpha((255 * 0.18).round()),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: kTextColor.withAlpha((255 * 0.10).round()),
            ),
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
                      color: kPrimaryColor.withAlpha((255 * 0.14).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: kPrimaryColor.withAlpha((255 * 0.28).round()),
                      ),
                    ),
                    child: Text(
                      "${target.toStringAsFixed(0)} kcal",
                      style: const TextStyle(
                        color: kTextColor,
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
