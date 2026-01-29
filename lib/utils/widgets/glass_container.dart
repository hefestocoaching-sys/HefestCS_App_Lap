import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

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
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(24),
      margin: margin,
      decoration: BoxDecoration(
        // Usa el color por defecto (kAppBarColor con alpha) si no se especifica uno
        color: color ?? kAppBarColor.withAlpha(110),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border,
      ),
      child: child,
    );
  }
}
