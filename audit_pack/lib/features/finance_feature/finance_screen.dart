import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/transactions_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Pantalla de gestión de Ingresos/Finanzas
///
/// Placeholder mínimo con estética existente.
/// Muestra resumen de ingresos/gastos si hay, o mensaje de placeholder.
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final now = DateTime.now();
    final monthlyIncome = transactionsNotifier.getMonthlyIncome(now);
    final monthlyExpenses = transactionsNotifier.getMonthlyExpenses(now);
    final monthlyProfit = monthlyIncome - monthlyExpenses;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Ingresos y Finanzas'),
        backgroundColor: kAppBarColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              const Text(
                'Gestión Financiera',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen del mes: ${DateFormat('MMMM yyyy', 'es_ES').format(now)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: kTextColorSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Resumen rápido
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      'Ingresos',
                      formatMXN(monthlyIncome),
                      kSuccessColor,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatTile(
                      'Gastos',
                      formatMXN(monthlyExpenses),
                      Colors.red[400]!,
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatTile(
                'Ganancia Neta',
                formatMXN(monthlyProfit),
                monthlyProfit >= 0 ? kSuccessColor : Colors.red[400]!,
                Icons.trending_up,
              ),
              const SizedBox(height: 32),

              // Contenido placeholder
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.attach_money_outlined,
                      size: 64,
                      color: const Color(0xFFFFB74D).withAlpha(150),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Módulo de finanzas en construcción',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aquí podrás gestionar ingresos, gastos, categorías y reportes financieros detallados.',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextColorSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver al Inicio'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB74D),
                        side: const BorderSide(color: Color(0xFFFFB74D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: kTextColorSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatear moneda mexicana
String formatMXN(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
