import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_engine_v3_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Dialog para recolectar outcome después de ejecutar plan
///
/// Guarda en Firestore (ml_training_data) para entrenar modelos ML.
///
/// Llamar cuando:
/// - Usuario completa 2-4 semanas de plan
/// - Coach revisa progreso con cliente
class MLOutcomeFeedbackDialog extends ConsumerStatefulWidget {
  final String mlExampleId;
  final String clientId;

  const MLOutcomeFeedbackDialog({
    super.key,
    required this.mlExampleId,
    required this.clientId,
  });

  @override
  ConsumerState<MLOutcomeFeedbackDialog> createState() =>
      _MLOutcomeFeedbackDialogState();
}

class _MLOutcomeFeedbackDialogState
    extends ConsumerState<MLOutcomeFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();

  double _adherence = 0.85;
  double _fatigue = 6.0;
  double _progress = 0.0;
  bool _injury = false;
  bool _tooHard = false;
  bool _tooEasy = false;

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.feedback, color: kPrimaryColor, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Feedback de Ejecución (ML)',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estos datos se usarán para mejorar las predicciones del motor IA.',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextColorSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                // Adherencia
                _buildSlider(
                  label: 'Adherencia (% de sets completados)',
                  value: _adherence,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  valueLabel: '${(_adherence * 100).toStringAsFixed(0)}%',
                  onChanged: (v) => setState(() => _adherence = v),
                ),

                // Fatiga
                _buildSlider(
                  label: 'Fatiga al final de semana (1-10)',
                  value: _fatigue,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  valueLabel: _fatigue.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _fatigue = v),
                ),

                // Progreso
                _buildSlider(
                  label: 'Progreso (kg o reps ganadas)',
                  value: _progress,
                  min: -5.0,
                  max: 10.0,
                  divisions: 30,
                  valueLabel: _progress >= 0
                      ? '+${_progress.toStringAsFixed(1)}'
                      : _progress.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _progress = v),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Flags
                CheckboxListTile(
                  title: const Text(
                    'Ocurrió lesión durante el plan',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _injury,
                  onChanged: (v) => setState(() => _injury = v ?? false),
                  dense: true,
                  activeColor: Colors.red,
                ),

                CheckboxListTile(
                  title: const Text(
                    'El plan fue muy duro',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _tooHard,
                  onChanged: (v) => setState(() => _tooHard = v ?? false),
                  dense: true,
                  activeColor: Colors.orange,
                ),

                CheckboxListTile(
                  title: const Text(
                    'El plan fue muy fácil',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _tooEasy,
                  onChanged: (v) => setState(() => _tooEasy = v ?? false),
                  dense: true,
                  activeColor: Colors.blue,
                ),

                const SizedBox(height: 16),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ML ID: ${widget.mlExampleId.substring(0, 16)}...',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: kTextColorSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _onSubmit,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Guardando...' : 'Guardar Feedback'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Chip(
              label: Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: kPrimaryColor.withValues(alpha: 0.2),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
          activeColor: kPrimaryColor,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final datasetService = ref.read(trainingDatasetServiceProvider);

      await datasetService.recordOutcome(
        exampleId: widget.mlExampleId,
        adherence: _adherence,
        fatigue: _fatigue,
        progress: _progress,
        injury: _injury,
        tooHard: _tooHard,
        tooEasy: _tooEasy,
        // TODO: Agregar weeklyFeedback si existe
        weeklyFeedback: null,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true = success

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feedback guardado para ML'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
