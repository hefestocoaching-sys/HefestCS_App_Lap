import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/config/feature_flags.dart';
import 'package:hcs_app_lap/core/utils/update_lock.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
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
    state = AsyncValue.data(current.copyWith(isLoading: true));
    try {
      final clients = await _loadClients();
      final activeId = _resolveActiveClientId(clients, current.activeClientId);
      await _persistActiveClientId(activeId);
      state = AsyncValue.data(
        current.copyWith(
          clients: clients,
          activeClientId: activeId,
          isLoading: false,
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
    state = AsyncValue.data(current.copyWith(isLoading: true));
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
      state = AsyncValue.data(current.copyWith(activeClientId: id));
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(activeClientId: id, error: e.toString()),
      );
    }
  }

  Future<void> updateActiveClient(Client Function(Client) transform) async {
    if (FeatureFlags.useLegacyClientUpdate) {
      return _updateActiveClientLegacy(transform);
    }
    return UpdateLock.instance.safeClientUpdate(() async {
      final current = state.value;
      if (current == null) return;
      final active = current.activeClient;
      if (active == null) return;
      state = AsyncValue.data(current.copyWith(isLoading: true));
      try {
        // Serialize writes per-client to avoid lost-update races.
        final clientId = active.id;
        final previous = _clientWriteLocks[clientId] ?? Future.value();

        // Usar .then() en lugar de .whenComplete() para evitar problemas con async
        final next = previous.then((_) async {
          final persisted = await _repository.getClientById(clientId) ?? active;
          final updated = transform(persisted);

          final mergedTrainingExtra = Map<String, dynamic>.from(
            persisted.training.extra,
          );
          mergedTrainingExtra.addAll(updated.training.extra);

          debugPrint('✅ training.extra mergeado en updateActiveClient');

          final mergedNutrition = _safeMergeNutrition(
            persisted.nutrition,
            updated.nutrition,
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

          // Refresh local state without reloading all clients.
          final updatedClients = current.clients
              .map(
                (client) =>
                    client.id == mergedClient.id ? mergedClient : client,
              )
              .toList();
          final sortedClients = _sortClients(updatedClients);
          state = AsyncValue.data(
            current.copyWith(
              clients: sortedClients,
              activeClientId: mergedClient.id,
              isLoading: false,
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
    });
  }

  Future<void> _updateActiveClientLegacy(
    Client Function(Client) transform,
  ) async {
    final current = state.value;
    if (current == null) return;
    final active = current.activeClient;
    if (active == null) return;
    state = AsyncValue.data(current.copyWith(isLoading: true));
    try {
      final clientId = active.id;
      final previous = _clientWriteLocks[clientId] ?? Future.value();

      final next = previous.then((_) async {
        final persisted = await _repository.getClientById(clientId) ?? active;
        final updated = transform(persisted);

        final mergedTrainingExtra = Map<String, dynamic>.from(
          persisted.training.extra,
        );
        mergedTrainingExtra.addAll(updated.training.extra);

        final mergedNutrition = _safeMergeNutrition(
          persisted.nutrition,
          updated.nutrition,
        );

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

        final updatedClients = current.clients
            .map(
              (client) => client.id == mergedClient.id ? mergedClient : client,
            )
            .toList();
        final sortedClients = _sortClients(updatedClients);
        state = AsyncValue.data(
          current.copyWith(
            clients: sortedClients,
            activeClientId: mergedClient.id,
            isLoading: false,
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

  NutritionSettings _safeMergeNutrition(
    NutritionSettings current,
    NutritionSettings updated,
  ) {
    final mergedExtra = Map<String, dynamic>.from(current.extra);
    updated.extra.forEach((key, value) {
      if (value != null) {
        mergedExtra[key] = value;
      }
    });

    return NutritionSettings(
      planType: updated.planType ?? current.planType,
      planStartDate: updated.planStartDate ?? current.planStartDate,
      planEndDate: updated.planEndDate ?? current.planEndDate,
      kcal: updated.kcal ?? current.kcal,
      dailyKcal: updated.dailyKcal ?? current.dailyKcal,
      weeklyMacroSettings:
          updated.weeklyMacroSettings ?? current.weeklyMacroSettings,
      dailyMealPlans: updated.dailyMealPlans ?? current.dailyMealPlans,
      clinicalRestrictionProfile: updated.clinicalRestrictionProfile,
      extra: mergedExtra,
    );
  }

  Future<void> _persistActiveClientId(String? id) async {
    await DatabaseHelper.instance.setActiveClientId(id);
  }

  Future<void> clearActiveClient() async {
    final current = state.value;
    if (current == null) return;
    await _persistActiveClientId(null);
    state = AsyncValue.data(current.copyWith());
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, ClientsState>(
  ClientsNotifier.new,
);
