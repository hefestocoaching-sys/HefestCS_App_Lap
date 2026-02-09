import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
        developer.log(
          '🔥 Firestore raw payload invalid paths: ${rawInvalidPaths.join(' | ')}',
        );
      }
      rawAuditFindings = listFirestoreAuditFindings(clientJson, limit: 12);
      if (rawAuditFindings.isNotEmpty) {
        developer.log(
          '🔥 Firestore raw payload audit findings: ${rawAuditFindings.join(' | ')}',
        );
      }
    }

    final fullPayload = <String, dynamic>{
      'payload': remotePayload,
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': deleted,
    };

    String? invalidPath;
    List<String> invalidPaths = const [];
    List<String> auditFindings = const [];
    if (_enableFirestoreAudit) {
      invalidPath = findInvalidFirestorePath(fullPayload);
      if (invalidPath != null) {
        developer.log('🔥 Firestore payload invalid at: $invalidPath');
      }
      invalidPaths = listInvalidFirestorePaths(fullPayload, limit: 12);
      if (invalidPaths.isNotEmpty) {
        developer.log(
          '🔥 Firestore payload invalid paths: ${invalidPaths.join(' | ')}',
        );
      }
      auditFindings = listFirestoreAuditFindings(fullPayload, limit: 12);
      if (auditFindings.isNotEmpty) {
        developer.log(
          '🔥 Firestore payload audit findings: ${auditFindings.join(' | ')}',
        );
      }

      debugPrint('🔥 Upserting client ${client.id} to Firestore...');
      debugPrint(
        '   training.extra keys: ${client.training.extra.keys.join(', ')}',
      );
      debugPrint(
        '   payload.training.extra is Map: ${(fullPayload['payload'] as Map)['training'] is Map}',
      );
    }

    if (_enableFirestoreAudit) {
      final hasAuditIssues =
          rawInvalidPaths.isNotEmpty ||
          rawAuditFindings.isNotEmpty ||
          invalidPath != null ||
          invalidPaths.isNotEmpty ||
          auditFindings.isNotEmpty;
      if (hasAuditIssues) {
        debugPrint(
          '⚠️ Skipping remote client sync due to invalid Firestore payload.',
        );
        return;
      }
    }

    try {
      // ✅ OBLIGATORIO: SetOptions(merge: true) para no perder datos en concurrencia
      await ref.set(fullPayload, SetOptions(merge: true));
      debugPrint('✅ Client ${client.id} synced to Firestore successfully');
    } catch (e, st) {
      final failInvalidPath = findInvalidFirestorePath(fullPayload);
      if (failInvalidPath != null) {
        developer.log('🔥 Firestore payload invalid at: $failInvalidPath');
      }
      final failInvalidPaths = listInvalidFirestorePaths(fullPayload, limit: 12);
      if (failInvalidPaths.isNotEmpty) {
        developer.log(
          '🔥 Firestore payload invalid paths: ${failInvalidPaths.join(' | ')}',
        );
      }
      final failAuditFindings = listFirestoreAuditFindings(
        fullPayload,
        limit: 12,
      );
      if (failAuditFindings.isNotEmpty) {
        developer.log(
          '🔥 Firestore payload audit findings: ${failAuditFindings.join(' | ')}',
        );
      }
      debugPrint(
        '🔥 Firestore upsert failed for client ${client.id}: ${e.runtimeType} $e',
      );
      debugPrint('Full payload keys: ${fullPayload.keys.join(', ')}');
      debugPrint(st.toString());
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
        debugPrint(
          '⚠️ Skipping remote client meta sync due to invalid Firestore payload.',
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
