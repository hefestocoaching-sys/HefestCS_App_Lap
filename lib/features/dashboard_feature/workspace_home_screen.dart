import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/pending_task.dart';
import 'package:hcs_app_lap/domain/entities/transaction.dart' as finance;
import 'package:hcs_app_lap/features/calendar_feature/calendar_screen.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/pending_tasks_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/transactions_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/screens/pending_plans_screen.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/executive_kpi_card.dart';
import 'package:hcs_app_lap/features/finance_feature/finance_screen.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/client_list_screen.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Dashboard ejecutivo sin captura de datos; solo resumen y navegación.
///
/// NOTE: WorkspaceHomeScreen is the active executive dashboard.
/// DashboardScreen remains as legacy/alternate dashboard and is not modified in this pass.
class WorkspaceHomeScreen extends ConsumerWidget {
  const WorkspaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final clientsAsync = ref.watch(clientsProvider);
    final appointments = ref.watch(appointmentsProvider);
    final pendingTasks = ref.watch(pendingTasksProvider);
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: clientsAsync.when(
                data: (clientsState) => _ExecutiveDashboard(
                  now: now,
                  clients: clientsState.clients,
                  appointments: appointments,
                  pendingTasks: pendingTasks,
                  transactions: transactions,
                ),
                loading: () => const _DashboardLoading(),
                error: (_, __) => const _DashboardError(),
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
    required this.clients,
    required this.appointments,
    required this.pendingTasks,
    required this.transactions,
  });

  final DateTime now;
  final List<Client> clients;
  final List<Appointment> appointments;
  final List<PendingTask> pendingTasks;
  final List<finance.Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final activeClients = clients.where((client) {
      return client.status == ClientStatus.active;
    }).toList();
    final todayAppointments = _appointmentsForDay(appointments, now);
    final monthAppointments = _appointmentsForMonth(appointments, now);
    final activePendingTasks = _activePendingTasks(pendingTasks);
    final monthTransactions = _transactionsForMonth(transactions, now);
    final income = _monthlyTotal(
      monthTransactions,
      finance.TransactionType.income,
    );
    final expenses = _monthlyTotal(
      monthTransactions,
      finance.TransactionType.expense,
    );
    final profit = income - expenses;
    final roi = expenses == 0 ? 0.0 : (profit / expenses) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHeader(now: now),
        const SizedBox(height: 20),
        _KpiRow(
          activeClients: activeClients.length,
          totalClients: clients.length,
          todayAppointments: todayAppointments.length,
          pendingPlans: activePendingTasks.length,
          monthlyIncome: income,
          monthlyProfit: profit,
          onOpenCalendar: () => _navigate(context, const CalendarScreen()),
          onOpenClients: () => _navigate(context, const ClientListScreen()),
          onOpenFinance: () => _navigate(context, const FinanceScreen()),
          onOpenPendingPlans: () =>
              _navigate(context, const PendingPlansScreen()),
        ),

        const SizedBox(height: 18),
        _MainDashboardGrid(
          now: now,
          clients: clients,
          todayAppointments: todayAppointments,
          monthAppointments: monthAppointments,
          monthTransactions: monthTransactions,
          income: income,
          expenses: expenses,
          profit: profit,
          roi: roi,
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Tablero ejecutivo - Solo resumen y navegación',
              style: TextStyle(
                color: kTextColorSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _Pill(label: _formatLongDate(now), icon: Icons.today_outlined),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 16),
              const _SearchAndProfile(width: double.infinity),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 20),
            const _SearchAndProfile(width: 340),
          ],
        );
      },
    );
  }
}

