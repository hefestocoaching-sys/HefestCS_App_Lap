# AUDIT GENERAL POST P2 LIB TEST REPORT

## 1. Resumen ejecutivo

El estado actual de `lib/` y `test/` es mejor que al inicio de los sprints P2, pero todavía no lo consideraría cerrado para auditoría operativa completa. Lo que sí quedó validado en el árbol actual es esto:

- `P1-FIRESTORE-CONTRACTS` cerró el problema de parsing tolerante en Firestore para transacciones y records.
- `P2-SYNC-OBSERVABILITY` cerró la observabilidad estructurada de `SyncService` sin cambiar la semántica de sync.
- `P2-CLIENTS-PROVIDER-LEGACY` cerró la ruta legacy de merge amplio en `ClientsNotifier`.
- `P2-TRAINING-PROVIDER-LEGACY` cerró el bloque muerto y legacy de `TrainingPlanNotifier`.

Lo que sigue abierto no es un bug corregido todavía, sino deuda técnica y cobertura de validación:

- tests manuales de Firestore siguen fuera de CI y requieren sesión real;
- siguen existiendo imports `flutter_riverpod/legacy.dart` en providers de bajo nivel;
- persiste el wrapper legacy de `ExerciseCatalogLoader`;
- hay providers grandes con `debugPrint` y responsabilidades mezcladas fuera de los bloques que ya se limpiaron;
- no se validó navegación runtime completa ni Firebase Console.

Recomendación técnica: el siguiente sprint debería ser `P2-TESTS-FIREBASE-CI`, porque el mayor hueco real ahora es que las correcciones de contratos Firestore siguen protegidas por tests contractuales y manuales, pero no por un flujo CI reproducible.

## 2. Metodología

Archivos leídos para consolidar el estado actual:

- [lib/audit/AUDIT_FULL_REPO_PROFESSIONAL_CODE_QUALITY_SECURITY_REPORT.md](lib/audit/AUDIT_FULL_REPO_PROFESSIONAL_CODE_QUALITY_SECURITY_REPORT.md)
- [lib/audit/AUDIT_FULL_REPO_PROFESSIONAL_CODE_QUALITY_SECURITY_REPORT_V2.md](lib/audit/AUDIT_FULL_REPO_PROFESSIONAL_CODE_QUALITY_SECURITY_REPORT_V2.md)
- [lib/audit/AUDIT_P1_FIRESTORE_CONTRACTS_REPORT.md](lib/audit/AUDIT_P1_FIRESTORE_CONTRACTS_REPORT.md)
- [lib/audit/AUDIT_P2_SYNC_OBSERVABILITY_REPORT.md](lib/audit/AUDIT_P2_SYNC_OBSERVABILITY_REPORT.md)
- [lib/audit/AUDIT_P2_CLIENTS_PROVIDER_LEGACY_REPORT.md](lib/audit/AUDIT_P2_CLIENTS_PROVIDER_LEGACY_REPORT.md)
- [lib/audit/AUDIT_P2_TRAINING_PROVIDER_LEGACY_REPORT.md](lib/audit/AUDIT_P2_TRAINING_PROVIDER_LEGACY_REPORT.md)
- [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart)
- [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart)
- [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart)
- [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart)
- [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart)
- [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart)
- [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart)
- [lib/data/datasources/local/sync_queue_helper.dart](lib/data/datasources/local/sync_queue_helper.dart)
- [lib/data/repositories/client_repository.dart](lib/data/repositories/client_repository.dart)
- [lib/data/datasources/remote/client_firestore_datasource.dart](lib/data/datasources/remote/client_firestore_datasource.dart)
- [lib/features/training_feature/providers/training_engine_v3_provider.dart](lib/features/training_feature/providers/training_engine_v3_provider.dart)
- [test/data/repositories/transaction_repository_contract_test.dart](test/data/repositories/transaction_repository_contract_test.dart)
- [test/data/datasources/remote/record_firestore_datasource_contract_test.dart](test/data/datasources/remote/record_firestore_datasource_contract_test.dart)
- [test/core/services/sync_service_observability_test.dart](test/core/services/sync_service_observability_test.dart)
- [test/features/main_shell/providers/clients_provider_legacy_contract_test.dart](test/features/main_shell/providers/clients_provider_legacy_contract_test.dart)
- [test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart](test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart)
- [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart)
- [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart)
- [test/manual/training_v3_case_audit_runner_test.dart](test/manual/training_v3_case_audit_runner_test.dart)
- [test/integration/critical_flows_test.dart](test/integration/critical_flows_test.dart)

