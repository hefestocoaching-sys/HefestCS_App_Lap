import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/general_equivalents_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class GeneralEquivalentsTable extends ConsumerWidget {
  final Map<String, double>? targets;
  final Map<String, double>? equivalentsOverride;
  final Function(String id, double delta)? onUpdateOverride;

  const GeneralEquivalentsTable({
    super.key,
    this.targets,
    this.equivalentsOverride,
    this.onUpdateOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine source of data
    final Map<String, double> equivalents;
    final Function(String, double) onUpdate;

    if (equivalentsOverride != null) {
      equivalents = equivalentsOverride!;
      onUpdate = onUpdateOverride ?? (_, __) {};
    } else {
      final state = ref.watch(generalEquivalentsProvider);
      equivalents = state.equivalents;
      onUpdate = (id, delta) => ref
          .read(generalEquivalentsProvider.notifier)
          .updateEquivalent(id, delta);
    }

    final definitions = EquivalentCatalog.v1Definitions;

    // Calculate Totals
    double sumKcal = 0;
    double sumProt = 0;
    double sumFat = 0;
    double sumCarb = 0;
    double sumEthanol = 0;

    for (var def in definitions) {
      final qty = equivalents[def.id] ?? 0;
      if (qty > 0) {
        sumKcal += def.kcal * qty;
        sumProt += def.proteinG * qty;
        sumFat += def.fatG * qty;
        sumCarb += def.carbG * qty;
        sumEthanol += def.ethanolG * qty;
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: kBorderColor),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 1000,
            margin: const EdgeInsets.only(bottom: 40),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor.withValues(alpha: 0.5)),
              boxShadow: kCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DIETOCÁLCULO',
                        style: TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Total Kcal: ${sumKcal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // THE TABLE
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2), // Grupo
                    1: FlexColumnWidth(2), // Subgrupo
                    2: FixedColumnWidth(120), // Eq (Wider for buttons)
                    3: FixedColumnWidth(60), // Kcal
                    4: FixedColumnWidth(50), // P
                    5: FixedColumnWidth(50), // L
                    6: FixedColumnWidth(50), // HC
                    7: FixedColumnWidth(50), // Et
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // TABLE HEADERS
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: kBorderColor)),
                        color: kBackgroundColor,
                      ),
                      children: [
                        _headerCell('GRUPO'),
                        _headerCell('SUBGRUPO'),
                        _headerCell('EQUIVALENTES'),
                        _headerCell('KCAL'),
                        _headerCell('PR'),
                        _headerCell('GR'),
                        _headerCell('HC'),
                        _headerCell('ET'),
                      ],
                    ),

                    // DEFINITIONS
                    ...definitions.map((def) {
                      final qty = equivalents[def.id] ?? 0;
                      final isActive = qty > 0;

                      return TableRow(
                        decoration: BoxDecoration(
                          color: isActive
                              ? kPrimaryColor.withValues(alpha: 0.05)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: kBorderColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        children: [
                          _cell(
                            _formatId(def.group),
                            alignLeft: true,
                            color: isActive ? kTextColor : kTextColorSecondary,
                          ),
                          _cell(
                            _formatId(def.subgroup),
                            alignLeft: true,
                            color: kTextColorSecondary,
                          ),

                          // Custom Input Stepper
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            height: 32,
                            decoration: BoxDecoration(
                              color: kInputFillColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive
                                    ? kPrimaryColor.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _iconBtn(
                                  Icons.remove,
                                  () => onUpdate(def.id, -0.5),
                                ),
                                Text(
                                  qty == 0 ? '-' : qty.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isActive
                                        ? kTextColor
                                        : kTextColorSecondary.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                _iconBtn(
                                  Icons.add,
                                  () => onUpdate(def.id, 0.5),
                                ),
                              ],
                            ),
                          ),

                          _cell(
                            (def.kcal * qty).toStringAsFixed(0),
                            bold: isActive,
                          ),
                          _cell((def.proteinG * qty).toStringAsFixed(0)),
                          _cell((def.fatG * qty).toStringAsFixed(0)),
                          _cell((def.carbG * qty).toStringAsFixed(0)),
                          _cell(
                            (def.ethanolG * qty).toStringAsFixed(0),
                            color: (def.ethanolG * qty) > 0
                                ? kErrorColor
                                : null,
                          ),
                        ],
                      );
                    }),

                    // TARGETS ROW (Professional Look)
                    TableRow(
                      decoration: const BoxDecoration(
                        color: kInputFillColor,
                        border: Border(top: BorderSide(color: kBorderColor)),
                      ),
                      children: [
                        _cell(
                          'OBJETIVO',
                          bold: true,
                          alignLeft: true,
                          color: kPrimaryColor,
                        ),
                        _cell(
                          'Requerimiento Diario',
                          alignLeft: true,
                          color: kTextColorSecondary,
                        ),
                        const SizedBox(),
                        _cell(
                          targets?['kcal']?.toStringAsFixed(0) ?? '-',
                          bold: true,
                          color: kTextColor,
                        ),
                        _cell(
                          targets?['protein']?.toStringAsFixed(0) ?? '-',
                          bold: true,
                          color: kTextColor,
                        ),
                        _cell(
                          targets?['fat']?.toStringAsFixed(0) ?? '-',
                          bold: true,
                          color: kTextColor,
                        ),
                        _cell(
                          targets?['carbs']?.toStringAsFixed(0) ?? '-',
                          bold: true,
                          color: kTextColor,
                        ),
                        const SizedBox(),
                      ],
                    ),

                    // SUMMARY ROW
                    TableRow(
                      decoration: const BoxDecoration(color: kCardColor),
                      children: [
                        _cell(
                          'ACTUAL',
                          bold: true,
                          alignLeft: true,
                          color: kSuccessColor,
                        ),
                        _cell(
                          'Consumo Total',
                          alignLeft: true,
                          color: kTextColorSecondary,
                        ),
                        _cell(
                          definitions
                              .fold<double>(
                                0,
                                (sum, def) => sum + (equivalents[def.id] ?? 0),
                              )
                              .toStringAsFixed(1),
                          bold: true,
                        ),
                        _cell(sumKcal.toStringAsFixed(0), bold: true),
                        _cell(sumProt.toStringAsFixed(0), bold: true),
                        _cell(sumFat.toStringAsFixed(0), bold: true),
                        _cell(sumCarb.toStringAsFixed(0), bold: true),
                        _cell(sumEthanol.toStringAsFixed(0), bold: true),
                      ],
                    ),

                    // DIFF ROW
                    TableRow(
                      decoration: BoxDecoration(
                        color: kBackgroundColor.withValues(alpha: 0.5),
                        border: const Border(
                          bottom: BorderSide(color: kBorderColor),
                        ),
                      ),
                      children: [
                        _cell(
                          'RESTANTE',
                          bold: true,
                          alignLeft: true,
                          color: kWarningColor,
                        ),
                        _cell(
                          'Para Objetivo',
                          alignLeft: true,
                          color: kTextColorSecondary,
                        ),
                        const SizedBox(),
                        _diffCell(targets?['kcal'], sumKcal),
                        _diffCell(targets?['protein'], sumProt),
                        _diffCell(targets?['fat'], sumFat),
                        _diffCell(targets?['carbs'], sumCarb),
                        const SizedBox(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 24,
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: kPrimaryColor),
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextColorSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _cell(
    String text, {
    bool bold = false,
    Color? color,
    bool alignLeft = false,
  }) {
    return Container(
      height: 45, // Taller rows for better touch targets
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12, // Slightly larger font
          color: color ?? kTextColorSecondary,
        ),
      ),
    );
  }

  Widget _diffCell(double? target, double current) {
    if (target == null) return _cell('-');
    final diff = target - current;
    final isNegative = diff < 0; // Over target
    // If diff is close to 0 (allow small margin), it's good => Green.
    // If positive (needs more) => Orange/White.
    // If negative (too much) => Red.

    Color color = kTextColor;
    if (diff.abs() < 5) {
      color = kSuccessColor; // Hit target
    } else if (isNegative) {
      color = kErrorColor; // Surpassed
    } else {
      color = kTextColorSecondary; // Still need more
    }

    return _cell(diff.toStringAsFixed(0), bold: true, color: color);
  }

  String _formatId(String t) => t.replaceAll('_', ' ').toUpperCase();
}
