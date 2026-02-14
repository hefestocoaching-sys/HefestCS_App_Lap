// lib/features/training_feature/widgets/weekly_feedback_form.dart

import 'package:flutter/material.dart';

/// Weekly feedback form for a single muscle
///
/// Collects:
/// - Muscle activation (1-10)
/// - Pump quality (1-10)
/// - Fatigue level (1-10)
/// - Recovery quality (1-10)
/// - Pain (yes/no + severity)
///
/// Version: 1.0.0
class WeeklyFeedbackForm extends StatefulWidget {
  final String muscle;
  final Map<String, dynamic>? initialFeedback;
  final ValueChanged<Map<String, dynamic>> onFeedbackChanged;

  const WeeklyFeedbackForm({
    super.key,
    required this.muscle,
    this.initialFeedback,
    required this.onFeedbackChanged,
  });

  @override
  State<WeeklyFeedbackForm> createState() => _WeeklyFeedbackFormState();
}

class _WeeklyFeedbackFormState extends State<WeeklyFeedbackForm> {
  late double _muscleActivation;
  late double _pumpQuality;
  late double _fatigueLevel;
  late double _recoveryQuality;
  late bool _hadPain;
  double? _painSeverity;
  String? _painDescription;
  late final TextEditingController _painController;

  @override
  void initState() {
    super.initState();
    _initializeFromFeedback();
    _painController = TextEditingController(text: _painDescription ?? '');
  }

  @override
  void didUpdateWidget(covariant WeeklyFeedbackForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFeedback != widget.initialFeedback) {
      _initializeFromFeedback();
      _painController.text = _painDescription ?? '';
    }
  }

  @override
  void dispose() {
    _painController.dispose();
    super.dispose();
  }

  void _initializeFromFeedback() {
    final feedback = widget.initialFeedback ?? {};
    _muscleActivation =
        (feedback['muscle_activation'] as num?)?.toDouble() ?? 7.0;
    _pumpQuality = (feedback['pump_quality'] as num?)?.toDouble() ?? 7.0;
    _fatigueLevel = (feedback['fatigue_level'] as num?)?.toDouble() ?? 5.0;
    _recoveryQuality =
        (feedback['recovery_quality'] as num?)?.toDouble() ?? 7.0;
    _hadPain = feedback['had_pain'] as bool? ?? false;
    _painSeverity = (feedback['pain_severity'] as num?)?.toDouble();
    _painDescription = feedback['pain_description'] as String?;
  }

  void _notifyChange() {
    final feedback = {
      'muscle_activation': _muscleActivation,
      'pump_quality': _pumpQuality,
      'fatigue_level': _fatigueLevel,
      'recovery_quality': _recoveryQuality,
      'had_pain': _hadPain,
      'pain_severity': _painSeverity,
      'pain_description': _painDescription,
    };
    widget.onFeedbackChanged(feedback);
  }

  @override
  Widget build(BuildContext context) {
    final muscleDisplay = _getDisplayName(widget.muscle);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              muscleDisplay,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Muscle Activation
            _buildSlider(
              label: 'Activacion Muscular',
              value: _muscleActivation,
              onChanged: (v) {
                setState(() => _muscleActivation = v);
                _notifyChange();
              },
              min: 1,
              max: 10,
              divisions: 9,
              valueLabel: _muscleActivation.toStringAsFixed(1),
              icon: Icons.fitbit,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Pump Quality
            _buildSlider(
              label: 'Calidad del Pump',
              value: _pumpQuality,
              onChanged: (v) {
                setState(() => _pumpQuality = v);
                _notifyChange();
              },
              min: 1,
              max: 10,
              divisions: 9,
              valueLabel: _pumpQuality.toStringAsFixed(1),
              icon: Icons.water_drop,
              color: Colors.purple,
            ),

            const SizedBox(height: 16),

            // Fatigue Level
            _buildSlider(
              label: 'Nivel de Fatiga',
              value: _fatigueLevel,
              onChanged: (v) {
                setState(() => _fatigueLevel = v);
                _notifyChange();
              },
              min: 1,
              max: 10,
              divisions: 9,
              valueLabel: _fatigueLevel.toStringAsFixed(1),
              icon: Icons.battery_alert,
              color: Colors.orange,
            ),

            const SizedBox(height: 16),

            // Recovery Quality
            _buildSlider(
              label: 'Calidad de Recuperacion',
              value: _recoveryQuality,
              onChanged: (v) {
                setState(() => _recoveryQuality = v);
                _notifyChange();
              },
              min: 1,
              max: 10,
              divisions: 9,
              valueLabel: _recoveryQuality.toStringAsFixed(1),
              icon: Icons.hotel,
              color: Colors.green,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Pain
            SwitchListTile(
              title: const Text('Tuviste dolor?'),
              subtitle: const Text(
                'Marca si experimentaste dolor durante los entrenamientos',
              ),
              value: _hadPain,
              onChanged: (v) {
                setState(() {
                  _hadPain = v;
                  if (!v) {
                    _painSeverity = null;
                    _painDescription = null;
                    _painController.text = '';
                  }
                });
                _notifyChange();
              },
            ),

            if (_hadPain) ...[
              const SizedBox(height: 16),

              // Pain Severity
              _buildSlider(
                label: 'Severidad del Dolor',
                value: _painSeverity ?? 5.0,
                onChanged: (v) {
                  setState(() => _painSeverity = v);
                  _notifyChange();
                },
                min: 1,
                max: 10,
                divisions: 9,
                valueLabel: (_painSeverity ?? 5.0).toStringAsFixed(1),
                icon: Icons.warning,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              // Pain Description
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Descripcion del dolor (opcional)',
                  hintText: 'Ej: Dolor agudo en el codo al hacer curl',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) {
                  _painDescription = v.isEmpty ? null : v;
                  _notifyChange();
                },
                controller: _painController,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          activeColor: color,
        ),
      ],
    );
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
