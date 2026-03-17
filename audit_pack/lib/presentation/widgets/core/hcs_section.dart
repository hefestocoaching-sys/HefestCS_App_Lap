// lib/presentation/widgets/core/hcs_section.dart

import 'package:flutter/material.dart';

/// Sección con título, ícono opcional y acción opcional
///
/// Uso:
/// ```dart
/// HcsSection(
///   title: 'Análisis de Volumen',
///   icon: Icons.analytics,
///   action: IconButton(icon: Icon(Icons.edit), onPressed: () {}),
///   child: VolumeChart(),
/// )
/// ```
class HcsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? action;
  final EdgeInsets? padding;
  final Color? titleColor;

  const HcsSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.padding,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: titleColor ?? const Color(0xFF00D9FF),
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor ?? Colors.white,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          // Content
          child,
        ],
      ),
    );
  }
}
