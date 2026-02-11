import 'package:flutter/material.dart';

/// Contenedor con estilo glassmorphism ligero para superficies clínicas.
///
/// Uso básico:
/// ```dart
/// HcsGlassContainer(
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       Text('Resumen semanal'),
///       SizedBox(height: 8),
///       Text('Volumen en zona MAV'),
///     ],
///   ),
/// )
/// ```
///
/// Ejemplo con sombra sutil:
/// ```dart
/// HcsGlassContainer(
///   showShadow: true,
///   borderRadius: 16,
///   padding: EdgeInsets.all(20),
///   child: Text('Detalle de sesión'),
/// )
/// ```
class HcsGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showShadow;

  const HcsGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? Colors.white.withAlpha(10);
    final resolvedBorder = borderColor ?? Colors.white.withAlpha(20);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBackground,
        border: Border.all(color: resolvedBorder),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
