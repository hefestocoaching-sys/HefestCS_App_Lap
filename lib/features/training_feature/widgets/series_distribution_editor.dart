import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Editor de distribución de series por intensidad (Heavy/Medium/Light)
///
/// Permite ajustar el porcentaje de series pesadas, medias y ligeras
/// basado en evidencia científica (Schoenfeld, Krieger, Burd).
class SeriesDistributionEditor extends StatefulWidget {
  final Map<String, dynamic> trainingExtra;
  final Function(Map<String, int>) onDistributionChanged;

  const SeriesDistributionEditor({
    super.key,
    required this.trainingExtra,
    required this.onDistributionChanged,
  });

  @override
  State<SeriesDistributionEditor> createState() =>
      _SeriesDistributionEditorState();
}

class _SeriesDistributionEditorState extends State<SeriesDistributionEditor> {
  int _heavyPercent = 20;
  int _mediumPercent = 60;
  int _lightPercent = 20;

  @override
  void initState() {
    super.initState();
    _loadFromExtra();
  }

  void _loadFromExtra() {
    final split =
        widget.trainingExtra[TrainingExtraKeys.seriesTypePercentSplit] as Map?;
    if (split != null) {
      setState(() {
        _heavyPercent = (split['heavy'] as num?)?.toInt() ?? 20;
        _mediumPercent = (split['medium'] as num?)?.toInt() ?? 60;
        _lightPercent = (split['light'] as num?)?.toInt() ?? 20;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HEADER: Explicación
          _buildExplanationCard(),

          const SizedBox(height: 24),

          // EDITOR: Sliders interactivos
          _buildDistributionSliders(),

          const SizedBox(height: 24),

          // PREVIEW: Cómo se aplicará
          _buildPreviewTable(),

          const SizedBox(height: 24),

          // PRESETS: Objetivos comunes
          _buildPresetButtons(),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: kPrimaryColor),
              SizedBox(width: 12),
              Text(
                'Distribución de Intensidad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Las series se clasifican en 3 intensidades según evidencia científica:',
            style: TextStyle(color: kTextColorSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _buildIntensityExplanation(
            '🔴 PESADAS (Heavy)',
            '6-8 reps, 80-85% 1RM',
            'Fuerza + Hipertrofia miofibrilar',
            'Schoenfeld et al. (2021)',
          ),
          _buildIntensityExplanation(
            '🟡 MEDIAS (Medium)',
            '8-12 reps, 70-80% 1RM',
            'Hipertrofia óptima (zona principal)',
            'Krieger (2010) - Meta-análisis',
          ),
          _buildIntensityExplanation(
            '🟢 LIGERAS (Light)',
            '12-20 reps, 60-70% 1RM',
            'Hipertrofia sarcoplásmica + resistencia',
            'Burd et al. (2010)',
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityExplanation(
    String title,
    String range,
    String benefit,
    String reference,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: title.contains('PESADAS')
                  ? Colors.red
                  : title.contains('MEDIAS')
                  ? Colors.orange
                  : Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: const TextStyle(
                    fontSize: 11,
                    color: kTextColorSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit,
                  style: const TextStyle(fontSize: 11, color: kTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  reference,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextColorSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSliders() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Ajusta la distribución según objetivo del asesorado',
            style: TextStyle(
              color: kTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Slider PESADAS
          _buildSlider(
            label: '🔴 Series Pesadas',
            value: _heavyPercent.toDouble(),
            color: Colors.red,
            onChanged: (value) {
              setState(() {
                _heavyPercent = value.round();
                _rebalance();
                _notifyChange();
              });
            },
          ),

          // Slider MEDIAS
          _buildSlider(
            label: '🟡 Series Medias',
            value: _mediumPercent.toDouble(),
            color: Colors.orange,
            onChanged: (value) {
              setState(() {
                _mediumPercent = value.round();
                _rebalance();
                _notifyChange();
              });
            },
          ),

          // Slider LIGERAS
          _buildSlider(
            label: '🟢 Series Ligeras',
            value: _lightPercent.toDouble(),
            color: Colors.green,
            onChanged: (value) {
              setState(() {
                _lightPercent = value.round();
                _rebalance();
                _notifyChange();
              });
            },
          ),

          const SizedBox(height: 16),

          // Validación visual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_heavyPercent + _mediumPercent + _lightPercent == 100)
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  (_heavyPercent + _mediumPercent + _lightPercent == 100)
                      ? Icons.check_circle
                      : Icons.warning,
                  color: (_heavyPercent + _mediumPercent + _lightPercent == 100)
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: ${_heavyPercent + _mediumPercent + _lightPercent}% ${(_heavyPercent + _mediumPercent + _lightPercent == 100) ? '✓' : '(debe sumar 100%)'}',
                  style: const TextStyle(color: kTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Color color,
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
              style: const TextStyle(color: kTextColor, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          max: 100,
          divisions: 20,
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.3),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreviewTable() {
    final targetSetsByMuscle =
        widget.trainingExtra['targetSetsByMuscle'] as Map<String, dynamic>? ??
        {};

    if (targetSetsByMuscle.isEmpty) {
      return _buildEmptyPreviewState();
    }

    final muscles = targetSetsByMuscle.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 PREVISUALIZACIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cómo se distribuirán las series según los porcentajes configurados:',
                  style: TextStyle(color: kTextColorSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Table(
            border: TableBorder.all(
              color: kPrimaryColor.withValues(alpha: 0.2),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                ),
                children: [
                  _tableCell('Músculo', isHeader: true),
                  _tableCell('Total', isHeader: true),
                  _tableCell('🔴 Pesadas', isHeader: true),
                  _tableCell('🟡 Medias', isHeader: true),
                  _tableCell('🟢 Ligeras', isHeader: true),
                ],
              ),
              // Rows con datos reales
              ...muscles.map((muscle) {
                final total =
                    (targetSetsByMuscle[muscle] as num?)?.toInt() ?? 0;
                final heavy = (total * _heavyPercent / 100).round();
                final medium = (total * _mediumPercent / 100).round();
                final light = total - heavy - medium;

                return TableRow(
                  children: [
                    _tableCell(_formatMuscleName(muscle)),
                    _tableCell('$total sets'),
                    _tableCell('$heavy', color: Colors.red.shade300),
                    _tableCell('$medium', color: Colors.orange.shade300),
                    _tableCell('$light', color: Colors.green.shade300),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreviewState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Genera un plan primero para ver la distribución',
              style: TextStyle(color: kTextColorSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ve a la pestaña "Semanal" y haz click en "Generar Plan"',
              style: TextStyle(
                color: kTextColorSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMuscleName(String muscle) {
    final names = {
      'chest': 'Pecho',
      'lats': 'Dorsales',
      'midBack': 'Espalda Media',
      'lowBack': 'Lumbar',
      'traps': 'Trapecios',
      'frontDelts': 'Hombro Frontal',
      'sideDelts': 'Hombro Lateral',
      'rearDelts': 'Hombro Posterior',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiosurales',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'abs': 'Abdominales',
    };
    return names[muscle] ?? muscle.toUpperCase();
  }

  Widget _tableCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? (isHeader ? kPrimaryColor : kTextColor),
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
      ),
    );
  }

  Widget _buildPresetButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _presetButton('Fuerza', heavy: 40, medium: 40, light: 20),
        _presetButton('Hipertrofia Clásica', heavy: 20, medium: 60, light: 20),
        _presetButton('Resistencia Muscular', heavy: 10, medium: 30, light: 60),
        _presetButton('Balanceado', heavy: 30, medium: 50, light: 20),
      ],
    );
  }

  Widget _presetButton(
    String label, {
    required int heavy,
    required int medium,
    required int light,
  }) {
    final isActive =
        _heavyPercent == heavy &&
        _mediumPercent == medium &&
        _lightPercent == light;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _heavyPercent = heavy;
          _mediumPercent = medium;
          _lightPercent = light;
          _notifyChange();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? kPrimaryColor : kCardColor,
        foregroundColor: isActive ? Colors.white : kTextColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$heavy% / $medium% / $light%',
            style: TextStyle(
              fontSize: 10,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.8)
                  : kTextColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _rebalance() {
    // Auto-ajustar para que sume 100%
    int total = _heavyPercent + _mediumPercent + _lightPercent;
    if (total != 100) {
      int diff = 100 - total;
      _mediumPercent += diff; // Ajustar medias por defecto
      _mediumPercent = _mediumPercent.clamp(0, 100);
    }
  }

  void _notifyChange() {
    widget.onDistributionChanged({
      'heavy': _heavyPercent,
      'medium': _mediumPercent,
      'light': _lightPercent,
    });
  }
}
