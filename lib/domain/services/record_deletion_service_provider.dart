import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';
import 'package:hcs_app_lap/domain/services/record_deletion_service.dart';

/// Provider para RecordDeletionService.
///
/// Uso:
/// ```dart
/// final service = ref.read(recordDeletionServiceProvider);
/// await service.deleteAnthropometryByDate(
///   clientId: clientId,
///   date: selectedDate,
/// );
/// ```
final recordDeletionServiceProvider = Provider<RecordDeletionService>(
  (ref) => RecordDeletionService(
    clinicalRecordsRepository: ref.read(clinicalRecordsRepositoryProvider),
    legacyRecordDataSource: RecordFirestoreDataSource(
      FirebaseFirestore.instance,
    ),
  ),
);
