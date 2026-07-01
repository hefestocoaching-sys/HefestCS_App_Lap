import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/utils/firestore_sanitizer.dart';

class RemoteClientSnapshot {
  final String clientId;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final bool deleted;

  RemoteClientSnapshot({
    required this.clientId,
    required this.payload,
    required this.updatedAt,
    required this.deleted,
  });
}

abstract class ClientRemoteDataSource {
  Future<void> upsertClient({
    required String coachId,
    required Client client,
    required bool deleted,
  });

  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  });

  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
    int? limit,
  });
}

void validateRemoteClientPayloadOrThrow({
  required String clientId,
  required Map<String, dynamic> fullPayload,
}) {
  final invalidPath = findInvalidFirestorePath(fullPayload);
  if (invalidPath != null) {
    final invalidPaths = listInvalidFirestorePaths(fullPayload, limit: 12);
    final auditFindings = listFirestoreAuditFindings(fullPayload, limit: 12);
    logger.warning(
      'Remote client sync blocked due to invalid Firestore payload',
      {
        'clientId': clientId,
        'invalidPath': invalidPath,
        'invalidPaths': invalidPaths,
        'auditFindings': auditFindings,
      },
    );
    throw StateError(
      '[SAVE][REMOTE_PAYLOAD_INVALID] '
      'clientId=$clientId invalidPath=$invalidPath',
    );
  }
}

class ClientFirestoreDataSource implements ClientRemoteDataSource {
  final FirebaseFirestore _firestore;
  // Audits disabled in production for performance (500-2000ms savings per save)
  // Enable only in debug mode via: _enableFirestoreAudit = kDebugMode
  static const bool _enableFirestoreAudit = false;
  static const Set<String> _remoteExcludedKeys = {
    'anthropometry',
    'biochemistry',
    'tracking',
    'trainingPlans',
    'trainingWeeks',
    'trainingSessions',
    'trainingLogs',
    'sessionLogs',
    'trainingCycles',
    'trainingHistory',
    'nutritionHistory',
    'trainingEvaluation',
    'exerciseMotivation',
    'gluteSpecializationProfile',
    'mobilityAssessments',
    'movementPatternAssessments',
    'strengthAssessments',
    'volumeToleranceProfiles',
    'psychologicalTrainingProfiles',
  };
  static const Set<String> _trainingExtraWhitelist = {
    'sportDiscipline',
    'trainingYears',
    'trainingMonths',
    'yearsTrainingContinuous',
    'hasTrainedBefore',
    'totalYearsTrainedBefore',
    'hadLongPause',
    'longestPauseMonths',
    'isTrainingNow',
    'monthsTrainingNow',
    'injuries',
    'availableEquipment',
    'barriers',
    'periodizationHistory',
    'priorityExercises',
    'prSquat',
    'prBench',
    'prDeadlift',
    'detailedInjuryHistory',
    'pastVolumeTolerance',
    'typicalRestPeriods',
    'trainingPreferences',
    'competitionDateIso',
    'trainingLevel',
    'trainingLevelLabel',
    'effectiveTrainingState',
    'effectiveTrainingLevel',
    'isReconditioningPhase',
    'volumeToleranceModifier',
    'trainingAge',
    'previousTrainingExperience',
    'daysPerWeek',
    'plannedFrequency',
    'historicalFrequency',
    'timePerSession',
    'timePerSessionBucket',
    'timePerSessionMinutes',
    'planDurationInWeeks',
    'avgSleepHours',
    'perceivedStress',
    'stressLevel',
    'recoveryQuality',
    'sleepBucket',
    'usesAnabolics',
    'isCompetitor',
    'competitionCategory',
    'priorityMusclesPrimary',
    'priorityMusclesSecondary',
    'priorityMusclesTertiary',
    'baseSeries',
    'backFocus',
    'movementRestrictions',
    'movementRestrictionsDetail',
    'selectedPlanStartDateIso',
    'discipline',
    'volumeTolerance',
    'intensityTolerance',
    'restProfile',
    'activeInjuries',
    'injuryRegion',
    'injuryPattern',
    'injurySeverity',
    'injuryStatus',
    'knowsPRs',
    'sessionDurationMinutes',
    'restBetweenSetsSeconds',
    'externalRecovery',
    'strengthLevelClass',
    'workCapacityScore',
    'recoveryHistoryScore',
    'externalRecoverySupport',
    'programNoveltyClass',
    'externalPhysicalStressLevel',
    'dietHabitsClass',
    'nonPhysicalStressLevel2',
    'restQuality2',
    'mevBase',
    'mrvBase',
    'mevAdjustTotal',
    'mrvAdjustTotal',
    'mevIndividual',
    'mrvIndividual',
    'vmeBase',
    'vmrBase',
    'vmeAdjustTotal',
    'vmrAdjustTotal',
    'vmeCalculated',
    'vmrCalculated',
    'vopCalculated',
    'targetSetsByMuscle',
    'mevByMuscle',
    'mrvByMuscle',
    'priorityVolumeSplit',
    'targetSetsByMusclePriority',
    'intensityVolumeSplit',
    'targetSetsByMusclePriorityIntensity',
    'seriesTypePercentSplit',
    'trainingSetupV1',
    'trainingEvaluationSnapshotV1',
    'trainingProgressionStateV1',
    'generatedAtIso',
    'forDateIso',
  };

