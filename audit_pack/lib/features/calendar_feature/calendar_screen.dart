import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/appointments_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Pantalla de gestión del Calendario/Citas
///
/// Placeholder mínimo con estética existente.
/// Muestra las citas próximas si hay, o mensaje de placeholder.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(globalDateProvider);
    final appointments = ref.watch(appointmentsProvider);
    final allAppointmentsCount = appointments.length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Calendario de Revisiones'),
        backgroundColor: kAppBarColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              const Text(
                'Gestión de Citas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha seleccionada: ${DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(selectedDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: kTextColorSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Contenido placeholder
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: kPrimaryColor.withAlpha(150),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Calendario en construcción',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      allAppointmentsCount == 0
                          ? 'Sin citas registradas.'
                          : 'Tienes $allAppointmentsCount cita${allAppointmentsCount > 1 ? 's' : ''} registrada${allAppointmentsCount > 1 ? 's' : ''}.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: kTextColorSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver al Inicio'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: BorderSide(color: kPrimaryColor.withAlpha(100)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
