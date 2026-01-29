import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// ✅ Contenedor clínico global (workspace)
/// Proporciona:
/// - Ancho máximo 1200px (patrón clínico)
/// - Padding uniforme 24px
/// - Decoración: fondo y bordes clínicos
/// - Margen superior/inferior para separación
///
/// Uso:
/// ```dart
/// ClinicalWorkspaceContainer(
///   child: Column(
///     children: [...sections...],
///   ),
/// )
/// ```
class ClinicalWorkspaceContainer extends StatelessWidget {
  final Widget child;

  const ClinicalWorkspaceContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          margin: const EdgeInsets.only(top: 16, bottom: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}
