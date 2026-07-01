import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/macro_ranges.dart';
import 'package:fl_chart/fl_chart.dart';

/// Horizontal macro card showing inline dropdowns, insights, and chart in one line
class HorizontalMacroCard extends StatefulWidget {
  final String day;
  final DailyMacroSettings settings;
  final double weightKg;
  final Map<String, int>? dailyKcal;
  final double? maintenanceKcal;
  final double kcalAdjustment;
  final ValueChanged<DailyMacroSettings> onChanged;
  final bool isBase;
  final DailyMacroSettings? baseSettings; // Lunes (Base)

  const HorizontalMacroCard({
    super.key,
    required this.day,
    required this.settings,
    required this.weightKg,
    this.dailyKcal,
    this.maintenanceKcal,
    required this.kcalAdjustment,
    required this.onChanged,
    this.isBase = false,
    this.baseSettings,
  });

  @override
  State<HorizontalMacroCard> createState() => _HorizontalMacroCardState();
}

class _HorizontalMacroCardState extends State<HorizontalMacroCard> {
  late DailyMacroSettings _settings;
  late bool _isCustom; // true = personalizado, false = heredado de Lunes
  late String _proteinRangeName;
  late String _fatRangeName;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    // Si no es Lunes, usar isCustomizedFromBase; si es Lunes, nunca es custom
    _isCustom = !widget.isBase && widget.settings.isCustomizedFromBase;
    // Usar los nombres de rango guardados en el modelo, o calcularlos si están vacíos
    if (_settings.proteinRangeName.isEmpty || _settings.fatRangeName.isEmpty) {
      _updateRangeNames();
    } else {
      _proteinRangeName = _settings.proteinRangeName;
      _fatRangeName = _settings.fatRangeName;
    }
  }

  @override
  void didUpdateWidget(HorizontalMacroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los baseSettings cambiaron (modificaron Lunes) y no estamos en modo custom, sincronizar
    if (!_isCustom && widget.baseSettings != oldWidget.baseSettings) {
      _settings = widget.baseSettings ?? widget.settings;
      // Usar los nombres de rango guardados
      _proteinRangeName = _settings.proteinRangeName.isEmpty
          ? _findRangeName(_settings.proteinSelected, MacroRanges.protein)
          : _settings.proteinRangeName;
      _fatRangeName = _settings.fatRangeName.isEmpty
          ? _findRangeName(_settings.fatSelected, MacroRanges.lipids)
          : _settings.fatRangeName;
    }
  }

  void _updateRangeNames() {
    // Priorizar los nombres guardados en el modelo
    if (_settings.proteinRangeName.isNotEmpty) {
      _proteinRangeName = _settings.proteinRangeName;
    } else {
      _proteinRangeName = _findRangeName(
        _settings.proteinSelected,
        MacroRanges.protein,
      );
    }
    if (_settings.fatRangeName.isNotEmpty) {
      _fatRangeName = _settings.fatRangeName;
    } else {
      _fatRangeName = _findRangeName(_settings.fatSelected, MacroRanges.lipids);
    }
  }

  String _findRangeName(double value, Map<String, MacroRange> ranges) {
    for (final entry in ranges.entries) {
      if (value >= entry.value.min && value <= entry.value.max) {
        return entry.key;
      }
    }
    return ranges.keys.first;
  }

  double _getDayKcal() {
    if (widget.dailyKcal != null && widget.dailyKcal!.isNotEmpty) {
      final normalizedDay = widget.day
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');
      final entry = widget.dailyKcal!.entries.firstWhere(
        (e) =>
            e.key
                .toLowerCase()
                .replaceAll('á', 'a')
                .replaceAll('é', 'e')
                .replaceAll('í', 'i')
                .replaceAll('ó', 'o')
                .replaceAll('ú', 'u') ==
            normalizedDay,
        orElse: () => widget.dailyKcal!.entries.first,
      );
      return entry.value.toDouble();
    }
    return widget.maintenanceKcal ?? 0;
  }

  List<double> _generateGramageOptions(double min, double max) {
    final options = <double>[];
    double current = (min * 10).roundToDouble() / 10;
    final maxRounded = (max * 10).roundToDouble() / 10;
    while (current <= maxRounded) {
      options.add(double.parse(current.toStringAsFixed(1)));
      current = (current * 10 + 1).roundToDouble() / 10;
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final dayKcal = _getDayKcal();
    final proteinG = _settings.proteinSelected * widget.weightKg;
    final fatG = _settings.fatSelected * widget.weightKg;
    final proteinKcal = proteinG * 4;
    final fatKcal = fatG * 9;
    final carbKcal = dayKcal - proteinKcal - fatKcal;
    final carbG = carbKcal / 4;
    final carbGperKg = carbG / widget.weightKg;
    final totalKcal = proteinKcal + fatKcal + carbKcal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isBase ? kPrimaryColor.withAlpha(150) : kBorderColor,
          width: widget.isBase ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Header + Badge
          SizedBox(
            width: 35,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.day,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                if (widget.isBase)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withAlpha(32),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: kPrimaryColor.withAlpha(80),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'Base',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Separator
          Container(height: 80, width: 0.5, color: kBorderColor.withAlpha(80)),
          const SizedBox(width: 8),
          // Dropdowns Section - Inline
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // PROTEÍNA: Rango + Gramaje
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🥚 Proteína',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rango dropdown
                      _InlineDropdown(
                        items: MacroRanges.protein.keys.toList(),
                        value: _proteinRangeName,
                        onChanged: (widget.isBase || _isCustom)
                            ? (rangeName) {
                                setState(() {
                                  _proteinRangeName = rangeName;
                                  final range = MacroRanges.protein[rangeName]!;
                                  _settings = _settings.copyWith(
                                    proteinSelected: range.min,
                                    proteinRangeName: rangeName,
                                  );
                                });
                                widget.onChanged(_settings);
                              }
                            : null,
                        color: Colors.greenAccent,
                        enabled: (widget.isBase || _isCustom),
                      ),
                      const SizedBox(height: 6),
                      // Gramaje dropdown
                      _InlineDropdown(
                        items: _generateGramageOptions(
                          MacroRanges.protein[_proteinRangeName]!.min,
                          MacroRanges.protein[_proteinRangeName]!.max,
                        ).map((v) => v.toStringAsFixed(1)).toList(),
                        value: _settings.proteinSelected.toStringAsFixed(1),
                        onChanged: (widget.isBase || _isCustom)
                            ? (val) {
                                setState(() {
                                  _settings = _settings.copyWith(
                                    proteinSelected: double.parse(val),
                                  );
                                });
                                widget.onChanged(_settings);
                              }
                            : null,
                        color: Colors.greenAccent,
                        enabled: (widget.isBase || _isCustom),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // GRASAS: Rango + Gramaje
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '💛 Grasas',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rango dropdown
                      _InlineDropdown(
                        items: MacroRanges.lipids.keys.toList(),
                        value: _fatRangeName,
                        onChanged: (widget.isBase || _isCustom)
                            ? (rangeName) {
                                setState(() {
                                  _fatRangeName = rangeName;
                                  final range = MacroRanges.lipids[rangeName]!;
                                  _settings = _settings.copyWith(
                                    fatSelected: range.min,
                                    fatRangeName: rangeName,
                                  );
                                });
                                widget.onChanged(_settings);
                              }
                            : null,
                        color: Colors.orangeAccent,
                        enabled: (widget.isBase || _isCustom),
                      ),
                      const SizedBox(height: 6),
                      // Gramaje dropdown
                      _InlineDropdown(
                        items: _generateGramageOptions(
                          MacroRanges.lipids[_fatRangeName]!.min,
                          MacroRanges.lipids[_fatRangeName]!.max,
                        ).map((v) => v.toStringAsFixed(1)).toList(),
                        value: _settings.fatSelected.toStringAsFixed(1),
                        onChanged: (widget.isBase || _isCustom)
                            ? (val) {
                                setState(() {
                                  _settings = _settings.copyWith(
                                    fatSelected: double.parse(val),
                                  );
                                });
                                widget.onChanged(_settings);
                              }
                            : null,
                        color: Colors.orangeAccent,
                        enabled: (widget.isBase || _isCustom),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // CARBOS: Automáticos (display)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🌾 Carbos',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withAlpha(16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.lightBlueAccent.withAlpha(80),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              carbGperKg.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'g/kg',
                              style: TextStyle(
                                color: kTextColorSecondary,
                                fontSize: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Insights Section
          Expanded(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 90),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kcal:',
                        style: TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        totalKcal.toStringAsFixed(0),
                        style: const TextStyle(
                          color: kTextColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.kcalAdjustment < -10
                          ? Colors.red.withAlpha(32)
                          : widget.kcalAdjustment > 10
                          ? Colors.green.withAlpha(32)
                          : Colors.blue.withAlpha(32),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.kcalAdjustment < -10
                          ? '📉 Déficit'
                          : widget.kcalAdjustment > 10
                          ? '📈 Superávit'
                          : '⚖️ Mant.',
                      style: TextStyle(
                        color: widget.kcalAdjustment < -10
                            ? Colors.red
                            : widget.kcalAdjustment > 10
                            ? Colors.green
                            : Colors.blue,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Chart + Legend
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: totalKcal > 0
                      ? PieChart(
                          PieChartData(
                            sections: [
                              if (proteinKcal > 0)
                                PieChartSectionData(
                                  value: proteinKcal,
                                  color: Colors.greenAccent,
                                  radius: 25,
                                ),
                              if (fatKcal > 0)
                                PieChartSectionData(
                                  value: fatKcal,
                                  color: Colors.orangeAccent,
                                  radius: 25,
                                ),
                              if (carbKcal > 0)
                                PieChartSectionData(
                                  value: carbKcal,
                                  color: Colors.lightBlueAccent,
                                  radius: 25,
                                ),
                            ],
                            centerSpaceRadius: 18,
                            sectionsSpace: 1,
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Sin datos',
                            style: TextStyle(
                              color: kTextColorSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                // Legend
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(
                        emoji: '🥚',
                        label: 'P',
                        grams: '${proteinG.toStringAsFixed(0)}g',
                        kcal: proteinKcal.toStringAsFixed(0),
                        pct:
                            '${(proteinKcal / totalKcal * 100).toStringAsFixed(0)}%',
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(height: 2),
                      _LegendRow(
                        emoji: '💛',
                        label: 'F',
                        grams: '${fatG.toStringAsFixed(0)}g',
                        kcal: fatKcal.toStringAsFixed(0),
                        pct:
                            '${(fatKcal / totalKcal * 100).toStringAsFixed(0)}%',
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 2),
                      _LegendRow(
                        emoji: '🌾',
                        label: 'C',
                        grams: '${carbG.toStringAsFixed(0)}g',
                        kcal: carbKcal.toStringAsFixed(0),
                        pct:
                            '${(carbKcal / totalKcal * 100).toStringAsFixed(0)}%',
                        color: Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Custom/Heredado Button
          if (!widget.isBase)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isCustom) {
                    // Volver a heredar de Lunes
                    setState(() {
                      _settings = (widget.baseSettings ?? widget.settings)
                          .copyWith(isCustomizedFromBase: false);
                      _updateRangeNames();
                      _isCustom = false;
                    });
                  } else {
                    // Activar modo custom
                    setState(() {
                      _settings = _settings.copyWith(
                        isCustomizedFromBase: true,
                      );
                      _isCustom = true;
                    });
                  }
                  widget.onChanged(_settings);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isCustom
                        ? Colors.amber.withAlpha(80)
                        : Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isCustom
                          ? Colors.amber.withAlpha(150)
                          : kBorderColor.withAlpha(80),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCustom ? Icons.lock_open : Icons.link,
                        size: 14,
                        color: _isCustom ? Colors.amber : kTextColorSecondary,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _isCustom ? 'Custom' : 'Heredado',
                        style: TextStyle(
                          color: _isCustom ? Colors.amber : kTextColorSecondary,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// INLINE DROPDOWN
// ─────────────────────────────────────────────────────────
class _InlineDropdown extends StatelessWidget {
  final List<String> items;
  final String value;
  final Function(String)? onChanged;
  final Color color;
  final bool enabled;

  const _InlineDropdown({
    required this.items,
    required this.value,
    this.onChanged,
    required this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.black.withAlpha(60)
            : Colors.black.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enabled ? color.withAlpha(100) : color.withAlpha(40),
          width: 0.8,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: enabled ? (val) => onChanged?.call(val ?? value) : null,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: enabled ? color : color.withAlpha(100),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
        icon: Icon(
          Icons.arrow_drop_down,
          size: 14,
          color: enabled ? color.withAlpha(150) : color.withAlpha(60),
        ),
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(
          color: enabled ? color : color.withAlpha(100),
          fontSize: 9,
        ),
        dropdownColor: kCardColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// RANGE BUTTON
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
// LEGEND ROW
// ─────────────────────────────────────────────────────────
class _LegendRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String grams;
  final String kcal;
  final String pct;
  final Color color;

  const _LegendRow({
    required this.emoji,
    required this.label,
    required this.grams,
    required this.kcal,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 9)),
        const SizedBox(width: 2),
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          grams,
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 1),
        Text(
          '($kcal kcal',
          style: const TextStyle(color: kTextColorSecondary, fontSize: 6),
        ),
        const SizedBox(width: 0.5),
        Text(
          '$pct)',
          style: const TextStyle(
            color: kTextColorSecondary,
            fontSize: 6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
