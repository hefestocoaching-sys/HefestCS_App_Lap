import 'dart:math';

import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_2_volume_capacity.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

class Phase3TargetVolumeResult {
  final Map<String, int> targetWeeklySetsByMuscle;
  final Map<String, double> chosenPercentileByMuscle;
  final List<DecisionTrace> decisions;

  const Phase3TargetVolumeResult({
    required this.targetWeeklySetsByMuscle,
    required this.chosenPercentileByMuscle,
    required this.decisions,
  });
}

/// Capa 3: elige el volumen objetivo dentro de MEV–MRV.
/// Método: percentil adaptativo (p) dentro del rango, determinista y trazable.
class Phase3TargetVolume {
  Phase3TargetVolumeResult run({
    required TrainingContext ctx,
    required double readinessScore,
    required Map<String, V2VolumeCapacity> capacityByMuscle,
    required int maxWeeklySetsSoftCap,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    final outSets = <String, int>{};
    final outP = <String, double>{};

    // Ajustes globales
    final isDeficit = ctx.energy.state == 'deficit';
    final deficitHard = isDeficit && ctx.energy.magnitude >= 300;

    // Priors globales por nivel: percentil base sugerido
    final pBase = _basePercentileByLevel(ctx.meta.level!.name.toLowerCase());

    // Aprendizaje local: posterior por músculo (si existe)
    final posterior = _safePosterior(ctx.longitudinal);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase3TargetVolume',
        category: 'global_percentile_inputs',
        description:
            'Inputs globales para percentil base (nivel/readiness/energía).',
        context: {
          'level': ctx.meta.level!.name,
          'pBase': pBase,
          'readinessScore': readinessScore,
          'energyState': ctx.energy.state,
          'energyMagnitude': ctx.energy.magnitude,
          'deficitHard': deficitHard,
        },
        timestamp: ts,
      ),
    );

