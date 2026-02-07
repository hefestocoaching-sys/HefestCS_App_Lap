import 'dart:convert';

class TrainingInterview {
  final String id;
  final String clientId;
  final int version;
  final String status;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const TrainingInterview({
    required this.id,
    required this.clientId,
    required this.version,
    required this.status,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory TrainingInterview.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final decoded = rawData is String ? jsonDecode(rawData) : rawData;

    return TrainingInterview(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      version: map['version'] as int? ?? 1,
      status: map['status'] as String? ?? 'empty',
      data: Map<String, dynamic>.from(decoded as Map? ?? const {}),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'version': version,
      'status': status,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory TrainingInterview.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final decoded = rawData is String ? jsonDecode(rawData) : rawData;

    return TrainingInterview(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      version: json['version'] as int? ?? 1,
      status: json['status'] as String? ?? 'empty',
      data: Map<String, dynamic>.from(decoded as Map? ?? const {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'version': version,
      'status': status,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  TrainingInterview copyWith({
    String? id,
    String? clientId,
    int? version,
    String? status,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TrainingInterview(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      version: version ?? this.version,
      status: status ?? this.status,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
