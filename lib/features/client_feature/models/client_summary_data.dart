import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/services/anthropometry_analyzer.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';

/// Modelo que encapsula los datos resumidos del cliente.
/// Una única fuente de verdad para porcentajes de grasa, músculo y tipo de plan.
class ClientSummaryData {
  /// Porcentaje de grasa corporal (ej: 25.3)
  final double? bodyFatPercent;

  /// Porcentaje de masa muscular (ej: 35.8)
  final double? musclePercent;

  /// Tipo de plan (ej: "Mensual", "Trimestral", etc.)
  final String planLabel;

  /// Si el plan está activo (endDate > ahora)
  final bool isActivePlan;

  const ClientSummaryData({
    required this.bodyFatPercent,
    required this.musclePercent,
    required this.planLabel,
    required this.isActivePlan,
  });

  /// Factory constructor que extrae la lógica del ClientSummaryHeader antiguo.
  /// Calcula porcentajes a partir del último AnthropometryRecord disponible.
  factory ClientSummaryData.fromClient(Client client, DateTime referenceDate) {
    final analyzer = AnthropometryAnalyzer();

    double? bodyFatPercent;
    double? musclePercent;

    // Obtener el registro más reciente en o antes de la fecha de referencia
    final latest = client.latestAnthropometryAtOrBefore(referenceDate);

    if (latest != null) {
      final analysis = analyzer.analyze(
        record: latest,
        age: client.profile.age,
        gender: client.profile.gender?.label ?? 'Hombre',
      );
      bodyFatPercent = analysis.bodyFatPercentage;
      musclePercent = analysis.muscleMassPercent;
    }

    // Plan label y estado
    final isActive =
        client.nutrition.planEndDate?.isAfter(DateTime.now()) ?? false;
    final planLabel = client.nutrition.planType ?? 'N/A';

    return ClientSummaryData(
      bodyFatPercent: bodyFatPercent,
      musclePercent: musclePercent,
      planLabel: planLabel,
      isActivePlan: isActive,
    );
  }

  /// Formatea el porcentaje de grasa para mostrar (ej: "25.3%")
  String get formattedBodyFat {
    if (bodyFatPercent == null) return 'N/A';
    return '${bodyFatPercent!.toStringAsFixed(1)}%';
  }

  /// Formatea el porcentaje de músculo para mostrar (ej: "35.8%")
  String get formattedMuscle {
    if (musclePercent == null) return 'N/A';
    return '${musclePercent!.toStringAsFixed(1)}%';
  }
}
