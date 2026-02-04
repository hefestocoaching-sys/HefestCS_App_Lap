// lib/domain/training_v3/converters/v3_to_v2_converter.dart

import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/training/training_plan_model.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';

/// Conversor V3 → V2
///
/// PROPÓSITO:
/// Convertir el resultado de Motor V3 (TrainingProgramV3Result)
/// al modelo V2 (TrainingPlan) usado por UI y Firestore.
///
/// REGLAS:
/// - Conversión pura sin lógica de negocio
/// - Mapeo determinístico y predecible
/// - Preservar toda la información relevante
/// - Mantener orden y coherencia
///
/// ARQUITECTURA:
/// - TrainingProgramV3Result.plan (TrainingPlanConfig)
///   → TrainingPlan (modelo V2 para UI/Firestore)
///
/// - TrainingPlanConfig.weeks (List<TrainingWeek>)
///   → PlanWeek (semanas V2)
///
/// - TrainingWeek.sessions (List<TrainingSession>)
///   → PlanDay (días V2)
///
/// - TrainingSession.prescriptions (List<ExercisePrescription>)
///   → DayMuscleVolume (volumen por músculo V2)
class V3ToV2Converter {
  V3ToV2Converter._(); // Clase estática

  /// Convierte TrainingProgramV3Result a TrainingPlan (V2)
  ///
  /// ENTRADA:
  /// - [v3Result]: Resultado del Motor V3
  ///
  /// SALIDA:
  /// - TrainingPlan con estructura V2 compatible con UI/Firestore
  ///
  /// CASOS:
  /// - Si v3Result.isBlocked → lanza Exception
  /// - Si v3Result.plan == null → lanza Exception
  /// - Si conversión exitosa → retorna TrainingPlan
  ///
  /// THROWS:
  /// - [StateError] si el resultado está bloqueado o no tiene plan
  static TrainingPlan convert({required TrainingProgramV3Result v3Result}) {
    // Validaciones
    if (v3Result.isBlocked) {
      throw StateError(
        'No se puede convertir plan bloqueado: ${v3Result.blockReason}',
      );
    }

    final planConfig = v3Result.plan;
    if (planConfig == null) {
      throw StateError('TrainingProgramV3Result.plan es null');
    }

    // Convertir TrainingPlanConfig → TrainingPlan
    return _convertPlanConfig(planConfig);
  }

  /// Convierte TrainingPlanConfig (V3) a TrainingPlan (V2)
  static TrainingPlan _convertPlanConfig(TrainingPlanConfig planConfig) {
    // Convertir semanas
    final planWeeks = <PlanWeek>[];
    for (var i = 0; i < planConfig.weeks.length; i++) {
      final weekV3 = planConfig.weeks[i];
      final planWeek = _convertWeek(weekV3);
      planWeeks.add(planWeek);
    }

    // Determinar daysPerWeek (número de sesiones por semana)
    final daysPerWeek = planConfig.weeks.isNotEmpty
        ? planConfig.weeks.first.sessions.length
        : 0;

    // Construir nombre del template basado en splitId
    final templateName = _parseTemplateName(planConfig.splitId);

    return TrainingPlan(
      id: planConfig.id,
      templateId: planConfig.splitId,
      templateName: templateName,
      daysPerWeek: daysPerWeek,
      weeks: planWeeks,
      generatedAt: DateTime.now(),
      adaptationNotes: _extractAdaptationNotes(planConfig),
    );
  }

  /// Convierte TrainingWeek (V3) a PlanWeek (V2)
  static PlanWeek _convertWeek(TrainingWeek weekV3) {
    final planDays = <PlanDay>[];

    for (var i = 0; i < weekV3.sessions.length; i++) {
      final sessionV3 = weekV3.sessions[i];
      final planDay = _convertSession(sessionV3, dayNumber: i + 1);
      planDays.add(planDay);
    }

    return PlanWeek(
      weekNumber: weekV3.weekNumber,
      days: planDays,
      adaptationReason: null, // V3 no tiene adaptationReason por semana
    );
  }

  /// Convierte TrainingSession (V3) a PlanDay (V2)
  static PlanDay _convertSession(
    TrainingSession sessionV3, {
    required int dayNumber,
  }) {
    // Agrupar prescripciones por grupo muscular
    final muscleVolumes = <String, DayMuscleVolume>{};

    for (final prescription in sessionV3.prescriptions) {
      final muscleName = _getMuscleDisplayName(prescription.muscleGroup);

      // Si ya existe volumen para este músculo, sumar
      if (muscleVolumes.containsKey(muscleName)) {
        final current = muscleVolumes[muscleName]!;
        final intensityCategory = _categorizeIntensity(prescription.repRange);

        muscleVolumes[muscleName] = DayMuscleVolume(
          muscleName: muscleName,
          total: current.total + prescription.sets,
          heavy:
              current.heavy +
              (intensityCategory == 'heavy' ? prescription.sets : 0),
          medium:
              current.medium +
              (intensityCategory == 'medium' ? prescription.sets : 0),
          light:
              current.light +
              (intensityCategory == 'light' ? prescription.sets : 0),
          source: 'PLAN',
        );
      } else {
        // Primera vez que vemos este músculo
        final intensityCategory = _categorizeIntensity(prescription.repRange);

        muscleVolumes[muscleName] = DayMuscleVolume(
          muscleName: muscleName,
          total: prescription.sets,
          heavy: intensityCategory == 'heavy' ? prescription.sets : 0,
          medium: intensityCategory == 'medium' ? prescription.sets : 0,
          light: intensityCategory == 'light' ? prescription.sets : 0,
          source: 'PLAN',
        );
      }
    }

    return PlanDay(
      dayNumber: dayNumber,
      dayLabel: sessionV3.sessionName,
      muscleVolumes: muscleVolumes,
      notes: null, // V3 no tiene notes por sesión
    );
  }

