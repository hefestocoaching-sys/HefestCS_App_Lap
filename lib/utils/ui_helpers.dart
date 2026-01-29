// lib/utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart'; // Importa tus colores

/// Muestra un SnackBar de error (rojo) o éxito (primario).
void showErrorSnackbar(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : kPrimaryColor,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Muestra un DatePicker con el tema oscuro personalizado de la app.
Future<DateTime?> showCustomDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  List<DateTime>? highlightedDates, // Fechas con registros
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(1920),
    lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    locale: const Locale('es', 'ES'), // Asegura el idioma español
    selectableDayPredicate: highlightedDates != null
        ? (DateTime day) {
            // Todas las fechas son seleccionables
            return true;
          }
        : null,
    builder: (context, child) {
      return Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: kPrimaryColor,
            onPrimary: kTextColor,
            surface: kCardColor,
            onSurface: kTextColor,
            // Destacar fechas con registros
            secondary: const Color(0xFF00E676),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: kBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Marcar fechas específicas
          textTheme: TextTheme(
            bodyLarge: TextStyle(
              color: highlightedDates != null ? kTextColor : kTextColor,
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
