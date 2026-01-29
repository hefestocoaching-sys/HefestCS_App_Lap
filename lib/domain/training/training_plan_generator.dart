import 'package:hcs_app_lap/domain/entities/weekly_volume_record.dart';
import 'package:hcs_app_lap/domain/training/split_templates.dart' as legacy;
import 'package:hcs_app_lap/domain/training/training_plan_model.dart';

/// Generador de planes de entrenamiento de 4 semanas basado en:
/// - Plantilla de split (define estructura de días/músculos)
/// - VOP de Tab 2 (define volumen semanal)
/// - Bitácora (ajusta volumen desde semana 2)
/// - Distribución H/M/L de Tab 2
class TrainingPlanGenerator {
  /// Generar un plan de 4 semanas
  static TrainingPlan generatePlan({
    required legacy.LegacySplitTemplate template,
    required int volumePerWeek, // VOP total
    required Map<String, int> muscleBaselines, // VOP por músculo
    required Map<String, dynamic> seriesSplit, // H/M/L (20/60/20 default)
    required List<WeeklyVolumeRecord>? bitacoraHistory, // Histórico opcional
  }) {
    final weeks = <PlanWeek>[];
    // Preasignar el baseline semanal por músculo a los días donde aparece
    final perDayAllocations = _allocateBaselineAcrossDays(
      template,
      muscleBaselines,
    );

    for (int weekNum = 1; weekNum <= 4; weekNum++) {
      // Verificar si hay adaptación en esta semana
      final prevWeekBitacora = weekNum > 1
          ? _getBitacoraForWeek(bitacoraHistory, weekNum - 1)
          : null;
      final adaptationFactor = _calculateAdaptationFactor(
        weekNumber: weekNum,
        prevWeekData: prevWeekBitacora,
        baseVolume: volumePerWeek,
      );

      final week = _buildPlanWeek(
        weekNumber: weekNum,
        template: template,
        perDayAllocations: perDayAllocations,
        adaptationFactor: adaptationFactor,
        seriesSplit: seriesSplit,
      );

      weeks.add(week);
    }

    return TrainingPlan(
      id: '${template.id}_${DateTime.now().millisecondsSinceEpoch}',
      templateId: template.id,
      templateName: template.name,
      daysPerWeek: template.daysPerWeek,
      weeks: weeks,
      generatedAt: DateTime.now(),
      adaptationNotes: _buildAdaptationNotes(bitacoraHistory),
    );
  }

  /// Construir una semana del plan
  static PlanWeek _buildPlanWeek({
    required int weekNumber,
    required legacy.LegacySplitTemplate template,
    required Map<String, Map<int, int>> perDayAllocations,
    required double adaptationFactor,
    required Map<String, dynamic> seriesSplit,
  }) {
    final days = <PlanDay>[];

    for (int dayNum = 1; dayNum <= template.daysPerWeek; dayNum++) {
      final muscleList = template.getMusclesForDay(dayNum);

      if (muscleList.isEmpty) {
        // Día de descanso (ej: PPL tiene día 4 vacío)
        days.add(
          PlanDay(
            dayNumber: dayNum,
            dayLabel: 'Día $dayNum (Descanso)',
            muscleVolumes: {},
          ),
        );
        continue;
      }

      final dayMuscleVolumes = <String, DayMuscleVolume>{};
      for (final muscle in muscleList) {
        final baseForDay = perDayAllocations[muscle]?[dayNum] ?? 0;
        final adaptedVolume = (baseForDay * adaptationFactor).round();
        final split = _distributeSeries(adaptedVolume, {
          'heavy': (seriesSplit['heavy'] as num?)?.toInt() ?? 20,
          'medium': (seriesSplit['medium'] as num?)?.toInt() ?? 60,
          'light': (seriesSplit['light'] as num?)?.toInt() ?? 20,
        });

        dayMuscleVolumes[muscle] = DayMuscleVolume(
          muscleName: muscle,
          total: adaptedVolume,
          heavy: split['heavy']!,
          medium: split['medium']!,
          light: split['light']!,
          source: weekNumber == 1 ? 'PLAN' : 'AUTO',
        );
      }

      days.add(
        PlanDay(
          dayNumber: dayNum,
          dayLabel: 'Día $dayNum',
          muscleVolumes: dayMuscleVolumes,
        ),
      );
    }

    return PlanWeek(
      weekNumber: weekNumber,
      days: days,
      adaptationReason: weekNumber == 1
          ? null
          : 'Adaptado por bitácora semana ${weekNumber - 1}',
    );
  }

