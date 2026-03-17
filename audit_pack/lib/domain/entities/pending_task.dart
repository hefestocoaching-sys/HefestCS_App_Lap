/// Entidad para tareas pendientes en el dashboard operacional
class PendingTask {
  final String id;
  final String clientId;
  final String title;
  final String? description;
  final PendingTaskPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isResolved;

  const PendingTask({
    required this.id,
    required this.clientId,
    required this.title,
    this.description,
    this.priority = PendingTaskPriority.normal,
    required this.createdAt,
    this.dueDate,
    this.isResolved = false,
  });

  PendingTask copyWith({
    String? id,
    String? clientId,
    String? title,
    String? description,
    PendingTaskPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isResolved,
  }) {
    return PendingTask(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'isResolved': isResolved,
    };
  }

  factory PendingTask.fromJson(Map<String, dynamic> json) {
    return PendingTask(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: PendingTaskPriority.values.byName(
        (json['priority'] as String?) ?? 'normal',
      ),
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'].toString()),
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] is DateTime
                ? json['dueDate'] as DateTime
                : DateTime.parse(json['dueDate'].toString()))
          : null,
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }
}

/// Prioridades de tareas pendientes
enum PendingTaskPriority { low, normal, high, urgent }

/// Extensiones para PendingTaskPriority
extension PendingTaskPriorityExt on PendingTaskPriority {
  String get label {
    switch (this) {
      case PendingTaskPriority.low:
        return 'Baja';
      case PendingTaskPriority.normal:
        return 'Normal';
      case PendingTaskPriority.high:
        return 'Alta';
      case PendingTaskPriority.urgent:
        return 'Urgente';
    }
  }

  String get emoji {
    switch (this) {
      case PendingTaskPriority.low:
        return '📌';
      case PendingTaskPriority.normal:
        return '📋';
      case PendingTaskPriority.high:
        return '⚠️';
      case PendingTaskPriority.urgent:
        return '🔴';
    }
  }
}
