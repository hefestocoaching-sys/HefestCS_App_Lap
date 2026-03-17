import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/domain/entities/appointment.dart';
import 'package:hcs_app_lap/utils/firestore_sanitizer.dart';

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
      logger.warning('Appointment watch requested without auth');
      return Stream.value([]);
    }

    return collection.snapshots().map((snapshot) {
      logger.debug('Appointment watch snapshot received', {
        'count': snapshot.docs.length,
      });
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Appointment.fromJson(data);
            } catch (e) {
              logger.warning('Appointment watch parse failed', {
                'appointmentId': doc.id,
                'error': e.toString(),
              });
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
      logger.warning('Appointment list requested without auth');
      return [];
    }

    try {
      logger.debug('Loading appointments');
      final snapshot = await collection
          .orderBy('date', descending: true)
          .limit(100)
          .get();
      logger.debug('Appointments loaded', {'count': snapshot.docs.length});

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Appointment.fromJson(data);
            } catch (e) {
              logger.warning('Appointment parse failed', {
                'appointmentId': doc.id,
                'error': e.toString(),
              });
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();
    } catch (e, stack) {
      logger.error('Failed to load appointments', e, stack);
      return [];
    }
  }

  /// Agregar nueva cita
  Future<void> addAppointment(Appointment appointment) async {
    final collection = _appointmentsCollection();
    if (collection == null) return;

    try {
      final payload = sanitizeForFirestore(appointment.toJson());
      final invalidPath = findInvalidFirestorePath(payload);
      if (invalidPath != null) {
        logger.warning('Firestore payload invalid', {'path': invalidPath});
      }
      await collection.doc(appointment.id).set(payload);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar cita existente
  Future<void> updateAppointment(Appointment appointment) async {
    final collection = _appointmentsCollection();
    if (collection == null) return;

    try {
      final payload = sanitizeForFirestore(appointment.toJson());
      final invalidPath = findInvalidFirestorePath(payload);
      if (invalidPath != null) {
        logger.warning('Firestore payload invalid', {'path': invalidPath});
      }
      await collection.doc(appointment.id).update(payload);
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
