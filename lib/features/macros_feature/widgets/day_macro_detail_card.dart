import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macro_distribution_chart.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macro_day_view_data.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macro_insight_card.dart';
import 'package:hcs_app_lap/utils/theme.dart';

const Color _proteinColor = Color(0xFF35D39D);
const Color _fatColor = Color(0xFFF7A33B);
const Color _carbColor = Color(0xFF4EA7FF);
const Color _negativeColor = Color(0xFFFF6B6B);

class DayMacroDetailCard extends StatelessWidget {
  final dynamic data;
  final dynamic day;
  final dynamic viewData;
  final dynamic dayData;
  final dynamic selectedDay;
  final int dayIndex;
  final Function? onChanged;
  final Function? onChangedSelectedDay;
  final Function? onEdit;
  final Function? onEditDay;
  final Function? onEditMacros;
  final Function? onEditSelectedDay;
  final Function? onEditPressed;

  const DayMacroDetailCard({
    super.key,
    this.data,
    this.day,
    this.viewData,
    this.dayData,
    this.selectedDay,
    this.dayIndex = 0,
    this.onChanged,
    this.onChangedSelectedDay,
    this.onEdit,
    this.onEditDay,
    this.onEditMacros,
    this.onEditSelectedDay,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final source = data ?? day ?? viewData ?? dayData ?? selectedDay;

    late final double protein;
    late final double fat;
    late final double carbs;
    late final double kcal;
    late final double proteinPerKg;
    late final double fatPerKg;
    late final double carbsPerKg;

    if (source is MacroDayViewData) {
      protein = source.proteinGrams;
      fat = source.fatGrams;
      carbs = source.carbsGrams;
      kcal = source.targetKcal;

      final weightKg = source.weightKg > 0 ? source.weightKg : 0.0;
      proteinPerKg = weightKg > 0 ? protein / weightKg : 0.0;
      fatPerKg = weightKg > 0 ? fat / weightKg : 0.0;
      carbsPerKg = weightKg > 0 ? carbs / weightKg : 0.0;
    } else {
      protein = _readNumber(
        source,
        keys: ['proteinGrams', 'protein', 'proteinG'],
      );
      fat = _readNumber(
        source,
        keys: ['fatGrams', 'fatsGrams', 'fats', 'fat'],
      );
      carbs = _readNumber(
        source,
        keys: [
          'carbsGrams',
          'carbGrams',
          'carbohydrateGrams',
          'carbs',
          'carbohydrates',
        ],
      );
      kcal = _readNumber(
        source,
        keys: ['targetKcal', 'targetCalories', 'calories', 'kcal'],
      );

      final weightKg = _readNumber(
        source,
        keys: ['weightKg', 'weight', 'pesoKg'],
      );
      proteinPerKg = weightKg > 0 ? protein / weightKg : 0.0;
      fatPerKg = weightKg > 0 ? fat / weightKg : 0.0;
      carbsPerKg = weightKg > 0 ? carbs / weightKg : 0.0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kInputFillColor.withValues(alpha: 0.28),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: _readTitle(source),
            subtitle: _readSubtitle(source),
            status: _readStatus(source),
            kcal: kcal,
            onEdit: () => _callEdit(
              [onEdit, onEditDay, onEditMacros, onEditSelectedDay, onEditPressed],
              source,
            ),
          ),
          const SizedBox(height: 14),
          _MacroEquationRow(
            protein: protein,
            fat: fat,
            carbs: carbs,
            proteinPerKg: proteinPerKg,
            fatPerKg: fatPerKg,
            carbsPerKg: carbsPerKg,
          ),
          const SizedBox(height: 14),
          MacroDistributionChart(
            proteinGrams: protein,
            fatGrams: fat,
            carbsGrams: carbs,
            targetCalories: kcal,
          ),
          const SizedBox(height: 14),
          MacroInsightCard(
            targetCalories: kcal,
            hasNegativeCarbs: carbs < 0,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final double kcal;
  final VoidCallback onEdit;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.kcal,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final titleBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _StatusBadge(label: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KcalTarget(kcal: kcal),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onEdit,
              tooltip: 'Editar macros del dia',
              icon: const Icon(Icons.edit_rounded, size: 18),
              color: kTextColor,
              style: IconButton.styleFrom(
                backgroundColor: kPrimaryColor.withValues(alpha: 0.16),
                side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.28)),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [titleBlock]),
              const SizedBox(height: 14),
              actions,
            ],
          );
        }

        return Row(
          children: [
            titleBlock,
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

class _KcalTarget extends StatelessWidget {
  final double kcal;

  const _KcalTarget({required this.kcal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            kcal.toStringAsFixed(0),
            style: const TextStyle(
              color: kTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'kcal · objetivo',
            style: TextStyle(
              color: kTextColorSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroEquationRow extends StatelessWidget {
  final double protein;
  final double fat;
  final double carbs;
  final double proteinPerKg;
  final double fatPerKg;
  final double carbsPerKg;

  const _MacroEquationRow({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.proteinPerKg,
    required this.fatPerKg,
    required this.carbsPerKg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              _MacroMainCard(
                title: 'Proteina',
                value: protein,
                perKg: proteinPerKg,
                kcal: protein * 4,
                color: _proteinColor,
              ),
              const SizedBox(height: 10),
              _MacroMainCard(
                title: 'Grasas',
                value: fat,
                perKg: fatPerKg,
                kcal: fat * 9,
                color: _fatColor,
              ),
              const SizedBox(height: 10),
              _MacroMainCard(
                title: 'Carbohidratos',
                value: carbs,
                perKg: carbsPerKg,
                kcal: carbs * 4,
                color: carbs < 0 ? _negativeColor : _carbColor,
                automatic: true,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _MacroMainCard(
                title: 'Proteina',
                value: protein,
                perKg: proteinPerKg,
                kcal: protein * 4,
                color: _proteinColor,
              ),
            ),
            const _EquationSign('+'),
            Expanded(
              child: _MacroMainCard(
                title: 'Grasas',
                value: fat,
                perKg: fatPerKg,
                kcal: fat * 9,
                color: _fatColor,
              ),
            ),
            const _EquationSign('+'),
            Expanded(
              child: _MacroMainCard(
                title: 'Carbohidratos',
                value: carbs,
                perKg: carbsPerKg,
                kcal: carbs * 4,
                color: carbs < 0 ? _negativeColor : _carbColor,
                automatic: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MacroMainCard extends StatelessWidget {
  final String title;
  final double value;
  final double perKg;
  final double kcal;
  final Color color;
  final bool automatic;

  const _MacroMainCard({
    required this.title,
    required this.value,
    required this.perKg,
    required this.kcal,
    required this.color,
    this.automatic = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 118),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${value.toStringAsFixed(0)} g',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  perKg > 0
                      ? '${perKg.toStringAsFixed(1)} g/kg · ${kcal.toStringAsFixed(0)} kcal'
                      : '${kcal.toStringAsFixed(0)} kcal',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (automatic)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: const BorderRadius.all(Radius.circular(999)),
                      border: Border.all(color: color.withValues(alpha: 0.26)),
                    ),
                    child: Text(
                      'Automatico',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EquationSign extends StatelessWidget {
  final String sign;

  const _EquationSign(this.sign);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        sign,
        style: const TextStyle(
          color: kTextColorSecondary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _proteinColor.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: _proteinColor.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _proteinColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

double _readNumber(
  dynamic source, {
  List<String> keys = const [],
  double fallback = 0.0,
}) {
  if (source == null) return fallback;

  if (source is num) return source.toDouble();

  if (source is String) {
    return double.tryParse(source.replaceAll(',', '.')) ?? fallback;
  }

  if (source is Map) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
  }

  return fallback;
}

String _readTitle(dynamic source) {
  if (source is MacroDayViewData) return source.dayName;
  return _readString(
    source,
    keys: ['dayName', 'weekdayName', 'label', 'title'],
    fallback: 'Dia seleccionado',
  );
}

String _readSubtitle(dynamic source) {
  if (source is MacroDayViewData) return source.subtitle;
  return _readString(
    source,
    keys: ['subtitle', 'activityLabel', 'trainingLabel', 'description'],
    fallback: 'Distribucion diaria de macronutrientes',
  );
}

String _readStatus(dynamic source) {
  if (source is MacroDayViewData) return source.statusLabel;
  return _readString(
    source,
    keys: ['statusLabel', 'statusText', 'status'],
    fallback: 'BASE',
  );
}

String _readString(
  dynamic source, {
  List<String> keys = const [],
  String fallback = '',
}) {
  if (source == null) return fallback;
  if (source is String && source.trim().isNotEmpty) return source;

  if (source is Map) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
  }

  return fallback;
}

void _callEdit(List<Function?> callbacks, dynamic value) {
  for (final callback in callbacks) {
    if (callback == null) continue;
    if (value is MacroDayViewData && callback is void Function(MacroDayViewData)) {
      callback(value);
      return;
    }
    if (callback is void Function(dynamic)) {
      callback(value);
      return;
    }
    if (callback is void Function()) {
      callback();
      return;
    }
  }
}
