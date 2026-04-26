import 'package:flutter/material.dart';

/// Widget reutilizable que renderiza un label con icono "?" que muestra tooltip de ayuda.
class LabelWithHelp extends StatelessWidget {
  final String label;
  final String helpText;
  final TextStyle? labelStyle;
  final double iconSize;

  const LabelWithHelp({
    super.key,
    required this.label,
    required this.helpText,
    this.labelStyle,
    this.iconSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style:
              labelStyle ??
              Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: helpText,
          showDuration: const Duration(seconds: 6),
          preferBelow: true,
          child: Icon(
            Icons.help_outline,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
