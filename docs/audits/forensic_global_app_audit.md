# Auditoría Forense Global — HefestoCS

## Fecha
2026-05-09

## Alcance
Se auditaron rutas bajo `lib/`, con enfasis en `lib/core/`, `lib/data/`, `lib/domain/`, `lib/features/` y `lib/utils/`.

Features revisadas: `anthropometry_feature`, `biochemistry_feature`, `calendar_feature`, `client_feature`, `client_summary_feature`, `finance_feature`, `food_database_feature`, `history_clinic_feature`, `macros_feature`, `meal_plan_feature`, `nutrition_feature` y `training_feature`.

Motores/dominios revisados: `lib/domain/training_engine`, `lib/domain/training_v3`, `lib/domain/training_domain`, `lib/nutrition_engine` y repositorios de persistencia/sync relacionados.

Comando ejecutado: `flutter analyze --no-pub`.

Resultado: 29 issues existentes: warnings/info en entrenamiento, imports no usados en `client_selector_modal.dart`, warnings en widgets legacy de macros y dead code en `training_plan_provider.dart`. No se modifico codigo funcional durante esta auditoria.

## Resumen Ejecutivo
| Severidad | Cantidad | Descripcion |
|---|---:|---|
| P0 | 4 | Rutas que pueden romper offline-first, borrado persistente o crear duplicados funcionales |
| P1 | 13 | Calculos/fechas/estado que pueden cargar registros equivocados, duplicar snapshots o mostrar datos stale |
| P2 | 9 | Riesgos de performance, merge parcial, sync incompleto o arquitectura dispersa |
| P3 | 5 | Legacy, textos corruptos, warnings y nomenclatura inconsistente |

## Hallazgos P0 — Críticos

### P0-001 — Borrado clinico depende de Firestore antes de borrar local

**Archivo(s):**
- `lib/domain/services/record_deletion_service.dart`
- `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
- `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`
- `lib/features/nutrition_feature/widgets/dietary_tab.dart`

**Clase / funcion / metodo:**
- `RecordDeletionService.deleteAnthropometryByDate`
- `RecordDeletionService.deleteBiochemistryByDate`
- `RecordDeletionService.deleteNutritionByDate`
- `_deleteRecordByDate`
- `_deleteSelectedRecord`

**Problema:**
El servicio dice ser "fire-and-forget", pero sus metodos son `Future<void>` y hacen `await _recordDataSource.deleteRecord(...)` despues de exigir usuario autenticado. Los tabs de antropometria, bioquimica y nutricion hacen `await deletionService.delete...` antes de aplicar el borrado local. Si no hay auth, internet o Firestore falla, el registro no se borra localmente.

**Evidencia:**
`RecordDeletionService`:

```dart
final coachId = _getAuthenticatedCoachId();
if (coachId == null) {
  throw Exception('No authenticated user');
}
await _recordDataSource.deleteRecord(...);
```

Usos bloqueantes detectados:
- `anthropometry_measures_tab.dart:811`
- `biochemistry_tab.dart:611`
- `dietary_tab.dart:962`

**Impacto:**
Borrado no offline-first. Un registro clinico puede persistir aunque el usuario presione borrar. Tambien puede reaparecer al recargar si el flujo local nunca se ejecuto.

**Reproduccion probable:**
1. Abrir antropometria, bioquimica o nutricion sin sesion Firebase activa o sin conexion.
2. Intentar borrar un registro.
3. El servicio remoto lanza error.
4. El listado local conserva el registro.

**Correccion recomendada:**
Invertir flujo: borrar/marcar local primero con `updateActiveClient`, actualizar UI y encolar/ejecutar sync remoto en background. El servicio remoto no debe bloquear el borrado local.

**Riesgo si no se corrige:**
Registros clinicos persistentes, falsa confirmacion de borrado, incumplimiento offline-first.

---

### P0-002 — Finanzas escribe directo en Firestore y espera red antes de actualizar UI

**Archivo(s):**
- `lib/features/dashboard_feature/providers/transactions_provider.dart`
- `lib/data/repositories/transaction_firestore_datasource.dart`
- `lib/data/repositories/transaction_repository.dart`
- `lib/features/finance_feature/finance_screen.dart`

**Clase / funcion / metodo:**
- `TransactionsNotifier.addTransaction`
- `TransactionsNotifier.updateTransaction`
- `TransactionsNotifier.deleteTransaction`
- `TransactionFirestoreDataSource.addTransaction`
- `TransactionFirestoreDataSource.updateTransaction`
- `TransactionFirestoreDataSource.deleteTransaction`

**Problema:**
Las operaciones financieras hacen `await _datasource.*` contra Firestore antes de mutar `state`. No hay SQLite, cola local, `isSynced`, `isDeleted` ni retry offline.

**Evidencia:**

```dart
Future<void> addTransaction(Transaction transaction) async {
  await _datasource.addTransaction(transaction);
  state = [...state, transaction];
}
```

El datasource usa colecciones Firestore directamente y ordena por `date`.

**Impacto:**
Pagos/ingresos/gastos no se guardan si no hay internet. El usuario puede perder registros financieros creados offline.

**Reproduccion probable:**
1. Cortar conexion.
2. Intentar registrar pago o gasto.
3. Firestore falla.
4. `state` no cambia y no queda pendiente local.

**Correccion recomendada:**
Crear persistencia local para transacciones o moverlas al modelo cliente local-first. Guardar local primero, marcar `isSynced=false`, sincronizar en background.

**Riesgo si no se corrige:**
Perdida de pagos, deuda mal calculada, app inutilizable offline en finanzas.

---

### P0-003 — Calendario/citas escribe directo en Firestore y espera red antes de actualizar UI

**Archivo(s):**
- `lib/features/dashboard_feature/providers/appointments_provider.dart`
- `lib/data/repositories/appointment_firestore_datasource.dart`
- `lib/data/repositories/appointment_repository.dart`
- `lib/features/calendar_feature/calendar_screen.dart`

**Clase / funcion / metodo:**
- `AppointmentsNotifier.addAppointment`
- `AppointmentsNotifier.updateAppointment`
- `AppointmentsNotifier.deleteAppointment`
- `AppointmentFirestoreDataSource.addAppointment`
- `AppointmentFirestoreDataSource.updateAppointment`
- `AppointmentFirestoreDataSource.deleteAppointment`

**Problema:**
Las citas dependen de Firestore antes de actualizar estado local. No existe guardado local SQLite ni cola de sync para agenda.

**Evidencia:**

```dart
Future<void> addAppointment(Appointment appointment) async {
  await _datasource.addAppointment(appointment);
  state = [...state, appointment];
}
```

**Impacto:**
Citas creadas offline no se guardan. Una cita cancelada o completada offline no queda registrada.

**Reproduccion probable:**
1. Cortar internet.
2. Crear/cancelar/completar una cita.
3. La llamada remota falla.
4. No hay persistencia local ni reintento.

**Correccion recomendada:**
Persistir citas localmente primero, agregar metadatos `isSynced/isDeleted/updatedAt`, y sincronizar despues.

**Riesgo si no se corrige:**
Perdida de agenda y estados de citas; calendario no cumple offline-first.

---

### P0-004 — Meal plan puede duplicar registros del mismo dia por comparacion cruda de `dateIso`

**Archivo(s):**
- `lib/features/meal_plan_feature/screen/meal_plan_screen.dart`

**Clase / funcion / metodo:**
- `_MealPlanDaysCardState._upsertMealPlanRecord`

**Problema:**
El upsert elimina registros existentes comparando strings crudos. Si un registro tiene `2026-05-09T21:00:00.000` y otro `2026-05-09`, ambos quedan como dias distintos aunque representan el mismo dia.

**Evidencia:**

```dart
records.removeWhere((record) => record['dateIso']?.toString() == dateIso);
records.add({
  'dateIso': dateIso,
  'dailyMealPlans': plans.map((k, v) => MapEntry(k, v.toJson())),
});
```

**Impacto:**
Duplicados persistentes en menu semanal. La app puede mostrar o guardar contra un registro y cargar otro despues.

**Reproduccion probable:**
1. Tener un registro legacy con timestamp.
2. Editar menu para el mismo dia usando fecha `YYYY-MM-DD`.
3. Guardar.
4. Quedan dos registros para el mismo dia normalizado.

**Correccion recomendada:**
Normalizar toda fecha con `dateIsoFrom(DateTime.parse(...))` y remover por dia normalizado, no por string crudo.

**Riesgo si no se corrige:**
Menus duplicados, datos stale, borrados incompletos y seleccion de registro incorrecta.

## Hallazgos P1 — Altos

### P1-001 — DietaryProvider carga el ultimo calculo si la fecha activa no tiene registro

**Archivo(s):**
- `lib/features/nutrition_feature/providers/dietary_provider.dart`

**Clase / funcion / metodo:**
- `DietaryNotifier.initialize`

**Problema:**
Cuando `activeDateIso` no tiene evaluacion, el provider usa `latestNutritionRecordByDate(records)`. Esto mezcla actividades/NAF de otra fecha en un nuevo calculo.

**Evidencia:**

```dart
final evalRecord = activeDateIso == null
    ? latestNutritionRecordByDate(records)
    : (nutritionRecordForDate(records, activeDateIso) ??
          latestNutritionRecordByDate(records));
