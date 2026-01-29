import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';

/// Repositorio para gestionar citas (Firestore + caché local)
class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  /// Obtener todas las citas de un entrenador
  Stream<List<Appointment>> getAppointmentsStream(String trainerId) {
    return _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Obtener citas por rango de fechas
  Stream<List<Appointment>> getAppointmentsByDateRange(
    String trainerId,
    DateTime start,
    DateTime end,
  ) {
    return _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .where('dateTime', isGreaterThanOrEqualTo: start)
        .where('dateTime', isLessThan: end)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Obtener citas de hoy
  Stream<List<Appointment>> getTodayAppointments(String trainerId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getAppointmentsByDateRange(trainerId, startOfDay, endOfDay);
  }

  /// Obtener citas de la semana
  Stream<List<Appointment>> getWeekAppointments(
    String trainerId, {
    DateTime? startOfWeek,
  }) {
    final weekStart = startOfWeek ?? _getStartOfWeek(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 7));

    return getAppointmentsByDateRange(trainerId, weekStart, weekEnd);
  }

  /// Crear nueva cita
  Future<String> createAppointment(
    String trainerId,
    Appointment appointment,
  ) async {
    final docRef = await _firestore.collection(_collection).add({
      ...appointment.toJson(),
      'trainerId': trainerId,
      'id': null, // Firestore generará el ID
    });

    return docRef.id;
  }

  /// Actualizar cita existente
  Future<void> updateAppointment(Appointment appointment) async {
    await _firestore
        .collection(_collection)
        .doc(appointment.id)
        .update(appointment.toJson());
  }

  /// Eliminar cita
  Future<void> deleteAppointment(String appointmentId) async {
    await _firestore.collection(_collection).doc(appointmentId).delete();
  }

  /// Marcar cita como completada
  Future<void> completeAppointment(String appointmentId) async {
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': AppointmentStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancelar cita
  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': AppointmentStatus.cancelled.name,
    });
  }

  /// Obtener inicio de la semana (lunes)
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday - 1));
  }
}
