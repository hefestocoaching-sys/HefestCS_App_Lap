import 'package:equatable/equatable.dart';

/// Modelo de configuración de plan de entrenamiento
class TrainingPlanConfig extends Equatable {
  final String id;
  final String clientId;
  final DateTime startDate;
  final List<dynamic> weeks; // TrainingWeek
  final DateTime createdAt;
  final Map<String, dynamic> extra;

  const TrainingPlanConfig({
    required this.id,
    required this.clientId,
    required this.startDate,
    required this.weeks,
    required this.createdAt,
    required this.extra,
  });

  @override
  List<Object?> get props => [id, clientId, startDate, weeks, createdAt, extra];
}
