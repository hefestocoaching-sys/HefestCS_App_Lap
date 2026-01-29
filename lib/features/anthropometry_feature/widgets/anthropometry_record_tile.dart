import 'package:flutter/material.dart';

/// Componente tile para cada registro antropométrico.
/// Muestra fecha, estado y permite navegación al detalle.
class AnthropometryRecordTile extends StatelessWidget {
  final String date;
  final String status;
  final VoidCallback onTap;

  const AnthropometryRecordTile({
    super.key,
    required this.date,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
