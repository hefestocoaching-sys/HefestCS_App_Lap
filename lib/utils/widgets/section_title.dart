import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Un título de sección estandarizado para usar fuera de las tarjetas (GlassContainers).
/// Define la jerarquía visual principal de las pantallas.
class SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.color,
    this.padding = const EdgeInsets.only(left: 4.0, bottom: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: color ?? kTextColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 20,
        ),
      ),
    );
  }
}
