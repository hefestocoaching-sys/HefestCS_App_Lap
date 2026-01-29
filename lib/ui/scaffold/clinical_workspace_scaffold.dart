import 'package:flutter/material.dart';

/// Rail clínico estándar para todos los módulos.
///
/// Características:
/// - Scroll único vertical
/// - Anchura máxima 1200px centrada
/// - Padding 24px
/// - Header del cliente
/// - Tabs opcionales
/// - Contenido principal
///
/// ✅ Mismo patrón que HistoryClinic/Antropometría
/// ✅ Reutilizable en TODOS los módulos clínicos
class ClinicalWorkspaceScaffold extends StatelessWidget {
  final Widget header;
  final Widget? tabs;
  final Widget body;

  const ClinicalWorkspaceScaffold({
    super.key,
    required this.header,
    this.tabs,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (tabs != null) ...[const SizedBox(height: 16), tabs!],
                const SizedBox(height: 24),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
