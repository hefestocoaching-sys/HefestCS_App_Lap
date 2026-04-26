import 'package:flutter/material.dart';

import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_volume_computation_helper.dart';
import 'package:hcs_app_lap/features/training_feature/services/training_profile_form_mapper.dart';

enum TrainingDurationUnit { months, years }

class TrainingInterviewFormState {
  final TextEditingController heightCmController = TextEditingController();
  final TextEditingController weightKgController = TextEditingController();
  final TextEditingController ageYearsController = TextEditingController();
  final TextEditingController trainingDurationController =
      TextEditingController();

  TrainingDurationUnit trainingDurationUnit = TrainingDurationUnit.months;

  int? trainingMonths;
  TrainingLevelDerived? trainingLevelDerived;

  String? strengthLevelClass;
  int? workCapacityScore;
  int? recoveryHistoryScore;
  bool? externalRecoverySupport;
  String? programNoveltyClass;
  String? externalPhysicalStressLevel;
  String? nonPhysicalStressLevel2;
  String? restQuality2;
  String? dietHabitsClass;
  bool? usesAnabolics;

  final Set<String> injuryRegions = <String>{};
  final Map<String, String> injuryPatternByRegion = <String, String>{};
  String? injurySeverity;
  String? injuryStatus;

  String? backFocus;
  final List<String> priorityMusclesPrimary = <String>[];
  final List<String> priorityMusclesSecondary = <String>[];
  final List<String> priorityMusclesTertiary = <String>[];

  void dispose() {
    heightCmController.dispose();
    weightKgController.dispose();
    ageYearsController.dispose();
    trainingDurationController.dispose();
  }

  void loadFromProfile(TrainingProfile profile) {
    final seed = TrainingProfileFormMapper.valuesFromProfile(profile);

    heightCmController.text =
        seed.heightCm?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '';
    weightKgController.text =
        seed.weightKg?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '';
    ageYearsController.text = seed.ageYears?.toString() ?? '';

    trainingMonths = seed.trainingMonths;
    trainingLevelDerived = seed.trainingLevelDerived;
    if (trainingMonths != null && trainingMonths! > 0) {
      if (trainingMonths! % 12 == 0) {
        trainingDurationUnit = TrainingDurationUnit.years;
        trainingDurationController.text = (trainingMonths! ~/ 12).toString();
      } else {
        trainingDurationUnit = TrainingDurationUnit.months;
        trainingDurationController.text = trainingMonths!.toString();
      }
    } else {
      trainingDurationUnit = TrainingDurationUnit.months;
      trainingDurationController.clear();
    }

    strengthLevelClass = seed.strengthLevelClass;
    workCapacityScore = seed.workCapacityScore;
    recoveryHistoryScore = seed.recoveryHistoryScore;
    externalRecoverySupport = seed.externalRecoverySupport;
    programNoveltyClass = seed.programNoveltyClass;
    externalPhysicalStressLevel = seed.externalPhysicalStressLevel;
    nonPhysicalStressLevel2 = seed.nonPhysicalStressLevel2;
    restQuality2 = seed.restQuality2;
    dietHabitsClass = seed.dietHabitsClass;
    usesAnabolics = seed.usesAnabolics;

    injuryRegions
      ..clear()
      ..addAll(seed.injuryRegions);
    injuryPatternByRegion
      ..clear()
      ..addAll(seed.injuryPatternByRegion);
    injurySeverity = seed.injurySeverity;
    injuryStatus = seed.injuryStatus;

    backFocus = seed.backFocus;
    priorityMusclesPrimary
      ..clear()
      ..addAll(seed.priorityMusclesPrimary);
    priorityMusclesSecondary
      ..clear()
      ..addAll(seed.priorityMusclesSecondary);
    priorityMusclesTertiary
      ..clear()
      ..addAll(seed.priorityMusclesTertiary);
  }

  void setTrainingDurationUnit(TrainingDurationUnit unit) {
    trainingDurationUnit = unit;
  }

  void setTrainingDurationFromText(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      trainingMonths = null;
      trainingLevelDerived = null;
      return;
    }

    final unit = switch (trainingDurationUnit) {
      TrainingDurationUnit.months => 'months',
      TrainingDurationUnit.years => 'years',
    };
    trainingMonths = toTrainingMonths(value: parsed, unit: unit);
    trainingLevelDerived = deriveTrainingLevelFromMonths(trainingMonths!);
  }

  String? validateLocal() {
    final height = double.tryParse(
      heightCmController.text.trim().replaceAll(',', '.'),
    );
    final weight = double.tryParse(
      weightKgController.text.trim().replaceAll(',', '.'),
    );
    final age = int.tryParse(ageYearsController.text.trim());

    if (height == null || height <= 0) return 'Estatura requerida';
    if (weight == null || weight <= 0) return 'Peso requerido';
    if (age == null || age <= 0) return 'Edad requerida';
    if (trainingMonths == null || trainingMonths! <= 0) {
      return 'Tiempo entrenando requerido';
    }
    if (strengthLevelClass == null) return 'Nivel de fuerza requerido';
    if (workCapacityScore == null) return 'Capacidad de trabajo requerida';
    if (recoveryHistoryScore == null) {
      return 'Historial de recuperación requerido';
    }
    if (externalRecoverySupport == null) return 'Apoyo externo requerido';
    if (programNoveltyClass == null) return 'Novedad del programa requerida';
    if (externalPhysicalStressLevel == null) {
      return 'Desgaste físico externo requerido';
    }
    if (nonPhysicalStressLevel2 == null) return 'Estrés no físico requerido';
    if (restQuality2 == null) return 'Descanso requerido';
    if (dietHabitsClass == null) return 'Estado energético requerido';
    if (usesAnabolics == null) return 'Uso de anabólicos requerido';
    return null;
  }

  double? get heightCm =>
      double.tryParse(heightCmController.text.trim().replaceAll(',', '.'));

  double? get weightKg =>
      double.tryParse(weightKgController.text.trim().replaceAll(',', '.'));

  int? get ageYears => int.tryParse(ageYearsController.text.trim());

  TrainingInterviewFormValues toValues({Gender? sex}) {
    return TrainingInterviewFormValues(
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      ageYears: ageYears,
      trainingMonths: trainingMonths,
      trainingLevelDerived: trainingLevelDerived,
      strengthLevelClass: strengthLevelClass,
      workCapacityScore: workCapacityScore,
      recoveryHistoryScore: recoveryHistoryScore,
      externalRecoverySupport: externalRecoverySupport,
      programNoveltyClass: programNoveltyClass,
      externalPhysicalStressLevel: externalPhysicalStressLevel,
      nonPhysicalStressLevel2: nonPhysicalStressLevel2,
      restQuality2: restQuality2,
      dietHabitsClass: dietHabitsClass,
      usesAnabolics: usesAnabolics,
      injuryRegions: injuryRegions.toSet(),
      injuryPatternByRegion: Map<String, String>.from(injuryPatternByRegion),
      injurySeverity: injurySeverity,
      injuryStatus: injuryStatus,
      backFocus: backFocus,
      priorityMusclesPrimary: List<String>.from(priorityMusclesPrimary),
      priorityMusclesSecondary: List<String>.from(priorityMusclesSecondary),
      priorityMusclesTertiary: List<String>.from(priorityMusclesTertiary),
    );
  }
}