Búsquedas realizadas en `lib/` y `test/` para el reporte actual:

- `readFiniteAmount`
- `asStringDynamicMap`
- `readPayload`
- `readUpdatedAt`
- `readSchemaVersion`
- `readDeleted`
- `SyncQueueObservabilityContext`
- `buildItemFailureContext`
- `buildGlobalFailureContext`
- `buildUnsupportedDomainContext`
- `useLegacyClientUpdate`
- `_updateActiveClientLegacy`
- `generateTrainingPlan`
- `generatePlanFromActiveCycle`
- `No se pudo materializar TrainingPlan legacy`
- `[TrainingPlanProvider] Generating plan for client`
- `doc.data()['amount'] as num`
- `d.data() as Map<String, dynamic>`
- `data['updatedAt'] as Timestamp?`
- `Map<String, dynamic>.from(data['payload'] ?? {})`
- `data['schemaVersion'] as int?`
- `debugPrint(`
- `@Deprecated`
- `throw StateError`
- `flutter_riverpod/legacy.dart`
- `TODO|FIXME|HACK`

Comandos ejecutados en esta auditoría:

- `git status`
- `git ls-files`

Comandos no ejecutados en esta auditoría:

- `flutter analyze --no-pub`
- cualquier `flutter test ...` específico
- cualquier suite completa

Limitaciones reales de esta auditoría:

- no se revalidó runtime de UI;
- no se ejecutó Firebase real ni emulador;
- no se inspeccionó visualmente todo `assets/`;
- no se validó Firebase Console;
- no se ejecutó la suite completa;
- la evidencia funcional adicional proviene de los reportes de sprint ya cerrados y de los canary tests presentes en el árbol.

## 3. Matriz de sprints cerrados

