import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? userMessage,
    bool showSnackbar = true,
  }) {
    logger.error('Error handled', error);

    // FirebaseCrashlytics.instance.recordError(error, stackTrace);

    if (showSnackbar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage ?? _getUserFriendlyMessage(error)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _getUserFriendlyMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('firebase')) {
      return 'Error de sincronizacion. Los datos se guardaran localmente.';
    } else if (message.contains('database')) {
      return 'Error al guardar datos. Por favor, intenta nuevamente.';
    } else if (message.contains('network')) {
      return 'Sin conexion a internet. Los cambios se sincronizaran despues.';
    }
    return 'Ocurrio un error inesperado.';
  }
}
