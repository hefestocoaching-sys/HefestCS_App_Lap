import 'package:flutter/material.dart';
import '../../../domain/training/models/muscle_priorities.dart';

/// Widget to configure priorities for the 14 canonical muscles.
///
/// Shows 14 sliders (1-5) organized by anatomical sections.
class MusclePriorityMatrix extends StatefulWidget {
  final MusclePriorities initialPriorities;
  final ValueChanged<MusclePriorities> onChanged;

  const MusclePriorityMatrix({
    super.key,
    required this.initialPriorities,
    required this.onChanged,
  });

  @override
  State<MusclePriorityMatrix> createState() => _MusclePriorityMatrixState();
}

class _MusclePriorityMatrixState extends State<MusclePriorityMatrix> {
  late MusclePriorities priorities;

  @override
  void initState() {
    super.initState();
    priorities = widget.initialPriorities;
  }

  void _updatePriority(String muscle, int value) {
    setState(() {
      priorities.set(muscle, value);
    });
    widget.onChanged(priorities);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prioridades Musculares',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Asigna prioridad a cada grupo muscular (1=minima, 5=maxima)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Pecho',
              muscles: [_MuscleConfig('chest', 'Pectorales')],
            ),
            _buildSection(
              context,
              title: 'Espalda',
              muscles: [
                _MuscleConfig('lats', 'Dorsales'),
                _MuscleConfig('upper_back', 'Espalda Alta'),
                _MuscleConfig('traps', 'Trapecio'),
              ],
            ),
            _buildSection(
              context,
              title: 'Hombros',
              muscles: [
                _MuscleConfig('deltoide_anterior', 'Deltoide Anterior'),
                _MuscleConfig('deltoide_lateral', 'Deltoide Lateral'),
                _MuscleConfig('deltoide_posterior', 'Deltoide Posterior'),
              ],
            ),
            _buildSection(
              context,
              title: 'Brazos',
              muscles: [
                _MuscleConfig('biceps', 'Biceps'),
                _MuscleConfig('triceps', 'Triceps'),
              ],
            ),
            _buildSection(
              context,
              title: 'Piernas',
              muscles: [
                _MuscleConfig('quads', 'Cuadriceps'),
                _MuscleConfig('hamstrings', 'Femoral'),
                _MuscleConfig('glutes', 'Gluteos'),
                _MuscleConfig('calves', 'Gemelos'),
              ],
            ),
            _buildSection(
              context,
              title: 'Core',
              muscles: [_MuscleConfig('abs', 'Abdominales')],
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MuscleConfig> muscles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ...muscles.map(
          (config) =>
              _buildSlider(context, label: config.label, muscleKey: config.key),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required String muscleKey,
  }) {
    final currentValue = priorities.get(muscleKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: currentValue.toDouble(),
              label: _getPriorityLabel(currentValue),
              onChanged: (value) {
                _updatePriority(muscleKey, value.toInt());
              },
              activeColor: _getPriorityColor(currentValue),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getPriorityColor(currentValue).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentValue.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getPriorityColor(currentValue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final sortedMuscles = priorities.getSortedByPriority();
    final topMuscles = sortedMuscles.take(5).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Prioridades',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Top 5 musculos prioritarios:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ...topMuscles.map((muscle) {
              final priority = priorities.get(muscle);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMuscleLabel(muscle),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      'Prioridad: $priority',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getPriorityLabel(int value) {
    switch (value) {
      case 1:
        return 'Muy Baja';
      case 2:
        return 'Baja';
      case 3:
        return 'Media';
      case 4:
        return 'Alta';
      case 5:
        return 'Muy Alta';
      default:
        return 'Media';
    }
  }

  Color _getPriorityColor(int value) {
    switch (value) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getMuscleLabel(String muscle) {
    const labels = {
      'chest': 'Pectorales',
      'lats': 'Dorsales',
      'upper_back': 'Espalda Alta',
      'traps': 'Trapecio',
      'deltoide_anterior': 'Deltoide Anterior',
      'deltoide_lateral': 'Deltoide Lateral',
      'deltoide_posterior': 'Deltoide Posterior',
      'biceps': 'Biceps',
      'triceps': 'Triceps',
      'quads': 'Cuadriceps',
      'hamstrings': 'Femoral',
      'glutes': 'Gluteos',
      'calves': 'Gemelos',
      'abs': 'Abdominales',
    };
    return labels[muscle] ?? muscle;
  }
}

class _MuscleConfig {
  final String key;
  final String label;

  _MuscleConfig(this.key, this.label);
}
