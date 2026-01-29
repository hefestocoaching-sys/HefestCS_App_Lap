// ============================================================================
// EJEMPLO DE USO: TrainingSessionLogV2 en App Móvil
// ============================================================================
// Este archivo NO es código de producción.
// Es un ejemplo educativo de cómo usar el contrato desde la app móvil.
// ============================================================================
// ignore_for_file: depend_on_referenced_packages, non_constant_identifier_names, avoid_print

import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:uuid/uuid.dart';

/// EJEMPLO 1: Registrar sesión completa sin interrupciones
Future<void> ejemplo1_sesionCompletaNormal() async {
  // 1. Usuario completa 4 sets de Press Banca
  final log = TrainingSessionLogV2(
    id: const Uuid().v4(),
    clientId: 'user_12345',
    exerciseId: 'bench_press',
    sessionDate: normalizeTrainingLogDate(DateTime.now()),
    createdAt: DateTime.now(),
    source: 'mobile',
    plannedSets: 4,
    completedSets: 4,
    avgReportedRIR: 2.5, // Usuario reporta ~2-3 reps restantes
    perceivedEffort: 7, // Esfuerzo moderado
    stoppedEarly: false,
    painFlag: false,
    formDegradation: false,
    notes: 'Todo bien, buena progresión',
    schemaVersion: 'v1.0.0',
  );

  // 2. Validar antes de guardar
  log.validate(); // OK

  // 3. Guardar en local DB
  await _saveToLocalDB(log);

  print('✅ Sesión registrada correctamente');
}

/// EJEMPLO 2: Sesión interrumpida por dolor
Future<void> ejemplo2_sesionInterrumpidaPorDolor() async {
  // Usuario completa solo 2 de 4 sets por molestia en hombro
  final log = TrainingSessionLogV2(
    id: const Uuid().v4(),
    clientId: 'user_12345',
    exerciseId: 'overhead_press',
    sessionDate: normalizeTrainingLogDate(DateTime.now()),
    createdAt: DateTime.now(),
    source: 'mobile',
    plannedSets: 4,
    completedSets: 2, // Solo completó 2
    avgReportedRIR: 1.0, // Muy cerca del fallo
    perceivedEffort: 9, // Muy duro
    stoppedEarly: true, // ⚠️ BANDERA CRÍTICA
    painFlag: true, // ⚠️ BANDERA CRÍTICA
    formDegradation: false,
    notes: 'Molestia en hombro derecho, detuve por precaución',
    schemaVersion: 'v1.0.0',
  );

  log.validate(); // OK (stoppedEarly=true justifica completedSets < plannedSets)

  await _saveToLocalDB(log);

  // ⚠️ Esta sesión activará:
  // - fatigueExpectation = 'high'
  // - deloadRecommended = true
  // - Phase 8 aplicará volumeFactor = 0.85 (-15% volumen)

  print('⚠️ Sesión registrada con banderas de alarma');
}

/// EJEMPLO 3: Sesión con degradación técnica
Future<void> ejemplo3_sesionConDegradacionTecnica() async {
  // Usuario completa todo pero nota pérdida de técnica en últimas series
  final log = TrainingSessionLogV2(
    id: const Uuid().v4(),
    clientId: 'user_12345',
    exerciseId: 'squat',
    sessionDate: normalizeTrainingLogDate(DateTime.now()),
    createdAt: DateTime.now(),
    source: 'mobile',
    plannedSets: 5,
    completedSets: 5,
    avgReportedRIR: 1.5,
    perceivedEffort: 8,
    stoppedEarly: false,
    painFlag: false,
    formDegradation: true, // ⚠️ Técnica comprometida
    notes: 'Series 4 y 5 con profundidad reducida',
    schemaVersion: 'v1.0.0',
  );

  log.validate(); // OK

  await _saveToLocalDB(log);

  // ⚠️ Esta sesión contribuirá a:
  // - fatigueExpectation = 'moderate'
  // - No fuerza deload inmediato, pero alerta

  print('⚠️ Sesión registrada con degradación técnica');
}

/// EJEMPLO 4: Sesión excelente (señal positiva)
Future<void> ejemplo4_sesionExcelente() async {
  // Usuario completa todo con sensación de poder más
  final log = TrainingSessionLogV2(
    id: const Uuid().v4(),
    clientId: 'user_12345',
    exerciseId: 'deadlift',
    sessionDate: normalizeTrainingLogDate(DateTime.now()),
    createdAt: DateTime.now(),
    source: 'mobile',
    plannedSets: 3,
    completedSets: 3,
    avgReportedRIR: 3.5, // Muchas reps restantes
    perceivedEffort: 5, // Fácil
    stoppedEarly: false,
    painFlag: false,
    formDegradation: false,
    notes: 'Sentí que podía hacer 5-6 reps más, muy bien',
    schemaVersion: 'v1.0.0',
  );

  log.validate(); // OK

  await _saveToLocalDB(log);

  // ✅ Esta sesión contribuirá a:
  // - fatigueExpectation = 'low'
  // - signal = 'positive'
  // - progressionAllowed = true
  // - Phase 8 aplicará volumeFactor = 1.05-1.08 (+5-8% volumen)

  print('✅ Sesión registrada con señales positivas');
}

