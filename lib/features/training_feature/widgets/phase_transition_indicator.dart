// lib/features/training_feature/widgets/phase_transition_indicator.dart

import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:intl/intl.dart';

/// Widget showing phase transition timeline
///
/// Displays:
/// - Phase transitions history
/// - Transition reasons
/// - Timestamps
///
/// Version: 1.0.0
class PhaseTransitionIndicator extends StatelessWidget {
  final List<PhaseTransition> transitions;
  final int maxTransitions;

  const PhaseTransitionIndicator({
    super.key,
    required this.transitions,
    this.maxTransitions = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (transitions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No hay transiciones de fase aun')),
        ),
      );
    }

    final recentTransitions = transitions.length > maxTransitions
        ? transitions.sublist(transitions.length - maxTransitions)
        : transitions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Transiciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentTransitions.reversed.map((transition) {
              return _buildTransitionItem(transition);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionItem(PhaseTransition transition) {
    final fromColor = _getPhaseColor(transition.fromPhase);
    final toColor = _getPhaseColor(transition.toPhase);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week indicator
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'S${transition.weekNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Transition arrow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase transition
                Row(
                  children: [
                    _buildPhaseChip(
                      _getPhaseName(transition.fromPhase),
                      fromColor,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16),
                    ),
                    _buildPhaseChip(_getPhaseName(transition.toPhase), toColor),
                  ],
                ),

                const SizedBox(height: 4),

                // Reason
                Text(
                  transition.reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 2),

                // Date
                Text(
                  dateFormat.format(transition.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChip(String label, Color color) {
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
          fontSize: 11,
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
}
