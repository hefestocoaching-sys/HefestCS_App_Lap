/// Entidad simple para transacciones financieras (sin Freezed temporalmente)
class Transaction {
  final String id;
  final String? clientId;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final String? notes;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    this.clientId,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    this.notes,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    String? clientId,
    DateTime? date,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? description,
    String? notes,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'date': date,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'description': description,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  /// Crear desde JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      clientId: json['clientId'] as String?,
      date: json['date'] is DateTime
          ? json['date'] as DateTime
          : DateTime.parse(json['date'].toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.byName(
        (json['type'] as String?) ?? 'income',
      ),
      category: TransactionCategory.values.byName(
        (json['category'] as String?) ?? 'otherIncome',
      ),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'].toString()),
    );
  }
}

/// Tipo de transacción
enum TransactionType { income, expense }

/// Categoría de transacción
enum TransactionCategory {
  newPlan,
  renewal,
  consultation,
  software,
  education,
  equipment,
  marketing,
  otherIncome,
  otherExpense,
}

/// Extensiones para TransactionType
extension TransactionTypeExt on TransactionType {
  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}

/// Extensiones para TransactionCategory
extension TransactionCategoryExt on TransactionCategory {
  TransactionType get type {
    switch (this) {
      case TransactionCategory.newPlan:
      case TransactionCategory.renewal:
      case TransactionCategory.consultation:
      case TransactionCategory.otherIncome:
        return TransactionType.income;
      case TransactionCategory.software:
      case TransactionCategory.education:
      case TransactionCategory.equipment:
      case TransactionCategory.marketing:
      case TransactionCategory.otherExpense:
        return TransactionType.expense;
    }
  }

  String get label {
    switch (this) {
      case TransactionCategory.newPlan:
        return 'Plan Nuevo';
      case TransactionCategory.renewal:
        return 'Renovación';
      case TransactionCategory.consultation:
        return 'Consulta';
      case TransactionCategory.software:
        return 'Software';
      case TransactionCategory.education:
        return 'Educación';
      case TransactionCategory.equipment:
        return 'Equipo';
      case TransactionCategory.marketing:
        return 'Marketing';
      case TransactionCategory.otherIncome:
        return 'Otro Ingreso';
      case TransactionCategory.otherExpense:
        return 'Otro Gasto';
    }
  }
}
