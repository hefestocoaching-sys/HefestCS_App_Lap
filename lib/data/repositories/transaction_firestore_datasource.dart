import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/domain/entities/transaction.dart'
    as app_transaction;

/// Datasource para gestionar transacciones financieras en Firestore
/// Estructura: coaches/{coachId}/transactions/{transactionId}
class TransactionFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Obtener referencia a la colección de transactions del coach actual
  CollectionReference<Map<String, dynamic>>? _transactionsCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('coaches')
        .doc(userId)
        .collection('transactions');
  }

  /// Stream de todas las transacciones del coach
  Stream<List<app_transaction.Transaction>> watchTransactions() {
    final collection = _transactionsCollection();
    if (collection == null) {
      return Stream.value([]);
    }

    return collection.orderBy('date', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return app_transaction.Transaction.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<app_transaction.Transaction>()
          .toList();
    });
  }

  /// Obtener todas las transacciones del coach
  Future<List<app_transaction.Transaction>> getTransactions() async {
    final collection = _transactionsCollection();
    if (collection == null) return [];

    try {
      final snapshot = await collection.orderBy('date', descending: true).get();
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return app_transaction.Transaction.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<app_transaction.Transaction>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Agregar nueva transacción
  Future<void> addTransaction(app_transaction.Transaction transaction) async {
    final collection = _transactionsCollection();
    if (collection == null) return;

    try {
      await collection.doc(transaction.id).set(transaction.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar transacción existente
  Future<void> updateTransaction(
    app_transaction.Transaction transaction,
  ) async {
    final collection = _transactionsCollection();
    if (collection == null) return;

    try {
      await collection.doc(transaction.id).update(transaction.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar transacción
  Future<void> deleteTransaction(String transactionId) async {
    final collection = _transactionsCollection();
    if (collection == null) return;

    try {
      await collection.doc(transactionId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener transacciones por mes
  Future<List<app_transaction.Transaction>> getTransactionsByMonth(
    DateTime month,
  ) async {
    final collection = _transactionsCollection();
    if (collection == null) return [];

    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await collection
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return app_transaction.Transaction.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<app_transaction.Transaction>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener transacciones de un cliente específico
  Future<List<app_transaction.Transaction>> getClientTransactions(
    String clientId,
  ) async {
    final collection = _transactionsCollection();
    if (collection == null) return [];

    try {
      final snapshot = await collection
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return app_transaction.Transaction.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<app_transaction.Transaction>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
