import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/pending_task.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/pending_tasks_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/client_list_screen.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class PendingPlansScreen extends ConsumerWidget {
  const PendingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(pendingTasksProvider).where((task) {
      return !task.isResolved;
    }).toList()
      ..sort(_sortTasks);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Planes por entregar'),
        backgroundColor: kBackgroundColor,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: clientsAsync.when(
                data: (clientsState) => _PendingPlansBody(
                  tasks: tasks,
                  clients: clientsState.clients,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const _ScreenStateCard(
                  icon: Icons.error_outline,
                  title: 'No se pudieron cargar los clientes',
                  subtitle: 'Intenta de nuevo desde la lista de pacientes.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingPlansBody extends ConsumerWidget {
  const _PendingPlansBody({required this.tasks, required this.clients});

  final List<PendingTask> tasks;
  final List<Client> clients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const _ScreenStateCard(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Sin planes pendientes por entregar',
        subtitle: 'Cuando exista una tarea pendiente aparecerá aquí.',
      );
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final client = _findClient(clients, task.clientId);

        return _PendingPlanTile(
          task: task,
          clientName: client?.fullName ?? 'Cliente no encontrado',
          onTap: client == null
              ? null
              : () async {
                  await ref
                      .read(clientsProvider.notifier)
                      .setActiveClientById(client.id);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientListScreen(),
                      ),
                    );
                  }
                },
        );
      },
    );
  }
}

class _PendingPlanTile extends StatelessWidget {
  const _PendingPlanTile({
    required this.task,
    required this.clientName,
    required this.onTap,
  });

  final PendingTask task;
  final String clientName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(task.priority);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.assignment_outlined, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clientName,
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Entrega: ${_formatDate(task.dueDate!)}',
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PriorityPill(label: task.priority.label, color: color),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kTextColorSecondary),
          ],
        ),
      ),
    );
  }
}

class _ScreenStateCard extends StatelessWidget {
  const _ScreenStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: kTextColorSecondary),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Client? _findClient(List<Client> clients, String id) {
  for (final client in clients) {
    if (client.id == id) return client;
  }
  return null;
}

int _sortTasks(PendingTask a, PendingTask b) {
  final priorityOrder = {
    PendingTaskPriority.urgent: 0,
    PendingTaskPriority.high: 1,
    PendingTaskPriority.normal: 2,
    PendingTaskPriority.low: 3,
  };
  final priorityCompare = (priorityOrder[a.priority] ?? 99).compareTo(
    priorityOrder[b.priority] ?? 99,
  );
  if (priorityCompare != 0) return priorityCompare;
  final aDue = a.dueDate ?? DateTime(9999);
  final bDue = b.dueDate ?? DateTime(9999);
  return aDue.compareTo(bDue);
}

Color _priorityColor(PendingTaskPriority priority) {
  switch (priority) {
    case PendingTaskPriority.low:
      return kTextColorSecondary;
    case PendingTaskPriority.normal:
      return kInfoColor;
    case PendingTaskPriority.high:
      return kWarningColor;
    case PendingTaskPriority.urgent:
      return kErrorColor;
  }
}

String _formatDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