```

**Impacto:**
Calorias, NAF y actividades pueden precargarse desde otro dia. Puede producir calculos nutricionales incorrectos.

**Reproduccion probable:**
1. Crear calculo para una fecha anterior con actividades.
2. Cambiar fecha global a una fecha sin registro.
3. Abrir calculo nutricional.
4. El provider reutiliza el ultimo registro.

**Correccion recomendada:**
Si existe `activeDateIso`, cargar solo esa fecha. Si no existe, inicializar estado limpio/creating.

**Riesgo si no se corrige:**
Registros nuevos nacen con datos viejos y pueden persistir calculos incorrectos.

---

### P1-002 — Macros usa fallback a ultimo registro de evaluacion y puede calcular con kcal/mantenimiento equivocados

**Archivo(s):**
- `lib/features/macros_feature/widgets/macros_content.dart`

**Clase / funcion / metodo:**
- `MacrosContentState.build`
- `_resolveDisplayedMacrosDateIso`

**Problema:**
Para el `displayedMacrosDateIso`, macros intenta registro exacto y luego cae a `latestNutritionRecordByDate` tanto para macros como para evaluacion nutricional.

**Evidencia:**

```dart
final macroRecord =
    nutritionRecordForDate(macroRecords, displayedMacrosDateIso) ??
    latestNutritionRecordByDate(macroRecords);

final evalRecord =
    nutritionRecordForDate(evalRecords, displayedMacrosDateIso) ??
    latestNutritionRecordByDate(evalRecords);
```

**Impacto:**
El insight, carbohidratos y kcal por dia pueden calcularse usando datos de otra fecha. El error es clinicamente relevante porque afecta deficit/superavit y macros.

**Reproduccion probable:**
1. Tener evaluacion del 2026-05-01.
2. Abrir macros para 2026-05-09 sin evaluacion.
3. La UI muestra 2026-05-09 pero calcula con evaluacion previa.

**Correccion recomendada:**
Para fecha activa, no usar fallback a latest. Mostrar estado sin evaluacion o exigir calculo nutricional para esa fecha.

**Riesgo si no se corrige:**
Macros calculados con mantenimiento/kcal finales de otra fecha.

---

### P1-003 — Meal plan selecciona ultimo registro cuando la fecha activa no existe

**Archivo(s):**
- `lib/features/meal_plan_feature/screen/meal_plan_screen.dart`

**Clase / funcion / metodo:**
- `_resolvePlansForDate`
- `_resolveDisplayedMealPlanDateIso`

**Problema:**
El menu resuelve la fecha pedida con fallback a ultimo registro. La pantalla puede abrir/editar el ultimo menu aunque la fecha activa sea otra.

**Evidencia:**

```dart
final record =
    nutritionRecordForDate(records, dateIso) ??
    latestNutritionRecordByDate(records);
