import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macro_day_view_data.dart';
import 'package:hcs_app_lap/utils/theme.dart';

const Color _proteinColor = Color(0xFF35D39D);
const Color _fatColor = Color(0xFFF7A33B);
const Color _carbColor = Color(0xFF4EA7FF);
const Color _negativeColor = Color(0xFFFF6B6B);

const List<String> _dayNames = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

class WeeklyMacroSidebar extends StatelessWidget {
  final List<dynamic>? days;
  final List<dynamic>? weekDays;
  final List<dynamic>? macroDays;
  final List<dynamic>? dayViews;
  final List<dynamic>? weekData;
  final int selectedDayIndex;
  final int? selectedIndex;
  final ValueChanged<int>? onDaySelected;
  final ValueChanged<int>? onSelectedDayChanged;
  final ValueChanged<int>? onSelectDay;
  final ValueChanged<dynamic>? onEditDay;
  final ValueChanged<dynamic>? onEdit;

  const WeeklyMacroSidebar({
    super.key,
    this.days,
    this.weekDays,
    this.macroDays,
    this.dayViews,
    this.weekData,
    this.selectedDayIndex = 0,
    this.selectedIndex,
    this.onDaySelected,
    this.onSelectedDayChanged,
    this.onSelectDay,
    this.onEditDay,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final items = days ?? weekDays ?? macroDays ?? dayViews ?? weekData ?? const [];
    final selected = selectedIndex ?? selectedDayIndex;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kInputFillColor.withValues(alpha: 0.28),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rows = List.generate(items.length, (index) {
            final item = items[index];
            return _SidebarDayRow(
              index: index,
              item: item,
              isSelected: index == selected,
              onTap: () => _notifySelectedDay(index),
              onEdit: () => _notifyEditDay(item),
            );
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Semana',
                style: TextStyle(
                  color: kTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (constraints.hasBoundedHeight)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => rows[index],
                  ),
                )
              else
                Column(
                  children: List.generate(rows.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == rows.length - 1 ? 0 : 10,
                      ),
                      child: rows[index],
                    );
                  }),
                ),
            ],
          );
        },
      ),
    );
  }

  void _notifySelectedDay(int index) {
    final callback = onDaySelected ?? onSelectedDayChanged ?? onSelectDay;
    callback?.call(index);
  }

  void _notifyEditDay(dynamic item) {
    final callback = onEditDay ?? onEdit;
    callback?.call(item);
  }
}

class _SidebarDayRow extends StatelessWidget {
  final int index;
  final dynamic item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SidebarDayRow({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final macro = item is MacroDayViewData ? item as MacroDayViewData : null;
    final title = _fullDayName(item, index);
    const subtitle = 'Plan diario';
    const status = 'BASE';
    final protein = macro?.proteinGrams ?? 0;
    final fat = macro?.fatGrams ?? 0;
    final carbs = macro?.carbsGrams ?? 0;
    final kcal = macro?.targetKcal ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: 0.13)
                : Colors.white.withValues(alpha: 0.035),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(
              color: isSelected
                  ? kPrimaryColor.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: kTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusMiniBadge(label: status, selected: isSelected),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MacroMiniValue(label: 'P', value: protein, color: _proteinColor),
                        _MacroMiniValue(label: 'G', value: fat, color: _fatColor),
                        _MacroMiniValue(
                          label: 'C',
                          value: carbs,
                          color: carbs < 0 ? _negativeColor : _carbColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${kcal.toStringAsFixed(0)} kcal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Editar día',
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  color: kPrimaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor: kPrimaryColor.withValues(alpha: 0.14),
                    minimumSize: const Size(34, 34),
                    fixedSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _fullDayName(dynamic item, int index) {
  if (item is MacroDayViewData) {
    final raw = item.dayName.trim();
    if (raw.isNotEmpty) return raw;
  }

  if (item is Map) {
    final raw = item['dayName'] ??
        item['weekday'] ??
        item['weekdayName'] ??
        item['name'] ??
        item['label'];

    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }
  }

  return _dayNames[index.clamp(0, _dayNames.length - 1)];
}

class _MacroMiniValue extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroMiniValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Text(
        '$label ${value.toStringAsFixed(0)}g',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusMiniBadge extends StatelessWidget {
  final String label;
  final bool selected;

  const _StatusMiniBadge({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? kPrimaryColor.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? kPrimaryColor : kTextColorSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
