import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

class Phase8FinalizeResult {
  final bool isBlocked;
  final String? blockedReason;
  final Map<String, dynamic> blockedDetails;

  final Map<String, dynamic>? finalPlanJson;
  final Map<String, dynamic>? learningPayload;

  final List<DecisionTrace> decisions;

  const Phase8FinalizeResult({
    required this.isBlocked,
    required this.blockedReason,
    required this.blockedDetails,
    required this.finalPlanJson,
    required this.learningPayload,
    required this.decisions,
  });

  factory Phase8FinalizeResult.blocked({
    required String reason,
    required DateTime ts,
    Map<String, dynamic> details = const {},
    List<DecisionTrace> decisions = const [],
  }) {
    return Phase8FinalizeResult(
      isBlocked: true,
      blockedReason: reason,
      blockedDetails: details,
      finalPlanJson: null,
      learningPayload: null,
      decisions: [
        ...decisions,
        DecisionTrace.critical(
          phase: 'Phase8FinalizeAndLearning',
          category: 'validation_failed',
          description: reason,
          context: details,
          timestamp: ts,
          action: 'Corregir los puntos indicados y volver a generar.',
        ),
      ],
    );
  }
}

class Phase8FinalizeAndLearning {
  Phase8FinalizeResult run({
    required TrainingContext ctx,
    required Map<String, dynamic> baseState,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    // -------- 1) Validaciones mínimas ----------
    final errors = <String>[];
    final warnings = <String>[];

    final p1 = baseState['phase1'];
    final p4 = baseState['phase4'];
    final p5 = baseState['phase5'];
    final p6 = baseState['phase6'];
    final p7 = baseState['phase7'];

    if (p1 is! Map) errors.add('Falta phase1 en baseState.');
    if (p4 is! Map || p4['weeklySplit'] is! Map) {
      errors.add('Falta phase4.weeklySplit en baseState.');
    }
    if (p5 is! Map || p5['prescriptionsByDay'] is! Map) {
      errors.add('Falta phase5.prescriptionsByDay en baseState.');
    }
    if (p6 is! Map || p6['selectionsByDay'] is! Map) {
      errors.add('Falta phase6.selectionsByDay en baseState.');
    }

    final days = ctx.meta.daysPerWeek;
    if (days <= 0) errors.add('daysPerWeek inválido.');

    final minExercisesPerDay =
        _readInt(p1, ['caps', 'minExercisesPerDay']) ?? 4;
    final maxIntensificationPerWeek =
        _readInt(p1, ['caps', 'maxIntensificationPerWeek']) ?? 2;

    // Validar coherencia día por día
    if (p4 is Map && p6 is Map) {
      final weeklySplit = (p4['weeklySplit'] as Map?) ?? const {};
      final selections = (p6['selectionsByDay'] as Map?) ?? const {};

      for (var d = 1; d <= days; d++) {
        final splitDay = weeklySplit[d.toString()];
        if (splitDay is! Map) {
          errors.add('Día $d: weeklySplit ausente.');
          continue;
        }

        final musclesCount = splitDay.keys.length;
        if (musclesCount < minExercisesPerDay) {
          errors.add(
            'Día $d: tiene $musclesCount músculos (< $minExercisesPerDay).',
          );
        }

        final selDay = selections[d.toString()];
        if (selDay is! Map) {
          errors.add('Día $d: selectionsByDay ausente.');
          continue;
        }

        for (final m in splitDay.keys) {
          final sel = selDay[m];
          if (sel is! List || sel.isEmpty) {
            errors.add('Día $d: músculo "$m" sin ejercicios seleccionados.');
          }
        }
      }
    }

    // Intensificación no excede cap
    if (p7 is Map) {
      final appliedCount = (p7['appliedCount'] is num)
          ? (p7['appliedCount'] as num).toInt()
          : 0;
      if (appliedCount > maxIntensificationPerWeek) {
        errors.add(
          'Intensificación excede cap: appliedCount=$appliedCount > maxPerWeek=$maxIntensificationPerWeek.',
        );
      }
    } else {
      warnings.add('phase7 no presente; se asume sin intensificación.');
    }

    if (errors.isNotEmpty) {
      return Phase8FinalizeResult.blocked(
        reason: 'Validación final falló (Phase8).',
        ts: ts,
        details: {'errors': errors, 'warnings': warnings},
        decisions: decisions,
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8FinalizeAndLearning',
        category: 'validation_passed',
        description: 'Validación final exitosa.',
        context: {
          'daysPerWeek': days,
          'minExercisesPerDay': minExercisesPerDay,
          'warnings': warnings,
        },
        timestamp: ts,
      ),
    );

    // -------- 2) Empaquetado del plan final ----------
    final planVersion = 'v2.0.0';
    final finalPlan = <String, dynamic>{
      'schemaVersion': planVersion,
      'generatedAt': ts.toIso8601String(),
      'engine': {'name': 'training_engine_v2', 'phases': 8},
      'meta': {
        'daysPerWeek': ctx.meta.daysPerWeek,
        'timePerSessionMinutes': ctx.meta.timePerSessionMinutes,
        'level': ctx.meta.level?.name,
        'goal': ctx.meta.goal.name,
        'focus': ctx.meta.focus?.name,
      },
      'signals': {
        'energyState': ctx.energy.state,
        'energyMagnitude': ctx.energy.magnitude,
        'readinessScore': _readDouble(p1, ['readinessScore']) ?? 0.0,
        'readinessLevel': _readString(p1, ['readinessLevel']) ?? 'unknown',
      },
      'state': baseState, // auditability end-to-end
    };

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8FinalizeAndLearning',
        category: 'plan_packaged',
        description: 'Plan v2 empaquetado (schema estable).',
        context: {
          'schemaVersion': planVersion,
          'includedStateKeys': baseState.keys.toList(),
        },
        timestamp: ts,
      ),
    );

