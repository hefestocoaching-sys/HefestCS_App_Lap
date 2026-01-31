// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/exceptions/training_plan_blocked_exception.dart';
import 'package:hcs_app_lap/domain/services/exercise_selector.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart'
    show DerivedTrainingContext;

class Phase6SelectionResult {
  /// weekIndex -> day -> muscle -> selected exercises (1-2)
  final Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>> selections;
  final List<DecisionTrace> decisions;

  const Phase6SelectionResult({
    required this.selections,
    required this.decisions,
  });
}

/// Fase 6: Selección determinística de ejercicios basada en catálogo y equipo.
/// - Prioriza compuestos
/// - Máximo 1–2 ejercicios por músculo por sesión
/// - Evita repetir dentro de la misma semana cuando hay alternativas
///
/// LÍMITES DUROS (A3):
/// - MAX_EXERCISES_PER_SESSION = 8 ejercicios máximo
/// - MAX_PRIMARY_MUSCLE_EXERCISES = 3 ejercicios máximo para músculos primarios
/// - MAX_SECONDARY_MUSCLE_EXERCISES = 2 ejercicios máximo para secundarios
/// - MAX_ACCESSORY_EXERCISES = 1 ejercicio accesorio por músculo
class Phase6ExerciseSelectionService {
  // Límites duros por sesión (TAREA A3)
  static const int MAX_EXERCISES_PER_SESSION = 8;
  static const int MAX_PRIMARY_MUSCLE_EXERCISES = 3;
  static const int MAX_SECONDARY_MUSCLE_EXERCISES = 2;
  static const int MAX_ACCESSORY_EXERCISES = 1;

  // Rastrea patrón principal por músculo dentro de la semana para evitar consecutivos.
  final Map<int, Map<String, String?>> _lastPrimaryPatternForWeek = {};

