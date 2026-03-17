import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Widget reutilizable para mostrar historial de registros clínicos por fecha
class RecordHistoryPanel<T> extends StatelessWidget {
  final List<T> records;
  final DateTime? selectedDate;
  final void Function(DateTime date) onSelectDate;
  final String Function(T record) primaryLabel;
  final DateTime Function(T record) dateOf;
  final String title;

  const RecordHistoryPanel({
    super.key,
    required this.records,
    required this.selectedDate,
    required this.onSelectDate,
    required this.primaryLabel,
    required this.dateOf,
    this.title = 'Historial de Registros',
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kAppBarColor.withAlpha(110),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.history, size: 48, color: kTextColorSecondary),
            const SizedBox(height: 12),
            Text(
              'Sin registros previos',
              style: TextStyle(
                color: kTextColorSecondary.withAlpha(180),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar por fecha descendente
    final sortedRecords = [...records]
      ..sort((a, b) => dateOf(b).compareTo(dateOf(a)));
    final mostRecentDate = dateOf(sortedRecords.first);

    return Container(
      decoration: BoxDecoration(
        color: kAppBarColor.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length} registro${records.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kTextColorSecondary),

          // Lista de registros
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: sortedRecords.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = sortedRecords[index];
                final recordDate = dateOf(record);
                final isSelected =
                    selectedDate != null &&
                    DateUtils.isSameDay(selectedDate, recordDate);
                final isMostRecent = DateUtils.isSameDay(
                  recordDate,
                  mostRecentDate,
                );
                final label = primaryLabel(record);

                return InkWell(
                  onTap: () => onSelectDate(recordDate),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimaryColor.withAlpha(51)
                          : kCardColor.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? kPrimaryColor
                            : Colors.white.withAlpha(20),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icono de calendario
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimaryColor.withAlpha(76)
                                : kTextColorSecondary.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: isSelected
                                ? kPrimaryColor
                                : kTextColorSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Fecha y label
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                  'es',
                                ).format(recordDate),
                                style: TextStyle(
                                  color: isSelected
                                      ? kPrimaryColor
                                      : kTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (label.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: kTextColorSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Badge distintivo
                        if (isMostRecent && isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kSuccessColor.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✓ Último',
                              style: TextStyle(
                                color: kSuccessColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isMostRecent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kSuccessColor.withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Último',
                              style: TextStyle(
                                color: kSuccessColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Archivo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
