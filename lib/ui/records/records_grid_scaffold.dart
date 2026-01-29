import 'package:flutter/material.dart';

/// Contenedor para grids de registros (overview de antropometría, nutrición, etc).
///
/// Características:
/// - Padding 24px
/// - Alineación top-left
/// - No fuerza scroll (el grid lo maneja)
/// - No mete cards innecesarias
///
/// ✅ Deja que el grid controle su propio layout
/// ✅ Solo proporciona aire visual consistente
class RecordsGridScaffold extends StatelessWidget {
  final Widget grid;

  const RecordsGridScaffold({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(alignment: Alignment.topLeft, child: grid),
    );
  }
}
