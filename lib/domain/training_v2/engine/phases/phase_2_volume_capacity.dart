import 'dart:math';

import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

class V2VolumeCapacity extends DecisionTraceCapable {
  final int mev;
  final int mrv;
  final int mav;

  const V2VolumeCapacity({
    required this.mev,
    required this.mrv,
    required this.mav,
  }) : super();

  Map<String, dynamic> toJson() => {'mev': mev, 'mrv': mrv, 'mav': mav};

  @override
  Map<String, dynamic> traceContext() => toJson();
}

/// Resultado de Capa 2.
class Phase2VolumeCapacityResult {
  final Map<String, V2VolumeCapacity> capacityByMuscle;
  final List<DecisionTrace> decisions;

  const Phase2VolumeCapacityResult({
    required this.capacityByMuscle,
    required this.decisions,
  });
}

/// Capa 2: estima rangos MEV/MRV por músculo.
/// Modelo: prior por nivel + penalizaciones por energía/readiness + posterior local si existe.
class Phase2VolumeCapacity {
  /// Canon mínimo de músculos: delegado a MuscleRegistry (SSOT)
  static final List<String> _canonicalMuscles = muscle_registry.canonicalMuscles
      .toList();

  Phase2VolumeCapacityResult run({
    required TrainingContext ctx,
    required double readinessScore,
    required int maxWeeklySetsSoftCap,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    // 1) Universo de músculos = canon + prioridades (normalizado: trim)
    final muscles = <String>{
      ..._canonicalMuscles.map((e) => e.trim()),
      ...ctx.priorities.primary.map((e) => e.trim()),
      ...ctx.priorities.secondary.map((e) => e.trim()),
      ...ctx.priorities.tertiary.map((e) => e.trim()),
    }..removeWhere((e) => e.isEmpty);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase2VolumeCapacity',
        category: 'muscle_universe',
        description: 'Universo de músculos construido (canon + prioridades).',
        context: {'count': muscles.length, 'muscles': muscles.toList()},
        timestamp: ts,
      ),
    );

    // 2) Penalizaciones globales por energía/readiness/lesiones (aplican a todos)
    final deficitPenalty = _deficitPenalty(
      ctx.energy.state,
      ctx.energy.magnitude,
    ); // 0..0.20
    final readinessPenalty = _readinessPenalty(readinessScore); // 0..0.20
    final injuryPenalty = ctx.constraints.activeInjuries.isNotEmpty
        ? 0.10
        : 0.0;

