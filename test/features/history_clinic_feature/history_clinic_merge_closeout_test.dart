import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/constants/history_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart';

void main() {
  group('history clinic merge closeout', () {
    test('clinical tab patches preserve unrelated sections', () {
      final base = _clientFixture(
        profile: _profileFixture(fullName: 'Base', phone: '111'),
        history: const ClinicalHistory(
          medications: 'Ninguno',
          specificGynecoConditions: 'SOP',
          extra: {
            HistoryExtraKeys.hereditaryFamilyHistory: ['Hipertension'],
            HistoryExtraKeys.foodPreferences: 'Sin lacteos',
            HistoryExtraKeys.menstrualStatus: 'Regular',
          },
        ),
        nutrition: const NutritionSettings(
          extra: {NutritionExtraKeys.dietHistory: 'Base'},
        ),
      );

      final afterPersonal = applyPersonalDataTabPatch(
        activeClient: base.copyWith(
          history: base.history.copyWith(
            extra: {
              ...base.history.extra,
              HistoryExtraKeys.hereditaryFamilyHistory: ['Diabetes'],
            },
          ),
        ),
        baseProfile: base.profile,
        draftProfile: base.profile.copyWith(fullName: 'Personal edit'),
        baseNutrition: base.nutrition,
        draftNutrition: base.nutrition,
      );
      expect(afterPersonal.profile.fullName, 'Personal edit');
      expect(
        afterPersonal.history.extra[HistoryExtraKeys.hereditaryFamilyHistory],
        ['Diabetes'],
      );

      final afterBackground = applyBackgroundTabPatch(
        activeClient: base.copyWith(
          profile: base.profile.copyWith(phone: '999'),
        ),
        baseHistory: base.history,
        draftHistory: base.history.copyWith(
          extra: {
            ...base.history.extra,
            HistoryExtraKeys.hereditaryFamilyHistory: ['Cancer'],
          },
        ),
      );
      expect(afterBackground.profile.phone, '999');
      expect(
        afterBackground.history.extra[HistoryExtraKeys.hereditaryFamilyHistory],
        ['Cancer'],
      );

      final afterGeneral = applyGeneralEvaluationTabPatch(
        activeClient: base.copyWith(
          history: base.history.copyWith(
            specificGynecoConditions: 'Endometriosis',
            extra: {
              ...base.history.extra,
              HistoryExtraKeys.menstrualStatus: 'Irregular',
            },
          ),
        ),
        baseHistory: base.history,
        draftHistory: base.history.copyWith(medications: 'Metformina'),
        baseNutrition: base.nutrition,
        draftNutrition: base.nutrition.copyWith(
          extra: {
            ...base.nutrition.extra,
            NutritionExtraKeys.dietHistory: 'General edit',
          },
        ),
        baseTraining: base.training,
        draftTraining: base.training,
      );
      expect(afterGeneral.history.medications, 'Metformina');
      expect(afterGeneral.history.specificGynecoConditions, 'Endometriosis');
      expect(
        afterGeneral.history.extra[HistoryExtraKeys.menstrualStatus],
        'Irregular',
      );

      final afterGyneco = applyGynecoTabPatch(
        activeClient: base.copyWith(
          history: base.history.copyWith(medications: 'Levotiroxina'),
          nutrition: base.nutrition.copyWith(
            extra: {
              ...base.nutrition.extra,
              NutritionExtraKeys.dietHistory: 'General fresh',
            },
          ),
        ),
        baseHistory: base.history,
        draftHistory: base.history.copyWith(
          specificGynecoConditions: 'Miomas',
        ),
      );
      expect(afterGyneco.history.specificGynecoConditions, 'Miomas');
      expect(afterGyneco.history.medications, 'Levotiroxina');
      expect(
        afterGyneco.nutrition.extra[NutritionExtraKeys.dietHistory],
        'General fresh',
      );
    });

    test('history clinic wide merge is not used for migrated tabs', () {
      expect(shouldRunLegacyHistoryMerge([null, null, null, null]), isFalse);
      expect(
        shouldRunLegacyHistoryMerge([null, _clientFixture(), null]),
        isTrue,
      );
    });

    test('clinical revisions change only on relevant fields', () {
      final base = _clientFixture();
      final personalChanged = base.copyWith(
        profile: base.profile.copyWith(fullName: 'Personal changed'),
      );
      final backgroundChanged = base.copyWith(
        history: base.history.copyWith(
          extra: {
            ...base.history.extra,
            HistoryExtraKeys.hereditaryFamilyHistory: ['Diabetes'],
          },
        ),
      );
      final generalChanged = base.copyWith(
        history: base.history.copyWith(medications: 'Metformina'),
      );
      final gynecoChanged = base.copyWith(
        history: base.history.copyWith(specificGynecoConditions: 'SOP'),
      );

      expect(
        personalDataTabRevision(personalChanged),
        isNot(personalDataTabRevision(base)),
      );
      expect(
        personalDataTabRevision(backgroundChanged),
        personalDataTabRevision(base),
      );

      expect(
        backgroundTabRevision(backgroundChanged),
        isNot(backgroundTabRevision(base)),
      );
      expect(backgroundTabRevision(personalChanged), backgroundTabRevision(base));

      expect(
        generalEvaluationTabRevision(generalChanged),
        isNot(generalEvaluationTabRevision(base)),
      );
      expect(
        generalEvaluationTabRevision(gynecoChanged),
        generalEvaluationTabRevision(base),
      );

      expect(gynecoTabRevision(gynecoChanged), isNot(gynecoTabRevision(base)));
      expect(gynecoTabRevision(generalChanged), gynecoTabRevision(base));
    });
  });
}

Client _clientFixture({
  String id = 'client-1',
  ClientProfile? profile,
  ClinicalHistory? history,
  NutritionSettings nutrition = const NutritionSettings(),
  TrainingProfile? training,
}) {
  return Client(
    id: id,
    profile: profile ?? _profileFixture(),
    history:
        history ??
        const ClinicalHistory(
          extra: {
            HistoryExtraKeys.hereditaryFamilyHistory: ['Hipertension'],
            HistoryExtraKeys.foodPreferences: 'Sin lacteos',
            HistoryExtraKeys.menstrualStatus: 'Regular',
          },
        ),
    training: training ?? TrainingProfile.empty(),
    nutrition: nutrition,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

ClientProfile _profileFixture({
  String fullName = 'Paciente base',
  String email = 'base@example.com',
  String phone = '555-base',
}) {
  return ClientProfile(
    id: 'profile-1',
    fullName: fullName,
    email: email,
    phone: phone,
    country: 'Mexico',
    occupation: 'Coach',
    objective: 'Salud general',
    gender: Gender.female,
  );
}
