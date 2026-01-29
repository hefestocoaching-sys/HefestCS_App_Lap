// ignore_for_file: deprecated_member_use_from_same_package
import 'package:equatable/equatable.dart';

// ============================================================================
// CONTRATO PROVISIONAL (DEPRECADO)
// Mantiene compatibilidad con motor y UI existentes.
// NO usar en código nuevo. Usar TrainingSessionLogV2 en su lugar.
// ============================================================================
@Deprecated('Usar TrainingSessionLogV2 en su lugar')
class TrainingSessionLog {
  final String dateIso;
  final String? sessionName;
  final List<ExerciseLogEntry> entries;
  final String createdAtIso;

  const TrainingSessionLog({
    required this.dateIso,
    required this.sessionName,
    required this.entries,
    required this.createdAtIso,
  });

  Map<String, dynamic> toJson() => {
    'dateIso': dateIso,
    'sessionName': sessionName,
    'entries': entries.map((e) => e.toJson()).toList(),
    'createdAtIso': createdAtIso,
  };

  factory TrainingSessionLog.fromJson(Map<String, dynamic> json) {
    return TrainingSessionLog(
      dateIso: json['dateIso']?.toString() ?? '',
      sessionName: json['sessionName']?.toString(),
      entries: _parseEntries(json['entries']),
      createdAtIso: json['createdAtIso']?.toString() ?? '',
    );
  }

  static List<ExerciseLogEntry> _parseEntries(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (entry) => ExerciseLogEntry.fromJson(entry.cast<String, dynamic>()),
        )
        .toList();
  }
}

@Deprecated('Usar TrainingSessionLogV2 en su lugar')
class ExerciseLogEntry {
  final String exerciseIdOrName;
  final int sets;
  final List<int> reps;
  final List<double> load;
  final List<double>? rpe;

  const ExerciseLogEntry({
    required this.exerciseIdOrName,
    required this.sets,
    required this.reps,
    required this.load,
    required this.rpe,
  });

  Map<String, dynamic> toJson() => {
    'exerciseIdOrName': exerciseIdOrName,
    'sets': sets,
    'reps': reps,
    'load': load,
    'rpe': rpe,
  };

  factory ExerciseLogEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseLogEntry(
      exerciseIdOrName: json['exerciseIdOrName']?.toString() ?? '',
      sets: _parseInt(json['sets']),
      reps: _parseIntList(json['reps']),
      load: _parseDoubleList(json['load']),
      rpe: json['rpe'] == null ? null : _parseDoubleList(json['rpe']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<int> _parseIntList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => _parseInt(item))
        .where((value) => value >= 0)
        .toList();
  }

  static List<double> _parseDoubleList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is double) return item;
          if (item is num) return item.toDouble();
          return double.tryParse(item?.toString() ?? '') ?? 0.0;
        })
        .where((value) => value >= 0)
        .toList();
  }
}

// ============================================================================
// HELPERS DEPRECADOS - mantener para compatibilidad
// ============================================================================

@Deprecated('Usar TrainingSessionLogV2 en su lugar')
List<TrainingSessionLog> readTrainingSessionLogs(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (record) => TrainingSessionLog.fromJson(record.cast<String, dynamic>()),
      )
      .toList();
}

TrainingSessionLog? trainingSessionLogForDate(
  List<TrainingSessionLog> logs,
  String dateIso,
) {
  for (final log in logs) {
    if (log.dateIso == dateIso) {
      return log;
    }
  }
  return null;
}

TrainingSessionLog? latestTrainingSessionLogByDate(
  List<TrainingSessionLog> logs,
) {
  if (logs.isEmpty) return null;
  var latest = logs.first;
  for (final log in logs.skip(1)) {
    if (log.dateIso.compareTo(latest.dateIso) > 0) {
      latest = log;
    }
  }
  return latest;
}

List<TrainingSessionLog> upsertTrainingSessionLogByDate(
  List<TrainingSessionLog> logs,
  TrainingSessionLog log,
) {
  final updated = List<TrainingSessionLog>.from(logs)
    ..removeWhere((entry) => entry.dateIso == log.dateIso)
    ..add(log);
  updated.sort((a, b) => a.dateIso.compareTo(b.dateIso));
  return updated;
}

