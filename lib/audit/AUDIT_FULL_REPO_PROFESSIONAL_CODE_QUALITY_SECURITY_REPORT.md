# AUDIT FULL REPO PROFESSIONAL CODE QUALITY & SECURITY REPORT

## 1. Resumen ejecutivo

El repositorio tiene una base funcional y el análisis estatico actual pasa limpio, pero no lo considero listo para produccion sin plan de correccion. El riesgo mas alto hoy no es compilacion, sino robustez de persistencia y contratos de datos: hay rutas Firestore que asumen payloads bien formados, calculos financieros que cascan con datos mal tipados, y providers grandes que mezclan orquestacion, persistencia y logs abundantes.

Hallazgos confirmados por severidad:
- P0: 0
- P1: 2
- P2: 4
- P3: 2

Modulos mas riesgosos:
- Persistencia remota Firestore en [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart#L121) y [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart#L134).
- State management / entrenamiento en [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520) y [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart#L240).
- Sync local/remoto en [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L37).

Veredicto: el repo no esta bloqueado por compilacion, pero si por deuda tecnica y riesgos de datos que ameritan sprint de hardening antes de considerar el sistema estable para produccion completa.

## 2. Metodología

Archivos revisados de forma directa:
- [lib/main.dart](lib/main.dart)
- [lib/app.dart](lib/app.dart)
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart)
- [lib/firebase_options.dart](lib/firebase_options.dart)
- [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart)
- [lib/data/datasources/local/database_helper.dart](lib/data/datasources/local/database_helper.dart)
- [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart)
- [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart)
- [lib/data/datasources/remote/client_firestore_datasource.dart](lib/data/datasources/remote/client_firestore_datasource.dart)
- [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart)
- [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart)
- [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart)
- [lib/utils/firestore_sanitizer.dart](lib/utils/firestore_sanitizer.dart)
- [firestore.rules](firestore.rules)
- [firestore.indexes.json](firestore.indexes.json)
- [firebase.json](firebase.json)
- [pubspec.yaml](pubspec.yaml)
- [pubspec.lock](pubspec.lock)
- [analysis_options.yaml](analysis_options.yaml)
- [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart)
- [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart)
- [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart)
- [test/manual/training_v3_case_audit_runner_test.dart](test/manual/training_v3_case_audit_runner_test.dart)
- [test/integration/critical_flows_test.dart](test/integration/critical_flows_test.dart)

Busquedas usadas:
- `git status`
- `flutter analyze --no-pub`
- Búsquedas focalizadas sobre `TODO|FIXME|HACK|deprecated|debugPrint|developer.log`
- Búsquedas focalizadas sobre `dynamic|Map<String, dynamic>|as |!`
- Búsquedas focalizadas sobre `Firebase.initializeApp|FirebaseAppCheck|debugToken|localhost|useFirestoreEmulator|useAuthEmulator|useStorageEmulator`
- Búsquedas sobre `withOpacity|WillPopScope|RaisedButton|FlatButton|OutlineButton|MaterialStateProperty|RadioListTile.*groupValue|DropdownButton.*value`
- Búsquedas de consumo de símbolos legacy y manual smoke tests

Limitaciones:
- El terminal de PowerShell no tenia `rg` disponible, asi que use el buscador del editor y `grep_search` para las consultas.
- No hice lectura lineal de cada archivo del repo; la auditoria es por muestreo dirigido en hotspots y por cobertura de areas criticas.
- No hubo comandos colgados en esta corrida.

## 3. Matriz de cobertura

| Área | Archivos revisados | Estado | Riesgo principal |
| --- | --- | --- | --- |
| Bootstrap / app start | [lib/main.dart](lib/main.dart), [lib/app.dart](lib/app.dart), [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart), [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart) | Revisado | Bootstrap correcto pero con política explícita por plataforma y skip desktop en App Check |
| Seguridad Firebase | [lib/firebase_options.dart](lib/firebase_options.dart), [firestore.rules](firestore.rules), [firestore.indexes.json](firestore.indexes.json), [firebase.json](firebase.json), [lib/data/datasources/remote/client_firestore_datasource.dart](lib/data/datasources/remote/client_firestore_datasource.dart), [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart) | Revisado | Parseos Firestore frágiles y smoke tests manuales fuera de CI |
| Persistencia local | [lib/data/datasources/local/database_helper.dart](lib/data/datasources/local/database_helper.dart), [lib/data/datasources/local/sync_queue_helper.dart](lib/data/datasources/local/sync_queue_helper.dart), [lib/data/datasources/local/local_client_datasource_impl.dart](lib/data/datasources/local/local_client_datasource_impl.dart) | Revisado | Schema/outbox bien encaminados, pero la integración depende de rutas legacy y retries silenciosos |
| Repositorios / datasources | [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart), [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart), [lib/data/datasources/remote/client_firestore_datasource.dart](lib/data/datasources/remote/client_firestore_datasource.dart) | Revisado | Casts directos y contratos de payload poco tolerantes |
| Providers / state management | [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart), [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), [lib/features/training_feature/providers/weekly_progression_provider.dart](lib/features/training_feature/providers/weekly_progression_provider.dart), [lib/features/training_feature/providers/muscle_progression_tracker_provider.dart](lib/features/training_feature/providers/muscle_progression_tracker_provider.dart) | Revisado | Providers grandes, legacy y con mucho side effect/logging |
| UI Flutter | [lib/app.dart](lib/app.dart), [lib/features/training_feature/screens/training_workspace_screen.dart](lib/features/training_feature/screens/training_workspace_screen.dart), [lib/features/training_feature/screens/training_dashboard_screen.dart](lib/features/training_feature/screens/training_dashboard_screen.dart) | Muestreo | No confirmé overflow/ancho roto, pero el estado de UI depende de providers pesados |
| APIs deprecadas / legacy | [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart), [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart) | Revisado | Legacy vivo, código muerto y rutas de compatibilidad que duplican mantenimiento |
| Arquitectura | [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart), [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart) | Revisado | Responsabilidades mezcladas y bootstrap/persistencia acoplados a demasiadas decisiones |
| Tests | [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart), [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart), [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart), [test/integration/critical_flows_test.dart](test/integration/critical_flows_test.dart) | Revisado | Smoke tests manuales fuera de CI y cobertura crítica no automatizada |
| Dependencias / config | [pubspec.yaml](pubspec.yaml), [pubspec.lock](pubspec.lock), [analysis_options.yaml](analysis_options.yaml), [firebase.json](firebase.json) | Revisado | Configuración razonable, sin lint suficiente para cast/legacy sprawl |
| Assets | [assets/data/training_v3/catalog/](assets/data/training_v3/catalog/), [assets/data/exercises/](assets/data/exercises/), [assets/media/exercises/gifs/](assets/media/exercises/gifs/) | Revisado por muestreo | No confirmé rutas rotas en la muestra revisada |

## 4. Hallazgos P0

No hay hallazgos P0 confirmados en esta revisión.

## 5. Hallazgos P1

### P1-01 — Totales mensuales pueden romperse con un payload Firestore mal tipado

- Ruta: [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart#L134)
- Clase/función: `TransactionRepository.calculateMonthlyIncome` / `TransactionRepository.calculateMonthlyExpenses`
- Snippet actual:

```dart
return snapshot.docs.fold<double>(
  0.0,
  (total, doc) => total + (doc.data()['amount'] as num).toDouble(),
);
```

- Evidencia: el código asume que `amount` existe y es `num`. No hay guardas ni fallback si un documento remoto llega con `String`, `null` o un schema viejo.
- Impacto: una transacción mal formada puede romper el cálculo de ingresos/gastos del mes y tumbar vistas financieras completas.
- Por qué ocurre: el repositorio consume Firestore como si la colección estuviera perfectamente normalizada.
- Corrección recomendada: validar `doc.data()['amount']` antes del cast, usar un decoder tolerante y registrar el documento corrupto sin tumbar el stream o el cálculo.
- Archivos que tocaría: [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart), tests de repositorio de transacciones.
- Test recomendado: caso con `amount` ausente, `null` y `String` en un snapshot simulado.
- Estado: requiere sprint.

### P1-02 — Lectura de records remotos lanza por casts inseguros en Firestore

- Ruta: [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart#L174)
- Clase/función: `RecordFirestoreDataSource.fetchRecords`
- Snippet actual:

```dart
final data = d.data() as Map<String, dynamic>;
final ts = data['updatedAt'] as Timestamp?;

return RemoteRecordSnapshot(
  dateKey: d.id,
  payload: Map<String, dynamic>.from(data['payload'] ?? {}),
  deleted: data['deleted'] == true,
  schemaVersion: data['schemaVersion'] as int? ?? 1,
  updatedAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
);
```

- Evidencia: `d.data()` y `payload` se convierten por cast directo sin validación de forma ni tipo.
- Impacto: un documento remoto parcialmente migrado o corrupto puede abortar la lectura de todos los records del dominio y romper sync/visualización clínica.
- Por qué ocurre: el datasource confía en que Firestore siempre devuelve una estructura perfecta.
- Corrección recomendada: validar el tipo del snapshot, tolerar `payload` ausente o mal tipado y devolver error controlado o snapshot descartado con telemetría.
- Archivos que tocaría: [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart), tests de datasource payload contract.
- Test recomendado: snapshot con `payload` string, `schemaVersion` string y `updatedAt` ausente.
- Estado: requiere sprint.

## 6. Hallazgos P2

### P2-01 — SyncService traga errores y degrada observabilidad de la cola

- Ruta: [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L37)
- Clase/función: `SyncService._processPendingQueue` / `SyncService._syncItem`
- Snippet actual:

```dart
        } catch (e) {
          debugPrint('Sync failed for ${item['id']}: $e');
          await SyncQueueHelper.markFailure(item['id'] as String, e.toString());
        }
      }

      await backgroundSyncService.trySyncPendingData();
    } catch (e) {
      debugPrint('Error processing sync queue: $e');
    } finally {
      _isProcessing = false;
    }
```

- Evidencia: los fallos se reducen a `debugPrint` y a un cambio de estado local; no hay telemetría estructurada ni señal fuerte para errores repetidos.
- Impacto: una cola con fallos recurrentes puede quedar como deuda silenciosa; el usuario ve la app seguir funcionando mientras datos quedan sin sincronizar.
- Por qué ocurre: la cola prioriza continuidad sobre detección de fallos sistémicos.
- Corrección recomendada: elevar fallo recurrente a logger estructurado, contador de reintentos o evento de reporting; distinguir error de item de error del proceso global.
- Archivos que tocaría: [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart), [lib/data/datasources/local/sync_queue_helper.dart](lib/data/datasources/local/sync_queue_helper.dart).
- Test recomendado: cola con fallo repetido en un item y verificación de que el servicio deja trazabilidad no solo debug.
- Estado: puede corregirse seguro.

### P2-02 — TrainingPlanProvider mezcla orquestación, persistencia, compatibilidad legacy y logging masivo

- Ruta: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520)
- Clase/función: `TrainingPlanNotifier.generateTrainingPlan` y `TrainingPlanNotifier.generatePlanFromActiveCycle`
- Snippet actual:

```dart
    throw StateError(
      'No se pudo materializar TrainingPlan legacy. Usa generatePlanFromActiveCycle.',
    );

    try {
      debugPrint(
        '[TrainingPlanProvider] Generating plan for client: $clientId',
      );
```

- Evidencia: hay código inalcanzable después del `throw`, múltiples métodos `@Deprecated`, y un volumen alto de `debugPrint` repartido por toda la clase.
- Impacto: el provider es difícil de mantener, duplicará comportamiento con facilidad y hace muy costoso razonar sobre qué ruta es realmente productiva.
- Por qué ocurre: la lógica de generación, persistencia, bootstrap del ciclo y compatibilidad legacy quedaron en un único archivo enorme.
- Corrección recomendada: separar el adaptador legacy del flujo productivo, eliminar el bloque muerto y reducir el provider a orquestación fina.
- Archivos que tocaría: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), potencialmente un helper legacy separado.
- Test recomendado: garantizar que la ruta productiva no pasa por el código legacy y que el método deprecated no tiene consumidores nuevos.
- Estado: requiere sprint.

### P2-03 — ClientsNotifier conserva una ruta legacy de merge amplio detrás de feature flag

- Ruta: [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart#L240)
- Clase/función: `ClientsNotifier.updateActiveClient` / `_updateActiveClientLegacy`
- Snippet actual:

```dart
  Future<void> updateActiveClient(Client Function(Client) transform) async {
    if (FeatureFlags.useLegacyClientUpdate) {
      return _updateActiveClientLegacy(transform);
    }
```

- Evidencia: la rama legacy sigue viva y el propio archivo mantiene un método `_updateActiveClientLegacy` que vuelve a mezclar secciones completas.
- Impacto: si la bandera se reactiva o un caller antiguo vuelve a depender de esa ruta, reaparece el riesgo de snapshots viejos y sobrescritura amplia de estado.
- Por qué ocurre: la compatibilidad temporal quedó embebida dentro del notifier principal.
- Corrección recomendada: mover la compatibilidad a un adaptador aislado o eliminarla cuando ya no existan callers legítimos.
- Archivos que tocaría: [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart), [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart).
- Test recomendado: asegurar que el flujo productivo usa solo `updateActiveClient` granular y que no hay regresión por snapshots antiguos.
- Estado: requiere sprint.

### P2-04 — Las pruebas manuales de Firestore quedan fuera de CI y requieren sesión real

- Ruta: [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart#L1), [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart#L1)
- Clase/función: tests manuales skippeados que inicializan Firebase real
- Snippet actual:

```dart
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
...
    skip:
        'Manual smoke test. Requires an authenticated coach session before run.',
```

- Evidencia: son tests reales contra Firebase, pero están `skip` y exigen sesión autenticada en la app de escritorio.
- Impacto: las rutas críticas de lectura/escritura Firestore no forman parte del pipeline automático; el riesgo de regresión de integración queda fuera de CI.
- Por qué ocurre: están pensados como smoke tests manuales, no como cobertura repetible.
- Corrección recomendada: mantenerlos como manuales, pero agregar cobertura automatizada equivalente con emulator o fixtures desacoplados.
- Archivos que tocaría: `test/manual/*` y algún harness de integración/emulador.
- Test recomendado: una versión CI-friendly que valide upsert/fetch/delete sin depender de sesión manual.
- Estado: requiere sprint.

## 7. Hallazgos P3

### P3-01 — Wrapper legacy de catálogo de ejercicios sin consumidores visibles

- Ruta: [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart#L7)
- Clase/función: `ExerciseCatalogLoader.load`
- Snippet actual:

```dart
class ExerciseCatalogLoader {
  @Deprecated(
    'Legacy wrapper kept for compatibility; runtime SSOT is ExerciseCatalogV3.',
  )
  static List<Exercise>? _cache;
...
  static Future<List<Exercise>> load() async {
    final jsonStr = await rootBundle.loadString(
      'assets/data/training_v3/catalog/exercise_catalog_v3_runtime.json';
```

- Evidencia: la clase está marcada como wrapper legacy y no encontré consumidores directos en búsquedas textuales del árbol revisado.
- Impacto: añade ambigüedad sobre cuál loader es la fuente verdadera y aumenta superficie de mantenimiento.
- Corrección recomendada: retirar o aislar la compatibilidad cuando se confirme que no hay consumidores.
- Archivos que tocaría: [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart).
- Test recomendado: búsqueda de consumidores y eliminación controlada en un cleanup sprint.
- Estado: puede corregirse seguro.

### P3-02 — Logging de producción excesivo en providers y sync

- Ruta: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L557), [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L64)
- Clase/función: múltiples `debugPrint` en provider de entrenamiento y sync service
- Snippet actual:

```dart
debugPrint('[TrainingPlanProvider] Generating plan for client: $clientId');
debugPrint('🎯 [Motor V3] Generando plan desde ciclo activo...');
debugPrint('Sync failed for ${item['id']}: $e');
```

- Evidencia: la traza de depuración es muy abundante y llega a rutas de producción.
- Impacto: ruido de logs, mayor dificultad para observabilidad útil y posible exposición de contexto sensible en trazas.
- Corrección recomendada: degradar a logger estructurado con nivel y contexto, y limitar `debugPrint` a debug o canary.
- Archivos que tocaría: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart), [lib/core/utils/app_logger.dart](lib/core/utils/app_logger.dart).
- Test recomendado: revisar que las rutas productivas no usan `debugPrint` para errores esperables.
- Estado: puede corregirse seguro.

## 8. Seguridad

### Firebase

La inicialización ahora está centralizada en [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L8) y [lib/firebase_options.dart](lib/firebase_options.dart#L5). No confirmé un `Firebase.initializeApp` duplicado. La política por plataforma está explícita.

### Auth

Los smoke tests manuales usan `FirebaseAuth.instance.currentUser` y exigen sesión autenticada; eso es operacionalmente correcto, pero deja la cobertura automatizada fuera de CI.

### Firestore

[firestore.rules](firestore.rules#L1) tiene una política coherente con coach/owner y subcolecciones clínicas. El riesgo real no está en las reglas visibles sino en los contracts de lectura/escritura: `TransactionRepository` y `RecordFirestoreDataSource` asumen payloads sanos.

### Storage

No encontré archivo de reglas de Storage en el workspace revisado. No reporto un bug de Storage; solo marco ausencia de evidencia de configuración específica.

### App Check

La política App Check está separada por plataforma. No encontré `debugToken` hardcodeado ni emuladores runtime en `lib/`. El riesgo aquí está controlado comparado con la corrida P1A previa.

### Logs sensibles

Hay muchas rutas con `debugPrint` y `developer.log`, especialmente en entrenamiento y sync. No lo trato como fuga confirmada, pero sí como riesgo de ruido y posible exposición de datos operativos.

### Secretos

No confirmé credenciales hardcodeadas nuevas en el muestreo de este turno. El archivo [lib/firebase_options.dart](lib/firebase_options.dart#L5) contiene opciones cliente; eso no es un secreto por sí mismo.

### Reglas

[firestore.rules](firestore.rules#L1) es la única política Firebase encontrada en el workspace. No hay reglas Storage visibles.

### Emuladores

No encontré llamadas runtime a `useFirestoreEmulator`, `useAuthEmulator` o `useStorageEmulator` en `lib/`.

### Datos clínicos / personales

La estructura Firestore y los repositorios clínicos asumen payloads bien formados. Eso hace que los fallos de contrato sean más peligrosos que un simple warning: pueden romper lectura o sync de datos sensibles.

## 9. APIs deprecadas y Flutter/Dart moderno

| API/patrón | Ruta | Evidencia | Reemplazo recomendado | Severidad |
| --- | --- | --- | --- | --- |
| `@Deprecated` wrapper legacy | [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart#L7) | Wrapper explícitamente legacy | Eliminar cuando no haya consumidores | P3 |
| Método legacy de plan | [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520) | `generateTrainingPlan` está deprecado y deja bloque legacy muerto | Mantener solo `generatePlanFromActiveCycle` | P2 |
| Legacy Riverpod imports | [lib/features/training_feature/providers/weekly_progression_provider.dart](lib/features/training_feature/providers/weekly_progression_provider.dart#L1), [lib/features/training_feature/providers/muscle_progression_tracker_provider.dart](lib/features/training_feature/providers/muscle_progression_tracker_provider.dart#L1), [lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart](lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart#L1) | `flutter_riverpod/legacy.dart` sigue en uso | Consolidar cuando se toque el flujo | P3 |
| `debugPrint` amplio en producción | [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L557) | Muchísimas trazas en provider productivo | Logger estructurado y guardas por nivel | P3 |

## 10. Código muerto/no usado

| Símbolo/archivo | Ruta | Evidencia | Acción sugerida |
| --- | --- | --- | --- |
| `ExerciseCatalogLoader.load` | [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart#L55) | Wrapper deprecated; no vi consumidores directos en búsquedas de texto | Retirar en cleanup sprint |
| `TrainingPlanNotifier.generateTrainingPlan` tail legacy | [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520) | Código inalcanzable tras `throw StateError` | Eliminar o separar en adapter legacy |
| `test/training_v3/motor_v3_orchestrator_test.dart.bak` | `test/training_v3/motor_v3_orchestrator_test.dart.bak` | Apareció como artefacto de backup en búsquedas | Verificar si realmente debe versionarse |

## 11. Código duplicado

| Bloque duplicado | Rutas | Riesgo | Refactor recomendado |
| --- | --- | --- | --- |
| Serialización/parseo Firestore repetido | [lib/data/datasources/remote/client_firestore_datasource.dart](lib/data/datasources/remote/client_firestore_datasource.dart), [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart) | La tolerancia y sanidad de payloads vive en varias capas | Unificar un decoder/validator compartido y un contrato único |
| Estado/merge de cliente en notifiers | [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart) y rutas legacy de tabs clínicas | Aumenta divergencia entre helpers y legacy | Mantener solo helpers granulares frescos |
| Logging de debug de entrenamiento | [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart) | Repite señales y hace ruido | Centralizar trazas por fase o usar logger estructurado |

## 12. Arquitectura y diseño

La separación general UI/domain/data existe, pero hay puntos donde la frontera se difumina:
- [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520) mezcla orchestration, persistencia, recuperación de ciclos y migración legacy.
- [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart#L240) aún conserva merge amplio bajo flag.
- [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L37) coordina cola, retry y background sync con poco espacio para observabilidad.

Arquitecturalmente esto no rompe hoy, pero hace caro mantener garantías de dato fresco y de ejecución clara.

## 13. UI/UX técnica

No confirmé un bug visual crítico por overflow o layout roto en esta pasada. El riesgo técnico de UI viene más por el estado que alimentan los providers pesados que por problemas de render concretos. No marqué `withOpacity`, `WillPopScope` ni APIs material antiguas porque no aparecieron como problema real en el muestreo actual.

## 14. Persistencia y sincronización

Este es el bloque más delicado del repo:
- SQLite está bien encaminado con [lib/data/datasources/local/database_helper.dart](lib/data/datasources/local/database_helper.dart#L1) y outbox.
- La sincronización sigue teniendo rutas legacy y logging ruidoso en [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L37).
- Firestore remoto tiene dos puntos frágiles confirmados: totales de transacciones y lectura de records.

## 15. Tests

| Test | Estado | Problema | Acción |
| --- | --- | --- | --- |
| [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart#L12) | Bueno | Canary útil y estático | Mantener y ampliar si se toca Firebase |
| [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart#L1) | Manual / skip | Firebase real + sesión real, fuera de CI | Añadir cobertura automatizada equivalente |
| [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart#L1) | Manual / skip | Igual que arriba | Añadir integración reproducible |
| [test/manual/training_v3_case_audit_runner_test.dart](test/manual/training_v3_case_audit_runner_test.dart#L1) | Manual | Generador de auditorías, no test de CI normal | Documentar como herramienta manual |
| [test/integration/critical_flows_test.dart](test/integration/critical_flows_test.dart#L1) | Útil | Buen sanity check, pero no cubre Firestore remoto real | Completar con casos de contrato |

## 16. Dependencias y configuración

- [pubspec.yaml](pubspec.yaml#L1) declara Firebase, Riverpod/Provider, SQLite, `http`, `google_fonts`, `shared_preferences`, `mockito` y `fake_async`.
- [pubspec.lock](pubspec.lock#L340) fija `firebase_app_check` 0.4.1+4 y [pubspec.lock](pubspec.lock#L388) fija `firebase_core` 4.4.0.
- [analysis_options.yaml](analysis_options.yaml#L1) es razonable pero ligera: bloquea `avoid_print` y `use_build_context_synchronously`, pero no endurece casts/dynamic tan fuerte como podría.
- [firebase.json](firebase.json#L1) solo muestra Firestore rules/indexes y emuladores; no hay Storage rules ni `.github/` en el workspace revisado.

## 17. Riesgos por módulo

| Módulo | Riesgo | Severidad | Sprint sugerido |
| --- | --- | --- | --- |
| Firestore remoto | Payloads mal tipados rompen lectura y agregados | P1 | SAVE-FS-1 |
| Sync / outbox | Errores tragan observabilidad | P2 | SAVE-SYNC-1 |
| Training provider | Mezcla legacy, side effects y dead code | P2 | TRAINING-PROVIDER-1 |
| Clients provider | Legacy wide merge todavía existe | P2 | CLIENTS-PROVIDER-1 |
| Tests de integración | Cobertura manual fuera de CI | P2 | TESTS-FIREBASE-1 |
| Legacy loaders | Wrappers deprecated sin consumidores visibles | P3 | CLEANUP-1 |

## 18. Plan de sprints recomendado

| Orden | Sprint | Objetivo | Severidad | Archivos probables | Tests |
| --- | --- | --- | --- | --- | --- |
| 1 | SAVE-FS-1 | Endurecer contratos Firestore de transacciones y records | P1 | [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart), [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart) | tests de payload contract y totals |
| 2 | TESTS-FIREBASE-1 | Pasar smoke tests manuales a cobertura reproducible | P2 | [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart), [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart) | integración con emulator/fixtures |
| 3 | TRAINING-PROVIDER-1 | Separar provider de entrenamiento, remover dead code legacy | P2 | [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart) | tests de ruta productiva/deprecated |
| 4 | SAVE-SYNC-1 | Mejorar observabilidad de cola y retries | P2 | [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart) | tests de fallo/reintento |
| 5 | CLIENTS-PROVIDER-1 | Aislar o eliminar fallback wide-merge legacy | P2 | [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart), [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart) | tests de patch granular |
| 6 | CLEANUP-1 | Retirar wrappers deprecated y artefactos legacy | P3 | [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart) | búsquedas de consumidores |

## 19. Quick wins seguros

Estos cambios parecen de bajo riesgo y no cambian lógica científica ni UI:
- Reemplazar casts directos en agregados financieros por parseo tolerante.
- Añadir telemetría estructurada en lugar de `debugPrint` para fallos de sync.
- Separar el bloque legacy inalcanzable de [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520).
- Documentar formalmente los smoke tests manuales como no-CI.
- Limpiar wrappers deprecated sin consumidores.

## 20. Veredicto final

FULL-REPO-AUDIT: INCOMPLETO POR LIMITACIONES

Motivo: la auditoría sí identificó riesgos reales y priorizados con evidencia concreta, pero no hice una lectura exhaustiva línea por línea de todos los archivos del workspace. Aun así, la muestra cubre los módulos críticos y deja un plan de sprint accionable.