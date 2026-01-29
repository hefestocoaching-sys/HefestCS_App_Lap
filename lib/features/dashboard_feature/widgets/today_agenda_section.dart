import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Sección dominante del HOME: "Agenda de hoy"
/// Muestra timeline de citas con cliente, hora y tipo.
/// Click en item navega al cliente (workspace clínico).
class TodayAgendaSection extends ConsumerWidget {
  const TodayAgendaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final todayAppointments = appointmentsNotifier.getTodayAppointments();
    final clientsAsync = ref.watch(clientsProvider);
    final clients = clientsAsync.value?.clients ?? [];

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agenda de hoy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM', 'es_ES').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: kTextColorSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: todayAppointments.isEmpty
                      ? Colors.grey.withAlpha(38)
                      : kPrimaryColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${todayAppointments.length} ${todayAppointments.length == 1 ? 'cita' : 'citas'}',
                  style: TextStyle(
                    color: todayAppointments.isEmpty
                        ? kTextColorSecondary
                        : kPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contenido
          if (todayAppointments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 48,
                      color: kTextColorSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin citas para este día',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Timeline
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = todayAppointments[index];
                    final isLast = index == todayAppointments.length - 1;

                    // Encontrar cliente
                    dynamic client;
                    for (final c in clients) {
                      if (c.id == appointment.clientId) {
                        client = c;
                        break;
                      }
                    }

                    return _AgendaTimelineItem(
                      appointment: appointment,
                      client: client,
                      isLast: isLast,
                      onTap: () {
                        // TODO: Navegar al cliente
                        // 1. Seleccionar cliente en clientsProvider
                        // 2. Cambiar módulo actual al workspace clínico (HistoryClinic o similar)
                        // 3. NO abrir diálogos, solo cambiar tab/modulo

                        if (client != null) {
                          ref
                              .read(clientsProvider.notifier)
                              .setActiveClientById(client.id);
                          // TODO: Cambiar a módulo clínico (ej. index 1 = HistoryClinic)
                          // Esto requiere acceso a MainShellScreen context
                        }
                      },
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Item de timeline de cita
class _AgendaTimelineItem extends StatelessWidget {
  final Appointment appointment;
  final dynamic client;
  final bool isLast;
  final VoidCallback onTap;

  const _AgendaTimelineItem({
    required this.appointment,
    required this.client,
    required this.isLast,
    required this.onTap,
  });

  String _getTypeLabel(AppointmentType type) {
    return type.label;
  }

  Color _getTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.weeklyCheck:
        return kPrimaryColor;
      case AppointmentType.firstConsult:
        return const Color(0xFF10B981);
      case AppointmentType.measurement:
        return Colors.orange[400]!;
      case AppointmentType.planRenewal:
        return kPrimaryColor;
      case AppointmentType.training:
        return Colors.purple[400]!;
      case AppointmentType.custom:
        return kTextColorSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour =
        '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}';
    final typeColor = _getTypeColor(appointment.type);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAppBarColor.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hora
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hour,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Información de cliente y tipo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client?.fullName ?? 'Sin cliente',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTypeLabel(appointment.type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (appointment.status == AppointmentStatus.completed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kSuccessColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 10,
                                    color: kSuccessColor,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Completada',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: kSuccessColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (appointment.status == AppointmentStatus.cancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cancelada',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[400],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icono de navegación
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: kTextColorSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),

        // Línea del timeline
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 30),
                Container(
                  width: 2,
                  height: 16,
                  color: Colors.white.withAlpha(20),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 0),
      ],
    );
  }
}
