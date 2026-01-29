// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/core/navigation/client_navigation.dart';
import 'package:hcs_app_lap/core/navigation/client_open_origin.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/empty_state_onboarding.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/invitation_code_dialog.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/invitation_code_generator.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:intl/intl.dart';

class ClientSelectorModal extends ConsumerStatefulWidget {
  final Future<void> Function(Client) onClientSelected;
  final VoidCallback onClose;
  final VoidCallback? onClientActivated;

  const ClientSelectorModal({
    super.key,
    required this.onClientSelected,
    required this.onClose,
    this.onClientActivated,
  });

  @override
  ConsumerState<ClientSelectorModal> createState() =>
      _ClientSelectorModalState();
}

class _ClientSelectorModalState extends ConsumerState<ClientSelectorModal> {
  final _searchController = TextEditingController();
  List<Client> _filtered = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    final allClients = ref.watch(clientsProvider).value?.clients ?? <Client>[];
    _lastQuery = query;

    List<_ScoredClient> scored = [];
    for (final c in allClients) {
      if (c.status != ClientStatus.active) continue;

      final name = c.fullName.toLowerCase();
      final email = c.profile.email.toLowerCase();

      int score = 0;
      if (query.isEmpty) {
        score = 1;
      } else {
        if (name.startsWith(query)) score += 120;
        if (name.contains(query)) score += 80;
        if (email.startsWith(query)) score += 70;
        if (email.contains(query)) score += 40;
      }

      if (score > 0 || query.isEmpty) {
        scored.add(_ScoredClient(client: c, score: score));
      }
    }

    scored.sort((a, b) {
      if (b.score != a.score) return b.score.compareTo(a.score);
      final aDate = a.client.updatedAt;
      final bDate = b.client.updatedAt;
      return bDate.compareTo(aDate);
    });