| Sprint | Estado reportado | Estado validado | Evidencia | Tests |
| --- | --- | --- | --- | --- |
| `P1-FIRESTORE-CONTRACTS` | Cerrado en su reporte | Cerrado en el código actual | `readFiniteAmount`, `asStringDynamicMap`, `readPayload`, `readUpdatedAt`, `readSchemaVersion`, `readDeleted` presentes en [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart#L153) y [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart#L174) | [test/data/repositories/transaction_repository_contract_test.dart](test/data/repositories/transaction_repository_contract_test.dart), [test/data/datasources/remote/record_firestore_datasource_contract_test.dart](test/data/datasources/remote/record_firestore_datasource_contract_test.dart) |
| `P2-SYNC-OBSERVABILITY` | Cerrado en su reporte | Cerrado en el código actual | `SyncQueueObservabilityContext` y helpers en [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L9) | [test/core/services/sync_service_observability_test.dart](test/core/services/sync_service_observability_test.dart) |
| `P2-CLIENTS-PROVIDER-LEGACY` | Cerrado en su reporte | Cerrado en el código actual | `updateActiveClient` ya no contiene la rama flag legacy en [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart#L238) | [test/features/main_shell/providers/clients_provider_legacy_contract_test.dart](test/features/main_shell/providers/clients_provider_legacy_contract_test.dart) |
| `P2-TRAINING-PROVIDER-LEGACY` | Cerrado en su reporte | Cerrado en el código actual | `generateTrainingPlan` quedó como stub deprecated corto en [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L516) y `generatePlanFromActiveCycle` sigue como ruta productiva en [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L673) | [test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart](test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart) |

## 4. Validación de código actual

### 4.1 TransactionRepository

El cierre de P1 está vivo en el código actual. La lectura mensual ya no usa el cast directo original y pasa por `readFiniteAmount`:

```dart
final amount = readFiniteAmount(rawAmount);
if (amount == null) {
  if (rawAmount != null) {
    developer.log(
      'Skipping invalid income amount for transaction ${doc.id}: ${rawAmount.runtimeType}',
      name: 'TransactionRepository',
    );
  }
  return total;
}
return total + amount;
```

Referencia: [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart#L153)

### 4.2 RecordFirestoreDataSource

El datasource de records ya no depende de casts duros en `fetchRecords`:

```dart
final data = asStringDynamicMap(d.data());

return RemoteRecordSnapshot(
  dateKey: d.id,
  payload: readPayload(data['payload']),
  deleted: readDeleted(data['deleted']),
  schemaVersion: readSchemaVersion(data['schemaVersion']),
  updatedAt: readUpdatedAt(data['updatedAt']),
);
```

Los helpers actuales están en el mismo archivo:

```dart
Map<String, dynamic> asStringDynamicMap(Object? value) { ... }
Map<String, dynamic> readPayload(Object? value) { ... }
DateTime readUpdatedAt(Object? value) { ... }
int readSchemaVersion(Object? value) { ... }
bool readDeleted(Object? value) => value == true;
```

Referencia: [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart#L174)

### 4.3 SyncService

El servicio de sync ya no usa `debugPrint` para errores de cola. El contexto de observabilidad está estructurado:

```dart
final context = buildItemFailureContext(
  item,
  error: e,
  stackTrace: st,
);
logger.warning(context.message, context.data);
```

Y para el error global:

```dart
final context = buildGlobalFailureContext(error: e, stackTrace: st);
logger.error(context.message, e, st);
```

También existe la ruta de dominio no soportado:

```dart
final context = buildUnsupportedDomainContext(domain);
logger.warning(context.message, context.data);
```

Referencia: [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L72)

### 4.4 ClientsProvider

La ruta productiva ya no depende del flag legacy:

```dart
Future<void> updateActiveClient(Client Function(Client) transform) async {
  return UpdateLock.instance.safeClientUpdate(() async {
    final current = state.value;
    if (current == null) return;
    final active = current.activeClient;
    if (active == null) return;
    ...
```

No hay `FeatureFlags.useLegacyClientUpdate` ni `_updateActiveClientLegacy` dentro del flujo normal.

Referencia: [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart#L238)

### 4.5 TrainingPlanProvider

El método legacy quedó como stub explícito, sin bloque muerto posterior:

```dart
@Deprecated('Usar generatePlanFromActiveCycle como entrada oficial')
Future<TrainingPlan> generateTrainingPlan({
  required String clientId,
  required TrainingEvaluation evaluation,
}) async {
  throw StateError(
    'generateTrainingPlan es legacy. Usa generatePlanFromActiveCycle.',
  );
}
```

La ruta productiva sigue separada y visible más abajo en el archivo:

```dart
Future<TrainingPlanConfig?> generatePlanFromActiveCycle(
  DateTime selectedDate,
) async {
```

El flujo real del motor sigue siendo el mismo según el runner de auditoría manual: `training_plan_provider.generatePlanFromActiveCycle -> unified service -> training_orchestrator_v3.generatePlan -> motor_v3_orchestrator.generateProgram -> cycle_template_builder -> training_plan_forensic_validator`.

Referencias: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L516), [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L673), [test/manual/training_v3_case_audit_runner_test.dart](test/manual/training_v3_case_audit_runner_test.dart#L675)

## 5. Validación de tests actuales

| Test | Qué protege | Estado | Observación |
| --- | --- | --- | --- |
| [test/data/repositories/transaction_repository_contract_test.dart](test/data/repositories/transaction_repository_contract_test.dart) | `readFiniteAmount` y totales financieros tolerantes | Verde en su sprint | Protege amounts válidos, ausentes, no finitos y mal tipados |
| [test/data/datasources/remote/record_firestore_datasource_contract_test.dart](test/data/datasources/remote/record_firestore_datasource_contract_test.dart) | `asStringDynamicMap`, `readPayload`, `readUpdatedAt`, `readSchemaVersion`, `readDeleted` | Verde en su sprint | Protege payloads inválidos y schema viejo |
| [test/core/services/sync_service_observability_test.dart](test/core/services/sync_service_observability_test.dart) | `SyncQueueObservabilityContext` y helpers | Verde en su sprint | Verifica contexto mínimo y exclusión de payload sensible |
| [test/features/main_shell/providers/clients_provider_legacy_contract_test.dart](test/features/main_shell/providers/clients_provider_legacy_contract_test.dart) | eliminación de `useLegacyClientUpdate` del flujo normal | Verde en su sprint | Canary estático + preservación granular |
| [test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart](test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart) | eliminación de dead code y separación de ruta productiva | Verde en su sprint | Canary estático + stub legacy corto |

## 6. Riesgos cerrados

- Parsing Firestore tolerante de transacciones y records: cerrado por `readFiniteAmount`, `asStringDynamicMap`, `readPayload`, `readUpdatedAt`, `readSchemaVersion`, `readDeleted`.
- Observabilidad de sync: cerrado por `SyncQueueObservabilityContext` y `AppLogger` en `SyncService`.
- Wide merge legacy en `ClientsNotifier`: cerrado porque `updateActiveClient` ya no depende de `FeatureFlags.useLegacyClientUpdate`.
- Dead code legacy en `TrainingPlanProvider`: cerrado porque `generateTrainingPlan` quedó como stub corto y `generatePlanFromActiveCycle` sigue como ruta productiva.
- Riesgo de payload sensible en logs de sync: cerrado porque el test de observabilidad valida exclusión de payload completo.

## 7. Riesgos pendientes confirmados

### R-1 — Firestore smoke tests fuera de CI

- Ruta: [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart#L17), [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart#L14)
- Evidencia: ambos tests hacen `Firebase.initializeApp(...)` y están marcados `skip` como smoke tests manuales.
- Impacto: las rutas reales contra Firestore no quedan protegidas en CI.
- Severidad: P2
- Sprint sugerido: `P2-TESTS-FIREBASE-CI`

### R-2 — Legacy cleanup inerte todavía vivo

- Ruta: [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart#L8), [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart#L7), [lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart](lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart#L1), [lib/features/training_feature/providers/muscle_progression_tracker_provider.dart](lib/features/training_feature/providers/muscle_progression_tracker_provider.dart#L4), [lib/features/training_feature/providers/weekly_feedback_provider.dart](lib/features/training_feature/providers/weekly_feedback_provider.dart#L3), [lib/features/training_feature/providers/weekly_progression_provider.dart](lib/features/training_feature/providers/weekly_progression_provider.dart#L3)
- Evidencia: `useLegacyClientUpdate` sigue definido aunque ya es inerte; `ExerciseCatalogLoader` sigue marcado `@Deprecated`; aún hay cuatro providers con `flutter_riverpod/legacy.dart`.
- Impacto: deuda técnica y mantenimiento redundante.
- Severidad: P3
- Sprint sugerido: `P3-LEGACY-CLEANUP`

### R-3 — Providers grandes restantes con logging y responsabilidades mezcladas

- Ruta: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L673), [lib/domain/training_v3/services/motor_v3_orchestrator.dart](lib/domain/training_v3/services/motor_v3_orchestrator.dart#L162), [lib/domain/training_v3/services/cycle_template_builder.dart](lib/domain/training_v3/services/cycle_template_builder.dart#L113)
- Evidencia: el flujo de entrenamiento sigue concentrando bootstrap, persistencia, validaciones y mucho `debugPrint`.
- Impacto: coste alto para cambios futuros y riesgo de regresión por acoplamiento.
- Severidad: P2
- Sprint sugerido: `P2-PROVIDER-STRUCTURE`

### R-4 — UI runtime no validado

- Ruta: [lib/features/training_feature/screens/training_workspace_screen.dart](lib/features/training_feature/screens/training_workspace_screen.dart), [lib/features/training_feature/screens/training_dashboard_screen.dart](lib/features/training_feature/screens/training_dashboard_screen.dart)
- Evidencia: no hubo navegación runtime completa ni verificación de overflow/layout en esta auditoría.
- Impacto: bugs visuales o de navegación pueden seguir ocultos.
- Severidad: P2
- Sprint sugerido: `P2-UI-RUNTIME-AUDIT`

### R-5 — Assets y catálogos grandes no inspeccionados visualmente

- Ruta: [assets/data/training_v3/catalog/](assets/data/training_v3/catalog/), [assets/data/exercises/](assets/data/exercises/), [assets/media/exercises/gifs/](assets/media/exercises/gifs/)
- Evidencia: se revisó por muestreo, no asset por asset.
- Impacto: rutas rotas o assets desalineados pueden pasar inadvertidos.
- Severidad: P2
- Sprint sugerido: `P2-ASSETS-CATALOG-AUDIT`

### R-6 — Firebase Console / App Check readiness no validado

- Ruta: [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart), [firebase.json](firebase.json), [firestore.rules](firestore.rules)
- Evidencia: no se validó Firebase Console ni enforcement real de App Check en esta auditoría.
- Impacto: el estado de producción real puede diferir del contrato local.
- Severidad: P2
- Sprint sugerido: `P2-FIREBASE-CONSOLE-READINESS`

## 8. Riesgos no confirmados

| Riesgo | Por qué no se confirmó | Qué falta |
| --- | --- | --- |
| Overflow/layout en pantallas grandes | no hubo navegación runtime completa | abrir pantallas clave y revisar en desktop/móvil |
| Integración Firestore reproducible en CI | los smoke tests siguen siendo manuales | harness emulador o fixtures CI-friendly |
| Estado real de App Check en Console | no se consultó consola | validación manual o reporte exportado |
| Inspección visual total de assets | solo hubo muestreo | recorrido por catálogo y verificación de rutas |
| Impacto runtime de `flutter_riverpod/legacy.dart` en providers restantes | se confirmó la existencia de imports, no el coste runtime | migración o justificación de cada provider |

## 9. Deuda técnica restante

### Firebase/tests

- Smoke tests de Firestore manuales fuera de CI.
- Falta una cobertura CI-friendly que repita el flujo de lectura/escritura remota sin sesión manual.
- Falta una validación automatizada de readiness de consola/App Check.

### Providers

- `training_plan_provider.dart` sigue siendo grande aunque ya no arrastra el bloque legacy muerto.
- Hay más providers con `flutter_riverpod/legacy.dart` en entrenamiento y nutrición.
- Persisten `debugPrint` abundantes fuera de los bloques ya corregidos.

### Legacy

- `FeatureFlags.useLegacyClientUpdate` sigue definido, aunque ya no gobierna el flujo productivo.
- `ExerciseCatalogLoader` sigue como wrapper deprecated.
- Hay imports legacy de Riverpod en varios providers.

### UI runtime

- No se validó navegación, scroll, overflow ni render de pantallas grandes.
- El árbol de UI puede seguir escondiendo problemas no cubiertos por tests unitarios.

### Assets

- Catálogos JSON grandes y assets binarios no fueron auditados visualmente uno a uno.
- No hay validación runtime completa de todos los paths de imagen/gif.

### Configuración

- `firebase.json`, `firestore.rules` y `firestore.indexes.json` no fueron contrastados con Firebase Console en esta auditoría.
- `analysis_options.yaml` sigue siendo la barrera principal de lint; no cubre todo el legado estructural.

### Logs

- El logging de Motor V3 sigue muy verboso.
- `training_plan_provider.dart` todavía contiene mucho `debugPrint`, aunque no en el bloque legacy eliminado.
- Hay logs de diagnóstico en varios services/repositorios.

### Arquitectura

- Los providers de entrenamiento siguen concentrando demasiadas responsabilidades.
- La separación entre orquestación, persistencia y recuperación todavía puede mejorar.

## 10. Estado de `lib/`

| Área | Estado | Riesgo actual |
| --- | --- | --- |
| bootstrap/Firebase | estable | bajo; falta validar console readiness |
| data/repositories | mejorado | medio; transacciones y otros repos ya tienen contratos fuertes, pero hay deuda alrededor |
| remote datasources | mejorado | medio; `record_firestore_datasource` está endurecido, `client_firestore_datasource` sigue verboso |
| local datasources | estable | bajo/medio; `sync_queue_helper` sigue simple y correcto |
| sync | cerrado en observabilidad | bajo; falta posible telemetría/contador de retries |
| main shell | cerrado en legacy wide merge | bajo; quedan otros providers legacy ajenos al sprint |
| training | mejorado pero grande | medio/alto; Motor V3 y providers siguen concentrando lógica |
| nutrition | estable con legacy puntual | medio; existen providers legacy y wrappers heredados |
| anthropometry | estable | medio; faltó runtime/manual completo |
| biochemistry | estable | medio; falta validación runtime completa |
| finance | parcialmente mejorado | medio; `TransactionRepository` está endurecido, pero el área sigue sensible |
| UI | no validada runtime completa | medio/alto; no se auditó navegación/overflow completo |

## 11. Estado de `test/`

| Tipo de test | Estado | Riesgo |
| --- | --- | --- |
| contract | fuerte en Firestore, sync y providers | bajo/medio |
| canary | presente para legacy cleanup | bajo |
| unit | abundante | bajo/medio |
| integration | presente | medio; falta expandir CI en Firestore real |
| manual | presente y útil | alto si se usa como única red de seguridad |
| smoke | presente pero manual | alto por no estar en CI |
| regression | presente en Motor V3 | medio |
| verification | presente en Motor V3 y contratos | medio |

## 12. Análisis del siguiente sprint

| Sprint candidato | Beneficio | Riesgo de tocarlo ahora | Prioridad |
| --- | --- | --- | --- |
| `P2-TESTS-FIREBASE-CI` | Muy alto: convierte los smoke tests manuales en cobertura reproducible y protege los contratos Firestore recién cerrados | Bajo/medio: afecta tests/harness, no negocio | 1 |
| `P3-LEGACY-CLEANUP` | Medio: limpia wrappers e imports legacy inertes | Bajo: pero su impacto es menor que cerrar CI de Firestore | 2 |
| `P2-PROVIDER-STRUCTURE` | Alto: baja deuda de providers grandes y logging | Medio/alto: puede abrir refactor amplio | 3 |
| `P2-UI-RUNTIME-AUDIT` | Medio: detecta regressions visuales/runtime | Medio: requiere ejecución interactiva | 4 |
| `P2-ASSETS-CATALOG-AUDIT` | Medio: valida catálogos y assets | Medio: volumen alto, mucho trabajo de muestreo | 5 |
| `P2-FIREBASE-CONSOLE-READINESS` | Alto si hay gap real con consola/App Check | Alto: depende de acceso/estado externo | 6 |

## 13. Recomendación técnica

Siguiente sprint recomendado: `P2-TESTS-FIREBASE-CI`.

Por qué ese:

- El mayor hueco confirmado hoy es que Firestore sigue protegido por canary tests y smoke tests manuales, no por un flujo CI reproducible.
- Las correcciones de `P1-FIRESTORE-CONTRACTS` ya existen y necesitan una red de seguridad automatizada para no degradarse.
- También protege indirectamente los cuatro sprints P2 cerrados porque el punto común de riesgo es la validación de datos y la regresión de contratos.

Por qué no los otros primero:

- `P3-LEGACY-CLEANUP` es real, pero su impacto es menor y no protege el cambio funcional más sensible que sigue sin CI.
- `P2-PROVIDER-STRUCTURE` puede abrir una refactorización amplia y costosa; conviene hacerlo después de robustecer la batería de tests que lo sostenga.
- `P2-UI-RUNTIME-AUDIT` y `P2-ASSETS-CATALOG-AUDIT` son valiosos, pero no cierran la brecha más importante de confianza funcional.
- `P2-FIREBASE-CONSOLE-READINESS` depende de validación externa y no reduce tanto la incertidumbre interna del árbol como un sprint de tests CI.

Qué tocaría ese sprint:

- [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart)
- [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart)
- [test/integration/critical_flows_test.dart](test/integration/critical_flows_test.dart)
- un harness CI-friendly nuevo o adaptado para Firestore/emulator
- posiblemente un canary de configuración bajo `test/security/` o `test/integration/`

Qué no debe tocar ese sprint:

- UI;
- Motor V3;
- reglas científicas;
- reglas Firestore;
- bootstrap Firebase;
- contratos de payload ya cerrados;
- providers que no formen parte del harness de integración.

## 14. Limitaciones restantes

- no se hizo navegación runtime;
- no se validó Firebase Console;
- no se ejecutó suite completa;
- no se inspeccionaron visualmente todos los assets;
- no se hizo build nativo real;
- no se reejecutaron los tests específicos de sprint en esta auditoría general; la validación funcional está en los reportes de sprint ya cerrados.

## 15. Veredicto final

AUDIT-GENERAL-POST-P2: LISTO PARA SIGUIENTE SPRINT
