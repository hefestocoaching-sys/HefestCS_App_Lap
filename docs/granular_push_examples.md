// Ejemplo: Integrar push granular en DepletionTab (NutritionTab)
// Archivo: lib/features/nutrition_feature/widgets/depletion_tab.dart

// PASO 1: Agregar import
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';

// PASO 2: En el método de guardado (ejemplo simplificado)
Future<void> _saveNutritionRecord() async {
  // ... validaciones previas

  final date = DateTime.parse(_dateController.text);
  
  // Crear el record (ejemplo con DailyTrackingRecord)
  final newRecord = DailyTrackingRecord(
    date: date,
    // ... otros campos
  );

  final client = _client;
  if (client == null) return;

  // PASO 3: Guardar local (fuente de verdad)
  await ref.read(clientsProvider.notifier).updateActiveClient((current) {
    final updated = upsertRecordByDate<DailyTrackingRecord>(
      existingRecords: current.tracking,
      newRecord: newRecord,
      dateExtractor: (record) => record.date,
    );
    return current.copyWith(tracking: updated);
  });

  // PASO 4: Push granular a Firestore (fire-and-forget)
  final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
  await recordsRepo.pushNutritionRecord(
    client.id,
    newRecord.toJson(),
    date,
  );

  // ... resto del flujo (resetear estado, mostrar snackbar, etc.)
}

// ==========================================
// Ejemplo: Integrar push granular en TrainingDashboard
// Archivo: lib/features/training_feature/screens/training_dashboard_screen.dart

// PASO 1: Agregar import
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';

// PASO 2: En el método de guardado de session log
Future<void> _saveTrainingSession(TrainingSessionLogV2 sessionLog) async {
  // ... validaciones previas

  final client = ref.read(clientsProvider).value?.activeClient;
  if (client == null) return;

  // PASO 3: Guardar local (fuente de verdad)
  await ref.read(clientsProvider.notifier).updateActiveClient((current) {
    final updatedLogs = upsertTrainingSessionLogByDateV2(
      current.sessionLogsV2,
      sessionLog,
    );
    return current.copyWith(sessionLogsV2: updatedLogs);
  });

  // PASO 4: Push granular a Firestore (fire-and-forget)
  final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
  await recordsRepo.pushTrainingRecord(
    client.id,
    sessionLog.toJson(),
    sessionLog.date,
  );

  // ... resto del flujo
}

// ==========================================
// Patrón General para Cualquier Tab
// ==========================================

/*
TEMPLATE:

// 1. Import
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';

// 2. Método de guardado
Future<void> _saveRecord() async {
  final client = _client;
  if (client == null) return;

  // A. Crear record
  final newRecord = XxxRecord(
    date: date,
    // ... campos
  );

  // B. Guardar local (SQLite - fuente de verdad)
  await ref.read(clientsProvider.notifier).updateActiveClient((current) {
    final updated = upsertRecordByDate<XxxRecord>(
      existingRecords: current.xxxRecords,
      newRecord: newRecord,
      dateExtractor: (record) => record.date,
    );
    return current.copyWith(xxxRecords: updated);
  });

  // C. Push granular (Firestore - fire-and-forget)
  final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
  await recordsRepo.pushXxxRecord(client.id, newRecord);
  
  // O si no hay método específico:
  // await recordsRepo.pushNutritionRecord(
  //   client.id,
  //   newRecord.toJson(),
  //   date,
  // );

  // D. Resetear estado, mostrar feedback, etc.
}
*/

// ==========================================
// Verificación de Push Exitoso
// ==========================================

/*
Para verificar que el push granular funciona:

1. Ejecutar app en modo debug
2. Abrir Firebase Console
3. Ir a Firestore Database
4. Navegar a: coaches/{coachId}/clients/{clientId}/{domain}_records/
5. Guardar un record en la app
6. Verificar que aparece en Firestore con estructura:
   {
     "dateKey": "2025-01-15",
     "schemaVersion": 1,
     "updatedAt": <Timestamp>,
     "deleted": false,
     "payload": { ... }
   }
*/

// ==========================================
// Debugging
// ==========================================

/*
Si el push NO aparece en Firestore:

1. Verificar autenticación:
   - FirebaseAuth.instance.currentUser debe NO ser null
   
2. Verificar reglas de Firestore:
   - firestore.rules debe incluir reglas para subcollections
   
3. Verificar logs en console:
   - El push es fire-and-forget, pero puedes agregar logs:
   
   final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
   print('Pushing record for date: ${newRecord.date}');
   await recordsRepo.pushAnthropometryRecord(client.id, newRecord);
   print('Push completed (or failed silently)');
   
4. Si falla silenciosamente:
   - Es ESPERADO (fire-and-forget)
   - El guardado local YA fue exitoso
   - No afecta la funcionalidad de la app
*/
