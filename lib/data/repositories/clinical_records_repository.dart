import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/data/datasources/remote/anthropometry_firestore_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/record_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/biochemistry_record.dart';
import 'package:intl/intl.dart';

/// Repositorio para push granular de clinical records a Firestore.
///
/// Responsabilidades:
/// - Push fire-and-forget de records individuales por dominio
/// - NO afecta guardado local (local sigue siendo fuente de verdad)
/// - NO falla operaciones si Firestore no está disponible
///
/// Uso:
/// ```dart
/// final repo = ref.read(clinicalRecordsRepositoryProvider);
///
/// // Después de guardar local exitosamente
/// await repo.pushAnthropometryRecord(clientId, record);
/// ```
class ClinicalRecordsRepository {
  final AnthropometryFirestoreDataSource _anthropometryDataSource;
  final RecordFirestoreDataSource _genericRecordDataSource;
  final FirebaseFirestore _firestore;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  ClinicalRecordsRepository({required FirebaseFirestore firestore})
    : _firestore = firestore,
      _anthropometryDataSource = AnthropometryFirestoreDataSource(firestore),
      _genericRecordDataSource = RecordFirestoreDataSource(firestore);

  /// Push de un registro de antropometría a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/anthropometry_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: Lanza en background sin bloquear
  void pushAnthropometryRecord(String clientId, AnthropometryRecord record) {
    // Ejecuta en background completamente desacoplado
    _pushInBackground(() => _doPushAnthropometryRecord(clientId, record));
  }

  Future<void> _doPushAnthropometryRecord(
    String clientId,
    AnthropometryRecord record,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('Warning: No authenticated user - skipping Firestore sync');
      return;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = _firestore
          .collection('coaches')
          .doc(user.uid)
          .collection('clients')
          .doc(clientId);

      // Check if client exists, create stub if not
      // Use timeout to prevent hanging
      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          // Create a stub client document so the subcollections can be written
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
        // If client check/creation fails, continue anyway
        // Local storage will still work
        developer.log('Warning: Could not ensure client exists in Firestore: $e');
      }

      // Now push the anthropometry record
      await _anthropometryDataSource
          .upsertAnthropometryRecord(
            coachId: user.uid,
            clientId: clientId,
            record: record,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
    } catch (e) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
      developer.log('Note: Firestore sync failed (local save succeeded): $e');
    }
  }

  /// Push de un registro de bioquímica a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/biochemistry_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: No bloquea (síncrono)
  void pushBiochemistryRecord(String clientId, BioChemistryRecord record) {
    _pushInBackground(() => _doPushBiochemistryRecord(clientId, record));
  }

  Future<void> _doPushBiochemistryRecord(
    String clientId,
    BioChemistryRecord record,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('Warning: No authenticated user - skipping Firestore sync');
      return;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = _firestore
          .collection('coaches')
          .doc(user.uid)
          .collection('clients')
          .doc(clientId);

      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
          developer.log('Warning: Could not ensure client exists in Firestore: $e');
      }

      final dateKey = _dateFormat.format(record.date);
      final payload = record.toJson();
      final hasData = payload.entries.any(
        (e) => e.key != 'date' && e.value != null,
      );

      if (!hasData) {
        // Evita escribir registros vacíos (solo fecha) que disparan errores de reglas
        return;
      }

      await _genericRecordDataSource
          .upsertRecordByDate(
            coachId: user.uid,
            clientId: clientId,
            domain: RecordDomain.biochemistry,
            dateKey: dateKey,
            payload: payload,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
    } catch (e) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
        developer.log('Note: Firestore sync failed (local save succeeded): $e');
    }
  }

  /// Push de un registro de nutrición a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/nutrition_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: No bloquea (síncrono)
  void pushNutritionRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) {
    _pushInBackground(() => _doPushNutritionRecord(clientId, recordJson, date));
  }

  Future<void> _doPushNutritionRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('Warning: No authenticated user - skipping Firestore sync');
      return;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = _firestore
          .collection('coaches')
          .doc(user.uid)
          .collection('clients')
          .doc(clientId);

      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
          developer.log('Warning: Could not ensure client exists in Firestore: $e');
      }

      final dateKey = _dateFormat.format(date);

      await _genericRecordDataSource
          .upsertRecordByDate(
            coachId: user.uid,
            clientId: clientId,
            domain: RecordDomain.nutrition,
            dateKey: dateKey,
            payload: recordJson,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
    } catch (e) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
        developer.log('Note: Firestore sync failed (local save succeeded): $e');
    }
  }

  /// Push de un registro de entrenamiento a Firestore.
  ///
  /// Path: coaches/{coachId}/clients/{clientId}/training_records/{yyyy-MM-dd}
  ///
  /// Fire-and-forget: No bloquea (síncrono)
  void pushTrainingRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) {
    // Temporal: no se sincroniza entrenamiento a Firestore para evitar errores de payload.
    // La persistencia local sigue siendo fuente de verdad.
    return;
  }

  // ignore: unused_element
  Future<void> _doPushTrainingRecord(
    String clientId,
    Map<String, dynamic> recordJson,
    DateTime date,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('Warning: No authenticated user - skipping Firestore sync');
      return;
    }

    try {
      // Attempt to push to Firestore, but don't block if it fails
      // The local storage is the source of truth

      // Ensure client document exists before writing records
      final clientRef = _firestore
          .collection('coaches')
          .doc(user.uid)
          .collection('clients')
          .doc(clientId);

      try {
        final clientSnapshot = await clientRef.get().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Client check timeout'),
        );

        if (!clientSnapshot.exists) {
          await clientRef
              .set({
                'id': clientId,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () =>
                    throw TimeoutException('Client creation timeout'),
              );
        }
      } catch (e) {
          developer.log('Warning: Could not ensure client exists in Firestore: $e');
      }

      final dateKey = _dateFormat.format(date);

      await _genericRecordDataSource
          .upsertRecordByDate(
            coachId: user.uid,
            clientId: clientId,
            domain: RecordDomain.training,
            dateKey: dateKey,
            payload: recordJson,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Record push timeout'),
          );
    } catch (e) {
      // Fire-and-forget: Log the error but don't fail
      // The local save already succeeded, Firestore is just a bonus
        developer.log('Note: Firestore sync failed (local save succeeded): $e');
    }
  }

  /// Helper para ejecutar operaciones completamente en background
  /// sin conexión con el flujo principal
  void _pushInBackground(Future<void> Function() operation) {
    // Ejecuta en un Future independiente y captura cualquier error
    unawaited(
      Future<void>(() async {
        try {
          await operation();
        } catch (e, st) {
            developer.log('Background push failed: $e');
            developer.log(st.toString());
        }
      }),
    );
  }
}
