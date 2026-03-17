// lib/presentation/widgets/core/hcs_card.dart

import 'package:flutter/material.dart';

/// Card base con efecto glass consistente
///
/// Uso:
/// ```dart
/// HcsCard(
///   child: Text('Contenido'),
///   padding: EdgeInsets.all(16),
/// )
/// ```
class HcsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool glassEffect;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const HcsCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.glassEffect = true,
    this.onTap,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBgColor = glassEffect
        ? const Color(0xFF1A1F2E).withValues(alpha: 0.96)
        : const Color(0xFF1A1F2E);

    final defaultBorder = glassEffect
        ? Border.all(color: Colors.white.withValues(alpha: 0.08))
        : null;

    final defaultShadow = glassEffect
        ? [
            BoxShadow(
              color: const Color(0xFF00D9FF).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : null;

    final container = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBgColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: border ?? defaultBorder,
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: container,
      );
    }

    return container;
  }
}
