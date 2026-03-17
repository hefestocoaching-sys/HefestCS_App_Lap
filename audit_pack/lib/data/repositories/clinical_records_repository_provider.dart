import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository.dart';

/// Provider para el repositorio de clinical records.
///
/// Uso:
/// ```dart
/// final repo = ref.read(clinicalRecordsRepositoryProvider);
/// await repo.pushAnthropometryRecord(clientId, record);
/// ```
final clinicalRecordsRepositoryProvider = Provider<ClinicalRecordsRepository>(
  (ref) => ClinicalRecordsRepository(firestore: FirebaseFirestore.instance),
);
