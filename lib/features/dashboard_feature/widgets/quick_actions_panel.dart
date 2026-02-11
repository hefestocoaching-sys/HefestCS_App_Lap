import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/client_list_screen.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Panel de acciones rápidas en el HOME
/// Proporciona CTAs para las operaciones más comunes:
/// - Nuevo cliente
/// - Ver clientes
/// - Registrar pago
class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 20),

          // Grid de botones (3 columnas)
          Row(
            children: [
              // Botón: + Nuevo cliente
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.person_add_alt,
                  label: '+ Nuevo\ncliente',
                  color: kPrimaryColor,
                  onPressed: () {
                    // Navegar a ClientListScreen y mostrar diálogo de nuevo cliente
                    _navigateToNewClient(context);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Botón: Ver clientes
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.people_outline,
                  label: 'Ver\nclientes',
                  color: Colors.blue[400]!,
                  onPressed: () {
                    // Navegar a ClientListScreen
                    _navigateToClientList(context);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Botón: Registrar pago (deshabilitado por ahora)
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.payment_outlined,
                  label: 'Registrar\npago',
                  color: Colors.green[400]!,
                  isDisabled: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Módulo de pagos próximamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToNewClient(BuildContext context) {
    // Navegar a ClientListScreen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ClientListScreen()));
  }

  void _navigateToClientList(BuildContext context) {
    // Navegar a ClientListScreen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ClientListScreen()));
  }
}

/// Botón individual para acciones rápidas
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isDisabled;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: isDisabled ? 'Próximamente disponible' : '',
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAppBarColor.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey.withAlpha(30)
                      : color.withAlpha(51),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? kTextColorSecondary : kTextColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
