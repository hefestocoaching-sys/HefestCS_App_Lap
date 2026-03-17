import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/calendar_feature/calendar_screen.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/transactions_provider.dart';
import 'package:hcs_app_lap/features/finance_feature/finance_screen.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/client_list_screen.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Dashboard ejecutivo sin captura de datos; solo resumen y navegación.
class WorkspaceHomeScreen extends ConsumerWidget {
  const WorkspaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: clientsAsync.when(
                data: (clientsState) {
                  final totalClients = clientsState.clients.length;
                  final activeClients = clientsState.clients
                      .where((c) => c.status == ClientStatus.active)
                      .length;
                  final todaysAppointments = appointmentsNotifier
                      .getTodayAppointments();

                  return _ExecutiveDashboard(
                    now: now,
                    totalClients: totalClients,
                    activeClients: activeClients,
                    todaysAppointments: todaysAppointments,
                    transactionsNotifier: transactionsNotifier,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExecutiveDashboard extends StatelessWidget {
  const _ExecutiveDashboard({
    required this.now,
    required this.totalClients,
    required this.activeClients,
    required this.todaysAppointments,
    required this.transactionsNotifier,
  });

  final DateTime now;
  final int totalClients;
  final int activeClients;
  final List<Appointment> todaysAppointments;
  final TransactionsNotifier transactionsNotifier;

  @override
  Widget build(BuildContext context) {
    final income = transactionsNotifier.getMonthlyIncome(now);
    final expenses = transactionsNotifier.getMonthlyExpenses(now);
    final profit = transactionsNotifier.getMonthlyProfit(now);
    final roi = transactionsNotifier.getROI(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(now: now),
        const SizedBox(height: 24),
        _KpiRow(
          activeClients: activeClients,
          totalClients: totalClients,
          todaysAppointments: todaysAppointments.length,
          onOpenCalendar: () => _navigate(context, const CalendarScreen()),
          onOpenClients: () => _navigate(context, const ClientListScreen()),
          onOpenFinance: () => _navigate(context, const FinanceScreen()),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1100;
            final summaryColumn = Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FinanceCard(
                        month: now,
                        income: income,
                        expenses: expenses,
                        profit: profit,
                        roi: roi,
                        onTap: () => _navigate(context, const FinanceScreen()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MonthCalendarCard(
                        month: now,
                        onTap: () => _navigate(context, const CalendarScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: summaryColumn),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 320,
                    child: _AgendaCard(
                      appointments: todaysAppointments,
                      onOpenCalendar: () =>
                          _navigate(context, const CalendarScreen()),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summaryColumn,
                const SizedBox(height: 16),
                _AgendaCard(
                  appointments: todaysAppointments,
                  onOpenCalendar: () =>
                      _navigate(context, const CalendarScreen()),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';

    final formattedDate = _formatDate(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tablero ejecutivo - Solo resumen y navegación',
                style: TextStyle(
                  fontSize: 15,
                  color: kTextColorSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [_Pill(label: formattedDate)]),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _SearchAndProfile(),
      ],
    );
  }
}

class _SearchAndProfile extends StatelessWidget {
  const _SearchAndProfile();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            readOnly: true,
            decoration: hcsDecoration(
              context,
              hintText: 'Buscar en módulos',
              prefixIcon: const Icon(Icons.search, color: kTextColorSecondary),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 22,
          backgroundColor: kCardColor,
          child: Icon(Icons.person, color: kTextColor),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.activeClients,
    required this.totalClients,
    required this.todaysAppointments,
    required this.onOpenCalendar,
    required this.onOpenClients,
    required this.onOpenFinance,
  });

  final int activeClients;
  final int totalClients;
  final int todaysAppointments;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenClients;
  final VoidCallback onOpenFinance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 900;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KpiCard(
              title: 'Citas de hoy',
              value: todaysAppointments.toString(),
              trendLabel: todaysAppointments > 0
                  ? 'Revisa el calendario'
                  : 'Sin citas programadas',
              icon: Icons.calendar_today_outlined,
              color: kPrimaryColor,
              onTap: onOpenCalendar,
              width: _kpiWidth(isStacked, constraints),
            ),
            _KpiCard(
              title: 'Planes por entregar',
              value: '${(totalClients - activeClients).clamp(0, totalClients)}',
              trendLabel: 'Pendiente consolidar',
              icon: Icons.assignment_outlined,
              color: const Color(0xFFFFB74D),
              onTap: onOpenClients,
              width: _kpiWidth(isStacked, constraints),
            ),
            _KpiCard(
              title: 'Pacientes activos',
              value: activeClients.toString(),
              trendLabel: '$totalClients totales',
              icon: Icons.people_outline,
              color: const Color(0xFF4CAF50),
              onTap: onOpenClients,
              width: _kpiWidth(isStacked, constraints),
            ),
          ],
        );
      },
    );
  }

  double _kpiWidth(bool isStacked, BoxConstraints constraints) {
    if (isStacked) return constraints.maxWidth;
    return (constraints.maxWidth - 32) / 3;
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.trendLabel,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.width,
  });

  final String title;
  final String value;
  final String trendLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kTextColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trendLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kTextColorSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.month,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.roi,
    required this.onTap,
  });

  final DateTime month;
  final double income;
  final double expenses;
  final double profit;
  final double roi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(label: _formatMonth(month)),
              const SizedBox(width: 12),
              const Text(
                'Resumen financiero',
                style: TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: kTextColorSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: 'Ingresos', value: _money(income)),
              _Metric(label: 'Gastos', value: _money(expenses)),
              _Metric(label: 'Margen', value: _money(profit)),
              _Metric(label: 'ROI', value: '${roi.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 16),
          const _ChartPlaceholder(),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: const Center(
        child: Text(
          'Placeholder gráfico (barra/area)',
          style: TextStyle(color: kTextColorSecondary),
        ),
      ),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({required this.month, required this.onTap});

  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = _buildMonthDays(month);

    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(label: _formatMonth(month)),
              const SizedBox(width: 12),
              const Text(
                'Calendario mensual',
                style: TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: kTextColorSecondary),
            ],
          ),
          const SizedBox(height: 12),
          const _WeekdayHeader(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: days.map((day) {
              final isToday = _isSameDay(day, DateTime.now());
              return Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? kPrimaryColor.withAlpha(40) : kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? kPrimaryColor.withAlpha(140)
                        : Colors.white.withAlpha(20),
                  ),
                ),
                child: Text(
                  day.day.toString(),
                  style: TextStyle(
                    color: isToday ? kPrimaryColor : kTextColor,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.appointments, required this.onOpenCalendar});

  final List<Appointment> appointments;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onOpenCalendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Agenda de hoy',
                style: TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _Pill(label: _formatDate(DateTime.now())),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: kTextColorSecondary),
            ],
          ),
          const SizedBox(height: 12),
          if (appointments.isEmpty)
            const Text(
              'Sin citas programadas',
              style: TextStyle(color: kTextColorSecondary),
            )
          else
            ...appointments.map((apt) => _AgendaItem(appointment: apt)),
        ],
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  const _AgendaItem({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final start = appointment.dateTime;
    final end = start.add(Duration(minutes: appointment.durationMinutes));
    final timeLabel =
        '${_twoDigits(start.hour)}:${_twoDigits(start.minute)} - '
        '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (appointment.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.notes!,
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: child,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatMonth(DateTime date) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return months[date.month - 1];
}

List<DateTime> _buildMonthDays(DateTime date) {
  final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
  return List.generate(daysInMonth, (index) {
    return DateTime(date.year, date.month, index + 1);
  });
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _money(double value) {
  return '\$${value.toStringAsFixed(0)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

void _navigate(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}
