import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';

import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/services/anthropometry_analyzer.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:intl/intl.dart';

class ClientSummaryPanel extends ConsumerWidget {
  final Client? client;
  final VoidCallback onTap;

  const ClientSummaryPanel({
    super.key,
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final currentClient = client; // Local variable for null promotion
      final globalDate = ref.watch(globalDateProvider);
      final analyzer = AnthropometryAnalyzer();
      String fatPerc = 'N/A';
      String musclePerc = 'N/A';
      String bonePerc = 'N/A';
      String residualPerc = 'N/A';
      String insight = '';
      final latest = currentClient?.latestAnthropometryAtOrBefore(globalDate);
      if (currentClient != null && latest != null) {
        final analysis = analyzer.analyze(
          record: latest,
          age: currentClient.profile.age,
          gender: currentClient.profile.gender?.label ?? 'Hombre',
        );
        fatPerc = analysis.bodyFatPercentage?.toStringAsFixed(1) ?? 'N/A';
        musclePerc = analysis.muscleMassPercent?.toStringAsFixed(1) ?? 'N/A';
        bonePerc = analysis.boneMassPercent?.toStringAsFixed(1) ?? 'N/A';
        // Masa residual = 100% - grasa - músculo - óseo
        if (analysis.bodyFatPercentage != null &&
            analysis.muscleMassPercent != null &&
            analysis.boneMassPercent != null) {
          final residual =
              100.0 -
              analysis.bodyFatPercentage! -
              analysis.muscleMassPercent! -
              analysis.boneMassPercent!;
          residualPerc = residual.toStringAsFixed(1);
        }
        insight = analysis.overallInterpretation ?? '';
      }
      final Color searchTextColor = Colors.grey[800]!;
      final String planStartDate =
          currentClient?.nutrition.planStartDate != null
          ? DateFormat(
              'dd/MM/yyyy',
            ).format(currentClient!.nutrition.planStartDate!)
          : 'N/A';
      final String planEndDate = currentClient?.nutrition.planEndDate != null
          ? DateFormat(
              'dd/MM/yyyy',
            ).format(currentClient!.nutrition.planEndDate!)
          : 'N/A';
      final bool isActive =
          (currentClient?.nutrition.planEndDate?.isAfter(DateTime.now()) ??
          false);

      return LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportHeight,
                maxHeight: viewportHeight,
              ),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(8.0),
                      child: InputDecorator(
                        decoration: hcsDecoration(
                          context,
                          hintText: 'Buscar cliente...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: searchTextColor,
                          ),
                        ),
                        child: Text(
                          "Buscar cliente...",
                          style: TextStyle(
                            color: searchTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(225),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: kCardShadow,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: kBackgroundColor,
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_outline,
                                size: 50,
                                color: kTextColorSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentClient?.fullName.isEmpty ?? true
                                ? "Seleccionar Cliente"
                                : currentClient!.fullName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontSize: 18, color: kTextColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (currentClient != null &&
                              currentClient.profile.objective.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                currentClient.profile.objective,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: kTextColorSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildInfoRow(
                      context,
                      'Estatus:',
                      widget: _buildStatusChip(
                        context,
                        isActive ? 'Activo' : 'Inactivo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Plan:',
                      value: currentClient?.nutrition.planType ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Inicio:', value: planStartDate),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Término:', value: planEndDate),

                    const Divider(height: 32, color: kBackgroundColor),

                    // Composición Corporal compacta con 4 componentes + insight
                    Container(
                      decoration: BoxDecoration(
                        color: kBackgroundColor.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kTextColorSecondary.withAlpha(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grid 2x2 de componentes
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactCompositionItem(
                                  label: '% Grasa',
                                  value: fatPerc,
                                  icon: Icons.water_drop_outlined,
                                  color: Colors.blue[400]!,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactCompositionItem(
                                  label: '% Músculo',
                                  value: musclePerc,
                                  icon: Icons.favorite,
                                  color: Colors.red[400]!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactCompositionItem(
                                  label: '% Óseo',
                                  value: bonePerc,
                                  icon: Icons.domain,
                                  color: Colors.amber[600]!,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactCompositionItem(
                                  label: '% Residual',
                                  value: residualPerc,
                                  icon: Icons.info_outline,
                                  color: Colors.grey[500]!,
                                ),
                              ),
                            ],
                          ),
                          // Insight debajo si existe
                          if (insight.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                insight,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextColorSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Divider(height: 32, color: kBackgroundColor),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        child: const Text(
          'No se pudo renderizar el resumen del cliente.',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label, {
    String? value,
    Widget? widget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kTextColorSecondary),
        ),
        if (value != null)
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: kTextColor, fontSize: 14),
          ),
        if (widget != null) widget,
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final bool isActive = status == 'Activo';
    final Color chipColor = isActive
        ? Colors.green.shade900.withAlpha(127)
        : Colors.red.shade900.withAlpha(127);
    final Color textColor = isActive
        ? Colors.green.shade200
        : Colors.red.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: textColor.withAlpha(127)),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: textColor, fontSize: 10),
      ),
    );
  }

  Widget _buildCompactCompositionItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(100),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: kTextColorSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '$value %',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