```

**Impacto:**
El usuario puede creer que edita una fecha nueva, pero modifica un menu anterior.

**Reproduccion probable:**
1. Tener meal plan en una fecha pasada.
2. Cambiar fecha activa a hoy sin meal plan.
3. Abrir menu.
4. Se carga el ultimo registro disponible.

**Correccion recomendada:**
Eliminar fallback a latest cuando hay fecha objetivo. Si no hay registro, crear estado vacio para esa fecha.

**Riesgo si no se corrige:**
Edicion de registro equivocado y menus fantasma.

---

### P1-004 — Equivalentes por dia usa fallback a latest y tiene escrituras sin await

**Archivo(s):**
- `lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart`

**Clase / funcion / metodo:**
- `_resolveDisplayedEquivalentsDateIso`
- `_createNewEquivalentsRecord`
- `_selectRecord`

**Problema:**
La resolucion de fecha cae a latest si la fecha preferida no existe. Ademas `_createNewEquivalentsRecord` y `_selectRecord` invocan `updateActiveClient` sin `await`.

**Evidencia:**

```dart
final record = nutritionRecordForDate(records, preferred) ?? latest;
```

```dart
ref.read(clientsProvider.notifier).updateActiveClient((current) { ... });
setState(() { _mode = _EquivalentsMode.view; });
```

**Impacto:**
La UI puede entrar en modo view antes de persistir. Tambien puede cargar equivalentes de otra fecha.

**Reproduccion probable:**
1. Crear registro nuevo de equivalentes.
2. Cambiar rapido de pantalla o cliente.
3. La UI marca view aunque la persistencia aun este corriendo.

**Correccion recomendada:**
Esperar `updateActiveClient` y no resolver fecha objetivo contra latest.

**Riesgo si no se corrige:**
Registros fantasma, estado stale y equivalentes asignados a fecha incorrecta.

---

### P1-005 — NutritionPlanRepository puede guardar multiples snapshots para la misma fecha y cargar uno stale

**Archivo(s):**
- `lib/data/repositories/nutrition_plan_repository.dart`
- `lib/features/nutrition_feature/providers/daily_nutrition_plan_provider.dart`

**Clase / funcion / metodo:**
- `NutritionPlanRepository.savePlan`
- `NutritionPlanRepository.loadPlanForDate`
- `dailyNutritionPlanProvider`

**Problema:**
`savePlan` agrega siempre un nuevo snapshot. Los planes generados pueden tener `Uuid().v4()` nuevo. `loadPlanForDate` filtra por `dateIso` y ordena por `version`, pero si existen varios `planId` con version 1 para la misma fecha, el resultado depende del orden de la lista.

**Evidencia:**

```dart
final updatedRecords = [...records, snapshot];
```

```dart
exactMatch.sort((a, b) => b.version.compareTo(a.version));
return DailyNutritionPlan.fromJson(exactMatch.first.data);
```

**Impacto:**
Puede cargar un plan anterior aunque haya uno mas reciente para la misma fecha.

**Reproduccion probable:**
1. Generar plan para una fecha.
2. Regenerar con nuevo `plan.id`.
3. Guardar.
4. Recargar fecha: si ambas versiones son iguales, puede cargar el snapshot viejo.

**Correccion recomendada:**
Definir clave unica por fecha o por `(dateIso, planId)` y ordenar tambien por `createdAt/updatedAt`.

**Riesgo si no se corrige:**
Menus y equivalentes no reflejan el ultimo plan guardado.

---

### P1-006 — AppointmentFirestoreDataSource ordena por campo que la entidad no escribe

**Archivo(s):**
- `lib/data/repositories/appointment_firestore_datasource.dart`
- `lib/domain/entities/appointment.dart`

**Clase / funcion / metodo:**
- `AppointmentFirestoreDataSource.getAppointments`
- `Appointment.toJson`

**Problema:**
El datasource lee con `.orderBy('date', descending: true)`, pero la entidad serializa `dateTime`.

**Evidencia:**

```dart
// datasource
.orderBy('date', descending: true)

