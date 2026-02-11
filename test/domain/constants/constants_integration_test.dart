import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/constants/volume_landmarks.dart';
import 'package:hcs_app_lap/domain/constants/session_limits.dart';
import 'package:hcs_app_lap/domain/constants/rir_by_phase.dart';
import 'package:hcs_app_lap/domain/constants/exercise_fatigue_cost.dart';
import 'package:hcs_app_lap/domain/constants/rest_period_calculator.dart';
import 'package:hcs_app_lap/domain/constants/intensity_calculator.dart';
import 'package:hcs_app_lap/domain/constants/volume_progression.dart';

void main() {
  test('VolumeLandmarks tiene todos los músculos', () {
    final expectedMuscles = [
      'chest',
      'lats',
      'back_mid_upper',
      'upper_traps',
      'shoulders',
      'quads',
      'hamstrings',
      'glutes',
      'biceps',
      'triceps',
      'calves',
      'abs',
    ];

    for (final muscle in expectedMuscles) {
      expect(VolumeLandmarks.supportedMuscles, contains(muscle));
      expect(VolumeLandmarks.getMEV(muscle, 'beginner'), greaterThan(0));
      expect(VolumeLandmarks.getMEV(muscle, 'intermediate'), greaterThan(0));
      expect(VolumeLandmarks.getMEV(muscle, 'advanced'), greaterThan(0));
    }

    expect(VolumeLandmarks.getMRV('chest', 'intermediate'), 22);
  });

  test('SessionVolumeLimits retorna valores correctos', () {
    expect(SessionVolumeLimits.getLimit('beginner', 'chest'), 6);
    expect(SessionVolumeLimits.getLimit('intermediate', 'chest'), 8);
    expect(SessionVolumeLimits.getLimit('advanced', 'glutes'), 12);
  });

  test('RIRByPhase tiene todas las fases', () {
    expect(
      RIRByPhase.allPhases,
      containsAll(['accumulation', 'intensification', 'realization', 'deload']),
    );

    expect(RIRByPhase.getRIRTarget('accumulation'), 2.5);
    expect(RIRByPhase.getRIRTarget('deload'), 4.5);
  });

  test('ExerciseFatigueCost clasifica correctamente', () {
    expect(
      ExerciseFatigueCost.getCostCategory('conventional_deadlift'),
      'very_high',
    );
    expect(ExerciseFatigueCost.getCostCategory('bicep_curl'), 'low');
  });

  test('RestPeriodCalculator calcula descanso correcto', () {
    expect(RestPeriodCalculator.getRestSeconds(5, true), 240);
    expect(RestPeriodCalculator.getRestSeconds(10, false), 90);
    expect(RestPeriodCalculator.formatRestTime(240), '4:00');
  });

  test('IntensityCalculator convierte correctamente', () {
    expect(IntensityCalculator.repsToPercent[10], 0.75);
    expect(IntensityCalculator.estimated1RM(100, 10), closeTo(133.33, 0.5));
  });

  test('VolumeProgression tiene valores por nivel', () {
    expect(VolumeProgression.getIncrement('beginner'), 2);
    expect(VolumeProgression.getWeeksInterval('beginner'), 3);
    expect(VolumeProgression.getIncrement('advanced'), 4);
    expect(VolumeProgression.getWeeksInterval('advanced'), 1);
  });
}
