// lib/utils/widgets/analyzed_text_field.dart
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/biochemistry_analyzer.dart';
import 'package:hcs_app_lap/utils/theme.dart';

// Asegúrate de que esta ruta sea correcta según tu estructura de carpetas
import 'package:hcs_app_lap/utils/widgets/bio_analysis_result.dart';

class AnalyzedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String biomarkerKey;
  final String? gender;
  final int? age;
  final TextInputType keyboardType;
  final String? hintText;
  // NUEVA PROPIEDAD
  final bool readOnly;

  const AnalyzedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.biomarkerKey,
    this.gender,
    this.age,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.hintText,
    // Inicializamos en false por defecto
    this.readOnly = false,
  });

  @override
  State<AnalyzedTextField> createState() => _AnalyzedTextFieldState();
}

class _AnalyzedTextFieldState extends State<AnalyzedTextField> {
  BioAnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_analyzeValue);
    // Analizamos el valor inicial (útil para campos calculados que ya traen texto)
    _analyzeValue();
  }

  @override
  void didUpdateWidget(covariant AnalyzedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_analyzeValue);
      widget.controller.addListener(_analyzeValue);
      _analyzeValue();
    }
    // Si cambia el género o la edad, re-analizamos
    if (widget.gender != oldWidget.gender || widget.age != oldWidget.age) {
      _analyzeValue();
    }
  }

  void _analyzeValue() {
    final double? value = double.tryParse(widget.controller.text);
    final newResult = BiochemistryAnalyzer.analyze(
      widget.biomarkerKey,
      value,
      gender: widget.gender,
      // Si tu analyzer soporta edad, pásala aquí también
    );

    final bool hasChanged = _result != newResult;

    if (hasChanged) {
      if (mounted) {
        setState(() {
          _result = newResult;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_analyzeValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          // AQUÍ USAMOS LA PROPIEDAD READONLY
          readOnly: widget.readOnly,
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration()
              .applyDefaults(Theme.of(context).inputDecorationTheme)
              .copyWith(hintText: widget.hintText),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: (_result != null)
              ? _buildResultBox(_result!)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildResultBox(BioAnalysisResult result) {
    IconData icon;
    switch (result.status) {
      case BioStatus.optimal:
        icon = Icons.check_circle;
        break;
      case BioStatus.normal:
        icon = Icons.check_circle_outline;
        break;
      case BioStatus.low:
      case BioStatus.high:
        icon = Icons.warning_amber_rounded;
        break;
      case BioStatus.criticallyLow:
      case BioStatus.criticallyHigh:
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(top: 8.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: result.color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: result.color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: result.color, size: 20),
              const SizedBox(width: 8),
              Text(
                result.status.name.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: result.color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.interpretation,
            style: TextStyle(color: kTextColor.withAlpha(229), fontSize: 13),
          ),
          if (result.recommendation.isNotEmpty) ...[
            const Divider(height: 16, color: kTextColorSecondary),
            Text(
              result.recommendation,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