  /// Parsea el nombre del template desde splitId
  ///
  /// EJEMPLOS:
  /// - "torso_pierna_4d" → "Torso/Pierna (4 días)"
  /// - "ppl_6d" → "Push/Pull/Legs (6 días)"
  /// - "fullbody_3d" → "Full Body (3 días)"
  static String _parseTemplateName(String splitId) {
    final parts = splitId.split('_');
    if (parts.length < 2) return splitId;

    final splitType = parts[0];
    final frequency = parts.length > 1 ? parts[1] : '';

    final splitNames = {
      'torso': 'Torso/Pierna',
      'ppl': 'Push/Pull/Legs',
      'fullbody': 'Full Body',
      'upper': 'Upper/Lower',
      'bro': 'Bro Split',
    };

    final splitName = splitNames[splitType] ?? splitType;
    final frequencyDisplay = frequency.replaceAll('d', ' días');

    return '$splitName ($frequencyDisplay)';
  }

  /// Obtiene el nombre displayable del grupo muscular
  static String _getMuscleDisplayName(MuscleGroup muscleGroup) {
    // Mapeo de MuscleGroup enum a nombres legibles
    final muscleNames = {
      MuscleGroup.chest: 'Pectoral',
      MuscleGroup.shoulderAnterior: 'Deltoides Anterior',
      MuscleGroup.shoulderLateral: 'Deltoides Lateral',
      MuscleGroup.shoulderPosterior: 'Deltoides Posterior',
      MuscleGroup.shoulders: 'Hombros',
      MuscleGroup.lats: 'Dorsal Ancho',
      MuscleGroup.back: 'Espalda Alta',
      MuscleGroup.upperBack: 'Espalda Superior',
      MuscleGroup.traps: 'Trapecio',
      MuscleGroup.biceps: 'Bíceps',
      MuscleGroup.triceps: 'Tríceps',
      MuscleGroup.forearms: 'Antebrazos',
      MuscleGroup.quads: 'Cuádriceps',
      MuscleGroup.hamstrings: 'Femoral',
      MuscleGroup.glutes: 'Glúteos',
      MuscleGroup.calves: 'Gemelos',
      MuscleGroup.abs: 'Abdominales',
      MuscleGroup.lowerBack: 'Lumbar',
      MuscleGroup.fullBody: 'Cuerpo Completo',
    };

    return muscleNames[muscleGroup] ?? muscleGroup.name;
  }

  /// Categoriza la intensidad basándose en el rango de repeticiones
  ///
  /// REGLAS:
  /// - Heavy: 1-6 reps (fuerza/potencia)
  /// - Medium: 7-12 reps (hipertrofia)
  /// - Light: 13+ reps (resistencia/congestión)
  static String _categorizeIntensity(RepRange repRange) {
    final avgReps = (repRange.min + repRange.max) / 2;

    if (avgReps <= 6) {
      return 'heavy';
    } else if (avgReps <= 12) {
      return 'medium';
    } else {
      return 'light';
    }
  }

  /// Extrae notas de adaptación desde el state del plan
  static String? _extractAdaptationNotes(TrainingPlanConfig planConfig) {
    final state = planConfig.state;
    if (state == null) return null;

    // Intentar extraer información relevante del state
    final notes = <String>[];

    // Fase de periodización
    if (state.containsKey('phase')) {
      final phase = state['phase'];
      if (phase is String && phase.isNotEmpty) {
        notes.add('Fase: $phase');
      }
    }

    // Estrategia utilizada
    if (state.containsKey('strategy')) {
      final strategy = state['strategy'];
      if (strategy is String && strategy.isNotEmpty) {
        notes.add('Estrategia: $strategy');
      }
    }

    // Ajustes por fatiga
    if (state.containsKey('fatigueAdjustment')) {
      final fatigue = state['fatigueAdjustment'];
      if (fatigue is Map && fatigue.isNotEmpty) {
        notes.add('Ajustes por fatiga aplicados');
      }
    }

    return notes.isNotEmpty ? notes.join(' | ') : null;
  }

  /// Método alternativo: Convierte directamente TrainingPlanConfig a TrainingPlan
  ///
  /// Útil cuando ya se tiene un TrainingPlanConfig sin envolver en V3Result
  static TrainingPlan convertFromConfig({
    required TrainingPlanConfig planConfig,
  }) {
    return _convertPlanConfig(planConfig);
  }
}
