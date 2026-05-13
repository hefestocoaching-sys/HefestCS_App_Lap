import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/day_macro_detail_card.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/weekly_macro_sidebar.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class WeeklyMacrosLayout extends StatelessWidget {
  final List<dynamic>? days;
  final List<dynamic>? weekDays;
  final List<dynamic>? macroDays;
  final List<dynamic>? dayViews;
  final List<dynamic>? weekData;
  final List<dynamic>? weeklyData;
  final dynamic selectedDay;
  final dynamic selectedDayView;
  final int selectedDayIndex;
  final int? selectedIndex;
  final Function? onDaySelected;
  final Function? onChangedSelectedDay;
  final Function? onSelectedDayChanged;
  final Function? onSelectDay;
  final Function? onEditDay;
  final Function? onEdit;
  final Function? onEditSelectedDay;
  final Function? onEditMacros;

  const WeeklyMacrosLayout({
    super.key,
    this.days,
    this.weekDays,
    this.macroDays,
    this.dayViews,
    this.weekData,
    this.weeklyData,
    this.selectedDay,
    this.selectedDayView,
    this.selectedDayIndex = 0,
    this.selectedIndex,
    this.onDaySelected,
    this.onChangedSelectedDay,
    this.onSelectedDayChanged,
    this.onSelectDay,
    this.onEditDay,
    this.onEdit,
    this.onEditSelectedDay,
    this.onEditMacros,
  });

  List<dynamic> _resolveWeekItems() {
    final candidates = [
      days,
      weekDays,
      macroDays,
      dayViews,
      weekData,
      weeklyData,
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.length >= 7) {
        return candidate;
      }
    }

    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return const [];
  }

  ValueChanged<int>? get _selectedDayCallback {
    final callback = onDaySelected ?? onSelectedDayChanged ?? onSelectDay;
    if (callback == null) return null;
    return (index) => callback(index);
  }

  ValueChanged<dynamic>? get _editDayCallback {
    final callback = onEditDay ?? onEdit ?? onEditSelectedDay ?? onEditMacros;
    if (callback == null) return null;
    return (item) => callback(item);
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolveWeekItems();
    final rawIndex = selectedIndex ?? selectedDayIndex;
    final index = items.isEmpty ? 0 : rawIndex.clamp(0, items.length - 1);
    final activeDay = selectedDay ?? selectedDayView ?? (items.isEmpty ? null : items[index]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;
        final detail = DayMacroDetailCard(
          data: activeDay,
          dayIndex: index,
          onChanged: onChangedSelectedDay,
          onChangedSelectedDay: onChangedSelectedDay,
          onEditDay: onEditDay,
          onEdit: onEdit,
          onEditSelectedDay: onEditSelectedDay,
          onEditMacros: onEditMacros,
        );
        final sidebar = WeeklyMacroSidebar(
          days: items,
          selectedDayIndex: index,
          onDaySelected: _selectedDayCallback,
          onEditDay: _editDayCallback,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const _MacrosTitle(),
            const SizedBox(height: 16),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const _InlineStateLegend(),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _ScrollableDayContent(
                                  child: Column(
                                    children: [
                                      detail,
                                      const SizedBox(height: 12),
                                      const _AutomaticCarbsNote(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(width: 420, child: sidebar),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const _InlineStateLegend(),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _ScrollableDayContent(
                                  child: Column(
                                    children: [
                                      detail,
                                      const SizedBox(height: 16),
                                      sidebar,
                                      const SizedBox(height: 12),
                                      const _AutomaticCarbsNote(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MacrosTitle extends StatelessWidget {
  const _MacrosTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.16),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(color: kPrimaryColor.withValues(alpha: 0.28)),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: kPrimaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Macronutrientes semanales',
                style: TextStyle(
                  color: kTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Distribución diaria de proteína, grasas y carbohidratos',
                style: TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScrollableDayContent extends StatelessWidget {
  final Widget child;

  const _ScrollableDayContent({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: child,
    );
  }
}

class _InlineStateLegend extends StatelessWidget {
  const _InlineStateLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kInputFillColor.withValues(alpha: 0.20),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Wrap(
        spacing: 12,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LegendItem(
            label: 'BASE',
            text: 'Día base editable',
            color: Color(0xFF35D39D),
          ),
          _LegendItem(
            label: 'HEREDADO',
            text: 'Heredado del lunes',
            color: Color(0xFF4EA7FF),
          ),
          _LegendItem(
            label: 'CUSTOM',
            text: 'Personalizado',
            color: kPrimaryColor,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: kTextColorSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AutomaticCarbsNote extends StatelessWidget {
  const _AutomaticCarbsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kInfoColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: kInfoColor.withValues(alpha: 0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: kInfoColor, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Los carbohidratos se calculan automáticamente como el remanente de calorías una vez definidos proteína y grasas.',
              style: TextStyle(
                color: kTextColorSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
