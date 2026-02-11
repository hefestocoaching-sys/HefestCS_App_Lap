import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/macrocycle_plan.dart';
import 'package:hcs_app_lap/domain/entities/week_plan.dart'; // Usamos la entidad correcta
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';

class TrainingWeeksOverviewScreen extends ConsumerWidget {
  const TrainingWeeksOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(trainingPlanProvider);
    if (planState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (planState.missingFields.isNotEmpty) {
      final fields = planState.missingFields.join(', ');
      return Center(child: Text("Perfil incompleto. Faltan: $fields"));
    }
    if (planState.error != null) {
      return Center(child: Text("Error: ${planState.error}"));
    }

    final plan = planState.plan;
    if (plan == null || plan.weeks <= 0) {
      return const Center(
        child: Text("No hay un plan activo para visualizar."),
      );
    }

    final macroPlan = MacrocyclePlan(
      weeklyPlans: List.generate(
        plan.weeks,
        (index) => WeekPlan(
          weekNumber: index + 1,
          phase: _phaseForIndex(index, plan.weeks),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Vista General del Macrociclo"),
        backgroundColor: kAppBarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // GRÁFICA DE ONDULACIÓN DE VOLUMEN
            SizedBox(
              height: 200,
              child: _VolumeChart(weeklyPlans: macroPlan.weeklyPlans),
            ),
            const SizedBox(height: 24),

            // LISTA DE SEMANAS
            Expanded(
              child: ListView.builder(
                itemCount: macroPlan.weeklyPlans.length,
                itemBuilder: (context, index) {
                  final week = macroPlan.weeklyPlans[index];
                  return Card(
                    color: kCardColor,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForPhase(week.phase),
                        child: Text(
                          "${week.weekNumber}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        "Semana ${week.weekNumber}: ${_getPhaseLabel(week.phase)}",
                        style: const TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Factor de Volumen: ${(week.volumeFactor * 100).toInt()}%",
                        style: const TextStyle(color: kTextColorSecondary),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: kTextColorSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseLabel(TrainingPhase phase) {
    switch (phase) {
      case TrainingPhase.accumulation:
        return "Adaptación (AA)";
      case TrainingPhase.intensification:
        return "Fuerza (ST)";
      case TrainingPhase.deload:
        return "Descarga (DL)";
    }
  }

  Color _getColorForPhase(TrainingPhase phase) {
    if (phase.isDeload) return Colors.greenAccent;
    if (phase.isIntensification) return Colors.redAccent;
    if (phase.isAccumulation) return kPrimaryColor;
    return Colors.grey;
  }

  TrainingPhase _phaseForIndex(int index, int totalWeeks) {
    if (totalWeeks <= 1) return TrainingPhase.accumulation;
    final progress = (index + 1) / totalWeeks;
    if (progress >= 0.9) return TrainingPhase.deload;
    if (progress >= 0.7) return TrainingPhase.intensification;
    return TrainingPhase.accumulation;
  }
}

class _VolumeChart extends StatelessWidget {
  final List<WeekPlan> weeklyPlans;

  const _VolumeChart({required this.weeklyPlans});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.5,
        minY: 0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < weeklyPlans.length) {
                  // Mostrar solo algunas etiquetas si son muchas semanas
                  if (value.toInt() % 4 == 0) {
                    return Text(
                      "S${weeklyPlans[value.toInt()].weekNumber}",
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 10,
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            
          ),
          topTitles: const AxisTitles(
            
          ),
          rightTitles: const AxisTitles(
            
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weeklyPlans.asMap().entries.map((entry) {
          final index = entry.key;
          final week = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: week.volumeFactor,
                color: _getBarColor(week.phase),
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getBarColor(TrainingPhase phase) {
    if (phase.isDeload) return Colors.green;
    if (phase.isIntensification) return Colors.red;
    return kPrimaryColor;
  }
}
