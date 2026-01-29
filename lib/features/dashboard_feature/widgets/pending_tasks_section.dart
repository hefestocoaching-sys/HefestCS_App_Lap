import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/pending_task.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/pending_tasks_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Bloque de tareas pendientes en el HOME
/// Muestra acciones urgentes (planes no enviados, evaluaciones pendientes, etc.)
class PendingTasksSection extends ConsumerWidget {
  const PendingTasksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTasksNotifier = ref.read(pendingTasksProvider.notifier);
    final activeTasks = pendingTasksNotifier.getActivePendingTasks();
    final clientsAsync = ref.watch(clientsProvider);
    final clients = clientsAsync.value?.clients ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pendientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  Text(
                    'Acciones por completar',
                    style: TextStyle(
                      fontSize: 12,
                      color: kTextColorSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (activeTasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${activeTasks.length}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Contenido
          if (activeTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 44,
                      color: kSuccessColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay pendientes',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeTasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = activeTasks[index];

                    // Encontrar cliente
                    dynamic client;
                    try {
                      client = clients.firstWhere((c) => c.id == task.clientId);
                    } catch (_) {
                      client = null;
                    }

                    return _PendingTaskItem(
                      task: task,
                      client: client,
                      onTap: () {
                        // Navegar al cliente
                        if (client != null) {
                          ref
                              .read(clientsProvider.notifier)
                              .setActiveClientById(client.id);
                          // TODO: Cambiar a módulo clínico
                        }
                      },
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Item individual de tarea pendiente
class _PendingTaskItem extends StatelessWidget {
  final PendingTask task;
  final dynamic client;
  final VoidCallback onTap;

  const _PendingTaskItem({
    required this.task,
    required this.client,
    required this.onTap,
  });

  Color _getPriorityColor(PendingTaskPriority priority) {
    switch (priority) {
      case PendingTaskPriority.low:
        return kTextColorSecondary;
      case PendingTaskPriority.normal:
        return kPrimaryColor;
      case PendingTaskPriority.high:
        return Colors.orange[400]!;
      case PendingTaskPriority.urgent:
        return Colors.red[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kAppBarColor.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(20), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de prioridad
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Información de tarea
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Cliente + Prioridad
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          client?.fullName ?? 'Cliente desconocido',
                          style: TextStyle(
                            fontSize: 12,
                            color: kTextColorSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (task.priority.index >= 2)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.priority.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Icono de navegación
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: kTextColorSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
