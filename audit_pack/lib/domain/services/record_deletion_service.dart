import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';

/// Servicio para borrado seguro de registros por fecha.
///
/// Características:
/// - Solo borra el registro de una fecha específica
/// - No afecta otros registros
/// - Sin recalcular planes
/// - Fire-and-forget: borrado en background sin bloquear UI
///
/// Uso:
/// ```dart
/// final service = RecordDeletionService(FirebaseFirestore.instance);
/// await service.deleteAnthropometryByDate(
///   clientId: 'client-123',
///   date: DateTime(2025, 01, 15),
///   onError: (e) => debugPrint('Error: $e'),
/// );
/// ```
class RecordDeletionService {
  final RecordFirestoreDataSource _recordDataSource;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  RecordDeletionService(FirebaseFirestore firestore)
    : _recordDataSource = RecordFirestoreDataSource(firestore);

  /// Obtiene el ID del coach autenticado
  String? _getAuthenticatedCoachId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Borra el registro de antropometría para una fecha específica.
  ///
  /// - Elimina SOLO el documento de esa fecha
  /// - No afecta registros de otras fechas
  /// - No recalcula nada
  /// - Fire-and-forget en background
  ///
  /// Parámetros:
  /// - clientId: ID del cliente
  /// - date: Fecha a borrar (se usa solo yyyy-MM-dd)
  /// - onError: Callback opcional para errores (e.g., logging)
  Future<void> deleteAnthropometryByDate({
    required String clientId,
    required DateTime date,
    Function(Exception)? onError,
  }) async {
    try {
      final coachId = _getAuthenticatedCoachId();
      if (coachId == null) {
        throw Exception('No authenticated user');
      }

      final dateKey = _dateFormat.format(date);

      // Soft delete: marca el registro como eliminado
      await _recordDataSource.deleteRecord(
        coachId: coachId,
        clientId: clientId,
        domain: RecordDomain.anthropometry,
        dateKey: dateKey,
      );
    } catch (e) {
      if (onError != null && e is Exception) {
        onError(e);
      } else {
        rethrow;
      }
    }
  }

  /// Borra el registro de nutrición para una fecha específica.
  ///
  /// - Elimina SOLO el documento de esa fecha
  /// - No recalcula planes
  /// - Fire-and-forget
  ///
  /// Parámetros:
  /// - clientId: ID del cliente
  /// - date: Fecha a borrar
  /// - onError: Callback opcional para errores
  Future<void> deleteNutritionByDate({
    required String clientId,
    required DateTime date,
    Function(Exception)? onError,
  }) async {
    try {
      final coachId = _getAuthenticatedCoachId();
      if (coachId == null) {
        throw Exception('No authenticated user');
      }

      final dateKey = _dateFormat.format(date);

      // Soft delete: marca el registro como eliminado
      await _recordDataSource.deleteRecord(
        coachId: coachId,
        clientId: clientId,
        domain: RecordDomain.nutrition,
        dateKey: dateKey,
      );
    } catch (e) {
      if (onError != null && e is Exception) {
        onError(e);
      } else {
        rethrow;
      }
    }
  }

  /// Borra el registro de entrenamiento para una fecha específica.
  ///
  /// - Elimina SOLO el documento de esa fecha
  /// - No modifica el plan de entrenamiento
  /// - No recalcula próximas semanas
  /// - Fire-and-forget
  ///
  /// Parámetros:
  /// - clientId: ID del cliente
  /// - date: Fecha a borrar
  /// - onError: Callback opcional para errores
  Future<void> deleteTrainingByDate({
    required String clientId,
    required DateTime date,
    Function(Exception)? onError,
  }) async {
    try {
      final coachId = _getAuthenticatedCoachId();
      if (coachId == null) {
        throw Exception('No authenticated user');
      }

      final dateKey = _dateFormat.format(date);

      // Soft delete: marca el registro como eliminado
      await _recordDataSource.deleteRecord(
        coachId: coachId,
        clientId: clientId,
        domain: RecordDomain.training,
        dateKey: dateKey,
      );
    } catch (e) {
      if (onError != null && e is Exception) {
        onError(e);
      } else {
        rethrow;
      }
    }
  }

  /// Borra el registro de bioquímica para una fecha específica.
  ///
  /// - Elimina SOLO el documento de esa fecha
  /// - No afecta otros registros
  /// - Fire-and-forget
  ///
  /// Parámetros:
  /// - clientId: ID del cliente
  /// - date: Fecha a borrar
  /// - onError: Callback opcional para errores
  Future<void> deleteBiochemistryByDate({
    required String clientId,
    required DateTime date,
    Function(Exception)? onError,
  }) async {
    try {
      final coachId = _getAuthenticatedCoachId();
      if (coachId == null) {
        throw Exception('No authenticated user');
      }

      final dateKey = _dateFormat.format(date);

      // Soft delete: marca el registro como eliminado
      await _recordDataSource.deleteRecord(
        coachId: coachId,
        clientId: clientId,
        domain: RecordDomain.biochemistry,
        dateKey: dateKey,
      );
    } catch (e) {
      if (onError != null && e is Exception) {
        onError(e);
      } else {
        rethrow;
      }
    }
  }
}
