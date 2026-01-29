import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/dietary_state_models.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';

class DietaryTmbSection extends StatefulWidget {
  final String selectedFormulaKey;
  final Map<String, TMBFormulaInfo> tmbCalculations;
  final double calculatedAverageTMB;
  final double currentTMBValue;
  final String? recommendedFormulaKey;
  final ValueChanged<String> onFormulaSelected;
  final VoidCallback onShowRecommendation;

  const DietaryTmbSection({
    super.key,
    required this.selectedFormulaKey,
    required this.tmbCalculations,
    required this.calculatedAverageTMB,
    required this.currentTMBValue,
    required this.recommendedFormulaKey,
    required this.onFormulaSelected,
    required this.onShowRecommendation,
  });

  @override
  State<DietaryTmbSection> createState() => _DietaryTmbSectionState();
}

class _DietaryTmbSectionState extends State<DietaryTmbSection> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final List<String> selectableOptions =
        widget.tmbCalculations.entries
            .where((entry) => entry.value.value > 0)
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => a.compareTo(b));

    if (!selectableOptions.contains('Promedio')) {
      selectableOptions.add('Promedio');
    }

    final bool isCorrectlySelected =
        widget.recommendedFormulaKey == widget.selectedFormulaKey;

    return GlassContainer(
      height: 450,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(
                      title: 'FÓRMULA BASE',
                      textColor: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                    if (!isCorrectlySelected &&
                        widget.recommendedFormulaKey != null)
                      InkWell(
                        onTap: () {
                          widget.onFormulaSelected(
                            widget.recommendedFormulaKey!,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✨ Aplicada: ${widget.recommendedFormulaKey}',
                                style: const TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.white,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((255 * 0.2).round()),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  (255 * 0.1).round(),
                                ),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_fix_high,
                                size: 14,
                                color: kPrimaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Usar ${widget.recommendedFormulaKey}",
                                style: const TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (isCorrectlySelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Recomendada",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      // --- FIX ---
                      // Ensure the value is always in the list of items to prevent assertion error.
                      // If the selected key isn't in the options (e.g., during initial build),
                      // default to the first available option.
                      value:
                          selectableOptions.contains(widget.selectedFormulaKey)
                          ? widget.selectedFormulaKey
                          : selectableOptions.firstOrNull,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                      ),
                      dropdownColor: kAppBarColor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: selectableOptions.map((String value) {
                        final isRec = value == widget.recommendedFormulaKey;
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Text(value),
                              if (isRec) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        widget.onFormulaSelected(newValue);
                      },
                    ),
                  ),
                ),

                const Spacer(),

                const Text(
                  "Gasto Basal Estimado",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.currentTMBValue.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "kcal",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white24, thickness: 0.5),
                const SizedBox(height: 16),

                Theme(
                  data: ThemeData.dark(),
                  child: _buildCleanDescriptionInfo(),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            color: Colors.white10,
          ),

          // COLUMNA DERECHA
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(
                      title: 'COMPARATIVA DE FÓRMULAS',
                      textColor: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                    if (widget.recommendedFormulaKey != null)
                      InkWell(
                        onTap: widget.onShowRecommendation,
                        child: const Text(
                          "Ver análisis de la fórmula recomendada",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildTMBBarChartVertical()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDescriptionInfo() {
    TMBFormulaInfo? info;
    if (widget.selectedFormulaKey == 'Promedio') {
      info = const TMBFormulaInfo(
        key: 'Promedio',
        population: 'Promedio matemático de las fórmulas aplicables.',
        requires: 'Múltiples fuentes.',
        equation: 'TMB = Σ(fórmulas válidas) / n',
        value: 0.0,
      );
    } else {
      info = widget.tmbCalculations[widget.selectedFormulaKey];
    }
    if (info == null) return const SizedBox();
    final hasEquation = info.equation.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.population,
          style: TextStyle(
            color: kTextColor.withAlpha((255 * 0.7).round()),
            fontSize: 12,
            height: 1.4,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (hasEquation) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kPrimaryColor.withAlpha((255 * 0.3).round()),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.functions, size: 14, color: kPrimaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.equation,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (info.requires.isNotEmpty)
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 12,
                color: kPrimaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Variables: ${info.requires}',
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTMBBarChartVertical() {
    if (widget.tmbCalculations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.shade700.withAlpha((255 * 0.2).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade700, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin datos antropométricos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pueden calcular fórmulas TMB sin datos básicos.\n\nNecesitas crear un registro de Antropometría con:\n• Peso\n• Estatura\n• Fecha de nacimiento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final List<MapEntry<String, TMBFormulaInfo>> validEntries =
        widget.tmbCalculations.entries
            .where((entry) => entry.value.value > 0)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    validEntries.add(
      MapEntry(
        'Promedio',
        TMBFormulaInfo(
          key: 'Promedio',
          population: '',
          requires: '',
          value: widget.calculatedAverageTMB,
        ),
      ),
    );

    if (validEntries.isEmpty) return const SizedBox();

    double maxValue = validEntries
        .map((e) => e.value.value)
        .reduce((a, b) => a > b ? a : b);
    final double maxPossibleValue = maxValue * 1.11;
    double maxY = (maxPossibleValue / 100).ceil() * 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 500,
              getTitlesWidget: (value, meta) => value == 0
                  ? const SizedBox()
                  : Text(
                      '${value.toInt()}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= validEntries.length) {
                  return const SizedBox();
                }

                String label = validEntries[index].key;
                if (label.contains('Mifflin')) {
                  label = 'Mifflin\nSt. Jeor';
                } else if (label.contains('Harris')) {
                  label = 'Harris\nBenedict';
                } else if (label.contains('Katch')) {
                  label = 'Katch\nMcArdle';
                } else if (label.contains('Müller')) {
                  label = 'Müller';
                }

                final bool isSelected =
                    validEntries[index].key == widget.selectedFormulaKey;

                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: validEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final key = entry.value.key;
          final value = entry.value.value.value;
          final isSelected = key == widget.selectedFormulaKey;
          final isTouched = index == touchedIndex;

          final double finalHeight = isTouched ? (value * 1.1) : value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: finalHeight,
                color: isSelected ? kPrimaryColor.withAlpha(180) : Colors.white,
                width: isTouched ? 28 : (isSelected ? 24 : 18),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.transparent,
                ),
              ),
            ],
            showingTooltipIndicators: isTouched || isSelected ? [0] : [],
          );
        }).toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipMargin: 4,
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Validación de seguridad para evitar index out of range
              if (groupIndex < 0 || groupIndex >= validEntries.length) {
                return null;
              }
              if (groupIndex != touchedIndex &&
                  validEntries[groupIndex].key != widget.selectedFormulaKey) {
                return null;
              }
              final originalValue = validEntries[groupIndex].value.value;
              return BarTooltipItem(
                '${originalValue.round()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.spot == null) {
                touchedIndex = -1;
              } else {
                touchedIndex = response.spot!.touchedBarGroupIndex;
              }
            });
          },
        ),
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
    );
  }
}
