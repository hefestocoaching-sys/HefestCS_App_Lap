import 'package:flutter/material.dart';

/// ✅ Sección clínica estándar
/// Proporciona estructura visual consistente:
/// - Título con estilo uniforme
/// - Separación estándar (16px)
/// - Contenido flexible
///
/// Uso:
/// ```dart
/// ClinicalSection(
///   title: 'Título de Sección',
///   child: YourWidget(),
/// )
/// ```
class ClinicalSection extends StatelessWidget {
  final String title;
  final Widget child;

  const ClinicalSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
