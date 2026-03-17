import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';

/// Helper público para resolver el registro antropométrico más reciente
class LatestRecordResolver {
  const LatestRecordResolver();

  /// Obtiene el registro antropométrico más reciente por fecha real del record
  ///
  /// Reglas:
  /// - Si records está vacío -> null
  /// - Ordena por fecha real del record (no DateTime.now())
  /// - Toma el máximo por fecha
  AnthropometryRecord? latestAnthropometry(List<AnthropometryRecord> records) {
    if (records.isEmpty) return null;

    // Ordenar por fecha descendente y tomar el primero
    final sorted = List<AnthropometryRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sorted.first;
  }
}
