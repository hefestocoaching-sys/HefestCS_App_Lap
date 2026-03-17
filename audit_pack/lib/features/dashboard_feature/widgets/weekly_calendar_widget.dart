import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Widget de calendario semanal horizontal
class WeeklyCalendarWidget extends ConsumerStatefulWidget {
  const WeeklyCalendarWidget({super.key});

  @override
  ConsumerState<WeeklyCalendarWidget> createState() =>
      _WeeklyCalendarWidgetState();
}

class _WeeklyCalendarWidgetState extends ConsumerState<WeeklyCalendarWidget> {
  DateTime _selectedWeekStart = _getStartOfWeek(DateTime.now());

  static DateTime _getStartOfWeek(DateTime date) {
    // Lunes como inicio de semana
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _selectedWeekStart = _getStartOfWeek(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final clients = ref.watch(clientsProvider).value?.clients ?? [];

    final weekDays = List.generate(7, (i) {
      return _selectedWeekStart.add(Duration(days: i));
    });

    final weekAppointments = appointments.where((apt) {
      final aptDate = apt.dateTime;
      return aptDate.isAfter(
            _selectedWeekStart.subtract(const Duration(days: 1)),
          ) &&
          aptDate.isBefore(_selectedWeekStart.add(const Duration(days: 8)));
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F2E).withAlpha(245),
            const Color(0xFF1A1F2E).withAlpha(240),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con navegación
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withAlpha(30),
                      const Color(0xFF00D9FF).withAlpha(20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withAlpha(50),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF00D9FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Agenda Semanal',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withAlpha(10),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: kTextColor,
                        size: 20,
                      ),
                      onPressed: _previousWeek,
                      tooltip: 'Semana anterior',
                    ),
                    TextButton(
                      onPressed: _goToToday,
                      child: Text(
                        DateFormat('MMM dd', 'es').format(_selectedWeekStart),
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: kTextColor,
                        size: 20,
                      ),
                      onPressed: _nextWeek,
                      tooltip: 'Siguiente semana',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendario de 7 días
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final dayAppointments =
                    weekAppointments
                        .where(
                          (apt) =>
                              apt.dateTime.year == day.year &&
                              apt.dateTime.month == day.month &&
                              apt.dateTime.day == day.day,
                        )
                        .toList()
                      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                final isToday = _isToday(day);

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF00D9FF).withAlpha(30),
                              const Color(0xFF00D9FF).withAlpha(20),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF1A1F2E).withAlpha(200),
                              const Color(0xFF1A1F2E).withAlpha(180),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF00D9FF).withAlpha(80)
                          : Colors.white.withAlpha(10),
                      width: isToday ? 2 : 1.5,
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00D9FF).withAlpha(25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Día de la semana
                      Text(
                        DateFormat('EEE', 'es').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? const Color(0xFF00D9FF)
                              : kTextColorSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      // Número del día
                      Text(
                        DateFormat('dd').format(day),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isToday ? const Color(0xFF00D9FF) : kTextColor,
                        ),
                      ),
                      Divider(
                        height: 12,
                        color: isToday
                            ? const Color(0xFF00D9FF).withAlpha(50)
                            : kTextColorSecondary.withAlpha(50),
                      ),

                      // Citas del día
                      Expanded(
                        child: dayAppointments.isEmpty
                            ? Center(
                                child: Text(
                                  'Libre',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kTextColorSecondary.withAlpha(150),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: dayAppointments.length,
                                itemBuilder: (context, aptIndex) {
                                  final apt = dayAppointments[aptIndex];
                                  final client = clients.isNotEmpty
                                      ? clients.firstWhere(
                                          (c) => c.id == apt.clientId,
                                          orElse: () => clients.first,
                                        )
                                      : null;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getAppointmentColor(
                                            apt.type,
                                          ).withAlpha(35),
                                          _getAppointmentColor(
                                            apt.type,
                                          ).withAlpha(25),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getAppointmentColor(
                                          apt.type,
                                        ).withAlpha(60),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'HH:mm',
                                          ).format(apt.dateTime),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: kTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          client?.fullName ?? 'Sin cliente',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: kTextColorSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${apt.type.emoji} ${apt.type.label}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: _getAppointmentColor(
                                              apt.type,
                                            ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getAppointmentColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.weeklyCheck:
        return const Color(0xFF10B981);
      case AppointmentType.measurement:
        return const Color(0xFF3B82F6);
      case AppointmentType.planRenewal:
        return const Color(0xFFF59E0B);
      case AppointmentType.training:
        return const Color(0xFFA855F7);
      case AppointmentType.firstConsult:
        return const Color(0xFF00D9FF);
      case AppointmentType.custom:
        return kTextColorSecondary;
    }
  }
}
