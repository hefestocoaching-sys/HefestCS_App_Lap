import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/constants/volume_to_frequency_rule.dart';
import 'package:hcs_app_lap/domain/policies/pairing_contract.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/policies/intensification_eligibility.dart';

class TrainingPlanForensicValidationResult {
  final bool isValid;
  final List<String> blockingErrors;
  final List<String> warnings;
  final Map<String, dynamic> diagnostics;

  const TrainingPlanForensicValidationResult({
    required this.isValid,
    required this.blockingErrors,
    required this.warnings,
    required this.diagnostics,
  });

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'blockingErrors': blockingErrors,
      'warnings': warnings,
      'diagnostics': diagnostics,
    };
  }
}

class TrainingPlanForensicValidator {
  static const int _defaultDailyCapPerMuscle = 10;
  static const int _warningSessionSetLimit = 36;
  static const int _hardSessionSetLimit = 45;

  static TrainingPlanForensicValidationResult validate({
    required dynamic planConfig,
    Map<String, int>? expectedWeeklyVolumeByMuscle,
    Map<String, int>? musclePriorities,
    int dailyCapPerMuscle = _defaultDailyCapPerMuscle,
  }) {
    final issues = <_ForensicIssue>[];
    for (final warning in ExerciseCatalogV3.getCatalogWarnings()) {
      issues.add(
        _ForensicIssue.warning(
          rule: '2.10_selector_coherence',
          message: warning,
        ),
      );
    }
    final planExtra = _extractPlanExtraMap(planConfig);
    final volumeLandmarksByMuscle = _extractVolumeLandmarks(planExtra);
    final businessPhaseByWeek = _extractBusinessPhaseByWeek(planExtra);
    final primaryOverVmrAllowed = _primaryOverVmrAllowed(planExtra);

    final weeks = _extractWeeks(planConfig);
    if (weeks.isEmpty) {
      issues.add(
        _ForensicIssue.blocking(
          rule: '2.1_coverage',
          message: 'Plan sin semanas o estructura inválida.',
        ),
      );
      return _buildResult(
        issues: issues,
        diagnostics: {
          'totals': {'weeks': 0, 'sessions': 0, 'exercises': 0, 'sets': 0},
          'issues': issues.map((e) => e.toMap()).toList(),
        },
      );
    }

    final expectedVolume = _normalizeExpectedVolume(
      expectedWeeklyVolumeByMuscle ?? _extractExpectedVolume(planConfig),
    );
    final priorityMap = _normalizePriorityMap(
      musclePriorities ?? _extractMusclePriorities(planExtra),
    );

    final weeklySetsByMuscle = <int, Map<String, int>>{};
    final weeklyFrequencyByMuscle = <int, Map<String, int>>{};
    final exerciseAppearancesByWeek = <int, Map<String, int>>{};
    final equivalenceGroupByWeek = <int, Map<String, int>>{};

    var totalSessions = 0;
    var totalExercises = 0;
    var totalSets = 0;

    for (var weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final week = weeks[weekIndex];
      final weekNumber = _readInt(week, [
        'weekNumber',
      ], fallback: weekIndex + 1);
      final sessions = _extractSessions(week);
      final weekBusinessPhase =
          businessPhaseByWeek[weekNumber] ??
          _inferBusinessPhaseFromWeek(weekNumber, weeks.length);

      final setsByMuscle = <String, int>{};
      final daysByMuscle = <String, Set<int>>{};
      final exerciseCount = <String, int>{};
      final eqGroupCount = <String, int>{};

      for (final session in sessions) {
        totalSessions++;
        final dayNumber = _readInt(session, ['dayNumber'], fallback: 0);
        final extracted = _extractExercises(session);

        var sessionSets = 0;
        final sessionSetsByMuscle = <String, int>{};
        final pairGroups = <String, List<_ExtractedExercise>>{};
        var hasHeavy = false;
        var firstHeavyIndex = -1;
        var firstLightOrMediumIndex = -1;

        for (var i = 0; i < extracted.length; i++) {
          final ex = extracted[i];
          totalExercises++;
          totalSets += ex.setCount;
          sessionSets += ex.setCount;

          final slotLabel = ex.slotLabel.toUpperCase();
          final blockLabel = ex.blockLabel.toUpperCase();

          if (!{'A', 'B', 'C', 'D'}.contains(blockLabel) ||
              (blockLabel != 'A' &&
                  !RegExp(r'^[BCD][12]$').hasMatch(slotLabel)) ||
              (blockLabel == 'A' && slotLabel != 'A')) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.10_selector_coherence',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                message:
                    'Slot o bloque inválido: block=${ex.blockLabel} slot=${ex.slotLabel}.',
              ),
            );
          }

          if (ex.exerciseId.isEmpty) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.10_selector_coherence',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                message: 'Ejercicio sin identificador en flujo final.',
              ),
            );
            continue;
          }

          final catalogExercise = ExerciseCatalogV3.getById(ex.exerciseId);
          if (catalogExercise == null) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.10_selector_coherence',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                message:
                    'Ejercicio ${ex.exerciseId} fuera de catálogo (fallback inválido).',
              ),
            );
            continue;
          }

          if (ex.slotLabel.isNotEmpty) {
            final normalizedSlot = ex.slotLabel.trim().toUpperCase();
            if (!ExerciseCatalogV3.supportsSlot(
              ex.exerciseId,
              normalizedSlot,
            )) {
              issues.add(
                _ForensicIssue.blocking(
                  rule: '2.10_selector_coherence',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  exerciseId: ex.exerciseId,
                  message:
                      'Ejercicio ${ex.exerciseId} usado en slot no permitido por catálogo: $normalizedSlot.',
                ),
              );
            }

            if (normalizedSlot == 'A' &&
                !ExerciseCatalogV3.isAEligible(ex.exerciseId)) {
              issues.add(
                _ForensicIssue.blocking(
                  rule: '2.10_selector_coherence',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  exerciseId: ex.exerciseId,
                  message:
                      'Ejercicio ${ex.exerciseId} no es elegible para slot A (aEligibility/slotRoles).',
                ),
              );
            }

            final allowedPatternsForSlot =
                ExerciseCatalogV3.allowedPatternsForSlot(
                  normalizedSlot,
                ).toSet();
            final movementPattern = ExerciseCatalogV3.getMovementPattern(
              ex.exerciseId,
            );
            if (allowedPatternsForSlot.isNotEmpty &&
                !allowedPatternsForSlot.contains(movementPattern)) {
              issues.add(
                _ForensicIssue.blocking(
                  rule: '2.10_selector_coherence',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  exerciseId: ex.exerciseId,
                  message:
                      'Pattern incoherente con path de selección: slot=$normalizedSlot pattern=$movementPattern.',
                ),
              );
            }
          }

          final primaryMuscle = ex.primaryMuscle.isNotEmpty
              ? normalizeMuscleKey(ex.primaryMuscle)
              : normalizeMuscleKey(
                  catalogExercise.primaryMuscles.isNotEmpty
                      ? catalogExercise.primaryMuscles.first
                      : '',
                );

          if (primaryMuscle.isNotEmpty) {
            setsByMuscle[primaryMuscle] =
                (setsByMuscle[primaryMuscle] ?? 0) + ex.setCount;
            sessionSetsByMuscle[primaryMuscle] =
                (sessionSetsByMuscle[primaryMuscle] ?? 0) + ex.setCount;
            if (dayNumber > 0) {
              daysByMuscle
                  .putIfAbsent(primaryMuscle, () => <int>{})
                  .add(dayNumber);
            }
          }

          exerciseCount[ex.exerciseId] =
              (exerciseCount[ex.exerciseId] ?? 0) + 1;

          final eqGroup = ExerciseCatalogV3.getEquivalenceGroup(ex.exerciseId);
          if (eqGroup != null && eqGroup.isNotEmpty) {
            eqGroupCount[eqGroup] = (eqGroupCount[eqGroup] ?? 0) + 1;
          }

          final movementPattern = ExerciseCatalogV3.getMovementPattern(
            ex.exerciseId,
          );
          if (!_isPatternMuscleCoherent(primaryMuscle, movementPattern)) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.10_selector_coherence',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                muscle: primaryMuscle,
                message:
                    'Incoherencia patrón-ejercicio: muscle=$primaryMuscle pattern=$movementPattern exercise=${ex.exerciseId}.',
              ),
            );
          }

          final intensification = ex.intensification;
          if (intensification != null) {
            final intensityIssue = _validateIntensificationContract(
              exerciseId: ex.exerciseId,
              movementPattern: movementPattern,
              loadCategory: ExerciseCatalogV3.getLoadCategory(ex.exerciseId),
              intensification: intensification,
              weekBusinessPhase: weekBusinessPhase,
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              muscle: primaryMuscle,
            );
            if (intensityIssue != null) {
              issues.add(intensityIssue);
            }
          } else {
            final requirement =
                IntensificationEligibility.requirementForExercise(
                  businessPhaseLabel: weekBusinessPhase,
                  exerciseId: ex.exerciseId,
                  loadCategory: ExerciseCatalogV3.getLoadCategory(
                    ex.exerciseId,
                  ),
                  movementPattern: movementPattern,
                  blockLabel: ex.blockLabel,
                );
            if (requirement != IntensificationRequirement.required) {
              continue;
            }
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.3_intensity_correctness',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                muscle: primaryMuscle,
                message:
                    'Fase $weekBusinessPhase requiere intensificación por zona y el ejercicio ${ex.exerciseId} no la tiene.',
              ),
            );
          }

          if (ex.pairGroupId != null && ex.pairGroupId!.isNotEmpty) {
            pairGroups
                .putIfAbsent(ex.pairGroupId!, () => <_ExtractedExercise>[])
                .add(ex);
          }

          final loadCategory = ExerciseCatalogV3.getLoadCategory(ex.exerciseId);
          if (loadCategory == 'heavy' &&
              ex.slotLabel.trim().toUpperCase() != 'A' &&
              !ExerciseCatalogV3.getSecondaryHeavyEligibility(ex.exerciseId)) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.7_daily_feasibility',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                muscle: primaryMuscle,
                message:
                    'Heavy secundario no permitido por catálogo para ${ex.exerciseId}.',
              ),
            );
          }
          if (loadCategory == 'heavy') {
            hasHeavy = true;
            firstHeavyIndex = firstHeavyIndex == -1 ? i : firstHeavyIndex;
          }
          if ((loadCategory == 'medium' || loadCategory == 'light') &&
              firstLightOrMediumIndex == -1) {
            firstLightOrMediumIndex = i;
          }

          final zonesInExercise = ex.repRanges
              .map((r) => _inferZone(min: r.$1, max: r.$2))
              .toSet();

          if (zonesInExercise.contains(null)) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.4_reps_by_zone',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                muscle: primaryMuscle,
                message:
                    'Rango de reps inválido para zona en ${ex.exerciseId}: ${ex.repRanges.map((r) => '${r.$1}-${r.$2}').join(', ')}.',
              ),
            );
          }

          final resolvedZones = zonesInExercise.whereType<String>().toSet();
          if (resolvedZones.length > 1) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.3_intensity_correctness',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                exerciseId: ex.exerciseId,
                muscle: primaryMuscle,
                message:
                    'Ejercicio ${ex.exerciseId} mezcla zonas de intensidad en la misma sesión: ${resolvedZones.join('/')}.',
              ),
            );
          }

          if (resolvedZones.length == 1) {
            final zone = resolvedZones.first;
            if (!ExerciseCatalogV3.allowsZone(ex.exerciseId, zone)) {
              issues.add(
                _ForensicIssue.blocking(
                  rule: '2.9_zone_valid_by_exercise',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  exerciseId: ex.exerciseId,
                  muscle: primaryMuscle,
                  message:
                      'Ejercicio ${ex.exerciseId} incompatible con zona $zone.',
                ),
              );
            }
          }
        }

        if (sessionSets > _hardSessionSetLimit) {
          issues.add(
            _ForensicIssue.blocking(
              rule: '2.7_daily_feasibility',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              message:
                  'Sesion excede limite duro de sets: $sessionSets > $_hardSessionSetLimit.',
            ),
          );
        } else if (sessionSets >= _warningSessionSetLimit) {
          issues.add(
            _ForensicIssue.warning(
              rule: '2.7_daily_feasibility',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              message:
                  'Sesion alta en sets: $sessionSets >= $_warningSessionSetLimit.',
            ),
          );
        }

        if (sessionSets > 0) {
          for (final entry in sessionSetsByMuscle.entries) {
            if (entry.value > dailyCapPerMuscle) {
              issues.add(
                _ForensicIssue.blocking(
                  rule: '2.7_daily_feasibility',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  muscle: entry.key,
                  message:
                      'Cap diario excedido: muscle=${entry.key} sets=${entry.value} cap=$dailyCapPerMuscle.',
                ),
              );
            }
            final share = entry.value / sessionSets;
            if (entry.value > 8 && share > 0.65) {
              issues.add(
                _ForensicIssue.blocking(
                  rule: '2.7_daily_feasibility',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  muscle: entry.key,
                  message:
                      'Concentracion absurda: ${entry.key} concentra ${(share * 100).toStringAsFixed(1)}% de la sesion con ${entry.value} sets directos.',
                ),
              );
            } else if (share >= 0.65) {
              issues.add(
                _ForensicIssue.warning(
                  rule: '2.7_daily_feasibility',
                  weekNumber: weekNumber,
                  dayNumber: dayNumber,
                  muscle: entry.key,
                  message:
                      'Distribucion suboptima: ${entry.key} concentra ${(share * 100).toStringAsFixed(1)}% de la sesion.',
                ),
              );
            }
          }
        }

        final heavyConflictPatternCounts = <String, int>{};
        for (final ex in extracted) {
          final loadCategory = ExerciseCatalogV3.getLoadCategory(ex.exerciseId);
          if (loadCategory != 'heavy') continue;
          final catalogExercise = ExerciseCatalogV3.getById(ex.exerciseId);
          if (catalogExercise == null ||
              ExerciseCatalogV3.getTypeById(ex.exerciseId) != 'compound') {
            continue;
          }
          final conflictPatterns = ExerciseCatalogV3.getConflictPatterns(
            ex.exerciseId,
          );
          if (conflictPatterns.isEmpty) {
            final pattern = ExerciseCatalogV3.getMovementPattern(ex.exerciseId);
            heavyConflictPatternCounts[pattern] =
                (heavyConflictPatternCounts[pattern] ?? 0) + 1;
            continue;
          }
          for (final pattern in conflictPatterns) {
            heavyConflictPatternCounts[pattern] =
                (heavyConflictPatternCounts[pattern] ?? 0) + 1;
          }
        }
        if (heavyConflictPatternCounts.values.any((count) => count > 1)) {
          issues.add(
            _ForensicIssue.blocking(
              rule: '2.7_daily_feasibility',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              message:
                  'Dos compuestos heavy comparten conflictPattern dominante: ${heavyConflictPatternCounts.entries.where((e) => e.value > 1).map((e) => '${e.key}x${e.value}').join(', ')}.',
            ),
          );
        }

        if (hasHeavy &&
            firstLightOrMediumIndex != -1 &&
            firstHeavyIndex > firstLightOrMediumIndex) {
          issues.add(
            _ForensicIssue.warning(
              rule: '2.5_structural_order',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              message:
                  'Orden suboptimo: ejercicio medium/light aparece antes que heavy.',
            ),
          );
        }

        _validatePriorityContract(
          issues: issues,
          weekNumber: weekNumber,
          dayNumber: dayNumber,
          setsByMuscle: setsByMuscle,
          volumeLandmarksByMuscle: volumeLandmarksByMuscle,
          priorityMap: priorityMap,
          primaryOverVmrAllowed: primaryOverVmrAllowed,
        );

        for (final group in pairGroups.entries) {
          final members = group.value;
          if (members.length < 2) continue;
          final left = members[0];
          final right = members[1];

          final leftMuscle = _resolvePrimaryMuscle(left);
          final rightMuscle = _resolvePrimaryMuscle(right);

          if (leftMuscle.isNotEmpty && leftMuscle == rightMuscle) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.6_pairing_valid',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                muscle: leftMuscle,
                message:
                    'Pairing prohibido en grupo ${group.key}: mismo musculo primario.',
              ),
            );
          }

          final allowed = PairingContract.isAllowedBiserie(
            firstPrimaryMuscle: leftMuscle,
            secondPrimaryMuscle: rightMuscle,
          );
          if (!allowed) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.6_pairing_valid',
                weekNumber: weekNumber,
                dayNumber: dayNumber,
                message:
                    'Pairing ${group.key} fuera de contrato permitido (antagonist/lowInterference/synergy).',
              ),
            );
          }
        }
      }

      weeklySetsByMuscle[weekNumber] = setsByMuscle;
      weeklyFrequencyByMuscle[weekNumber] = {
        for (final entry in daysByMuscle.entries) entry.key: entry.value.length,
      };
      exerciseAppearancesByWeek[weekNumber] = exerciseCount;
      equivalenceGroupByWeek[weekNumber] = eqGroupCount;

      for (final entry in exerciseCount.entries) {
        if (entry.value > 2) {
          issues.add(
            _ForensicIssue.warning(
              rule: '2.8_redundancy',
              weekNumber: weekNumber,
              exerciseId: entry.key,
              message:
                  'Ejercicio repetido en exceso en semana $weekNumber: ${entry.key} x${entry.value}.',
            ),
          );
        }
      }

      for (final entry in eqGroupCount.entries) {
        if (entry.value > 3) {
          issues.add(
            _ForensicIssue.warning(
              rule: '2.8_redundancy',
              weekNumber: weekNumber,
              message:
                  'Uso repetido de equivalenceGroup ${entry.key}: ${entry.value} apariciones.',
            ),
          );
        }
      }

      if (expectedVolume.isNotEmpty) {
        for (final expected in expectedVolume.entries) {
          if (expected.value <= 0) continue;
          final actualSets = setsByMuscle[expected.key] ?? 0;
          if (actualSets == 0) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.1_coverage',
                weekNumber: weekNumber,
                muscle: expected.key,
                message:
                    'Musculo con volumen esperado sin cobertura: ${expected.key} target=${expected.value} actual=0.',
              ),
            );
          }

          final expectedFrequency = _frequencyForVolume(expected.value);
          final actualFrequency = daysByMuscle[expected.key]?.length ?? 0;
          if (actualSets > 0 && actualFrequency != expectedFrequency) {
            issues.add(
              _ForensicIssue.blocking(
                rule: '2.2_frequency',
                weekNumber: weekNumber,
                muscle: expected.key,
                message:
                    'Frecuencia incorrecta para ${expected.key}: targetSets=${expected.value} expected=f$expectedFrequency actual=f$actualFrequency.',
              ),
            );
          } else if (actualSets > 0) {
            final actualShares = _distributionSharesForMuscle(
              expected.key,
              daysByMuscle[expected.key] ?? const <int>{},
              sessionSetsByMuscle: _collectMuscleSetsByDay(
                sessions,
                expected.key,
              ),
            );
            final distributionIssue = _validateFrequencyDistributionContract(
              muscle: expected.key,
              expectedFrequency: expectedFrequency,
              actualShares: actualShares,
              weekNumber: weekNumber,
            );
            if (distributionIssue != null) {
              issues.add(distributionIssue);
            }
          }
        }
      }
    }

    final generatedBy = _readString(planConfig, [
      'extra.generated_by',
      'extra.strategy',
    ]);
    if (generatedBy.isNotEmpty && !generatedBy.toLowerCase().contains('v3')) {
      issues.add(
        _ForensicIssue.warning(
          rule: '2.10_selector_coherence',
          message:
              'Flujo de generacion no identificado como V3 deterministico: $generatedBy.',
        ),
      );
    }

    final diagnostics = {
      'totals': {
        'weeks': weeks.length,
        'sessions': totalSessions,
        'exercises': totalExercises,
        'sets': totalSets,
      },
      'weeklySetsByMuscle': weeklySetsByMuscle,
      'weeklyFrequencyByMuscle': weeklyFrequencyByMuscle,
      'exerciseAppearancesByWeek': exerciseAppearancesByWeek,
      'equivalenceGroupByWeek': equivalenceGroupByWeek,
      'issues': issues.map((e) => e.toMap()).toList(),
    };

    return _buildResult(issues: issues, diagnostics: diagnostics);
  }

  static void logStructured(TrainingPlanForensicValidationResult result) {
    final issueList = (result.diagnostics['issues'] as List?) ?? const [];
    for (final raw in issueList) {
      if (raw is! Map) continue;
      final severity = (raw['severity'] ?? 'warning').toString().toUpperCase();
      final rule = (raw['rule'] ?? 'unknown').toString();
      final week = raw['weekNumber']?.toString() ?? '-';
      final day = raw['dayNumber']?.toString() ?? '-';
      final muscle = raw['muscle']?.toString() ?? '-';
      final exercise = raw['exerciseId']?.toString() ?? '-';
      final message = raw['message']?.toString() ?? '';
      debugPrint(
        '[V3][FORENSIC][$severity] rule=$rule week=$week day=$day muscle=$muscle exercise=$exercise message=$message',
      );
    }
  }

  static Map<String, dynamic> _extractPlanExtraMap(dynamic planConfig) {
    final raw = _readDynamic(planConfig, ['extra']);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  static Map<String, Map<String, dynamic>> _extractVolumeLandmarks(
    Map<String, dynamic> extra,
  ) {
    final raw = extra['volume_landmarks_by_muscle'];
    if (raw is! Map) return const <String, Map<String, dynamic>>{};
    return raw.map((key, value) {
      if (value is Map) {
        return MapEntry(
          normalizeMuscleKey(key.toString()),
          Map<String, dynamic>.from(value),
        );
      }
      return MapEntry(
        normalizeMuscleKey(key.toString()),
        const <String, dynamic>{},
      );
    });
  }

  static Map<int, String> _extractBusinessPhaseByWeek(
    Map<String, dynamic> extra,
  ) {
    final raw = extra['business_phase_by_week'];
    if (raw is Map) {
      return raw.map(
        (key, value) =>
            MapEntry(int.tryParse(key.toString()) ?? 0, value.toString()),
      );
    }
    return const <int, String>{};
  }

  static bool _primaryOverVmrAllowed(Map<String, dynamic> extra) {
    final raw = extra['weeklyDecisionArtifactsV1'];
    if (raw is Map) {
      final flags = raw['flags'];
      if (flags is Map) {
        final val =
            flags['primaryOverVmrAllowed'] ?? flags['allowPrimaryOverVmr'];
        if (val is bool) return val;
      }
      final direct = raw['primaryOverVmrAllowed'] ?? raw['allowPrimaryOverVmr'];
      if (direct is bool) return direct;
    }
    return false;
  }

  static Map<String, int> _extractMusclePriorities(Map<String, dynamic> extra) {
    final raw = extra['musclePriorities'] ?? extra['priorityMuscles'];
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(
          normalizeMuscleKey(key.toString()),
          value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0,
        ),
      );
    }
    return const <String, int>{};
  }

  static Map<String, int> _normalizePriorityMap(Map<String, int> raw) {
    final out = <String, int>{};
    for (final entry in raw.entries) {
      final key = normalizeMuscleKey(entry.key);
      if (key.isEmpty) continue;
      out[key] = entry.value;
    }
    return out;
  }

  static String _inferBusinessPhaseFromWeek(int weekNumber, int totalWeeks) {
    if (weekNumber <= 1) return 'AA';
    if (weekNumber == 2) return 'HF1';
    if (weekNumber == 3) return 'HF2';
    if (weekNumber >= totalWeeks) return 'regeneration';
    return 'HF3';
  }

  static Map<int, int> _collectMuscleSetsByDay(
    List<dynamic> sessions,
    String muscle,
  ) {
    final out = <int, int>{};
    for (final session in sessions) {
      final dayNumber = _readInt(session, ['dayNumber'], fallback: 0);
      final exercises = _extractExercises(session);
      var total = 0;
      for (final exercise in exercises) {
        if (normalizeMuscleKey(exercise.primaryMuscle) != muscle) continue;
        total += exercise.setCount;
      }
      if (dayNumber > 0 && total > 0) {
        out[dayNumber] = total;
      }
    }
    return out;
  }

  static List<double> _distributionSharesForMuscle(
    String muscle,
    Set<int> activeDays, {
    required Map<int, int> sessionSetsByMuscle,
  }) {
    final totals = <int>[];
    var weeklyTotal = 0;
    for (final day in activeDays) {
      final sets = sessionSetsByMuscle[day] ?? 0;
      if (sets <= 0) continue;
      totals.add(sets);
      weeklyTotal += sets;
    }
    if (weeklyTotal <= 0) return const <double>[];
    totals.sort((a, b) => b.compareTo(a));
    return totals.map((value) => value / weeklyTotal).toList(growable: false);
  }

  static _ForensicIssue? _validateFrequencyDistributionContract({
    required String muscle,
    required int expectedFrequency,
    required List<double> actualShares,
    required int weekNumber,
  }) {
    if (actualShares.isEmpty) return null;

    final tolerance = expectedFrequency == 1
        ? const [1.0, 1.0]
        : expectedFrequency == 2
        ? const [0.40, 0.60]
        : const [0.25, 0.45];

    if (expectedFrequency == 1) {
      if (actualShares.length != 1 ||
          (actualShares.first - 1.0).abs() > 0.001) {
        return _ForensicIssue.blocking(
          rule: '2.2_frequency',
          weekNumber: weekNumber,
          muscle: muscle,
          message:
              'Distribucion invalida para f1: se esperaba 100% en una sola exposicion y se obtuvo ${actualShares.map((e) => (e * 100).toStringAsFixed(1)).join('/')}%.',
        );
      }
      return null;
    }

    if (expectedFrequency == 2) {
      if (actualShares.length != 2) {
        return _ForensicIssue.blocking(
          rule: '2.2_frequency',
          weekNumber: weekNumber,
          muscle: muscle,
          message:
              'Distribucion invalida para f2: se esperaban 2 exposiciones y se obtuvieron ${actualShares.length}.',
        );
      }

      final left = actualShares[0];
      final right = actualShares[1];
      if (left < tolerance[0] ||
          left > tolerance[1] ||
          right < tolerance[0] ||
          right > tolerance[1]) {
        return _ForensicIssue.blocking(
          rule: '2.2_frequency',
          weekNumber: weekNumber,
          muscle: muscle,
          message:
              'Distribucion invalida para f2: ${actualShares.map((e) => (e * 100).toStringAsFixed(1)).join('/')} fuera de 60/40-50/50.',
        );
      }
      return null;
    }

    if (expectedFrequency == 3) {
      if (actualShares.length != 3) {
        return _ForensicIssue.blocking(
          rule: '2.2_frequency',
          weekNumber: weekNumber,
          muscle: muscle,
          message:
              'Distribucion invalida para f3: se esperaban 3 exposiciones y se obtuvieron ${actualShares.length}.',
        );
      }

      final sorted = List<double>.from(actualShares)
        ..sort((a, b) => b.compareTo(a));
      final target = const [0.40, 0.30, 0.30];
      for (var i = 0; i < 3; i++) {
        if ((sorted[i] - target[i]).abs() > 0.05) {
          return _ForensicIssue.blocking(
            rule: '2.2_frequency',
            weekNumber: weekNumber,
            muscle: muscle,
            message:
                'Distribucion invalida para f3: ${sorted.map((e) => (e * 100).toStringAsFixed(1)).join('/')} fuera de 40/30/30 ±5%.',
          );
        }
      }
      return null;
    }

    return null;
  }

  static void _validatePriorityContract({
    required List<_ForensicIssue> issues,
    required int weekNumber,
    required int dayNumber,
    required Map<String, int> setsByMuscle,
    required Map<String, Map<String, dynamic>> volumeLandmarksByMuscle,
    required Map<String, int> priorityMap,
    required bool primaryOverVmrAllowed,
  }) {
    for (final entry in setsByMuscle.entries) {
      final muscle = entry.key;
      final totalSets = entry.value;
      final landmarks = volumeLandmarksByMuscle[muscle];
      if (landmarks == null) continue;

      final vme = (landmarks['vme'] as num?)?.toInt() ?? 0;
      final vop = (landmarks['vop'] as num?)?.toInt() ?? 0;
      final vmr = (landmarks['vmr'] as num?)?.toInt() ?? 0;
      final priority = priorityMap[muscle] ?? 0;

      final band = priority >= 5
          ? 'primary'
          : priority >= 3
          ? 'secondary'
          : 'tertiary';

      if (band == 'primary') {
        if (totalSets > vmr && !primaryOverVmrAllowed) {
          issues.add(
            _ForensicIssue.blocking(
              rule: '2.1_coverage',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              muscle: muscle,
              message:
                  'Primario excede VMR sin bitacora: sets=$totalSets vmr=$vmr.',
            ),
          );
        }
      } else if (band == 'secondary') {
        final cap = (vmr * 0.75).floor();
        if (totalSets > cap) {
          issues.add(
            _ForensicIssue.blocking(
              rule: '2.1_coverage',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              muscle: muscle,
              message:
                  'Secundario excede 75% de VMR: sets=$totalSets cap=$cap vmr=$vmr.',
            ),
          );
        }
      } else {
        if (totalSets > vop) {
          issues.add(
            _ForensicIssue.blocking(
              rule: '2.1_coverage',
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              muscle: muscle,
              message: 'Terciario excede VOP: sets=$totalSets vop=$vop.',
            ),
          );
        }
      }

      if (vop > 0 && vme > 0 && totalSets < vme) {
        issues.add(
          _ForensicIssue.warning(
            rule: '2.1_coverage',
            weekNumber: weekNumber,
            dayNumber: dayNumber,
            muscle: muscle,
            message: 'Músculo por debajo de VME: sets=$totalSets vme=$vme.',
          ),
        );
      }
    }
  }

  static bool _isPatternMuscleCoherent(String muscle, String pattern) {
    final normalizedPattern = pattern.trim().toLowerCase();
    if (normalizedPattern.isEmpty || normalizedPattern == 'unknown') {
      return true;
    }

    const upperPatterns = {
      'horizontal_press',
      'vertical_press',
      'horizontal_pull',
      'vertical_pull',
      'deltoid_lateral',
      'deltoid_rear',
      'biceps_curl',
      'triceps_extension',
    };
    const lowerPatterns = {
      'knee_dominant',
      'hip_hinge',
      'squat',
      'lunge',
      'deadlift',
      'glute_bridge',
      'calf_raise',
      'core',
    };

    final upperMuscles = {
      'pectorals',
      'lats',
      'upper_back',
      'traps',
      'delts_front',
      'delts_lateral',
      'delts_rear',
      'biceps',
      'triceps',
      'abs',
    };
    final lowerMuscles = {'quads', 'hamstrings', 'glutes', 'calves'};

    if (upperPatterns.contains(normalizedPattern)) {
      return upperMuscles.contains(muscle);
    }
    if (lowerPatterns.contains(normalizedPattern)) {
      return lowerMuscles.contains(muscle) || muscle == 'abs';
    }

    if (normalizedPattern.contains('press')) {
      return upperMuscles.contains(muscle) &&
          muscle != 'biceps' &&
          muscle != 'glutes' &&
          muscle != 'calves';
    }
    if (normalizedPattern.contains('pull') ||
        normalizedPattern.contains('row')) {
      return const {
        'lats',
        'upper_back',
        'traps',
        'biceps',
        'delts_rear',
      }.contains(muscle);
    }
    if (normalizedPattern.contains('squat') ||
        normalizedPattern.contains('hinge') ||
        normalizedPattern.contains('leg')) {
      return lowerMuscles.contains(muscle) || muscle == 'abs';
    }

    return true;
  }

  static _ForensicIssue? _validateIntensificationContract({
    required String exerciseId,
    required String movementPattern,
    required String loadCategory,
    required IntensificationRule intensification,
    required String weekBusinessPhase,
    required int weekNumber,
    required int dayNumber,
    required String muscle,
  }) {
    final requirement = IntensificationEligibility.requirementForExercise(
      businessPhaseLabel: weekBusinessPhase,
      exerciseId: exerciseId,
      loadCategory: loadCategory,
      movementPattern: movementPattern,
    );
    if (requirement == IntensificationRequirement.exempt) {
      return null;
    }

    final normalizedType = intensification.type.name;
    if (loadCategory == 'heavy') {
      if (normalizedType != IntensificationType.dropSet.name) {
        return _ForensicIssue.blocking(
          rule: '2.3_intensity_correctness',
          weekNumber: weekNumber,
          dayNumber: dayNumber,
          exerciseId: exerciseId,
          muscle: muscle,
          message:
              'Intensificación heavy inválida: se esperaba dropSet y llegó $normalizedType.',
        );
      }
      final drops = intensification.parameters['drop_percentages'];
      if (drops is List && drops.length >= 2) {
        final first = (drops[0] as num?)?.toDouble() ?? 0.0;
        final second = (drops[1] as num?)?.toDouble() ?? 0.0;
        if ((first - 0.25).abs() > 0.001 || (second - 0.25).abs() > 0.001) {
          return _ForensicIssue.blocking(
            rule: '2.3_intensity_correctness',
            weekNumber: weekNumber,
            dayNumber: dayNumber,
            exerciseId: exerciseId,
            muscle: muscle,
            message:
                'Double drop set heavy inválido: drops=${drops.toString()}.',
          );
        }
      }
    } else if (loadCategory == 'medium') {
      if (normalizedType != IntensificationType.restPause.name) {
        return _ForensicIssue.blocking(
          rule: '2.3_intensity_correctness',
          weekNumber: weekNumber,
          dayNumber: dayNumber,
          exerciseId: exerciseId,
          muscle: muscle,
          message:
              'Intensificación medium inválida: se esperaba restPause y llegó $normalizedType.',
        );
      }
    } else if (loadCategory == 'light') {
      if (normalizedType != IntensificationType.isometricHold.name) {
        return _ForensicIssue.blocking(
          rule: '2.3_intensity_correctness',
          weekNumber: weekNumber,
          dayNumber: dayNumber,
          exerciseId: exerciseId,
          muscle: muscle,
          message:
              'Intensificación light inválida: se esperaba isometricHold y llegó $normalizedType.',
        );
      }
    }

    if (movementPattern == 'unknown') {
      return _ForensicIssue.warning(
        rule: '2.10_selector_coherence',
        weekNumber: weekNumber,
        dayNumber: dayNumber,
        exerciseId: exerciseId,
        muscle: muscle,
        message: 'Intensificación validada sobre patrón desconocido.',
      );
    }

    return null;
  }

  static TrainingPlanForensicValidationResult _buildResult({
    required List<_ForensicIssue> issues,
    required Map<String, dynamic> diagnostics,
  }) {
    final blocking = issues
        .where((i) => i.severity == _Severity.blocking)
        .map((i) => i.format())
        .toList(growable: false);
    final warnings = issues
        .where((i) => i.severity == _Severity.warning)
        .map((i) => i.format())
        .toList(growable: false);

    return TrainingPlanForensicValidationResult(
      isValid: blocking.isEmpty,
      blockingErrors: blocking,
      warnings: warnings,
      diagnostics: diagnostics,
    );
  }

  static List<dynamic> _extractWeeks(dynamic planConfig) {
    final weeks = _readDynamic(planConfig, ['weeks']);
    if (weeks is List) return weeks;
    return const <dynamic>[];
  }

  static List<dynamic> _extractSessions(dynamic week) {
    final sessions = _readDynamic(week, ['sessions']);
    if (sessions is List) return sessions;
    return const <dynamic>[];
  }

  static List<_ExtractedExercise> _extractExercises(dynamic session) {
    final raw = _readDynamic(session, ['exercises', 'prescriptions']);
    if (raw is! List) return const <_ExtractedExercise>[];

    final out = <_ExtractedExercise>[];
    for (final item in raw) {
      final exerciseId = _readString(item, [
        'exerciseId',
        'exerciseCode',
      ]).trim();
      final primaryMuscle = _readString(item, [
        'primaryMuscle',
        'muscleKey',
        'muscleGroup.name',
      ]);
      final blockLabel = _readString(item, ['blockLabel']);
      final slotLabel = _readString(item, ['slotLabel']);
      final pairGroupId = _readString(item, ['pairGroupId', 'supersetGroup']);
      final intensificationRaw = _readDynamic(item, ['intensification']);
      final intensification = intensificationRaw is Map
          ? IntensificationRule.fromMap(
              Map<String, dynamic>.from(intensificationRaw),
            )
          : null;

      var setCount = 0;
      final repRanges = <(int, int)>[];

      final setList = _readDynamic(item, ['sets']);
      if (setList is List && setList.isNotEmpty) {
        setCount = setList.length;
        for (final s in setList) {
          final repsMin = _readInt(s, ['repsMin', 'repMin'], fallback: 0);
          final repsMax = _readInt(s, ['repsMax', 'repMax'], fallback: 0);
          repRanges.add((repsMin, repsMax));
        }
      } else {
        setCount = _readInt(item, ['sets'], fallback: 0);
        final repRange = _readDynamic(item, ['repRange']);
        if (repRange != null) {
          final repsMin = _readInt(repRange, ['min', 'repsMin'], fallback: 0);
          final repsMax = _readInt(repRange, ['max', 'repsMax'], fallback: 0);
          repRanges.add((repsMin, repsMax));
        }
      }

      if (setCount <= 0) {
        setCount = repRanges.isEmpty ? 1 : repRanges.length;
      }

      if (repRanges.isEmpty) {
        repRanges.add((0, 0));
      }

      out.add(
        _ExtractedExercise(
          exerciseId: exerciseId,
          primaryMuscle: primaryMuscle,
          blockLabel: blockLabel,
          slotLabel: slotLabel,
          setCount: setCount,
          repRanges: repRanges,
          pairGroupId: pairGroupId.isEmpty ? null : pairGroupId,
          intensification: intensification,
        ),
      );
    }

    return out;
  }

  static String _resolvePrimaryMuscle(_ExtractedExercise ex) {
    if (ex.primaryMuscle.isNotEmpty) {
      return normalizeMuscleKey(ex.primaryMuscle);
    }
    final catalogExercise = ExerciseCatalogV3.getById(ex.exerciseId);
    final raw =
        (catalogExercise != null && catalogExercise.primaryMuscles.isNotEmpty)
        ? catalogExercise.primaryMuscles.first
        : '';
    return normalizeMuscleKey(raw);
  }

  static String? _inferZone({required int min, required int max}) {
    if (min >= 6 && max <= 8) return 'heavy';
    if (min >= 8 && max <= 12) return 'medium';
    if (min >= 15 && max <= 20) return 'light';
    return null;
  }

  static int _frequencyForVolume(int weeklySets) {
    return VolumeToFrequencyRule.frequencyForWeeklyVolume(weeklySets);
  }

  static Map<String, int> _extractExpectedVolume(dynamic planConfig) {
    final raw = _readDynamic(planConfig, ['volumePerMuscle']);
    if (raw is! Map) return const <String, int>{};
    return _normalizeExpectedVolume(raw);
  }

  static Map<String, int> _normalizeExpectedVolume(Map<dynamic, dynamic> raw) {
    final out = <String, int>{};
    for (final entry in raw.entries) {
      final key = normalizeMuscleKey(entry.key.toString());
      if (key.isEmpty) continue;
      final value = entry.value;
      final parsed = value is int
          ? value
          : value is num
          ? value.round()
          : int.tryParse(value?.toString() ?? '') ?? 0;
      out[key] = parsed;
    }
    return out;
  }

  static dynamic _readDynamic(dynamic source, List<String> keys) {
    for (final key in keys) {
      final value = _readByPath(source, key);
      if (value != null) return value;
    }
    return null;
  }

  static String _readString(dynamic source, List<String> keys) {
    for (final key in keys) {
      final value = _readByPath(source, key);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int _readInt(
    dynamic source,
    List<String> keys, {
    required int fallback,
  }) {
    for (final key in keys) {
      final value = _readByPath(source, key);
      if (value is int) return value;
      if (value is num) return value.round();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static dynamic _readByPath(dynamic source, String path) {
    final parts = path.split('.');
    dynamic current = source;

    for (final part in parts) {
      if (current == null) return null;
      if (current is Map) {
        current = current[part];
        continue;
      }

      try {
        switch (part) {
          case 'weeks':
            current = current.weeks;
            break;
          case 'sessions':
            current = current.sessions;
            break;
          case 'exercises':
            current = current.exercises;
            break;
          case 'prescriptions':
            current = current.prescriptions;
            break;
          case 'weekNumber':
            current = current.weekNumber;
            break;
          case 'dayNumber':
            current = current.dayNumber;
            break;
          case 'exerciseId':
            current = current.exerciseId;
            break;
          case 'exerciseCode':
            current = current.exerciseCode;
            break;
          case 'muscleKey':
            current = current.muscleKey;
            break;
          case 'primaryMuscle':
            current = current.primaryMuscle;
            break;
          case 'muscleGroup':
            current = current.muscleGroup;
            break;
          case 'name':
            current = current.name;
            break;
          case 'sets':
            current = current.sets;
            break;
          case 'repRange':
            current = current.repRange;
            break;
          case 'min':
            current = current.min;
            break;
          case 'max':
            current = current.max;
            break;
          case 'repsMin':
            current = current.repsMin;
            break;
          case 'repsMax':
            current = current.repsMax;
            break;
          case 'pairGroupId':
            current = current.pairGroupId;
            break;
          case 'blockLabel':
            current = current.blockLabel;
            break;
          case 'slotLabel':
            current = current.slotLabel;
            break;
          case 'intensification':
            current = current.intensification;
            break;
          case 'supersetGroup':
            current = current.supersetGroup;
            break;
          case 'volumePerMuscle':
            current = current.volumePerMuscle;
            break;
          case 'extra':
            current = current.extra;
            break;
          case 'generated_by':
            current = current.generated_by;
            break;
          case 'strategy':
            current = current.strategy;
            break;
          default:
            return null;
        }
      } catch (_) {
        return null;
      }
    }

    return current;
  }
}

enum _Severity { blocking, warning }

class _ForensicIssue {
  final _Severity severity;
  final String rule;
  final String message;
  final String? muscle;
  final int? weekNumber;
  final int? dayNumber;
  final String? exerciseId;

  const _ForensicIssue._({
    required this.severity,
    required this.rule,
    required this.message,
    this.muscle,
    this.weekNumber,
    this.dayNumber,
    this.exerciseId,
  });

  factory _ForensicIssue.blocking({
    required String rule,
    required String message,
    String? muscle,
    int? weekNumber,
    int? dayNumber,
    String? exerciseId,
  }) {
    return _ForensicIssue._(
      severity: _Severity.blocking,
      rule: rule,
      message: message,
      muscle: muscle,
      weekNumber: weekNumber,
      dayNumber: dayNumber,
      exerciseId: exerciseId,
    );
  }

  factory _ForensicIssue.warning({
    required String rule,
    required String message,
    String? muscle,
    int? weekNumber,
    int? dayNumber,
    String? exerciseId,
  }) {
    return _ForensicIssue._(
      severity: _Severity.warning,
      rule: rule,
      message: message,
      muscle: muscle,
      weekNumber: weekNumber,
      dayNumber: dayNumber,
      exerciseId: exerciseId,
    );
  }

  String format() {
    final sev = severity == _Severity.blocking ? 'BLOCKING' : 'WARNING';
    final where = [
      if (weekNumber != null) 'week=$weekNumber',
      if (dayNumber != null) 'day=$dayNumber',
      if (muscle != null && muscle!.isNotEmpty) 'muscle=$muscle',
      if (exerciseId != null && exerciseId!.isNotEmpty) 'exercise=$exerciseId',
    ].join(' ');
    return '[FORENSIC][$sev][$rule] ${where.isEmpty ? '' : '$where '} $message'
        .trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'severity': severity == _Severity.blocking ? 'blocking' : 'warning',
      'rule': rule,
      'message': message,
      'muscle': muscle,
      'weekNumber': weekNumber,
      'dayNumber': dayNumber,
      'exerciseId': exerciseId,
    };
  }
}

class _ExtractedExercise {
  final String exerciseId;
  final String primaryMuscle;
  final String blockLabel;
  final String slotLabel;
  final int setCount;
  final List<(int, int)> repRanges;
  final String? pairGroupId;
  final IntensificationRule? intensification;

  const _ExtractedExercise({
    required this.exerciseId,
    required this.primaryMuscle,
    required this.blockLabel,
    required this.slotLabel,
    required this.setCount,
    required this.repRanges,
    required this.pairGroupId,
    required this.intensification,
  });
}