    for (final entry in capacityByMuscle.entries) {
      final muscle = entry.key;
      final cap = entry.value;

      // 1) Percentil inicial = prior por nivel
      double p = pBase;

      // 2) Ajuste por prioridad muscular
      p += _priorityDelta(
        muscle,
        ctx,
      ); // +0.10 primary / +0.06 secondary / +0.03 tertiary

      // 3) Ajuste por readiness
      p += _readinessDelta(readinessScore);

      // 4) Ajuste por energía (déficit reduce percentil)
      if (isDeficit) {
        p -= deficitHard ? 0.12 : 0.06;
      }

      // 5) Lesiones activas -> conservador
      if (ctx.constraints.activeInjuries.isNotEmpty) {
        p -= 0.06;
      }

      // 6) Aprendizaje local: si hay posterior, orientar percentil hacia volumen que “toleró”
      // Estrategia: inferimos un percentil equivalente en el rango MEV–MRV basado en posterior.mrvMean.
      final post = posterior[muscle];
      if (post != null) {
        final inferredP = _inferPercentileFromPosterior(
          mev: cap.mev,
          mrv: cap.mrv,
          postMrvMean: post.mrvMean,
        );
        // Blend: 60% inferred, 40% p calculado (conservador).
        p = (p * 0.40) + (inferredP * 0.60);

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase3TargetVolume',
            category: 'local_percentile_blend',
            description: 'Percentil ajustado con aprendizaje local (blend).',
            context: {
              'muscle': muscle,
              'p_before': _round2(pBase),
              'inferredP': _round2(inferredP),
              'p_after': _round2(p),
              'posteriorMrvMean': post.mrvMean,
            },
            timestamp: ts,
          ),
        );
      }

      // 7) Clamp percentil a rango clínico seguro
      // No usar extremos 0 o 1: evita under/overfitting.
      p = _clampDouble(p, 0.30, 0.85);

      // 8) Convertir percentil a sets objetivo
      final target = _percentileToSets(
        mev: cap.mev,
        mrv: cap.mrv,
        p: p,
        softCap: maxWeeklySetsSoftCap,
      );

      // 9) Guardrails finales con softCap RELATIVO al músculo
      // (evita homogeneizar todos los targets al mismo valor global)
      const double softCapRatio = 0.85; // 85% del MRV como límite superior
      final int muscleSoftCap = max(cap.mev, (cap.mrv * softCapRatio).round());

      final finalTarget = _clampInt(
        target,
        cap.mev,
        min(cap.mrv, muscleSoftCap),
      );

      outSets[muscle] = finalTarget;
      outP[muscle] = p;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase3TargetVolume',
          category: 'target_final',
          description:
              'Target semanal definido por percentil dentro de MEV–MRV.',
          context: {
            'muscle': muscle,
            'mev': cap.mev,
            'mrv': cap.mrv,
            'mav': cap.mav,
            'muscleSoftCap': muscleSoftCap,
            'p': _round2(p),
            'targetWeeklySets': finalTarget,
            'inputs': {
              'priorityDelta': _priorityDelta(muscle, ctx),
              'readinessDelta': _readinessDelta(readinessScore),
              'energyDelta': isDeficit ? (deficitHard ? -0.12 : -0.06) : 0.0,
              'injuryDelta': ctx.constraints.activeInjuries.isNotEmpty
                  ? -0.06
                  : 0.0,
              'pBase': pBase,
            },
          },
          timestamp: ts,
        ),
      );
    }

    return Phase3TargetVolumeResult(
      targetWeeklySetsByMuscle: outSets,
      chosenPercentileByMuscle: outP,
      decisions: decisions,
    );
  }

  // ---------------- helpers ----------------

  double _basePercentileByLevel(String levelName) {
    // Conservador: novato más bajo; avanzado más alto.
    switch (levelName) {
      case 'beginner':
        return 0.45;
      case 'intermediate':
        return 0.55;
      case 'advanced':
        return 0.62;
      default:
        return 0.55;
    }
  }

  double _priorityDelta(String muscle, TrainingContext ctx) {
    if (ctx.priorities.primary.contains(muscle)) return 0.10;
    if (ctx.priorities.secondary.contains(muscle)) return 0.06;
    if (ctx.priorities.tertiary.contains(muscle)) return 0.03;
    return 0.0;
  }

  double _readinessDelta(double readiness) {
    // readiness alto sube percentil; bajo lo baja.
    if (readiness >= 0.80) return 0.08;
    if (readiness >= 0.65) return 0.04;
    if (readiness >= 0.55) return 0.00;
    if (readiness >= 0.45) return -0.05;
    if (readiness >= 0.30) return -0.10;
    return -0.14;
  }

  int _percentileToSets({
    required int mev,
    required int mrv,
    required double p,
    required int
    softCap, // Conservado por compatibilidad de firma, pero no usado aquí
  }) {
    // El soft cap se aplica de forma RELATIVA al músculo en el clamp final,
    // no de forma global aquí (evita homogeneizar todos los targets).
    final span = max(1, mrv - mev);
    final raw = mev + (span * p);
    return raw.round();
  }

  double _inferPercentileFromPosterior({
    required int mev,
    required int mrv,
    required double postMrvMean,
  }) {
    // Si el posterior sugiere MRV alto, tendemos a percentiles más altos.
    // Convertimos postMrvMean a un punto "relativo" dentro del rango MEV–MRV.
    final span = max(1, mrv - mev).toDouble();
    final rel = (postMrvMean - mev) / span;
    // Clamp suave
    return _clampDouble(rel, 0.35, 0.80);
  }

  Map<String, _PosteriorLite> _safePosterior(AthleteLongitudinalState st) {
    try {
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

  double _round2(double v) => (v * 100).roundToDouble() / 100.0;

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
  double _clampDouble(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}

class _PosteriorLite {
  final double mevMean;
  final double mrvMean;
  const _PosteriorLite({required this.mevMean, required this.mrvMean});
}
