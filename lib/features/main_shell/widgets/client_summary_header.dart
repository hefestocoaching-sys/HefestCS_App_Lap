import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/client_feature/models/client_summary_data.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Header compacto con resumen del cliente activo
/// Se muestra arriba del contenido clínico cuando hay un cliente seleccionado
class ClientSummaryHeader extends ConsumerWidget {
  final Client client;

  const ClientSummaryHeader({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalDate = ref.watch(globalDateProvider);
    final summary = ClientSummaryData.fromClient(client, globalDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor.withAlpha((255 * 0.5).round()),
        border: Border(
          bottom: BorderSide(
            color: kAppBarColor.withAlpha((255 * 0.3).round()),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar y nombre
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, size: 24, color: kPrimaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (client.profile.objective.isNotEmpty)
                  Text(
                    client.profile.objective,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kTextColorSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // KPIs compactos
          const SizedBox(width: 16),
          _buildCompactKpi(
            icon: Icons.water_drop_outlined,
            label: 'Grasa',
            value: summary.formattedBodyFat,
          ),
          const SizedBox(width: 16),
          _buildCompactKpi(
            icon: Icons.man,
            label: 'Músculo',
            value: summary.formattedMuscle,
          ),

          // Estado y plan
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: summary.isActivePlan
                  ? Colors.green.withAlpha(30)
                  : Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: summary.isActivePlan
                    ? Colors.green.withAlpha(100)
                    : Colors.grey.withAlpha(100),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  summary.isActivePlan ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: summary.isActivePlan ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  summary.planLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: summary.isActivePlan
                        ? Colors.green
                        : kTextColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactKpi({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: kTextColorSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: kTextColorSecondary),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