// ============================================================================
// CONTRATO CANÓNICO V2 - BITÁCORA DE ENTRENAMIENTO
// ============================================================================
// VERSION: v1.0.0
// FECHA DE CONGELAMIENTO: 30 de diciembre de 2025
// BREAKING CHANGES REQUIEREN: v2.0.0
//
// PROPÓSITO:
// - Registrar ejecución real de ejercicios desde app móvil
// - Alimentar Phase 8 (adaptación bidireccional)
// - Auditoría longitudinal de entrenamiento
//
// GARANTÍAS:
// - Offline-first (id generado por cliente)
// - JSON serializable (toJson/fromJson)
// - Forward/backward compatible (schemaVersion)
// - Sin lógica de negocio (solo datos)
// - Inmutable (Equatable)
//
// FLUJO DE DATOS:
// Mobile App → TrainingSessionLogV2 → TrainingFeedbackAggregatorService
// → WeeklyTrainingFeedbackSummary → Phase8AdaptationService
// ============================================================================

/// Bitácora de sesión de entrenamiento (CONTRATO CANÓNICO v1.0.0).
///
/// Representa la ejecución real de un ejercicio en una sesión específica.
/// Esta entidad es la fuente de verdad para adaptación bidireccional
/// del motor de entrenamiento.
///
/// TODOS LOS CAMPOS SON INPUT (desde app móvil o desktop).
/// NO SE CALCULAN CAMPOS DERIVADOS EN ESTA ENTIDAD.
///
/// Los campos derivados (adherenceRatio, avgEffort semanal, signal, etc.)
/// se calculan en [WeeklyTrainingFeedbackSummary] via
/// [TrainingFeedbackAggregatorService].
///
/// VALIDACIONES:
/// - RIR ∈ [0.0, 5.0]
/// - perceivedEffort ∈ [1, 10]
/// - completedSets ≤ plannedSets
/// - source ∈ {'mobile', 'desktop'}
/// - schemaVersion no vacío
/// - completedSets == 0 → stoppedEarly == true
///
/// INMUTABILIDAD:
/// - Toda mutación debe crear nueva instancia.
/// - Extends [Equatable] para comparación por valor.
///
/// IDENTIFICACIÓN:
/// - Única: [id] (UUID generado por cliente)
/// - Lógica: [clientId] + [exerciseId] + [sessionDate]
class TrainingSessionLogV2 extends Equatable {
  // =========================================================================
  // IDENTIFICACIÓN Y METADATA
  // =========================================================================
  // INPUT FROM MOBILE APP
  // DO NOT COMPUTE HERE

  /// Identificador único de la bitácora (UUID).
  ///
  /// Generado por el cliente móvil/desktop antes de persistir.
  /// Usado para sync offline-first y resolución de conflictos.
  final String id;

  /// Identificador del cliente.
  ///
  /// Aislamiento multi-tenant. Usado en filtrado de agregación semanal.
  final String clientId;

  /// Identificador del ejercicio ejecutado.
  ///
  /// Referencia a catálogo de ejercicios. Permite derivar muscleGroup.
  /// Usado en agrupación por músculo en agregación semanal.
  final String exerciseId;

  /// Fecha de la sesión (sin hora, solo día).
  ///
  /// Normalizada a medianoche (00:00:00) para agrupación semanal.
  /// Usado en cálculo de weekStart (lunes) → weekEnd (domingo).
  final DateTime sessionDate;

  /// Timestamp de creación del registro.
  ///
  /// DateTime.now() capturado en cliente al guardar.
  /// Útil para auditoría y resolución de conflictos en sync.
  /// NO usado en lógica de Phase 8.
  final DateTime createdAt;

  /// Origen del registro: 'mobile' | 'desktop'.
  ///
  /// Indica si el log proviene de app móvil o entrada manual desktop.
  /// Útil para trazabilidad. NO afecta lógica de motor.
  final String source;

  /// Versión del esquema del contrato (semver).
  ///
  /// Ejemplo: 'v1.0.0'
  /// Usado para forward/backward compatibility en fromJson.
  /// Cambios breaking requieren bump mayor (v2.0.0).
  final String schemaVersion;