class _SearchAndProfile extends StatelessWidget {
  const _SearchAndProfile({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      readOnly: true,
      decoration: hcsDecoration(
        context,
        hintText: 'Buscar módulos',
        prefixIcon: const Icon(Icons.search, color: kTextColorSecondary),
        suffixIcon: Tooltip(
          message: 'Búsqueda global próximamente',
          child: Icon(
            Icons.lock_clock_outlined,
            color: kTextColorSecondary.withAlpha(170),
            size: 18,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (width == double.infinity)
          Expanded(child: searchField)
        else
          SizedBox(width: width, child: searchField),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kCardColor,
            shape: BoxShape.circle,
            border: Border.all(color: kPrimaryColor.withAlpha(72)),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withAlpha(16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.person_outline, color: kTextColor, size: 23),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.activeClients,
    required this.totalClients,
    required this.todayAppointments,
    required this.pendingPlans,
    required this.monthlyIncome,
    required this.monthlyProfit,
    required this.onOpenCalendar,
    required this.onOpenClients,
    required this.onOpenFinance,
    required this.onOpenPendingPlans,
  });

  final int activeClients;
  final int totalClients;
  final int todayAppointments;
  final int pendingPlans;
  final double monthlyIncome;
  final double monthlyProfit;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenClients;
  final VoidCallback onOpenFinance;
  final VoidCallback onOpenPendingPlans;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 900
            ? 2
            : 1;
        const spacing = 16.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: ExecutiveKpiCard(
                title: 'Citas de hoy',
                value: '$todayAppointments',
                subtitle: todayAppointments == 0
                    ? 'Sin citas programadas'
                    : '$todayAppointments citas programadas',
                statusLabel: 'Hoy',
                icon: Icons.event_available_outlined,
                color: kInfoColor,
                onTap: onOpenCalendar,
              ),
            ),
            SizedBox(
              width: width,
              child: ExecutiveKpiCard(
                title: 'Planes pendientes',
                value: '$pendingPlans',
                subtitle: pendingPlans == 0
                    ? 'Sin planes pendientes'
                    : 'Pendiente consolidar',
                statusLabel: 'Pendiente',
                icon: Icons.assignment_outlined,
                color: kWarningColor,
                onTap: onOpenPendingPlans,
              ),
            ),
            SizedBox(
              width: width,
              child: ExecutiveKpiCard(
                title: 'Pacientes activos',
                value: '$activeClients',
                subtitle: activeClients == 0
                    ? 'Sin pacientes activos'
                    : '$totalClients totales',
                statusLabel: 'Activos',
                icon: Icons.people_alt_outlined,
                color: kSuccessColor,
                onTap: onOpenClients,
              ),
            ),
            SizedBox(
              width: width,
              child: ExecutiveKpiCard(
                title: 'Ingresos del mes',
                value: _money(monthlyIncome),
                subtitle: monthlyIncome == 0
                    ? 'Sin ingresos registrados'
                    : 'Margen ${_money(monthlyProfit)}',
                statusLabel: _formatMonth(now: DateTime.now()),
                icon: Icons.account_balance_wallet_outlined,
                color: kPrimaryColor,
                onTap: onOpenFinance,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MainDashboardGrid extends StatelessWidget {
  static const double _mainCardHeight = 372;

  const _MainDashboardGrid({
    required this.now,
    required this.clients,
    required this.todayAppointments,
    required this.monthAppointments,
    required this.monthTransactions,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.roi,
  });

  final DateTime now;
  final List<Client> clients;
  final List<Appointment> todayAppointments;
  final List<Appointment> monthAppointments;
  final List<finance.Transaction> monthTransactions;
  final double income;
  final double expenses;
  final double profit;
  final double roi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final financeCard = _FinancialSummaryCard(
          month: now,
          transactions: monthTransactions,
          income: income,
          expenses: expenses,
          profit: profit,
          roi: roi,
          onTap: () => _navigate(context, const FinanceScreen()),
        );
        final calendarCard = _MonthCalendarCard(
          month: now,
          appointments: monthAppointments,
          onOpenCalendar: () => _navigate(context, const CalendarScreen()),
        );
        final agendaCard = _AgendaCard(
          appointments: todayAppointments,
          clients: clients,
          onOpenCalendar: () => _navigate(context, const CalendarScreen()),
        );

        if (constraints.maxWidth >= 1200) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(height: _mainCardHeight, child: financeCard),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: SizedBox(height: _mainCardHeight, child: calendarCard),
              ),
              const SizedBox(width: 16),
              SizedBox(width: 352, height: _mainCardHeight, child: agendaCard),
            ],
          );
        }

        if (constraints.maxWidth >= 900) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: _mainCardHeight,
                      child: financeCard,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: _mainCardHeight,
                      child: calendarCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              agendaCard,
            ],
          );
        }

        return Column(
          children: [
            financeCard,
            const SizedBox(height: 16),
            calendarCard,
            const SizedBox(height: 16),
            agendaCard,
          ],
        );
      },
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.month,
    required this.transactions,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.roi,
    required this.onTap,
  });

  final DateTime month;
  final List<finance.Transaction> transactions;
  final double income;
  final double expenses;
  final double profit;
  final double roi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = transactions.isEmpty && income == 0 && expenses == 0;

    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: kPrimaryColor,
            title: 'Resumen financiero',
            subtitle: _formatMonthYear(month),
          ),
          const SizedBox(height: 10),
          _FinanceMetricsGrid(
            income: income,
            expenses: expenses,
            profit: profit,
            roi: roi,
          ),
          const SizedBox(height: 8),
          if (empty)
            const _FinanceGhostChart()
          else
            _FinanceBars(income: income, expenses: expenses, profit: profit),
          const SizedBox(height: 8),
          const _InlineCta(label: 'Ver informe financiero'),
        ],
      ),
    );
  }
}

