import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Lista de citas de hoy con acciones rápidas
class TodayAppointmentsWidget extends ConsumerWidget {
  const TodayAppointmentsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final todayAppointments = appointmentsNotifier.getTodayAppointments();
    final clients = ref.watch(clientsProvider).value?.clients ?? [];

    if (todayAppointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_available, size: 48, color: kTextColorSecondary),
            SizedBox(height: 12),
            Text(
              'No hay citas programadas para hoy',
              style: TextStyle(color: kTextColorSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: kPrimaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Hoy - ${DateFormat('dd MMM', 'es').format(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${todayAppointments.length} citas',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...todayAppointments.map((apt) {
            final client = clients.isNotEmpty
                ? clients.firstWhere(
                    (c) => c.id == apt.clientId,
                    orElse: () => clients.first,
                  )
                : null;

            return _AppointmentCard(
              appointment: apt,
              clientName: client?.fullName ?? 'Sin cliente',
              onComplete: () {
                ref
                    .read(appointmentsProvider.notifier)
                    .completeAppointment(apt.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cita marcada como completada'),
                    backgroundColor: kSuccessColor,
                  ),
                );
              },
              onCancel: () {
                ref
                    .read(appointmentsProvider.notifier)
                    .cancelAppointment(apt.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cita cancelada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final String clientName;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.clientName,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        widget.appointment.status == AppointmentStatus.completed;
    final isCancelled =
        widget.appointment.status == AppointmentStatus.cancelled;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1F2E).withAlpha(240),
                const Color(0xFF1A1F2E).withAlpha(230),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? kSuccessColor.withAlpha(80)
                  : isCancelled
                  ? Colors.red.withAlpha(80)
                  : _isHovered
                  ? Colors.white.withAlpha(25)
                  : Colors.white.withAlpha(12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? kSuccessColor.withAlpha(20)
                    : isCancelled
                    ? Colors.red.withAlpha(20)
                    : const Color(0xFF00D9FF).withAlpha(_isHovered ? 15 : 8),
                blurRadius: _elevationAnimation.value + 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Hora con glassmorphism
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00D9FF).withAlpha(35),
                          const Color(0xFF00D9FF).withAlpha(25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00D9FF).withAlpha(50),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Color(0xFF00D9FF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(widget.appointment.dateTime),
                          style: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tipo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(
                        widget.appointment.type,
                      ).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getTypeColor(
                          widget.appointment.type,
                        ).withAlpha(50),
                      ),
                    ),
                    child: Text(
                      '${widget.appointment.type.emoji} ${widget.appointment.type.label}',
                      style: TextStyle(
                        color: _getTypeColor(widget.appointment.type),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Estado
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: kSuccessColor,
                      size: 26,
                    )
                  else if (isCancelled)
                    const Icon(Icons.cancel, color: Colors.red, size: 26),
                ],
              ),
              const SizedBox(height: 16),

              // Cliente con gradiente de avatar
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF00D9FF),
                          Color(0xFF0EA5E9),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.clientName.isNotEmpty
                            ? widget.clientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clientName,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (widget.appointment.notes != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.appointment.notes!,
                            style: const TextStyle(
                              color: kTextColorSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Acciones (solo si no está completada o cancelada)
              if (!isCompleted && !isCancelled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(
                            color: Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(
                            0xFFF59E0B,
                          ).withAlpha(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: widget.onComplete,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Completar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 4,
                          shadowColor: kSuccessColor.withAlpha(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(AppointmentType type) {
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
