import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/data/repositories/appointment_firestore_datasource.dart';

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  late final AppointmentFirestoreDataSource _datasource;

  @override
  List<Appointment> build() {
    _datasource = AppointmentFirestoreDataSource();
    _loadAppointments();
    return [];
  }

  /// Cargar citas desde Firestore
  Future<void> _loadAppointments() async {
    try {
      debugPrint('📋 AppointmentsProvider: Iniciando carga...');
      final appointments = await _datasource.getAppointments();
      debugPrint(
        '✅ AppointmentsProvider: ${appointments.length} citas cargadas',
      );
      state = appointments;
    } catch (e, stack) {
      debugPrint('❌ AppointmentsProvider._loadAppointments ERROR: $e');
      debugPrint('Stack trace: $stack');
      state = [];
    }
  }

  /// Recargar citas
  Future<void> refresh() async {
    await _loadAppointments();
  }

  /// Agregar nueva cita
  Future<void> addAppointment(Appointment appointment) async {
    try {
      await _datasource.addAppointment(appointment);
      state = [...state, appointment];
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar cita existente
  Future<void> updateAppointment(Appointment updated) async {
    try {
      await _datasource.updateAppointment(updated);
      state = [
        for (final apt in state)
          if (apt.id == updated.id) updated else apt,
      ];
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar cita
  Future<void> deleteAppointment(String id) async {
    try {
      await _datasource.deleteAppointment(id);
      state = state.where((apt) => apt.id != id).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Marcar cita como completada
  Future<void> completeAppointment(String id) async {
    final now = DateTime.now();
    final apt = state.firstWhere((a) => a.id == id);
    await updateAppointment(
      apt.copyWith(status: AppointmentStatus.completed, completedAt: now),
    );
  }

  /// Cancelar cita
  Future<void> cancelAppointment(String id) async {
    final apt = state.firstWhere((a) => a.id == id);
    await updateAppointment(apt.copyWith(status: AppointmentStatus.cancelled));
  }

  /// Obtener citas por fecha
  List<Appointment> getAppointmentsByDate(DateTime date) {
    return state.where((apt) {
      return apt.dateTime.year == date.year &&
          apt.dateTime.month == date.month &&
          apt.dateTime.day == date.day;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Obtener citas de hoy
  List<Appointment> getTodayAppointments() {
    return getAppointmentsByDate(DateTime.now());
  }

  /// Obtener citas de esta semana
  List<Appointment> getWeekAppointments({DateTime? startOfWeek}) {
    final weekStart = startOfWeek ?? _getStartOfWeek(DateTime.now());
    final endOfWeek = weekStart.add(const Duration(days: 7));
    return state.where((apt) {
      return apt.dateTime.isAfter(weekStart) &&
          apt.dateTime.isBefore(endOfWeek);
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Obtener inicio de la semana (lunes)
  DateTime _getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
      () => AppointmentsNotifier(),
    );