  // =========================================================================
  // DATOS DE VOLUMEN
  // =========================================================================
  // INPUT FROM MOBILE APP
  // DO NOT COMPUTE HERE

  /// Series planificadas originalmente según el plan.
  ///
  /// Valor tomado del plan de entrenamiento activo.
  /// Usado en cálculo de adherencia: completedSets / plannedSets.
  final int plannedSets;

  /// Series efectivamente completadas por el usuario.
  ///
  /// Contador real de sets ejecutados.
  /// Usado como ponderador en promedios (RIR, esfuerzo) y adherencia.
  final int completedSets;

  // =========================================================================
  // DATOS DE INTENSIDAD
  // =========================================================================
  // INPUT FROM MOBILE APP
  // DO NOT COMPUTE HERE

  /// RIR promedio reportado en la sesión (0.0 – 5.0).
  ///
  /// Reps In Reserve percibido por el usuario post-sesión.
  /// Promediado a través de todas las series completadas.
  /// Usado en cálculo de fatiga semanal (avgReportedRIR ponderado).
  final double avgReportedRIR;

  /// Esfuerzo percibido general de la sesión (1 – 10).
  ///
  /// RPE (Rate of Perceived Exertion) subjetivo del usuario.
  /// Indicador de fatiga general. NO es RPE por set.
  /// Usado en cálculo de avgEffort semanal (ponderado por sets).
  final int perceivedEffort;

  // =========================================================================
  // SEÑALES DE ALARMA (BANDERAS CRÍTICAS)
  // =========================================================================
  // INPUT FROM MOBILE APP
  // DO NOT COMPUTE HERE

  /// Indica si la sesión se detuvo anticipadamente.
  ///
  /// true → Sesión interrumpida antes de completar plan.
  /// BANDERA ROJA: Activa fatigueExpectation='high' → deload inmediato.
  /// Si completedSets == 0, este campo DEBE ser true (validación).
  final bool stoppedEarly;

  /// Bandera de dolor durante la ejecución.
  ///
  /// true → Usuario reportó dolor/molestia inusual.
  /// BANDERA ROJA: Activa fatigueExpectation='high' → deload inmediato.
  final bool painFlag;

  /// Bandera de degradación técnica observada.
  ///
  /// true → Usuario nota pérdida de técnica/forma en últimas series.
  /// Señal de fatiga moderada. Menos crítico que painFlag/stoppedEarly.
  /// Contribuye a fatigueExpectation='moderate'.
  final bool formDegradation;

  // =========================================================================
  // NOTAS LIBRES
  // =========================================================================
  // INPUT FROM MOBILE APP
  // DO NOT COMPUTE HERE

  /// Notas adicionales del cliente o entrenador.
  ///
  /// Texto libre. NO procesado por motor de entrenamiento.
  /// Útil para contexto clínico manual y auditoría cualitativa.
  final String? notes;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Crea una nueva instancia de TrainingSessionLogV2.
  ///
  /// TODOS LOS CAMPOS SON REQUERIDOS excepto [notes].
  ///
  /// IMPORTANTE:
  /// - [id]: Generar UUID en cliente antes de llamar constructor.
  /// - [sessionDate]: Normalizar a medianoche (sin hora).
  /// - [createdAt]: Usar DateTime.now() en momento de creación.
  /// - [source]: 'mobile' desde app móvil, 'desktop' desde entrada manual.
  /// - [schemaVersion]: Siempre 'v1.0.0' para esta versión del contrato.
  ///
  /// Llamar [validate()] después de construcción para verificar invariantes.
  const TrainingSessionLogV2({
    required this.id,
    required this.clientId,
    required this.exerciseId,
    required this.sessionDate,
    required this.createdAt,
    required this.source,
    required this.plannedSets,
    required this.completedSets,
    required this.avgReportedRIR,
    required this.perceivedEffort,
    required this.stoppedEarly,
    required this.painFlag,
    required this.formDegradation,
    this.notes,
    required this.schemaVersion,
  });

  // =========================================================================
  // VALIDACIÓN
  // =========================================================================

