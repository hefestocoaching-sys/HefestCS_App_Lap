import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/navigation/client_navigation.dart';
import 'package:hcs_app_lap/core/navigation/client_open_origin.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/transactions_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/alerts_panel_widget.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/financial_summary_widget.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/pending_tasks_section.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/quick_actions_panel.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/quick_stat_card.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/today_agenda_section.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/today_appointments_widget.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/today_date_block.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/weekly_calendar_widget.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Pantalla principal del Dashboard
///
/// Muestra:
/// - Estadísticas rápidas (clientes, ingresos, gastos, ganancia)
/// - Calendario semanal de citas
/// - Citas de hoy
/// - Resumen financiero mensual
/// - Alertas y recordatorios
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final now = DateTime.now();

    final activeClientId = clientsAsync.value?.activeClient?.id;

    final monthlyIncome = transactionsNotifier.getMonthlyIncome(now);
    final monthlyExpenses = transactionsNotifier.getMonthlyExpenses(now);
    final monthlyProfit = monthlyIncome - monthlyExpenses;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloque "HOY" con fecha seleccionada
              const TodayDateBlock(),
              const SizedBox(height: 24),

              // Sección dominante: Agenda de hoy
              const TodayAgendaSection(),
              const SizedBox(height: 24),

              // Bloque de pendientes
              const PendingTasksSection(),
              const SizedBox(height: 24),

              // Header
              _buildHeader(context: context, activeClientId: activeClientId),
              const SizedBox(height: 24),

              // Stats rápidos
              clientsAsync.when(
                data: (clientsState) {
                  final allClients = clientsState.clients;
                  final activeClients = allClients.where((c) {
                    return c.status == ClientStatus.active;
                  }).length;

                  return _buildQuickStats(
                    totalClients: allClients.length,
                    activeClients: activeClients,
                    monthlyIncome: monthlyIncome,
                    monthlyExpenses: monthlyExpenses,
                    monthlyProfit: monthlyProfit,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Calendario semanal
              const WeeklyCalendarWidget(),
              const SizedBox(height: 24),

              // Layout de dos columnas para escritorio, apilado en móvil
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna izquierda (60%)
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              const TodayAppointmentsWidget(),
                              const SizedBox(height: 24),
                              const FinancialSummaryWidget(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Columna derecha (40%)
                        const Expanded(flex: 4, child: AlertsPanelWidget()),
                      ],
                    );
                  } else {
                    return const Column(
                      children: [
                        TodayAppointmentsWidget(),
                        SizedBox(height: 24),
                        AlertsPanelWidget(),
                        SizedBox(height: 24),
                        FinancialSummaryWidget(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),

              // Panel de acciones rápidas
              const QuickActionsPanel(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String? activeClientId,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Aquí tienes un resumen de tu negocio',
          style: TextStyle(fontSize: 14, color: kTextColorSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                openClientChart(context, '', ClientOpenOrigin.clients);
              },
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text('Abrir clientes'),
            ),
            if (activeClientId != null)
              OutlinedButton.icon(
                onPressed: () {
                  openClientChart(
                    context,
                    activeClientId,
                    ClientOpenOrigin.home,
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Continuar con cliente'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats({
    required int totalClients,
    required int activeClients,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double monthlyProfit,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final crossAxisCount = isWide ? 4 : 2;
        final childAspectRatio = isWide ? 1.4 : 1.2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            QuickStatCard(
              icon: Icons.people,
              iconColor: kPrimaryColor,
              title: 'Clientes Activos',
              value: '$activeClients',
              subtitle: 'de $totalClients totales',
              trend: activeClients > 0 ? '+$activeClients' : null,
              isPositive: true,
              onTap: () {
                // TODO: Navegar a lista de clientes
              },
            ),
            QuickStatCard(
              icon: Icons.arrow_upward,
              iconColor: kSuccessColor,
              title: 'Ingresos del Mes',
              value: formatMXN(monthlyIncome),
              subtitle: 'Total ingresado',
              trend: monthlyIncome > 0 ? '+${formatMXN(monthlyIncome)}' : null,
              isPositive: true,
              onTap: () {
                // TODO: Navegar a detalles financieros
              },
            ),
            QuickStatCard(
              icon: Icons.arrow_downward,
              iconColor: Colors.red[400]!,
              title: 'Gastos del Mes',
              value: formatMXN(monthlyExpenses),
              subtitle: 'Total gastado',
              trend: monthlyExpenses > 0 ? formatMXN(monthlyExpenses) : null,
              isPositive: false,
              onTap: () {
                // TODO: Navegar a detalles financieros
              },
            ),
            QuickStatCard(
              icon: Icons.trending_up,
              iconColor: monthlyProfit >= 0 ? kSuccessColor : Colors.red[400]!,
              title: 'Ganancia Neta',
              value: formatMXN(monthlyProfit),
              subtitle: 'Ingresos - Gastos',
              trend: monthlyProfit != 0 ? formatMXN(monthlyProfit.abs()) : null,
              isPositive: monthlyProfit >= 0,
              onTap: () {
                // TODO: Navegar a resumen financiero
              },
            ),
          ],
        );
      },
    );
  }
}
