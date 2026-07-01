# AUDIT_GLOBAL_DART_PRODUCTION_READINESS_REPORT

Fecha de auditoria: 2026-06-29  
Alcance: `lib/`, `test/`, presencia de `integration_test/` y `tool/`.  
Tipo: diagnostico tecnico de produccion. No se modifico codigo productivo.

## 1. Resumen ejecutivo

La app tiene una base tecnica seria: `flutter analyze --no-pub` esta limpio, existen tests relevantes de Motor V3, outbox, stale drafts, sync y modelos de dominio, y se cerraron P0 previos de contrato remoto/client outbox. Aun asi, no esta lista para produccion real sin cerrar algunos P0/P1 de persistencia, seguridad operativa y mantenibilidad.

Veredicto principal:

```text
VEREDICTO: AVANZAR FEATURES DESPUES DE CERRAR BLOQUEADORES P0/P1
```

Puede avanzar features de bajo riesgo si se protegen las rutas criticas, pero no conviene abrir features grandes que escriban datos clinicos/financieros hasta cerrar deletes durables, agenda/pagos offline-first, hardening Firebase/App Check y observabilidad.

## 2. Comandos ejecutados

```text
rg -n "PROVIDER-P1A|SAVE-P0|clientsProvider|production readiness" C:\Users\pedro\.codex\memories\MEMORY.md
```

```text
Get-ChildItem -Path lib,test -Recurse -Filter *.dart | Select-Object FullName
Resultado: salida truncada por tamano; se confirmo inventario amplio con 777 lineas emitidas antes del truncado.
```

```text
Get-ChildItem -Path lib -Recurse -Filter *.dart | Measure-Object
Count: 685
```

```text
Get-ChildItem -Path test -Recurse -Filter *.dart | Measure-Object
Count: 87
```

```text
Get-ChildItem -Path . -Directory | Select-Object Name
Resultado: existe integration_test/ y tool/; no existe scripts/ en raiz.
```

```text
Get-ChildItem -Path integration_test -Recurse -Filter *.dart | Select-Object FullName
Resultado: 2 archivos.
```

