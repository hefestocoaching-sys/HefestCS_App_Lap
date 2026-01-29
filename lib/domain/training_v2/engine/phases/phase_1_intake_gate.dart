import 'dart:math';

import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

/// Nivel de readiness (alineado con Phase2 existente, pero sin dependencia a Phase2).
enum V2ReadinessLevel { critical, low, moderate, good, excellent }

/// Resultado de Capa 1.
/// IMPORTANTE: esta capa NO prescribe. Solo valida y emite caps/clamps iniciales.
class Phase1IntakeGateResult {
  final bool isBlocked;
  final String? blockedReason;
  final Map<String, dynamic> blockedDetails;

  /// 0..1
  final double readinessScore;

  /// Interpretación categórica
  final V2ReadinessLevel readinessLevel;

  /// Factor multiplicador de volumen (para capas posteriores). Rango típico: 0.70..1.10
  final double volumeAdjustmentFactor;

  /// Permiso base de intensificación (capas posteriores pueden restringir más).
  final bool allowIntensification;

  /// Guardrails base para el resto del motor (caps operativos).
  final V2SafetyCaps caps;

  final List<DecisionTrace> decisions;

  const Phase1IntakeGateResult({
    required this.isBlocked,
    required this.blockedReason,
    required this.blockedDetails,
    required this.readinessScore,
    required this.readinessLevel,
    required this.volumeAdjustmentFactor,
    required this.allowIntensification,
    required this.caps,
    required this.decisions,
  });

  factory Phase1IntakeGateResult.blocked({
    required String reason,
    Map<String, dynamic> details = const {},
    required DateTime ts,
    List<DecisionTrace> decisions = const [],
  }) {
    return Phase1IntakeGateResult(
      isBlocked: true,
      blockedReason: reason,
      blockedDetails: details,
      readinessScore: 0.0,
      readinessLevel: V2ReadinessLevel.critical,
      volumeAdjustmentFactor: 0.70,
      allowIntensification: false,
      caps: V2SafetyCaps.defaultCaps(),
      decisions: [
        ...decisions,
        DecisionTrace.critical(
          phase: 'Phase1IntakeGate',
          category: 'blocked',
          description: reason,
          context: details,
          timestamp: ts,
          action: 'Completar/ajustar datos críticos antes de generar plan.',
        ),
      ],
    );
  }
}

/// Caps iniciales (conservadores) para robustez del motor.
class V2SafetyCaps {
  /// Mínimo de ejercicios por día (guardrail estructural).
  final int minExercisesPerDay;

  /// Máximo “soft” de sets semanales por músculo (cap operativo; Phase3/2 afina).
  final int maxWeeklySetsPerMuscleSoft;

  /// Máximo de técnicas de intensificación por semana.
  final int maxIntensificationPerWeek;

  /// Límite de agresividad de progresión semanal (0.0..1.0)
  final double maxWeeklyProgression;

  const V2SafetyCaps({
    required this.minExercisesPerDay,
    required this.maxWeeklySetsPerMuscleSoft,
    required this.maxIntensificationPerWeek,
    required this.maxWeeklyProgression,
  });

  factory V2SafetyCaps.defaultCaps() {
    return const V2SafetyCaps(
      minExercisesPerDay: 4,
      maxWeeklySetsPerMuscleSoft: 24,
      maxIntensificationPerWeek: 2,
      maxWeeklyProgression: 0.08,
    );
  }

  V2SafetyCaps copyWith({
    int? minExercisesPerDay,
    int? maxWeeklySetsPerMuscleSoft,
    int? maxIntensificationPerWeek,
    double? maxWeeklyProgression,
  }) {
    return V2SafetyCaps(
      minExercisesPerDay: minExercisesPerDay ?? this.minExercisesPerDay,
      maxWeeklySetsPerMuscleSoft:
          maxWeeklySetsPerMuscleSoft ?? this.maxWeeklySetsPerMuscleSoft,
      maxIntensificationPerWeek:
          maxIntensificationPerWeek ?? this.maxIntensificationPerWeek,
      maxWeeklyProgression: maxWeeklyProgression ?? this.maxWeeklyProgression,
    );
  }
}

