import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';

/// Header global que muestra la fecha activa y permite cambiarla
class ActiveDateHeader extends ConsumerWidget {
  const ActiveDateHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(globalDateProvider);
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Container(
      height: 48,
      color: kCardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Texto de estado
          Text(
            'Mostrando estado al: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
            style: const TextStyle(
              color: kTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),

          // Botón "Hoy"
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: isToday
                  ? null
                  : () {
                      ref
                          .read(globalDateProvider.notifier)
                          .setDate(DateTime.now());
                    },
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Hoy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isToday
                    ? kButtonBackgroundColor
                    : kPrimaryColor,
                foregroundColor: isToday ? Colors.grey : Colors.white,
                disabledBackgroundColor: isToday
                    ? Colors.grey[300]
                    : kPrimaryColor,
                disabledForegroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón DatePicker
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () async {
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
                  if (context.mounted) {
                    ref.read(globalDateProvider.notifier).setDate(endOfDay);
                  }
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text('Cambiar fecha'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: const BorderSide(color: kPrimaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