// entity
'dateTime': dateTime,
```

**Impacto:**
La consulta general de citas puede fallar, devolver orden incorrecto o depender de documentos legacy con campo `date`.

**Reproduccion probable:**
1. Crear cita nueva con `Appointment.toJson`.
2. Recargar dashboard.
3. `getAppointments` consulta por `date`, campo inexistente en documentos nuevos.

**Correccion recomendada:**
Unificar campo a `dateTime` en datasource y repositorio. Agregar migracion/compatibilidad de lectura si hay docs legacy.

**Riesgo si no se corrige:**
Citas desaparecen del dashboard o quedan mal ordenadas.

---

### P1-007 — Training generatedPlanRecords puede duplicarse por comparacion cruda de fecha

**Archivo(s):**
- `lib/features/training_feature/providers/training_plan_provider.dart`

**Clase / funcion / metodo:**
- `TrainingPlanNotifier.generatePlan` / bloque de actualizacion de `generatedPlanRecords`

**Problema:**
El plan generado elimina registros comparando `forDateIso` como string crudo contra `activeDateIso`.

**Evidencia:**

```dart
records.removeWhere(
  (record) =>
      record[TrainingExtraKeys.forDateIso]?.toString() == activeDateIso,
);
```

**Impacto:**
Si hay fechas con timestamp y fechas `YYYY-MM-DD`, se pueden crear duplicados de metadata de plan generado.

**Reproduccion probable:**
1. Tener metadata legacy con timestamp.
2. Regenerar plan para el mismo dia normalizado.
3. La lista conserva ambos registros.

**Correccion recomendada:**
Normalizar `forDateIso` antes de comparar y guardar.

**Riesgo si no se corrige:**
Historial de generacion duplicado y seleccion de plan inconsistente.

---

### P1-008 — ActiveCycleBootstrapper no es deterministico porque usa timestamp en la semilla

**Archivo(s):**
- `lib/domain/training/services/active_cycle_bootstrapper.dart`

**Clase / funcion / metodo:**
- `ActiveCycleBootstrapper.buildDefaultCycle`
- `_generateSeed`

**Problema:**
El comentario habla de consistencia por cliente/musculo, pero la semilla incluye timestamp por segundo.

**Evidencia:**

```dart
final now = DateTime.now().millisecondsSinceEpoch;
final timestamp = (now ~/ 1000).toString();
final muscleSeed = _generateSeed(clientId, muscle, timestamp);
```

**Impacto:**
Si se reconstruye un ciclo default en otro segundo, puede seleccionar ejercicios distintos sin accion explicita del usuario.

**Reproduccion probable:**
1. Crear/abrir ciclo default.
2. Forzar reconstruccion despues de unos segundos.
3. Comparar ejercicios por musculo.

**Correccion recomendada:**
Usar semilla estable por cliente + ciclo + musculo. El timestamp solo debe formar parte del id, no de la seleccion deterministica.

**Riesgo si no se corrige:**
Plan cambia sin consentimiento y rompe trazabilidad.

---

### P1-009 — TrainingCycleRepository guarda en repositorio pero no actualiza estado de clientsProvider

**Archivo(s):**
- `lib/features/training_feature/providers/training_cycle_repository.dart`

**Clase / funcion / metodo:**
- `TrainingCycleRepositoryImpl.createCycle`
- `TrainingCycleRepositoryImpl.upsertCycle`
- `TrainingCycleRepositoryImpl.closeCycle`

**Problema:**
Estas operaciones usan `clientRepositoryProvider.saveClient(updatedClient)` directamente. Ese guardado local-first persiste, pero no actualiza el estado en memoria de `clientsProvider`.

**Evidencia:**
Patron detectado: repositorio de ciclos construye `updatedClient` y llama `saveClient`, no `clientsProvider.notifier.updateActiveClient`.

**Impacto:**
La UI puede seguir mostrando ciclos viejos hasta recargar providers.

**Reproduccion probable:**
1. Crear/cerrar ciclo de entrenamiento.
2. Volver a pantalla que lee `clientsProvider`.
3. El estado puede no reflejar el cambio hasta reload.

**Correccion recomendada:**
Centralizar escritura de cliente por `updateActiveClient` o invalidar/actualizar provider despues del save.

**Riesgo si no se corrige:**
Estado stale, activePlanId/ciclos inconsistentes.

---

### P1-010 — `training_interviews` acumula filas aunque los datos no cambien

**Archivo(s):**
- `lib/data/datasources/local/database_helper.dart`

**Clase / funcion / metodo:**
- `DatabaseHelper.upsertClient`
- `_buildInterviewFromClient`

**Problema:**
Cada `upsertClient` inserta un `TrainingInterview` con `Uuid().v4()`. Si los datos no cambian, conserva version pero cambia id, por lo que se acumulan filas duplicadas de la misma version/datos.

**Evidencia:**

```dart
final lastInterview = await getActiveTrainingInterview(client.id);
final newInterview = _buildInterviewFromClient(client, lastInterview);
batch.insert('training_interviews', newInterview.toMap(), ...);
```

```dart
return TrainingInterview(id: const Uuid().v4(), ...);
```

**Impacto:**
Crecimiento innecesario de SQLite y riesgo de que "active interview" dependa de orden/fecha mas que de cambios reales.

**Reproduccion probable:**
1. Guardar cliente varias veces sin cambiar entrevista.
2. Revisar tabla `training_interviews`.
3. Aparecen multiples filas equivalentes.

**Correccion recomendada:**
No insertar nueva entrevista si `isSameData`. Reusar id o hacer upsert por `(clientId, version)`.

**Riesgo si no se corrige:**
Duplicados locales y degradacion progresiva.

---

### P1-011 — ClientOverview toma energia "latest" con `records.last` sin ordenar

**Archivo(s):**
- `lib/features/client_feature/screen/client_overview_screen.dart`

**Clase / funcion / metodo:**
- `ClientOverviewScreen.build` / resolucion de energia

**Problema:**
La vista de cliente usa el ultimo elemento de la lista sin normalizar ni ordenar por fecha.

**Evidencia:**
Patron detectado:

```dart
final latestEnergy = energyRecords.isNotEmpty ? energyRecords.last : null;
```

**Impacto:**
Si la lista no esta en orden cronologico, el resumen muestra kcal/energia de una fecha incorrecta.

**Reproduccion probable:**
1. Tener registros importados o guardados con orden mixto.
2. Abrir overview.
3. La tarjeta de energia puede mostrar un registro no reciente.

**Correccion recomendada:**
Usar `latestNutritionRecordByDate` o ordenar por `dateIso` normalizado.

**Riesgo si no se corrige:**
Dashboard clinico con datos viejos.

---

### P1-012 — `clearActiveClient` no limpia realmente el cliente activo en memoria

**Archivo(s):**
- `lib/features/main_shell/providers/clients_provider.dart`

**Clase / funcion / metodo:**
- `ClientsNotifier.clearActiveClient`

**Problema:**
Despues de persistir `null`, el estado se actualiza con `current.copyWith()` sin pasar un valor que borre `activeClientId`. En un `copyWith` comun, null significa "mantener valor actual".

**Evidencia:**

```dart
await _persistActiveClientId(null);
state = AsyncValue.data(current.copyWith());
```

**Impacto:**
La UI puede conservar cliente activo aunque se haya pedido limpiar seleccion.

**Reproduccion probable:**
1. Limpiar seleccion de cliente desde shell.
2. Observar providers dependientes antes de reinicio.
3. El estado puede seguir apuntando al cliente anterior.

**Correccion recomendada:**
Agregar metodo explicito para clear o permitir sentinel en `copyWith` para `activeClientId`.

**Riesgo si no se corrige:**
Datos de un cliente mostrados en contexto de otro o despues de salir.

---

### P1-013 — SyncQueue marca exito sin subir datos reales

**Archivo(s):**
- `lib/core/services/sync_service.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`

**Clase / funcion / metodo:**
- `SyncService.syncPendingData`
- `SyncService._syncItem`
- `SyncQueueHelper.markSuccess`

**Problema:**
`syncPendingData` llama `_syncItem(item)` y luego `markSuccess`. `_syncItem` solo registra debug para antropometria y no ejecuta upload real.

**Evidencia:**

```dart
await _syncItem(item);
await SyncQueueHelper.markSuccess(item['id'] as String);
```

```dart
if (domain == 'anthropometry') {
  debugPrint('Syncing anthropometry record...');
}
```

**Impacto:**
Si algun flujo usa `SyncQueueHelper.enqueue`, los items pueden eliminarse de la cola como exitosos sin llegar al remoto.

**Reproduccion probable:**
1. Encolar item en `sync_queue`.
2. Ejecutar `SyncService.syncPendingData`.
3. El item se marca success aunque `_syncItem` no suba nada.

**Correccion recomendada:**
Implementar upload por dominio o deshabilitar esta cola hasta que exista contrato real. No marcar success si no hubo persistencia remota.

**Riesgo si no se corrige:**
Perdida silenciosa de cambios pendientes en rutas que usen la cola.

## Hallazgos P2 — Medios

### P2-001 — Antropometria tiene doble ruta de guardado para el mismo cambio

**Archivo(s):**
- `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
- `lib/data/repositories/client_repository.dart`
- `lib/features/main_shell/providers/clients_provider.dart`

**Clase / funcion / metodo:**
- `_saveRecord`
- `ClientRepository.saveClient`
- `ClientsNotifier.updateActiveClient`

**Problema:**
El tab guarda primero `repository.saveClient(updatedClient)` y luego llama `updateActiveClient`. Son dos escrituras locales/remotas para el mismo cambio, con distinto merge.

**Evidencia:**
Patron observado: construye `updatedClient`, ejecuta `repository.saveClient(updatedClient)` y despues `updateActiveClient((current) => current.copyWith(...))`.

**Impacto:**
Riesgo de carrera, doble sync, y sobrescritura si el cliente cambio entre ambos pasos.

**Reproduccion probable:**
Guardar antropometria mientras otro modulo actualiza el cliente.

**Correccion recomendada:**
Usar una sola ruta: `updateActiveClient` con merge seguro y persistencia local-first.

**Riesgo si no se corrige:**
Sync duplicado y mayor probabilidad de perder cambios concurrentes.

---

### P2-002 — Merge de nutricion puede no preservar `clinicalRestrictionProfile`

**Archivo(s):**
- `lib/features/main_shell/providers/clients_provider.dart`

**Clase / funcion / metodo:**
- `_safeMergeNutrition`

**Problema:**
El merge seguro preserva extras y planes, pero asigna `clinicalRestrictionProfile` desde `updated` sin fallback visible a `current`.

**Evidencia:**

```dart
clinicalRestrictionProfile: updated.clinicalRestrictionProfile,
extra: mergedExtra,
```

**Impacto:**
Si un updater construye `updated.nutrition` sin perfil clinico completo, puede pisar restricciones.

**Reproduccion probable:**
Ejecutar un update parcial de nutricion que no contemple perfil clinico.

**Correccion recomendada:**
Hacer fallback explicito a `current.clinicalRestrictionProfile` cuando el update no pretende modificarlo.

**Riesgo si no se corrige:**
Perdida de restricciones clinicas en planes nutricionales.

---

### P2-003 — Bitacora/workout logs son SQLite local sin estrategia de sync visible

