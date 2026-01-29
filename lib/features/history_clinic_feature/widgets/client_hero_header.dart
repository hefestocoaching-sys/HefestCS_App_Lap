import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/client_feature/models/client_summary_data.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';

/// ClientHeroHeader: Header hero para mostrar información destacada del cliente.
/// Extrae datos del ClientSummaryData para garantizar una única fuente de verdad.
class ClientHeroHeader extends ConsumerWidget {
  final Client client;

  const ClientHeroHeader({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalDate = ref.watch(globalDateProvider);
    final summary = ClientSummaryData.fromClient(client, globalDate);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto del cliente
          _buildPhoto(context),
          const SizedBox(width: 24),

          // Información central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.profile.fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  client.profile.objective.isNotEmpty
                      ? client.profile.objective
                      : 'Sin objetivo especificado',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Indicadores a la derecha (usando datos de summary)
          _buildIndicators(context, summary),
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: _buildPhotoPlaceholder(context),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 40,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildIndicators(BuildContext context, ClientSummaryData summary) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          context,
          label: 'Grasa ${summary.formattedBodyFat}',
          color: theme.colorScheme.secondaryContainer,
        ),
        _buildChip(
          context,
          label: 'Músculo ${summary.formattedMuscle}',
          color: theme.colorScheme.tertiaryContainer,
        ),
        if (summary.planLabel != 'N/A')
          _buildChip(
            context,
            label: summary.planLabel,
            color: summary.isActivePlan
                ? Colors.green.shade100
                : Colors.grey.shade200,
          ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
