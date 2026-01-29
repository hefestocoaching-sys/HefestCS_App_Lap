import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/transaction.dart';
import 'package:hcs_app_lap/features/dashboard_feature/providers/transactions_provider.dart';
import 'package:hcs_app_lap/features/dashboard_feature/widgets/quick_stat_card.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Resumen financiero mensual
class FinancialSummaryWidget extends ConsumerStatefulWidget {
  const FinancialSummaryWidget({super.key});

  @override
  ConsumerState<FinancialSummaryWidget> createState() =>
      _FinancialSummaryWidgetState();
}

class _FinancialSummaryWidgetState
    extends ConsumerState<FinancialSummaryWidget> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final income = transactionsNotifier.getMonthlyIncome(_selectedMonth);
    final expenses = transactionsNotifier.getMonthlyExpenses(_selectedMonth);
    final profit = income - expenses;
    final roi = transactionsNotifier.getROI(_selectedMonth);

    final incomeBreakdown = transactionsNotifier.getIncomeBreakdown(
      _selectedMonth,
    );
    final expenseBreakdown = transactionsNotifier.getExpenseBreakdown(
      _selectedMonth,
    );

    final canGoNext =
        _selectedMonth.month < DateTime.now().month ||
        _selectedMonth.year < DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F2E).withAlpha(245),
            const Color(0xFF1A1F2E).withAlpha(240),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withAlpha(30),
                      const Color(0xFF00D9FF).withAlpha(20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withAlpha(50),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF00D9FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Resumen Financiero',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withAlpha(10),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: kTextColor,
                        size: 20,
                      ),
                      onPressed: _previousMonth,
                      tooltip: 'Mes anterior',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        DateFormat('MMMM yyyy', 'es').format(_selectedMonth),
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: canGoNext ? kTextColor : kTextColorSecondary,
                        size: 20,
                      ),
                      onPressed: canGoNext ? _nextMonth : null,
                      tooltip: 'Siguiente mes',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Resumen principal
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Ingresos',
                  formatMXN(income),
                  kSuccessColor,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Gastos',
                  formatMXN(expenses),
                  Colors.red[400]!,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Ganancia',
                  formatMXN(profit),
                  profit >= 0 ? kSuccessColor : Colors.red[400]!,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: kTextColorSecondary, height: 1),
          const SizedBox(height: 20),

          // Desglose de ingresos
          const Text(
            'INGRESOS',
            style: TextStyle(
              color: kTextColorSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...incomeBreakdown.entries.map((entry) {
            return _buildBreakdownItem(
              entry.key.label,
              entry.value,
              income,
              kSuccessColor,
            );
          }),
          const SizedBox(height: 16),

          // Desglose de gastos
          const Text(
            'GASTOS',
            style: TextStyle(
              color: kTextColorSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...expenseBreakdown.entries.map((entry) {
            return _buildBreakdownItem(
              entry.key.label,
              entry.value,
              expenses,
              Colors.red[400]!,
            );
          }),
          const SizedBox(height: 20),
          const Divider(color: kTextColorSecondary, height: 1),
          const SizedBox(height: 20),

          // ROI
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (roi >= 100 ? kSuccessColor : const Color(0xFFF59E0B))
                      .withAlpha(25),
                  (roi >= 100 ? kSuccessColor : const Color(0xFFF59E0B))
                      .withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (roi >= 100 ? kSuccessColor : const Color(0xFFF59E0B))
                    .withAlpha(60),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'ROI (Retorno de Inversión)',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${roi.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: roi >= 100
                            ? kSuccessColor
                            : const Color(0xFFF59E0B),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.trending_up,
                      color: roi >= 100
                          ? kSuccessColor
                          : const Color(0xFFF59E0B),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withAlpha(25), color.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double amount,
    double total,
    Color color,
  ) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: kTextColor, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMXN(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: kAppBarColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
