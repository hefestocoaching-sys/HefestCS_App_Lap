import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/services/database_helper.dart';

class ClientsState {
  final List<Client> clients;
  final String? activeClientId;
  final bool isLoading;
  final String? error;

  const ClientsState({
    this.clients = const [],
    this.activeClientId,
    this.isLoading = false,
    this.error,
  });

  Client? get activeClient {
    if (activeClientId == null) return null;
    for (final client in clients) {
      if (client.id == activeClientId) {
        return client;
      }
    }
    return null;
  }

  ClientsState copyWith({
    List<Client>? clients,
    String? activeClientId,
    bool? isLoading,
    String? error,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      activeClientId: activeClientId ?? this.activeClientId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ClientsNotifier extends AsyncNotifier<ClientsState> {
  // Per-client write queue to serialize writes and avoid lost-update races
  final Map<String, Future<void>> _clientWriteLocks = {};
  late final ClientRepository _repository;

  @override
  Future<ClientsState> build() async {
    _repository = ref.watch(clientRepositoryProvider);
    try {
      final storedActiveId = await DatabaseHelper.instance.getActiveClientId();
      final clients = await _loadClients();
      final activeId = _resolveActiveClientId(clients, storedActiveId);
      await _persistActiveClientId(activeId);
      return ClientsState(clients: clients, activeClientId: activeId);
    } catch (e) {
      return ClientsState(error: e.toString());
    }
  }

  Future<List<Client>> _loadClients() async {
    final clients = await _repository.getClients();
    return _sortClients(clients);
  }

  List<Client> _sortClients(List<Client> clients) {
    final sorted = List<Client>.from(clients);
    sorted.sort((a, b) {
      final dateCompare = b.updatedAt.compareTo(a.updatedAt);
      if (dateCompare != 0) return dateCompare;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  String? _resolveActiveClientId(List<Client> clients, String? preferredId) {
    if (preferredId == null) return null;
    final exists = clients.any((c) => c.id == preferredId);
    return exists ? preferredId : null;
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isLoading: true, error: null));
    try {
      final clients = await _loadClients();
      final activeId = _resolveActiveClientId(clients, current.activeClientId);
      await _persistActiveClientId(activeId);
      state = AsyncValue.data(
        current.copyWith(
          clients: clients,
          activeClientId: activeId,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  Future<void> createClient(Client client) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isLoading: true, error: null));
    try {
      await _repository.saveClient(client);
      final clients = await _loadClients();
      final activeId = _resolveActiveClientId(clients, current.activeClientId);
      await _persistActiveClientId(activeId);
      state = AsyncValue.data(
        current.copyWith(
          clients: clients,
          activeClientId: activeId,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  Future<void> setActiveClientById(String id) async {
    final current = state.value;
    if (current == null) return;
    final exists = current.clients.any((c) => c.id == id);
    if (!exists) return;
    try {
      await _persistActiveClientId(id);
      state = AsyncValue.data(
        current.copyWith(activeClientId: id, error: null),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(activeClientId: id, error: e.toString()),
      );
    }
  }

  Future<void> updateActiveClient(Client Function(Client) transform) async {
    final current = state.value;
    if (current == null) return;
    final active = current.activeClient;
    if (active == null) return;
    state = AsyncValue.data(current.copyWith(isLoading: true, error: null));
    try {
      // Serialize writes per-client to avoid lost-update races.
      final clientId = active.id;
      final previous = _clientWriteLocks[clientId] ?? Future.value();

      // Usar .then() en lugar de .whenComplete() para evitar problemas con async
      final next = previous.then((_) async {
        final persisted = await _repository.getClientById(clientId) ?? active;
        final updated = transform(persisted);

        final mergedNutritionExtra = Map<String, dynamic>.from(
          persisted.nutrition.extra,
        );
        mergedNutritionExtra.addAll(updated.nutrition.extra);

        final mergedTrainingExtra = Map<String, dynamic>.from(
          persisted.training.extra,
        );
        mergedTrainingExtra.addAll(updated.training.extra);

        // ✅ P0-3: ELIMINAR claves legacy Motor V2 después de merge
        const legacyV2Keys = [
          'activePlanId',
          'mevByMuscle',
          'mrvByMuscle',
          'mavByMuscle',
          'targetSetsByMuscle',
          'intensityDistribution',
          'mevTable',
          'seriesTypePercentSplit',
          'weeklyPlanId',
          'finalTargetSetsByMuscleUi',
        ];

        for (final key in legacyV2Keys) {
          if (mergedTrainingExtra.containsKey(key)) {
            mergedTrainingExtra.remove(key);
            debugPrint('🗑️ P0-3 clients_provider: Removed legacy key $key');
          }
        }

        debugPrint('✅ P0-3: training.extra limpiado en updateActiveClient');
        debugPrint('   Claves finales: ${mergedTrainingExtra.keys.toList()}');

        final mergedNutrition = persisted.nutrition.copyWith(
          extra: mergedNutritionExtra,
          dailyMealPlans:
              updated.nutrition.dailyMealPlans ??
              persisted.nutrition.dailyMealPlans,
          planType: updated.nutrition.planType ?? persisted.nutrition.planType,
          planStartDate:
              updated.nutrition.planStartDate ??
              persisted.nutrition.planStartDate,
          planEndDate:
              updated.nutrition.planEndDate ?? persisted.nutrition.planEndDate,
        );

        // ✅ CORRECTO: usar updated.training como base, solo mergear extra
        final mergedTraining = updated.training.copyWith(
          extra: mergedTrainingExtra,
        );

        final mergedClient = persisted.copyWith(
          profile: updated.profile,
          history: updated.history,
          nutrition: mergedNutrition,
          training: mergedTraining,
          trainingPlans: updated.trainingPlans,
          trainingWeeks: updated.trainingWeeks,
          trainingSessions: updated.trainingSessions,
          status: updated.status,
        );

        await _repository.saveClient(mergedClient);

        // Refresh local state after write.
        final clients = await _loadClients();
        final activeId = _resolveActiveClientId(clients, mergedClient.id);
        await _persistActiveClientId(activeId);
        state = AsyncValue.data(
          current.copyWith(
            clients: clients,
            activeClientId: activeId,
            isLoading: false,
            error: null,
          ),
        );
      });

      _clientWriteLocks[clientId] = next;
      await next;
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  Future<void> _persistActiveClientId(String? id) async {
    await DatabaseHelper.instance.setActiveClientId(id);
  }

  Future<void> clearActiveClient() async {
    final current = state.value;
    if (current == null) return;
    await _persistActiveClientId(null);
    state = AsyncValue.data(
      current.copyWith(activeClientId: null, error: null),
    );
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, ClientsState>(
  ClientsNotifier.new,
);
