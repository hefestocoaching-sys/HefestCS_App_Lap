import 'package:flutter/material.dart';

import 'package:hcs_app_lap/features/training_feature/domain/interview_help_content.dart';

class InterviewFieldLabel extends StatelessWidget {
  final String label;
  final InterviewHelpContent? helpContent;
  final TextStyle? labelStyle;
  final double iconSize;

  const InterviewFieldLabel({
    super.key,
    required this.label,
    this.helpContent,
    this.labelStyle,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final help = helpContent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style:
                labelStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (help != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: help.shortHelp,
            preferBelow: true,
            waitDuration: const Duration(milliseconds: 250),
            child: InkWell(
              onTap: () => _showHelpDialog(context, help),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.help_outline,
                  size: iconSize,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showHelpDialog(BuildContext context, InterviewHelpContent help) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(help.modalTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HelpSection(title: 'Qué significa', body: help.meaning),
                _HelpSection(
                  title: 'Cómo elegir la respuesta',
                  body: help.howToAnswer,
                ),
                _HelpSection(
                  title: 'Ejemplos',
                  body: help.examples.map((e) => '• $e').join('\n'),
                ),
                _HelpSection(
                  title: 'Cómo afecta el volumen',
                  body: help.volumeImpact,
                ),
                _HelpSection(
                  title: 'Error común a evitar',
                  body: help.commonMistake,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String body;

  const _HelpSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
