import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/features/training_feature/utils/audit_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Widget que muestra la distribución de series por:
/// 1. Prioridad muscular (Primario/Secundario/Terciario)
/// 2. Intensidad (Pesadas/Medias/Ligeras)
class SeriesBreakdownTable extends StatelessWidget {
  final TrainingPlanConfig planConfig;

  const SeriesBreakdownTable({super.key, required this.planConfig});

  @override
  Widget build(BuildContext context) {
    final snapshot = planConfig.trainingProfileSnapshot;

    if (snapshot == null) {
      return _buildEmptyState('No hay perfil de entrenamiento asociado');
    }

    final extra = snapshot.extra;
    final totalsByMuscle = computeTotalSetsByMuscle(planConfig);

    // Parsear listas de prioridad muscular
    final primaryMuscles = _parseMuscleList(
      extra[TrainingExtraKeys.priorityMusclesPrimary]?.toString(),
    );
    final secondaryMuscles = _parseMuscleList(
      extra[TrainingExtraKeys.priorityMusclesSecondary]?.toString(),
    );
    final tertiaryMuscles = _parseMuscleList(
      extra[TrainingExtraKeys.priorityMusclesTertiary]?.toString(),
    );

    // Calcular totales por categoría de prioridad
    int primaryTotal = 0;
    int secondaryTotal = 0;
    int tertiaryTotal = 0;
    int otherTotal = 0;

    totalsByMuscle.forEach((muscle, sets) {
      if (primaryMuscles.contains(muscle)) {
        primaryTotal += sets;
      } else if (secondaryMuscles.contains(muscle)) {
        secondaryTotal += sets;
      } else if (tertiaryMuscles.contains(muscle)) {
        tertiaryTotal += sets;
      } else {
        otherTotal += sets;
      }
    });

    // Calcular totales por intensidad (basado en RIR de las prescripciones)
    final intensityBreakdown = _calculateIntensityBreakdown(planConfig);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección 1: Series por Prioridad Muscular
        _buildPrioritySection(
          primaryTotal,
          secondaryTotal,
          tertiaryTotal,
          otherTotal,
          primaryMuscles,
          secondaryMuscles,
          tertiaryMuscles,
          totalsByMuscle,
        ),

        const SizedBox(height: 32),
        const Divider(color: kBorderColor),
        const SizedBox(height: 32),

        // Sección 2: Series por Intensidad
        _buildIntensitySection(intensityBreakdown),
      ],
    );
  }

  Widget _buildPrioritySection(
    int primaryTotal,
    int secondaryTotal,
    int tertiaryTotal,
    int otherTotal,
    List<String> primaryMuscles,
    List<String> secondaryMuscles,
    List<String> tertiaryMuscles,
    Map<String, int> totalsByMuscle,
  ) {
    final grandTotal =
        primaryTotal + secondaryTotal + tertiaryTotal + otherTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DISTRIBUCIÓN POR PRIORIDAD MUSCULAR',
          style: TextStyle(
            color: kTextColorSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        _buildPriorityRow(
          'PRIMARIOS',
          primaryTotal,
          grandTotal,
          Colors.red.shade300,
          primaryMuscles,
          totalsByMuscle,
        ),
        const SizedBox(height: 12),

        _buildPriorityRow(
          'SECUNDARIOS',
          secondaryTotal,
          grandTotal,
          Colors.orange.shade300,
          secondaryMuscles,
          totalsByMuscle,
        ),
        const SizedBox(height: 12),

        _buildPriorityRow(
          'TERCIARIOS',
          tertiaryTotal,
          grandTotal,
          Colors.yellow.shade300,
          tertiaryMuscles,
          totalsByMuscle,
        ),

        if (otherTotal > 0) ...[
          const SizedBox(height: 12),
          _buildPriorityRow(
            'OTROS',
            otherTotal,
            grandTotal,
            Colors.grey.shade400,
            [],
            totalsByMuscle,
          ),
        ],

        const SizedBox(height: 16),
        const Divider(color: kBorderColor, height: 1),
        const SizedBox(height: 12),

        // Total general
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '$grandTotal series',
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityRow(
    String label,
    int sets,
    int grandTotal,
    Color color,
    List<String> muscles,
    Map<String, int> totalsByMuscle,
  ) {
    final percentage = grandTotal > 0 ? (sets / grandTotal * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$sets series',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (muscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles.map((muscle) {
                final muscleSets = totalsByMuscle[muscle] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '$muscle ($muscleSets)',
                    style: const TextStyle(color: kTextColor, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntensitySection(Map<String, int> breakdown) {
    final heavy = breakdown['heavy'] ?? 0;
    final medium = breakdown['medium'] ?? 0;
    final light = breakdown['light'] ?? 0;
    final total = heavy + medium + light;

    final heavyPercent = total > 0 ? (heavy / total * 100) : 0.0;
    final mediumPercent = total > 0 ? (medium / total * 100) : 0.0;
    final lightPercent = total > 0 ? (light / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DISTRIBUCIÓN POR INTENSIDAD (RIR)',
          style: TextStyle(
            color: kTextColorSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        _buildIntensityRow(
          'PESADAS (RIR 0-2)',
          heavy,
          heavyPercent,
          Colors.red.shade300,
        ),
        const SizedBox(height: 12),

        _buildIntensityRow(
          'MEDIAS (RIR 3-4)',
          medium,
          mediumPercent,
          Colors.orange.shade300,
        ),
        const SizedBox(height: 12),

        _buildIntensityRow(
          'LIGERAS (RIR 5+)',
          light,
          lightPercent,
          Colors.green.shade300,
        ),

        const SizedBox(height: 16),
        const Divider(color: kBorderColor, height: 1),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '$total series',
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntensityRow(
    String label,
    int sets,
    double percentage,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '$sets series',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: kTextColorSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Calcula distribución de series por intensidad basada en RIR
  Map<String, int> _calculateIntensityBreakdown(TrainingPlanConfig plan) {
    int heavy = 0; // RIR 0-2
    int medium = 0; // RIR 3-4
    int light = 0; // RIR 5+

    for (final week in plan.weeks) {
      for (final session in week.sessions) {
        for (final prescription in session.prescriptions) {
          // Usar el rirTarget que parsea correctamente el String
          final rirTarget = prescription.rirTarget;
          final avgRir = (rirTarget.min + rirTarget.max) / 2;

          if (avgRir <= 2) {
            heavy += prescription.sets;
          } else if (avgRir <= 4) {
            medium += prescription.sets;
          } else {
            light += prescription.sets;
          }
        }
      }
    }

    return {'heavy': heavy, 'medium': medium, 'light': light};
  }

  /// Parsea una lista de músculos separados por coma
  List<String> _parseMuscleList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();
  }
}
