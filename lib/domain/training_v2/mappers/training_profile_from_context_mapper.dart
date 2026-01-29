import 'dart:math';

import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

class TrainingProfileFromContextMapper {
  const TrainingProfileFromContextMapper();

  /// Convierte TrainingContext -> TrainingProfile para reutilizar Phase1..Phase8.
  /// IMPORTANT: este profile es "motor-ready": ya lleva extra normalizado + overrides.
  TrainingProfile map(TrainingContext ctx) {
    // Base: parte de un copy del training profile existente NO existe en ctx.
    // Entonces armamos el mínimo con los campos que TrainingProfile exige.
    final baseExtra = <String, dynamic>{};

    // Meta
    baseExtra[TrainingExtraKeys.trainingLevel] = ctx.meta.level?.name;
    baseExtra[TrainingExtraKeys.daysPerWeek] = ctx.meta.daysPerWeek;
    baseExtra[TrainingExtraKeys.timePerSessionMinutes] =
        ctx.meta.timePerSessionMinutes;

    // Interview cuantitativa
    baseExtra[TrainingExtraKeys.trainingYears] =
        ctx.interview.yearsTrainingContinuous;
    baseExtra[TrainingExtraKeys.avgSleepHours] = ctx.interview.avgSleepHours;
    baseExtra[TrainingExtraKeys.restBetweenSetsSeconds] =
        ctx.interview.restBetweenSetsSeconds;

    // Priorización muscular
    baseExtra[TrainingExtraKeys.priorityMusclesPrimary] =
        ctx.priorities.primary;
    baseExtra[TrainingExtraKeys.priorityMusclesSecondary] =
        ctx.priorities.secondary;
    baseExtra[TrainingExtraKeys.priorityMusclesTertiary] =
        ctx.priorities.tertiary;

    // Lesiones
    baseExtra['activeInjuries'] = ctx.constraints.activeInjuries;

    // Persistir snapshot biológico (útil para trazabilidad)
    baseExtra['athlete.gender'] = ctx.athlete.gender?.name;
    baseExtra['athlete.ageYears'] = ctx.athlete.ageYears;
    baseExtra['athlete.heightCm'] = ctx.athlete.heightCm;
    baseExtra['athlete.weightKg'] = ctx.athlete.weightKg;
    baseExtra['athlete.usesAnabolics'] = ctx.athlete.usesAnabolics;
    baseExtra['athlete.isCompetitor'] = ctx.athlete.isCompetitor;

    // Energy availability (señal de recuperación)
    baseExtra['energy.state'] = ctx.energy.state;
    baseExtra['energy.deltaKcalMinusGet'] = ctx.energy.deltaKcalMinusGet;
    baseExtra['energy.magnitude'] = ctx.energy.magnitude;

    // Adaptive overrides (aprendizaje) -> solo si NO existe override manual para ese músculo
    final adaptiveRaw = _adaptiveVolumeOverridesFromLongitudinal(
      ctx.longitudinal,
      energyState: ctx.energy.state,
      energyMagnitude: ctx.energy.magnitude,
    );

    final mergedManual = _mergeManualOverridesPreferCoach(
      coachManualRaw: ctx.manualOverrides,
      adaptiveRaw: adaptiveRaw,
    );

    baseExtra[TrainingExtraKeys.manualOverrides] = mergedManual;

    // Crear profile con campos directos (globalGoal, trainingFocus van en constructor)
    final profile = TrainingProfile(
      trainingLevel: ctx.meta.level,
      globalGoal: ctx.meta.goal,
      trainingFocus: ctx.meta.focus,
      daysPerWeek: ctx.meta.daysPerWeek,
      timePerSessionMinutes: ctx.meta.timePerSessionMinutes,
      extra: baseExtra,
    );

    return profile.normalizedFromExtra();
  }

  Map<String, dynamic> _adaptiveVolumeOverridesFromLongitudinal(
    AthleteLongitudinalState state, {
    required String energyState,
    int energyMagnitude = 0,
  }) {
    // Construimos volumeOverrides: { muscle: {mev,mav,mrv} }
    // Estrategia conservadora:
    // - tomamos medias posteriores
    // - redondeo a sets
    // - clamp min 4, max 30 (guardrail)
    // - en déficit fuerte, reducimos MRV 10-20% (no nutrición; recuperación).
    final vol = <String, dynamic>{};

    final isDeficit = (energyState == 'deficit');
    final deficitHard = isDeficit && energyMagnitude >= 300;

    state.posteriorByMuscle.forEach((muscle, posterior) {
      final mev = _clampInt(posterior.mevMean.round(), 4, 24);
      var mrv = _clampInt(posterior.mrvMean.round(), 6, 30);

      if (deficitHard) {
        mrv = max(6, (mrv * 0.85).round());
      }

      // mav opcional: punto intermedio
      final mav = max(mev, min(mrv, ((mev + mrv) / 2).round()));

      vol[muscle] = {'mev': mev, 'mav': mav, 'mrv': mrv};
    });

    if (vol.isEmpty) return const {};

    return {
      'volumeOverrides': vol,
      // No tocamos priorityOverrides aquí.
      // Intensificación y RIR quedan al coach/servicios.
    };
  }

  Map<String, dynamic> _mergeManualOverridesPreferCoach({
    required Map<String, dynamic> coachManualRaw,
    required Map<String, dynamic> adaptiveRaw,
  }) {
    if (adaptiveRaw.isEmpty) return coachManualRaw;

    final coach = Map<String, dynamic>.from(coachManualRaw);
    final adaptive = Map<String, dynamic>.from(adaptiveRaw);

    // volumeOverrides: preferimos coach si existe.
    final coachVol = (coach['volumeOverrides'] is Map)
        ? Map<String, dynamic>.from(coach['volumeOverrides'])
        : <String, dynamic>{};
    final adapVol = (adaptive['volumeOverrides'] is Map)
        ? Map<String, dynamic>.from(adaptive['volumeOverrides'])
        : <String, dynamic>{};

    adapVol.forEach((muscle, v) {
      if (!coachVol.containsKey(muscle)) {
        coachVol[muscle] = v;
      }
    });

    if (coachVol.isNotEmpty) coach['volumeOverrides'] = coachVol;

    // allowIntensification / rirTargetOverride / intensificationMaxPerWeek:
    // nunca los pone el adaptive, solo el coach o defaults del motor.
    return coach;
  }

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
}
