import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/client_exporter.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class InactiveClientsScreen extends ConsumerWidget {
  const InactiveClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Clientes Desactivados'),
        backgroundColor: kAppBarColor,
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (state) {
          final inactiveClients = state.clients
              .where((c) => c.status == ClientStatus.inactive)
              .toList();

          if (inactiveClients.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: kTextColorSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay clientes desactivados',
                    style: TextStyle(color: kTextColorSecondary, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inactiveClients.length,
            itemBuilder: (context, index) {
              final client = inactiveClients[index];
              return Card(
                color: kCardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[700],
                    child: Icon(Icons.person_off, color: Colors.grey[400]),
                  ),
                  title: Text(
                    client.fullName,
                    style: const TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Desactivado',
                    style: TextStyle(color: Colors.orange[400], fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón reactivar
                      IconButton(
                        icon: Icon(Icons.restore, color: Colors.green[400]),
                        onPressed: () =>
                            _confirmReactivateClient(context, ref, client),
                        tooltip: 'Reactivar cliente',
                      ),
                      // Botón eliminar permanentemente
                      IconButton(
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red[400],
                        ),
                        onPressed: () =>
                            _confirmPermanentDelete(context, ref, client),
                        tooltip: 'Eliminar permanentemente',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmReactivateClient(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.green[400]),
            const SizedBox(width: 8),
            const Text(
              'Reactivar Cliente',
              style: TextStyle(color: kTextColor),
            ),
          ],
        ),
        content: Text(
          '¿Deseas reactivar a "${client.fullName}"?\n\n'
          'El cliente volverá a aparecer en la lista principal.',
          style: const TextStyle(color: kTextColorSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              // Actualizar el cliente con status = active
              final updatedClient = client.copyWith(
                status: ClientStatus.active,
              );

              await ref
                  .read(clientsProvider.notifier)
                  .updateActiveClient((prev) => updatedClient);

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('${client.fullName} ha sido reactivado'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text('Eliminar Cliente', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Estás a punto de eliminar permanentemente a:\n\n'
              '"${client.fullName}"\n\n'
              '¿Deseas exportar los datos antes de eliminarlos?',
              style: const TextStyle(color: kTextColorSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[400], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'La exportación guardará un respaldo en JSON',
                      style: TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Solo eliminar sin exportar
              Navigator.pop(context);
              await _deleteClientPermanently(context, ref, client);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
            child: const Text('Solo Eliminar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              // Primero exportar
              final filePath = await ClientExporter.exportClientToJson(client);

              if (filePath != null && context.mounted) {
                // Mostrar éxito de exportación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exportado a: $filePath'),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 4),
                  ),
                );

                // Luego eliminar
                await _deleteClientPermanently(context, ref, client);
              } else if (context.mounted) {
                // Error en exportación
                ClientExporter.showExportErrorDialog(context);
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar y Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Elimina el cliente permanentemente después de confirmación
  Future<void> _deleteClientPermanently(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) async {
    // Mostrar diálogo de confirmación final con nombre
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text(
              'Confirmación Final',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Esta acción NO se puede deshacer.\n\n'
              'Para confirmar, escribe el nombre completo:',
              style: TextStyle(color: kTextColorSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: kTextColor),
              decoration: hcsDecoration(context, hintText: client.fullName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final isMatch = nameController.text.trim() == client.fullName;
              nameController.dispose();
              Navigator.pop(context, isMatch);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      if (context.mounted && confirmed == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre no coincide'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Eliminar permanentemente
    try {
      final repository = ref.read(clientRepositoryProvider);
      await repository.deleteClient(client.id);
      await ref.read(clientsProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client.fullName} eliminado permanentemente'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
