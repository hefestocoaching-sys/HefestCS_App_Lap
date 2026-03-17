import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Widget unificado para Context Bar en todos los módulos clínicos.
///
/// Parámetros:
/// - [mode]: Texto del modo actual (ej: "VISTA", "EDITANDO", "NUEVO")
/// - [modeColor]: Color asociado al modo
/// - [modeIcon]: Icono del modo
/// - [dateLabel]: Label opcional de fecha (ej: "Último: 2024-01-15", "Registro: 2024-01-15")
/// - [dateColor]: Color del texto de fecha (default: kTextColor)
/// - [extraWidgets]: Widgets adicionales opcionales al final de la barra
///
/// Uso:
/// ```dart
/// ClinicalContextBar(
///   mode: 'EDITANDO',
///   modeColor: Colors.orange,
///   modeIcon: Icons.edit,
///   dateLabel: '15 Ene 2024',
/// )
/// ```
class ClinicalContextBar extends StatelessWidget {
  final String mode;
  final Color modeColor;
  final IconData modeIcon;
  final String? dateLabel;
  final Color? dateColor;
  final List<Widget>? extraWidgets;

  const ClinicalContextBar({
    super.key,
    required this.mode,
    required this.modeColor,
    required this.modeIcon,
    this.dateLabel,
    this.dateColor,
    this.extraWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: modeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: modeColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(modeIcon, color: modeColor, size: 18),
          const SizedBox(width: 8),
          Text(
            mode,
            style: TextStyle(
              color: modeColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          if (dateLabel != null && dateLabel!.isNotEmpty) ...[
            const SizedBox(width: 12),
            const Text(
              '•',
              style: TextStyle(color: kTextColorSecondary, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                dateLabel!,
                style: TextStyle(color: dateColor ?? kTextColor, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (extraWidgets != null) ...extraWidgets!,
        ],
      ),
    );
  }

  /// Factory para modo VIEW
  factory ClinicalContextBar.view({
    required DateTime? selectedDate,
    String? customLabel,
  }) {
    final dateLabel = selectedDate != null
        ? customLabel ?? DateFormat('d MMM yyyy', 'es').format(selectedDate)
        : '';

    return ClinicalContextBar(
      mode: 'VISTA',
      modeColor: Colors.blue,
      modeIcon: Icons.visibility,
      dateLabel: dateLabel,
    );
  }

  /// Factory para modo EDITING
  factory ClinicalContextBar.editing({
    required DateTime? selectedDate,
    String? customLabel,
  }) {
    final dateLabel = selectedDate != null
        ? customLabel ?? DateFormat('d MMM yyyy', 'es').format(selectedDate)
        : '';

    return ClinicalContextBar(
      mode: 'EDITANDO',
      modeColor: Colors.orange,
      modeIcon: Icons.edit,
      dateLabel: dateLabel,
    );
  }

  /// Factory para modo CREATING
  factory ClinicalContextBar.creating({String? lastRecordInfo}) {
    return ClinicalContextBar(
      mode: 'NUEVO REGISTRO',
      modeColor: kPrimaryColor,
      modeIcon: Icons.add_circle_outline,
      dateLabel: lastRecordInfo,
    );
  }
}