class _FinanceMetricsGrid extends StatelessWidget {
  const _FinanceMetricsGrid({
    required this.income,
    required this.expenses,
    required this.profit,
    required this.roi,
  });

  final double income;
  final double expenses;
  final double profit;
  final double roi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _MoneyMetric(
                label: 'Ingresos',
                value: _money(income),
                color: kSuccessColor,
              ),
            ),
            SizedBox(
              width: width,
              child: _MoneyMetric(
                label: 'Gastos',
                value: _money(expenses),
                color: kErrorColor,
              ),
            ),
            SizedBox(
              width: width,
              child: _MoneyMetric(
                label: 'Margen',
                value: _money(profit),
                color: profit >= 0 ? kSuccessColor : kErrorColor,
              ),
            ),
            SizedBox(
              width: width,
              child: _MoneyMetric(
                label: 'ROI',
                value: '${roi.toStringAsFixed(1)}%',
                color: roi >= 0 ? kInfoColor : kErrorColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FinanceBars extends StatelessWidget {
  const _FinanceBars({
    required this.income,
    required this.expenses,
    required this.profit,
  });

  final double income;
  final double expenses;
  final double profit;

  @override
  Widget build(BuildContext context) {
    final base = _maxDouble(income.abs(), expenses.abs(), profit.abs(), 1);

    return Column(
      children: [
        _FinanceBar(
          label: 'Ingresos',
          value: income / base,
          amount: _money(income),
          color: kSuccessColor,
        ),
        const SizedBox(height: 8),
        _FinanceBar(
          label: 'Gastos',
          value: expenses / base,
          amount: _money(expenses),
          color: kErrorColor,
        ),
        const SizedBox(height: 8),
        _FinanceBar(
          label: 'Margen',
          value: profit.abs() / base,
          amount: _money(profit),
          color: profit >= 0 ? kInfoColor : kErrorColor,
        ),
      ],
    );
  }
}

class _FinanceGhostChart extends StatelessWidget {
  const _FinanceGhostChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: kTextColorSecondary,
            size: 26,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin movimientos registrados este mes',
              style: TextStyle(
                color: kTextColorSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GhostBar(widthFactor: .92),
                SizedBox(height: 7),
                _GhostBar(widthFactor: .66),
                SizedBox(height: 7),
                _GhostBar(widthFactor: .78),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostBar extends StatelessWidget {
  const _GhostBar({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(16),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _FinanceBar extends StatelessWidget {
  const _FinanceBar({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
  });

  final String label;
  final double value;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            const Spacer(),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withAlpha(18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.month,
    required this.appointments,
    required this.onOpenCalendar,
  });

  final DateTime month;
  final List<Appointment> appointments;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final cells = _buildCalendarCells(month);
    final countsByDay = <int, int>{};
    for (final appointment in appointments) {
      countsByDay.update(
        appointment.dateTime.day,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return _CardShell(
      onTap: onOpenCalendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.calendar_month_outlined,
            iconColor: kInfoColor,
            title: 'Calendario mensual',
            subtitle: 'Vista mensual',
            trailingLabel: _formatMonth(now: month),
          ),
          const SizedBox(height: 6),
          const _WeekdayHeader(),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, gridConstraints) {
              final aspectRatio = gridConstraints.maxWidth >= 360 ? 2.05 : 1.65;
              const spacing = 5.0;
              final cellWidth = (gridConstraints.maxWidth - (spacing * 6)) / 7;
              final cellHeight = cellWidth / aspectRatio;
              final rowCount = (cells.length / 7).ceil();
              final gridHeight =
                  (cellHeight * rowCount) + (spacing * (rowCount - 1));

              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cells.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final day = cells[index];
                    final count = day == null ? 0 : countsByDay[day.day] ?? 0;

                    return _MonthDayCell(
                      day: day,
                      appointmentCount: count,
                      onTap: onOpenCalendar,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            countsByDay.isEmpty
                ? 'Sin eventos este mes'
                : '${countsByDay.length} días con citas este mes',
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 10,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const _InlineCta(label: 'Ver calendario completo'),
        ],
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.appointmentCount,
    required this.onTap,
  });

  final DateTime? day;
  final int appointmentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox.shrink();

    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final hasAppointments = appointmentCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isToday
              ? kPrimaryColor.withAlpha(42)
              : hasAppointments
              ? kInfoColor.withAlpha(26)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? kPrimaryColor.withAlpha(130)
                : hasAppointments
                ? kInfoColor.withAlpha(90)
                : Colors.white.withAlpha(18),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day!.day}',
              style: TextStyle(
                color: isToday ? kPrimaryColor : kTextColor,
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (hasAppointments)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: kInfoColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.appointments,
    required this.clients,
    required this.onOpenCalendar,
  });

  final List<Appointment> appointments;
  final List<Client> clients;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final visibleAppointments = appointments.take(3).toList();

    return _CardShell(
      onTap: onOpenCalendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.view_agenda_outlined,
            iconColor: kPrimaryColor,
            title: 'Agenda de hoy',
            subtitle: appointments.isEmpty
                ? 'Sin citas programadas'
                : '${appointments.length} citas programadas',
          ),
          const SizedBox(height: 14),
          if (appointments.isEmpty)
            const _EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Sin citas programadas para hoy',
            )
          else ...[
            ...visibleAppointments.map((appointment) {
              final client = _findClient(clients, appointment.clientId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AppointmentMiniTile(
                  appointment: appointment,
                  clientName: client?.fullName ?? 'Sin cliente',
                ),
              );
            }),
            if (appointments.length > visibleAppointments.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '+${appointments.length - visibleAppointments.length} citas más',
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          const _InlineCta(label: 'Ver agenda completa'),
        ],
      ),
    );
  }
}

class _AppointmentMiniTile extends StatelessWidget {
  const _AppointmentMiniTile({
    required this.appointment,
    required this.clientName,
  });

  final Appointment appointment;
  final String clientName;

  @override
  Widget build(BuildContext context) {
    final color = _appointmentStatusColor(appointment.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: kInfoColor.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatTime(appointment.dateTime),
              style: const TextStyle(
                color: kInfoColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.type.label,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SmallStatus(label: appointment.status.label, color: color),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        hoverColor: Colors.white.withAlpha(8),
        splashColor: kPrimaryColor.withAlpha(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color.alphaBlend(Colors.white.withAlpha(5), kCardColor),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withAlpha(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(34),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailingLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (trailingLabel != null) ...[
          _SmallStatus(label: trailingLabel!, color: iconColor),
          const SizedBox(width: 6),
        ],
        const Icon(Icons.chevron_right, color: kTextColorSecondary),
      ],
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SmallStatus extends StatelessWidget {
  const _SmallStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _InlineCta extends StatelessWidget {
  const _InlineCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kInfoColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward, color: kInfoColor, size: 15),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kTextColorSecondary, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
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
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: kTextColorSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimaryColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kPrimaryColor.withAlpha(42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kPrimaryColor, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.error_outline,
      title: 'No se pudo cargar el dashboard',
    );
  }
}

List<Appointment> _appointmentsForDay(
  List<Appointment> appointments,
  DateTime day,
) {
  return appointments.where((appointment) {
    return DateUtils.isSameDay(appointment.dateTime, day);
  }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}

List<Appointment> _appointmentsForMonth(
  List<Appointment> appointments,
  DateTime month,
) {
  return appointments.where((appointment) {
    return appointment.dateTime.year == month.year &&
        appointment.dateTime.month == month.month;
  }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}

List<PendingTask> _activePendingTasks(List<PendingTask> tasks) {
  return tasks.where((task) => !task.isResolved).toList()..sort(_sortTasks);
}

List<finance.Transaction> _transactionsForMonth(
  List<finance.Transaction> transactions,
  DateTime month,
) {
  return transactions.where((transaction) {
    return transaction.date.year == month.year &&
        transaction.date.month == month.month;
  }).toList();
}

double _monthlyTotal(
  List<finance.Transaction> transactions,
  finance.TransactionType type,
) {
  return transactions
      .where((transaction) => transaction.type == type)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
}

List<DateTime?> _buildCalendarCells(DateTime month) {
  final first = DateTime(month.year, month.month);
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  final leadingEmptyCells = first.weekday - 1;
  final totalUsedCells = leadingEmptyCells + daysInMonth;
  final trailingEmptyCells = (7 - (totalUsedCells % 7)) % 7;

  return [
    ...List<DateTime?>.filled(leadingEmptyCells, null),
    ...List.generate(daysInMonth, (index) {
      return DateTime(month.year, month.month, index + 1);
    }),
    ...List<DateTime?>.filled(trailingEmptyCells, null),
  ];
}

Client? _findClient(List<Client> clients, String id) {
  for (final client in clients) {
    if (client.id == id) return client;
  }
  return null;
}

int _sortTasks(PendingTask a, PendingTask b) {
  final priorityOrder = {
    PendingTaskPriority.urgent: 0,
    PendingTaskPriority.high: 1,
    PendingTaskPriority.normal: 2,
    PendingTaskPriority.low: 3,
  };
  final priorityCompare = (priorityOrder[a.priority] ?? 99).compareTo(
    priorityOrder[b.priority] ?? 99,
  );
  if (priorityCompare != 0) return priorityCompare;

  final aDue = a.dueDate ?? DateTime(9999);
  final bDue = b.dueDate ?? DateTime(9999);
  return aDue.compareTo(bDue);
}

Color _appointmentStatusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.scheduled:
      return kInfoColor;
    case AppointmentStatus.completed:
      return kSuccessColor;
    case AppointmentStatus.cancelled:
    case AppointmentStatus.noShow:
      return kErrorColor;
  }
}

String _greeting(DateTime now) {
  if (now.hour < 12) return 'Buenos días';
  if (now.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

String _formatLongDate(DateTime date) {
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

String _formatMonthYear(DateTime date) {
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
  return '${months[date.month - 1]} ${date.year}';
}

String _formatMonth({required DateTime now}) {
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
  return months[now.month - 1];
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _money(double value) {
  final rounded = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < rounded.length; index++) {
    final remaining = rounded.length - index;
    buffer.write(rounded[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${value < 0 ? '-' : ''}\$${buffer.toString()}';
}

double _maxDouble(double a, double b, double c, double d) {
  var result = a;
  if (b > result) result = b;
  if (c > result) result = c;
  if (d > result) result = d;
  return result;
}

void _navigate(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
