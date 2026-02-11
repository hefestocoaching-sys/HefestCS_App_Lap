import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ClientSummaryScreen extends StatelessWidget {
  final Client client;

  const ClientSummaryScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre del cliente
          Text(
            'Resumen de ${client.profile.fullName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Métricas principales
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Peso',
                  value: client.lastWeight?.toStringAsFixed(1) ?? '--',
                  unit: 'kg',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: 'Altura',
                  value:
                      (client.initialHeightCm != null
                              ? (client.initialHeightCm! / 100)
                              : null)
                          ?.toStringAsFixed(2) ??
                      '--',
                  unit: 'm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Información de calorías y macros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Nutricional',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Calorías Diarias',
                  value: client.kcal?.toString() ?? '--',
                  unit: 'kcal',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Estado del cliente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: client.status.name == 'active'
                            ? Colors.green.withAlpha(50)
                            : Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        client.status.name == 'active' ? 'Activo' : 'Inactivo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: client.status.name == 'active'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Registro',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      _formatDate(client.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Plan de entrenamiento actual
          if (client.trainingPlans.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan de Entrenamiento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${client.trainingPlans.length} plan(es) activo(s)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        Text(
          '$value $unit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }
}