```text
Get-ChildItem -Path tool -Recurse -Filter *.dart | Select-Object FullName
Resultado: 0 archivos.
```

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Analyzing hcs_app_lap...
No issues found! (ran in 5.9s)
```

Tambien se ejecutaron los barridos `rg` solicitados para wide merges, persistencia/outbox, errores, dynamic/maps, seguridad, Firebase, providers, lifecycle, APIs deprecadas y performance UI. Las salidas grandes fueron truncadas por volumen, por lo que este reporte cita los hits relevantes y comandos focalizados posteriores.

## 3. Comandos cancelados

Ninguno en esta auditoria.

## 4. Inventario general

Conteo:

- `lib/`: 685 archivos `.dart`.
- `test/`: 87 archivos `.dart`.
- `integration_test/`: 2 archivos `.dart`.
- `tool/`: 0 archivos `.dart`.
- `scripts/`: no encontrado en raiz.

Distribucion top-level en `lib/`:

| Carpeta | Archivos Dart |
|---|---:|
| `domain` | 314 |
| `features` | 202 |
| `core` | 72 |
| `utils` | 36 |
| `data` | 23 |
| `nutrition_engine` | 16 |
| `presentation` | 7 |
| `services` | 4 |
| `ui` | 4 |
| `shared` | 2 |

Distribucion en `lib/features/`:

| Modulo | Archivos Dart |
|---|---:|
| `training_feature` | 75 |
| `nutrition_feature` | 22 |
| `main_shell` | 21 |
| `history_clinic_feature` | 19 |
| `dashboard_feature` | 16 |
| `macros_feature` | 14 |
| `anthropometry_feature` | 10 |
| `food_database_feature` | 6 |
| `meal_plan_feature` | 3 |
| `auth` | 3 |
| `biochemistry_feature` | 3 |

Archivos mas grandes detectados:

| Lineas | Archivo |
|---:|---|
| 2850 | `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart` |
| 2840 | `lib/domain/training_v3/services/motor_v3_orchestrator.dart` |
| 2755 | `lib/features/training_feature/widgets/muscle_detail_modal.dart` |
| 2749 | `lib/features/training_feature/screens/training_workspace_screen.dart` |
| 2657 | `lib/domain/training_v3/services/cycle_template_builder.dart` |
| 2184 | `lib/features/training_feature/providers/training_plan_provider.dart` |
| 2138 | `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart` |
| 2083 | `lib/presentation/screens/training/motor_v3_dashboard_screen.dart` |
| 2004 | `lib/features/training_feature/screens/training_dashboard_screen.dart` |
| 1542 | `lib/features/nutrition_feature/widgets/dietary_tab.dart` |
| 1440 | `lib/features/dashboard_feature/workspace_home_screen.dart` |
| 1141 | `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart` |

Carpetas con mayor riesgo aparente:

- `features/training_feature`: mayor volumen, providers grandes, persistencia directa de `Client`, Firestore V3/ML y mucha logica en UI/provider.
- `features/anthropometry_feature`: widget monolitico con UI, calculo, persistencia local, outbox y deletes.
- `features/biochemistry_feature`: widget monolitico similar a antropometria.
- `features/nutrition_feature` y `meal_plan_feature`: muchos records en `nutrition.extra`, deletes y snapshots parciales.
- `data/repositories` y `data/datasources`: mezcla de offline-first robusto para cliente/outbox con rutas Firestore directas para agenda/pagos.

## 5. Analyze controlado

Resultado:

```text
No issues found! (ran in 5.9s)
```

Interpretacion: el proyecto compila para analizador y cumple lints configurados. Esto no elimina riesgos de arquitectura, seguridad Firebase, falta de outbox en dominios online-first ni cobertura insuficiente por modulo.

## 6. Hallazgos con severidad

### P0-01: Deletes granulares de records clinicos no son durables

- Severidad: P0
- Archivo: `lib/domain/services/record_deletion_service.dart`
- Lineas aproximadas: 47, 86, 165
- Evidencia: `deleteAnthropometryByDate`, `deleteNutritionByDate`, `deleteBiochemistryByDate` llaman `_recordDataSource.deleteRecord(...)`.
- Archivo relacionado: `lib/data/datasources/remote/record_firestore_datasource.dart`
- Linea aproximada: 202
- Evidencia: `deleteRecord` hace `await ref.set({'deleted': true, ...}, SetOptions(merge: true));`
- Impacto: si la app cae, el usuario pierde auth o Firestore falla antes del set remoto, el delete local/remoto puede quedar inconsistente. Los upserts antropometria/bioquimica ya tienen outbox, pero deletes no.
- Recomendacion: implementar outbox durable para deletes granulares por `clientId + domain + dateKey` con tombstone local y retry idempotente.
- Sprint sugerido: `SAVE-P0E`.
- Bloquea produccion: si, para produccion real con records clinicos.

### P1-01: Agenda y pagos/transacciones son online-first sin outbox local

- Severidad: P1
- Archivos:
  - `lib/data/repositories/appointment_firestore_datasource.dart`
  - `lib/data/repositories/transaction_firestore_datasource.dart`
  - `lib/features/dashboard_feature/providers/appointments_provider.dart`
  - `lib/features/dashboard_feature/providers/transactions_provider.dart`
- Lineas aproximadas:
  - Appointments: `set/update/delete` en 109, 126, 138.
  - Transactions: `set/update/delete` en 93, 112, 124.
  - Providers actualizan estado solo despues de Firestore.
- Evidencia: providers instancian datasources Firestore y no hay `sync_queue` ni persistencia SQLite local.
- Impacto: sin red/auth, agenda y pagos no son confiables; se pueden perder operaciones o dejar UI divergente.
- Recomendacion: definir si agenda/pagos son scope de beta. Si si, agregar tablas locales + outbox o degradar feature a online-only explicitamente con UX y tests.
- Sprint sugerido: `AGENDA-PAYMENTS-P1A`.
- Bloquea produccion: si, si agenda/pagos entran en produccion.

### P1-02: `clientsProvider.updateActiveClient` sigue siendo API publica de merge amplio

- Severidad: P1
- Archivo: `lib/features/main_shell/providers/clients_provider.dart`
- Lineas aproximadas: 160, 196, 197, 320, 321
- Evidencia: aunque el contrato fue documentado y hay helpers granulares, el merge interno conserva `profile: updated.profile` y `history: updated.history`; el path legacy privado conserva lo mismo.
- Impacto: un caller futuro puede devolver snapshot viejo y pisar ramas completas del `Client`.
- Recomendacion: migrar callers restantes a helpers granulares, hacer canary de patrones, y eventualmente deprecar `updateActiveClient(Client Function(Client))` para escritura parcial.
- Sprint sugerido: `PROVIDER-P1A-E`.
- Bloquea produccion: no si se congela la superficie de nuevos callers, pero si bloquea features grandes que escriban `Client`.

### P1-03: `InactiveClientsScreen` usa snapshot completo para reactivar

- Severidad: P1
- Archivo: `lib/features/main_shell/widgets/inactive_clients_screen.dart`
- Linea aproximada: 152
- Evidencia: `.updateActiveClient((prev) => updatedClient)`
- Impacto: ademas de wide snapshot, semantica sospechosa: reactivar un cliente inactivo de lista no necesariamente coincide con el active client. Puede actualizar el cliente activo equivocado o copiar un snapshot amplio.
- Recomendacion: usar repositorio/operacion por id o helper dedicado `reactivateClientById`, con test de que no modifica otro active client.
- Sprint sugerido: `CLIENT-STATUS-P1A`.
- Bloquea produccion: si para flujos de reactivacion/desactivacion.

### P1-04: `TrainingInterviewTab` copia `updatedClient.training` desde snapshot local

- Severidad: P1
- Archivo: `lib/features/training_feature/tabs/training_interview_tab.dart`
- Lineas aproximadas: 122, 134
- Evidencia:

```dart
final updatedClient = currentClient.copyWith(training: updatedTraining);
await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
  return prev.copyWith(training: updatedClient.training);
});
```

- Impacto: si `currentClient` quedo stale frente a otros cambios de `training`, puede pisar subramas de entrenamiento no editadas.
- Recomendacion: aplicar patch de campos editados contra `prev.training` o usar `updateActiveClientTraining`.
- Sprint sugerido: `TRAINING-INTERVIEW-P1A`.
- Bloquea produccion: si se habilita edicion concurrente o cambios paralelos de entrenamiento.

### P1-05: Preferencias reales de ejercicio no alimentan el provider activo

- Severidad: P1
- Archivo: `lib/features/training_feature/providers/client_preferences_effect_provider.dart`
- Lineas aproximadas: 7, 17
- Evidencia: `clientPreferencesEffectProvider` retorna `const ExercisePreferencesByMuscle()` aunque haya cliente activo.
- Impacto: preferencias reales del cliente pueden no afectar seleccion de ejercicios; riesgo funcional alto para entrenamiento personalizado.
- Recomendacion: leer `TrainingExtraKeys.exercisePreferencesByMuscle` o fuente canonica validada, con tests de mapeo.
- Sprint sugerido: `TRAINING-PREF-P1`.
- Bloquea produccion: no para beta limitada, si para prometer personalizacion real.

### P1-06: App Check usa providers debug en Android/iOS

- Severidad: P1
- Archivo: `lib/main.dart`
- Lineas aproximadas: 51-53
- Evidencia: `providerAndroid: const AndroidDebugProvider()`, `providerApple: const AppleDebugProvider()`.
- Impacto: para produccion real App Check debe usar providers productivos; debug tokens no son barrera adecuada contra abuso.
- Recomendacion: condicionar por build flavor/ambiente y exigir providers productivos antes de release.
- Sprint sugerido: `SECURITY-FIREBASE-P1A`.
- Bloquea produccion: si.

### P1-07: Observabilidad de errores no esta conectada a Crashlytics/servicio remoto

- Severidad: P1
- Archivo: `lib/core/utils/error_handler.dart`
- Linea aproximada: 13
- Evidencia: `// FirebaseCrashlytics.instance.recordError(error, stackTrace);`
- Archivo relacionado: `lib/core/utils/app_logger.dart`
- Evidencia: logger imprime solo bajo `kDebugMode`; en release no hay salida remota.
- Impacto: fallos productivos quedan invisibles; sin trazas, no hay operacion segura.
- Recomendacion: conectar Crashlytics/Sentry u observabilidad equivalente, con redaccion y sampling.
- Sprint sugerido: `OBS-P1A`.
- Bloquea produccion: si para produccion real.

