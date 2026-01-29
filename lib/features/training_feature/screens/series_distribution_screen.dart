import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/features/training_feature/domain/volume_intelligence/models/intensity_distribution.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/section_title.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/deep_merge.dart';

const muscleLabelEs = {
  'chest': 'Pectoral',
  'back': 'Espalda',
  'lats': 'Dorsal ancho',
  'traps': 'Trapecio',
  'shoulders': 'Hombros',
  'biceps': 'Bíceps',
  'triceps': 'Tríceps',
  'forearms': 'Antebrazo',
  'quads': 'Cuádriceps',
  'hamstrings': 'Isquiotibiales',
  'glutes': 'Glúteos',
  'calves': 'Pantorrillas',
  'abs': 'Abdomen',
  'fullBody': 'Cuerpo completo',
};

/// Pantalla de distribución de intensidad (Semana 3)
///
/// Distribuye el volumen total (targetSetsByMuscle) en:
/// - Series pesadas (15-30%)
/// - Series moderadas (40-70%)
/// - Series ligeras (15-30%)
///
/// NO recalcula MEV/MRV ni genera sets adicionales.
class SeriesDistributionScreen extends ConsumerStatefulWidget {
  const SeriesDistributionScreen({super.key});

  @override
  ConsumerState<SeriesDistributionScreen> createState() =>
      _SeriesDistributionScreenState();
}

