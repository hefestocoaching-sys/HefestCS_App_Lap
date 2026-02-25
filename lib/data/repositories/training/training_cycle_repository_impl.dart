import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/training/repositories/training_cycle_repository.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

/// Implementación del [TrainingCycleRepository] que persiste los ciclos
/// dentro del propio [Client] (campo `trainingCycles` + `activeCycleId`),
/// usando el mismo patrón que [NutritionPlanRepository].
///
/// CONSTRAINT OBLIGATORIA:
/// Antes de crear un ciclo nuevo verifica si ya hay uno activo.
/// Si existe → lo cierra (status = "completed" + endDateEpoch).
/// Nunca puede haber dos ciclos con status == "active" para el mismo clientId.
class TrainingCycleRepositoryImpl implements TrainingCycleRepository {
  TrainingCycleRepositoryImpl(this._ref);

  final Ref _ref;

  // ─────────────────────────────────────────────────────────────────────────
  // getActiveCycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<TrainingCycle?> getActiveCycle(String clientId) async {
    final clientsAsync = _ref.read(clientsProvider);
    final client = clientsAsync.value?.activeClient;

    if (client == null || client.id != clientId) {
      // Fallback al repositorio si el cliente cacheado no coincide
      final repoClient = await _ref
          .read(clientRepositoryProvider)
          .getClientById(clientId);
      if (repoClient == null) return null;

      return _findActiveInList(repoClient.trainingCycles);
    }

    return _findActiveInList(client.trainingCycles);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // createCycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> createCycle(TrainingCycle cycle) async {
    final repo = _ref.read(clientRepositoryProvider);
    final client = await repo.getClientById(cycle.clientId);
    if (client == null) {
      debugPrint(
        '[TrainingCycleRepository] createCycle: client not found '
        '(clientId=${cycle.clientId})',
      );
      return;
    }

    // CONSTRAINT: cerrar ciclo activo si existe antes de crear el nuevo
    var cycles = List<TrainingCycle>.from(client.trainingCycles);
    final now = DateTime.now();

    final closedCycles = cycles.map((c) {
      if (c.status == 'active') {
        debugPrint(
          '[TrainingCycleRepository] Closing active cycle: ${c.cycleId}',
        );
        return c.copyWith(status: 'completed', endDate: now, updatedAt: now);
      }
      return c;
    }).toList();

    // Garantizar status "active" en el nuevo ciclo
    final newCycle = cycle.status == 'active'
        ? cycle
        : cycle.copyWith(status: 'active');

    final updatedCycles = [...closedCycles, newCycle];

    final updatedClient = client.copyWith(
      trainingCycles: updatedCycles,
      activeCycleId: newCycle.cycleId,
    );

    await repo.saveClient(updatedClient);

    debugPrint(
      '[TrainingCycleRepository] Cycle created: ${newCycle.cycleId} '
      '(total cycles: ${updatedCycles.length})',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // closeCycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> closeCycle(String cycleId) async {
    final repo = _ref.read(clientRepositoryProvider);

    // Obtener cliente que contiene este ciclo
    final clientsAsync = _ref.read(clientsProvider);
    final cachedClient = clientsAsync.value?.activeClient;
    if (cachedClient == null) {
      debugPrint(
        '[TrainingCycleRepository] closeCycle: no active client in cache',
      );
      return;
    }

    final client = await repo.getClientById(cachedClient.id);
    if (client == null) return;

    final now = DateTime.now();
    final updatedCycles = client.trainingCycles.map((c) {
      if (c.cycleId == cycleId) {
        return c.copyWith(status: 'completed', endDate: now, updatedAt: now);
      }
      return c;
    }).toList();

    // Si el ciclo cerrado era el activo, limpiar activeCycleId
    final isCurrentActive = client.activeCycleId == cycleId;

    final updatedClient = client.copyWith(
      trainingCycles: updatedCycles,
      activeCycleId: isCurrentActive ? null : client.activeCycleId,
    );

    await repo.saveClient(updatedClient);

    debugPrint(
      '[TrainingCycleRepository] Cycle closed: $cycleId '
      '(wasActive=$isCurrentActive)',
    );
  }

  @override
  Future<void> upsertCycle(TrainingCycle cycle) async {
    final repo = _ref.read(clientRepositoryProvider);
    final client = await repo.getClientById(cycle.clientId);
    if (client == null) {
      debugPrint(
        '[TrainingCycleRepository] upsertCycle: client not found '
        '(clientId=${cycle.clientId})',
      );
      return;
    }

    final hasExisting = client.trainingCycles.any(
      (c) => c.cycleId == cycle.cycleId,
    );
    if (!hasExisting) {
      await createCycle(cycle);
      return;
    }

    final updatedCycles = client.trainingCycles.map((c) {
      if (c.cycleId == cycle.cycleId) {
        if (c.status == 'active' && c.freezePlanSnapshot.isNotEmpty) {
          return cycle.copyWith(
            splitType: c.splitType,
            baseExercisesByMuscle: c.baseExercisesByMuscle,
            freezePlanSnapshot: c.freezePlanSnapshot,
          );
        }

        return cycle;
      }

      if (cycle.status == 'active' && c.status == 'active') {
        return c.copyWith(
          status: 'completed',
          endDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return c;
    }).toList();

    final updatedClient = client.copyWith(
      trainingCycles: updatedCycles,
      activeCycleId: cycle.status == 'active'
          ? cycle.cycleId
          : client.activeCycleId,
    );

    await repo.saveClient(updatedClient);

    debugPrint('[TrainingCycleRepository] Cycle upserted: ${cycle.cycleId}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers privados
  // ─────────────────────────────────────────────────────────────────────────

  /// Devuelve el primer ciclo con status == "active", o null.
  TrainingCycle? _findActiveInList(List<TrainingCycle> cycles) {
    try {
      return cycles.firstWhere((c) => c.status == 'active');
    } on StateError {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final trainingCycleRepositoryProvider = Provider<TrainingCycleRepository>((
  ref,
) {
  return TrainingCycleRepositoryImpl(ref);
});