    setState(() {
      _filtered = scored.map((e) => e.client).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            constraints: const BoxConstraints.expand(),
          ),
        ),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Card(
              color: kCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: clientsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (state) {
                    final allClients = state.clients;
                    if (_filtered.isEmpty && _searchController.text.isEmpty) {
                      _filtered = allClients;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Seleccionar Cliente',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: kAccentColor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: kTextColor),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: kTextColor),
                          decoration: hcsDecoration(
                            context,
                            hintText: 'Buscar por nombre o email...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: kTextColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón "Nuevo Cliente"
                        ElevatedButton.icon(
                          onPressed: () => _showCreateClientDialog(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Nuevo Cliente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mostrar empty state si no hay clientes, sino mostrar lista
                        Expanded(
                          child: allClients.isEmpty
                              ? EmptyStateOnboarding(
                                  onCreateFirstClient: () {
                                    Navigator.pop(context);
                                    _showCreateClientDialog(context);
                                  },
                                )
                              : _filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: kTextColorSecondary.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No se encontraron clientes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: kTextColorSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Intenta con otro nombre',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: kTextColorSecondary
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, index) {
                                    final client = _filtered[index];
                                    final bool isActive =
                                        (client.nutrition.planEndDate?.isAfter(
                                          DateTime.now(),
                                        ) ??
                                        false);

                                    final lastActivity = client.updatedAt;
                                    final lastActivityText = DateFormat(
                                      'dd MMM yyyy',
                                      'es_MX',
                                    ).format(lastActivity);

                                    return ListTile(
                                      leading: Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: isActive
                                            ? Colors.green[600]
                                            : Colors.red[600],
                                      ),
                                      title: RichText(
                                        text: TextSpan(
                                          children: _highlightMatches(
                                            client.fullName,
                                            _lastQuery,
                                          ),
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if ((client.profile.email)
                                                .isNotEmpty)
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Email: ',
                                                      style: TextStyle(
                                                        color:
                                                            kTextColorSecondary,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    ..._highlightMatches(
                                                      client.profile.email,
                                                      _lastQuery,
                                                      matchColor: kAccentColor,
                                                      defaultStyle:
                                                          const TextStyle(
                                                            color: kTextColor,
                                                            fontSize: 13,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Última actividad: $lastActivityText',
                                              style: const TextStyle(
                                                color: kTextColorSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[400],
                                        ),
                                        onPressed: () =>
                                            _confirmDeactivateClient(
                                              context,
                                              client,
                                            ),
                                        tooltip: 'Desactivar cliente',
                                      ),
                                      onTap: () async {
                                        await ref
                                            .read(clientsProvider.notifier)
                                            .setActiveClientById(client.id);
                                        await widget.onClientSelected(client);
                                        widget.onClientActivated?.call();
                                        if (!context.mounted) return;
                                        await openClientChart(
                                          context,
                                          client.id,
                                          ClientOpenOrigin.clients,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateClientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Row(
          children: [
            Icon(Icons.person_add, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text('Nuevo Cliente', style: TextStyle(color: kPrimaryColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: kTextColor),
              decoration: hcsDecoration(
                context,
                labelText: 'Nombre completo *',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: kTextColor),
              decoration: hcsDecoration(context, labelText: 'Email (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              emailController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre es obligatorio'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newClient = Client(
                id: 'client_${DateTime.now().millisecondsSinceEpoch}',
                profile: ClientProfile(
                  id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
                  fullName: name,
                  email: emailController.text.trim(),
                  phone: '',
                  country: '',
                  occupation: '',
                  objective: '',
                ),
                history: const ClinicalHistory(),
                training: TrainingProfile.empty(),
                nutrition: const NutritionSettings(),
                invitationCode: InvitationCodeGenerator.generate(),
              );

              // Capturar contexto antes de cerrar diálogos
              final dialogContext = context;

              nameController.dispose();
              emailController.dispose();
              Navigator.pop(context);

              // Crear el cliente
              await ref.read(clientsProvider.notifier).createClient(newClient);

              // Seleccionarlo automáticamente sin guardar el estado previo
              if (mounted) {
                // Cambiar directamente sin llamar a onClientSelected que guarda estado previo
                await ref
                    .read(clientsProvider.notifier)
                    .setActiveClientById(newClient.id);

                // Cerrar el modal selector
                widget.onClose();
                widget.onClientActivated?.call();
              }

              // Mostrar diálogo modal con código de invitación después de un pequeño delay
              if (mounted) {
                await Future.delayed(const Duration(milliseconds: 150));
                if (dialogContext.mounted) {
                  InvitationCodeDialog.show(
                    dialogContext,
                    invitationCode: newClient.invitationCode ?? '',
                    clientName: newClient.profile.fullName,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivateClient(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[400]),
            const SizedBox(width: 8),
            const Text(
              'Desactivar Cliente',
              style: TextStyle(color: kTextColor),
            ),
          ],
        ),
        content: Text(
          '¿Deseas desactivar a "${client.fullName}"?\n\n'
          'Podrás reactivarlo o eliminarlo permanentemente desde la sección de Ajustes.',
          style: const TextStyle(color: kTextColorSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capturar el contexto del scaffold antes de cerrar el diálogo
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              // Guardar el ID del cliente que se va a desactivar
              final clientToDeactivateId = client.id;

              // Actualizar el cliente con status = inactive
              final updatedClient = client.copyWith(
                status: ClientStatus.inactive,
              );

              // Guardar el cliente desactivado directamente en el repositorio
              await ref
                  .read(clientRepositoryProvider)
                  .saveClient(updatedClient);

              // Recargar todos los clientes
              final clientsNotifier = ref.read(clientsProvider.notifier);
              await clientsNotifier.refresh();

              // Verificar si el cliente desactivado era el activo
              final currentState = ref.read(clientsProvider).value;
              if (currentState?.activeClient?.id == clientToDeactivateId) {
                // Seleccionar el primer cliente activo disponible
                final activeClients = currentState!.clients
                    .where((c) => c.status == ClientStatus.active)
                    .toList();

                if (activeClients.isNotEmpty) {
                  await clientsNotifier.setActiveClientById(
                    activeClients.first.id,
                  );
                }
              }

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('${client.fullName} ha sido desactivado'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightMatches(
    String source,
    String query, {
    Color matchColor = kAccentColor,
    TextStyle defaultStyle = const TextStyle(color: kTextColor),
  }) {
    if (query.isEmpty) {
      return [TextSpan(text: source, style: defaultStyle)];
    }

    final lowerSource = source.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerSource.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: source.substring(start), style: defaultStyle));
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: source.substring(start, index), style: defaultStyle),
        );
      }
      spans.add(
        TextSpan(
          text: source.substring(index, index + query.length),
          style: defaultStyle.copyWith(
            color: matchColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
    }

    return spans;
  }
}

class _ScoredClient {
  final Client client;
  final int score;

  _ScoredClient({required this.client, required this.score});
}
