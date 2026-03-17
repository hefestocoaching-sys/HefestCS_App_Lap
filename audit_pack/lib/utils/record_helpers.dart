// lib/utils/record_helpers.dart
import 'package:flutter/material.dart';

/// Helper genérico para upsert (update or insert) de registros por fecha.
///
/// Esta función centraliza la lógica de:
/// 1. Eliminar registro existente del mismo día (usando DateUtils.isSameDay)
/// 2. Agregar el nuevo registro
/// 3. Ordenar la lista por fecha ascendente
///
/// **Uso:**
/// ```dart
/// final updatedRecords = upsertRecordByDate<AnthropometryRecord>(
///   existingRecords: client.anthropometry,
///   newRecord: newRecord,
///   dateExtractor: (record) => record.date,
/// );
/// ```
///
/// **Parámetros:**
/// - [existingRecords]: Lista actual de registros
/// - [newRecord]: Registro nuevo o actualizado a insertar
/// - [dateExtractor]: Función que extrae la fecha del registro
/// - [sortAscending]: true para orden ascendente (por defecto), false para descendente
///
/// **Comportamiento:**
/// - Si existe un registro del mismo día: lo sobrescribe
/// - Si no existe: agrega el nuevo
/// - Siempre retorna lista ordenada por fecha
List<T> upsertRecordByDate<T>({
  required List<T> existingRecords,
  required T newRecord,
  required DateTime Function(T) dateExtractor,
  bool sortAscending = true,
}) {
  final newRecordDate = dateExtractor(newRecord);

  final updated = List<T>.from(existingRecords)
    ..removeWhere((r) => DateUtils.isSameDay(dateExtractor(r), newRecordDate))
    ..add(newRecord);

  updated.sort((a, b) {
    final comparison = dateExtractor(a).compareTo(dateExtractor(b));
    return sortAscending ? comparison : -comparison;
  });

  return updated;
}

/// Helper genérico para upsert de registros usando una clave de fecha ISO string.
///
/// Útil cuando los registros usan string ISO (ej: "2026-01-02") en lugar de DateTime.
///
/// **Uso:**
/// ```dart
/// final updatedLogs = upsertRecordByDateIso<TrainingSessionLog>(
///   existingRecords: logs,
///   newRecord: newLog,
///   dateIsoExtractor: (log) => log.dateIso,
/// );
/// ```
///
/// **Parámetros:**
/// - [existingRecords]: Lista actual de registros
/// - [newRecord]: Registro nuevo o actualizado a insertar
/// - [dateIsoExtractor]: Función que extrae el string ISO de fecha del registro
/// - [sortAscending]: true para orden ascendente (por defecto), false para descendente
///
/// **Comportamiento:**
/// - Compara fechas usando igualdad exacta de strings ISO
/// - Sobrescribe si la fecha ISO coincide
/// - Retorna lista ordenada por fecha ISO
List<T> upsertRecordByDateIso<T>({
  required List<T> existingRecords,
  required T newRecord,
  required String Function(T) dateIsoExtractor,
  bool sortAscending = true,
}) {
  final newRecordDateIso = dateIsoExtractor(newRecord);

  final updated = List<T>.from(existingRecords)
    ..removeWhere((r) => dateIsoExtractor(r) == newRecordDateIso)
    ..add(newRecord);

  updated.sort((a, b) {
    final comparison = dateIsoExtractor(a).compareTo(dateIsoExtractor(b));
    return sortAscending ? comparison : -comparison;
  });

  return updated;
}
