import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/services/nutrition_plan_pdf_service.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

class ClientActionPanel extends ConsumerWidget {
  final Client client;
  const ClientActionPanel({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalDate = ref.watch(globalDateProvider);
    final Color statCardColor = Theme.of(context).cardColor.withAlpha(127);
    final TextStyle statLabelStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey[400],
    );
    const TextStyle statValueStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final latestRecord = client.latestAnthropometryAtOrBefore(globalDate);
    // Simplified, real logic would be more complex
    final String fatPerc = latestRecord?.thighFold?.toStringAsFixed(1) ?? 'N/A';
    final String weight = latestRecord?.weightKg?.toStringAsFixed(1) ?? 'N/A';
    final double? weightVal = latestRecord?.weightKg;
    final double? fatPercVal = latestRecord?.thighFold; // Simplified
    final String fatMass = (weightVal != null && fatPercVal != null)
        ? (weightVal * (fatPercVal / 100.0)).toStringAsFixed(1)
        : 'N/A';
    const String muscleMass = 'N/A';
    final evalRecords = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final evalRecord = latestNutritionRecordByDate(evalRecords);
    final String kcalValue =
        (evalRecord?['kcal'] as num?)?.toString() ??
        client.nutrition.kcal?.toString() ??
        'N/A';

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Datos Clave y Acciones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: '% Grasa',
                    value: '$fatPerc %',
                    cardColor: statCardColor,
                    labelStyle: statLabelStyle,
                    valueStyle: statValueStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Masa Grasa',
                    value: '$fatMass kg',
                    cardColor: statCardColor,
                    labelStyle: statLabelStyle,
                    valueStyle: statValueStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: '% Músculo',
                    value: 'N/A',
                    cardColor: statCardColor,
                    labelStyle: statLabelStyle,
                    valueStyle: statValueStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Masa Muscular',
                    value: muscleMass,
                    cardColor: statCardColor,
                    labelStyle: statLabelStyle,
                    valueStyle: statValueStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Kcal',
                    value: kcalValue,
                    cardColor: statCardColor,
                    labelStyle: statLabelStyle,
                    valueStyle: statValueStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Peso',
                    value: '$weight kg',
                    cardColor: statCardColor,
                    labelStyle: statLabelStyle,
                    valueStyle: statValueStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Divider(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text('WHATSAPP'),
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent[400],
                      side: BorderSide(color: Colors.greenAccent[400]!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text('GMAIL'),
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent[200],
                      side: BorderSide(color: Colors.redAccent[200]!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('DISEÑAR PLAN'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.fitness_center),
              label: const Text('DISEÑAR RUTINA'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const Divider(height: 32),

            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('EXPORTAR PDF'),
              onPressed: () async {
                final dateIso = dateIsoFrom(globalDate);
                final path = await nutritionPlanPdfService.generateForClient(
                  client: client,
                  dateIso: dateIso,
                );
                if (!context.mounted) return;
                final message = path == null
                    ? 'No hay plan de comidas para exportar.'
                    : 'PDF generado en $path';
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color cardColor,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 4),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
