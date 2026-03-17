import 'package:flutter/material.dart';

import 'package:hcs_app_lap/core/design/hcs_glass_container.dart';

/// Un contenedor reutilizable que aplica el estilo "Glassmorphism" estándar de la app.
/// Centraliza el color, opacidad y bordes para mantener consistencia visual.
/// Si cambias el diseño aquí, se actualizará en toda la aplicación.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // ⚠️ REFACTOR: Wraps HcsGlassContainer for consistent visual style (Glass V3)
    // Maps legacy properties to the new component.
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: HcsGlassContainer(
        padding: padding ?? const EdgeInsets.all(24),
        borderRadius: borderRadius is BorderRadius
            ? (borderRadius as BorderRadius).topLeft.x
            : 16.0,
        backgroundColor:
            color, // Allow override, but HcsGlassContainer has its own default
        borderColor: border is Border ? (border as Border).top.color : null,
        child: child,
      ),
    );
  }
}
