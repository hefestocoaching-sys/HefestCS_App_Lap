import 'package:collection/collection.dart';
import 'package:hcs_app_lap/core/constants/history_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

const _deepEquals = DeepCollectionEquality();

const _backgroundHistoryExtraKeys = <String>[
  HistoryExtraKeys.hereditaryFamilyHistory,
  HistoryExtraKeys.personalPathologicalHistory,
];

const _generalHistoryExtraKeys = <String>[
  HistoryExtraKeys.foodPreferences,
  HistoryExtraKeys.supplementUse,
];

const _generalNutritionExtraKeys = <String>[
  NutritionExtraKeys.typicalDayEating,
  NutritionExtraKeys.typicalDayEatingEntries,
  NutritionExtraKeys.dietHistory,
  NutritionExtraKeys.supplementsPre,
  NutritionExtraKeys.supplementsIntra,
  NutritionExtraKeys.supplementsPost,
  NutritionExtraKeys.supplementsHealth,
  NutritionExtraKeys.preferredMealsPerDay,
  NutritionExtraKeys.weekdayCookingTime,
  NutritionExtraKeys.weekendCookingTime,
  NutritionExtraKeys.foodAccess,
  NutritionExtraKeys.budgetLevel,
  NutritionExtraKeys.eatingBehaviorNotes,
];

const _gynecoHistoryExtraKeys = <String>[
  HistoryExtraKeys.menstrualStatus,
  HistoryExtraKeys.usesHormonalContraceptives,
  HistoryExtraKeys.contraceptiveType,
  HistoryExtraKeys.pregnancyHistory,
  HistoryExtraKeys.weeksGestationOrPostpartum,
  HistoryExtraKeys.birthType,
];

bool shouldRunLegacyHistoryMerge(Iterable<Client?> tabResults) =>
    tabResults.any((result) => result != null);

Client applyPersonalDataTabPatch({
  required Client activeClient,
  required ClientProfile baseProfile,
  required ClientProfile draftProfile,
  required NutritionSettings baseNutrition,
  required NutritionSettings draftNutrition,
  String? invitationCode,
}) {
  var profile = activeClient.profile;
  if (draftProfile.fullName != baseProfile.fullName) {
    profile = profile.copyWith(fullName: draftProfile.fullName);
  }
  if (draftProfile.email != baseProfile.email) {
    profile = profile.copyWith(email: draftProfile.email);
  }
  if (draftProfile.phone != baseProfile.phone) {
    profile = profile.copyWith(phone: draftProfile.phone);
  }
  if (draftProfile.birthDate != baseProfile.birthDate) {
    profile = profile.copyWith(birthDate: draftProfile.birthDate);
  }
  if (draftProfile.age != baseProfile.age) {
    profile = profile.copyWith(age: draftProfile.age);
  }
  if (draftProfile.gender != baseProfile.gender) {
    profile = profile.copyWith(gender: draftProfile.gender);
  }
  if (draftProfile.country != baseProfile.country) {
    profile = profile.copyWith(country: draftProfile.country);
  }
  if (draftProfile.occupation != baseProfile.occupation) {
    profile = profile.copyWith(occupation: draftProfile.occupation);
  }
  if (draftProfile.level != baseProfile.level) {
    profile = profile.copyWith(level: draftProfile.level);
  }
  if (draftProfile.objective != baseProfile.objective) {
    profile = profile.copyWith(objective: draftProfile.objective);
  }

  var nutrition = activeClient.nutrition;
  if (draftNutrition.planType != baseNutrition.planType) {
    nutrition = nutrition.copyWith(planType: draftNutrition.planType);
  }
  if (draftNutrition.planStartDate != baseNutrition.planStartDate) {
    nutrition = nutrition.copyWith(planStartDate: draftNutrition.planStartDate);
  }
  if (draftNutrition.planEndDate != baseNutrition.planEndDate) {
    nutrition = nutrition.copyWith(planEndDate: draftNutrition.planEndDate);
  }

  return activeClient.copyWith(
    profile: profile,
    nutrition: nutrition,
    invitationCode: invitationCode ?? activeClient.invitationCode,
  );
}

Client applyBackgroundTabPatch({
  required Client activeClient,
  required ClinicalHistory baseHistory,
  required ClinicalHistory draftHistory,
}) {
  return activeClient.copyWith(
    history: _copyHistoryWithChangedExtraKeys(
      activeClient.history,
      baseHistory,
      draftHistory,
      _backgroundHistoryExtraKeys,
    ),
  );
}