class Phase1IntakeGate {
  /// Ejecuta validación + normalización + scoring probabilístico.
  Phase1IntakeGateResult run({required TrainingContext ctx}) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    // 0) Validación básica (redundante con Builder, pero protege contra regresiones)
    final meta = ctx.meta;
    if (meta.daysPerWeek <= 0 ||
        meta.timePerSessionMinutes <= 0 ||
        meta.level == null) {
      return Phase1IntakeGateResult.blocked(
        reason:
            'Meta de entrenamiento inválida: daysPerWeek/timePerSession/level incompletos.',
        details: {
          'daysPerWeek': meta.daysPerWeek,
          'timePerSessionMinutes': meta.timePerSessionMinutes,
          'level': meta.level?.name,
        },
        ts: ts,
        decisions: decisions,
      );
    }

    // 1) Normalización defensiva (clamps) para evitar valores absurdos que rompen probabilidades.
    final normalized = _normalize(ctx, decisions);

    // 2) Scoring probabilístico determinista (no aleatorio)
    final readiness = _computeReadiness(normalized, decisions, ts);

    // 3) Convertir readinessScore -> readinessLevel
    final level = _mapReadinessLevel(readiness, decisions, ts);

    // 4) Factor de ajuste de volumen (conservador)
    final volumeFactor = _volumeFactor(level, readiness, decisions, ts);

    // 5) Permiso de intensificación: depende de readiness + energía + nivel
    final allowIntensification = _allowIntensification(
      normalized,
      level,
      readiness,
      decisions,
      ts,
    );

    // 6) Caps base (pueden ajustarse aquí con señales duras)
    var caps = V2SafetyCaps.defaultCaps();

