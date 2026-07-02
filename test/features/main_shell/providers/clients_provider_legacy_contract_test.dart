import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
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

class _InMemoryClientRepository extends ClientRepository {
  _InMemoryClientRepository(Iterable<Client> clients)
    : _clients = {for (final client in clients) client.id: client},
      super(
        local: _NeverUsedLocalClientDataSource(),
        remote: _NoopClientRemoteDataSource(),
        currentCoachIdProvider: () => null,
      );

  final Map<String, Client> _clients;

  @override
  Future<List<Client>> getClients() async => _clients.values.toList();

  @override
  Future<Client?> getClientById(String id) async => _clients[id];

  @override
  Future<void> saveClient(Client client) async {
    _clients[client.id] = client;
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

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ClientsProvider legacy contract', () {
    test('updateActiveClient no longer depends on the legacy feature flag', () {
      final source = File(
        'lib/features/main_shell/providers/clients_provider.dart',
      ).readAsStringSync();

      final updateBlock = _extractMethodBody(
        source,
        'Future<void> updateActiveClient(Client Function(Client) transform) async',
      );

      expect(
        updateBlock,
        isNot(contains('FeatureFlags.useLegacyClientUpdate')),
      );
      expect(
        updateBlock,
        contains('return UpdateLock.instance.safeClientUpdate'),
      );
      expect(updateBlock, isNot(contains('_updateActiveClientLegacy')));
    });

    test('legacy wide merge helper is removed from the provider flow', () {
      final source = File(
        'lib/features/main_shell/providers/clients_provider.dart',
      ).readAsStringSync();

      expect(
        source,
        isNot(contains('Future<void> _updateActiveClientLegacy(')),
      );
      expect(source, isNot(contains('FeatureFlags.useLegacyClientUpdate')));
    });

    test(
      'granular update preserves unrelated sections on active client',
      () async {
        final base = _clientFixture(id: 'legacy-contract-1');
        await DatabaseHelper.instance.upsertClient(base);
        await DatabaseHelper.instance.setActiveClientId(base.id);

        final repository = _InMemoryClientRepository([base]);
        final container = ProviderContainer(
          overrides: [clientRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container.read(clientsProvider.future);
        final notifier = container.read(clientsProvider.notifier);

        await notifier.updateActiveClient((prev) {
          final training = prev.training.copyWith(
            extra: {...prev.training.extra, 'macroBlock': 'granular'},
          );
          return prev.copyWith(
            profile: prev.profile.copyWith(fullName: 'Patched profile'),
            training: training,
          );
        });

        final updated = await repository.getClientById(base.id);
        expect(updated, isNotNull);
        expect(updated!.profile.fullName, 'Patched profile');
        expect(updated.training.extra['macroBlock'], 'granular');
        expect(updated.history.medications, base.history.medications);
        expect(updated.nutrition.kcal, base.nutrition.kcal);
      },
    );
  });
}

String _extractMethodBody(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNonNegative);
  final braceStart = source.indexOf('{', start);
  expect(braceStart, isNonNegative);

  var depth = 0;
  for (var index = braceStart; index < source.length; index++) {
    final char = source[index];
    if (char == '{') depth++;
    if (char == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(braceStart, index + 1);
      }
    }
  }

  fail('Could not extract method body for $signature');
}

Client _clientFixture({required String id}) {
  return Client(
    id: id,
    profile: const ClientProfile(
      id: 'profile-legacy-contract',
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
