import 'package:hcs_app_lap/domain/entities/generated_plan.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/muscle_volume_buckets.dart';

/// Mapper para compatibilidad: convierte TrainingPlanConfig → GeneratedPlan (legacy).
/// No agrega lógica: solo traduce volumen total por músculo en la primera semana.
class TrainingPlanMapper {
  static GeneratedPlan toGeneratedPlan(TrainingPlanConfig plan) {
    final week = plan.weeks.isNotEmpty ? plan.weeks.first : null;
    final volumePlan = <String, dynamic>{};
    if (week != null) {
      for (final session in week.sessions) {
        for (final p in session.prescriptions) {
          final muscle = p.muscleGroup.name;
          final prev = volumePlan[muscle];
          final prevMedium = prev is Map
              ? (prev['mediumSets'] as double? ?? 0.0)
              : 0.0;
          volumePlan[muscle] = {
            // Colocamos todo en mediumSets para sumar volumen total sin añadir reglas nuevas
            'heavySets': 0.0,
            'mediumSets': prevMedium + p.sets.toDouble(),
            'lightSets': 0.0,
          };
        }
      }
    }

    return GeneratedPlan(
      weeks: plan.microcycleLengthInWeeks,
      volumePlan: volumePlan.map(
        (k, v) => MapEntry(
          k,
          MuscleVolumeBuckets(
            heavySets: (v['heavySets'] as double?) ?? 0.0,
            mediumSets: (v['mediumSets'] as double?) ?? 0.0,
            lightSets: (v['lightSets'] as double?) ?? 0.0,
          ),
        ),
      ),
      audit: {
        'engine': 'TrainingProgramEngine_1to8',
        'splitId': plan.splitId,
        'weeks': plan.microcycleLengthInWeeks,
      },
    );
  }
}
