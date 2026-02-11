import 'package:flutter/material.dart';

/// Diálogo de confirmación para borrar un registro por fecha.
///
/// Muestra:
/// - Fecha a borrar en formato legible
/// - Tipo de registro (Antropometría, Nutrición, etc.)
/// - Botones: Cancelar / Borrar
///
/// Retorna `true` si el usuario confirma, `false` si cancela.
///
/// Uso:
/// ```dart
/// final confirmed = await showDeleteConfirmationDialog(
///   context: context,
///   date: DateTime(2025, 01, 15),
///   recordType: 'Medidas de Antropometría',
/// );
///
/// if (confirmed) {
///   await deletionService.deleteAnthropometryByDate(
///     clientId: clientId,
///     date: date,
///   );
/// }
/// ```
Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required DateTime date,
  required String recordType,
}) async {
  final dateStr = _formatDate(date);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmar borrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vas a borrar el registro de:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                border: Border.all(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recordType,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer. Solo se eliminará el registro de esta fecha.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

/// Muestra un snackbar de confirmación después de borrar.
void showDeleteSuccessSnackbar(
  BuildContext context,
  DateTime date,
  String recordType,
) {
  final dateStr = _formatDate(date);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$recordType ($dateStr) eliminado'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Muestra un snackbar de error al borrar.
void showDeleteErrorSnackbar(BuildContext context, Exception error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error al borrar: ${error.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}

/// Formatea una fecha al formato "viernes, 15 de enero de 2025"
String _formatDate(DateTime date) {
  final days = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  final months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  final dayName = days[date.weekday - 1];
  final monthName = months[date.month - 1];

  return '$dayName, ${date.day} de $monthName de ${date.year}';
}
