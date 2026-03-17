import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Card profesional para agrupar información relacionada con header visual
class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor,
    this.padding,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? kPrimaryColor;

    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          // Contenido
          ...children,
        ],
      ),
    );
  }
}
