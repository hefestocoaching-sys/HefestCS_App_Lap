import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository.dart';
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
/// final service = ref.read(recordDeletionServiceProvider);
/// await service.deleteAnthropometryByDate(
///   clientId: 'client-123',
///   date: DateTime(2025, 01, 15),
///   onError: (e) => debugPrint('Error: $e'),
/// );
/// ```
class RecordDeletionService {
  final ClinicalRecordsRepository _clinicalRecordsRepository;
  final RecordRemoteDataSource? _legacyRecordDataSource;
  final String? Function() _currentCoachIdProvider;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  RecordDeletionService({
    required ClinicalRecordsRepository clinicalRecordsRepository,
    RecordRemoteDataSource? legacyRecordDataSource,
    String? Function()? currentCoachIdProvider,
  }) : _clinicalRecordsRepository = clinicalRecordsRepository,
       _legacyRecordDataSource = legacyRecordDataSource,
       _currentCoachIdProvider =
           currentCoachIdProvider ?? _defaultCurrentCoachId;

  /// Obtiene el ID del coach autenticado para rutas legacy sin outbox.
  String? _getAuthenticatedCoachId() {
    return _currentCoachIdProvider();
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
      await _clinicalRecordsRepository.deleteAnthropometryRecord(
        clientId,
        date,
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
      await _deleteLegacyRemoteRecord(
        clientId: clientId,
        domain: RecordDomain.nutrition,
        date: date,
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
      await _deleteLegacyRemoteRecord(
        clientId: clientId,
        domain: RecordDomain.training,
        date: date,
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
      await _clinicalRecordsRepository.deleteBiochemistryRecord(
        clientId,
        date,
      );
    } catch (e) {
      if (onError != null && e is Exception) {
        onError(e);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteLegacyRemoteRecord({
    required String clientId,
    required RecordDomain domain,
    required DateTime date,
  }) async {
    final coachId = _getAuthenticatedCoachId();
    if (coachId == null) {
      throw Exception('No authenticated user');
    }

    final recordDataSource = _legacyRecordDataSource;
    if (recordDataSource == null) {
      throw Exception('No remote record datasource');
    }

    await recordDataSource.deleteRecord(
      coachId: coachId,
      clientId: clientId,
      domain: domain,
      dateKey: _dateFormat.format(date),
    );
  }
}

String? _defaultCurrentCoachId() {
  return FirebaseAuth.instance.currentUser?.uid;
}
