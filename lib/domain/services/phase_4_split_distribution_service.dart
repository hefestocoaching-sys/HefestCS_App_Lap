import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_structure.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/constants/session_limits.dart';
import 'package:hcs_app_lap/domain/constants/frequency_by_volume.dart';

class Phase4SplitResult {
  final SplitTemplate split;
  final TrainingStructure structure;
  final List<DecisionTrace> decisions;

  const Phase4SplitResult({
    required this.split,
    required this.structure,
    required this.decisions,
  });
}

/// Fase 4: Selección de split y distribución de volumen semanal por día.
/// - Determinismo absoluto
/// - Respeta MRV y tiempo por sesión (~4 min por set)
/// - Evita golpear el mismo músculo en días consecutivos (cuando aplica)
class Phase4SplitDistributionService {
  Phase4SplitResult buildWeeklySplit({
    required TrainingProfile profile,
    required Map<String, VolumeLimits> volumeByMuscle, // from Phase 3
    double readinessAdjustment = 1.0, // from Phase 2
    String readinessMode = 'normal', // 'conservative' → menor densidad
    // Contexto derivado de Fase 1 (opcional para frecuencia/especialización)
    dynamic derivedContext,
    ManualOverride? manualOverride,
  }) {
    final decisions = <DecisionTrace>[];

    // 1) Selección del splitId respetando estructura lockeada/selección del coach
    final splitId = _resolveSplitId(profile);
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase4SplitDistribution',
        category: 'split_selection',
        description: 'Split seleccionado: $splitId',
        context: {
          'daysPerWeek': profile.daysPerWeek,
          'readinessMode': readinessMode,
        },
      ),
    );

    // 2) Calcular objetivo semanal por músculo
    // REGLA: Leer targetSetsByMuscle del extra (ya calculado en PRE-FASE 3)
    // NO inventar valores aquí - solo distribuir
    final targetSetsByMuscleRaw = profile.extra['targetSetsByMuscle'];
    final targetSetsByMuscle = targetSetsByMuscleRaw is Map
        ? _normalizeMuscleKeys(targetSetsByMuscleRaw.cast<String, dynamic>())
        : <String, double>{};

    var weeklyTarget = <String, int>{};
    final orderedMuscles = volumeByMuscle.keys.toList()..sort();

    for (final muscle in orderedMuscles) {
      final limits = volumeByMuscle[muscle]!;

      // Prioridad 1: targetSetsByMuscle del extra (calculado en PRE-FASE 3)
      // Prioridad 2: fallback a recommendedStartVolume de Phase 3
      var target =
          targetSetsByMuscle[muscle]?.round() ?? limits.recommendedStartVolume;

      // readiness (solo si no viene del extra)
      if (!targetSetsByMuscle.containsKey(muscle)) {
        target = (target * readinessAdjustment).round();
        if (readinessMode == 'conservative') {
          target = (target * 0.9).round();
        }
      }

      // clamp final
      if (target < limits.mev) target = limits.mev;
      if (target > limits.mrv) target = limits.mrv;

      weeklyTarget[muscle] = target;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'weekly_target_source',
          description: 'Target semanal resuelto para $muscle',
          context: {
            'muscle': muscle,
            'source': targetSetsByMuscle.containsKey(muscle)
                ? 'PRE-FASE3_targetSetsByMuscle'
                : 'phase3_recommendedStartVolume',
            'targetFromExtra': targetSetsByMuscle[muscle],
            'recommendedStart': limits.recommendedStartVolume,
            'finalTarget': target,
            'mev': limits.mev,
            'mrv': limits.mrv,
            'readinessAdjustment': readinessAdjustment,
            'readinessMode': readinessMode,
          },
        ),
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase4SplitDistribution',
        category: 'weekly_targets',
        description: 'Objetivos semanales por músculo calculados',
        context: weeklyTarget,
      ),
    );

    // 2.5) Construir dayMuscles desde los músculos realmente disponibles en weeklyTarget
    final available = weeklyTarget.keys.toList()..sort();
    final dayMuscles = _buildDayMusclesFromAvailable(
      daysPerWeek: profile.daysPerWeek,
      availableMuscles: available,
    );

    // 3.5) Aplicar overrides de prioridad antes de especialización
    final primary = {...profile.priorityMusclesPrimary};
    final secondary = {...profile.priorityMusclesSecondary};

    if (manualOverride?.priorityOverrides != null &&
        manualOverride!.priorityOverrides!.isNotEmpty) {
      manualOverride.priorityOverrides!.forEach((muscle, priority) {
        if (priority == 'primary') {
          primary.add(muscle);
          secondary.remove(muscle);
        } else if (priority == 'secondary') {
          secondary.add(muscle);
          primary.remove(muscle);
        } else if (priority == 'none') {
          primary.remove(muscle);
          secondary.remove(muscle);
        }
      });

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'priority_override_applied',
          description: 'Overrides de prioridad aplicados',
          context: {
            'primary': primary.toList(),
            'secondary': secondary.toList(),
          },
        ),
      );
    }

    // 3.5.5) [ELIMINADO] Límite de 2 músculos primarios - ahora sin límite
    // 3.6) [ELIMINADO] Especialización con aumento de volumen - las prioridades
    //      solo afectan orden/frecuencia, no volumen total

    // 3.6) Frecuencia objetivo por músculo
    final prioritarySet = {
      ...profile.priorityMusclesPrimary,
      ...profile.priorityMusclesSecondary,
    }.toSet();

    final levelName = profile.trainingLevel?.name ?? 'beginner';
    final frequencyTarget = _calculateMuscleFrequencies(
      volumeLimits: volumeByMuscle,
      maxDaysAvailable: profile.daysPerWeek,
      level: levelName,
      decisions: decisions,
    );

    // 3.7) Especialización de glúteo (si aplica)
    final gluteSlots = <int, String>{}; // day -> slot (heavy/moderate/pump)
    final gluteDays =
        dayMuscles.entries
            .where((e) => e.value.contains('glutes'))
            .map((e) => e.key)
            .toList()
          ..sort();
    final hasGluteSpec =
        derivedContext != null && derivedContext.gluteSpecialization != null;
    if (hasGluteSpec && gluteDays.isNotEmpty) {
      final freqTarget =
          derivedContext.gluteSpecialization.targetFrequencyPerWeek ??
          frequencyTarget['glutes'] ??
          gluteDays.length;
      // Asignar slots determinísticos respetando no-consecutivos para heavy
      // Estrategia: heavy en primer día, moderate en el siguiente disponible no consecutivo, pump en el último
      if (freqTarget >= 1) {
        gluteSlots[gluteDays.first] = 'heavy';
      }
      if (freqTarget >= 2) {
        // buscar día no consecutivo para moderate
        final modDay = gluteDays.firstWhere(
          (d) => d != gluteDays.first && (d - gluteDays.first).abs() >= 2,
          orElse: () => gluteDays.length > 1 ? gluteDays[1] : gluteDays.first,
        );
        gluteSlots[modDay] = 'moderate';
      }
      if (freqTarget >= 3) {
        // último slot pump en el mayor día restante no asignado
        final remaining = gluteDays
            .where((d) => !gluteSlots.containsKey(d))
            .toList();
        if (remaining.isNotEmpty) {
          gluteSlots[remaining.last] = 'pump';
        }
      }
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'slots_assigned',
          description: 'Slots glúteo asignados',
          context: gluteSlots.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );

      // Validar recuperación: heavy no consecutivo
      final heavyDays =
          gluteSlots.entries
              .where((e) => e.value == 'heavy')
              .map((e) => e.key)
              .toList()
            ..sort();
      var okSpacing = true;
      for (var i = 1; i < heavyDays.length; i++) {
        if ((heavyDays[i] - heavyDays[i - 1]).abs() < 2) {
          okSpacing = false;
          break;
        }
      }
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'recovery_spacing',
          description: 'Espaciado de estímulos pesados (glúteo)',
          context: {'heavyDays': heavyDays, 'okSpacing48h': okSpacing},
        ),
      );
    }

    // 4) Distribución del volumen por día con frecuencia objetivo y slots
    final dailyVolume = _distributeVolumeWithFrequency(
      dayMuscles,
      weeklyTarget,
      frequencyTarget,
      gluteSlots,
      profile,
      volumeByMuscle,
      prioritarySet,
      decisions,
    );

    final split = SplitTemplate(
      splitId: splitId,
      daysPerWeek: profile.daysPerWeek,
      dayMuscles: dayMuscles,
      dailyVolume: dailyVolume,
    );

    // 5) Generar TrainingStructure lockeada mínima (densidad y lock condicional)
    final structure = TrainingStructure(
      splitId: splitId,
      daysPerWeek: profile.daysPerWeek,
      minExercisesPerDay: (profile.daysPerWeek >= 4) ? 5 : 3,
      targetExercisesPerDay: (profile.daysPerWeek >= 4) ? 7 : 6,
      lockedFromWeek: profile.currentWeekIndex,
      lockedUntilWeek: null,
    );

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase4SplitDistribution',
        category: 'structure_created',
        description: 'Estructura de entrenamiento generada',
        context: {
          'splitId': structure.splitId,
          'daysPerWeek': structure.daysPerWeek,
          'minExercisesPerDay': structure.minExercisesPerDay,
          'targetExercisesPerDay': structure.targetExercisesPerDay,
          'lockedFromWeek': structure.lockedFromWeek,
          'lockedUntilWeek': structure.lockedUntilWeek,
        },
      ),
    );

    return Phase4SplitResult(
      split: split,
      structure: structure,
      decisions: decisions,
    );
  }

  /// Calcula frecuencia óptima para cada músculo según volumen
  Map<String, int> _calculateMuscleFrequencies({
    required Map<String, VolumeLimits> volumeLimits,
    required int maxDaysAvailable,
    required String level,
    required List<DecisionTrace> decisions,
  }) {
    final frequencies = <String, int>{};

    for (final entry in volumeLimits.entries) {
      final muscle = entry.key;
      final limits = entry.value;
      final weeklyVolume = limits.recommendedStartVolume;

      // Calcular frecuencia según regla de volumen
      int frequency = FrequencyByVolume.calculateFrequency(
        weeklyVolume: weeklyVolume,
        maxDaysAvailable: maxDaysAvailable,
      );

      // Validar que sea suficiente para respetar límites de sesión
      final isSufficient = FrequencyByVolume.isFrequencySufficient(
        weeklyVolume: weeklyVolume,
        frequency: frequency,
        level: level,
        muscle: muscle,
      );

      if (!isSufficient) {
        // Aumentar frecuencia si es necesario
        final minFrequency = FrequencyByVolume.calculateMinimumFrequency(
          weeklyVolume: weeklyVolume,
          level: level,
          muscle: muscle,
        );

        final adjusted = minFrequency.clamp(1, maxDaysAvailable);
        frequency = adjusted;

        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase4SplitDistribution',
            category: 'frequency_increased_session_limit',
            description: 'Frecuencia aumentada para respetar límite de sesión',
            context: {
              'muscle': muscle,
              'weeklyVolume': weeklyVolume,
              'originalFrequency': FrequencyByVolume.calculateFrequency(
                weeklyVolume: weeklyVolume,
                maxDaysAvailable: maxDaysAvailable,
              ),
              'adjustedFrequency': frequency,
              'reason': 'Session limit exceeded',
            },
          ),
        );
      }

      frequencies[muscle] = frequency;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'frequency_assigned',
          description: FrequencyByVolume.explainFrequency(
            weeklyVolume: weeklyVolume,
            frequency: frequency,
            muscle: muscle,
          ),
          context: {
            'muscle': muscle,
            'weeklyVolume': weeklyVolume,
            'frequency': frequency,
            'rule': weeklyVolume >= 21 ? '≥21→3x' : '≤20→2x',
          },
        ),
      );
    }

    return frequencies;
  }

  /// Construye la lista de músculos por día a partir de los músculos disponibles
  /// en weeklyTarget, aplicando categorías base y un fill-pass para densidad mínima.
  Map<int, List<String>> _buildDayMusclesFromAvailable({
    required int daysPerWeek,
    required List<String> availableMuscles,
  }) {
    // Categorías canónicas
    final push = <String>{
      MuscleKeys.chest,
      MuscleKeys.deltoideAnterior,
      MuscleKeys.deltoideLateral,
      MuscleKeys.deltoidePosterior,
      MuscleKeys.triceps,
    };
    final pull = <String>{
      MuscleKeys.lats,
      MuscleKeys.upperBack,
      MuscleKeys.traps,
      MuscleKeys.biceps,
    };
    final lower = <String>{
      MuscleKeys.quads,
      MuscleKeys.hamstrings,
      MuscleKeys.glutes,
      MuscleKeys.calves,
    };

    // Intersecciones con available
    List<String> ix(Set<String> set) {
      final res = set.where((m) => availableMuscles.contains(m)).toList()
        ..sort();
      return res;
    }

    List<String> withCore(List<String> list) {
      final hasCore = list.contains(MuscleKeys.abs);
      final res = <String>[...list];
      if (!hasCore && availableMuscles.contains(MuscleKeys.abs)) {
        res.add(MuscleKeys.abs);
      }
      return res..sort();
    }

    final result = <int, List<String>>{};

    if (daysPerWeek <= 3) {
      // Full-body distribuido por foco (Lower / Push / Pull)
      result[1] = withCore([...ix(lower)]);
      result[2] = withCore([...ix(push)]);
      result[3] = withCore([...ix(pull)]);
    } else if (daysPerWeek == 4) {
      // Upper / Lower alternado
      final upper = <String>{...push, ...pull};
      final upperIx = ix(upper);
      final lowerIx = ix(lower);
      result[1] = withCore([...upperIx]);
      result[2] = withCore([...lowerIx]);
      result[3] = withCore([...upperIx]);
      result[4] = withCore([...lowerIx]);
    } else if (daysPerWeek == 5) {
      // Push / Pull / Legs / Push / Pull
      result[1] = withCore([...ix(push)]);
      result[2] = withCore([...ix(pull)]);
      result[3] = withCore([...ix(lower)]);
      result[4] = withCore([...ix(push)]);
      result[5] = withCore([...ix(pull)]);
    } else {
      // 6+: PPL repetido
      result[1] = withCore([...ix(push)]);
      result[2] = withCore([...ix(pull)]);
      result[3] = withCore([...ix(lower)]);
      result[4] = withCore([...ix(push)]);
      result[5] = withCore([...ix(pull)]);
      result[6] = withCore([...ix(lower)]);
    }

    return result;
  }

  // [ELIMINADO] _applySpecializationWithTradeoffs
  // Las prioridades NO deben afectar el volumen total, solo la frecuencia
  // y el orden de ejercicios. El volumen se calcula según tolerancia y tiempo.

  String _selectSplitId(int daysPerWeek) {
    if (daysPerWeek <= 3) return 'fullbody_3d';
    if (daysPerWeek == 4) return 'upper_lower_4d';
    if (daysPerWeek == 5) return 'ppl_5d';
    return 'ppl_6d'; // 6+ → ppl_6d
  }

  String _resolveSplitId(TrainingProfile profile) {
    final extra = profile.extra;

    // 1) Estructura lockeada (si existe y aplica por semana actual)
    final structureRaw = extra[TrainingExtraKeys.trainingStructure];
    int readInt(dynamic v, int fb) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fb;
    }

    if (structureRaw is Map) {
      final s = structureRaw.cast<String, dynamic>();
      final sid = s['splitId']?.toString() ?? '';
      if (sid.isNotEmpty) {
        final fromW = readInt(s['lockedFromWeek'], 0);
        final untilRaw = s['lockedUntilWeek'];
        final untilW = (untilRaw == null) ? null : readInt(untilRaw, fromW);

        final weekIndex = profile.currentWeekIndex;
        final locked = (untilW == null)
            ? weekIndex >= fromW
            : (weekIndex >= fromW && weekIndex <= untilW);

        if (locked) return sid;
      }
    }

    // 2) Split seleccionado explícitamente por el coach en UI
    final selected = extra[TrainingExtraKeys.selectedSplitId]?.toString() ?? '';
    if (selected.isNotEmpty) return selected;

    // 3) Fallback determinista por días/semana (solo fallback)
    return _selectSplitId(profile.daysPerWeek);
  }

  Map<int, Map<String, int>> _distributeVolumeWithFrequency(
    Map<int, List<String>> dayMuscles,
    Map<String, int> weeklyTarget,
    Map<String, int> frequencyTarget,
    Map<int, String> gluteSlots,
    TrainingProfile profile,
    Map<String, VolumeLimits> volumeByMuscle,
    Set<String> prioritarySet,
    List<DecisionTrace> decisions,
  ) {
    final levelName = profile.trainingLevel?.name ?? 'beginner';
    final days = dayMuscles.keys.toList()..sort();
    final result = <int, Map<String, int>>{
      for (final d in days) d: <String, int>{},
    };

    // Detectar si es fullbody 3D para aplicar boost al músculo focal
    final isFullbody3D =
        dayMuscles.length == 3 &&
        dayMuscles.values.every((muscles) => muscles.length >= 8);

    // 1) Reparto por músculo según frecuencia objetivo y slots
    for (final entry
        in weeklyTarget.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
      final muscle = entry.key;
      final target = entry.value;

      // Días donde aparece el músculo
      final muscleDays =
          days.where((d) => dayMuscles[d]!.contains(muscle)).toList()..sort();
      if (muscleDays.isEmpty) continue; // No asignado en este split
      var freq = frequencyTarget[muscle] ?? muscleDays.length;
      freq = freq.clamp(1, muscleDays.length);

      if (profile.daysPerWeek == 4 && freq == 3) {
        final lowerMuscles = <String>{
          'quads',
          'hamstrings',
          'glutes',
          'calves',
        };
        final muscleType = lowerMuscles.contains(muscle) ? 'lower' : 'upper';
        final distribution = _distribute3xIn4Days(
          muscle: muscle,
          weeklyVolume: target,
          muscleType: muscleType,
        );

        for (final entry in distribution.entries) {
          result[entry.key]![muscle] = entry.value;
        }

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase4SplitDistribution',
            category: '3x_frequency_distributed',
            description:
                '$muscle: $target sets distribuidos en 3 sesiones (4 días)',
            context: {
              'muscle': muscle,
              'weeklyVolume': target,
              'frequency': 3,
              'distribution': distribution,
            },
          ),
        );
        continue;
      }

      // Seleccionar días con preferencia a evitar consecutivos
      final selectedDays = <int>[];
      for (final d in muscleDays) {
        if (selectedDays.isEmpty) {
          selectedDays.add(d);
        } else if (selectedDays.length < freq) {
          final last = selectedDays.last;
          if ((d - last).abs() >= 2) {
            selectedDays.add(d);
          }
        }
      }
      // Si faltan slots, rellenar secuencialmente
      for (final d in muscleDays) {
        if (selectedDays.length >= freq) break;
        if (!selectedDays.contains(d)) selectedDays.add(d);
      }

      // Validar límite por sesión usando SessionVolumeLimits
      var setsPerSession = (target / selectedDays.length).ceil();
      final sessionLimit = SessionVolumeLimits.getLimit(levelName, muscle);

      if (setsPerSession > sessionLimit) {
        // OPCIÓN A: Aumentar frecuencia automáticamente
        final minFrequency = SessionVolumeLimits.calculateMinimumFrequency(
          target,
          levelName,
          muscle,
        );

        if (minFrequency <= profile.daysPerWeek) {
          // Redistribuir en más días
          frequencyTarget[muscle] = minFrequency;

          decisions.add(
            DecisionTrace.warning(
              phase: 'Phase4SplitDistribution',
              category: 'frequency_increased_saturation',
              description:
                  'Frecuencia aumentada para evitar saturación de sesión',
              context: {
                'muscle': muscle,
                'weeklyVolume': target,
                'originalFrequency': freq,
                'newFrequency': minFrequency,
                'sessionLimit': sessionLimit,
                'originalSetsPerSession': setsPerSession,
              },
              action: 'Músculo distribuido en $minFrequency sesiones',
            ),
          );

          // Recalcular selección de días y sets por sesión
          freq = minFrequency.clamp(1, muscleDays.length);
          selectedDays
            ..clear()
            ..addAll(muscleDays.take(freq));
          setsPerSession = (target / selectedDays.length).ceil();
        } else {
          // OPCIÓN B: Reducir volumen semanal
          final adjustedVolume = sessionLimit * freq;

          decisions.add(
            DecisionTrace.warning(
              phase: 'Phase4SplitDistribution',
              category: 'volume_reduced_saturation',
              description:
                  'Volumen reducido: saturación inevitable con días disponibles',
              context: {
                'muscle': muscle,
                'originalVolume': target,
                'adjustedVolume': adjustedVolume,
                'frequency': freq,
                'daysAvailable': profile.daysPerWeek,
                'sessionLimit': sessionLimit,
              },
              action:
                  'Considere aumentar días de entrenamiento a $minFrequency',
            ),
          );

          // Ajustar volumen
          weeklyTarget[muscle] = adjustedVolume;
          if (volumeByMuscle.containsKey(muscle)) {
            volumeByMuscle[muscle] = volumeByMuscle[muscle]!.copyWith(
              recommendedStartVolume: adjustedVolume,
            );
          }
          setsPerSession = (adjustedVolume / selectedDays.length).ceil();
        }
      }

      _validateSessionVolume(
        muscle: muscle,
        setsPerSession: setsPerSession,
        level: levelName,
        decisions: decisions,
      );

      // Asignación de sets con boost para músculo focal en fullbody 3D
      if (muscle == 'glutes' && gluteSlots.isNotEmpty) {
        // heavy/moderate/pump distribution: 40/35/25%
        final heavySets = (target * 0.40).round();
        final moderateSets = (target * 0.35).round();
        final pumpSets = target - heavySets - moderateSets;
        final slotToSets = {
          'heavy': heavySets,
          'moderate': moderateSets,
          'pump': pumpSets,
        };
        for (final day in selectedDays) {
          final slot = gluteSlots[day] ?? 'moderate';
          final sets = slotToSets[slot] ?? 0;
          result[day]![muscle] = sets;
        }
      } else if (isFullbody3D) {
        // FULLBODY 3D: Mayor densidad al músculo focal del día
        // El músculo focal es el PRIMERO en dayMuscles[day]
        final focalDays = <int>[];
        final nonFocalDays = <int>[];

        for (final d in selectedDays) {
          final focalMuscle = dayMuscles[d]?.first;
          if (focalMuscle == muscle) {
            focalDays.add(d);
          } else {
            nonFocalDays.add(d);
          }
        }

        // Distribuir: día focal recibe 45% del volumen, resto se distribuye equitativamente
        if (focalDays.isNotEmpty) {
          final focalSets = (target * 0.45).round();
          for (final d in focalDays) {
            result[d]![muscle] = focalSets;
          }

          if (nonFocalDays.isNotEmpty) {
            final remaining = target - (focalSets * focalDays.length);
            final setsPerNonFocal = (remaining / nonFocalDays.length)
                .round()
                .clamp(1, 10);
            for (final d in nonFocalDays) {
              result[d]![muscle] = setsPerNonFocal;
            }
          }
        } else {
          // Fallback: distribución uniforme si no hay día focal
          final base = target ~/ selectedDays.length;
          var remainder = target - base * selectedDays.length;
          for (final d in selectedDays) {
            result[d]![muscle] = base + (remainder > 0 ? 1 : 0);
            if (remainder > 0) remainder--;
          }
        }
      } else {
        // Distribución estándar para otros splits
        final base = target ~/ selectedDays.length;
        var remainder = target - base * selectedDays.length;
        for (final d in selectedDays) {
          result[d]![muscle] = base + (remainder > 0 ? 1 : 0);
          if (remainder > 0) remainder--;
        }
      }
    }

    // 2) Validar tiempo por sesión y escalar si es necesario (4 min/set)
    final minutesPerSession = profile.timePerSessionMinutes;
    for (final d in days) {
      final setsThisDay = result[d]!.values.fold<int>(0, (s, v) => s + v);
      final estMinutes = setsThisDay * 4;
      if (estMinutes > minutesPerSession) {
        final before = Map<String, int>.from(result[d]!);
        // Reducir primero músculos NO prioritarios, respetando MEV en prioritarios
        var currentMinutes = estMinutes;
        // Conteo de días asignados por músculo (para MEV por día)
        final assignedCount = <String, int>{};
        for (final md in days) {
          for (final m in result[md]!.keys) {
            if ((result[md]![m] ?? 0) > 0) {
              assignedCount[m] = (assignedCount[m] ?? 0) + 1;
            }
          }
        }
        while (currentMinutes > minutesPerSession) {
          // seleccionar músculo candidato para reducir
          String? candidate;
          int maxSets = -1;
          for (final m in result[d]!.keys) {
            final sets = result[d]![m] ?? 0;
            if (!prioritarySet.contains(m)) {
              if (sets > maxSets) {
                maxSets = sets;
                candidate = m;
              }
            }
          }
          // Si no hay no-prioritarios o ya en cero, intentar reducir prioritarios sin violar MEV
          if (candidate == null) {
            for (final m in result[d]!.keys) {
              final sets = result[d]![m] ?? 0;
              final mev = volumeByMuscle[m]?.mev ?? 0;
              final count = assignedCount[m] ?? 1;
              final perDayMin = (mev / count).ceil();
              if (sets > mev && sets > maxSets) {
                // solo si al reducir no violamos el mínimo por día
                if (sets - 1 >= perDayMin) {
                  maxSets = sets;
                  candidate = m;
                }
              }
            }
          }
          if (candidate == null) break; // no reducible
          result[d]![candidate] = (result[d]![candidate]! - 1).clamp(0, 1000);
          currentMinutes -= 4;
        }
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase4SplitDistribution',
            category: 'time_adjustment',
            description:
                'Día $d: reducción por límite de tiempo (est=$estMinutes > max=$minutesPerSession)',
            context: {
              'before': before,
              'after': result[d],
              'minutesPerSession': minutesPerSession,
            },
            action: 'Reducido proporcionalmente sets/día',
          ),
        );
      }
    }

    return result;
  }

  /// Distribuye músculo con frecuencia 3x en split de 4 días
  Map<int, int> _distribute3xIn4Days({
    required String muscle,
    required int weeklyVolume,
    required String muscleType, // 'upper' o 'lower'
  }) {
    final distribution = FrequencyByVolume.distributeSetsAcrossFrequency(
      weeklyVolume: weeklyVolume,
      frequency: 3,
    );

    if (muscleType == 'lower') {
      return {1: distribution[0], 2: distribution[1], 3: distribution[2]};
    }

    return {1: distribution[0], 2: distribution[1], 4: distribution[2]};
  }

  /// Valida distribución de volumen respetando límites por sesión
  bool _validateSessionVolume({
    required String muscle,
    required int setsPerSession,
    required String level,
    required List<DecisionTrace> decisions,
  }) {
    final validation = SessionVolumeLimits.validateDistribution(
      setsPerSession,
      level,
      muscle,
    );

    if (validation != null) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase4SplitDistribution',
          category: 'session_saturation_detected',
          description: validation,
          context: {
            'muscle': muscle,
            'setsPerSession': setsPerSession,
            'level': level,
          },
        ),
      );
      return false;
    }

    return true;
  }

  Map<String, double> _normalizeMuscleKeys(Map<String, dynamic> raw) {
    const keyMap = {
      'chest': 'pectorals',
      'back': 'upperBack',
      'lats': 'latissimus',
      'traps': 'trapezius',
      'shoulders': 'deltoids',
      'biceps': 'biceps',
      'triceps': 'triceps',
      'forearms': 'forearms',
      'quads': 'quadriceps',
      'hamstrings': 'hamstrings',
      'glutes': 'glutes',
      'calves': 'calves',
      'abs': 'abdominals',
      'fullBody': 'fullBody',
    };

    final normalized = <String, double>{};

    for (final entry in raw.entries) {
      final rawKey = entry.key.toString();
      final mappedKey = keyMap[rawKey] ?? rawKey;
      final canonical = _canonicalMuscleKey(mappedKey);
      if (canonical == null) continue;

      final value = entry.value;
      double? sets;
      if (value is num) {
        sets = value.toDouble();
      } else if (value is String) {
        sets = double.tryParse(value.replaceAll(',', '.'));
      }

      if (sets != null) {
        normalized[canonical] = sets;
      }
    }

    return normalized;
  }

  String? _canonicalMuscleKey(String rawKey) {
    final normalized = rawKey.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-]+'),
      '',
    );

    const aliasToCanonical = {
      'pectorals': 'chest',
      'pectorales': 'chest',
      'upperback': 'back',
      'latissimus': 'lats',
      'trapezius': 'traps',
      'deltoids': 'shoulders',
      'quadriceps': 'quads',
      'abdominals': 'abs',
      'fullbody': 'fullBody',
    };

    final aliasMatch = aliasToCanonical[normalized];
    if (aliasMatch != null) return aliasMatch;

    for (final muscle in MuscleGroup.values) {
      final canonical = muscle.name.toLowerCase();
      final flattened = canonical.replaceAll(RegExp(r'[\s_\-]+'), '');
      if (normalized == flattened) {
        return muscle.name;
      }
    }

    return null;
  }

  // [ELIMINADO] _enforcePriorityLimit - Las prioridades ahora son ilimitadas.
  // Solo afectan orden de ejercicios y frecuencia de entrenamiento, NO el volumen.
}
