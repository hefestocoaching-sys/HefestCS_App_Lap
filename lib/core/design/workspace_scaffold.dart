import 'package:flutter/material.dart';

/// WorkspaceScaffold: Wrapper sin card que aprovecha todo el ancho disponible.
/// Diseñado para reemplazar el patrón Align+ConstrainedBox+ModuleCardContainer.
class WorkspaceScaffold extends StatelessWidget {
  /// Header opcional que se muestra en la parte superior.
  final Widget? header;

  /// Contenido principal del workspace.
  final Widget body;

  /// Padding alrededor del body (no aplica al header).
  final EdgeInsetsGeometry padding;

  /// Si se debe envolver en una card con superficie (no usado en esta fase).
  final bool useSurfaceCard;

  const WorkspaceScaffold({
    super.key,
    this.header,
    required this.body,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
    this.useSurfaceCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: Padding(padding: padding, child: body),
          ),
        ],
      ),
    );
  }
}