    // -------- 3) Payload de aprendizaje (para persistir) ----------
    // NO entrenamos aquí; solo definimos el snapshot que se guardará para que,
    // cuando llegue bitácora y feedback real, se actualicen posteriors.
    final learning = <String, dynamic>{
      'schemaVersion': 'learning_v1',
      'asOfDate': ts.toIso8601String(),
      'clientSignals': {
        'level': ctx.meta.level?.name,
        'goal': ctx.meta.goal.name,
        'energyState': ctx.energy.state,
        'energyMagnitude': ctx.energy.magnitude,
      },
      // Targets que el motor "decidió" esta semana (para comparar vs. adherencia/rendimiento)
      'targets': {
        'weeklySetsByMuscle':
            (baseState['phase3'] as Map?)?['targetWeeklySetsByMuscle'] ??
            const {},
        'chosenPercentiles':
            (baseState['phase3'] as Map?)?['chosenPercentileByMuscle'] ??
            const {},
        'frequencyByMuscle':
            (baseState['phase4'] as Map?)?['frequencyByMuscle'] ?? const {},
        'dayLoadProfile':
            (baseState['phase5'] as Map?)?['dayLoadProfile'] ?? const {},
        'intensificationApplied':
            (baseState['phase7'] as Map?)?['appliedCount'] ?? 0,
      },
      // Resumen de selección (para rotación futura)
      'selectedExerciseIdsByMuscle': _extractSelectedExerciseIds(baseState),
      // Huella de decisiones (para auditoría y análisis global)
      // Nota: el DecisionTrace completo ya se retorna fuera, pero aquí guardamos un resumen ligero.
      'decisionDigest': {
        'hasWarnings': warnings.isNotEmpty,
        'warnings': warnings,
      },
    };

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8FinalizeAndLearning',
        category: 'learning_payload_created',
        description: 'Payload de aprendizaje construido (persistible).',
        context: {
          'schemaVersion': learning['schemaVersion'],
          'targetsKeys': (learning['targets'] as Map).keys.toList(),
        },
        timestamp: ts,
      ),
    );

    return Phase8FinalizeResult(
      isBlocked: false,
      blockedReason: null,
      blockedDetails: const {},
      finalPlanJson: finalPlan,
      learningPayload: learning,
      decisions: decisions,
    );
  }

  Map<String, List<String>> _extractSelectedExerciseIds(
    Map<String, dynamic> baseState,
  ) {
    final out = <String, List<String>>{};
    final p6 = baseState['phase6'];
    if (p6 is! Map) return out;

    final selectionsByDay = p6['selectionsByDay'];
    if (selectionsByDay is! Map) return out;

    for (final dayEntry in selectionsByDay.entries) {
      final muscles = dayEntry.value;
      if (muscles is! Map) continue;

      for (final mEntry in muscles.entries) {
        final muscle = mEntry.key.toString();
        final list = mEntry.value;
        if (list is! List) continue;

        for (final item in list) {
          if (item is Map) {
            final id = item['exerciseId']?.toString();
            if (id == null || id.isEmpty) continue;
            out.putIfAbsent(muscle, () => <String>[]);
            if (!out[muscle]!.contains(id)) out[muscle]!.add(id);
          }
        }
      }
    }

    return out;
  }

  int? _readInt(Object? root, List<String> path) {
    final v = _read(root, path);
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  double? _readDouble(Object? root, List<String> path) {
    final v = _read(root, path);
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  String? _readString(Object? root, List<String> path) {
    final v = _read(root, path);
    if (v == null) return null;
    return v.toString();
  }

  Object? _read(Object? root, List<String> path) {
    Object? cur = root;
    for (final k in path) {
      if (cur is Map && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return null;
      }
    }
    return cur;
  }
}
