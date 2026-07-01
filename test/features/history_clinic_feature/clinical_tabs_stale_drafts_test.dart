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
  group('clinical tab patches stale draft protection', () {
    test('personal data patch does not overwrite background changes', () {
      final base = _clientFixture(
        profile: _profileFixture(phone: '111'),
        history: const ClinicalHistory(
          extra: {
            HistoryExtraKeys.personalPathologicalHistory: ['Asma'],
          },
        ),
      );

      final staleDraftProfile = base.profile.copyWith(
        fullName: 'Paciente editada',
      );
      final current = base.copyWith(
        history: const ClinicalHistory(
          extra: {
            HistoryExtraKeys.personalPathologicalHistory: ['Diabetes'],
          },
        ),
      );

      final result = applyPersonalDataTabPatch(
        activeClient: current,
        baseProfile: base.profile,
        draftProfile: staleDraftProfile,
        baseNutrition: base.nutrition,
        draftNutrition: base.nutrition,
      );

      expect(result.profile.fullName, 'Paciente editada');
      expect(
        result.history.extra[HistoryExtraKeys.personalPathologicalHistory],
        ['Diabetes'],
      );
    });

    test('background patch does not overwrite personal data changes', () {
      final base = _clientFixture(
        profile: _profileFixture(phone: '111'),
        history: const ClinicalHistory(
          extra: {
            HistoryExtraKeys.hereditaryFamilyHistory: ['Hipertension'],
          },
        ),
      );

      final staleDraftHistory = base.history.copyWith(
        extra: {
          ...base.history.extra,
          HistoryExtraKeys.hereditaryFamilyHistory: ['Cancer'],
        },
      );
      final current = base.copyWith(
        profile: base.profile.copyWith(fullName: 'Nombre fresco', phone: '999'),
      );

      final result = applyBackgroundTabPatch(
        activeClient: current,
        baseHistory: base.history,
        draftHistory: staleDraftHistory,
      );

      expect(result.history.extra[HistoryExtraKeys.hereditaryFamilyHistory], [
        'Cancer',
      ]);
      expect(result.profile.fullName, 'Nombre fresco');
      expect(result.profile.phone, '999');
    });

    test('general evaluation patch does not overwrite gyneco changes', () {
      final base = _clientFixture(
        history: const ClinicalHistory(
          medications: 'Ninguno',
          extra: {
            HistoryExtraKeys.foodPreferences: 'Sin preferencia',
            HistoryExtraKeys.menstrualStatus: 'Regular',
          },
        ),
        nutrition: const NutritionSettings(
          extra: {NutritionExtraKeys.dietHistory: 'Ninguna'},
        ),
      );

      final staleDraftHistory = base.history.copyWith(
        medications: 'Metformina',
        extra: {
          ...base.history.extra,
          HistoryExtraKeys.foodPreferences: 'Prefiere arroz',
        },
      );
      final staleDraftNutrition = base.nutrition.copyWith(
        extra: {
          ...base.nutrition.extra,
          NutritionExtraKeys.dietHistory: 'Hipocalorica previa',
        },
      );
      const staleDraftTraining = TrainingProfile(
        isCompetitor: true,
        competitionCategory: 'Bikini wellness',
      );
      final current = base.copyWith(
        history: base.history.copyWith(
          specificGynecoConditions: 'SOP',
          extra: {
            ...base.history.extra,
            HistoryExtraKeys.menstrualStatus: 'Irregular',
          },
        ),
      );

      final result = applyGeneralEvaluationTabPatch(
        activeClient: current,
        baseHistory: base.history,
        draftHistory: staleDraftHistory,
        baseNutrition: base.nutrition,
        draftNutrition: staleDraftNutrition,
        baseTraining: base.training,
        draftTraining: staleDraftTraining,
      );

      expect(result.history.medications, 'Metformina');
      expect(
        result.nutrition.extra[NutritionExtraKeys.dietHistory],
        'Hipocalorica previa',
      );
      expect(result.training.isCompetitor, isTrue);
      expect(result.training.competitionCategory, 'Bikini wellness');
      expect(result.history.specificGynecoConditions, 'SOP');
      expect(
        result.history.extra[HistoryExtraKeys.menstrualStatus],
        'Irregular',
      );
    });

    test('gyneco patch does not overwrite general evaluation changes', () {
      final base = _clientFixture(
        history: const ClinicalHistory(
          medications: 'Ninguno',
          extra: {
            HistoryExtraKeys.foodPreferences: 'Sin preferencia',
            HistoryExtraKeys.menstrualStatus: 'Regular',
          },
        ),
        nutrition: const NutritionSettings(
          extra: {NutritionExtraKeys.dietHistory: 'Ninguna'},
        ),
        training: TrainingProfile.empty(),
      );

      final staleDraftHistory = base.history.copyWith(
        specificGynecoConditions: 'Endometriosis',
        extra: {
          ...base.history.extra,
          HistoryExtraKeys.menstrualStatus: 'Ausente (Amenorrea)',
        },
      );
      final current = base.copyWith(
        history: base.history.copyWith(
          medications: 'Levotiroxina',
          extra: {
            ...base.history.extra,
            HistoryExtraKeys.foodPreferences: 'Sin lacteos',
          },
        ),
        nutrition: base.nutrition.copyWith(
          extra: {
            ...base.nutrition.extra,
            NutritionExtraKeys.dietHistory: 'Cetogenica previa',
          },
        ),
        training: const TrainingProfile(
          isCompetitor: true,
          competitionCategory: 'Figure',
        ),
      );

      final result = applyGynecoTabPatch(
        activeClient: current,
        baseHistory: base.history,
        draftHistory: staleDraftHistory,
      );

      expect(result.history.specificGynecoConditions, 'Endometriosis');
      expect(
        result.history.extra[HistoryExtraKeys.menstrualStatus],
        'Ausente (Amenorrea)',
      );
      expect(result.history.medications, 'Levotiroxina');
      expect(
        result.history.extra[HistoryExtraKeys.foodPreferences],
        'Sin lacteos',
      );
      expect(
        result.nutrition.extra[NutritionExtraKeys.dietHistory],
        'Cetogenica previa',
      );
      expect(result.training.competitionCategory, 'Figure');
    });

    test('personalDataTabRevision changes when personal data changes', () {
      final a = _clientFixture(
        profile: _profileFixture(fullName: 'Paciente A'),
      );
      final b = _clientFixture(
        profile: _profileFixture(fullName: 'Paciente B'),
      );

      expect(personalDataTabRevision(a), isNot(personalDataTabRevision(b)));
    });

    test('backgroundTabRevision changes when background changes', () {
      final a = _clientFixture(
        history: const ClinicalHistory(
          extra: {
            HistoryExtraKeys.hereditaryFamilyHistory: ['Hipertension'],
          },
        ),
      );
      final b = _clientFixture(
        history: const ClinicalHistory(
          extra: {
            HistoryExtraKeys.hereditaryFamilyHistory: ['Diabetes'],
          },
        ),
      );

      expect(backgroundTabRevision(a), isNot(backgroundTabRevision(b)));
    });

    test(
      'generalEvaluationTabRevision changes when general evaluation changes',
      () {
        final a = _clientFixture(
          history: const ClinicalHistory(medications: 'Ninguno'),
        );
        final b = _clientFixture(
          history: const ClinicalHistory(medications: 'Metformina'),
        );

        expect(
          generalEvaluationTabRevision(a),
          isNot(generalEvaluationTabRevision(b)),
        );
      },
    );

    test('gynecoTabRevision changes when gyneco changes', () {
      final a = _clientFixture(
        history: const ClinicalHistory(specificGynecoConditions: 'SOP'),
      );
      final b = _clientFixture(
        history: const ClinicalHistory(
          specificGynecoConditions: 'Endometriosis',
        ),
      );

      expect(gynecoTabRevision(a), isNot(gynecoTabRevision(b)));
    });
  });
}

Client _clientFixture({
  String id = 'client-1',
  ClientProfile? profile,
  ClinicalHistory history = const ClinicalHistory(),
  NutritionSettings nutrition = const NutritionSettings(),
  TrainingProfile? training,
}) {
  return Client(
    id: id,
    profile: profile ?? _profileFixture(),
    history: history,
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
