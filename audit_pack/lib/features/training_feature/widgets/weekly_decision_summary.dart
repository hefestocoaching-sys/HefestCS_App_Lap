// lib/features/training_feature/widgets/weekly_decision_summary.dart

import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';

/// Widget showing weekly decisions summary
///
/// Displays:
/// - Decisions for all muscles
/// - Actions (increase, maintain, deload, etc.)
/// - New volumes
/// - Reasons
///
/// Version: 1.0.0
class WeeklyDecisionSummary extends StatelessWidget {
  final Map<String, MuscleDecision> decisions;
  final int weekNumber;

  const WeeklyDecisionSummary({
    super.key,
    required this.decisions,
    required this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    final sortedMuscles = decisions.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Decisiones Semana $weekNumber',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Summary stats
            _buildSummaryStats(),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Decisions list
            ...sortedMuscles.map((muscle) {
              final decision = decisions[muscle]!;
              return _buildDecisionItem(muscle, decision);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    int increases = 0;
    int maintains = 0;
    int decreases = 0;
    int microdeloads = 0;

    for (final decision in decisions.values) {
      switch (decision.action) {
        case VolumeAction.increase:
          increases++;
          break;
        case VolumeAction.maintain:
        case VolumeAction.adjust:
          maintains++;
          break;
        case VolumeAction.deload:
        case VolumeAction.decrease:
          decreases++;
          break;
        case VolumeAction.microdeload:
          microdeloads++;
          break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatChip('^ $increases', Colors.green, 'Aumentar'),
        _buildStatChip('= $maintains', Colors.blue, 'Mantener'),
        _buildStatChip('~ $microdeloads', Colors.purple, 'Micro'),
        _buildStatChip('v $decreases', Colors.orange, 'Descarga'),
      ],
    );
  }

  Widget _buildStatChip(String value, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDecisionItem(String muscle, MuscleDecision decision) {
    final muscleDisplay = _getDisplayName(muscle);
    final actionColor = _getActionColor(decision.action);
    final actionIcon = _getActionIcon(decision.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: actionColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: actionColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muscle name + action
          Row(
            children: [
              Icon(actionIcon, color: actionColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  muscleDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: actionColor),
                ),
                child: Text(
                  _getActionName(decision.action),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Volume change
          Row(
            children: [
              const Text('Volumen: ', style: TextStyle(fontSize: 14)),
              Text(
                '${decision.newVolume} sets',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: actionColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${decision.newPhase.name})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Reason
          Text(
            decision.reason,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),

          // VMR discovered
          if (decision.vmrDiscovered != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.flag, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'VMR descubierto: ${decision.vmrDiscovered} sets',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Microdeload required
          if (decision.requiresMicrodeload) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.battery_charging_full,
                  size: 14,
                  color: Colors.purple,
                ),
                const SizedBox(width: 4),
                Text(
                  'Microdescarga requerida (${decision.weeksToMicrodeload} semanas)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getActionColor(VolumeAction action) {
    switch (action) {
      case VolumeAction.increase:
        return Colors.green;
      case VolumeAction.maintain:
      case VolumeAction.adjust:
        return Colors.blue;
      case VolumeAction.deload:
      case VolumeAction.decrease:
        return Colors.orange;
      case VolumeAction.microdeload:
        return Colors.purple;
    }
  }

  IconData _getActionIcon(VolumeAction action) {
    switch (action) {
      case VolumeAction.increase:
        return Icons.trending_up;
      case VolumeAction.maintain:
      case VolumeAction.adjust:
        return Icons.trending_flat;
      case VolumeAction.deload:
      case VolumeAction.decrease:
        return Icons.trending_down;
      case VolumeAction.microdeload:
        return Icons.battery_charging_full;
    }
  }

  String _getActionName(VolumeAction action) {
    switch (action) {
      case VolumeAction.increase:
        return 'AUMENTAR';
      case VolumeAction.maintain:
        return 'MANTENER';
      case VolumeAction.adjust:
        return 'AJUSTAR';
      case VolumeAction.deload:
      case VolumeAction.decrease:
        return 'DESCARGA';
      case VolumeAction.microdeload:
        return 'MICRO';
    }
  }

  String _getDisplayName(String muscle) {
    const displayNames = {
      'pectorals': 'Pectorales',
      'lats': 'Dorsales',
      'upper_back': 'Espalda Alta',
      'traps': 'Trapecios',
      'deltoide_anterior': 'Hombro Frontal',
      'deltoide_lateral': 'Hombro Lateral',
      'deltoide_posterior': 'Hombro Posterior',
      'biceps': 'Biceps',
      'triceps': 'Triceps',
      'quadriceps': 'Cuadriceps',
      'hamstrings': 'Isquiotibiales',
      'glutes': 'Gluteos',
      'calves': 'Pantorrillas',
      'abs': 'Abdominales',
    };

    return displayNames[muscle] ?? muscle;
  }
}