  /// Genera un número determinístico basado en clientId + muscle + day
  /// para introducir variabilidad controlada entre clientes
  int _getClientSeed(String clientId, String muscle, int dayNumber) {
    final combined = '$clientId-$muscle-$dayNumber';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
      hash = hash & hash; // Convertir a 32-bit int
    }
    return hash.abs();
  }

  Phase6SelectionResult selectExercises({
    required TrainingProfile profile,
    required SplitTemplate baseSplit,
    required Object catalog,
    int weeks = 4,
    DerivedTrainingContext? derivedContext,
    List<TrainingSessionLog>? logs,
    Map<String, List<String>>? baseExercisesByMuscle,
  }) {
    _lastPrimaryPatternForWeek.clear();
    final decisions = <DecisionTrace>[];
    final catalogList = _toExerciseList(catalog);
    // CAMBIO B — NEVER EMPTY: si el catálogo queda vacío, detener con error claro
    if (catalogList.isEmpty) {
      throw TrainingPlanBlockedException.insufficientCatalog(
        availableExercises: 0,
        equipment: profile.equipment,
        restrictions: profile.movementRestrictions,
      );
    }

    final selections = <int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>{};
    final availableEquipment = profile.equipment;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase6ExerciseSelection',
        category: 'init',
        description: 'Seleccionando ejercicios con equipo disponible',
        context: {'equipment': availableEquipment, 'weeks': weeks},
      ),
    );

    // Filtros avanzados
    final contraindicatedPatterns =
        derivedContext?.contraindicatedPatterns ?? const <String>{};
    final mustHave = derivedContext?.exerciseMustHave ?? const <String>{};
    final dislikes = derivedContext?.exerciseDislikes ?? const <String>{};
    final gluteSpec = derivedContext?.gluteSpecialization;
    final hasGluteSpec =
        (profile.gender == Gender.female) ||
        (gluteSpec != null && (gluteSpec.targetFrequencyPerWeek ?? 0) > 0);

    // Fecha de referencia para determinismo temporal
    final referenceDate = derivedContext?.referenceDate ?? DateTime(2025, 1, 1);

    // Construir historial de ejercicios recientes
    final recentExercises = _buildRecentHistory(
      logs ?? const [],
      referenceDate,
    );

    for (var w = 1; w <= weeks; w++) {
      final usedByMuscle = <MuscleGroup, Set<String>>{};
      final weekMap = <int, Map<MuscleGroup, List<ExerciseEntry>>>{};

      for (var d = 1; d <= baseSplit.daysPerWeek; d++) {
        final int minExercisesPerDay = (baseSplit.daysPerWeek >= 4) ? 5 : 3;
        final dayMuscles = baseSplit.dayMuscles[d] ?? const <String>[];
        final dayMap = <MuscleGroup, List<ExerciseEntry>>{};

        // CLAVE: Respetar el ORDEN de dayMuscles (no ordenar alfabéticamente)
        // El primer músculo es el FOCAL del día y debe seleccionarse primero
        for (final mName in dayMuscles) {
          final mg = MuscleGroup.values.firstWhere(
            (e) => e.name == mName,
            orElse: () => MuscleGroup.fullBody,
          );
          final sets = baseSplit.dailyVolume[d]?[mName] ?? 0;
          if (sets <= 0) continue;

          // RESTRICCIÓN A3: Si baseExercisesByMuscle está definido, SOLO usar ejercicios del ciclo
          if (baseExercisesByMuscle != null &&
              baseExercisesByMuscle.isNotEmpty &&
              !baseExercisesByMuscle.containsKey(mName)) {
            // Este músculo NO tiene ejercicios base definidos en el ciclo
            // NO se seleccionan ejercicios → se omite
            decisions.add(
              DecisionTrace.info(
                phase: 'Phase6ExerciseSelection',
                category: 'muscle_omitted_no_base_exercises',
                description:
                    'Semana $w Día $d: $mName omitido (sin ejercicios base en ciclo)',
                context: {'muscle': mName},
              ),
            );
            continue;
          }

          // Obtener candidatos simples por músculo (sin filtro de equipo por ahora)
          var candidates = ExerciseSelector.byMuscle(
            catalogList,
            mg.name,
            limit: 6,
            clientSeed: profile.id,
          );

          debugPrint(
            '🔍 [Phase6][Pre-filtro] Músculo=$mName, clientSeed=${profile.id}, '
            'candidates=${candidates.take(3).map((e) => e.id).toList()}',
          );

          // RESTRICCIÓN A3: Filtrar candidatos para que SOLO provengan de baseExercisesByMuscle
          if (baseExercisesByMuscle != null &&
              baseExercisesByMuscle.isNotEmpty) {
            final baseExercisesForMuscle = baseExercisesByMuscle[mName] ?? [];
            if (baseExercisesForMuscle.isNotEmpty) {
              final baseSet = baseExercisesForMuscle.toSet();
              candidates = candidates
                  .where(
                    (e) =>
                        baseSet.contains(e.id) ||
                        baseSet.contains(e.externalId),
                  )
                  .toList();

              debugPrint(
                '🔍 [Phase6][Post-filtro] Músculo=$mName, '
                'baseExercises=${baseExercisesForMuscle.take(3).toList()}, '
                'candidates filtrados=${candidates.take(3).map((e) => e.id).toList()}',
              );

              // ✅ Si el filtro dejó candidates vacío, crear Exercise desde baseExercises del ciclo
              if (candidates.isEmpty && baseExercisesForMuscle.isNotEmpty) {
                debugPrint(
                  '⚠️ [Phase6] Filtro dejó candidates=[] para $mName. Creando desde baseExercises del ciclo.',
                );
                candidates = baseExercisesForMuscle.map((exerciseId) {
                  return Exercise(
                    id: exerciseId,
                    name: exerciseId.replaceAll('_', ' '),
                    muscleKey: mName,
                    equipment: 'bodyweight',
                    externalId: exerciseId,
                    primaryMuscles: [mName],
                    secondaryMuscles: const [],
                    tertiaryMuscles: const [],
                  );
                }).toList();
                debugPrint(
                  '✅ [Phase6] Creados ${candidates.length} placeholders para $mName desde ciclo',
                );
              }
            }
          }

          List<ExerciseEntry> toEntry(List<Exercise> list) {
            return list.map((e) {
              final equipment = e.equipment.isNotEmpty
                  ? <String>[e.equipment.toLowerCase()]
                  : const <String>[];
              final provisional = ExerciseEntry(
                code: e.id.isNotEmpty
                    ? e.id
                    : (e.externalId.isNotEmpty ? e.externalId : e.name),
                name: e.name,
                muscleGroup: mg,
                equipment: equipment,
                isCompound: false,
              );
              final tags = _exerciseTags(provisional);
              final isCompound = _isCompoundPattern(tags);
              return ExerciseEntry(
                code: provisional.code,
                name: provisional.name,
                muscleGroup: provisional.muscleGroup,
                equipment: provisional.equipment,
                isCompound: isCompound,
              );
            }).toList();
          }

          var candidatesEntries = toEntry(candidates)
            ..sort((a, b) => a.code.compareTo(b.code));

          // Filtro por equipo disponible (string exacto)
          if (availableEquipment.isNotEmpty) {
            final lowerEq = availableEquipment
                .map((e) => e.toLowerCase())
                .toSet();
            final beforeEquip = candidatesEntries.length;
            candidatesEntries = candidatesEntries
                .where(
                  (e) =>
                      e.equipment.isEmpty ||
                      e.equipment.any((eq) => lowerEq.contains(eq)),
                )
                .toList();
            if (candidatesEntries.isEmpty) {
              // fallback: bodyweight default para no dejar sin ejercicio
              candidatesEntries = [
                ExerciseEntry(
                  code: '${mg.name}_bw_default',
                  name: '${mg.label} BW',
                  muscleGroup: mg,
                  equipment: const ['bodyweight'],
                  isCompound: false,
                ),
              ];
            } else if (beforeEquip != candidatesEntries.length) {
              decisions.add(
                DecisionTrace.info(
                  phase: 'Phase6ExerciseSelection',
                  category: 'filtered_by_equipment',
                  description:
                      '${mg.name}: ${beforeEquip - candidatesEntries.length} excluidos por equipo',
                  context: {'availableEquipment': lowerEq.toList()},
                ),
              );
            }
          }

          // Filtro por lesiones
          final beforeInjury = candidatesEntries.length;
          candidatesEntries = candidatesEntries
              .where((e) => !_isContraindicated(e, contraindicatedPatterns))
              .toList();
          if (candidatesEntries.length < beforeInjury) {
            decisions.add(
              DecisionTrace.info(
                phase: 'Phase6ExerciseSelection',
                category: 'filtered_by_injury_constraints',
                description:
                    '${mg.name}: ${beforeInjury - candidatesEntries.length} ejercicios excluidos por lesiones',
                context: {
                  'muscle': mg.name,
                  'excluded': beforeInjury - candidatesEntries.length,
                },
              ),
            );
          }

          // Filtro por dislikes
          final beforeDislikes = candidatesEntries.length;
          candidatesEntries = candidatesEntries
              .where(
                (e) => !dislikes.any(
                  (d) => e.code.contains(d) || e.name.toLowerCase().contains(d),
                ),
              )
              .toList();
          if (candidatesEntries.length < beforeDislikes) {
            decisions.add(
              DecisionTrace.info(
                phase: 'Phase6ExerciseSelection',
                category: 'filtered_by_dislikes',
                description:
                    '${mg.name}: ${beforeDislikes - candidatesEntries.length} ejercicios excluidos por dislikes',
                context: {
                  'muscle': mg.name,
                  'excluded': beforeDislikes - candidatesEntries.length,
                },
              ),
            );
          }

          if (candidatesEntries.isEmpty) {
            candidatesEntries = [_defaultExercise(mg)];
          }

          // Variabilidad determinística por cliente/músculo/día
          final clientId = profile.id ?? 'unknown_client';
          final seed = _getClientSeed(clientId, mg.name, d);
          final random = Random(seed);
          final shuffled = List<ExerciseEntry>.from(candidatesEntries);
          shuffled.shuffle(random);
          candidatesEntries = shuffled;

          final used = usedByMuscle.putIfAbsent(mg, () => <String>{});

          // Must-have: forzar si aplica
          ExerciseEntry? forcedMustHave;
          for (final mh in mustHave) {
            final match = candidatesEntries.firstWhere(
              (e) => e.code.contains(mh) || e.name.toLowerCase().contains(mh),
              orElse: () => candidatesEntries.first,
            );
            if (match.code.contains(mh) ||
                match.name.toLowerCase().contains(mh)) {
              forcedMustHave = match;
              decisions.add(
                DecisionTrace.info(
                  phase: 'Phase6ExerciseSelection',
                  category: 'must_have_applied',
                  description:
                      '${mg.name}: must-have forzado ($mh) → ${match.code}',
                ),
              );
              break;
            }
          }

          // Selección determinística con rotación
          ExerciseEntry pickFirst(
            List<ExerciseEntry> list, {
            bool avoidRecent = true,
          }) {
            if (forcedMustHave != null && list.contains(forcedMustHave)) {
              return forcedMustHave;
            }
            for (final e in list) {
              if (!used.contains(e.code)) {
                if (avoidRecent && recentExercises.contains(e.code)) {
                  continue;
                }
                return e;
              }
            }
            for (final e in list) {
              if (!used.contains(e.code)) return e;
            }
            return list.isNotEmpty ? list.first : _defaultExercise(mg);
          }

          final List<ExerciseEntry> selected = [];
          final lastPrimaryPattern = _lastPrimaryPatternForWeek.putIfAbsent(
            w,
            () => <String, String?>{},
          );

          if (sets <= 5) {
            final ex = pickFirst(
              _avoidSamePrimaryPattern(
                candidatesEntries,
                lastPrimaryPattern[mg.name],
              ),
            );
            selected.add(ex);
            used.add(ex.code);
            lastPrimaryPattern[mg.name] = _primaryPattern(ex);
          } else {
            // Dos ejercicios: compuesto principal + accesorio
            final primary = pickFirst(
              _avoidSamePrimaryPattern(
                candidatesEntries,
                lastPrimaryPattern[mg.name],
              ),
            );
            used.add(primary.code);
            selected.add(primary);
            lastPrimaryPattern[mg.name] = _primaryPattern(primary);

            final accessory = pickFirst(
              candidatesEntries.where((e) => e.code != primary.code).toList(),
            );
            used.add(accessory.code);
            selected.add(accessory);
          }

          dayMap[mg] = selected;
          decisions.add(
            DecisionTrace.info(
              phase: 'Phase6ExerciseSelection',
              category: 'day_selection',
              description:
                  'Semana $w Día $d: ${mg.name} → ${selected.map((e) => e.code).join(', ')}',
              context: {'sets': sets, 'muscle': mg.name},
            ),
          );
          decisions.add(
            DecisionTrace.info(
              phase: 'Phase6ExerciseSelection',
              category: 'exercise_selection_shuffled',
              description:
                  'Ejercicios seleccionados con variabilidad por cliente',
              context: {
                'clientId': clientId,
                'muscle': mg.name,
                'day': d,
                'seed': seed,
                'availableCount': candidatesEntries.length,
                'selectedCount': selected.length,
                'firstExercise': selected.first.name,
              },
            ),
          );

          // VALIDACIÓN A3: Verificar límites duros después de agregar ejercicios
          var totalExercisesThisDay = dayMap.values.fold<int>(
            0,
            (sum, list) => sum + list.length,
          );
          if (totalExercisesThisDay >= MAX_EXERCISES_PER_SESSION) {
            // Hemos alcanzado el máximo de ejercicios por sesión (8)
            // Detener selección inmediatamente
            decisions.add(
              DecisionTrace.info(
                phase: 'Phase6ExerciseSelection',
                category: 'max_exercises_reached',
                description:
                    'Semana $w Día $d: Alcanzado límite máximo de $MAX_EXERCISES_PER_SESSION ejercicios. Deteniendo selección.',
                context: {'totalExercises': totalExercisesThisDay},
              ),
            );
            break; // Salir del loop de músculos del día
          }
        }
        // Si el día quedó sin ejercicios, aplicar fallback determinista seguro
        var totalSelectedForDay = dayMap.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        );
        if (totalSelectedForDay == 0) {
          final fallback = _deterministicFallbackForDay(
            dayMuscles: dayMuscles,
            catalog: catalogList,
            availableEquipment: availableEquipment,
            minExercisesForDay: minExercisesPerDay,
            clientSeed: profile.id,
          );
          if (fallback.isEmpty) {
            throw TrainingPlanBlockedException(
              reason:
                  'No se pudo generar selección de ejercicios para el día $d',
              context: {
                'day': d,
                'dayMuscles': dayMuscles,
                'equipment': availableEquipment,
              },
              suggestions: [
                'Ampliar el equipamiento disponible',
                'Reducir las restricciones de movimiento',
                'Verificar que el catálogo contenga ejercicios para estos músculos',
              ],
            );
          }
          // Registrar fallback crítico
          decisions.add(
            DecisionTrace.critical(
              phase: 'Phase6ExerciseSelection',
              category: 'exercise_fallback_applied',
              description: 'Fallback determinista aplicado para día vacío',
              context: {
                'day': d,
                'muscles': dayMuscles,
                'count': fallback.values.fold<int>(0, (s, l) => s + l.length),
              },
            ),
          );
          // Asegurar mínimo 4 ejercicios en el día
          final fallbackTotal = fallback.values.fold<int>(
            0,
            (sum, list) => sum + list.length,
          );
          if (fallbackTotal < minExercisesPerDay) {
            throw TrainingPlanBlockedException.insufficientExercisesPerDay(
              week: 1,
              day: d,
              count: fallbackTotal,
              minimum: minExercisesPerDay,
            );
          }
          weekMap[d] = fallback;
        } else {
          // Si hay menos del mínimo, completar con fallback determinista
          if (totalSelectedForDay < minExercisesPerDay) {
            final fallback = _deterministicFallbackForDay(
              dayMuscles: dayMuscles,
              catalog: catalogList,
              availableEquipment: availableEquipment,
              minExercisesForDay: minExercisesPerDay,
              clientSeed: profile.id,
            );
            // Merge determinista evitando duplicados por código
            final existingCodes = dayMap.values
                .expand((l) => l)
                .map((e) => e.code)
                .toSet();
            outer:
            for (final entry in fallback.entries) {
              final mg = entry.key;
              final list = entry.value;
              final target = dayMap.putIfAbsent(mg, () => <ExerciseEntry>[]);
              for (final e in list) {
                if (existingCodes.contains(e.code)) continue;
                target.add(e);
                existingCodes.add(e.code);
                totalSelectedForDay++;
                if (totalSelectedForDay >= minExercisesPerDay) break outer;
              }
            }
            if (totalSelectedForDay < minExercisesPerDay) {
              throw TrainingPlanBlockedException.insufficientExercisesPerDay(
                week: 1,
                day: d,
                count: totalSelectedForDay,
                minimum: minExercisesPerDay,
              );
            }
            decisions.add(
              DecisionTrace.critical(
                phase: 'Phase6ExerciseSelection',
                category: 'exercise_fallback_applied',
                description:
                    'Fallback determinista aplicado para completar día (<4)',
                context: {
                  'day': d,
                  'muscles': dayMuscles,
                  'finalCount': totalSelectedForDay,
                },
              ),
            );
          }
          weekMap[d] = dayMap;
        }
      }

      selections[w] = weekMap;

      // Glute specialization bias
      if (hasGluteSpec) {
        _applyGluteSpecializationBias(
          weekMap,
          catalogList,
          availableEquipment,
          contraindicatedPatterns,
          decisions,
          clientSeed: profile.id,
        );
      }
    }

    return Phase6SelectionResult(selections: selections, decisions: decisions);
  }

  // Fallback determinista por día: selecciona 4–6 ejercicios “safe gym”
  // basados en músculos del día y equipo disponible. Sin heurísticas por texto
  // para elegir grupos: usa metadata de músculo y equipo.
  Map<MuscleGroup, List<ExerciseEntry>> _deterministicFallbackForDay({
    required List<String> dayMuscles,
    required List<Exercise> catalog,
    required List<String> availableEquipment,
    required int minExercisesForDay,
    String? clientSeed,
  }) {
    final lowerEq = availableEquipment.map((e) => e.toLowerCase()).toSet();
    final result = <MuscleGroup, List<ExerciseEntry>>{};

    // Si no hay músculos definidos para el día, asumir fullBody
    final muscles = dayMuscles.isEmpty ? <String>['fullBody'] : dayMuscles;

    // Selección: priorizar compuestos por músculo, filtrar por equipo
    for (final mName in muscles) {
      final mg = MuscleGroup.values.firstWhere(
        (e) => e.name == mName,
        orElse: () => MuscleGroup.fullBody,
      );
      final candidates =
          ExerciseSelector.byMuscle(
                catalog,
                mg.name,
                limit: 12,
                clientSeed: clientSeed,
              )
              .map(
                (e) => ExerciseEntry(
                  code: e.id.isNotEmpty
                      ? e.id
                      : (e.externalId.isNotEmpty ? e.externalId : e.name),
                  name: e.name,
                  muscleGroup: mg,
                  equipment: e.equipment.isNotEmpty
                      ? <String>[e.equipment.toLowerCase()]
                      : const <String>[],
                  isCompound: false, // compuesto se recalcula por tags
                ),
              )
              .where(
                (e) => e.equipment.isEmpty || e.equipment.any(lowerEq.contains),
              )
              .toList()
            ..sort((a, b) => a.code.compareTo(b.code));

      // Marcar compuestos por patrones conocidos (permite componer día con base segura)
      final enriched = candidates.map((c) {
        final tags = _exerciseTags(c);
        final isCompound = _isCompoundPattern(tags);
        return ExerciseEntry(
          code: c.code,
          name: c.name,
          muscleGroup: c.muscleGroup,
          equipment: c.equipment,
          isCompound: isCompound,
        );
      }).toList();

      // Tomar hasta 2 por músculo: primero compuestos, luego accesorios
      final compounds = enriched.where((e) => e.isCompound).take(2).toList();
      final accessories = enriched.where((e) => !e.isCompound).take(2).toList();
      final pick = <ExerciseEntry>[...compounds, ...accessories];

      if (pick.isEmpty) {
        pick.add(_defaultExercise(mg));
      }

      result[mg] = pick;
    }

    // Si total < minExercisesForDay, intentar completar con fullBody o defaults
    var total = result.values.fold<int>(0, (s, l) => s + l.length);
    if (total < minExercisesForDay) {
      final mg = MuscleGroup.fullBody;
      final current = result.putIfAbsent(mg, () => <ExerciseEntry>[]);
      final fb =
          ExerciseSelector.byMuscle(
                catalog,
                'fullBody',
                limit: 6,
                clientSeed: clientSeed,
              )
              .map(
                (e) => ExerciseEntry(
                  code: e.id.isNotEmpty
                      ? e.id
                      : (e.externalId.isNotEmpty ? e.externalId : e.name),
                  name: e.name,
                  muscleGroup: mg,
                  equipment: e.equipment.isNotEmpty
                      ? <String>[e.equipment.toLowerCase()]
                      : const <String>[],
                  isCompound: false,
                ),
              )
              .where(
                (e) => e.equipment.isEmpty || e.equipment.any(lowerEq.contains),
              )
              .toList()
            ..sort((a, b) => a.code.compareTo(b.code));
      for (final e in fb) {
        if (current.length >= 3) break; // no exceder 6 totales sumando otros
        current.add(e);
      }
      while (current.length < 2) {
        current.add(_defaultExercise(mg));
      }
      total = result.values.fold<int>(0, (s, l) => s + l.length);
    }

    return result;
  }

  List<Exercise> _toExerciseList(Object catalog) {
    if (catalog is List<Exercise>) return catalog;
    if (catalog is ExerciseCatalog) {
      return catalog.entries
          .map(
            (e) => Exercise(
              id: e.code,
              externalId: e.code,
              name: e.name,
              muscleKey: e.muscleGroup.name,
              equipment: e.equipment.isNotEmpty ? e.equipment.first : '',
              difficulty: '',
              gifUrl: '',
            ),
          )
          .toList();
    }
    return const <Exercise>[];
  }

  Set<String> _exerciseTags(ExerciseEntry e) {
    final tags = <String>{};
    final code = e.code.toLowerCase();
    final name = e.name.toLowerCase();
    if (code.contains('squat') || name.contains('squat')) tags.add('squat');
    if (code.contains('deadlift') ||
        code.contains('rdl') ||
        name.contains('deadlift')) {
      tags.add('hinge');
    }
    if (code.contains('thrust') ||
        code.contains('bridge') ||
        name.contains('thrust')) {
      tags.add('thrust');
    }
    if (code.contains('abduction') || name.contains('abduction')) {
      tags.add('abduction');
    }
    if (code.contains('overhead') ||
        code.contains('press') && name.contains('overhead')) {
      tags.add('overhead');
    }
    if (code.contains('row') || name.contains('row')) tags.add('row');
    if (code.contains('press') || name.contains('press')) tags.add('press');
    return tags;
  }

  bool _isCompoundPattern(Set<String> tags) {
    return tags.contains('squat') ||
        tags.contains('hinge') ||
        tags.contains('press') ||
        tags.contains('overhead') ||
        tags.contains('row') ||
        tags.contains('thrust');
  }

  List<ExerciseEntry> _avoidSamePrimaryPattern(
    List<ExerciseEntry> list,
    String? lastPattern,
  ) {
    if (lastPattern == null) return list;
    final filtered = list.where((e) {
      final tags = _exerciseTags(e);
      return !tags.contains(lastPattern);
    }).toList();
    return filtered.isNotEmpty ? filtered : list;
  }

  String? _primaryPattern(ExerciseEntry e) {
    final tags = _exerciseTags(e);
    for (final t in ['squat', 'hinge', 'press', 'overhead', 'row', 'thrust']) {
      if (tags.contains(t)) return t;
    }
    return null;
  }

  bool _isContraindicated(
    ExerciseEntry e,
    Set<String> contraindicatedPatterns,
  ) {
    final tags = _exerciseTags(e);
    for (final pattern in contraindicatedPatterns) {
      final p = pattern.toLowerCase();
      if (tags.contains(p)) return true;
      if (p.contains('lumbar') && tags.contains('hinge')) return true;
      if (p.contains('knee') && tags.contains('squat')) return true;
      if (p.contains('shoulder') && tags.contains('overhead')) return true;
    }
    return false;
  }

  ExerciseEntry _defaultExercise(MuscleGroup mg) {
    return ExerciseEntry(
      code: '${mg.name}_bw_default',
      name: mg.label,
      muscleGroup: mg,
      equipment: const ['bodyweight'],
      isCompound: false,
    );
  }

  Set<String> _buildRecentHistory(
    List<TrainingSessionLog> logs,
    DateTime referenceDate,
  ) {
    final recent = <String>{};

    // Estrategia preferida: usar últimos N logs disponibles (top-K)
    // Esto es más determinista que depender de fechas
    if (logs.isEmpty) return recent;

    // Ordenar logs por fecha (más recientes primero)
    final sortedLogs = logs.toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.dateIso) ?? DateTime(2000);
        final dateB = DateTime.tryParse(b.dateIso) ?? DateTime(2000);
        return dateB.compareTo(dateA); // Descendente
      });

    // Tomar los últimos 5 logs (o menos si hay menos disponibles)
    const maxRecentLogs = 5;
    final recentLogs = sortedLogs.take(maxRecentLogs);

    for (final log in recentLogs) {
      for (final entry in log.entries) {
        final code = entry.exerciseIdOrName;
        if (code.isNotEmpty) {
          recent.add(code);
        }
      }
    }

    return recent;
  }

  void _applyGluteSpecializationBias(
    Map<int, Map<MuscleGroup, List<ExerciseEntry>>> weekMap,
    List<Exercise> catalog,
    List<String> availableEquipment,
    Set<String> contraindicatedPatterns,
    List<DecisionTrace> decisions, {
    String? clientSeed,
  }) {
    // 1. Detectar patrones presentes en la semana
    final patterns = <String>{};
    var hasThrust = false;
    var hasAbduction = false;
    var hasHinge = false;

    for (final dayMap in weekMap.values) {
      final gluteExs = dayMap[MuscleGroup.glutes] ?? const [];
      for (final e in gluteExs) {
        final tags = _exerciseTags(e);
        if (tags.contains('thrust')) hasThrust = true;
        if (tags.contains('abduction')) hasAbduction = true;
        if (tags.contains('hinge')) hasHinge = true;
        patterns.addAll(tags);
      }
    }

    // 2. Definir cobertura mínima semanal requerida
    final missingPatterns = <String>[];
    if (!hasThrust) missingPatterns.add('thrust');
    if (!hasAbduction) missingPatterns.add('abduction');

    // Solo agregar hinge si no está contraindicado
    if (!hasHinge &&
        !contraindicatedPatterns.any(
          (p) => p.contains('lumbar') || p.contains('hinge'),
        )) {
      missingPatterns.add('hinge');
    }

    // Siempre registrar que se aplicó especialización (incluso si está completa)
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase6ExerciseSelection',
        category: 'glute_specialization_bias_applied',
        description: missingPatterns.isEmpty
            ? 'Especialización glúteo: cobertura completa detectada'
            : 'Especialización glúteo: intentando cubrir patrones faltantes',
        context: {
          'presentPatterns': patterns.toList(),
          'missingPatterns': missingPatterns,
          'hasThrust': hasThrust,
          'hasAbduction': hasAbduction,
          'hasHinge': hasHinge,
        },
      ),
    );

    if (missingPatterns.isEmpty) {
      // Cobertura completa, no hacer nada más
      return;
    }

    // 3. Intentar swaps para cubrir patrones faltantes
    for (final pattern in missingPatterns) {
      final swapped = _trySwapForPattern(
        pattern: pattern,
        weekMap: weekMap,
        catalog: catalog,
        availableEquipment: availableEquipment,
        contraindicatedPatterns: contraindicatedPatterns,
        decisions: decisions,
        clientSeed: clientSeed,
      );

      if (!swapped) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase6ExerciseSelection',
            category: 'glute_specialization_swap_failed',
            description: 'No se pudo cubrir patrón faltante: $pattern',
            context: {
              'pattern': pattern,
              'reason': 'Sin ejercicios disponibles o sin días con glúteos',
            },
          ),
        );
      }
    }
  }

  /// Intenta hacer swap de un ejercicio de glúteo para cubrir un patrón faltante.
  /// Retorna true si se realizó el swap exitosamente.
  bool _trySwapForPattern({
    required String pattern,
    required Map<int, Map<MuscleGroup, List<ExerciseEntry>>> weekMap,
    required List<Exercise> catalog,
    required List<String> availableEquipment,
    required Set<String> contraindicatedPatterns,
    required List<DecisionTrace> decisions,
    String? clientSeed,
  }) {
    // 1. Buscar ejercicios elegibles para este patrón
    final candidates =
        ExerciseSelector.byMuscle(
              catalog,
              'glutes',
              limit: 6,
              clientSeed: clientSeed,
            )
            .map(
              (e) => ExerciseEntry(
                code: e.id.isNotEmpty
                    ? e.id
                    : (e.externalId.isNotEmpty ? e.externalId : e.name),
                name: e.name,
                muscleGroup: MuscleGroup.glutes,
                equipment: e.equipment.isNotEmpty
                    ? <String>[e.equipment]
                    : const [],
                isCompound: false,
              ),
            )
            .where((e) => !_isContraindicated(e, contraindicatedPatterns))
            .where((e) {
              final tags = _exerciseTags(e);
              return tags.contains(pattern);
            })
            .toList();

    if (candidates.isEmpty) {
      // No hay ejercicios disponibles para este patrón
      return false;
    }

    // 2. Buscar día con glúteos y ejercicio menos crítico para swap
    for (final dayEntry
        in weekMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final day = dayEntry.key;
      final dayMap = dayEntry.value;
      final gluteExs = dayMap[MuscleGroup.glutes];

      if (gluteExs == null || gluteExs.isEmpty) continue;

      // 3. Identificar ejercicio menos crítico (no-compuesto preferido, o último)
      ExerciseEntry? toReplace;

      // Preferir reemplazar accesorios antes que compuestos
      for (final ex in gluteExs) {
        final tags = _exerciseTags(ex);
        // No reemplazar si ya tiene el patrón que buscamos
        if (tags.contains(pattern)) continue;

        // Preferir no-compuestos
        if (!ex.isCompound) {
          toReplace = ex;
          break;
        }
      }

      // Si no hay accesorios, tomar el último ejercicio
      if (toReplace == null && gluteExs.isNotEmpty) {
        final lastEx = gluteExs.last;
        final lastTags = _exerciseTags(lastEx);
        if (!lastTags.contains(pattern)) {
          toReplace = lastEx;
        }
      }

      if (toReplace == null) continue;

      // 4. Hacer el swap
      final replacement = candidates.first; // Determinístico: tomar el primero
      final newList = gluteExs.map((e) {
        if (e.code == toReplace!.code) {
          return replacement;
        }
        return e;
      }).toList();

      dayMap[MuscleGroup.glutes] = newList;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase6ExerciseSelection',
          category: 'glute_specialization_swap_applied',
          description: 'Día $day: swap ${toReplace.code} → ${replacement.code}',
          context: {
            'day': day,
            'pattern': pattern,
            'before': toReplace.code,
            'after': replacement.code,
          },
        ),
      );

      return true; // Swap exitoso
    }

    return false; // No se pudo hacer swap
  }
}
