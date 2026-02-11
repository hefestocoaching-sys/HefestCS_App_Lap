import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ClientFirestoreDataSource implements ClientRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const bool _enableFirestoreAudit = true;
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
    'movementRestrictions',
    'movementRestrictionsDetail',
    'selectedPlanStartDateIso',
    'discipline',
    'volumeTolerance',
    'intensityTolerance',
    'restProfile',
    'activeInjuries',
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

    // ESTRUCTURA ESTANDARIZADA: {payload, schemaVersion, updatedAt, deleted}
    // El payload contiene el Client.toJson() completo, sanitizado para Firestore
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

    String? invalidPath;
    List<String> invalidPaths = const [];
    List<String> auditFindings = const [];
    if (_enableFirestoreAudit) {
      invalidPath = findInvalidFirestorePath(fullPayload);
      invalidPaths = listInvalidFirestorePaths(fullPayload, limit: 12);
      auditFindings = listFirestoreAuditFindings(fullPayload, limit: 12);
      final hasAuditFindings =
          invalidPath != null ||
          invalidPaths.isNotEmpty ||
          auditFindings.isNotEmpty;
      if (hasAuditFindings) {
        logger.debug('Firestore payload audit findings detected', {
          'invalidPath': invalidPath,
          'invalidPaths': invalidPaths,
          'auditFindings': auditFindings,
        });
      }

      final training = fullPayload['payload'] as Map<String, dynamic>;
      final trainingPayload = training['training'] as Map<String, dynamic>?;
      logger.debug('Preparing client upsert for Firestore', {
        'clientId': client.id,
        'trainingExtraKeys': client.training.extra.keys.toList(),
        'trainingExtraIsMap': trainingPayload?['extra'] is Map,
      });
    }

    if (_enableFirestoreAudit) {
      final hasAuditIssues =
          rawInvalidPaths.isNotEmpty ||
          rawAuditFindings.isNotEmpty ||
          invalidPath != null ||
          invalidPaths.isNotEmpty ||
          auditFindings.isNotEmpty;
      if (hasAuditIssues) {
        logger.warning(
          'Skipping remote client sync due to invalid Firestore payload',
          {
            'hasRawInvalidPaths': rawInvalidPaths.isNotEmpty,
            'hasRawAuditFindings': rawAuditFindings.isNotEmpty,
            'hasInvalidPath': invalidPath != null,
            'hasInvalidPaths': invalidPaths.isNotEmpty,
            'hasAuditFindings': auditFindings.isNotEmpty,
          },
        );
        return;
      }
    }

    try {
      // ✅ OBLIGATORIO: SetOptions(merge: true) para no perder datos en concurrencia
      await ref.set(fullPayload, SetOptions(merge: true));
      logger.info('Client synced to Firestore', {'clientId': client.id});
    } catch (e, st) {
      final failInvalidPath = findInvalidFirestorePath(fullPayload);
      final failInvalidPaths = listInvalidFirestorePaths(
        fullPayload,
        limit: 12,
      );
      final failAuditFindings = listFirestoreAuditFindings(
        fullPayload,
        limit: 12,
      );
      logger.error('Firestore upsert failed', e, st);
      logger.debug('Firestore payload audit findings after failure', {
        'clientId': client.id,
        'invalidPath': failInvalidPath,
        'invalidPaths': failInvalidPaths,
        'auditFindings': failAuditFindings,
      });
      logger.debug('Firestore payload keys', {
        'keys': fullPayload.keys.toList(),
      });
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
