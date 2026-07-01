import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
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

class _InMemoryClientRepository extends ClientRepository {
  _InMemoryClientRepository(Iterable<Client> clients)
    : _clients = {for (final client in clients) client.id: client},
      super(
        local: _NeverUsedLocalClientDataSource(),
        remote: _NoopClientRemoteDataSource(),
        currentCoachIdProvider: () => null,
      );

  final Map<String, Client> _clients;
  int saveCalls = 0;

  @override
  Future<List<Client>> getClients() async => _clients.values.toList();

  @override
  Future<Client?> getClientById(String id) async => _clients[id];

  @override
  Future<void> saveClient(Client client) async {
    saveCalls++;
    _clients[client.id] = client.copyWith(
      updatedAt: DateTime.utc(2026, 1, 1, 0, 0, saveCalls),
    );
  }

  @override
  Future<void> deleteClient(String id) async {
    _clients.remove(id);
  }
}

class _NeverUsedLocalClientDataSource implements LocalClientDataSource {
  Never _unused() => throw UnsupportedError('Not used by this test');

  @override
  Future<void> deleteClient(String id) => _unused();

  @override
  Future<ClientOutboxWrite> deleteClientWithOutbox(Client client) => _unused();

  @override
  Future<Client?> fetchClient(String id) => _unused();

  @override
  Future<Client?> fetchClientIncludingDeleted(String id) => _unused();

  @override
  Future<List<Client>> getAllClients() => _unused();

  @override
  Future<List<Client>> getUnsyncedClients() => _unused();

  @override
  Future<List<Client>> getUnsyncedDeletedClients() => _unused();

  @override
  Future<void> markClientAsSynced(String id) => _unused();

  @override
  Future<void> saveClient(Client client) => _unused();

  @override
  Future<ClientOutboxWrite> saveClientWithOutbox(Client client) => _unused();
}

class _Harness {
  _Harness({required this.container, required this.repository});

  final ProviderContainer container;
  final _InMemoryClientRepository repository;

  ClientsNotifier get notifier => container.read(clientsProvider.notifier);
  ClientsState get state => container.read(clientsProvider).value!;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Client status reactivation contract', () {
    test('reactivating inactive client does not overwrite active client', () async {
      final clientA = _clientFixture(
        id: 'status-reactivate-a',
        marker: 'A',
        status: ClientStatus.active,
      );
      final clientB = _clientFixture(
        id: 'status-reactivate-b',
        marker: 'B',
        status: ClientStatus.inactive,
      );
      final harness = await _buildHarness(
        activeClient: clientA,
        secondaryClient: clientB,
      );

      final saved = await harness.notifier.updateClientStatusById(
        clientId: clientB.id,
        isActive: true,
      );

      final storedA = await harness.repository.getClientById(clientA.id);
      final storedB = await harness.repository.getClientById(clientB.id);
      expect(saved!.id, clientB.id);
      expect(storedB!.status, ClientStatus.active);
      expect(storedA!.status, ClientStatus.active);
      expect(harness.state.activeClient!.id, clientA.id);
      _expectBranches(storedA, clientA);
      _expectBranches(storedB, clientB);
    });

    test('reactivating with makeActive selects client without wide merge', () async {
      final clientA = _clientFixture(
        id: 'status-make-active-a',
        marker: 'A',
        status: ClientStatus.active,
      );
      final clientB = _clientFixture(
        id: 'status-make-active-b',
        marker: 'B',
        status: ClientStatus.inactive,
      );
      final harness = await _buildHarness(
        activeClient: clientA,
        secondaryClient: clientB,
      );

      await harness.notifier.updateClientStatusById(
        clientId: clientB.id,
        isActive: true,
        makeActive: true,
      );

      final storedA = await harness.repository.getClientById(clientA.id);
      final storedB = await harness.repository.getClientById(clientB.id);
      expect(harness.state.activeClient!.id, clientB.id);
      expect(storedB!.status, ClientStatus.active);
      expect(storedA!.status, ClientStatus.active);
      _expectBranches(storedA, clientA);
      _expectBranches(storedB, clientB);
    });