### P1-08: Rutas Firestore legacy/top-level pueden bifurcar datos

- Severidad: P1
- Archivo: `lib/data/datasources/remote/remote_client_datasource_impl.dart`
- Lineas aproximadas: 15, 24, 30, 43
- Evidencia: usa `collection('clients')` top-level, mientras el datasource principal usa `coaches/{coachId}/clients/{clientId}`.
- Impacto: si alguien inyecta o reactiva esta ruta, los datos pueden escribirse fuera del ownership esperado.
- Recomendacion: deprecar/remover tras confirmar no callers productivos, o bloquear con tests de contrato.
- Sprint sugerido: `FIRESTORE-CLEANUP-P1A`.
- Bloquea produccion: no si no hay callers productivos, si bloquea limpieza de seguridad.

### P1-09: Mapas `extra` y `Map<String,dynamic>` son SSOT extensivo sin schema central

- Severidad: P1
- Archivos representativos:
  - `lib/domain/entities/training_profile.dart`
  - `lib/domain/entities/clinical_history.dart`
  - `lib/domain/entities/nutrition_settings.dart`
  - `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
  - `lib/features/training_feature/domain/training_pipeline_guard.dart`
- Evidencia: busqueda `dynamic|Map<String, dynamic>|extra` produjo miles de hits; `training.extra`, `nutrition.extra` e `history.extra` contienen estado critico.
- Impacto: keys rotas o formatos mixtos pueden pasar hasta runtime/Firestore; el sanitizer evita caracteres invalidos, pero no valida semantica.
- Recomendacion: schema por dominio con validators, migraciones suaves y tests de round-trip por key critica.
- Sprint sugerido: `SCHEMA-EXTRA-P1A`.
- Bloquea produccion: parcial; bloquea nuevos dominios con datos sensibles.

### P1-10: Record Firestore upsert solo loguea payload invalido antes de set

- Severidad: P1
- Archivo: `lib/data/datasources/remote/record_firestore_datasource.dart`
- Lineas aproximadas: 112-124
- Evidencia: si `invalidPath != null`, hace `developer.log(...)` y luego ejecuta `ref.set`.
- Impacto: si aparece payload no valido tras sanitizer o por estructura adicional, puede fallar tarde o quedar inconsistente con contrato P0D aplicado a clients.
- Recomendacion: alinear contrato de records con clients: payload invalido debe lanzar error controlado y dejar outbox pendiente.
- Sprint sugerido: `SAVE-P0E` o `RECORDS-P1A`.
- Bloquea produccion: no si sanitizer cubre casos actuales; riesgo alto para robustez.

### P2-01: Providers/pantallas monoliticas concentran UI, estado, calculo y persistencia

- Severidad: P2
- Archivos:
  - `anthropometry_measures_tab.dart` 2850 lineas.
  - `biochemistry_tab.dart` 2138 lineas.
  - `training_workspace_screen.dart` 2749 lineas.
  - `training_plan_provider.dart` 2184 lineas.
  - `dietary_tab.dart` 1542 lineas.
- Impacto: alto costo de cambio, dificil test unitario, mayor riesgo de regresion.
- Recomendacion: extraer coordinadores/casos de uso cuando se toque cada modulo, sin refactor global.
- Sprint sugerido: continuo por modulo.
- Bloquea produccion: no por si solo, pero eleva costo de estabilizacion.

### P2-02: Logs de debug y mensajes con datos operativos dispersos

- Severidad: P2
- Archivos representativos:
  - `lib/features/dashboard_feature/providers/appointments_provider.dart`
  - `lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart`
  - `lib/domain/training_v3/repositories/*`
- Evidencia: `debugPrint` abundante; el logger redacciona email/UUID/numeros largos, pero muchos `debugPrint` saltan esa redaccion.
- Impacto: ruido, posible exposicion en builds debug/beta, baja trazabilidad estructurada.
- Recomendacion: normalizar logs por `AppLogger` con redaccion por dominio.
- Sprint sugerido: `OBS-P2B`.
- Bloquea produccion: no si release desactiva debug, pero si para beta con datos reales.

### P2-03: CI/CD no encontrado

- Severidad: P2
- Evidencia: `Test-Path .github` devolvio `False`.
- Impacto: no hay evidencia de pipeline automatico para analyze/tests/canaries.
- Recomendacion: agregar CI con `flutter analyze --no-pub` y canaries criticos; no ejecutar test completo si aun no es estable.
- Sprint sugerido: `CI-P1A`.
- Bloquea produccion: si para produccion real, no para desarrollo local.

### P2-04: APIs Flutter deprecadas no son problema dominante

- Severidad: P2/informativo
- Evidencia: no se detectaron `FlatButton`, `RaisedButton`, `OutlineButton`, `WillPopScope` relevantes. Hay `DropdownButtonFormField`, valido pero no Material 3 estricto.
- Recomendacion: no gastar sprint en esto salvo que UI/UX lo requiera.
- Bloquea produccion: no.

## 7. Auditoria por patrones

### 7.1 Wide merges / stale snapshots

Hits relevantes:

- `clients_provider.dart:196-203` y `320-327`: wide merge interno con `updated.profile/history/trainingPlans`.
- `inactive_clients_screen.dart:152`: snapshot completo `updatedClient`.
- `training_interview_tab.dart:134`: copia seccion completa `updatedClient.training`.
- `training_plan_provider.dart`: multiples `client.copyWith(training: client.training.copyWith(extra: ...))` y `repo.saveClient(updatedClient)`; muchos parecen transformaciones de entrenamiento, pero no todos usan `clientsProvider` fresco.

Estado: Historia Clinica/MealPlan/MainShell quedaron cerrados por canaries previos, pero la superficie general de `Client` sigue abierta.

### 7.2 Persistencia y outbox

Fortalezas:

- `ClientRepository` y `BackgroundSyncService` tienen contrato de snapshot/stale y outbox.
- `ClinicalRecordsRepository` encola upserts de antropometria y bioquimica.
- Tests existen para `client_repository_outbox`, `client_repository_sync` y `clinical_records_outbox`.

Riesgos:

- Deletes antropometria/bioquimica/nutricion/training via `RecordDeletionService` no pasan por outbox.
- Agenda/pagos son Firestore directos.
- Nutricion/training records genericos tienen push fire-and-forget sin evidencia de outbox equivalente a antropometria/bioquimica.

### 7.3 Manejo de errores

Bueno:

- `analysis_options.yaml` eleva `use_build_context_synchronously` y `avoid_print` a error.
- Muchos flujos usan `mounted` y `context.mounted`.

Riesgos:

- `appointment_firestore_datasource.dart` y `transaction_firestore_datasource.dart` devuelven `[]` en errores de lectura, ocultando causa a la UI.
- `transactions_provider.dart` atrapa error de carga y deja `state = []`.
- `RecordDeletionService` puede consumir error via callback y no construir retry durable.

### 7.4 Dynamic / Map sin contrato

La app depende intensamente de `extra`:

- `training.extra` para pipeline, landmarks, preferencias, snapshots.
- `nutrition.extra` para records, meal plans, equivalentes.
- `history.extra` para historia clinica granular.

Esto es pragmático, pero para produccion requiere schema versionado por key critica y validadores de entrada/salida.

### 7.5 Seguridad / datos sensibles

No se detectaron secretos obvios tipo `serviceAccount` o `privateKey` en `lib/test`. `firebase_options.dart` contiene `apiKey`, esperado en apps Firebase cliente.

Riesgos reales:

- App Check debug providers en `main.dart`.
- Crashlytics/observabilidad no activa.
- Logs directos con `debugPrint` fuera de `AppLogger`.
- No se auditaron Firebase rules porque estan fuera del alcance del prompt; aun asi son prerequisito de produccion.
- No se detecto uso de Firebase Storage en el barrido; si fotos/progress photos existen en assets o futuro, falta ownership/storage rules.

### 7.6 Firebase / Firestore / Storage

Rutas principales:

- Cliente: `coaches/{coachId}/clients/{clientId}`.
- Records: `coaches/{coachId}/clients/{clientId}/{anthropometry_records|biochemistry_records|nutrition_records|training_records}/{dateKey}`.
- Agenda: `coaches/{uid}/appointments/{appointmentId}`.
- Transacciones: `coaches/{uid}/transactions/{transactionId}`.
- Legacy clientes: `clients/{id}` en `RemoteClientDataSourceImpl`.
- Training V3/ML: varias rutas `users/{userId}/...`, `performance_metrics`, datasets ML.

Storage:

- No se detectaron hits relevantes de `FirebaseStorage`, `putFile`, `putData`, `getDownloadURL` en el barrido principal.

### 7.7 Providers / estado global

Riesgos:

- `training_plan_provider.dart` es demasiado grande y mezcla generacion, persistencia, estado y Firestore.
- `clientsProvider` es centro correcto de SSOT local, pero sigue aceptando transform amplio.
- `AppointmentsNotifier` y `TransactionsNotifier` hacen carga async dentro de `build()` y actualizan estado despues, sin outbox ni estado de error rico.

### 7.8 Navegacion / lifecycle

Hay buen uso de `mounted` en varias pantallas criticas. Riesgos restantes:

- Mucho `showDialog` y `ScaffoldMessenger` en widgets grandes.
- Controllers abundantes en tabs largas; varios tienen dispose, pero el volumen hace facil introducir fugas.
- `client_selection_screen.dart` crea controllers dentro de dialog y los dispone manualmente; aceptable, pero fragil.

### 7.9 Deprecated / compatibilidad Flutter

No hay uso relevante de botones Material antiguos. El uso de `DropdownButtonFormField` no es bloqueo.

### 7.10 Performance / UI pesada

Pantallas con riesgo:

- `AnthropometryMeasuresTab`: 2850 lineas, muchos controllers, calculos, persistencia y UI.
- `BiochemistryTab`: 2138 lineas.
- `TrainingWorkspaceScreen`, `TrainingDashboardScreen`, `MotorV3DashboardScreen`: UI y logica pesada.
- `WorkspaceHomeScreen`: 1440 lineas, agrega/calcula dashboard en build.

Recomendacion: perf profiling por pantallas top antes de beta; extraer solo al tocar cada modulo.

## 8. Auditoria por modulo

### main_shell

- Estado general: centraliza shell, navegacion, `clientsProvider`, seleccion activa y guardado de modulos.
- Riesgos P0: ninguno nuevo confirmado.
- Riesgos P1: `InactiveClientsScreen` reactivacion por snapshot completo; `clientsProvider.updateActiveClient` publico.
- Riesgos P2: shell grande y callbacks de guardado cruzados.
- Seguridad: `_ensureCoachRoot` escribe en Firestore desde UI/shell.
- Persistencia/sync: client outbox robusto; seleccion activa local.
- Tests existentes: `clients_provider_hardening_test.dart`, `concurrent_update_active_client_test.dart`.
- Falta para produccion: operacion por id para reactivar/desactivar, canary de no wide snapshot.
- Siguiente sprint: `CLIENT-STATUS-P1A`.

### history_clinic_feature

- Estado general: tabs principales migradas a `Future<void> saveIfDirty()` y patch helpers.
- Riesgos P0: no detectados en flujo migrado.
- Riesgos P1: `general_evaluation_tab.dart` sigue grande; datos en `history.extra` y `nutrition.extra`.
- Riesgos P2: tabs con muchos controllers y estado local.
- Seguridad: contiene datos clinicos sensibles; requiere rules/observabilidad redaccion.
- Persistencia/sync: via `clientsProvider`.
- Tests existentes: stale drafts, merge closeout, wide merge final closeout.
- Falta para produccion: schema/validators de `extra` clinico.
- Siguiente sprint: `SCHEMA-EXTRA-P1A`.

### anthropometry_feature

- Estado general: funcional pero monolitico.
- Riesgos P0: delete remoto no durable.
- Riesgos P1: widget mezcla UI, calculo, persistencia, outbox.
- Riesgos P2: 2850 lineas; alto costo de mantenimiento.
- Seguridad: datos clinicos sensibles.
- Persistencia/sync: upsert local+outbox existe; delete sin outbox.
- Tests existentes: clinical records outbox y smoke manual Firestore.
- Falta para produccion: delete durable, tests de delete, perf/refactor incremental.
- Siguiente sprint: `SAVE-P0E`.

### biochemistry_feature

- Estado general: similar a antropometria, con muchas entradas clinicas.
- Riesgos P0: delete remoto no durable.
- Riesgos P1: widget grande y posible validacion insuficiente de records vacios/parciales.
- Riesgos P2: 2138 lineas.
- Seguridad: datos de laboratorio sensibles.
- Persistencia/sync: upsert con outbox; delete sin outbox.
- Tests existentes: clinical records outbox.
- Falta para produccion: delete durable y tests por dateKey.
- Siguiente sprint: `SAVE-P0E`.

### nutrition_feature

- Estado general: mucha logica en `nutrition.extra`, equivalentes, dietary y deletion service.
- Riesgos P0: delete de nutricion remoto directo sin outbox si se considera record critico.
- Riesgos P1: records nutricionales genericos no tienen contrato outbox tan probado como antropometria/bioquimica.
- Riesgos P2: `dietary_tab.dart` 1542 lineas; estado UI y persistencia mezclados.
- Seguridad: datos sensibles de dieta/salud.
- Persistencia/sync: principalmente `Client.nutrition.extra` y Firestore records genericos.
- Tests existentes: nutrition validators, migration, record helpers, nutrition_engine.
- Falta para produccion: schema de nutrition.extra, outbox para deletes y records criticos.
- Siguiente sprint: `NUTRITION-RECORDS-P1A`.

### macros_feature

- Estado general: usa `clientsProvider` para persistir settings por dia.
- Riesgos P0: ninguno confirmado.
- Riesgos P1: `macros_view_model.dart` mantiene `updatedClient = client` y devuelve updated desde transform; revisar stale snapshot antes de ampliar.
- Riesgos P2: `macros_content.dart` 933 lineas.
- Seguridad: datos nutricionales.
- Persistencia/sync: via Client/nutrition.
- Tests existentes: algunos tests de macros/adherence indirectos.
- Falta para produccion: tests funcionales de no overwrite entre dias.
- Siguiente sprint: `MACROS-P2A`.

### meal_plan_feature

- Estado general: tras P1A-C/D, emite `onClientUpdated` y MainShell aplica patch nutricional granular.
- Riesgos P0: ninguno nuevo confirmado.
- Riesgos P1: mantiene `_pendingClient` y snapshots nutricionales locales; cubierto parcialmente por MainShell helper.
- Riesgos P2: faltan tests funcionales de delete/record selection.
- Seguridad: datos nutricionales.
- Persistencia/sync: via MainShell -> clientsProvider.
- Tests existentes: canaries de no usar viewmodel clinico; helpers de adherence.
- Falta para produccion: tests de flujos de delete meal plan y cambio de fecha.
- Siguiente sprint: `MEALPLAN-P2A`.

### training_feature

- Estado general: modulo dominante en tamano y complejidad.
- Riesgos P0: no se audito Motor V3 cientifico como cambio, pero si hay rutas Firestore directas y preferencias no conectadas.
- Riesgos P1: `TrainingInterviewTab` stale snapshot; `clientPreferencesEffectProvider` vacio; `training_plan_provider` gigante con persistencia directa; rutas V3/ML Firestore sin outbox.
- Riesgos P2: widgets y providers monoliticos, debug logs abundantes.
- Seguridad: training logs/ML datasets pueden contener datos de usuario.
- Persistencia/sync: mixto: Client JSON, SQLite workout logs, Firestore repositories.
- Tests existentes: fuerte cobertura Motor V3/domain/regression.
- Falta para produccion: estabilizar preferencias reales, delimitar repos Firestore V3, observabilidad.
- Siguiente sprint: `TRAINING-PREF-P1`.

### data/repositories

- Estado general: client/outbox robusto; agenda/pagos online-first.
- Riesgos P0: deletes records sin outbox viven fuera de repositorio durable.
- Riesgos P1: datasources legacy/top-level y Firestore directos.
- Riesgos P2: manejo de error que devuelve listas vacias.
- Seguridad: depende de FirebaseAuth y rules.
- Persistencia/sync: buena para clients y clinical upserts; incompleta para otros dominios.
- Tests existentes: client_repository_outbox/sync, clinical_records_outbox.
- Falta para produccion: unificar contrato offline-first por dominio.
- Siguiente sprint: `SAVE-P0E` y luego `AGENDA-PAYMENTS-P1A`.

### core

- Estado general: constants, services, logger, sync.
- Riesgos P0: ninguno nuevo confirmado.
- Riesgos P1: observabilidad no remota; SyncService procesa dominios soportados pero domains no soportados solo se saltan.
- Riesgos P2: logger solo debug local.
- Seguridad: sanitizacion Firestore existe.
- Persistencia/sync: background sync es pieza critica y tiene tests.
- Tests existentes: background sync outbox, registry strict.
- Falta para produccion: Crashlytics/Sentry, metricas sync, alertas.
- Siguiente sprint: `OBS-P1A`.

### auth

- Estado general: FirebaseAuth email/password y AuthGate.
- Riesgos P0: ninguno confirmado.
- Riesgos P1: no se auditaron rules ni MFA/roles; App Check debug afecta seguridad global.
- Riesgos P2: falta test auth UI/flows.
- Seguridad: requiere politica de roles/ownership en Firestore rules.
- Persistencia/sync: auth user es coach id.
- Tests existentes: no se observaron tests auth dedicados.
- Falta para produccion: security review Firebase rules, App Check productivo.
- Siguiente sprint: `SECURITY-FIREBASE-P1A`.

### agenda

- Estado general: existe `calendar_feature` y providers de appointments en dashboard.
- Riesgos P0: no si se declara online-only; si se promete offline, P1 alto.
- Riesgos P1: Firestore directo sin outbox/cache local durable.
- Riesgos P2: provider oculta errores con estado vacio.
- Seguridad: ownership por `coaches/{uid}`.
- Persistencia/sync: online-first.
- Tests existentes: no se observaron tests de appointments.
- Falta para produccion: tabla local/outbox o scope online-only documentado.
- Siguiente sprint: `AGENDA-PAYMENTS-P1A`.

### payments

- Estado general: transacciones en dashboard/finance.
- Riesgos P0: financieros requieren consistencia fuerte; sin outbox puede perder UX de escritura.
- Riesgos P1: Firestore directo y errores convertidos en `[]`.
- Riesgos P2: calculos en provider local sin tests suficientes visibles.
- Seguridad: datos financieros sensibles.
- Persistencia/sync: online-first.
- Tests existentes: no se observaron tests de transactions.
- Falta para produccion: offline-first o alcance beta claro; tests de permisos/errores.
- Siguiente sprint: `AGENDA-PAYMENTS-P1A`.

## 9. Tests existentes y cobertura real

Conteo `test/`: 87 archivos Dart.

Distribucion:

- `test/domain`: 44 archivos; fuerte cobertura Motor V3/domain.
- `test/features`: 7 archivos; cobertura focalizada, no completa por UI.
- `test/data`: 4 archivos; client/outbox/sync/clinical records.
- `test/core`: 3 archivos; sync/registry.
- `test/manual`: 3 archivos; smoke manual.
- `test/nutrition_engine`: 2 archivos.
- Raiz de `test/`: multiples unit/integration pequenos.

Tests funcionales fuertes:

- `test/data/repositories/client_repository_outbox_test.dart`
- `test/data/repositories/client_repository_sync_test.dart`
- `test/data/repositories/clinical_records_outbox_test.dart`
- `test/core/services/background_sync_service_outbox_test.dart`
- `test/core/services/background_sync_service_clinical_records_outbox_test.dart`
- Motor V3/domain regression suites.

Canaries de texto/contrato:

- `history_clinic_wide_merge_final_closeout_test.dart`
- `history_clinic_merge_closeout_test.dart`
- `clinical_tabs_stale_drafts_test.dart`
- `clients_provider_hardening_test.dart`

Modulos con cobertura insuficiente para produccion:

- Agenda/appointments.
- Payments/transactions.
- Auth.
- Reactivacion/desactivacion de clientes.
- Deletes granulares de records.
- UI critical flows end-to-end.
- Observabilidad/error handling.

## 10. Production Readiness Score

| Dimension | Score |
|---|---:|
| Arquitectura de dominio | 72/100 |
| Persistencia local | 74/100 |
| Sync/outbox | 63/100 |
| Seguridad Firebase | 48/100 |
| Seguridad local | 58/100 |
| Manejo de errores | 61/100 |
| Validacion de datos | 57/100 |
| Tests | 66/100 |
| CI/CD | 15/100 |
| Observabilidad | 25/100 |
| Performance UI | 54/100 |
| Mantenibilidad | 52/100 |

Score global estimado: 56/100  
Confianza de la estimacion: media.

Motivo de confianza media: se auditaron todos los Dart por patrones y archivos clave, pero no se ejecutaron todos los tests ni se auditaron Firebase rules, datos reales, perfiles de performance ni builds release.

## 11. Que bloquea avanzar con features ahora

### Bloqueadores reales

1. Deletes granulares clinicos no durables (`SAVE-P0E`).
2. App Check debug para builds moviles productivos.
3. Ausencia de observabilidad remota.
4. Agenda/pagos online-first si forman parte del alcance de produccion.
5. `InactiveClientsScreen` con reactivacion via snapshot completo.
6. `TrainingInterviewTab` con snapshot amplio de training.

### Riesgos aceptables temporalmente

- `updateActiveClient` publico si se congelan nuevos callers amplios y se exige helper granular.
- UI monolitica en antropometria/biochemistry/training si no se toca sin tests.
- `extra` maps si se agregan validators por dominio antes de ampliar features.

### Deuda que no debe bloquear

- Migrar todos los dropdowns a nuevos componentes.
- Refactor global de pantallas grandes.
- Limpiar todos los logs de debug antes de una beta interna sin datos reales.
- Unificar todo Motor V3 si los tests actuales se mantienen.

## 12. Roadmap recomendado

### Sprint 1: SAVE-P0E deletes durables

- Objetivo: outbox durable para deletes antropometria/bioquimica/nutricion/training por dateKey.
- Archivos probables: `record_deletion_service.dart`, `clinical_records_repository.dart`, `background_sync_service.dart`, tests data/core.
- Riesgo que cierra: perdida/inconsistencia de deletes clinicos.
- Tests esperados: delete enqueue, retry, no-auth pending, remote success closes queue.
- Reporte esperado: `AUDIT_SAVE_P0E_CLINICAL_RECORD_DELETES_OUTBOX_REPORT.md`.
- Bloquea produccion: si.

### Sprint 2: CLIENT-STATUS-P1A

- Objetivo: corregir reactivacion/desactivacion de clientes por id sin wide snapshot.
- Archivos probables: `inactive_clients_screen.dart`, `clients_provider.dart` o repositorio.
- Riesgo que cierra: stale snapshot y cliente equivocado.
- Tests esperados: reactivar cliente inactivo no modifica active client equivocado.
- Reporte esperado: `AUDIT_CLIENT_STATUS_P1A_REACTIVATION_CONTRACT_REPORT.md`.
- Bloquea produccion: si para flujos de clientes inactivos.

### Sprint 3: SECURITY-FIREBASE-P1A

- Objetivo: App Check productivo, validacion de rules esperadas, matriz de ownership.
- Archivos probables: `main.dart`, docs/rules fuera de este sprint, tests/manual smoke.
- Riesgo que cierra: abuso de API y acceso cruzado.
- Tests esperados: build/flavor config, smoke auth/permission-denied.
- Reporte esperado: `AUDIT_SECURITY_FIREBASE_P1A_REPORT.md`.
- Bloquea produccion: si.

### Sprint 4: OBS-P1A

- Objetivo: Crashlytics/Sentry, logger con redaccion y breadcrumbs de sync.
- Archivos probables: `app_logger.dart`, `error_handler.dart`, bootstrap.
- Riesgo que cierra: fallos invisibles en beta/produccion.
- Tests esperados: logger redaction unit tests, no PII.
- Reporte esperado: `AUDIT_OBS_P1A_RUNTIME_ERRORS_REPORT.md`.
- Bloquea produccion: si.

### Sprint 5: AGENDA-PAYMENTS-P1A

- Objetivo: decidir y cerrar contrato de agenda/pagos: online-only explicito o offline-first con outbox.
- Archivos probables: appointment/transaction datasources/providers.
- Riesgo que cierra: perdida de datos financieros/agenda.
- Tests esperados: add/update/delete failure paths, no-auth, permission-denied.
- Reporte esperado: `AUDIT_AGENDA_PAYMENTS_P1A_PERSISTENCE_CONTRACT_REPORT.md`.
- Bloquea produccion: si esos modulos entran en release.

### Sprint 6: TRAINING-PREF-P1

- Objetivo: conectar preferencias reales del cliente a entrenamiento.
- Archivos probables: `client_preferences_effect_provider.dart`, `exercise_preferences_models.dart`, training provider.
- Riesgo que cierra: personalizacion de ejercicio no efectiva.
- Tests esperados: prefs en `training.extra` afectan provider.
- Reporte esperado: `AUDIT_TRAINING_PREF_P1_REPORT.md`.
- Bloquea produccion: no para beta limitada, si para promesa comercial.

## 13. Separacion por etapa

### Para avanzar features con menor riesgo

- Cerrar `SAVE-P0E`.
- Congelar nuevos writers de `Client` sin helper granular.
- No tocar agenda/pagos salvo que se acepte online-only.

### Para beta interna

- Cerrar deletes durables.
- App Check configurado por ambiente.
- Crashlytics/observabilidad minima.
- Canaries P0/P1 en CI local o GitHub Actions.

### Para produccion real

- Firebase rules auditadas.
- CI/CD con analyze y canaries.
- Outbox o contrato online-only para agenda/pagos.
- Tests de auth/permission-denied.
- Plan de redaccion de logs y datos sensibles.

### Para escalar a movil/cliente

- App Check productivo.
- Offline-first definido por dominio.
- Performance profiling de pantallas grandes.
- Storage rules si se agregan imagenes/fotos.

## 14. Archivos inspeccionados destacados

No se abrieron completos todos los 685 archivos de `lib/`, pero se auditaron por inventario, conteo, analyze y barridos `rg`. Archivos leidos parcialmente:

- `analysis_options.yaml`
- `lib/main.dart`
- `lib/core/utils/app_logger.dart`
- `lib/core/utils/error_handler.dart`
- `lib/features/main_shell/providers/clients_provider.dart`
- `lib/features/main_shell/widgets/inactive_clients_screen.dart`
- `lib/features/training_feature/tabs/training_interview_tab.dart`
- `lib/features/training_feature/providers/client_preferences_effect_provider.dart`
- `lib/domain/services/record_deletion_service.dart`
- `lib/data/datasources/remote/record_firestore_datasource.dart`
- `lib/data/repositories/clinical_records_repository.dart`
- `lib/data/repositories/appointment_firestore_datasource.dart`
- `lib/data/repositories/transaction_firestore_datasource.dart`
- `lib/features/dashboard_feature/providers/appointments_provider.dart`
- `lib/features/dashboard_feature/providers/transactions_provider.dart`

## 15. Archivos modificados por esta auditoria

Solo reportes y artefactos de entrega:

- `lib/audit/AUDIT_GLOBAL_DART_PRODUCTION_READINESS_REPORT.md`
- `lib/audit/AUDIT_GLOBAL_DART_PRODUCTION_READINESS_EXECUTIVE_SUMMARY.md`
- `lib.zip`
- `test.zip`

No se modifico codigo Dart productivo.

## 16. Veredicto final

```text
VEREDICTO: AVANZAR FEATURES DESPUES DE CERRAR BLOQUEADORES P0/P1
```

La app puede seguir con features de bajo riesgo si no abren nuevas rutas de persistencia ni escriben `Client` por snapshots amplios. Para produccion real faltan al menos 4 sprints de estabilizacion: deletes durables, seguridad Firebase/App Check, observabilidad y contrato agenda/pagos.
