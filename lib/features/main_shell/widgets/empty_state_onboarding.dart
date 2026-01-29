import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Pantalla de bienvenida para coaches nuevos sin clientes
/// Aparece cuando no hay clientes en el sistema
class EmptyStateOnboarding extends StatelessWidget {
  final VoidCallback onCreateFirstClient;

  const EmptyStateOnboarding({super.key, required this.onCreateFirstClient});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustración/Icono grande
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 60,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // Título de bienvenida
            const Text(
              '¡Bienvenido a HCS App!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Mensaje principal
            Text(
              'Aún no tienes clientes registrados',
              style: TextStyle(
                fontSize: 16,
                color: kTextColorSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Pasos explicativos
            _buildStep(
              number: 1,
              title: 'Crea tu primer cliente',
              description:
                  'Registra los datos básicos, objetivos y nivel de tu cliente',
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: 2,
              title: 'Genera código de acceso',
              description:
                  'Comparte el código con tu cliente para que acceda a su app',
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: 3,
              title: 'Diseña planes personalizados',
              description:
                  'Crea programas de entrenamiento y nutrición adaptados',
            ),
            const SizedBox(height: 40),

            // Botón CTA principal
            ElevatedButton.icon(
              onPressed: onCreateFirstClient,
              icon: const Icon(Icons.person_add, size: 24),
              label: const Text(
                'Crear mi primer cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 24),

            // Texto secundario con tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAppBarColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kAccentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: kAccentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Puedes importar clientes desde otro sistema más adelante',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextColorSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número del paso
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: kAccentColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Texto del paso
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: kTextColorSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