  /// Valida la integridad del registro según reglas de negocio.
  ///
  /// Lanza [ArgumentError] si se viola alguna invariante:
  ///
  /// - `avgReportedRIR` fuera de rango [0.0, 5.0]
  /// - `perceivedEffort` fuera de rango [1, 10]
  /// - `completedSets` < 0
  /// - `completedSets` > `plannedSets`
  /// - `schemaVersion` vacío
  /// - `source` no es 'mobile' o 'desktop'
  /// - `completedSets == 0` y `stoppedEarly == false` (inconsistencia)
  ///
  /// USO RECOMENDADO:
  /// ```dart
  /// final log = TrainingSessionLogV2(...);
  /// log.validate(); // Lanza si hay error
  /// ```
  void validate() {
    if (avgReportedRIR < 0.0 || avgReportedRIR > 5.0) {
      throw ArgumentError(
        'avgReportedRIR debe estar en el rango [0.0, 5.0]. Valor recibido: $avgReportedRIR',
      );
    }

    if (perceivedEffort < 1 || perceivedEffort > 10) {
      throw ArgumentError(
        'perceivedEffort debe estar en el rango [1, 10]. Valor recibido: $perceivedEffort',
      );
    }

    if (completedSets < 0) {
      throw ArgumentError(
        'completedSets no puede ser negativo. Valor recibido: $completedSets',
      );
    }

    if (completedSets > plannedSets) {
      throw ArgumentError(
        'completedSets ($completedSets) no puede ser mayor que plannedSets ($plannedSets)',
      );
    }

    if (schemaVersion.isEmpty) {
      throw ArgumentError('schemaVersion no puede estar vacío');
    }

    if (source != 'mobile' && source != 'desktop') {
      throw ArgumentError(
        'source debe ser "mobile" o "desktop". Valor recibido: "$source"',
      );
    }

    if (completedSets == 0 && !stoppedEarly) {
      throw ArgumentError('Si completedSets == 0, stoppedEarly debe ser true');
    }
  }

  // =========================================================================
  // SERIALIZACIÓN
  // =========================================================================

