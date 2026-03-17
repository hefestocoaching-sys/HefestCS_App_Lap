// lib/features/training_feature/widgets/muscle_progression_card.dart

import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';

/// Card displaying muscle progression tracker
///
/// Shows:
/// - Muscle name
/// - Current volume
/// - Current phase
/// - Weeks in phase
/// - VMR if discovered
/// - Priority
///
/// Version: 1.0.0
class MuscleProgressionCard extends StatelessWidget {
  final String muscle;
  final MuscleProgressionTracker tracker;
  final VoidCallback? onTap;

  const MuscleProgressionCard({
    super.key,
    required this.muscle,
    required this.tracker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscleDisplay = _getDisplayName(muscle);
    final phaseColor = _getPhaseColor(tracker.currentPhase);
    final phaseIcon = _getPhaseIcon(tracker.currentPhase);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Muscle name
                  Expanded(
                    child: Text(
                      muscleDisplay,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Priority badge
                  _buildPriorityBadge(tracker.priority),
                ],
              ),

              const SizedBox(height: 12),

              // Phase indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: phaseColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(phaseIcon, size: 16, color: phaseColor),
                        const SizedBox(width: 6),
                        Text(
                          _getPhaseName(tracker.currentPhase),
                          style: TextStyle(
                            color: phaseColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Semana ${tracker.weekInCurrentPhase + 1}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Metrics
              Row(
                children: [
                  // Current volume
                  Expanded(
                    child: _buildMetric(
                      label: 'Volumen',
                      value: '${tracker.currentVolume} sets',
                      icon: Icons.fitness_center,
                      color: Colors.blue,
                    ),
                  ),

                  // VMR
                  Expanded(
                    child: _buildMetric(
                      label: 'VMR',
                      value: tracker.vmrDiscovered != null
                          ? '${tracker.vmrDiscovered} sets'
                          : 'No descubierto',
                      icon: Icons.flag,
                      color: tracker.vmrDiscovered != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Landmarks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLandmarkChip(
                    'VME: ${tracker.landmarks.vme}',
                    Colors.grey,
                  ),
                  _buildLandmarkChip(
                    'VOP: ${tracker.landmarks.vop}',
                    Colors.blue,
                  ),
                  _buildLandmarkChip(
                    'MRV: ${tracker.landmarks.vmr}',
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    String label;
    Color color;

    switch (priority) {
      case 5:
        label = 'Primario';
        color = Colors.red;
        break;
      case 3:
        label = 'Secundario';
        color = Colors.orange;
        break;
      case 1:
        label = 'Terciario';
        color = Colors.grey;
        break;
      default:
        label = 'P$priority';
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPhaseColor(ProgressionPhase phase) {
    switch (phase) {
      case ProgressionPhase.discovering:
        return Colors.blue;
      case ProgressionPhase.maintaining:
        return Colors.green;
      case ProgressionPhase.overreaching:
        return Colors.orange;
      case ProgressionPhase.deloading:
      case ProgressionPhase.microdeload:
        return Colors.purple;
    }
  }

  IconData _getPhaseIcon(ProgressionPhase phase) {
    switch (phase) {
      case ProgressionPhase.discovering:
        return Icons.explore;
      case ProgressionPhase.maintaining:
        return Icons.check_circle;
      case ProgressionPhase.overreaching:
        return Icons.warning;
      case ProgressionPhase.deloading:
      case ProgressionPhase.microdeload:
        return Icons.battery_charging_full;
    }
  }

  String _getPhaseName(ProgressionPhase phase) {
    switch (phase) {
      case ProgressionPhase.discovering:
        return 'Descubriendo';
      case ProgressionPhase.maintaining:
        return 'Manteniendo';
      case ProgressionPhase.overreaching:
        return 'Sobrecarga';
      case ProgressionPhase.deloading:
        return 'Descarga';
      case ProgressionPhase.microdeload:
        return 'Microdescarga';
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
