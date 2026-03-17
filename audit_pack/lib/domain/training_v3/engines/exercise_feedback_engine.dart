// lib/domain/training_v3/engines/exercise_feedback_engine.dart

import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';

/// Motor de procesamiento de feedback sobre ejercicios
///
/// Analiza el rendimiento de ejercicios individuales para detectar:
/// - Ejercicios problemáticos (dolor, técnica mala, estancamiento)
/// - Ejercicios candidatos para swap
/// - Ejercicios que están funcionando bien
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5: Selección individualizada de ejercicios
/// - No todos los ejercicios funcionan igual para todos
/// - Variación necesaria para progresión continua
///
/// Versión: 1.0.0
class ExerciseFeedbackEngine {
  /// Analiza feedback de un ejercicio específico
  ///
  /// ALGORITMO:
  /// 1. Analizar historial de logs (3+ sesiones)
  /// 2. Detectar patrones problemáticos
  /// 3. Calcular score de efectividad
  /// 4. Generar recomendación
  ///
  /// PARÁMETROS:
  /// - [exerciseLogs]: Logs del ejercicio (últimas 3-6 sesiones)
  /// - [exerciseId]: ID del ejercicio
  ///
  /// RETORNA:
  /// - Map con análisis y recomendación
  static Map<String, dynamic> analyzeExerciseFeedback({
    required List<ExerciseLog> exerciseLogs,
    required String exerciseId,
  }) {
    if (exerciseLogs.length < 3) {
      return {
        'can_analyze': false,
        'reason': 'Se requieren al menos 3 sesiones',
      };
    }

    // PASO 1: Detectar problemas
    final problems = _detectProblems(exerciseLogs);

    // PASO 2: Calcular efectividad
    final effectiveness = _calculateEffectiveness(exerciseLogs);

    // PASO 3: Determinar acción
    final action = _determineAction(problems, effectiveness);

    return {
      'can_analyze': true,
      'exercise_id': exerciseId,
      'problems': problems,
      'effectiveness_score': effectiveness,
      'action': action,
      'sessions_analyzed': exerciseLogs.length,
    };
  }

  /// Detecta problemas con el ejercicio
  ///
  /// PROBLEMAS DETECTADOS:
  /// 1. No completado frecuentemente (>50% sesiones)
  /// 2. RPE consistentemente muy alto (>9)
  /// 3. Estancamiento (sin progresión 3+ sesiones)
  /// 4. Notas de dolor/molestia
  static List<String> _detectProblems(List<ExerciseLog> logs) {
    final problems = <String>[];

    // Problema 1: Baja tasa de completado
    final incompleteSessions = logs.where((l) => !l.completed).length;
    final incompleteRate = incompleteSessions / logs.length;

    if (incompleteRate > 0.5) {
      problems.add(
        'No completado en ${(incompleteRate * 100).toStringAsFixed(0)}% de sesiones',
      );
    }

    // Problema 2: RPE muy alto consistente
    final highRpeSessions = logs.where((l) => l.averageRpe > 9.0).length;
    if (highRpeSessions == logs.length) {
      problems.add(
        'RPE consistentemente muy alto (>${logs.first.averageRpe.toStringAsFixed(1)})',
      );
    }

    // Problema 3: Estancamiento
    if (_hasStagnated(logs)) {
      problems.add(
        'Sin progresión de carga en últimas ${logs.length} sesiones',
      );
    }

    // Problema 4: Notas de dolor
    final painNotes = logs
        .where(
          (l) =>
              l.notes != null &&
              (l.notes!.toLowerCase().contains('dolor') ||
                  l.notes!.toLowerCase().contains('molestia')),
        )
        .length;

    if (painNotes > 0) {
      problems.add('Dolor/molestia reportado en $painNotes sesión(es)');
    }

    return problems;
  }

