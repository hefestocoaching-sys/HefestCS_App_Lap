import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Un encabezado estandarizado para secciones dentro de tarjetas o contenedores.
/// Por defecto usa el estilo: Pequeño, Mayúsculas, Negrita, Espaciado amplio y Color Primario.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? textColor;
  final Color? iconColor;
  final double fontSize;
  final double letterSpacing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.textColor,
    this.iconColor,
    this.fontSize = 11,
    this.letterSpacing = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? kPrimaryColor;
    final effectiveIconColor = iconColor ?? effectiveTextColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: effectiveIconColor),
          const SizedBox(width: 12),
        ],
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }
}