    // En déficit alto → restringir agresividad y sets soft
    if (normalized.energyState == 'deficit' &&
        normalized.energyMagnitude >= 300) {
      caps = caps.copyWith(
        maxWeeklySetsPerMuscleSoft: 20,
        maxIntensificationPerWeek: 1,
        maxWeeklyProgression: 0.05,
      );
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1IntakeGate',
          category: 'energy_cap',
          description:
              'Déficit energético alto detectado: caps más conservadores.',
          context: {
            'energyState': normalized.energyState,
            'energyMagnitude': normalized.energyMagnitude,
            'maxWeeklySetsPerMuscleSoft': caps.maxWeeklySetsPerMuscleSoft,
            'maxIntensificationPerWeek': caps.maxIntensificationPerWeek,
            'maxWeeklyProgression': caps.maxWeeklyProgression,
          },
          timestamp: ts,
          action: 'Reducir densidad/volumen e intensificación.',
        ),
      );
    }

    // Lesiones activas → desactivar intensificación y conservadurismo extra
    if (normalized.activeInjuries.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1IntakeGate',
          category: 'injury_cap',
          description:
              'Lesiones activas presentes: intensificación deshabilitada.',
          context: {'activeInjuries': normalized.activeInjuries},
          timestamp: ts,
          action:
              'Evitar técnicas de intensificación y priorizar variantes seguras.',
        ),
      );
    }

    // 7) Resultado final
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1IntakeGate',
        category: 'final',
        description:
            'Readiness ${(readiness * 100).toStringAsFixed(1)}% → ${level.name}; '
            'volumeFactor ${(volumeFactor * 100).toStringAsFixed(0)}%; '
            'allowIntensification=$allowIntensification',
        context: {
          'readinessScore': readiness,
          'readinessLevel': level.name,
          'volumeAdjustmentFactor': volumeFactor,
          'allowIntensification': allowIntensification,
          'caps': {
            'minExercisesPerDay': caps.minExercisesPerDay,
            'maxWeeklySetsPerMuscleSoft': caps.maxWeeklySetsPerMuscleSoft,
            'maxIntensificationPerWeek': caps.maxIntensificationPerWeek,
            'maxWeeklyProgression': caps.maxWeeklyProgression,
          },
        },
        timestamp: ts,
      ),
    );

    return Phase1IntakeGateResult(
      isBlocked: false,
      blockedReason: null,
      blockedDetails: const {},
      readinessScore: readiness,
      readinessLevel: level,
      volumeAdjustmentFactor: volumeFactor,
      allowIntensification:
          allowIntensification && normalized.activeInjuries.isEmpty,
      caps: caps,
      decisions: decisions,
    );
  }

  _NormalizedSignals _normalize(
    TrainingContext ctx,
    List<DecisionTrace> decisions,
  ) {
    // Clamps defensivos
    final sleep = _clampDouble(ctx.interview.avgSleepHours, 0.0, 12.0);
    final years = _clampInt(ctx.interview.yearsTrainingContinuous, 0, 50);
    final sessionMin = _clampInt(ctx.meta.timePerSessionMinutes, 20, 240);
    final restSec = _clampInt(ctx.interview.restBetweenSetsSeconds, 30, 300);

    final workCap = _clampInt(ctx.interview.workCapacity, 1, 5);
    final recovery = _clampInt(ctx.interview.recoveryHistory, 1, 5);

    final energyState = ctx.energy.state;
    final energyMag = _clampInt(ctx.energy.magnitude, 0, 2000);

    final activeInjuries = ctx.constraints.activeInjuries;

    // Emit warnings si hubo clamps relevantes
    if (ctx.interview.avgSleepHours != sleep) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1IntakeGate',
          category: 'normalize_sleep',
          description: 'avgSleepHours fuera de rango; se aplicó clamp.',
          context: {'raw': ctx.interview.avgSleepHours, 'clamped': sleep},
          timestamp: ctx.asOfDate,
        ),
      );
    }
    if (ctx.interview.restBetweenSetsSeconds != restSec) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1IntakeGate',
          category: 'normalize_rest',
          description:
              'restBetweenSetsSeconds fuera de rango; se aplicó clamp.',
          context: {
            'raw': ctx.interview.restBetweenSetsSeconds,
            'clamped': restSec,
          },
          timestamp: ctx.asOfDate,
        ),
      );
    }

    return _NormalizedSignals(
      sleepHours: sleep,
      yearsTrainingContinuous: years,
      timePerSessionMinutes: sessionMin,
      restBetweenSetsSeconds: restSec,
      workCapacity: workCap,
      recoveryHistory: recovery,
      energyState: energyState,
      energyMagnitude: energyMag,
      activeInjuries: activeInjuries,
      trainingLevelName: ctx.meta.level!.name,
    );
  }

  double _computeReadiness(
    _NormalizedSignals s,
    List<DecisionTrace> decisions,
    DateTime ts,
  ) {
    // Modelo probabilístico simple (determinista):
    // readiness = sigmoid( w0 + w_sleep + w_workcap + w_recovery - w_deficit - w_injury )
    //
    // Nota: no hay azar; es estadística paramétrica interpretable.
    final base = _baselineByLevel(s.trainingLevelName);

    final sleepTerm = _mapSleepToTerm(s.sleepHours); // 0..1
    final workTerm = (s.workCapacity - 1) / 4.0; // 0..1
    final recTerm = (s.recoveryHistory - 1) / 4.0; // 0..1

    final deficitPenalty = _energyPenalty(
      s.energyState,
      s.energyMagnitude,
    ); // 0..1
    final injuryPenalty = s.activeInjuries.isNotEmpty ? 0.25 : 0.0;

    // lineal interpretable
    final z =
        (base * 1.20) +
        (sleepTerm * 0.90) +
        (workTerm * 0.55) +
        (recTerm * 0.55) -
        (deficitPenalty * 0.80) -
        injuryPenalty;

    final readiness = _sigmoid(z);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1IntakeGate',
        category: 'readiness_model',
        description:
            'Modelo readiness aplicado (sigmoid lineal interpretable).',
        context: {
          'baseByLevel': base,
          'sleepTerm': sleepTerm,
          'workTerm': workTerm,
          'recoveryTerm': recTerm,
          'deficitPenalty': deficitPenalty,
          'injuryPenalty': injuryPenalty,
          'z': z,
          'readiness': readiness,
        },
        timestamp: ts,
      ),
    );

    return _clampDouble(readiness, 0.0, 1.0);
  }

  V2ReadinessLevel _mapReadinessLevel(
    double readiness,
    List<DecisionTrace> decisions,
    DateTime ts,
  ) {
    // thresholds conservadores
    final lvl = readiness < 0.30
        ? V2ReadinessLevel.critical
        : (readiness < 0.45
              ? V2ReadinessLevel.low
              : (readiness < 0.62
                    ? V2ReadinessLevel.moderate
                    : (readiness < 0.80
                          ? V2ReadinessLevel.good
                          : V2ReadinessLevel.excellent)));

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1IntakeGate',
        category: 'readiness_level',
        description: 'ReadinessLevel derivado desde readinessScore.',
        context: {'readiness': readiness, 'level': lvl.name},
        timestamp: ts,
      ),
    );

    return lvl;
  }

  double _volumeFactor(
    V2ReadinessLevel level,
    double readiness,
    List<DecisionTrace> decisions,
    DateTime ts,
  ) {
    // output: 0.70..1.10 (conservador)
    double factor;
    switch (level) {
      case V2ReadinessLevel.critical:
        factor = 0.70;
        break;
      case V2ReadinessLevel.low:
        factor = 0.80;
        break;
      case V2ReadinessLevel.moderate:
        factor = 0.92;
        break;
      case V2ReadinessLevel.good:
        factor = 1.00;
        break;
      case V2ReadinessLevel.excellent:
        factor = 1.08;
        break;
    }

    // micro-ajuste suave por score
    // (evita saltos bruscos)
    factor += (readiness - 0.62) * 0.05;
    factor = _clampDouble(factor, 0.70, 1.10);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1IntakeGate',
        category: 'volume_factor',
        description: 'volumeAdjustmentFactor calculado.',
        context: {
          'readiness': readiness,
          'factor': factor,
          'level': level.name,
        },
        timestamp: ts,
      ),
    );

    return factor;
  }

  bool _allowIntensification(
    _NormalizedSignals s,
    V2ReadinessLevel level,
    double readiness,
    List<DecisionTrace> decisions,
    DateTime ts,
  ) {
    // Política:
    // - solo good/excellent
    // - no si déficit alto
    // - no si lesiones
    // - readiness >= 0.65
    final deficitHard = s.energyState == 'deficit' && s.energyMagnitude >= 300;

    final allowed =
        (level == V2ReadinessLevel.good ||
            level == V2ReadinessLevel.excellent) &&
        readiness >= 0.65 &&
        !deficitHard &&
        s.activeInjuries.isEmpty;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1IntakeGate',
        category: 'allow_intensification',
        description: 'Permiso base de intensificación evaluado.',
        context: {
          'readiness': readiness,
          'level': level.name,
          'deficitHard': deficitHard,
          'activeInjuries': s.activeInjuries,
          'allowed': allowed,
        },
        timestamp: ts,
      ),
    );

    return allowed;
  }

  // -------- Helpers --------

  double _baselineByLevel(String levelName) {
    // Baseline prior: novato suele tener más recuperación “nueva” pero menos tolerancia técnica.
    // Esto no es "mejor"; es prior para readiness general.
    switch (levelName.toLowerCase()) {
      case 'beginner':
        return 0.55;
      case 'intermediate':
        return 0.52;
      case 'advanced':
        return 0.48;
      default:
        return 0.52;
    }
  }

  double _mapSleepToTerm(double sleepHours) {
    // 0..1; óptimo 7-9h
    if (sleepHours <= 4.0) return 0.15;
    if (sleepHours <= 6.0) return 0.45;
    if (sleepHours <= 7.0) return 0.70;
    if (sleepHours <= 9.0) return 0.90;
    if (sleepHours <= 10.0) return 0.78;
    return 0.65;
  }

  double _energyPenalty(String state, int magnitude) {
    if (state != 'deficit') return 0.0;
    if (magnitude < 150) return 0.15;
    if (magnitude < 300) return 0.30;
    if (magnitude < 500) return 0.45;
    return 0.60;
  }

  double _sigmoid(double z) => 1.0 / (1.0 + exp(-z));

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
  double _clampDouble(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}

class _NormalizedSignals {
  final double sleepHours;
  final int yearsTrainingContinuous;
  final int timePerSessionMinutes;
  final int restBetweenSetsSeconds;

  final int workCapacity;
  final int recoveryHistory;

  final String energyState;
  final int energyMagnitude;

  final List<String> activeInjuries;

  final String trainingLevelName;

  _NormalizedSignals({
    required this.sleepHours,
    required this.yearsTrainingContinuous,
    required this.timePerSessionMinutes,
    required this.restBetweenSetsSeconds,
    required this.workCapacity,
    required this.recoveryHistory,
    required this.energyState,
    required this.energyMagnitude,
    required this.activeInjuries,
    required this.trainingLevelName,
  });
}
