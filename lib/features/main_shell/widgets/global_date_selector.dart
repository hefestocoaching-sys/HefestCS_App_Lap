import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';

class GlobalDateSelector extends ConsumerWidget {
  const GlobalDateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(globalDateProvider);
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: kPrimaryColor,
                  onPrimary: Colors.white,
                  surface: kCardColor,
                  onSurface: kTextColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          // Ajustamos al final del día para incluir registros de ese día
          final endOfDay = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
          ref.read(globalDateProvider.notifier).setDate(endOfDay);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isToday ? Colors.transparent : kPrimaryColor.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? null : Border.all(color: kPrimaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isToday ? kTextColorSecondary : kPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              isToday
                  ? "HOY"
                  : DateFormat(
                      'dd MMM yyyy',
                      'es',
                    ).format(selectedDate).toUpperCase(),
              style: TextStyle(
                color: isToday ? kTextColorSecondary : kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
