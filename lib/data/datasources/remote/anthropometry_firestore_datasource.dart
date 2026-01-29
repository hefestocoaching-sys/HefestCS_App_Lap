// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:intl/intl.dart';

/// Datasource específico para AnthropometryRecords en Firestore.
///
/// Usa [RecordFirestoreDataSource] genérico y provee métodos
/// específicos de dominio con tipado fuerte.
class AnthropometryFirestoreDataSource {
  final RecordFirestoreDataSource _recordDataSource;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  AnthropometryFirestoreDataSource(FirebaseFirestore firestore)
    : _recordDataSource = RecordFirestoreDataSource(firestore);

  /// Guarda o actualiza un registro de antropometría por fecha.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/anthropometry_records/{yyyy-MM-dd}
  ///
  /// Ejemplo:
  /// ```dart
  /// final record = AnthropometryRecord(
  ///   date: DateTime(2025, 1, 15),
  ///   weightKg: 75.5,
  ///   heightCm: 175.0,
  /// );
  ///
  /// await datasource.upsertAnthropometryRecord(
  ///   coachId: 'coach123',
  ///   clientId: 'client456',
  ///   record: record,
  /// );
  /// ```
  Future<void> upsertAnthropometryRecord({
    required String coachId,
    required String clientId,
    required AnthropometryRecord record,
    bool deleted = false,
  }) async {
    try {
      final dateKey = _dateFormat.format(record.date);

      await _recordDataSource.upsertRecordByDate(
        coachId: coachId,
        clientId: clientId,
        domain: RecordDomain.anthropometry,
        dateKey: dateKey,
        payload: record.toJson(),
        deleted: deleted,
      );
    } catch (e) {
      print('Error in upsertAnthropometryRecord: $e');
      rethrow;
    }
  }

  /// Obtiene todos los registros de antropometría de un cliente.
  ///
  /// - [since]: Opcional, solo registros actualizados después de esta fecha
  ///
  /// Ejemplo:
  /// ```dart
  /// final records = await datasource.fetchAnthropometryRecords(
  ///   coachId: 'coach123',
  ///   clientId: 'client456',
  /// );
  ///
  /// for (final record in records) {
  ///   print('${record.date}: ${record.weightKg} kg');
  /// }
  /// ```
  Future<List<AnthropometryRecord>> fetchAnthropometryRecords({
    required String coachId,
    required String clientId,
    DateTime? since,
  }) async {
    final snapshots = await _recordDataSource.fetchRecords(
      coachId: coachId,
      clientId: clientId,
      domain: RecordDomain.anthropometry,
      since: since,
    );

    return snapshots
        .where((snap) => !snap.deleted)
        .map((snap) => AnthropometryRecord.fromJson(snap.payload))
        .toList();
  }

  /// Marca un registro de antropometría como eliminado (soft delete).
  ///
  /// - [date]: Fecha del registro a eliminar
  ///
  /// Ejemplo:
  /// ```dart
  /// await datasource.deleteAnthropometryRecord(
  ///   coachId: 'coach123',
  ///   clientId: 'client456',
  ///   date: DateTime(2025, 1, 15),
  /// );
  /// ```
  Future<void> deleteAnthropometryRecord({
    required String coachId,
    required String clientId,
    required DateTime date,
  }) async {
    final dateKey = _dateFormat.format(date);

    await _recordDataSource.deleteRecord(
      coachId: coachId,
      clientId: clientId,
      domain: RecordDomain.anthropometry,
      dateKey: dateKey,
    );
  }

  /// Helper: Convierte DateTime a dateKey (yyyy-MM-dd).
  String dateToKey(DateTime date) => _dateFormat.format(date);

  /// Helper: Convierte dateKey (yyyy-MM-dd) a DateTime.
  DateTime keyToDate(String dateKey) => _dateFormat.parse(dateKey);
}
