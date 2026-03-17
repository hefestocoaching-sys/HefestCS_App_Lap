import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/services/macrocycle_template_service.dart';
import 'package:hcs_app_lap/domain/training/macrocycle_calculator.dart';
import 'package:hcs_app_lap/domain/training/macrocycle_week.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Widget de demostración que muestra el flujo completo:
/// VOP base (Tab 1) → Macrocycle (semana) → Volumen efectivo
///
/// USO: Probar integración en contexto de entrenamiento actual.
/// NO es parte del UI principal, solo referencia educativa.
class MacrocycleWeeklyCalculatorExample extends StatefulWidget {
  /// VOP base de un músculo (viene de Tab 1)
  final double baseVopPerMuscle;

  /// Distribución de intensidades (viene de Tab 2)
  final Map<String, double> intensitySplit;

  const MacrocycleWeeklyCalculatorExample({
    super.key,
    this.baseVopPerMuscle = 10.0,
    this.intensitySplit = const {'heavy': 0.25, 'medium': 0.5, 'light': 0.25},
  });

  @override
  State<MacrocycleWeeklyCalculatorExample> createState() =>
      _MacrocycleWeeklyCalculatorExampleState();
}

class _MacrocycleWeeklyCalculatorExampleState
    extends State<MacrocycleWeeklyCalculatorExample> {
  late List<MacrocycleWeek> _macrocycle;
  int _selectedWeekNumber = 5; // Ejemplo: semana 5 (HF1)

  @override
  void initState() {
    super.initState();
    _macrocycle = MacrocycleTemplateService.buildDefaultMacrocycle();
  }

  @override
  Widget build(BuildContext context) {
    final selectedWeek = MacrocycleTemplateService.getWeekByNumber(
      _macrocycle,
      _selectedWeekNumber,
    );

    if (selectedWeek == null) {
      return const Center(child: Text('Semana no encontrada'));
    }

    final summary = MacrocycleWeekSummary.calculate(
      week: selectedWeek,
      baseVop: widget.baseVopPerMuscle,
      intensitySplit: widget.intensitySplit,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelector(),
          const SizedBox(height: 16),
          _buildFlowCard(summary),
          const SizedBox(height: 16),
          _buildExplanation(),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona una semana',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _selectedWeekNumber,
              decoration: hcsDecoration(
                context,
                labelText: 'Semana del macrocycle',
              ),
              onChanged: (week) {
                if (week != null) {
                  setState(() => _selectedWeekNumber = week);
                }
              },
              items: _macrocycle
                  .map(
                    (w) => DropdownMenuItem(
                      value: w.weekNumber,
                      child: Text(
                        'W${w.weekNumber} · ${_blockLabel(w.block)} · ${w.volumeMultiplier}×',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowCard(MacrocycleWeekSummary summary) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cálculo de volumen efectivo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _flowStep(
              '1. VOP Base (Tab 1)',
              '${summary.baseVop.toStringAsFixed(1)} series',
              Colors.green,
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '×',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 8),
            _flowStep(
              '2. Multiplicador Macrocycle',
              '${summary.week.volumeMultiplier}×',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '=',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 8),
            _flowStep(
              '3. VOP Efectivo (esta semana)',
              '${summary.effectiveVop.toStringAsFixed(1)} series',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _flowStep(
              '4. Distribución (Tab 2, SIN cambios)',
              'Pesadas: ${summary.distribution['heavy']} | '
                  'Medias: ${summary.distribution['medium']} | '
                  'Ligeras: ${summary.distribution['light']}',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _flowStep(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return Card(
      color: Colors.amber.withValues(alpha: 0.05),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text(
                  'Cómo funciona',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '• VOP base es fijo (viene de la evaluación motor)',
              style: TextStyle(fontSize: 10, color: kTextColorSecondary),
            ),
            SizedBox(height: 4),
            Text(
              '• Macrocycle multiplica el VOP según estrategia semanal',
              style: TextStyle(fontSize: 10, color: kTextColorSecondary),
            ),
            SizedBox(height: 4),
            Text(
              '• Distribución (Pesadas/Medias/Ligeras) NO cambia',
              style: TextStyle(fontSize: 10, color: kTextColorSecondary),
            ),
            SizedBox(height: 4),
            Text(
              '• VME/VMR son SOLO referencias fisiológicas',
              style: TextStyle(fontSize: 10, color: kTextColorSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _blockLabel(MacroBlock block) {
    return switch (block) {
      MacroBlock.AA => 'AA',
      MacroBlock.HF1 => 'HF1',
      MacroBlock.HF2 => 'HF2',
      MacroBlock.HF3 => 'HF3',
      MacroBlock.HF4 => 'HF4',
      MacroBlock.APC1 => 'APC1',
      MacroBlock.APC2 => 'APC2',
      MacroBlock.APC3 => 'APC3',
      MacroBlock.APC4 => 'APC4',
      MacroBlock.APC5 => 'APC5',
      MacroBlock.PC => 'PC',
    };
  }
}
