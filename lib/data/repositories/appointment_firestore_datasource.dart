import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';

/// Datasource para gestionar citas en Firestore
/// Estructura: coaches/{coachId}/appointments/{appointmentId}
class AppointmentFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AppointmentFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Obtener referencia a la colección de appointments del coach actual
  CollectionReference<Map<String, dynamic>>? _appointmentsCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('coaches')
        .doc(userId)
        .collection('appointments');
  }

  /// Stream de todas las citas del coach
  Stream<List<Appointment>> watchAppointments() {
    final collection = _appointmentsCollection();
    if (collection == null) {
      debugPrint('⚠️ AppointmentFirestore.watch: Usuario no autenticado');
      return Stream.value([]);
    }

    return collection.snapshots().map((snapshot) {
      debugPrint(
        '🔄 AppointmentFirestore.watch: ${snapshot.docs.length} documentos',
      );
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Appointment.fromJson(data);
            } catch (e) {
              debugPrint(
                '⚠️ AppointmentFirestore.watch: Error parseando ${doc.id}: $e',
              );
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();
    });
  }

  /// Obtener todas las citas del coach
  Future<List<Appointment>> getAppointments() async {
    final collection = _appointmentsCollection();
    if (collection == null) {
      debugPrint('⚠️ AppointmentFirestore: Usuario no autenticado');
      return [];
    }

    try {
      debugPrint('📥 AppointmentFirestore: Cargando citas...');
      final snapshot = await collection.get();
      debugPrint(
        '✅ AppointmentFirestore: ${snapshot.docs.length} documentos obtenidos',
      );

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Appointment.fromJson(data);
            } catch (e) {
              debugPrint(
                '⚠️ AppointmentFirestore: Error parseando documento ${doc.id}: $e',
              );
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();
    } catch (e, stack) {
      debugPrint('❌ AppointmentFirestore.getAppointments ERROR: $e');
      debugPrint('Stack trace: $stack');
      return [];
    }
  }

  /// Agregar nueva cita
  Future<void> addAppointment(Appointment appointment) async {
    final collection = _appointmentsCollection();
    if (collection == null) return;

    try {
      await collection.doc(appointment.id).set(appointment.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar cita existente
  Future<void> updateAppointment(Appointment appointment) async {
    final collection = _appointmentsCollection();
    if (collection == null) return;

    try {
      await collection.doc(appointment.id).update(appointment.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar cita
  Future<void> deleteAppointment(String appointmentId) async {
    final collection = _appointmentsCollection();
    if (collection == null) return;

    try {
      await collection.doc(appointmentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener citas por rango de fechas
  Future<List<Appointment>> getAppointmentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final collection = _appointmentsCollection();
    if (collection == null) return [];

    try {
      final snapshot = await collection
          .where('dateTime', isGreaterThanOrEqualTo: start)
          .where('dateTime', isLessThanOrEqualTo: end)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Appointment.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener citas de un cliente específico
  Future<List<Appointment>> getClientAppointments(String clientId) async {
    final collection = _appointmentsCollection();
    if (collection == null) return [];

    try {
      final snapshot = await collection
          .where('clientId', isEqualTo: clientId)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Appointment.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