  /// Extraer músculos únicos de la plantilla
  static Set<String> _extractMuscleGroups(legacy.LegacySplitTemplate template) {
    final muscles = <String>{};
    for (final dayMuscles in template.dayToMuscles.values) {
      muscles.addAll(dayMuscles);
    }
    return muscles;
  }

  /// Asignar el baseline semanal por músculo entre los días que aparece.
  /// Garantiza que la suma de los días = baseline semanal.
  static Map<String, Map<int, int>> _allocateBaselineAcrossDays(
    legacy.LegacySplitTemplate template,
    Map<String, int> baselines,
  ) {
    final allocations = <String, Map<int, int>>{};
    final muscles = _extractMuscleGroups(template);

    for (final muscle in muscles) {
      // Días donde aparece este músculo
      final daysForMuscle = <int>[];
      template.dayToMuscles.forEach((dayNum, ms) {
        if (ms.contains(muscle)) daysForMuscle.add(dayNum);
      });

      if (daysForMuscle.isEmpty) continue;

      final baseline = baselines[muscle] ?? 10;
      final freq = daysForMuscle.length;
      final q = baseline ~/ freq; // cuota base
      int r = baseline % freq; // resto

      final perDay = <int, int>{};
      for (final dayNum in daysForMuscle..sort()) {
        // Distribuir el resto +1 en los primeros r días
        final add = r > 0 ? 1 : 0;
        perDay[dayNum] = q + add;
        if (r > 0) r--;
      }

      allocations[muscle] = perDay;
    }

    return allocations;
  }

  /// Calcular factor de adaptación según bitácora
  static double _calculateAdaptationFactor({
    required int weekNumber,
    required Map<String, dynamic>? prevWeekData,
    required int baseVolume,
  }) {
    // Semana 1 siempre 1.0 (sin adaptación)
    if (weekNumber == 1) return 1.0;

    // Si no hay bitácora previa, mantener volumen
    if (prevWeekData == null) return 1.0;

    // Calcular adherencia
    final realVolume = prevWeekData['totalSeries'] as int? ?? baseVolume;
    final adherenceRatio = realVolume / baseVolume;

    // Lógica conservadora
    if (adherenceRatio >= 1.1) return 1.05; // +5%
    if (adherenceRatio >= 0.85) return 1.0; // Sin cambio
    return 0.95; // -5%
  }

  /// Obtener bitácora de una semana específica
  static Map<String, dynamic>? _getBitacoraForWeek(
    List<WeeklyVolumeRecord>? bitacora,
    int weekNumber,
  ) {
    if (bitacora == null || bitacora.isEmpty) return null;

    // Buscar registros de la semana anterior
    int totalSeries = 0;
    for (final record in bitacora) {
      totalSeries += record.totalSeries;
    }

    return totalSeries > 0
        ? {'totalSeries': totalSeries, 'weekNumber': weekNumber}
        : null;
  }

  /// Distribuir series según split H/M/L
  static Map<String, int> _distributeSeries(
    int totalSeries,
    Map<String, int> split,
  ) {
    final heavy = (totalSeries * (split['heavy'] ?? 20) / 100).round();
    final medium = (totalSeries * (split['medium'] ?? 60) / 100).round();
    final light = totalSeries - heavy - medium;

    return {'heavy': heavy, 'medium': medium, 'light': light};
  }

  /// Construir notas de adaptación
  static String? _buildAdaptationNotes(List<WeeklyVolumeRecord>? bitacora) {
    if (bitacora == null || bitacora.isEmpty) {
      return null;
    }

    return 'Plan adaptado según bitácora de entrenamientos previos.';
  }
}