    // Factor multiplicativo para MRV (conservador).
    // Ej: déficit fuerte + readiness bajo → MRV baja.
    final mrvFactor = _clampDouble(
      1.0 - deficitPenalty - readinessPenalty - injuryPenalty,
      0.70,
      1.00,
    );

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase2VolumeCapacity',
        category: 'global_penalties',
        description:
            'Penalizaciones globales aplicadas a MRV por energía/readiness/lesión.',
        context: {
          'energyState': ctx.energy.state,
          'energyMagnitude': ctx.energy.magnitude,
          'deficitPenalty': deficitPenalty,
          'readinessScore': readinessScore,
          'readinessPenalty': readinessPenalty,
          'injuryPenalty': injuryPenalty,
          'mrvFactor': mrvFactor,
        },
        timestamp: ts,
      ),
    );

    // 3) Priors por nivel (sets/semana por músculo) -> base MEV/MRV
    final levelName = ctx.meta.level!.name.toLowerCase();
    final prior = _priorByLevel(levelName);

    // 4) Posterior local (aprendizaje por cliente), si existe
    final posteriorByMuscle = _safePosterior(ctx.longitudinal);

    final out = <String, V2VolumeCapacity>{};

    for (final muscle in muscles) {
      // Base prior
      var baseMev = prior.baseMev;
      var baseMrv = prior.baseMrv;

      // Ajustes por músculo (prioridades elevan techo ligeramente, sin romper caps)
      final priorityBoost = _priorityBoost(muscle, ctx);
      baseMrv += priorityBoost;
      baseMev += (priorityBoost >= 2 ? 1 : 0);

      // Posterior local si existe: mezcla conservadora (no reemplaza brutalmente)
      final posterior = posteriorByMuscle[muscle];
      if (posterior != null) {
        final postMev = _clampInt(posterior.mevMean.round(), 4, 24);
        final postMrv = _clampInt(posterior.mrvMean.round(), 6, 30);

        // Blend: 70% posterior, 30% prior (si hay datos, confiamos más en el cliente).
        baseMev = _blendInt(baseMev, postMev, 0.70);
        baseMrv = _blendInt(baseMrv, postMrv, 0.70);

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase2VolumeCapacity',
            category: 'local_posterior_applied',
            description: 'Posterior local aplicado (blend) para músculo.',
            context: {
              'muscle': muscle,
              'priorMev': prior.baseMev,
              'priorMrv': prior.baseMrv,
              'postMev': postMev,
              'postMrv': postMrv,
              'blendedMev': baseMev,
              'blendedMrv': baseMrv,
            },
            timestamp: ts,
          ),
        );
      }

      // Aplicar factor global a MRV (y suavemente a MEV)
      var mrv = _clampInt(
        (baseMrv * mrvFactor).round(),
        6,
        maxWeeklySetsSoftCap,
      );
      var mev = _clampInt(
        (baseMev * (0.95 + (mrvFactor - 1.0).abs() * -0.10)).round(),
        4,
        max(4, mrv - 2),
      );

      // Asegurar coherencia MEV <= MRV-2
      if (mev > mrv - 2) {
        mev = max(4, mrv - 2);
      }

      // MAV = punto medio conservador (capas posteriores eligen percentil)
      final mav = max(mev, min(mrv, ((mev + mrv) / 2).round()));

      // Clamp final duro
      final cap = V2VolumeCapacity(mev: mev, mrv: mrv, mav: mav);
      out[muscle] = cap;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase2VolumeCapacity',
          category: 'capacity_final',
          description: 'MEV/MAV/MRV final para músculo.',
          context: {
            'muscle': muscle,
            'mev': mev,
            'mav': mav,
            'mrv': mrv,
            'priorityBoost': priorityBoost,
            'mrvFactor': mrvFactor,
          },
          timestamp: ts,
        ),
      );
    }

    return Phase2VolumeCapacityResult(
      capacityByMuscle: out,
      decisions: decisions,
    );
  }

  // ---------------- helpers ----------------

  _LevelPrior _priorByLevel(String levelName) {
    switch (levelName) {
      case 'beginner':
        return const _LevelPrior(baseMev: 6, baseMrv: 14);
      case 'intermediate':
        return const _LevelPrior(baseMev: 8, baseMrv: 18);
      case 'advanced':
        return const _LevelPrior(baseMev: 10, baseMrv: 22);
      default:
        return const _LevelPrior(baseMev: 8, baseMrv: 18);
    }
  }

  int _priorityBoost(String muscle, TrainingContext ctx) {
    if (ctx.priorities.primary.contains(muscle)) return 3;
    if (ctx.priorities.secondary.contains(muscle)) return 2;
    if (ctx.priorities.tertiary.contains(muscle)) return 1;
    return 0;
  }

  double _deficitPenalty(String state, int magnitude) {
    if (state != 'deficit') return 0.0;
    if (magnitude < 150) return 0.05;
    if (magnitude < 300) return 0.10;
    if (magnitude < 500) return 0.15;
    return 0.20;
  }

  double _readinessPenalty(double readiness) {
    // readiness bajo = penaliza MRV; readiness alto = sin penalización
    if (readiness >= 0.70) return 0.00;
    if (readiness >= 0.55) return 0.05;
    if (readiness >= 0.45) return 0.10;
    if (readiness >= 0.30) return 0.15;
    return 0.20;
  }

  Map<String, _PosteriorLite> _safePosterior(AthleteLongitudinalState st) {
    try {
      // El estado real ya existe en tu repo; aquí lo adaptamos de forma segura.
      final raw = st.posteriorByMuscle;
      final out = <String, _PosteriorLite>{};
      raw.forEach((k, v) {
        out[k] = _PosteriorLite(mevMean: v.mevMean, mrvMean: v.mrvMean);
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  int _blendInt(int a, int b, double wB) {
    final wA = 1.0 - wB;
    return (a * wA + b * wB).round();
  }

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
  double _clampDouble(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}

class _LevelPrior {
  final int baseMev;
  final int baseMrv;
  const _LevelPrior({required this.baseMev, required this.baseMrv});
}

class _PosteriorLite {
  final double mevMean;
  final double mrvMean;
  const _PosteriorLite({required this.mevMean, required this.mrvMean});
}

/// Helper para asegurar que V2VolumeCapacity se pueda loggear fácil si se requiere.
abstract class DecisionTraceCapable {
  const DecisionTraceCapable();
  Map<String, dynamic> traceContext();
}
