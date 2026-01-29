// ignore_for_file: deprecated_member_use_from_same_package
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';

/// Resultado de la Fase 1: Ingestión y validación de datos
class Phase1Result {
  final TrainingProfile profile;
  final TrainingHistory? history;
  final TrainingFeedback? latestFeedback;
  final List<DecisionTrace> decisions;
  final DerivedTrainingContext derivedContext;
  final bool isValid;
  final List<String> missingData;
  final List<String> warnings;
  final ManualOverride? manualOverride;

  const Phase1Result({
    required this.profile,
    this.history,
    this.latestFeedback,
    required this.decisions,
    required this.derivedContext,
    required this.isValid,
    this.missingData = const [],
    this.warnings = const [],
    this.manualOverride,
  });

  bool get hasHistory => history != null && history!.hasData;
  bool get hasFeedback => latestFeedback != null;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalIssues => !isValid || missingData.isNotEmpty;
}

/// Fase 1: Ingestión y validación de datos del perfil de entrenamiento.
///
/// Responsabilidades:
/// - Validar que los datos mínimos estén presentes
/// - Normalizar valores (ej: valores nulos a defaults conservadores)
/// - Detectar inconsistencias o datos faltantes
/// - Registrar todas las decisiones en DecisionTrace
///
/// REGLA DE ORO: Si faltan datos → asumir valores conservadores.
class Phase1DataIngestionService {
  /// Valida e ingesta el perfil de entrenamiento junto con datos históricos
  Phase1Result ingestAndValidate({
    required TrainingProfile profile,
    TrainingHistory? history,
    TrainingFeedback? latestFeedback,
    Map<String, dynamic>? manualOverridesRaw,
    DateTime? referenceDate,
  }) {
    final decisions = <DecisionTrace>[];
    final warnings = <String>[];
    final missingData = <String>[];

    // Fecha de referencia para determinismo temporal (no usar DateTime.now())
    final effectiveReferenceDate =
        referenceDate ??
        (profile.date ?? DateTime(2025, 1, 1)); // Fallback conservador

    // 0. Validar overrides manuales si existen
    ManualOverride? override;
    if (manualOverridesRaw != null) {
      override = ManualOverride.fromMap(manualOverridesRaw);
      final overrideWarnings = override.validate();
      warnings.addAll(overrideWarnings);

      if (override.hasAnyOverride) {
        decisions.add(
          DecisionTrace.info(
            phase: 'manual_override',
            category: 'override_detected',
            description: 'Overrides manuales del coach detectados y validados',
            context: {
              'volumeOverrides': override.volumeOverrides?.keys.toList(),
              'priorityOverrides': override.priorityOverrides?.keys.toList(),
              'rirTargetOverride': override.rirTargetOverride,
              'allowIntensification': override.allowIntensification,
              'intensificationMaxPerWeek': override.intensificationMaxPerWeek,
              'validationWarnings': overrideWarnings.length,
            },
            action: 'Overrides serán aplicados en fases 3, 4, 5, 7',
          ),
        );
      }
    } else {
      override = const ManualOverride();
    }

    // 1. Validar datos críticos del perfil
    if (!profile.isValid) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'Phase1DataIngestion',
          category: 'profile_validation',
          description:
              'Perfil inválido: daysPerWeek=${profile.daysPerWeek}, '
              'timePerSessionMinutes=${profile.timePerSessionMinutes}',
          context: {
            'daysPerWeek': profile.daysPerWeek,
            'timePerSessionMinutes': profile.timePerSessionMinutes,
          },
          action: 'No se puede generar plan sin días y tiempo por sesión',
        ),
      );
      missingData.add('daysPerWeek o timePerSessionMinutes');
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'profile_validation',
          description:
              'Perfil válido: ${profile.daysPerWeek} días/semana, '
              '${profile.timePerSessionMinutes} min/sesión',
        ),
      );
    }

    // 2. Validar nivel de entrenamiento
    if (profile.trainingLevel == null) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'missing_data',
          description: 'Nivel de entrenamiento no especificado',
          action: 'Se asumirá nivel principiante (conservador)',
        ),
      );
      warnings.add('Nivel de entrenamiento no especificado');
      missingData.add('trainingLevel');
    }

    // 3. Validar objetivo de entrenamiento
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestion',
        category: 'goal_analysis',
        description: 'Objetivo global: ${profile.globalGoal.name}',
        context: {
          'goal': profile.globalGoal.name,
          'focus': profile.trainingFocus?.name ?? 'no especificado',
        },
      ),
    );

    // 4. Validar datos de recuperación
    _validateRecoveryData(profile, decisions, warnings, missingData);

    // 5. Validar prioridades musculares
    _validateMusclePriorities(profile, decisions, warnings);

    // 6. Validar volumen base
    _validateBaseVolume(profile, decisions, warnings);

    // 7. Validar historial si existe
    if (history != null && history.hasData) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'history_analysis',
          description:
              'Historial disponible: ${history.totalSessions} sesiones, '
              'adherencia promedio ${(history.averageAdherence * 100).toStringAsFixed(1)}%',
          context: {
            'totalSessions': history.totalSessions,
            'completedSessions': history.completedSessions,
            'averageAdherence': history.averageAdherence,
            'averageRpe': history.averageRpe,
          },
        ),
      );

      // Verificar adherencia baja
      if (history.averageAdherence < 0.7) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase1DataIngestion',
            category: 'adherence_low',
            description:
                'Adherencia histórica baja (${(history.averageAdherence * 100).toStringAsFixed(1)}%)',
            action: 'Considerar plan más flexible o reducir volumen',
          ),
        );
        warnings.add('Adherencia histórica baja');
      }
    } else {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'missing_data',
          description: 'No hay historial de entrenamiento disponible',
          action: 'Se usarán valores conservadores sin referencia histórica',
        ),
      );
      warnings.add('Sin historial de entrenamiento');
    }

    // 8. Validar feedback reciente
    if (latestFeedback != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'feedback_analysis',
          description:
              'Feedback disponible: fatiga=${latestFeedback.fatigue.toStringAsFixed(1)}, '
              'adherencia=${(latestFeedback.adherence * 100).toStringAsFixed(1)}%',
          context: {
            'fatigue': latestFeedback.fatigue,
            'soreness': latestFeedback.soreness,
            'motivation': latestFeedback.motivation,
            'adherence': latestFeedback.adherence,
            'sleepHours': latestFeedback.sleepHours,
            'stressLevel': latestFeedback.stressLevel,
          },
        ),
      );
    } else {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'missing_data',
          description: 'No hay feedback reciente disponible',
          action: 'Se asumirán valores neutros para recuperación',
        ),
      );
      warnings.add('Sin feedback reciente');
    }

    // 9. Validar farmacología (importante para ajustes de volumen)
    if (profile.usesAnabolics) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'pharmacology',
          description: 'Cliente usa farmacología anabólica',
          context: {
            'protocol': profile.pharmacologyProtocol ?? 'no especificado',
          },
          action: 'Se aplicarán ajustes de volumen (+10-15% MRV)',
        ),
      );
    }

    // Derivar contexto reusable para fases 2-8 (no persistente)
    final derivedContext = _buildDerivedContext(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      decisions: decisions,
      referenceDate: effectiveReferenceDate,
    );

    // 10. Decisión final de validación
    final isValid = profile.isValid && missingData.isEmpty;

    if (!isValid) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'Phase1DataIngestion',
          category: 'validation_result',
          description:
              'Validación fallida: ${missingData.length} campos críticos faltantes',
          context: {'missingData': missingData},
          action: 'Requiere completar datos antes de generar plan',
        ),
      );
    } else if (warnings.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'validation_result',
          description:
              'Validación con advertencias: ${warnings.length} puntos de atención',
          context: {'warnings': warnings},
          action: 'Se procederá con valores conservadores',
        ),
      );
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'validation_result',
          description:
              'Validación exitosa: todos los datos necesarios presentes',
        ),
      );
    }

    return Phase1Result(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      decisions: decisions,
      derivedContext: derivedContext,
      isValid: isValid,
      missingData: missingData,
      warnings: warnings,
      manualOverride: override,
    );
  }

  DerivedTrainingContext _buildDerivedContext({
    required TrainingProfile profile,
    required TrainingHistory? history,
    required TrainingFeedback? latestFeedback,
    required List<DecisionTrace> decisions,
    required DateTime referenceDate,
  }) {
    final extra = profile.extra;

    // 1) Materializar datos de entrevista
    final interviewInjuries = extra[TrainingExtraKeys.injuries];
    final interviewPreferences = extra[TrainingExtraKeys.trainingPreferences];
    final interviewBarriers = extra[TrainingExtraKeys.barriers];
    final gluteSpecRaw = extra[TrainingExtraKeys.gluteSpecializationProfile];
    final logsRaw = extra[TrainingExtraKeys.trainingSessionLogRecords];
    final logs = readTrainingSessionLogs(logsRaw);

    final contraindicatedPatterns = <String>{};
    _parseInjuries(interviewInjuries, contraindicatedPatterns);

    final exerciseMustHave = <String>{};
    final exerciseDislikes = <String>{};
    final intensification = _parsePreferences(
      interviewPreferences,
      exerciseMustHave,
      exerciseDislikes,
    );

    final gluteSpec = _parseGluteSpec(gluteSpecRaw);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestion',
        category: 'interview_parsed',
        description:
            'Entrevista materializada (lesiones, preferencias, barreras)',
        context: {
          'injuriesType': interviewInjuries.runtimeType.toString(),
          'preferencesType': interviewPreferences.runtimeType.toString(),
          'barriersType': interviewBarriers.runtimeType.toString(),
        },
      ),
    );

    // 2) Derivar métricas efectivas
    final effectiveSleep = latestFeedback?.sleepHours ?? profile.avgSleepHours;

    double? effectiveAdherence;
    if (history != null && history.hasData) {
      effectiveAdherence = history.averageAdherence;
    } else if (logs.isNotEmpty) {
      final expected = profile.daysPerWeek > 0 ? profile.daysPerWeek : 1;
      final ratio = logs.length / expected;
      effectiveAdherence = ratio.clamp(0.0, 1.0);
    }

    double? effectiveAvgRir;
    if (latestFeedback?.avgRir != null) {
      effectiveAvgRir = latestFeedback!.avgRir;
    } else {
      final allRpe = <double>[];
      for (final log in logs) {
        for (final entry in log.entries) {
          if (entry.rpe != null && entry.rpe!.isNotEmpty) {
            allRpe.addAll(entry.rpe!.whereType<double>());
          }
        }
      }
      if (allRpe.isNotEmpty) {
        final meanRpe = allRpe.reduce((a, b) => a + b) / allRpe.length;
        effectiveAvgRir = (10 - meanRpe).clamp(0.0, 5.0);
      }
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestion',
        category: 'derived_metrics',
        description: 'Métricas efectivas derivadas',
        context: {
          'effectiveSleepHours': effectiveSleep,
          'effectiveAdherence': effectiveAdherence,
          'effectiveAvgRir': effectiveAvgRir,
        },
      ),
    );

    if (contraindicatedPatterns.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'injury_constraints',
          description:
              'Patrones contraindicados por lesiones: ${contraindicatedPatterns.join(', ')}',
          context: {
            'contraindicatedPatterns': contraindicatedPatterns.toList(),
          },
        ),
      );
    }

    if (gluteSpec != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'glute_specialization_detected',
          description: 'Perfil de especialización de glúteo detectado',
          context: gluteSpec.toJson(),
        ),
      );
    }

    return DerivedTrainingContext(
      effectiveSleepHours: effectiveSleep,
      effectiveAdherence: effectiveAdherence,
      effectiveAvgRir: effectiveAvgRir,
      contraindicatedPatterns: contraindicatedPatterns,
      exerciseMustHave: exerciseMustHave,
      exerciseDislikes: exerciseDislikes,
      intensificationAllowed: intensification.allowed,
      intensificationMaxPerSession: intensification.maxPerSession,
      gluteSpecialization: gluteSpec,
      referenceDate: referenceDate,
    );
  }

  void _parseInjuries(dynamic injuries, Set<String> contraindicatedPatterns) {
    if (injuries is List) {
      for (final item in injuries) {
        if (item is Map) {
          final pattern = item['pattern']?.toString();
          final severity = _parseDouble(item['severity']);
          if (pattern != null && pattern.isNotEmpty && severity >= 3) {
            contraindicatedPatterns.add(pattern);
          }
        } else if (item != null) {
          final text = item.toString();
          if (text.isNotEmpty) {
            contraindicatedPatterns.add(text);
          }
        }
      }
    } else if (injuries is Map) {
      final severity = _parseDouble(injuries['severity']);
      final pattern = injuries['pattern']?.toString();
      if (pattern != null && pattern.isNotEmpty && severity >= 3) {
        contraindicatedPatterns.add(pattern);
      }
    } else if (injuries is String && injuries.isNotEmpty) {
      contraindicatedPatterns.add(injuries);
    }
  }

  _IntensificationPref _parsePreferences(
    dynamic preferences,
    Set<String> mustHave,
    Set<String> dislikes,
  ) {
    var allowed = true;
    var maxPerSession = 1;

    if (preferences is Map) {
      final mustRaw = preferences['mustHave'];
      final dislikeRaw = preferences['dislikes'];
      if (mustRaw is List) {
        mustHave.addAll(
          mustRaw.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
      }
      if (dislikeRaw is List) {
        dislikes.addAll(
          dislikeRaw.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
      }
      if (preferences['intensificationAllowed'] is bool) {
        allowed = preferences['intensificationAllowed'] as bool;
      }
      if (preferences['intensificationMaxPerSession'] is num) {
        maxPerSession = (preferences['intensificationMaxPerSession'] as num)
            .toInt();
      }
    } else if (preferences is String && preferences.isNotEmpty) {
      final lower = preferences.toLowerCase();
      if (lower.contains('sin intensificacion')) {
        allowed = false;
      }
      final mustIndex = lower.indexOf('must:');
      if (mustIndex != -1) {
        final part = preferences.substring(mustIndex + 5);
        mustHave.addAll(
          part.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
      final avoidIndex = lower.indexOf('avoid:');
      if (avoidIndex != -1) {
        final part = preferences.substring(avoidIndex + 6);
        dislikes.addAll(
          part.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
    }

    return _IntensificationPref(allowed: allowed, maxPerSession: maxPerSession);
  }

  GluteSpecializationContext? _parseGluteSpec(dynamic raw) {
    if (raw is! Map) return null;
    final freq = (raw['targetFrequencyPerWeek'] ?? raw['frequency']) as num?;
    final minSets = raw['minSetsPerWeek'] as num?;
    final maxSets = raw['maxSetsPerWeek'] as num?;
    if (freq == null && minSets == null && maxSets == null) return null;
    return GluteSpecializationContext(
      targetFrequencyPerWeek: freq?.toInt(),
      minSetsPerWeek: minSets?.toInt(),
      maxSetsPerWeek: maxSets?.toInt(),
    );
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  void _validateRecoveryData(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
    List<String> warnings,
    List<String> missingData,
  ) {
    // Validar sueño
    if (profile.avgSleepHours < 6.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'recovery_concern',
          description: 'Sueño insuficiente (${profile.avgSleepHours}h < 6h)',
          action: 'Reducir volumen por mala recuperación',
        ),
      );
      warnings.add('Sueño insuficiente');
    }

    // Validar estrés
    if (profile.perceivedStress != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'recovery_data',
          description: 'Estrés percibido: ${profile.perceivedStress}',
        ),
      );
    }

    // Validar dolor muscular
    if (profile.sorenessLevel != null && profile.sorenessLevel! > 7.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'recovery_concern',
          description:
              'Nivel de dolor muscular alto (${profile.sorenessLevel}/10)',
          action: 'Considerar fase de deload o reducción de volumen',
        ),
      );
      warnings.add('DOMS alto');
    }

    // Validar motivación
    if (profile.motivationLevel != null && profile.motivationLevel! < 5.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'psychological_concern',
          description: 'Motivación baja (${profile.motivationLevel}/10)',
          action: 'Considerar plan más variado o reducir frecuencia',
        ),
      );
      warnings.add('Motivación baja');
    }
  }

  void _validateMusclePriorities(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
    List<String> warnings,
  ) {
    final totalPriorities =
        profile.priorityMusclesPrimary.length +
        profile.priorityMusclesSecondary.length +
        profile.priorityMusclesTertiary.length;

    if (totalPriorities == 0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'muscle_priorities',
          description: 'No se especificaron prioridades musculares',
          action: 'Se usará enfoque balanceado (full-body)',
        ),
      );
      warnings.add('Sin prioridades musculares');
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'muscle_priorities',
          description:
              'Prioridades definidas: '
              '${profile.priorityMusclesPrimary.length} primarias, '
              '${profile.priorityMusclesSecondary.length} secundarias, '
              '${profile.priorityMusclesTertiary.length} terciarias',
          context: {
            'primary': profile.priorityMusclesPrimary,
            'secondary': profile.priorityMusclesSecondary,
            'tertiary': profile.priorityMusclesTertiary,
          },
        ),
      );
    }

    // Advertir si hay demasiadas prioridades primarias
    if (profile.priorityMusclesPrimary.length > 4) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'muscle_priorities',
          description:
              'Demasiadas prioridades primarias (${profile.priorityMusclesPrimary.length} > 4)',
          action: 'Difícil distribuir volumen efectivo entre tantos grupos',
        ),
      );
      warnings.add('Demasiadas prioridades primarias');
    }
  }

  void _validateBaseVolume(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
    List<String> warnings,
  ) {
    if (profile.baseVolumePerMuscle.isEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'volume_config',
          description: 'No se especificó volumen base por músculo',
          action: 'Se calcularán valores basados en nivel y objetivo',
        ),
      );
      warnings.add('Sin volumen base configurado');
    } else {
      final totalWeeklyVolume = profile.baseVolumePerMuscle.values.fold<int>(
        0,
        (sum, vol) => sum + vol,
      );

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'volume_config',
          description: 'Volumen base total: $totalWeeklyVolume series/semana',
          context: {
            'volumePerMuscle': profile.baseVolumePerMuscle,
            'totalVolume': totalWeeklyVolume,
          },
        ),
      );

      // Verificar si el volumen parece excesivo para el tiempo disponible
      final minutesPerWeek =
          profile.daysPerWeek * profile.timePerSessionMinutes;
      final estimatedMinutesNeeded = totalWeeklyVolume * 4; // ~4 min por serie

      if (estimatedMinutesNeeded > minutesPerWeek * 1.2) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase1DataIngestion',
            category: 'time_constraint',
            description:
                'Volumen base requiere más tiempo del disponible '
                '(~$estimatedMinutesNeeded min vs $minutesPerWeek min)',
            action: 'Se ajustará volumen al tiempo disponible',
          ),
        );
        warnings.add('Volumen excede tiempo disponible');
      }
    }
  }
}

