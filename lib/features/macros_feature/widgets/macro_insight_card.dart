import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class MacroInsightCard extends StatelessWidget {
  final dynamic data;
  final dynamic day;
  final String? insight;
  final double? targetCalories;
  final double? maintenanceCalories;
  final double? deficitPercent;
  final double? weeklyDeficitCalories;
  final double? monthlyProjectionKg;
  final bool? hasNegativeCarbs;

  const MacroInsightCard({
    super.key,
    this.data,
    this.day,
    this.insight,
    this.targetCalories,
    this.maintenanceCalories,
    this.deficitPercent,
    this.weeklyDeficitCalories,
    this.monthlyProjectionKg,
    this.hasNegativeCarbs,
  });

  @override
  Widget build(BuildContext context) {
    final target = targetCalories ?? 0;
    final maintenance = maintenanceCalories ?? 0;
    final deficit = deficitPercent ?? 0;
    final weeklyDeficit = weeklyDeficitCalories ?? 0;
    final monthlyProjection = monthlyProjectionKg ?? 0;
    const activityText =
        'Distribución diaria calculada para el contexto del día.';
    const statusText = 'Estado configurado para este día.';
    final warning = hasNegativeCarbs ?? false;

    final energyText = maintenance > 0
        ? 'Déficit de ${deficit.toStringAsFixed(1)}%. Objetivo: ${target.toStringAsFixed(0)} kcal frente a mantenimiento de ${maintenance.toStringAsFixed(0)} kcal.'
        : 'Objetivo energético diario: ${target.toStringAsFixed(0)} kcal.';
    final weekText = weeklyDeficit > 0 || monthlyProjection != 0
        ? 'Déficit semanal estimado de ${weeklyDeficit.toStringAsFixed(0)} kcal. Proyección mensual aproximada: ${monthlyProjection.toStringAsFixed(2)} kg/mes.'
        : (insight ?? 'Sin proyección semanal adicional para este día.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kInputFillColor.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: warning
              ? kWarningColor.withValues(alpha: 0.32)
              : kPrimaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: warning ? kWarningColor : kPrimaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                warning ? 'Insight del día · revisar carbohidratos' : 'Insight del día',
                style: TextStyle(
                  color: warning ? kWarningColor : kPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _InsightSection(label: 'Actividad física', body: activityText),
          _InsightSection(label: 'Estado energético', body: energyText),
          _InsightSection(label: 'Semana tipo', body: weekText),
          const _InsightSection(label: 'Estado del día', body: statusText),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final String label;
  final String body;

  const _InsightSection({
    required this.label,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
