import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diálogo modal elegante para mostrar el código de invitación
/// al crear un nuevo cliente
class InvitationCodeDialog extends StatelessWidget {
  final String invitationCode;
  final String clientName;

  const InvitationCodeDialog({
    super.key,
    required this.invitationCode,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de éxito
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSuccessColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: kSuccessColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              '✅ Cliente Creado Exitosamente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Sección de código
            Text(
              '📋 CÓDIGO DE ACCESO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextColorSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Código destacado
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kPrimaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: SelectableText(
                invitationCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  letterSpacing: 2,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy, size: 20),
                    label: const Text('Copiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendWhatsApp(context),
                    icon: const Icon(Icons.send, size: 20),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF25D366,
                      ), // WhatsApp green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mensaje informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Comparte este código con $clientName para que acceda a su perfil desde la app móvil',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '✓ Entendido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invitationCode));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Código copiado al portapapeles'),
          ],
        ),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendWhatsApp(BuildContext context) async {
    final message =
        '''
¡Hola $clientName! 👋

Te doy la bienvenida a tu programa personalizado de nutrición y entrenamiento.

Tu código de acceso es:
*$invitationCode*

Descarga la app HCS Client y usa este código para acceder a:
✅ Tu plan nutricional personalizado
✅ Rutinas de entrenamiento
✅ Seguimiento de progreso
✅ Comunicación directa conmigo

¿Listo para alcanzar tus objetivos? 💪🎯
''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No se pudo abrir WhatsApp. Código copiado al portapapeles.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          _copyToClipboard(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Método estático para mostrar el diálogo fácilmente
  static Future<void> show(
    BuildContext context, {
    required String invitationCode,
    required String clientName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvitationCodeDialog(
        invitationCode: invitationCode,
        clientName: clientName,
      ),
    );
  }
}
