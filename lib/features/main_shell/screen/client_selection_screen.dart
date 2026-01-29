import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/invitation_code_generator.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class ClientSelectionScreen extends ConsumerWidget {
  final void Function(Client)? onClientSelected;

  const ClientSelectionScreen({super.key, this.onClientSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: onClientSelected != null
          ? null
          : AppBar(
              backgroundColor: kAppBarColor,
              elevation: 0,
              title: const Text('Clientes'),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: clientsAsync.when(
          data: (state) {
            final clients = state.clients
                .where((c) => c.status == ClientStatus.active)
                .toList();

            if (clients.isEmpty) {
              return Center(
                child: Text(
                  'No hay clientes activos',
                  style: TextStyle(color: kTextColorSecondary),
                ),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount:
                  clients.length + 1, // +1 para el botón de nuevo cliente
              itemBuilder: (context, index) {
                // Primer item: botón de nuevo cliente
                if (index == 0) {
                  return _NewClientCard(
                    onTap: () => _showNewClientDialog(context, ref),
                  );
                }

                // Items restantes: clientes existentes
                final client = clients[index - 1];
                final initials = _initials(client.profile.fullName);
                final planEndDate = client.nutrition.planEndDate;
                final hasActivePlan =
                    planEndDate != null && planEndDate.isAfter(DateTime.now());

                return _ClientCard(
                  client: client,
                  initials: initials,
                  hasActivePlan: hasActivePlan,
                  onTap: () {
                    if (onClientSelected != null) {
                      onClientSelected!(client);
                    } else {
                      Navigator.of(context).pop(client);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0].toUpperCase();
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0].toUpperCase()
        : '';
    return last.isEmpty ? first : '$first$last';
  }

  void _showNewClientDialog(BuildContext context, WidgetRef ref) {
    final nombreController = TextEditingController();
    final apellidoPaternoController = TextEditingController();
    final apellidoMaternoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text('Nuevo Cliente', style: TextStyle(color: kTextColor)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                style: const TextStyle(color: kTextColor),
                decoration: hcsDecoration(context, labelText: 'Nombre(s)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apellidoPaternoController,
                style: const TextStyle(color: kTextColor),
                decoration: hcsDecoration(
                  context,
                  labelText: 'Apellido Paterno *',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apellidoMaternoController,
                style: const TextStyle(color: kTextColor),
                decoration: hcsDecoration(
                  context,
                  labelText: 'Apellido Materno',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nombreController.dispose();
              apellidoPaternoController.dispose();
              apellidoMaternoController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final paterno = apellidoPaternoController.text.trim();
              final materno = apellidoMaternoController.text.trim();

              if (paterno.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El apellido paterno es obligatorio'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final fullName = [
                nombre,
                paterno,
                materno,
              ].where((s) => s.isNotEmpty).join(' ');

              final newClient = Client(
                id: 'client_${DateTime.now().millisecondsSinceEpoch}',
                profile: ClientProfile(
                  id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
                  fullName: fullName,
                  email: '',
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

              nombreController.dispose();
              apellidoPaternoController.dispose();
              apellidoMaternoController.dispose();
              Navigator.pop(dialogContext);

              // Capturar referencias ANTES de operaciones async que puedan causar dispose
              final clientsNotifier = ref.read(clientsProvider.notifier);

              // Crear el cliente
              await clientsNotifier.createClient(newClient);

              // Seleccionarlo automáticamente
              await clientsNotifier.setActiveClientById(newClient.id);

              // Cerrar pantalla de selección y abrir cliente
              if (context.mounted) {
                if (onClientSelected != null) {
                  onClientSelected!(newClient);
                } else {
                  Navigator.of(context).pop(newClient);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatefulWidget {
  final Client client;
  final String initials;
  final bool hasActivePlan;
  final VoidCallback onTap;

  const _ClientCard({
    required this.client,
    required this.initials,
    required this.hasActivePlan,
    required this.onTap,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _elevationController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _elevationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 2, end: 8).animate(
      CurvedAnimation(parent: _elevationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _elevationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (isHovering) {
      _elevationController.forward();
    } else {
      _elevationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(widget.client.createdAt);
    final colorSeed = widget.client.id.hashCode.abs();
    final gradientColor = _getGradientColorFromHash(colorSeed);

    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF00D9FF,
                  ).withAlpha((10 * (_elevationAnimation.value / 8)).toInt()),
                  blurRadius: _elevationAnimation.value,
                  spreadRadius: 0,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1F2E).withAlpha(240),
                      const Color(0xFF1A1F2E).withAlpha(235),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(15),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar con Gradient dinámico
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            gradientColor.withAlpha(200),
                            gradientColor.withAlpha(100),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withAlpha(30),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColor.withAlpha(40),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      width: 80,
                      height: 80,
                      child: Center(
                        child: Text(
                          widget.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Nombre del cliente
                    Text(
                      widget.client.fullName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFFFFFFFF),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status Badge mejorado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.hasActivePlan
                            ? Colors.green.withAlpha(30)
                            : Colors.grey.withAlpha(30),
                        border: Border.all(
                          color: widget.hasActivePlan
                              ? Colors.green.withAlpha(60)
                              : Colors.grey.withAlpha(60),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Status dot con animación sutil
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.hasActivePlan
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.hasActivePlan ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.hasActivePlan
                                  ? Colors.green[400]
                                  : Colors.grey[400],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Fecha de inicio con ícono
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Color(0xFF94A3B8).withAlpha(200),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGradientColorFromHash(int hash) {
    final gradients = [
      const Color(0xFF00D9FF), // Cyan
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF06B6D4), // Sky
      const Color(0xFF0EA5E9), // Blue
      const Color(0xFF8B5CF6), // Violet
    ];
    return gradients[hash % gradients.length];
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _NewClientCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NewClientCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withAlpha(100), width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono de +
            CircleAvatar(
              radius: 40,
              backgroundColor: kPrimaryColor.withAlpha(60),
              child: Icon(Icons.add, color: kPrimaryColor, size: 48),
            ),
            const SizedBox(height: 12),
            // Texto
            Text(
              'Nuevo\nCliente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
