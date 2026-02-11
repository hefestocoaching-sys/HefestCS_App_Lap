import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/client_level.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_focus.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/constants/history_extra_keys.dart';

final Client placeholderClient = Client(
  id: 'placeholder_id',
  profile: ClientProfile(
    id: 'placeholder_id',
    fullName: 'Nuevo Cliente',
    email: 'cliente@ejemplo.com',
    phone: '',
    birthDate: DateTime(1995),
    gender: Gender.male,
    country: 'México',
    occupation: '',
    level: ClientLevel.beginner,
    objective: 'Mejorar composición corporal',
  ),
  history: const ClinicalHistory(
    extra: {
      HistoryExtraKeys.hereditaryFamilyHistory: [],
      HistoryExtraKeys.personalPathologicalHistory: [],
    },
  ),
  training: const TrainingProfile(
    id: 'default_training_profile', // ID Requerido Agregado
    globalGoal: TrainingGoal.hypertrophy,
    trainingFocus: TrainingFocus.hypertrophy,
    trainingLevel: TrainingLevel.intermediate,
    daysPerWeek: 4,
  ),
  nutrition: const NutritionSettings(weeklyMacroSettings: {}),
);