  ClientFirestoreDataSource(this._firestore);

  @override
  Future<void> upsertClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    final ref = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(client.id);

    final clientJson = client.toJson();
    final sanitizedPayload = sanitizeForFirestore(clientJson);
    final remotePayload = Map<String, dynamic>.from(sanitizedPayload)
      ..removeWhere((key, _) => _remoteExcludedKeys.contains(key));

    final training = remotePayload['training'];
    if (training is Map) {
      final extra = training['extra'];
      if (extra is Map) {
        final filteredExtra = <String, dynamic>{};
        for (final entry in extra.entries) {
          final key = entry.key.toString();
          if (_trainingExtraWhitelist.contains(key)) {
            filteredExtra[key] = entry.value;
          }
        }
        final updatedTraining = Map<String, dynamic>.from(training);
        updatedTraining['extra'] = filteredExtra;
        remotePayload['training'] = updatedTraining;
      }
    }

    List<String> rawInvalidPaths = const [];
    List<String> rawAuditFindings = const [];
    if (_enableFirestoreAudit) {
      rawInvalidPaths = listInvalidFirestorePaths(clientJson, limit: 12);
      if (rawInvalidPaths.isNotEmpty) {
        logger.debug('Firestore raw payload invalid paths detected', {
          'invalidPaths': rawInvalidPaths,
        });
      }
      rawAuditFindings = listFirestoreAuditFindings(clientJson, limit: 12);
      if (rawAuditFindings.isNotEmpty) {
        logger.debug('Firestore raw payload audit findings detected', {
          'auditFindings': rawAuditFindings,
        });
      }
    }

    final fullPayload = <String, dynamic>{
      'payload': remotePayload,
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': deleted,
    };

    validateRemoteClientPayloadOrThrow(
      clientId: client.id,
      fullPayload: fullPayload,
    );

    final jsonStr = _safeJsonEncode(fullPayload);
    if (jsonStr.length > 900000) {
      logger.warning('Client document exceeds Firestore size limit', {
        'bytes': jsonStr.length,
      });
      throw Exception(
        'Client document exceeds Firestore limit (${jsonStr.length} bytes). '
        'Consider moving large arrays to subcollections.',
      );
    }

    if (_enableFirestoreAudit) {
      if (rawInvalidPaths.isNotEmpty || rawAuditFindings.isNotEmpty) {
        logger.debug('Firestore raw payload audit findings detected', {
          'invalidPaths': rawInvalidPaths,
          'auditFindings': rawAuditFindings,
        });
      }

      final trainingMap = fullPayload['payload'] as Map<String, dynamic>;
      final trainingPayload = trainingMap['training'] as Map<String, dynamic>?;
      logger.debug('Preparing client upsert for Firestore', {
        'clientId': client.id,
        'trainingExtraKeys': client.training.extra.keys.toList(),
        'trainingExtraIsMap': trainingPayload?['extra'] is Map,
      });
    }