    test('deactivating selected client clears selection and preserves branches', () async {
      final clientA = _clientFixture(
        id: 'status-deactivate-a',
        marker: 'A',
        status: ClientStatus.active,
      );
      final clientB = _clientFixture(
        id: 'status-deactivate-b',
        marker: 'B',
        status: ClientStatus.active,
      );
      final harness = await _buildHarness(
        activeClient: clientA,
        secondaryClient: clientB,
      );

      await harness.notifier.updateClientStatusById(
        clientId: clientA.id,
        isActive: false,
      );

      final storedA = await harness.repository.getClientById(clientA.id);
      final storedB = await harness.repository.getClientById(clientB.id);
      expect(storedA!.status, ClientStatus.inactive);
      expect(storedB!.status, ClientStatus.active);
      expect(harness.state.activeClientId, isNull);
      expect(harness.state.activeClient, isNull);
      _expectBranches(storedA, clientA);
      _expectBranches(storedB, clientB);
    });

    test('InactiveClientsScreen does not reactivate with full snapshot', () {
      final source = File(
        'lib/features/main_shell/widgets/inactive_clients_screen.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('updateActiveClient((prev) => updatedClient)')));
      expect(source, isNot(contains('return updatedClient')));
      expect(source, isNot(contains('prev) => updatedClient')));
    });

    test('ClientsNotifier exposes status contract by id', () {
      final source = File(
        'lib/features/main_shell/providers/clients_provider.dart',
      ).readAsStringSync();

      expect(source, contains('Future<Client?> updateClientStatusById({'));
      expect(source, contains('required String clientId'));
      expect(source, contains('required bool isActive'));
      expect(source, isNot(contains('required Client updatedClient')));
      expect(source, isNot(contains('Client updatedClient')));
    });
  });
}

Future<_Harness> _buildHarness({
  required Client activeClient,
  required Client secondaryClient,
}) async {
  await DatabaseHelper.instance.setActiveClientId(activeClient.id);

  final repository = _InMemoryClientRepository([activeClient, secondaryClient]);
  final container = ProviderContainer(
    overrides: [clientRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  addTearDown(() => DatabaseHelper.instance.setActiveClientId(null));

  await container.read(clientsProvider.future);
  return _Harness(container: container, repository: repository);
}

Client _clientFixture({
  required String id,
  required String marker,
  required ClientStatus status,
}) {
  final session = TrainingSession(
    id: 'session-$marker',
    dayNumber: 1,
    sessionName: 'Session $marker',
    prescriptions: const [],
  );
  final week = TrainingWeek(
    id: 'week-$marker',
    weekNumber: 1,
    phase: TrainingPhase.accumulation,
    sessions: [session],
  );
  final plan = TrainingPlanConfig(
    id: 'plan-$marker',
    name: 'Plan $marker',
    clientId: id,
    startDate: DateTime.utc(2026),
    phase: TrainingPhase.accumulation,
    splitId: 'split-$marker',
    microcycleLengthInWeeks: 4,
    weeks: [week],
  );

  return Client(
    id: id,
    profile: ClientProfile(
      id: 'profile-$id',
      fullName: 'Client $marker',
      email: '$id@example.com',
      phone: 'phone-$marker',
      country: 'Mexico',
      occupation: 'Occupation $marker',
      objective: 'Objective $marker',
    ),
    history: ClinicalHistory(medications: 'Medication $marker'),
    training: TrainingProfile(
      isCompetitor: marker == 'A',
      competitionCategory: 'Category $marker',
    ),
    nutrition: NutritionSettings(kcal: marker == 'A' ? 2100 : 2300),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    status: status,
    trainingPlans: [plan],
    trainingWeeks: [week],
    trainingSessions: [session],
  );
}

void _expectBranches(Client actual, Client expected) {
  expect(actual.profile, expected.profile);
  expect(actual.history, expected.history);
  expect(actual.training, expected.training);
  expect(actual.nutrition, expected.nutrition);
  expect(actual.trainingPlans, expected.trainingPlans);
  expect(actual.trainingWeeks, expected.trainingWeeks);
  expect(actual.trainingSessions, expected.trainingSessions);
}
