import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NoopClientRemoteDataSource implements ClientRemoteDataSource {
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

  @override
  Future<List<RemoteClientSnapshot>> fetchClients({
    required String coachId,
    DateTime? since,
  }) async {
    return const [];
  }
}

Client buildBaseClient() {
  final profile = ClientProfile(
    id: 'p1',
    fullName: 'Concurrent',
    email: 't@example.com',
    phone: '000',
    country: 'Nowhere',
    occupation: 'Test',
    objective: 'Test',
  );

  return Client(
    id: 'concurrent_client',
    profile: profile,
    history: const ClinicalHistory(),
    training: TrainingProfile.empty(),
    nutrition: const NutritionSettings(),
  );
}

void main() {
  setUpAll(() async {
    // Ensure Flutter bindings so path_provider works
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize sqflite ffi for unit tests (used by DatabaseHelper)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('concurrent updateActiveClient merges without lost updates', () async {
    // Ensure sqflite_common_ffi is initialized (same as in main.dart behavior)
    // Import is not available at test top-level; use package function directly.
    // ignore: undefined_prefixed_name
    // Call sqfliteFfiInit and set databaseFactory in test runtime
    // (requires sqflite_common_ffi in dev deps)
    // The functions are top-level; importing package at test level is necessary.

    final base = buildBaseClient();

    // ensure DB has base client
    await DatabaseHelper.instance.upsertClient(base);
    await DatabaseHelper.instance.setActiveClientId(base.id);

    final local = LocalClientDataSourceImpl(DatabaseHelper.instance);
    final repo = ClientRepository(
      local: local,
      remote: _NoopClientRemoteDataSource(),
    );

    final container = ProviderContainer(
      overrides: [clientRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // Wait for provider to initialize and return the state
    final stateValue = await container.read(clientsProvider.future);

    final notifier = container.read(clientsProvider.notifier);

    // Ensure we have an active client
    final activeClient = stateValue.activeClient;
    expect(activeClient, isNotNull);
    expect(activeClient!.id, base.id);

    // Two concurrent updates that touch different keys of nutrition.extra
    final f1 = notifier.updateActiveClient((prev) {
      final merged = Map<String, dynamic>.from(prev.nutrition.extra);
      merged['keyA'] = 'valueA';
      return prev.copyWith(nutrition: prev.nutrition.copyWith(extra: merged));
    });

    final f2 = notifier.updateActiveClient((prev) {
      final merged = Map<String, dynamic>.from(prev.nutrition.extra);
      merged['keyB'] = 'valueB';
      return prev.copyWith(nutrition: prev.nutrition.copyWith(extra: merged));
    });

    await Future.wait([f1, f2]);

    // Read persisted client from DB
    final persisted = await DatabaseHelper.instance.getClientById(base.id);
    expect(persisted, isNotNull);
    final extra = persisted!.nutrition.extra;

    expect(extra.containsKey('keyA'), true);
    expect(extra.containsKey('keyB'), true);
    expect(extra['keyA'], 'valueA');
    expect(extra['keyB'], 'valueB');
  });
}
