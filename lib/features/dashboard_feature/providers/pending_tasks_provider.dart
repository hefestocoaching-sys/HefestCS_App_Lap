import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/pending_task.dart';

/// Provider simple para tareas pendientes
/// Inicialmente con mock data, listo para conectar a Firebase
final pendingTasksProvider =
    NotifierProvider<PendingTasksNotifier, List<PendingTask>>(
      () => PendingTasksNotifier(),
    );

class PendingTasksNotifier extends Notifier<List<PendingTask>> {
  @override
  List<PendingTask> build() {
    // Mock data: vacío por defecto
    // TODO: Conectar a Firestore cuando esté listo
    return [];
  }

  /// Agregar una tarea pendiente
  void addTask(PendingTask task) {
    state = [...state, task];
  }

  /// Marcar tarea como resuelta
  void resolveTask(String taskId) {
    state = [
      for (final task in state)
        if (task.id == taskId) task.copyWith(isResolved: true) else task,
    ];
  }

  /// Eliminar tarea
  void removeTask(String taskId) {
    state = [
      for (final task in state)
        if (task.id != taskId) task,
    ];
  }

  /// Obtener tareas pendientes no resueltas (para mostrar en HOME)
  List<PendingTask> getActivePendingTasks() {
    return state.where((task) => !task.isResolved).toList()..sort((a, b) {
      // Ordenar por prioridad (urgente primero)
      final priorityOrder = {
        PendingTaskPriority.urgent: 0,
        PendingTaskPriority.high: 1,
        PendingTaskPriority.normal: 2,
        PendingTaskPriority.low: 3,
      };
      return (priorityOrder[a.priority] ?? 99).compareTo(
        priorityOrder[b.priority] ?? 99,
      );
    });
  }

  /// Obtener tareas de un cliente específico
  List<PendingTask> getClientTasks(String clientId) {
    return state
        .where((task) => task.clientId == clientId && !task.isResolved)
        .toList();
  }
}