  /// Calcula score de efectividad (0.0-1.0)
  ///
  /// CRITERIOS:
  /// - Tasa de completado (30%)
  /// - Progresión de carga (30%)
  /// - RPE apropiado (20%)
  /// - Adherencia (20%)
  static double _calculateEffectiveness(List<ExerciseLog> logs) {
    // Criterio 1: Tasa de completado
    final completionRate = logs.where((l) => l.completed).length / logs.length;

    // Criterio 2: Progresión
    final hasProgressed = _hasProgressed(logs);
    final progressionScore = hasProgressed ? 1.0 : 0.0;

    // Criterio 3: RPE apropiado (7-9 = óptimo)
    final avgRpe = logs.fold(0.0, (sum, l) => sum + l.averageRpe) / logs.length;
    double rpeScore;
    if (avgRpe >= 7.0 && avgRpe <= 9.0) {
      rpeScore = 1.0;
    } else if (avgRpe < 7.0) {
      rpeScore = 0.5; // Muy fácil
    } else {
      rpeScore = 0.3; // Muy duro
    }

    // Criterio 4: Adherencia (sets completados vs planeados)
    final avgAdherence =
        logs.fold(0.0, (sum, l) {
          final adherence = l.sets.length / l.plannedSets;
          return sum + adherence;
        }) /
        logs.length;

    // Calcular score ponderado
    final score =
        (completionRate * 0.3) +
        (progressionScore * 0.3) +
        (rpeScore * 0.2) +
        (avgAdherence * 0.2);

    return score;
  }

  /// Determina acción recomendada
  static Map<String, dynamic> _determineAction(
    List<String> problems,
    double effectiveness,
  ) {
    // Si hay problemas de dolor → swap inmediato
    if (problems.any((p) => p.contains('Dolor'))) {
      return {
        'action': 'swap_immediately',
        'reason': 'Dolor/molestia reportado',
        'urgency': 'high',
      };
    }

    // Si efectividad muy baja → swap
    if (effectiveness < 0.4) {
      return {
        'action': 'swap',
        'reason':
            'Efectividad baja (${(effectiveness * 100).toStringAsFixed(0)}%)',
        'urgency': 'medium',
      };
    }

    // Si efectividad baja-media → considerar swap
    if (effectiveness < 0.6) {
      return {
        'action': 'consider_swap',
        'reason':
            'Efectividad moderada (${(effectiveness * 100).toStringAsFixed(0)}%)',
        'urgency': 'low',
      };
    }

    // Si estancado → variar
    if (problems.any((p) => p.contains('progresión'))) {
      return {
        'action': 'vary_stimulus',
        'reason': 'Estancamiento detectado',
        'urgency': 'low',
      };
    }

    // Si todo bien → mantener
    return {
      'action': 'keep',
      'reason':
          'Ejercicio funcionando bien (${(effectiveness * 100).toStringAsFixed(0)}% efectividad)',
      'urgency': 'none',
    };
  }

  /// Verifica si hubo progresión de carga
  static bool _hasProgressed(List<ExerciseLog> logs) {
    if (logs.length < 2) return false;

    final firstLog = logs.first;
    final lastLog = logs.last;

    final firstAvgWeight =
        firstLog.sets.fold(0.0, (sum, s) => sum + s.weight) /
        firstLog.sets.length;
    final lastAvgWeight =
        lastLog.sets.fold(0.0, (sum, s) => sum + s.weight) /
        lastLog.sets.length;

    return lastAvgWeight > firstAvgWeight;
  }

  /// Verifica si hay estancamiento
  static bool _hasStagnated(List<ExerciseLog> logs) {
    if (logs.length < 3) return false;

    final weights = logs.map((l) {
      return l.sets.fold(0.0, (sum, s) => sum + s.weight) / l.sets.length;
    }).toList();

    // Si todas las cargas son iguales (±5kg tolerancia)
    final firstWeight = weights.first;
    return weights.every((w) => (w - firstWeight).abs() <= 5);
  }

  /// Agrupa feedback de múltiples ejercicios
  ///
  /// USADO PARA: Reporte semanal/mensual
  static Map<String, dynamic> aggregateFeedback({
    required Map<String, List<ExerciseLog>> exerciseLogsByExercise,
  }) {
    final toSwap = <String>[];
    final toConsider = <String>[];
    final working = <String>[];

    exerciseLogsByExercise.forEach((exerciseId, logs) {
      if (logs.length < 3) return;

      final analysis = analyzeExerciseFeedback(
        exerciseLogs: logs,
        exerciseId: exerciseId,
      );

      if (!analysis['can_analyze']) return;

      final action = analysis['action'] as Map<String, dynamic>;

      if (action['action'] == 'swap_immediately' ||
          action['action'] == 'swap') {
        toSwap.add(exerciseId);
      } else if (action['action'] == 'consider_swap') {
        toConsider.add(exerciseId);
      } else {
        working.add(exerciseId);
      }
    });

    return {
      'to_swap': toSwap,
      'to_consider': toConsider,
      'working_well': working,
      'total_analyzed': exerciseLogsByExercise.length,
    };
  }
}