/// Contexto derivado NO persistente, construido en Fase 1 y pasado a fases 2-8.
class DerivedTrainingContext {
  final double effectiveSleepHours;
  final double? effectiveAdherence;
  final double? effectiveAvgRir;
  final Set<String> contraindicatedPatterns;
  final Set<String> exerciseMustHave;
  final Set<String> exerciseDislikes;
  final bool intensificationAllowed;
  final int intensificationMaxPerSession;
  final GluteSpecializationContext? gluteSpecialization;

  /// Fecha de referencia para determinismo temporal.
  /// NO debe usar DateTime.now(), sino derivarse del inicio del plan o semana actual.
  final DateTime referenceDate;

  const DerivedTrainingContext({
    required this.effectiveSleepHours,
    required this.effectiveAdherence,
    required this.effectiveAvgRir,
    required this.contraindicatedPatterns,
    required this.exerciseMustHave,
    required this.exerciseDislikes,
    required this.intensificationAllowed,
    required this.intensificationMaxPerSession,
    required this.gluteSpecialization,
    required this.referenceDate,
  });
}

/// Perfil de especialización de glúteo (opcional).
class GluteSpecializationContext {
  final int? targetFrequencyPerWeek;
  final int? minSetsPerWeek;
  final int? maxSetsPerWeek;

  const GluteSpecializationContext({
    this.targetFrequencyPerWeek,
    this.minSetsPerWeek,
    this.maxSetsPerWeek,
  });

  Map<String, dynamic> toJson() => {
    'targetFrequencyPerWeek': targetFrequencyPerWeek,
    'minSetsPerWeek': minSetsPerWeek,
    'maxSetsPerWeek': maxSetsPerWeek,
  };
}

/// Helper interno para parseo de preferencias de intensificación.
class _IntensificationPref {
  final bool allowed;
  final int maxPerSession;

  const _IntensificationPref({
    required this.allowed,
    required this.maxPerSession,
  });
}