/// EJEMPLO 5: Sesión no realizada (usuario faltó)
Future<void> ejemplo5_sesionNoRealizada() async {
  // Usuario planificó entrenamiento pero no fue al gym
  final log = TrainingSessionLogV2(
    id: const Uuid().v4(),
    clientId: 'user_12345',
    exerciseId: 'lat_pulldown',
    sessionDate: normalizeTrainingLogDate(DateTime.now()),
    createdAt: DateTime.now(),
    source: 'mobile',
    plannedSets: 4,
    completedSets: 0, // Nada completado
    avgReportedRIR: 0.0, // No aplica
    perceivedEffort: 1, // Mínimo (no aplica)
    stoppedEarly: true, // DEBE ser true si completedSets == 0
    painFlag: false,
    formDegradation: false,
    notes: 'No asistí al gym por trabajo',
    schemaVersion: 'v1.0.0',
  );

  log.validate(); // OK (completedSets == 0 requiere stoppedEarly == true)

  await _saveToLocalDB(log);

  // ⚠️ Esta sesión contribuirá a:
  // - adherenceRatio bajo (0/4 = 0%)
  // - Si se repite, puede activar deloadRecommended

  print('⚠️ Sesión registrada con adherencia 0%');
}

/// EJEMPLO 6: Editar log de fecha pasada (offline-first)
Future<void> ejemplo6_editarLogPasado() async {
  // 1. Cargar logs existentes
  final existingLogs = await _loadFromLocalDB();

  // 2. Usuario corrige RIR de sesión del lunes
  final correctedLog = TrainingSessionLogV2(
    id: const Uuid().v4(), // Nuevo UUID (o reusar si se desea)
    clientId: 'user_12345',
    exerciseId: 'bench_press',
    sessionDate: DateTime(2025, 12, 29), // Lunes pasado
    createdAt: DateTime.now(), // Nuevo timestamp
    source: 'mobile',
    plannedSets: 4,
    completedSets: 4,
    avgReportedRIR: 2.0, // Corregido (antes era 2.5)
    perceivedEffort: 8, // Corregido (antes era 7)
    stoppedEarly: false,
    painFlag: false,
    formDegradation: false,
    notes: 'Edición: en realidad fue más duro de lo que pensé',
    schemaVersion: 'v1.0.0',
  );

  correctedLog.validate(); // OK

  // 3. Upsert (reemplaza si existe log para mismo día + ejercicio)
  final updatedLogs = upsertTrainingSessionLogByDateV2(
    existingLogs,
    correctedLog,
  );

  // 4. Guardar lista actualizada
  await _saveAllToLocalDB(updatedLogs);

  print('✅ Log editado correctamente (offline-first)');
}

/// EJEMPLO 7: Sincronización con servidor (cuando hay conexión)
Future<void> ejemplo7_syncConServidor() async {
  // 1. Cargar logs pendientes de sync
  final pendingLogs = await _loadPendingSyncLogs();

  // 2. Sync a Firebase/backend
  for (final log in pendingLogs) {
    final json = log.toJson();

    // Enviar a servidor
    await _sendToServer(json);

    // Marcar como synced
    await _markAsSynced(log.id);
  }

  print('✅ ${pendingLogs.length} logs sincronizados');
}

/// EJEMPLO 8: Validación con manejo de errores
Future<void> ejemplo8_validacionConErrores() async {
  try {
    // Usuario intenta registrar RIR inválido
    final log = TrainingSessionLogV2(
      id: const Uuid().v4(),
      clientId: 'user_12345',
      exerciseId: 'curl',
      sessionDate: normalizeTrainingLogDate(DateTime.now()),
      createdAt: DateTime.now(),
      source: 'mobile',
      plannedSets: 3,
      completedSets: 3,
      avgReportedRIR: 6.5, // ❌ INVÁLIDO (máximo es 5.0)
      perceivedEffort: 7,
      stoppedEarly: false,
      painFlag: false,
      formDegradation: false,
      schemaVersion: 'v1.0.0',
    );

    log.validate(); // ❌ Lanza ArgumentError
  } on ArgumentError catch (e) {
    print('❌ Error de validación: ${e.message}');
    // Mostrar mensaje al usuario
    // "El RIR debe estar entre 0.0 y 5.0"
  }
}

