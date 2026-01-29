import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';
import 'dart:math';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Clase interna para gestionar el estado de la distribución de series de un músculo.
/// Refactorizado a inmutable para mejor gestión de estado y prevención de bugs.
class SeriesDistribution {
  final double heavyPercent;
  final double mediumPercent;
  final double lightPercent;

  const SeriesDistribution({
    this.heavyPercent = 34.0,
    this.mediumPercent = 33.0,
    this.lightPercent = 33.0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesDistribution &&
        other.heavyPercent == heavyPercent &&
        other.mediumPercent == mediumPercent &&
        other.lightPercent == lightPercent;
  }

  @override
  int get hashCode => Object.hash(heavyPercent, mediumPercent, lightPercent);

  SeriesDistribution copyWith({double? heavy, double? medium, double? light}) {
    return SeriesDistribution(
      heavyPercent: heavy ?? heavyPercent,
      mediumPercent: medium ?? mediumPercent,
      lightPercent: light ?? lightPercent,
    );
  }
}

/// Un widget profesional y científico para el CÁLCULO DE SERIES de entrenamiento.
///
/// Permite distribuir un número base de series para diferentes grupos musculares
/// en porcentajes de intensidad (pesada, media, ligera) usando sliders interactivos.
/// La lógica de ajuste mantiene la suma de los porcentajes en 100%.
class SeriesCalculatorTable extends StatefulWidget {
  /// Mapa con el número de series base por grupo muscular.
  /// Ejemplo: `{ "Glúteo": 18, "Femoral": 12 }`
  final Map<String, int> baseSeries;

  /// Callback que se invoca cada vez que los valores cambian.
  /// Devuelve un mapa con las series calculadas por intensidad para cada músculo.
  final Function(Map<String, Map<String, double>> output) onUpdate;

  const SeriesCalculatorTable({
    super.key,
    required this.baseSeries,
    required this.onUpdate,
  });

  @override
  State<SeriesCalculatorTable> createState() => _SeriesCalculatorTableState();
}

class _SeriesCalculatorTableState extends State<SeriesCalculatorTable> {
  late Map<String, SeriesDistribution> _distributions;

  @override
  void initState() {
    super.initState();
    _distributions = {
      for (var muscle in widget.baseSeries.keys)
        muscle: const SeriesDistribution(
          heavyPercent: 34,
          mediumPercent: 33,
          lightPercent: 33,
        ),
    };
    // Notifica al padre los valores iniciales después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  @override
  void didUpdateWidget(covariant SeriesCalculatorTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el mapa de series base cambia (p. ej. por un ajuste inteligente),
    // actualizamos las distribuciones para que coincidan, pero preservando
    // los porcentajes existentes para los músculos que no han cambiado.
    if (widget.baseSeries != oldWidget.baseSeries) {
      final newDistributions = <String, SeriesDistribution>{};
      for (final muscle in widget.baseSeries.keys) {
        // Si el músculo ya tenía una distribución, la reutilizamos.
        // Si es un músculo nuevo, creamos una por defecto.
        newDistributions[muscle] =
            _distributions[muscle] ?? const SeriesDistribution();
      }
      setState(() {
        _distributions = newDistributions;
      });

      // Notificamos al padre con los nuevos totales calculados.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyParent();
      });
    }
  }

  /// Notifica al widget padre con los datos calculados más recientes.
  void _notifyParent() {
    final output = <String, Map<String, double>>{};
    _distributions.forEach((muscle, distribution) {
      final base = widget.baseSeries[muscle]!;
      output[muscle] = {
        'heavy': (base * distribution.heavyPercent / 100.0),
        'medium': (base * distribution.mediumPercent / 100.0),
        'light': (base * distribution.lightPercent / 100.0),
      };
    });
    widget.onUpdate(output);
  }