class _SeriesDistributionScreenState
    extends ConsumerState<SeriesDistributionScreen> {
  late IntensityDistribution _distribution;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client != null) {
        final trainingLevel =
            client.training.trainingLevel ?? TrainingLevel.intermediate;
        _distribution = IntensityDistribution.forLevel(trainingLevel);
        _initialized = true;
      }
    }
  }

  /// Actualiza un porcentaje asegurando que la suma sea 100%
  void _updatePercentage(String type, double newValue) {
    setState(() {
      if (type == 'heavy') {
        // Ajustar los otros dos para mantener suma en 100%
        final remaining = 1.0 - newValue;
        final ratio =
            remaining / (_distribution.moderatePct + _distribution.lightPct);
        _distribution = _distribution.copyWith(
          heavyPct: newValue,
          moderatePct: _distribution.moderatePct * ratio,
          lightPct: _distribution.lightPct * ratio,
        );
      } else if (type == 'moderate') {
        final remaining = 1.0 - newValue;
        final ratio =
            remaining / (_distribution.heavyPct + _distribution.lightPct);
        _distribution = _distribution.copyWith(
          moderatePct: newValue,
          heavyPct: _distribution.heavyPct * ratio,
          lightPct: _distribution.lightPct * ratio,
        );
      } else if (type == 'light') {
        final remaining = 1.0 - newValue;
        final ratio =
            remaining / (_distribution.heavyPct + _distribution.moderatePct);
        _distribution = _distribution.copyWith(
          lightPct: newValue,
          heavyPct: _distribution.heavyPct * ratio,
          moderatePct: _distribution.moderatePct * ratio,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientsProvider).value?.activeClient;
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text("Cliente no disponible.")),
      );
    }

    // Leer targetSetsByMuscle (calculado en PRE-FASE 3)
    final targetSetsByMuscleRaw = client.training.extra['targetSetsByMuscle'];
    final targetSetsByMuscle = targetSetsByMuscleRaw is Map
        ? Map<String, double>.from(targetSetsByMuscleRaw)
        : <String, double>{};

    if (targetSetsByMuscle.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Distribución de Intensidad"),
          backgroundColor: kAppBarColor,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No hay datos de volumen disponibles.\n'
              'Primero genera un plan de entrenamiento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextColorSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Distribución de Intensidad (P/M/L)"),
        backgroundColor: kAppBarColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 32),

            const SectionTitle(title: "Distribución de Intensidad"),
            _buildDistributionControls(),
            const SizedBox(height: 24),

            if (!_distribution.isValid) _buildValidationWarning(),

            const SizedBox(height: 32),
            const SectionTitle(title: "Desglose por Músculo"),
            _buildMuscleBreakdownTable(targetSetsByMuscle),

            const SizedBox(height: 32),
            _buildActionButtons(targetSetsByMuscle),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Distribución de Intensidad',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Distribuye el volumen total en series pesadas, moderadas y ligeras '
            'sin alterar el número total de sets. Los porcentajes deben sumar 100%.',
            style: TextStyle(color: kTextColorSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botones de presets
          Row(
            children: [
              const Text(
                'Presets: ',
                style: TextStyle(color: kTextColor, fontSize: 14),
              ),
              const SizedBox(width: 12),
              _presetButton('Principiante', TrainingLevel.beginner),
              const SizedBox(width: 8),
              _presetButton('Intermedio', TrainingLevel.intermediate),
              const SizedBox(width: 8),
              _presetButton('Avanzado', TrainingLevel.advanced),
            ],
          ),
          const SizedBox(height: 24),

          // Sliders
          _buildPercentageSlider(
            'Series Pesadas',
            _distribution.heavyPct,
            IntensityDistribution.minHeavyPct,
            IntensityDistribution.maxHeavyPct,
            (value) => _updatePercentage('heavy', value),
            Colors.red.shade400,
          ),
          const SizedBox(height: 16),

          _buildPercentageSlider(
            'Series Moderadas',
            _distribution.moderatePct,
            IntensityDistribution.minModeratePct,
            IntensityDistribution.maxModeratePct,
            (value) => _updatePercentage('moderate', value),
            Colors.orange.shade400,
          ),
          const SizedBox(height: 16),

          _buildPercentageSlider(
            'Series Ligeras',
            _distribution.lightPct,
            IntensityDistribution.minLightPct,
            IntensityDistribution.maxLightPct,
            (value) => _updatePercentage('light', value),
            Colors.green.shade400,
          ),

          const SizedBox(height: 16),
          Divider(color: kPrimaryColor.withValues(alpha: 0.3)),
          const SizedBox(height: 8),

          // Resumen total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  color: kTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((_distribution.heavyPct + _distribution.moderatePct + _distribution.lightPct) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _distribution.isValid
                      ? kPrimaryColor
                      : Colors.red.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String label, TrainingLevel level) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _distribution = IntensityDistribution.forLevel(level);
        });
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildPercentageSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: kTextColor, fontSize: 15),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            inactiveTrackColor: color.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 30, // Incrementos de ~0.5%
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mín: ${(min * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
            ),
            Text(
              'Máx: ${(max * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValidationWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ Los porcentajes deben sumar exactamente 100%',
              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleBreakdownTable(Map<String, double> targetSetsByMuscle) {
    final muscles = targetSetsByMuscle.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glass(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            kPrimaryColor.withValues(alpha: 0.1),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Músculo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Pesadas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Moderadas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Ligeras',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              numeric: true,
            ),
          ],
          rows: muscles.map((muscle) {
            final totalSets = targetSetsByMuscle[muscle]!.round();
            final breakdown = _distribution.calculateSets(totalSets);

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    muscleLabelEs[muscle] ?? muscle,
                    style: const TextStyle(color: kTextColorSecondary),
                  ),
                ),
                DataCell(
                  Text(
                    totalSets.toString(),
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    breakdown.heavy.toString(),
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
                DataCell(
                  Text(
                    breakdown.moderate.toString(),
                    style: TextStyle(color: Colors.orange.shade400),
                  ),
                ),
                DataCell(
                  Text(
                    breakdown.light.toString(),
                    style: TextStyle(color: Colors.green.shade400),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, double> targetSetsByMuscle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            final trainingLevel =
                ref
                    .read(clientsProvider)
                    .value
                    ?.activeClient
                    ?.training
                    .trainingLevel ??
                TrainingLevel.intermediate;
            setState(() {
              _distribution = IntensityDistribution.forLevel(trainingLevel);
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Restablecer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kTextColorSecondary,
            side: BorderSide(color: kTextColorSecondary.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: !_distribution.isValid
              ? null
              : () async {
                  // Calcular distribución por músculo
                  final intensityBreakdown = <String, Map<String, int>>{};

                  for (final entry in targetSetsByMuscle.entries) {
                    final muscle = entry.key;
                    final totalSets = entry.value.round();
                    final breakdown = _distribution.calculateSets(totalSets);

                    intensityBreakdown[muscle] = {
                      'heavy': breakdown.heavy,
                      'moderate': breakdown.moderate,
                      'light': breakdown.light,
                      'total': breakdown.total,
                    };
                  }

                  // Guardar en training.extra con deep merge
                  final messenger = ScaffoldMessenger.of(context);
                  await ref
                      .read(clientsProvider.notifier)
                      .updateActiveClient(
                        (prev) => prev.copyWith(
                          training: prev.training.copyWith(
                            extra: deepMerge(prev.training.extra, {
                              'intensityDistribution': {
                                'heavyPct': _distribution.heavyPct,
                                'moderatePct': _distribution.moderatePct,
                                'lightPct': _distribution.lightPct,
                              },
                              'intensityBreakdown': intensityBreakdown,
                            }),
                          ),
                        ),
                      );

                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("✅ Distribución de intensidad guardada"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
          icon: const Icon(Icons.save),
          label: const Text('Guardar Distribución'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  BoxDecoration _glass() {
    return BoxDecoration(
      color: kAppBarColor.withValues(alpha: 0.43),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
    );
  }
}