/// EJEMPLO 9: Deserialización desde servidor
Future<void> ejemplo9_deserializacionDesdeServidor() async {
  // JSON recibido del servidor
  final json = {
    'id': 'abc-123',
    'clientId': 'user_12345',
    'exerciseId': 'bench_press',
    'sessionDate': '2025-12-30T00:00:00.000Z',
    'createdAt': '2025-12-30T14:30:00.000Z',
    'source': 'mobile',
    'plannedSets': 4,
    'completedSets': 4,
    'avgReportedRIR': 2.5,
    'perceivedEffort': 7,
    'stoppedEarly': false,
    'painFlag': false,
    'formDegradation': false,
    'notes': 'Sesión desde servidor',
    'schemaVersion': 'v1.0.0',
  };

  // Deserializar
  final log = TrainingSessionLogV2.fromJson(json);

  // Validar (por si servidor envió datos inválidos)
  log.validate(); // OK

  // Guardar en local DB
  await _saveToLocalDB(log);

  print('✅ Log descargado y validado desde servidor');
}

/// EJEMPLO 10: Cálculo de adherencia semanal (preparación para agregador)
Future<void> ejemplo10_calcularAdherenciaSemanal() async {
  // 1. Cargar logs de esta semana
  final thisWeekLogs = await _loadLogsForCurrentWeek();

  // 2. Calcular totales
  int totalPlanned = 0;
  int totalCompleted = 0;

  for (final log in thisWeekLogs) {
    totalPlanned += log.plannedSets;
    totalCompleted += log.completedSets;
  }

  // 3. Calcular adherencia
  final adherenceRatio = totalPlanned > 0
      ? (totalCompleted / totalPlanned).clamp(0.0, 1.0)
      : 0.0;

  print('📊 Adherencia semanal: ${(adherenceRatio * 100).toStringAsFixed(1)}%');
  print('   Planificadas: $totalPlanned sets');
  print('   Completadas: $totalCompleted sets');

  // ⚠️ Este cálculo simple será reemplazado por TrainingFeedbackAggregatorService
  // que además calcula: signal, fatigueExpectation, progressionAllowed, etc.
}

// ============================================================================
// FUNCIONES MOCK (REEMPLAZAR CON IMPLEMENTACIÓN REAL)
// ============================================================================

Future<void> _saveToLocalDB(TrainingSessionLogV2 log) async {
  // TODO: Implementar con SQLite, Hive, SharedPreferences, etc.
  print('[DB] Guardando log: ${log.id}');
}

Future<void> _saveAllToLocalDB(List<TrainingSessionLogV2> logs) async {
  // TODO: Implementar bulk save
  print('[DB] Guardando ${logs.length} logs');
}

Future<List<TrainingSessionLogV2>> _loadFromLocalDB() async {
  // TODO: Implementar lectura desde DB local
  return [];
}

Future<List<TrainingSessionLogV2>> _loadPendingSyncLogs() async {
  // TODO: Implementar filtro por syncStatus
  return [];
}

Future<List<TrainingSessionLogV2>> _loadLogsForCurrentWeek() async {
  // TODO: Implementar filtro por fecha (lunes-domingo actual)
  return [];
}

Future<void> _sendToServer(Map<String, dynamic> json) async {
  // TODO: Implementar HTTP POST a Firebase/backend
  print('[SYNC] Enviando a servidor: ${json['id']}');
}

Future<void> _markAsSynced(String logId) async {
  // TODO: Actualizar flag syncStatus en DB local
  print('[SYNC] Marcado como synced: $logId');
}

// ============================================================================
// NOTAS DE IMPLEMENTACIÓN
// ============================================================================

/*
RECOMENDACIONES PARA APP MÓVIL:

1. GENERACIÓN DE UUID:
   - Usar package 'uuid' (https://pub.dev/packages/uuid)
   - Generar en cliente ANTES de guardar
   - Ejemplo: const Uuid().v4()

2. NORMALIZACIÓN DE FECHA:
   - SIEMPRE usar normalizeTrainingLogDate(DateTime.now())
   - NO guardar hora en sessionDate (solo día)

3. VALIDACIÓN:
   - Llamar log.validate() DESPUÉS de construcción
   - Manejar ArgumentError y mostrar mensaje al usuario

4. OFFLINE-FIRST:
   - Guardar en DB local PRIMERO
   - Sync a servidor cuando haya conexión
   - Usar upsertTrainingSessionLogByDateV2 para merge

5. UI/UX:
   - Sliders para RIR [0.0 - 5.0] con step 0.5
   - Sliders para perceivedEffort [1 - 10] con step 1
   - Checkboxes para painFlag, stoppedEarly, formDegradation
   - TextField opcional para notes

6. SYNC:
   - Usar toJson() para serializar antes de enviar
   - Usar fromJson() para deserializar respuesta servidor
   - Validar DESPUÉS de deserializar (por si servidor corrupto)

7. SCHEMAVERSION:
   - SIEMPRE usar 'v1.0.0' para esta versión
   - Si cambia contrato, bump a 'v2.0.0' y documentar migración

8. TESTING:
   - Testear cada ejemplo de este archivo
   - Testear casos edge (RIR=0, RIR=5, completedSets=0, etc.)
   - Testear sync offline → online → conflict resolution
*/