Client applyGeneralEvaluationTabPatch({
  required Client activeClient,
  required ClinicalHistory baseHistory,
  required ClinicalHistory draftHistory,
  required NutritionSettings baseNutrition,
  required NutritionSettings draftNutrition,
  required TrainingProfile baseTraining,
  required TrainingProfile draftTraining,
}) {
  var history = activeClient.history;
  if (draftHistory.allergies != baseHistory.allergies) {
    history = history.copyWith(allergies: draftHistory.allergies);
  }
  if (draftHistory.medications != baseHistory.medications) {
    history = history.copyWith(medications: draftHistory.medications);
  }
  history = _copyHistoryWithChangedExtraKeys(
    history,
    baseHistory,
    draftHistory,
    _generalHistoryExtraKeys,
  );

  final nutrition = _copyNutritionWithChangedExtraKeys(
    activeClient.nutrition,
    baseNutrition,
    draftNutrition,
    _generalNutritionExtraKeys,
  );

  var training = activeClient.training;
  if (draftTraining.isCompetitor != baseTraining.isCompetitor) {
    training = training.copyWith(isCompetitor: draftTraining.isCompetitor);
  }
  if (draftTraining.competitionCategory != baseTraining.competitionCategory) {
    training = training.copyWith(
      competitionCategory: draftTraining.competitionCategory,
    );
  }
  if (draftTraining.pharmacologyProtocol != baseTraining.pharmacologyProtocol) {
    training = training.copyWith(
      pharmacologyProtocol: draftTraining.pharmacologyProtocol,
    );
  }
  if (draftTraining.peakWeekHistory != baseTraining.peakWeekHistory) {
    training = training.copyWith(
      peakWeekHistory: draftTraining.peakWeekHistory,
    );
  }

  return activeClient.copyWith(
    history: history,
    nutrition: nutrition,
    training: training,
  );
}

Client applyGynecoTabPatch({
  required Client activeClient,
  required ClinicalHistory baseHistory,
  required ClinicalHistory draftHistory,
}) {
  var history = activeClient.history;
  if (draftHistory.isBreastfeeding != baseHistory.isBreastfeeding) {
    history = history.copyWith(isBreastfeeding: draftHistory.isBreastfeeding);
  }
  if (!_deepEquals.equals(
    draftHistory.cycleRelatedSymptoms,
    baseHistory.cycleRelatedSymptoms,
  )) {
    history = history.copyWith(
      cycleRelatedSymptoms: draftHistory.cycleRelatedSymptoms == null
          ? null
          : List<String>.from(draftHistory.cycleRelatedSymptoms!),
    );
  }
  if (draftHistory.specificGynecoConditions !=
      baseHistory.specificGynecoConditions) {
    history = history.copyWith(
      specificGynecoConditions: draftHistory.specificGynecoConditions,
    );
  }

  return activeClient.copyWith(
    history: _copyHistoryWithChangedExtraKeys(
      history,
      baseHistory,
      draftHistory,
      _gynecoHistoryExtraKeys,
    ),
  );
}

String personalDataTabRevision(Client client) {
  final profile = client.profile;
  final nutrition = client.nutrition;
  return _revision([
    client.id,
    profile.fullName,
    profile.email,
    profile.phone,
    profile.birthDate,
    profile.age,
    profile.gender?.name,
    profile.country,
    profile.occupation,
    profile.level?.name,
    profile.objective,
    nutrition.planType,
    nutrition.planStartDate,
    nutrition.planEndDate,
  ]);
}

String backgroundTabRevision(Client client) => _revision([
  client.id,
  ..._backgroundHistoryExtraKeys.map((key) => client.history.extra[key]),
]);

String generalEvaluationTabRevision(Client client) => _revision([
  client.id,
  client.history.allergies,
  client.history.medications,
  ..._generalHistoryExtraKeys.map((key) => client.history.extra[key]),
  ..._generalNutritionExtraKeys.map((key) => client.nutrition.extra[key]),
  client.training.isCompetitor,
  client.training.competitionCategory,
  client.training.pharmacologyProtocol,
  client.training.peakWeekHistory,
]);

String gynecoTabRevision(Client client) => _revision([
  client.id,
  client.history.isBreastfeeding,
  client.history.cycleRelatedSymptoms,
  client.history.specificGynecoConditions,
  ..._gynecoHistoryExtraKeys.map((key) => client.history.extra[key]),
]);

ClinicalHistory _copyHistoryWithChangedExtraKeys(
  ClinicalHistory activeHistory,
  ClinicalHistory baseHistory,
  ClinicalHistory draftHistory,
  Iterable<String> keys,
) {
  var changed = false;
  final extra = Map<String, dynamic>.from(activeHistory.extra);
  for (final key in keys) {
    if (_deepEquals.equals(baseHistory.extra[key], draftHistory.extra[key])) {
      continue;
    }
    extra[key] = _cloneValue(draftHistory.extra[key]);
    changed = true;
  }
  return changed ? activeHistory.copyWith(extra: extra) : activeHistory;
}

NutritionSettings _copyNutritionWithChangedExtraKeys(
  NutritionSettings activeNutrition,
  NutritionSettings baseNutrition,
  NutritionSettings draftNutrition,
  Iterable<String> keys,
) {
  var changed = false;
  final extra = Map<String, dynamic>.from(activeNutrition.extra);
  for (final key in keys) {
    if (_deepEquals.equals(
      baseNutrition.extra[key],
      draftNutrition.extra[key],
    )) {
      continue;
    }
    extra[key] = _cloneValue(draftNutrition.extra[key]);
    changed = true;
  }
  return changed ? activeNutrition.copyWith(extra: extra) : activeNutrition;
}

String _revision(Iterable<Object?> values) =>
    values.map(_stableValue).join('|');

String _stableValue(Object? value) {
  if (value == null) return '<null>';
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return '{${entries.map((e) => '${e.key}:${_stableValue(e.value)}').join(',')}}';
  }
  if (value is Iterable) {
    return '[${value.map(_stableValue).join(',')}]';
  }
  return value.toString();
}

dynamic _cloneValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), _cloneValue(value)),
    );
  }
  if (value is List) {
    return value.map(_cloneValue).toList();
  }
  return value;
}
