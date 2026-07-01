import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NoopClientRemoteDataSource implements ClientRemoteDataSource {
  @override
  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
    int? limit,
  }) async {
    return const [];
  }

  @override
  Future<void> upsertClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {}

  @override
  Future<void> upsertClientMeta({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> metaData,
  }) async {}
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ClientsProvider hardening', () {
    test('granular helpers preserve unrelated client sections', () async {
      final base = _clientFixture(id: 'provider-hardening-1');
      await DatabaseHelper.instance.upsertClient(base);
      await DatabaseHelper.instance.setActiveClientId(base.id);

      final local = LocalClientDataSourceImpl(DatabaseHelper.instance);
      final repository = ClientRepository(
        local: local,
        remote: _NoopClientRemoteDataSource(),
        currentCoachIdProvider: () => null,
        remotePushDebounceDuration: const Duration(hours: 1),
      );
      final container = ProviderContainer(
        overrides: [clientRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(clientsProvider.future);
      final notifier = container.read(clientsProvider.notifier);

      await notifier.updateActiveClientNutrition((previous) {
        final extra = Map<String, dynamic>.from(previous.extra);
        extra['mealPlanRecords'] = const ['nutrition-only'];
        return previous.copyWith(extra: extra, kcal: 2400);
      });

      final afterNutrition = await DatabaseHelper.instance.getClientById(
        base.id,
      );
      expect(afterNutrition, isNotNull);
      expect(afterNutrition!.nutrition.kcal, 2400);
      expect(afterNutrition.nutrition.extra['mealPlanRecords'], [
        'nutrition-only',
      ]);
      expect(afterNutrition.profile.fullName, base.profile.fullName);
      expect(afterNutrition.history.medications, base.history.medications);
      expect(afterNutrition.training.competitionCategory, 'Base category');
      expect(afterNutrition.trainingPlans, base.trainingPlans);
      expect(afterNutrition.trainingWeeks, base.trainingWeeks);
      expect(afterNutrition.trainingSessions, base.trainingSessions);

      await notifier.updateActiveClientProfile(
        (previous) => previous.copyWith(fullName: 'Profile patched'),
      );
      final afterProfile = await DatabaseHelper.instance.getClientById(base.id);
      expect(afterProfile!.profile.fullName, 'Profile patched');
      expect(afterProfile.history.medications, base.history.medications);
      expect(afterProfile.nutrition.kcal, 2400);
      expect(afterProfile.training.competitionCategory, 'Base category');

      await notifier.updateActiveClientHistory(
        (previous) => previous.copyWith(medications: 'History patched'),
      );
      final afterHistory = await DatabaseHelper.instance.getClientById(base.id);
      expect(afterHistory!.history.medications, 'History patched');
      expect(afterHistory.profile.fullName, 'Profile patched');
      expect(afterHistory.nutrition.kcal, 2400);
      expect(afterHistory.training.competitionCategory, 'Base category');

      await notifier.updateActiveClientTraining(
        (previous) => previous.copyWith(competitionCategory: 'Training patched'),
      );
      final afterTraining = await DatabaseHelper.instance.getClientById(
        base.id,
      );
      expect(afterTraining!.training.competitionCategory, 'Training patched');
      expect(afterTraining.profile.fullName, 'Profile patched');
      expect(afterTraining.history.medications, 'History patched');
      expect(afterTraining.nutrition.kcal, 2400);
    });

    test('history clinic viewmodel does not expose legacy wide saveClient', () {
      final source = _read(
        'lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart',
      );

      expect(source, isNot(contains('saveClient' '(Client updated)')));
    });

    test('main shell does not remerge history clinic snapshots', () {
      final source = _read(
        'lib/features/main_shell/screen/main_shell_screen.dart',
      );

      expect(source, isNot(contains(_wideMerge('client', 'profile'))));
      expect(source, isNot(contains(_wideMerge('client', 'history'))));
    });

    test('training interview saves with granular previous-based patch', () {
      final source = _read(
        'lib/features/training_feature/tabs/training_interview_tab.dart',
      );

      expect(source, isNot(contains('training: updatedClient.training')));
      expect(
        source,
        isNot(contains('prev.copyWith(training: updatedClient.training)')),
      );
      expect(source, contains('updateActiveClientTraining(applyInterviewPatch)'));
      expect(source, contains('base: previous'));
    });

    test('meal plan does not use history clinic viewmodel', () {
      final source = _read(
        'lib/features/meal_plan_feature/screen/meal_plan_screen.dart',
      );

      expect(source, isNot(contains(_historyVmProviderSymbol)));
    });

    test('migrated clinical tabs keep void save contract', () {
      const tabPaths = <String>[
        'lib/features/history_clinic_feature/tabs/personal_data_tab.dart',
        'lib/features/history_clinic_feature/tabs/background_tab.dart',
        'lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart',
        'lib/features/history_clinic_feature/tabs/gyneco_tab.dart',
      ];

      for (final path in tabPaths) {
        final source = _read(path);
        expect(source, contains('Future<void> saveIfDirty()'));
        expect(source, isNot(contains('Future<Client?> saveIfDirty()')));
      }
    });
  });
}

Client _clientFixture({required String id}) {
  return Client(
    id: id,
    profile: const ClientProfile(
      id: 'profile-provider-hardening',
      fullName: 'Base profile',
      email: 'base@example.com',
      phone: '000',
      country: 'Mexico',
      occupation: 'Coach',
      objective: 'Base objective',
    ),
    history: const ClinicalHistory(medications: 'Base medications'),
    training: const TrainingProfile(
      isCompetitor: true,
      competitionCategory: 'Base category',
    ),
    nutrition: const NutritionSettings(kcal: 2000),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

String _read(String path) => File(path).readAsStringSync();

String _wideMerge(String object, String field) => '$field: $object.$field';

String get _historyVmProviderSymbol =>
    ['history', 'Clinic', 'Vm', 'Provider'].join();