  /// Lógica central para ajustar los porcentajes de los sliders.
  /// Cuando un slider se mueve, los otros dos se ajustan para que la suma siempre sea 100.
  void _updateDistribution(String muscle, double newValue, String type) {
    setState(() {
      final currentDist = _distributions[muscle]!;
      double h = currentDist.heavyPercent;
      double m = currentDist.mediumPercent;
      double l = currentDist.lightPercent;

      // Redondea el nuevo valor para evitar saltos inesperados en el slider.
      final roundedValue = (newValue / 5).round() * 5.0;

      if (type == 'heavy') {
        h = roundedValue;
        m = min(m, max(0, 100.0 - h));
        l = 100.0 - h - m;
      } else if (type == 'medium') {
        m = roundedValue;
        h = min(h, max(0, 100.0 - m));
        l = 100.0 - h - m;
      } else {
        // 'light'
        l = roundedValue;
        h = min(h, max(0, 100.0 - l));
        m = 100.0 - h - l;
      }

      // Actualizamos el mapa con una nueva instancia inmutable
      _distributions[muscle] = SeriesDistribution(
        heavyPercent: h,
        mediumPercent: m,
        lightPercent: l,
      );
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    // No se necesita un FormBuilder si no hay un botón de submit,
    // pero lo mantenemos por si se añade validación en el futuro.
    return FormBuilder(
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: "DISTRIBUCIÓN DE SERIES POR INTENSIDAD"),
            const SizedBox(height: 20),
            _buildHeader(),
            const Divider(color: kBorderColor, height: 24),
            ...widget.baseSeries.keys.map((muscle) {
              return MuscleDistributionRow(
                muscle: muscle,
                baseSeries: widget.baseSeries[muscle]!,
                distribution: _distributions[muscle]!,
                onDistributionChanged: _updateDistribution,
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Construye la cabecera de la tabla.
  Widget _buildHeader() {
    const headerStyle = TextStyle(
      color: kTextColorSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('MÚSCULO', style: headerStyle)),
          Expanded(
            flex: 2,
            child: Text(
              'BASE',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              '% DISTRIBUCIÓN',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'SERIES FINALES',
              style: headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget extraído para optimizar el rendimiento y organizar el código.
/// Al ser un widget separado, Flutter puede gestionar mejor su ciclo de vida.
class MuscleDistributionRow extends StatelessWidget {
  final String muscle;
  final int baseSeries;
  final SeriesDistribution distribution;
  final Function(String muscle, double value, String type)
  onDistributionChanged;

  const MuscleDistributionRow({
    super.key,
    required this.muscle,
    required this.baseSeries,
    required this.distribution,
    required this.onDistributionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final heavySeries = (baseSeries * distribution.heavyPercent / 100.0);
    final mediumSeries = (baseSeries * distribution.mediumPercent / 100.0);
    final lightSeries = (baseSeries * distribution.lightPercent / 100.0);
    final totalSeries = heavySeries + mediumSeries + lightSeries;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Columna 1: Nombre del Músculo
          Expanded(
            flex: 3,
            child: Text(
              muscle,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Columna 2: Series Base
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kBorderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  baseSeries.toString(),
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Columna 3: Sliders de Distribución
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _buildSliderRow(
                  context,
                  'heavy',
                  muscle,
                  distribution.heavyPercent,
                  Colors.red.shade300,
                ),
                _buildSliderRow(
                  context,
                  'medium',
                  muscle,
                  distribution.mediumPercent,
                  Colors.orange.shade300,
                ),
                _buildSliderRow(
                  context,
                  'light',
                  muscle,
                  distribution.lightPercent,
                  Colors.green.shade300,
                ),
              ],
            ),
          ),
          // Columna 4: Series Calculadas
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${heavySeries.toStringAsFixed(1)} P',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${mediumSeries.toStringAsFixed(1)} M',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${lightSeries.toStringAsFixed(1)} L',
                  style: TextStyle(
                    color: Colors.green.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(color: kBorderColor, height: 8),
                Text(
                  '${totalSeries.toStringAsFixed(1)} Total',
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila de slider individual (Pesado, Medio o Ligero).
  Widget _buildSliderRow(
    BuildContext context,
    String type,
    String muscle,
    double percent,
    Color color,
  ) {
    return Row(
      children: [
        Text(
          '${type[0].toUpperCase()}:',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FormBuilderSlider(
            name: '${muscle}_$type',
            min: 0,
            max: 100,
            initialValue: percent,
            divisions: 20, // Pasos de 5%
            onChanged: (value) {
              if (value != null) onDistributionChanged(muscle, value, type);
            },
            activeColor: color,
            inactiveColor: color.withValues(alpha: 0.3),
            decoration: hcsDecoration(context, contentPadding: EdgeInsets.zero)
                .copyWith(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${percent.toInt()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