    try {
      await ref.set(fullPayload, SetOptions(merge: true));
      logger.info('Client synced to Firestore', {'clientId': client.id});
    } on FirebaseException catch (e, st) {
      logger.error('Firestore upsert failed', e, st);
      if (e.code == 'permission-denied') {
        _logPermissionDenied(
          coachId: coachId,
          client: client,
          deleted: deleted,
          stackTrace: st,
          errorCode: e.code,
          errorMessage: e.message,
        );
        throw FirebaseException(
          plugin: e.plugin,
          code: e.code,
          message: e.message,
        );
      }

      rethrow;
    } on PlatformException catch (e, st) {
      final isPermissionDenied =
          e.code == 'permission-denied' ||
          (e.message?.toLowerCase().contains('insufficient permissions') ??
              false);

      if (isPermissionDenied) {
        _logPermissionDenied(
          coachId: coachId,
          client: client,
          deleted: deleted,
          stackTrace: st,
          errorCode: e.code,
          errorMessage: e.message,
          errorType: e.runtimeType.toString(),
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: e.message,
        );
      }

      logger.error('Firestore upsert failed', e, st);
      rethrow;
    } catch (e, st) {
      final message = e.toString().toLowerCase();
      if (message.contains('permission-denied') ||
          message.contains('insufficient permissions')) {
        _logPermissionDenied(
          coachId: coachId,
          client: client,
          deleted: deleted,
          stackTrace: st,
          errorType: e.runtimeType.toString(),
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: e.toString(),
        );
      }

      logger.error('Firestore upsert failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  }) async {
    final ref = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients')
        .doc(clientId);

    final sanitizedMeta = sanitizeForFirestore(metaData);

    if (_enableFirestoreAudit) {
      final invalidPath = findInvalidFirestorePath(sanitizedMeta);
      if (invalidPath != null) {
        logger.warning(
          'Skipping remote client meta sync due to invalid Firestore payload',
          {'invalidPath': invalidPath},
        );
        return;
      }
    }

    await ref.set({
      'id': clientId,
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'meta': sanitizedMeta,
    }, SetOptions(merge: true));
  }

  @override
  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
    int? limit,
  }) async {
    Query query = _firestore
        .collection('coaches')
        .doc(coachId)
        .collection('clients');

    if (since != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(since),
      );
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snap = await query.get();

    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final ts = data['updatedAt'] as Timestamp?;

      return RemoteClientSnapshot(
        clientId: d.id,
        payload: Map<String, dynamic>.from(data['payload'] ?? {}),
        deleted: data['deleted'] == true,
        updatedAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }
}

void _logPermissionDenied({
  required String coachId,
  required Client client,
  required bool deleted,
  required StackTrace? stackTrace,
  String? errorCode,
  String? errorMessage,
  String? errorType,
}) {
  User? authUser;
  try {
    authUser = FirebaseAuth.instance.currentUser;
  } catch (_) {
    authUser = null;
  }

  logger.warning('Firestore permission denied during client upsert', {
    'path': 'coaches/$coachId/clients/${client.id}',
    'authUid': authUser?.uid,
    'authEmail': authUser?.email,
    'isAnonymous': authUser?.isAnonymous,
    'projectId': FirebaseFirestore.instance.app.options.projectId,
    'deleted': deleted,
    'errorCode': errorCode,
    'errorMessage': errorMessage,
    'errorType': errorType,
    'stackTrace': stackTrace?.toString(),
  });
}

String _safeJsonEncode(Object value) {
  return jsonEncode(_normalizeForJson(value));
}

dynamic _normalizeForJson(dynamic value) {
  if (value == null) return null;
  if (value is String || value is bool || value is num) return value;
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  }
  if (value is FieldValue) {
    return value.toString();
  }
  if (value is Blob) {
    return 'Blob(${value.bytes.length})';
  }
  if (value is GeoPoint) {
    return {'lat': value.latitude, 'lng': value.longitude};
  }
  if (value is Uint8List) {
    return 'Uint8List(${value.length})';
  }
  if (value is Enum) {
    return value.name;
  }
  if (value is Iterable) {
    return value.map(_normalizeForJson).toList();
  }
  if (value is Map) {
    final normalized = <String, dynamic>{};
    value.forEach((key, nestedValue) {
      normalized[key.toString()] = _normalizeForJson(nestedValue);
    });
    return normalized;
  }
  return value.toString();
}
