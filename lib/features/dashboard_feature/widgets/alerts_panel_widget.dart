import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Panel de alertas y recordatorios importantes
class AlertsPanelWidget extends ConsumerWidget {
  const AlertsPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final todayAppointments = appointmentsNotifier.getTodayAppointments();
    final upcomingAppointments = appointmentsNotifier
        .getWeekAppointments()
        .where((apt) => apt.dateTime.isAfter(DateTime.now()))
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.orange[400],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Alertas y Recordatorios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Alertas
          clientsAsync.when(
            data: (clientsState) {
              final alerts = _buildAlerts(
                clientsState.clients,
                todayAppointments.length,
                upcomingAppointments.length,
              );

              if (alerts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: kSuccessColor.withAlpha(128),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Todo en orden',
                          style: TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: alerts
                    .map(
                      (alert) => _buildAlertItem(
                        alert['title']!,
                        alert['subtitle']!,
                        alert['icon'] as IconData,
                        alert['color'] as Color,
                        alert['action'] as VoidCallback?,
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildAlerts(
    List<Client> clients,
    int todayCount,
    int upcomingCount,
  ) {
    final alerts = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Clientes inactivos (pueden necesitar atención)
    final inactiveClients = clients
        .where((c) => c.status == ClientStatus.inactive)
        .toList();
    if (inactiveClients.isNotEmpty) {
      alerts.add({
        'title': '${inactiveClients.length} cliente(s) inactivo(s)',
        'subtitle': 'Considera reactivarlos',
        'icon': Icons.person_off,
        'color': Colors.orange[400]!,
        'action': null,
      });
    }

    // Clientes sin entrenamientos registrados
    final withoutTrainings = clients.where((c) {
      return c.trainingSessions.isEmpty;
    }).toList();

    if (withoutTrainings.isNotEmpty) {
      alerts.add({
        'title':
            '${withoutTrainings.length} cliente(s) sin entrenamientos recientes',
        'subtitle': 'Más de 2 semanas sin registros',
        'icon': Icons.fitness_center,
        'color': Colors.orange[400]!,
        'action': null,
      });
    }

    // Clientes con antropometría desactualizada (más de 30 días)
    final outdatedAnthropometry = clients.where((c) {
      final lastRecord = c.latestAnthropometryRecord;
      if (lastRecord == null) return true;
      return now.difference(lastRecord.date).inDays > 30;
    }).toList();

    if (outdatedAnthropometry.isNotEmpty) {
      alerts.add({
        'title': '${outdatedAnthropometry.length} cliente(s) sin medición',
        'subtitle': 'Más de 30 días sin actualizar antropometría',
        'icon': Icons.monitor_weight_outlined,
        'color': Colors.blue[400]!,
        'action': null,
      });
    }

    // Citas de hoy
    if (todayCount > 0) {
      alerts.add({
        'title': '$todayCount cita(s) hoy',
        'subtitle': 'Revisa tu agenda',
        'icon': Icons.event_available,
        'color': kSuccessColor,
        'action': null,
      });
    }

    // Citas próximas
    if (upcomingCount > 0) {
      alerts.add({
        'title': '$upcomingCount cita(s) esta semana',
        'subtitle': 'Prepara tus sesiones',
        'icon': Icons.calendar_month,
        'color': kPrimaryColor,
        'action': null,
      });
    }

    // Sin alertas
    if (alerts.isEmpty) {
      alerts.add({
        'title': 'Seguimiento completo',
        'subtitle': 'Todos tus clientes están al día',
        'icon': Icons.check_circle,
        'color': kSuccessColor,
        'action': null,
      });
    }

    return alerts;
  }

  Widget _buildAlertItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: color.withAlpha(128),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
