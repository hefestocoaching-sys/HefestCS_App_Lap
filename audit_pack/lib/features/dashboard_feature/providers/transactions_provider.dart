import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/transaction.dart';
import 'package:hcs_app_lap/data/repositories/transaction_firestore_datasource.dart';

class TransactionsNotifier extends Notifier<List<Transaction>> {
  late final TransactionFirestoreDataSource _datasource;

  @override
  List<Transaction> build() {
    _datasource = TransactionFirestoreDataSource();
    _loadTransactions();
    return [];
  }

  /// Cargar transacciones desde Firestore
  Future<void> _loadTransactions() async {
    try {
      final transactions = await _datasource.getTransactions();
      state = transactions;
    } catch (e) {
      state = [];
    }
  }

  /// Recargar transacciones
  Future<void> refresh() async {
    await _loadTransactions();
  }

  /// Agregar nueva transacción
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _datasource.addTransaction(transaction);
      state = [...state, transaction];
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar transacción
  Future<void> updateTransaction(Transaction updated) async {
    try {
      await _datasource.updateTransaction(updated);
      state = [
        for (final txn in state)
          if (txn.id == updated.id) updated else txn,
      ];
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar transacción
  Future<void> deleteTransaction(String id) async {
    try {
      await _datasource.deleteTransaction(id);
      state = state.where((txn) => txn.id != id).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener transacciones por mes
  List<Transaction> getTransactionsByMonth(DateTime month) {
    return state.where((txn) {
      return txn.date.year == month.year && txn.date.month == month.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Calcular ingresos del mes
  double getMonthlyIncome(DateTime month) {
    return getTransactionsByMonth(month)
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  /// Calcular gastos del mes
  double getMonthlyExpenses(DateTime month) {
    return getTransactionsByMonth(month)
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  /// Calcular ganancia neta del mes
  double getMonthlyProfit(DateTime month) {
    return getMonthlyIncome(month) - getMonthlyExpenses(month);
  }

  /// Calcular ROI (Return on Investment)
  double getROI(DateTime month) {
    final expenses = getMonthlyExpenses(month);
    if (expenses == 0) return 0.0;
    final profit = getMonthlyProfit(month);
    return (profit / expenses) * 100;
  }

  /// Obtener resumen de ingresos por categoría
  Map<TransactionCategory, double> getIncomeBreakdown(DateTime month) {
    final transactions = getTransactionsByMonth(
      month,
    ).where((txn) => txn.type == TransactionType.income);

    final Map<TransactionCategory, double> breakdown = {};
    for (final txn in transactions) {
      breakdown[txn.category] = (breakdown[txn.category] ?? 0.0) + txn.amount;
    }
    return breakdown;
  }

  /// Obtener resumen de gastos por categoría
  Map<TransactionCategory, double> getExpenseBreakdown(DateTime month) {
    final transactions = getTransactionsByMonth(
      month,
    ).where((txn) => txn.type == TransactionType.expense);

    final Map<TransactionCategory, double> breakdown = {};
    for (final txn in transactions) {
      breakdown[txn.category] = (breakdown[txn.category] ?? 0.0) + txn.amount;
    }
    return breakdown;
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(
      () => TransactionsNotifier(),
    );