**Archivo(s):**
- `lib/data/datasources/local/database_helper.dart`
- `lib/domain/training_v3/repositories/workout_log_repository.dart`
- `lib/features/training_feature/providers/training_plan_v3_provider.dart`

**Clase / funcion / metodo:**
- Tabla `workout_logs`
- Repositorio de workout logs

**Problema:**
La tabla `workout_logs` existe localmente, pero no se observaron campos `isSynced/isDeleted` ni ruta clara en `BackgroundSyncService`.

**Evidencia:**
`DatabaseHelper` crea tabla local de logs; `BackgroundSyncService` sincroniza clientes, no logs independientes.

**Impacto:**
La bitacora puede persistir localmente pero no replicarse a remoto.

**Reproduccion probable:**
Registrar performance offline, reinstalar/cambiar dispositivo.

**Correccion recomendada:**
Definir si logs viven dentro del cliente o tabla syncable. Agregar metadata y sync por dominio.

**Riesgo si no se corrige:**
Perdida de bitacora fuera del dispositivo.

---

### P2-004 — Widgets/providers gigantes concentran estado, build y persistencia

**Archivo(s):**
- `lib/features/training_feature/providers/training_plan_provider.dart`
- `lib/features/training_feature/screens/training_workspace_screen.dart`
- `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
- `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`
- `lib/features/nutrition_feature/widgets/dietary_tab.dart`
- `lib/features/macros_feature/widgets/macros_content.dart`

**Clase / funcion / metodo:**
- Archivos completos

**Problema:**
Hay archivos entre 1000 y 3000+ lineas que combinan UI, parseo, calculo, persistencia y estado.

**Evidencia:**
Conteo observado:
- `training_plan_provider.dart`: 3000+ lineas.
- `training_workspace_screen.dart`: 2900+ lineas.
- `anthropometry_measures_tab.dart`: 2400+ lineas.
- `biochemistry_tab.dart`: 2200+ lineas.
- `dietary_tab.dart`: 1700+ lineas.
- `macros_content.dart`: 1000+ lineas.

**Impacto:**
Mayor riesgo de rebuilds amplios, bugs de estado y regresiones al corregir.

**Reproduccion probable:**
Cambios pequenos de inputs disparan `setState` en widgets con mucha responsabilidad.

**Correccion recomendada:**
Extraer calculos puros, repositorios de fecha, controladores por modulo y widgets menores con contratos claros.

**Riesgo si no se corrige:**
Lentitud progresiva y alto costo de mantenimiento.

---

### P2-005 — Calculos pesados y parseos ocurren en build de pantallas grandes

**Archivo(s):**
- `lib/features/training_feature/screens/training_workspace_screen.dart`
- `lib/features/training_feature/screens/training_dashboard_screen.dart`
- `lib/features/client_feature/screen/client_overview_screen.dart`
- `lib/features/nutrition_feature/widgets/dietary_tab.dart`
- `lib/features/macros_feature/widgets/macros_content.dart`

**Clase / funcion / metodo:**
- `build` y helpers llamados desde `build`

**Problema:**
Se detectan `fold`, `sort`, parseos de records y calculos de resumen dentro de construccion de UI.

**Evidencia:**
Patrones auditados: `readNutritionRecordList`, `latestNutritionRecordByDate`, `fold`, `sort`, `DateTime.parse` y calculos de volumen/kcal dentro de builds.

**Impacto:**
La UI puede degradarse conforme crecen clientes, registros y planes.

**Reproduccion probable:**
Cliente con muchos registros nutricionales y plan de entrenamiento largo; cambiar tab o fecha.

**Correccion recomendada:**
Memoizar por cliente/fecha/version, mover calculos a providers selectivos y usar modelos derivados.

**Riesgo si no se corrige:**
Lag al cambiar tabs, abrir resumen o guardar.

---

### P2-006 — FinanceScreen lee notifier con `ref.read` y no observa estado

**Archivo(s):**
- `lib/features/finance_feature/finance_screen.dart`

**Clase / funcion / metodo:**
- `FinanceScreen.build`

**Problema:**
La pantalla usa `ref.read(transactionsProvider.notifier)` para calcular resumen, pero no `ref.watch(transactionsProvider)`.

**Evidencia:**

```dart
final transactionsNotifier = ref.read(transactionsProvider.notifier);
final monthlyIncome = transactionsNotifier.getMonthlyIncome(now);
```

**Impacto:**
La pantalla puede no reconstruirse cuando `_loadTransactions` actualiza `state`.

**Reproduccion probable:**
Abrir finanzas mientras carga Firestore; el provider actualiza, pero la pantalla no depende del estado observado.

**Correccion recomendada:**
Usar `ref.watch(transactionsProvider)` y calcular resumen desde la lista observada.

**Riesgo si no se corrige:**
Resumen financiero stale.

---

### P2-007 — BackgroundSyncService no resuelve conflictos ni aplica backoff por entidad

**Archivo(s):**
- `lib/core/services/background_sync_service.dart`
- `lib/data/repositories/client_repository.dart`

**Clase / funcion / metodo:**
- `BackgroundSyncService.trySyncPendingData`
- `ClientRepository.syncPendingClients`

**Problema:**
El sync sube clientes pendientes, pero no se observo merge remoto-local, resolucion por `updatedAt` de subdocumentos ni estrategia multi-dispositivo.

**Evidencia:**
`trySyncPendingData` itera `getUnsyncedClients` y llama `syncPendingClients`; el repositorio marca synced tras push remoto.

**Impacto:**
Si dos dispositivos editan el mismo cliente offline, el ultimo push puede pisar datos.

**Reproduccion probable:**
Editar nutricion offline en un dispositivo y entrenamiento offline en otro; reconectar ambos.

**Correccion recomendada:**
Agregar versionado por modulo/registro, resolucion de conflictos y merges remotos seguros.

**Riesgo si no se corrige:**
Perdida de cambios multi-dispositivo.

---

### P2-008 — `updatedAt/migratedAt` cambian en cada upsert local del cliente

**Archivo(s):**
- `lib/data/datasources/local/database_helper.dart`

**Clase / funcion / metodo:**
- `_encodeClientJsonIsolate`
- `upsertClient`

**Problema:**
El encode agrega `updatedAt` y `migratedAt` con `DateTime.now()` en cada guardado del cliente.

**Evidencia:**
Patron detectado en encode local: se asignan timestamps nuevos durante serializacion.

**Impacto:**
Cualquier guardado menor parece una modificacion global reciente, generando sync churn y ordenamientos potencialmente falsos.

**Reproduccion probable:**
Guardar un campo menor; revisar `updatedAt` del cliente.

**Correccion recomendada:**
Diferenciar migracion real de guardado normal. Actualizar `updatedAt` solo por mutacion de dominio, no por encode.

**Riesgo si no se corrige:**
Sync innecesario y dificultad para resolver conflictos.

---

### P2-009 — Migracion de nutrition plans puede ocurrir durante lectura

**Archivo(s):**
- `lib/data/repositories/nutrition_plan_repository.dart`

**Clase / funcion / metodo:**
- `_ensureMigratedRecords`
- `loadPlanForDate`

**Problema:**
La carga de planes puede disparar migracion y persistencia del cliente.

**Evidencia:**
Repositorio ejecuta migracion de snapshots dentro de flujo de lectura/carga.

**Impacto:**
Abrir una pantalla puede modificar datos, generar sync y complicar depuracion.

**Reproduccion probable:**
Abrir plan nutricional con registros legacy; revisar que cliente cambia aunque no se edite manualmente.

**Correccion recomendada:**
Separar migracion explicita de lectura o marcar migraciones idempotentes con version clara.

**Riesgo si no se corrige:**
Writes inesperados y sync mientras solo se navega.

## Hallazgos P3 — Bajos

### P3-001 — Textos corruptos por encoding en UI

**Archivo(s):**
- `lib/features/macros_feature/widgets/macros_content.dart`
- `lib/features/meal_plan_feature/screen/meal_plan_screen.dart`
- `lib/features/biochemistry_feature/screen/biochemistry_screen.dart`
- `lib/features/nutrition_feature/providers/dietary_provider.dart`

**Clase / funcion / metodo:**
- Textos visibles y comentarios

**Problema:**
Hay mojibake en strings: `MiÃ©rcoles`, `SÃ¡bado`, `ComparaciÐ˜n`, `Â¿Deseas...`.

**Evidencia:**
Strings visibles detectados en listas de dias y titulos.

**Impacto:**
UI poco profesional y posible comparacion por nombre de dia inconsistente si se mezclan strings corruptos y normalizados.

**Reproduccion probable:**
Abrir macros, meal plan o biochemistry.

**Correccion recomendada:**
Normalizar archivos a UTF-8 y centralizar nombres de dias.

**Riesgo si no se corrige:**
UX degradada y bugs sutiles por claves de dia.

---

### P3-002 — Widgets legacy de macros siguen exportados

**Archivo(s):**
- `lib/features/macros_feature/widgets/horizontal_macro_card.dart`
- `lib/features/macros_feature/widgets/macros_pie_chart_inner.dart`
- `lib/features/macros_feature/widgets/macros_pie_chart_outer.dart`
- `lib/features/macros_feature/widgets/macros_week_summary_chart.dart`
- `lib/features/index.dart`

**Clase / funcion / metodo:**
- Exports en `features/index.dart`

**Problema:**
La nueva cadena activa es `MacrosContent -> WeeklyMacrosLayout -> DayMacroDetailCard + WeeklyMacroSidebar`, pero widgets legacy siguen disponibles/exportados.

**Evidencia:**
`features/index.dart` exporta charts legacy de macros. `flutter analyze` tambien reporta info en `horizontal_macro_card.dart`.

**Impacto:**
Riesgo de que una pantalla futura importe la UI anterior.

**Reproduccion probable:**
Importar `features/index.dart` y usar widgets legacy accidentalmente.

**Correccion recomendada:**
Marcar legacy/deprecated y retirar exports cuando no haya referencias reales.

**Riesgo si no se corrige:**
Feature sprawl y UI inconsistente.

---

### P3-003 — Existen helpers/base de datos duplicados o legacy

**Archivo(s):**
- `lib/data/datasources/local/database_helper.dart`
- `lib/services/database_helper.dart`
- `lib/_audit/CODE_DEAD_INVENTORY.md`

**Clase / funcion / metodo:**
- Helpers de base de datos

**Problema:**
Hay mas de un `DatabaseHelper`/servicio relacionado a persistencia. El inventario `_audit` ya marca algunos archivos muertos.

**Evidencia:**
`rg "class DatabaseHelper"` detecta helpers fuera de la ruta principal local datasource.

**Impacto:**
Confusion sobre fuente real de SQLite y riesgo de usar helper viejo.

**Reproduccion probable:**
Agregar una feature nueva y tomar el helper equivocado por autocompletado.

**Correccion recomendada:**
Documentar helper canonico y deprecar/remover el legacy tras verificar referencias.

**Riesgo si no se corrige:**
Persistencia fragmentada.

---

### P3-004 — Coexisten varios dominios/motores de entrenamiento

**Archivo(s):**
- `lib/domain/training_engine`
- `lib/domain/training`
- `lib/domain/training_domain`
- `lib/domain/training_v3`
- `lib/domain/services/*training*`

**Clase / funcion / metodo:**
- Motores y adaptadores de entrenamiento

**Problema:**
Hay motor v3 activo, dominio legacy, servicios `@Deprecated` y adaptadores coexistiendo.

**Evidencia:**
Imports simultaneos de `training_v3` y `training_domain` en pantallas como `training_workspace_screen.dart`. Comentarios indican migrar a `training_v3`.

**Impacto:**
Riesgo de doble fuente de verdad para plan, ciclo, volumen y progresion.

**Reproduccion probable:**
Modificar una regla en un motor y observar otra pantalla usando otro dominio.

**Correccion recomendada:**
Mapa de ownership: motor canonico, adaptadores permitidos y rutas legacy congeladas.

**Riesgo si no se corrige:**
Inconsistencias de entrenamiento.

---

### P3-005 — `flutter analyze` mantiene warnings/dead code

**Archivo(s):**
- `lib/domain/training_v3/engines/split_generator_engine.dart`
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart`
- `lib/features/main_shell/widgets/client_selector_modal.dart`
- `lib/features/training_feature/providers/training_plan_provider.dart`
- `lib/features/training_feature/screens/training_workspace_screen.dart`

**Clase / funcion / metodo:**
- Elementos no usados, imports muertos y dead code

**Problema:**
El analisis estatico devuelve 29 issues.

**Evidencia:**
Resultado ejecutado:

```text
29 issues found.
warning - _generatePPL5Days isn't referenced
warning - unused fields in motor_v3_orchestrator.dart
warning - unused imports in client_selector_modal.dart
warning - Dead code in training_plan_provider.dart
warning - unused placeholders in training_workspace_screen.dart
```

**Impacto:**
No bloquea ejecucion por si solo, pero aumenta ruido y oculta warnings nuevos.

**Reproduccion probable:**
Ejecutar `flutter analyze --no-pub`.

**Correccion recomendada:**
Limpiar warnings por fase, empezando por dead code y exports legacy.

**Riesgo si no se corrige:**
Analisis estatico deja de ser una barrera confiable.

## Bugs de guardado/persistencia
- P0-001: borrados clinicos remotos bloquean borrado local.
- P0-002: finanzas no tienen persistencia local.
- P0-003: calendario no tiene persistencia local.
- P0-004: meal plan duplica por fecha cruda.
- P1-004: equivalentes entra a view sin esperar persistencia.
- P1-005: snapshots nutricionales pueden duplicarse por fecha.
- P2-001: antropometria tiene doble ruta de guardado.
- P2-009: carga de plan puede escribir migraciones.

## Bugs offline-first/sync
- Cliente principal si cumple flujo local-first en `ClientRepository.saveClient`: guarda local, agenda push remoto.
- Finanzas y calendario no cumplen offline-first: esperan Firestore antes de mutar UI.
- `RecordDeletionService` rompe offline-first en borrados clinicos.
- `SyncQueueHelper` tiene una ruta de cola no funcional si se usa.
- `BackgroundSyncService` sincroniza clientes pendientes, pero no se observo resolucion de conflictos multi-dispositivo.

## Bugs de calculos
- P1-001: nutricion puede precargar NAF/actividades de otra fecha.
- P1-002: macros puede usar evaluacion de otra fecha para kcal/mantenimiento.
- P1-003: meal plan puede tomar menu de otra fecha.
- P1-011: overview puede tomar energia no reciente por `records.last`.
- P2-005: parseos/calculos en build generan riesgo de lentitud y recomputos.

## Bugs de UI/estado
- P1-004: equivalentes marca view antes de persistir.
- P1-009: ciclos de entrenamiento guardados por repositorio pueden no reflejarse en `clientsProvider`.
- P1-012: limpiar cliente activo no limpia estado en memoria.
- P2-006: finanzas no observa `transactionsProvider`.
- P3-001: textos corruptos visibles.

## Bugs de fechas/registros duplicados
- P0-004: meal plan compara `dateIso` crudo.
- P1-007: training generated records compara `forDateIso` crudo.
- P1-001/P1-002/P1-003/P1-004: fallbacks a latest mezclan fechas.
- Riesgo transversal: coexistencia de `dateIso`, `date`, timestamps ISO y `DateTime.now()` en varios modulos.

## Riesgos de rendimiento/lentitud
- Archivos gigantes de UI/provider concentran estado y builds.
- Sort/parse/fold dentro de build en modulos de nutricion, macros, entrenamiento y dashboard.
- SQLite acumula `training_interviews` redundantes.
- Sync remoto de cliente completo puede crecer por JSON de cliente completo y cambios de `updatedAt`.

## Riesgos de perdida/corrupcion de datos
1. Borrado clinico no local-first: registros persisten cuando remoto falla.
2. Finanzas/calendario sin SQLite: datos se pierden offline.
3. Fallback a latest: edicion sobre fecha equivocada.
4. Snapshots/records duplicados: carga de version vieja.
5. Conflictos multi-dispositivo: ultimo push puede pisar cambios por cliente completo.

## Archivos implicados por hallazgo
| Hallazgo | Archivos principales |
|---|---|
| P0-001 | `record_deletion_service.dart`, `anthropometry_measures_tab.dart`, `biochemistry_tab.dart`, `dietary_tab.dart` |
| P0-002 | `transactions_provider.dart`, `transaction_firestore_datasource.dart`, `finance_screen.dart` |
| P0-003 | `appointments_provider.dart`, `appointment_firestore_datasource.dart`, `calendar_screen.dart` |
| P0-004 | `meal_plan_screen.dart` |
| P1-001 | `dietary_provider.dart` |
| P1-002 | `macros_content.dart` |
| P1-003 | `meal_plan_screen.dart` |
| P1-004 | `equivalents_by_day_screen.dart` |
| P1-005 | `nutrition_plan_repository.dart`, `daily_nutrition_plan_provider.dart` |
| P1-006 | `appointment_firestore_datasource.dart`, `appointment.dart` |
| P1-007 | `training_plan_provider.dart` |
| P1-008 | `active_cycle_bootstrapper.dart` |
| P1-009 | `training_cycle_repository.dart` |
| P1-010 | `database_helper.dart` |
| P1-011 | `client_overview_screen.dart` |
| P1-012 | `clients_provider.dart` |
| P1-013 | `sync_service.dart`, `sync_queue_helper.dart` |
| P2-001 | `anthropometry_measures_tab.dart`, `client_repository.dart`, `clients_provider.dart` |
| P2-002 | `clients_provider.dart` |
| P2-003 | `database_helper.dart`, `workout_log_repository.dart` |
| P2-004 | pantallas/providers grandes listados |
| P2-005 | training/nutrition/macros/dashboard build paths |
| P2-006 | `finance_screen.dart` |
| P2-007 | `background_sync_service.dart`, `client_repository.dart` |
| P2-008 | `database_helper.dart` |
| P2-009 | `nutrition_plan_repository.dart` |
| P3-001 | macros/meal/biochemistry/dietary text files |
| P3-002 | macros legacy widgets, `features/index.dart` |
| P3-003 | database helpers legacy |
| P3-004 | training engine/domain folders |
| P3-005 | analyze warning files |

## Mapa de flujo de guardado detectado
Flujo principal de cliente:

```text
UI feature -> clientsProvider.updateActiveClient -> ClientRepository.saveClient
-> LocalClientDatasource.saveClient -> DatabaseHelper.upsertClient
-> estado UI actualizado -> push remoto diferido / BackgroundSyncService
```

`ClientRepository.saveClient` guarda local primero y agenda push remoto con debounce:

```dart
await _local.saveClient(client);
_pendingRemotePush[client.id] = client;
Timer(..., () => unawaited(_pushClientRemote(...)));
```

Flujos fuera del contrato:

```text
Finance UI/provider -> TransactionFirestoreDataSource -> Firestore
Calendar/provider -> AppointmentFirestoreDataSource -> Firestore
RecordDeletionService -> Firestore delete -> luego local en caller
```

## Mapa de flujo offline-first detectado
Cumple parcialmente:
- Cliente completo via `ClientRepository`.
- `BackgroundSyncService` sube clientes no sincronizados y eliminados.
- `ClientRepository.deleteClient` soft-delete local antes del remoto.

No cumple:
- Finanzas.
- Calendario/citas.
- Borrados clinicos por `RecordDeletionService`.
- SyncQueue generica.
- Logs de entrenamiento independientes.

Puede fallar:
- Conflictos multi-dispositivo por cliente completo sin merge remoto granular.
- Auth ausente en sync deja pendientes sin subir.
- Remote push fallido se reintenta solo cuando se ejecute sync; no hay politica por dominio.

## Mapa de calculo nutricional detectado
- `dietary_provider.dart` calcula TMB/NAF/actividades y carga evaluaciones desde `NutritionExtraKeys.evaluationRecords`.
- `dietary_tab.dart` persiste calculo nutricional en `evaluationRecords`; actualmente normaliza fecha al guardar/borrar.
- `macros_content.dart` usa `dailyKcal`, `dailyMaintenance` y semana de macros para calcular protein/fat/carbs por dia.
- `macro_day_view_data.dart` soporta mantenimiento diario y delta semanal/mensual via `MacroWeekInsightData`.
- Riesgo principal: varios consumers usan fallback a `latestNutritionRecordByDate` cuando la fecha activa no tiene registro.

## Mapa de fechas detectado
Uso correcto observado:
- Helpers `dateIsoFrom`, `nutritionRecordForDate`, `latestNutritionRecordByDate`.
- `dietary_tab.dart` ya contiene normalizacion defensiva para `dateIso`.
- `macros_content.dart` normaliza al crear/actualizar/borrar records.

Uso riesgoso observado:
- Comparacion cruda en `meal_plan_screen.dart`.
- Comparacion cruda en `training_plan_provider.dart`.
- Fallback a latest en macros, meal plan, equivalents y dietary provider.
- `DateTime.now()` usado para ids/seeds/createdAt en varios modulos.
- Textos de dias corruptos/variantes (`MiÃ©rcoles`, `Miercoles`, `Miércoles`) pueden afectar claves si no se normalizan.

## Riesgos de perdida de datos
1. Finanzas/calendario no persisten offline.
2. Borrado clinico remoto-first bloquea eliminacion local.
3. `SyncQueueHelper` puede marcar success sin upload real.
4. Ultimo push de cliente completo puede pisar cambios de otro dispositivo.
5. Snapshots de planes sin clave unica por fecha pueden cargar versiones stale.
6. Fallback a latest puede editar fecha equivocada.

## Riesgos de lentitud
1. Widgets/providers de 1000-3000 lineas reconstruyen superficies grandes.
2. Sort/parse/fold en build sobre listas de registros.
3. Graficos y resumenes recalculados sin memoizacion clara.
4. `training_interviews` duplica filas en cada save.
5. Sync de cliente completo crece con `extra` y registros embebidos.

## Archivos legacy/sospechosos
| Archivo | Motivo | Referenciado | Riesgo |
|---|---|---|---|
| `lib/features/macros_feature/widgets/horizontal_macro_card.dart` | UI anterior de macros | Analizado por `flutter analyze`; no es parte de cadena nueva | Reintroducir formulario/lista antigua |
| `lib/features/macros_feature/widgets/macros_pie_chart_inner.dart` | Chart legacy | Exportado por `lib/features/index.dart` | Confusion con `MacroDistributionChart` |
| `lib/features/macros_feature/widgets/macros_pie_chart_outer.dart` | Chart legacy | Exportado por `lib/features/index.dart` | Doble fuente visual |
| `lib/features/macros_feature/widgets/macros_week_summary_chart.dart` | Resumen semanal legacy | Exportado por `lib/features/index.dart` | UI duplicada |
| `lib/services/database_helper.dart` | Helper paralelo a datasource local canonico | Existe junto a `lib/data/datasources/local/database_helper.dart` | Usar DB helper equivocado |
| `lib/domain/training_engine` | Motor historico | Coexiste con v3/domain | Reglas divergentes |
| `lib/domain/training_domain` | Dominio intermedio/SSOT v1 | Importado junto con v3 | Doble contrato de plan |
| `lib/domain/services/*training*` | Servicios legacy/deprecated | Algunos comentarios piden migrar a v3 | Mantenimiento duplicado |

## Recomendacion de correccion por fases

### Fase 1 — P0 Guardado/duplicados/borrado
- Corregir `RecordDeletionService` y callers para borrar local primero.
- Migrar finanzas y calendario a persistencia local-first.
- Normalizar `dateIso` en meal plan upsert.
- Agregar tests de duplicados por timestamp vs `YYYY-MM-DD`.

### Fase 2 — Offline-first/sync
- Definir contratos sync por dominio.
- Implementar upload real o retirar `SyncQueueHelper`.
- Agregar conflicto por modulo/registro con `updatedAt` granular.
- Definir sync de workout logs.

### Fase 3 — Calculos nutricionales
- Eliminar fallback a latest cuando existe fecha activa.
- Reusar una fuente unica para mantenimiento diario, kcal finales y actividad.
- Validar macros/meal/equivalents contra fecha exacta.

### Fase 4 — Estado/providers
- Centralizar escrituras en `updateActiveClient`.
- Asegurar `await` en creacion/seleccion de equivalents.
- Corregir `clearActiveClient`.
- Hacer que finance/calendar observen estado real con `watch`.

### Fase 5 — Performance
- Mover parseos/sorts/calculos a providers memoizados por cliente+fecha.
- Partir widgets gigantes en subcomponentes con modelos view-data.
- Evitar folds/sorts repetidos en build.

### Fase 6 — Limpieza legacy
- Marcar widgets macros legacy como deprecated.
- Retirar exports no usados.
- Consolidar helpers de DB.
- Documentar motor entrenamiento canonico.
- Limpiar warnings de `flutter analyze`.

## Prompts sugeridos para correccion

### Prompt Fase 1 — Borrado local-first y duplicados
Corregir solo P0-001 y P0-004. Tocar `record_deletion_service.dart`, callers de antropometria/bioquimica/nutricion y `meal_plan_screen.dart`. Implementar borrado local primero, sync remoto en background y normalizacion `YYYY-MM-DD` para upsert/delete. Ejecutar `flutter analyze`.

### Prompt Fase 2 — Finanzas/calendario offline-first
Implementar persistencia local para transacciones y citas sin cambiar rutas UI. Guardar local primero, agregar `isSynced/isDeleted/updatedAt`, sync background y fallback offline. No tocar modelos publicos sin revisar referencias.

### Prompt Fase 3 — Fechas exactas en nutricion/macros/meal/equivalents
Eliminar fallback a `latestNutritionRecordByDate` cuando hay fecha activa. Mostrar estado vacio/creating si no existe record exacto. Auditar `dietary_provider.dart`, `macros_content.dart`, `meal_plan_screen.dart`, `equivalents_by_day_screen.dart`.

### Prompt Fase 4 — Entrenamiento persistencia y determinismo
Corregir comparacion cruda de `forDateIso`, semilla no deterministica en `ActiveCycleBootstrapper`, y repositorios de ciclo que guardan sin actualizar `clientsProvider`.

### Prompt Fase 5 — Performance
Extraer view models memoizados para dietary/macros/training dashboards y eliminar sort/parse/fold repetidos en build. Medir antes/despues con perfiles simples.

### Prompt Fase 6 — Legacy/analyze
Limpiar widgets legacy exportados, helpers duplicados y warnings de analyze sin cambiar comportamiento funcional.

## Resultado de `flutter analyze`

Comando:

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Resultado:

```text
29 issues found. (ran in 3.9s)
```

Resumen de issues:
- Warnings por elementos no usados en `split_generator_engine.dart`, `motor_v3_orchestrator.dart` y `training_workspace_screen.dart`.
- Warnings por imports no usados en `client_selector_modal.dart`.
- Warnings por dead code en `training_plan_provider.dart`.
- Infos de `prefer_const_*` y argumentos redundantes.
- Infos en `horizontal_macro_card.dart`, que coincide con archivo legacy de macros.

No se corrigieron porque la tarea fue exclusivamente auditoria.