  /// Serializa a JSON para persistencia o transferencia.
  ///
  /// FORMATO:
  /// - Fechas en ISO8601 (sessionDate, createdAt)
  /// - Tipos primitivos (int, double, bool, String)
  /// - notes puede ser null
  ///
  /// COMPATIBILIDAD:
  /// - Todos los campos presentes en v1.0.0 se incluyen siempre.
  /// - Versiones futuras pueden agregar campos opcionales.
  ///
  /// USO:
  /// ```dart
  /// final json = log.toJson();
  /// await saveToDatabase(json);
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'exerciseId': exerciseId,
      'sessionDate': sessionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'plannedSets': plannedSets,
      'completedSets': completedSets,
      'avgReportedRIR': avgReportedRIR,
      'perceivedEffort': perceivedEffort,
      'stoppedEarly': stoppedEarly,
      'painFlag': painFlag,
      'formDegradation': formDegradation,
      'notes': notes,
      'schemaVersion': schemaVersion,
    };
  }

  /// Deserializa desde JSON.
  ///
  /// VALIDACIÓN:
  /// - Lanza [FormatException] si fechas no son ISO8601 válidas.
  /// - Lanza [TypeError] si tipos no coinciden.
  /// - NO valida reglas de negocio (llamar [validate()] después).
  ///
  /// FORWARD COMPATIBILITY:
  /// - Ignora campos desconocidos (versiones futuras).
  /// - ⚠️ BREAKING: Lanza error si falta un campo requerido.
  ///   → Para v2.0.0, considerar valores por defecto.
  ///
  /// BACKWARD COMPATIBILITY:
  /// - Versiones antiguas pueden leer JSON de v1.0.0.
  ///
  /// USO:
  /// ```dart
  /// final json = await loadFromDatabase();
  /// final log = TrainingSessionLogV2.fromJson(json);
  /// log.validate(); // Validar invariantes
  /// ```
  factory TrainingSessionLogV2.fromJson(Map<String, dynamic> json) {
    return TrainingSessionLogV2(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      exerciseId: json['exerciseId'] as String,
      sessionDate: DateTime.parse(json['sessionDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String,
      plannedSets: json['plannedSets'] as int,
      completedSets: json['completedSets'] as int,
      avgReportedRIR: (json['avgReportedRIR'] as num).toDouble(),
      perceivedEffort: json['perceivedEffort'] as int,
      stoppedEarly: json['stoppedEarly'] as bool,
      painFlag: json['painFlag'] as bool,
      formDegradation: json['formDegradation'] as bool,
      notes: json['notes'] as String?,
      schemaVersion: json['schemaVersion'] as String,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    exerciseId,
    sessionDate,
    createdAt,
    source,
    plannedSets,
    completedSets,
    avgReportedRIR,
    perceivedEffort,
    stoppedEarly,
    painFlag,
    formDegradation,
    notes,
    schemaVersion,
  ];
}

// ============================================================================
// HELPERS PUROS (SIN SIDE EFFECTS)
// ============================================================================

/// Upsert de bitácora por fecha (V2).
///
/// Reemplaza una bitácora existente con el mismo (clientId, exerciseId, sessionDate),
/// o agrega una nueva si no existe coincidencia.
///
/// INVARIANTES:
/// - Operación inmutable: no modifica [existing].
/// - Lista resultante ordenada ascendentemente por [sessionDate].
/// - Coincidencia estricta por clientId, exerciseId y sessionDate (día completo).
/// - Determinista: mismo input → mismo output (sin DateTime.now()).
/// - Sin side effects: no mutaciones, no I/O, no excepciones.
///
/// LÓGICA:
/// 1. Itera [existing].
/// 2. Si encuentra match (clientId + exerciseId + mismo día), reemplaza con [incoming].
/// 3. Si no hay match, agrega [incoming] al final.
/// 4. Ordena resultado por sessionDate (ascendente).
///
/// USO TÍPICO (offline-first):
/// ```dart
/// // Usuario edita/crea log en móvil
/// final updatedLogs = upsertTrainingSessionLogByDateV2(currentLogs, newLog);
/// await saveToLocalDB(updatedLogs);
/// ```
///
/// CASOS DE USO:
/// - Sync offline: Merge log móvil con caché local.
/// - Edición: Usuario corrige log de fecha pasada.
/// - Creación: Usuario registra nueva sesión.
///
/// Retorna una nueva lista con el upsert aplicado.
List<TrainingSessionLogV2> upsertTrainingSessionLogByDateV2(
  List<TrainingSessionLogV2> existing,
  TrainingSessionLogV2 incoming,
) {
  final result = <TrainingSessionLogV2>[];
  bool replaced = false;

  for (final log in existing) {
    final isSameClient = log.clientId == incoming.clientId;
    final isSameExercise = log.exerciseId == incoming.exerciseId;
    final isSameDate = _isSameDayV2(log.sessionDate, incoming.sessionDate);

    if (isSameClient && isSameExercise && isSameDate) {
      result.add(incoming);
      replaced = true;
    } else {
      result.add(log);
    }
  }

  if (!replaced) {
    result.add(incoming);
  }

  // Ordenar por sessionDate ascendente.
  result.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

  return result;
}

/// Compara si dos fechas representan el mismo día (ignora hora).
///
/// Usado internamente por [upsertTrainingSessionLogByDateV2].
///
/// DETERMINISTA: No usa DateTime.now().
///
/// USO INTERNO:
/// ```dart
/// final isSame = _isSameDayV2(
///   DateTime(2025, 1, 15, 14, 30),
///   DateTime(2025, 1, 15, 22, 45),
/// ); // true
/// ```
bool _isSameDayV2(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Normaliza una fecha a medianoche (00:00:00) del mismo día.
///
/// DETERMINISTA: No usa DateTime.now().
/// SIN SIDE EFFECTS: Retorna nueva instancia.
///
/// USO:
/// ```dart
/// final normalized = normalizeTrainingLogDate(DateTime(2025, 1, 15, 14, 30));
/// // DateTime(2025, 1, 15, 0, 0, 0)
/// ```
///
/// RECOMENDADO antes de construir TrainingSessionLogV2:
/// ```dart
/// final log = TrainingSessionLogV2(
///   sessionDate: normalizeTrainingLogDate(userSelectedDate),
///   // ...
/// );
/// ```
DateTime normalizeTrainingLogDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
