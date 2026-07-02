import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:hcs_app_lap/domain/entities/transaction.dart' as app;

/// Repositorio para gestionar transacciones financieras
class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  /// Obtener todas las transacciones de un entrenador
  Stream<List<app.Transaction>> getTransactionsStream(String trainerId) {
    return _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    app.Transaction.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Obtener transacciones del mes actual
  Stream<List<app.Transaction>> getMonthTransactions(
    String trainerId, {
    DateTime? month,
  }) {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1);

    return _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    app.Transaction.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Obtener ingresos del mes
  Stream<List<app.Transaction>> getMonthIncome(
    String trainerId, {
    DateTime? month,
  }) {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1);

    return _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .where('type', isEqualTo: app.TransactionType.income.name)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    app.Transaction.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Obtener gastos del mes
  Stream<List<app.Transaction>> getMonthExpenses(
    String trainerId, {
    DateTime? month,
  }) {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1);

    return _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .where('type', isEqualTo: app.TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    app.Transaction.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Crear nueva transacción
  Future<String> createTransaction(
    String trainerId,
    app.Transaction transaction,
  ) async {
    final docRef = await _firestore.collection(_collection).add({
      ...transaction.toJson(),
      'trainerId': trainerId,
      'id': null, // Firestore generará el ID
    });

    return docRef.id;
  }

  /// Actualizar transacción
  Future<void> updateTransaction(app.Transaction transaction) async {
    await _firestore
        .collection(_collection)
        .doc(transaction.id)
        .update(transaction.toJson());
  }

  /// Eliminar transacción
  Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection(_collection).doc(transactionId).delete();
  }

  /// Calcular total de ingresos del mes
  Future<double> calculateMonthlyIncome(
    String trainerId, {
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1);

    final snapshot = await _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .where('type', isEqualTo: app.TransactionType.income.name)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .get();

    return snapshot.docs.fold<double>(0.0, (total, doc) {
      final rawAmount = doc.data()['amount'];
      final amount = readFiniteAmount(rawAmount);
      if (amount == null) {
        if (rawAmount != null) {
          developer.log(
            'Skipping invalid income amount for transaction ${doc.id}: ${rawAmount.runtimeType}',
            name: 'TransactionRepository',
          );
        }
        return total;
      }
      return total + amount;
    });
  }

  /// Calcular total de gastos del mes
  Future<double> calculateMonthlyExpenses(
    String trainerId, {
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1);

    final snapshot = await _firestore
        .collection(_collection)
        .where('trainerId', isEqualTo: trainerId)
        .where('type', isEqualTo: app.TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .get();

    return snapshot.docs.fold<double>(0.0, (total, doc) {
      final rawAmount = doc.data()['amount'];
      final amount = readFiniteAmount(rawAmount);
      if (amount == null) {
        if (rawAmount != null) {
          developer.log(
            'Skipping invalid expense amount for transaction ${doc.id}: ${rawAmount.runtimeType}',
            name: 'TransactionRepository',
          );
        }
        return total;
      }
      return total + amount;
    });
  }
}

double? readFiniteAmount(Object? raw) {
  if (raw is num && raw.isFinite) {
    return raw.toDouble();
  }
  return null;
}
