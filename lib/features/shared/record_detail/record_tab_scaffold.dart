import 'package:flutter/material.dart';

/// Wrapper para el contenido dentro de cada tab.
/// Proporciona scroll interno y padding consistente.
class RecordTabScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const RecordTabScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 32, 24, 32),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
