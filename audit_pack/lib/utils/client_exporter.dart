import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Utilidad para exportar datos de clientes en formato JSON
class ClientExporter {
  /// Exporta un cliente completo a JSON y guarda en el directorio de Descargas
  /// Retorna la ruta del archivo guardado o null si falla
  static Future<String?> exportClientToJson(Client client) async {
    try {
      // Convertir cliente a JSON
      final clientJson = client.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(clientJson);

      // Generar nombre de archivo con timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final sanitizedName = client.fullName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final filename = 'cliente_${sanitizedName}_$timestamp.json';

      // Obtener directorio de descargas (o documentos como fallback)
      Directory directory;
      if (Platform.isWindows) {
        // En Windows, usar directorio de documentos del usuario
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloads = Directory('$userProfile\\Downloads');
          if (await downloads.exists()) {
            directory = downloads;
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      // Crear archivo
      final file = File('${directory.path}${Platform.pathSeparator}$filename');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Error exportando cliente: $e');
      return null;
    }
  }

  /// Muestra un diálogo de éxito con la ruta del archivo exportado
  static void showExportSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Exportación exitosa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Los datos del cliente han sido exportados a:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                filePath,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de error si falla la exportación
  static void showExportErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Error al exportar'),
          ],
        ),
        content: const Text(
          'No se pudo exportar los datos del cliente. '
          'Verifica los permisos de escritura e intenta nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
