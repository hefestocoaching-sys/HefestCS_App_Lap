import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Sección plana (sin card) para Historia Clínica.
/// Objetivo: jerarquía clínica + máximo espacio útil.
/// No pinta fondo, solo organiza: header + divider + contenido.
class ClinicFlatSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accentColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry contentPadding;

  const ClinicFlatSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.contentPadding = const EdgeInsets.only(top: 12),
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? kPrimaryColor;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 10),

          // Divider sutil clínico
          Container(height: 1, color: kPrimaryColor.withValues(alpha: 0.18)),

          // Contenido
          Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
