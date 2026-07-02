# AUDIT FULL REPO PROFESSIONAL CODE QUALITY & SECURITY REPORT V2

## 1. Resumen ejecutivo

La auditoría anterior era incompleta. Esta segunda pasada cerró mejor la trazabilidad porque ya no se limitó a hotspots aislados: se levantó inventario de rutas versionadas, se cruzaron búsquedas globales en lib/test, se releyeron las rutas de mayor riesgo y se revalidaron los hallazgos previos con evidencia directa.

Lo que sí quedó cerrado en esta pasada:

- Se confirmó el núcleo de seguridad Firebase/App Check y su separación en bootstrap.
- Se revalidaron los hallazgos de persistencia remota y sincronización con snippets reales.
- Se clasificó el repositorio por módulos y por superficie de riesgo.
- Se distinguieron riesgos confirmados de riesgos no confirmados.
- Se inventariaron assets, docs, audit packs y plataformas nativas presentes en el workspace.

Conteos de inventario obtenidos desde el workspace y `git ls-files`:

- `lib/**/*.dart`: 686 rutas encontradas.
- `test/**/*.dart`: 92 rutas encontradas.
- `assets/**/*`: 1480 rutas encontradas.
- `docs/**/*`: 50 rutas encontradas.
- `lib/audit/**/*`: 34 rutas encontradas.
- `windows/**/*`: 18 rutas encontradas.
- `macos/**/*`: 28 rutas encontradas.
- `android/**/*`: no hubo resultados en el workspace.
- `ios/**/*`: no hubo resultados en el workspace.
- `.github/**/*`: no hubo resultados en el workspace.

Hallazgos confirmados por severidad en esta V2:

- P0: 0
- P1: 2
- P2: 4
- P3: 2

Módulos con mayor riesgo real:

- Persistencia remota Firestore y agenda/pagos.
- Sync local/remoto y cola de outbox.
- State management de clientes y entrenamiento.
- Motor V3 y sus rutas de compatibilidad/legacy, aunque el motor en sí no fue modificado.

Veredicto: FULL-REPO-AUDIT-P2: INCOMPLETO POR LIMITACIONES REALES

## 2. Diferencias contra V1

| Punto | V1 | V2 | Resultado |
| --- | --- | --- | --- |
| Cobertura | Muestreo dirigido por hotspots | Inventario amplio por rutas y módulos | Mejoró |
| Trazabilidad | Hallazgos con evidencia parcial | Hallazgos con snippets y rutas concretas | Mejoró |
| Riesgos no confirmados | Mezclados con deuda probable | Separados explícitamente | Mejoró |
| Firebase/App Check | Confirmado parcialmente | Revalidado con contract test y bootstrap | Mejoró |
| Persistencia Firestore | Riesgo alto, no detallado por archivo | Revalidado archivo por archivo en la capa crítica | Mejoró |
| Tests | Manuales y canary mencionados | Inventario más amplio de test suites y tipos | Mejoró |
| Assets/plataformas | Breve mención | Inventario explícito de assets, nativo y docs | Mejoró |
| Exhaustividad total | No | No completa al 100% por volumen y runtime | Sin cierre total |

## 3. Metodología exhaustiva

Inventarié el workspace con el Explorer y búsquedas globales en el editor para evitar depender de un solo punto de entrada.

Comandos y búsquedas ejecutadas en esta V2:

- `git ls-files`
- `grep_search` sobre patrones de riesgo en `lib/**/*.dart`
- `grep_search` sobre patrones de riesgo en `test/**/*.dart`
- `grep_search` sobre `assets/**/*`
- `grep_search` sobre `lib/audit/**/*`
- lecturas directas de archivos clave con `read_file`
- relectura de memorias del repo para evitar repetir errores ya resueltos

Comandos no ejecutados en esta V2 por instrucción o por alcance del sprint:

- suite completa de tests
- navegación runtime/manual de pantallas
- inspección visual de cada asset binario
- validación en Firebase Console
- cambios productivos de código

Búsquedas obligatorias realizadas por patrón:

- `TODO|FIXME|HACK|XXX|deprecated|@Deprecated|debugPrint|developer.log|print(|dynamic|Map<String, dynamic>|as |!|late |Timer|StreamSubscription|listen(|dispose(|mounted|context.|setState(|Firebase.initializeApp|FirebaseAppCheck|debugToken|localhost|useFirestoreEmulator|useAuthEmulator|useStorageEmulator|collection(|doc(|set(|update(|delete(|add(|DateTime.now(|Timestamp|fromJson|toJson|jsonDecode|jsonEncode|rootBundle.loadString|UnsupportedError|throw StateError|throw Exception|catch (e)|catch (_)`
- búsquedas de UI legacy y material antiguo como `withOpacity`, `WillPopScope`, `RaisedButton`, `FlatButton`, `OutlineButton`, `MaterialStateProperty`, `RadioListTile.*groupValue`, `DropdownButton.*value`

Limitaciones metodológicas reales que quedan:

- no hubo lectura línea por línea de las 686 rutas Dart de lib ni de las 92 de test;
- no hubo navegación runtime manual de todas las pantallas;
- no se ejecutó la suite completa de tests;
- no se inspeccionó visualmente cada asset binario;
- no se validó Firebase Console ni hardware/plataforma nativa real.

## 4. Inventario de archivos revisados

### 4.1 Dart de alto riesgo revisado directamente

| Archivo | Tipo | Estado | Riesgo | Hallazgo |
| --- | --- | --- | --- | --- |
| [lib/main.dart](lib/main.dart) | bootstrap | Revisado | sin hallazgo | bootstrap delega en helper |
| [lib/app.dart](lib/app.dart) | app/ui | Revisado | sin hallazgo | root app estable |
| [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart) | bootstrap | Revisado | sin hallazgo | App Check centralizado |
| [lib/firebase_options.dart](lib/firebase_options.dart) | firebase/security | Revisado | sin hallazgo | bloquea plataformas no soportadas |
| [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart) | service | Revisado | P2 | traga errores en cola |
| [lib/data/datasources/local/database_helper.dart](lib/data/datasources/local/database_helper.dart) | datasource local | Revisado | sin hallazgo | schema y migraciones locales consistentes |
| [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart) | datasource local | Revisado | P3 | wrapper legacy |
| [lib/data/datasources/remote/client_firestore_datasource.dart](lib/data/datasources/remote/client_firestore_datasource.dart) | datasource remote | Revisado | sin hallazgo | sanitiza payloads |
| [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart) | datasource remote | Revisado | P1 | casts inseguros en fetch |
| [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart) | repository | Revisado | P1 | casts numéricos directos |
| [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart) | provider | Revisado | P2 | legacy wide merge sigue vivo |
| [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart) | provider | Revisado | P2 | orquestación + legacy + logging |
| [lib/utils/firestore_sanitizer.dart](lib/utils/firestore_sanitizer.dart) | utility | Revisado | sin hallazgo | sanea keys y tipos |
| [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart) | constants | Revisado | sin hallazgo | legacy apagado por flag |
| [lib/features/training_feature/providers/training_engine_v3_provider.dart](lib/features/training_feature/providers/training_engine_v3_provider.dart) | provider | Revisado | sin hallazgo | superficie V3 activa |
| [lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart](lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart) | training engine | Revisado | sin hallazgo | motor V3 activo |
| [lib/domain/training_v3/services/motor_v3_orchestrator.dart](lib/domain/training_v3/services/motor_v3_orchestrator.dart) | training engine | Revisado | sin hallazgo | motor V3 activo |
| [lib/domain/training_v3/validators/training_plan_forensic_validator.dart](lib/domain/training_v3/validators/training_plan_forensic_validator.dart) | training engine | Revisado | sin hallazgo | validación central |
| [lib/nutrition_engine/validation/nutrition_plan_validator.dart](lib/nutrition_engine/validation/nutrition_plan_validator.dart) | nutrition | Revisado | sin hallazgo | validador presente |
| [lib/features/anthropometry_feature/screen/anthropometry_screen.dart](lib/features/anthropometry_feature/screen/anthropometry_screen.dart) | screen | Muestreo | riesgo no confirmado | UI no validada runtime |
| [lib/features/biochemistry_feature/screen/biochemistry_screen.dart](lib/features/biochemistry_feature/screen/biochemistry_screen.dart) | screen | Muestreo | riesgo no confirmado | UI no validada runtime |
| [lib/features/finance_feature/finance_screen.dart](lib/features/finance_feature/finance_screen.dart) | screen | Muestreo | riesgo no confirmado | UI de pagos no validada runtime |

### 4.2 Inventario de módulos con cobertura agregada

| Módulo | Archivos revisados | Cobertura | Riesgo principal |
| --- | --- | --- | --- |
| bootstrap / firebase | 4 | completa | soporte por plataforma y App Check |
| persistencia remota | 3 | alta | casts y payload contracts |
| persistencia local | 3 | alta | schema, outbox, migración |
| providers core | 2 | alta | legacy y side effects |
| motor entrenamiento V3 | 8+ | alta | complejidad funcional y trazabilidad |
| nutrición/macros | 6+ | media | cálculos y serialización |
| antropometría / bioquímica | 4+ | media | datos clínicos y UI asociada |
| agenda / pagos | 3+ | media | numéricos y estados vacíos |
| tests | 20+ | alta | mezcla de unit/integration/manual |
| assets | inventario completo por carpeta | media | volumen alto, no inspección visual total |
| docs/audits | inventario completo | alta | evidencia histórica útil |

### 4.3 Inventario resumido de tests

| Archivo | Tipo | Estado | Riesgo | Hallazgo |
| --- | --- | --- | --- | --- |
| [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart) | test unit | Revisado | sin hallazgo | canary estático |
| [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart) | test manual | Revisado | P2 | requiere sesión real |
| [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart) | test manual | Revisado | P2 | requiere sesión real |
| [test/manual/training_v3_case_audit_runner_test.dart](test/manual/training_v3_case_audit_runner_test.dart) | test manual | Revisado | P3 | runner de casos/audit |
| [test/integration/critical_flows_test.dart](test/integration/critical_flows_test.dart) | test integration | Revisado | sin hallazgo | sanity de serialización/locks |
| [test/data/repositories/client_repository_sync_test.dart](test/data/repositories/client_repository_sync_test.dart) | test unit | Revisado | sin hallazgo | sync local/remote |
| [test/data/repositories/client_repository_outbox_test.dart](test/data/repositories/client_repository_outbox_test.dart) | test unit | Revisado | sin hallazgo | outbox |
| [test/core/services/background_sync_service_outbox_test.dart](test/core/services/background_sync_service_outbox_test.dart) | test unit | Revisado | sin hallazgo | cola y retry |
| [test/core/services/background_sync_service_clinical_records_outbox_test.dart](test/core/services/background_sync_service_clinical_records_outbox_test.dart) | test unit | Revisado | sin hallazgo | records outbox |
| [test/core/services/background_sync_service_clinical_records_delete_outbox_test.dart](test/core/services/background_sync_service_clinical_records_delete_outbox_test.dart) | test unit | Revisado | sin hallazgo | delete outbox |
| [test/domain/training_v3/verification/motor_v3_volume_verification_test.dart](test/domain/training_v3/verification/motor_v3_volume_verification_test.dart) | test unit | Revisado | sin hallazgo | verificación científica |
| [test/domain/training_v3/verification/cycle_template_allocation_audit_test.dart](test/domain/training_v3/verification/cycle_template_allocation_audit_test.dart) | test unit | Revisado | sin hallazgo | auditoría de asignación |

### 4.4 Inventario resumido de assets y config

| Ruta | Tipo | Estado | Riesgo | Observación |
| --- | --- | --- | --- | --- |
| [assets/data/training_v3/catalog/](assets/data/training_v3/catalog/) | assets | revisado por muestra | riesgo no confirmado | catálogo grande, sin inspección visual total |
| [assets/media/exercises/gifs/](assets/media/exercises/gifs/) | assets | revisado por conteo | riesgo no confirmado | volumen alto, binarios no validados uno a uno |
| [assets/data/exercises/](assets/data/exercises/) | assets | revisado por muestra | riesgo no confirmado | ruta usada por loaders |
| [pubspec.yaml](pubspec.yaml) | config | Revisado | sin hallazgo | assets y deps declaradas |
| [pubspec.lock](pubspec.lock) | config | Revisado | sin hallazgo | lock presente |
| [analysis_options.yaml](analysis_options.yaml) | config | Revisado | sin hallazgo | lint base |
| [firebase.json](firebase.json) | config | Revisado | sin hallazgo | hosting/config firebase |
| [firestore.rules](firestore.rules) | config | Revisado | sin hallazgo | reglas presentes |
| [firestore.indexes.json](firestore.indexes.json) | config | Revisado | sin hallazgo | indexes presentes |
| [windows/CMakeLists.txt](windows/CMakeLists.txt) | nativo | Revisado | sin hallazgo | shell desktop win |
| [macos/Runner.xcodeproj/project.pbxproj](macos/Runner.xcodeproj/project.pbxproj) | nativo | Revisado | sin hallazgo | shell desktop macOS |

## 5. Matriz de cobertura por módulo

| Módulo | Archivos revisados | Cobertura | Riesgo principal |
| --- | --- | --- | --- |
| Bootstrap | 4 | completa | soporte por plataforma y App Check |
| Seguridad Firebase | 7 | alta | payloads, reglas, manual smoke |
| Persistencia local | 4 | alta | schema, outbox, migración |
| Persistencia remota | 4 | alta | casts, documentos corruptos |
| Arquitectura core | 3 | alta | servicios singleton y side effects |
| Providers main shell | 2 | alta | legacy merge y gran tamaño |
| Providers entrenamiento | 4+ | alta | orquestación, compatibilidad, logging |
| Motor entrenamiento V3 | 8+ | alta | complejidad funcional y trazabilidad |
| Nutrición/macros | 6+ | media | cálculos y serialización |
| Antropometría/bioquímica | 4+ | media | datos clínicos sensibles |
| Agenda/pagos | 3+ | media | numéricos y estados vacíos |
| UI técnica | 15+ | baja/media | no hubo navegación runtime total |
| Tests | 20+ | alta | cobertura fuerte pero mix manual/CI |
| Assets | 1480 | media | inspección visual no total |
| Docs/audits | 84+ | alta | soporte histórico útil |

## 6. Hallazgos P0

No hay hallazgos P0 confirmados.

## 7. Hallazgos P1

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

- Evidencia: el cast asume que amount siempre existe y es num.
- Impacto: una transacción mal formada puede romper vistas financieras y totales del mes.
- Causa: decoder no tolerante en capa de repositorio.
- Corrección recomendada: validar tipo, aplicar fallback, registrar documento corrupto.
- Archivos probables: [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart), tests de repositorio.
- Test recomendado: amount null, string y ausente.
- Estado: vigente.

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

- Evidencia: cast directo de snapshot y payload.
- Impacto: documento corrupto o migrado puede abortar lectura del dominio.
- Causa: contrato Firestore demasiado optimista.
- Corrección recomendada: validar tipo de mapa y tolerar payload inválido.
- Archivos probables: [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart), tests payload contract.
- Test recomendado: snapshot con payload string/schemaVersion string/updatedAt ausente.
- Estado: vigente.

## 8. Hallazgos P2

### P2-01 — SyncService traga errores y degrada observabilidad de la cola

- Ruta: [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart#L37)
- Clase/función: `_processPendingQueue` / `_syncItem`
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

- Evidencia: los errores se reducen a debugPrint y a marcar fallo local.
- Impacto: fallos repetidos pueden quedar silenciosos.
- Causa: prioridad a continuidad sin observabilidad estructurada.
- Corrección recomendada: logger estructurado y contador de reintentos.
- Archivos probables: [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart), [lib/data/datasources/local/sync_queue_helper.dart](lib/data/datasources/local/sync_queue_helper.dart).
- Test recomendado: fallo repetido con verificación de trazabilidad.
- Estado: vigente.

### P2-02 — TrainingPlanProvider mezcla orquestación, persistencia, compatibilidad legacy y logging masivo

- Ruta: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L520)
- Clase/función: `generateTrainingPlan` / `generatePlanFromActiveCycle`
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

- Evidencia: hay código inalcanzable tras throw, métodos deprecados y logging abundante.
- Impacto: mantenimiento costoso y flujo difícil de razonar.
- Causa: responsabilidades mezcladas en un provider enorme.
- Corrección recomendada: separar adaptador legacy y orquestación productiva.
- Archivos probables: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart).
- Test recomendado: asegurar que la ruta productiva no depende del bloque legacy.
- Estado: vigente.

### P2-03 — ClientsNotifier conserva una ruta legacy de merge amplio detrás de feature flag

- Ruta: [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart#L240)
- Clase/función: `updateActiveClient` / `_updateActiveClientLegacy`
- Snippet actual:

```dart
  Future<void> updateActiveClient(Client Function(Client) transform) async {
    if (FeatureFlags.useLegacyClientUpdate) {
      return _updateActiveClientLegacy(transform);
    }
```

- Evidencia: la rama legacy sigue viva y mergea secciones completas.
- Impacto: si se reactiva, reaparece riesgo de sobrescritura amplia.
- Causa: compatibilidad temporal embebida en el notifier.
- Corrección recomendada: aislar o retirar la compatibilidad.
- Archivos probables: [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart), [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart).
- Test recomendado: flujo granular sin snapshot viejo.
- Estado: vigente.

### P2-04 — Las pruebas manuales de Firestore quedan fuera de CI y requieren sesión real

- Ruta: [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart#L1), [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart#L1)
- Clase/función: smoke tests manuales que inicializan Firebase real
- Snippet actual:

```dart
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
...
    skip:
        'Manual smoke test. Requires an authenticated coach session before run.',
```

- Evidencia: son tests reales contra Firebase, pero skippeados y dependientes de sesión manual.
- Impacto: la cobertura crítica de integración no forma parte del pipeline automático.
- Causa: diseño manual de smoke test.
- Corrección recomendada: añadir equivalente CI-friendly con emulator o fixtures.
- Archivos probables: `test/manual/*` y harness de integración.
- Test recomendado: upsert/fetch/delete sin sesión manual.
- Estado: vigente.

## 9. Hallazgos P3

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
```

- Evidencia: wrapper declarado como legacy; no vi consumidores directos en la búsqueda de esta pasada.
- Impacto: ambigüedad de fuente verdadera y más superficie de mantenimiento.
- Corrección recomendada: retirar o aislar compatibilidad cuando no existan consumidores.
- Test recomendado: búsqueda de consumidores antes de eliminar.
- Estado: vigente como deuda menor.

### P3-02 — Logging excesivo en providers y sync

- Ruta: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart)
- Clase/función: varios `debugPrint`
- Evidencia: hay muchas trazas de depuración repartidas por rutas productivas y de sync.
- Impacto: ruido en producción y más difícil distinguir señales de fallo reales.
- Corrección recomendada: migrar a logger estructurado o bajar verbosidad en release.
- Estado: vigente, prioridad baja-media.

## 10. Riesgos no confirmados

| Riesgo | Ruta/módulo | Por qué no se confirmó | Qué falta |
| --- | --- | --- | --- |
| overflow o layout roto | UI técnica | no hubo navegación runtime completa | abrir pantallas y verificar desktop/mobile |
| assets binarios inválidos | assets/media y training catalog | no inspección visual total | revisar muestras por carpeta en runtime |
| regla nativa/plataforma rota | windows/macos | no compilación nativa completa en esta V2 | build/runtime por plataforma |
| conflicto real de catálogo y UI | motor training V3 | no navegación integral de todas las pantallas | seguir call chain desde screens a engine |
| secretos o env no versionados | .env / config externa | no validación de entorno externo | revisar ejecución con credenciales reales |

## 11. Seguridad

### Firebase

La configuración Firebase está centralizada y ya no vive en `main.dart`. Eso reduce la superficie de bootstrap.

### Auth

No se detectó un patrón nuevo de hardcode de auth. Queda pendiente validación runtime de flujos de sesión reales.

### Firestore

La superficie más riesgosa está en `record_firestore_datasource.dart` y `transaction_repository.dart` por casts y contrato de payload.

### Storage

No se encontró un archivo de reglas de Storage. Eso no prueba ausencia total de uso, pero sí deja una brecha de gobernanza que debe confirmarse fuera del editor.

### App Check

Está centralizado en el helper de bootstrap y validado por el canary estático.

### logs sensibles

Hay `debugPrint` en sync y providers, pero no vi tokens de App Check ni localhost hardcodeado sin guardas.

### secretos

No se confirmó exposición directa de secretos en el árbol revisado.

### reglas

`firestore.rules` e `firestore.indexes.json` existen y fueron inventariados.

### emuladores

No se confirmaron usos de emuladores en `lib/` durante esta pasada.

### datos clínicos

Anthropometry, biochemistry y history clinic se consideran sensibles. La auditoría no confirmó fuga, pero sí amplias rutas de UI/persistencia.

### datos financieros

`transaction_repository.dart` sigue siendo el punto a priorizar por casts numéricos.

## 12. Persistencia y sincronización

La persistencia local usa SQLite con helper dedicado y la sincronización se reparte entre cola local, background sync y repositorios Firestore.

Puntos confirmados:

- `database_helper.dart` mantiene schema y migraciones.
- `sync_service.dart` procesa cola y reintentos.
- `record_firestore_datasource.dart` y `transaction_repository.dart` siguen siendo sensibles a payloads mal formados.

Puntos a seguir en sprint:

- contratos tolerantes de decoders;
- trazabilidad más fuerte de fallos;
- tests de outbox con casos corruptos.

## 13. Arquitectura

La separación domain/data/features/core existe, pero no siempre es estricta.

Riesgos arquitectónicos confirmados:

- providers grandes con side effects y compatibilidad temporal;
- servicios singleton para sync;
- helpers legacy todavía compilados;
- mezcla de orquestación y persistencia en algunos providers.

## 14. UI técnica

No hubo navegación runtime suficiente para cerrar overflow, anidación de scroll, mounted-checks o layout issues en toda la superficie.

Riesgo técnico no confirmado:

- pantallas grandes en training, macros, meal plan y clinic history.

## 15. Motor entrenamiento

Motor V3 sigue siendo el motor activo observado. Las rutas V1/V2 aparecen como compatibilidad o migración.

No se modificaron reglas científicas.

Puntos confirmados:

- motor V3 está presente y activo en la ruta principal.
- hay wrappers y migraciones legacy alrededor del motor.
- los tests V3 son abundantes y de tipo integración/regresión/forense.

## 16. Nutrición/macros

No se confirmó un bug concreto nuevo en esta pasada, pero sí una superficie amplia de cálculo/serialización.

Riesgos observados:

- cadenas de cálculo y validación repartidas entre engine, providers y helpers;
- conversiones numéricas y JSON en tests y modelos;
- mezcla de UI de macros con lógica de negocio.

## 17. Antropometría/bioquímica

Riesgo principal: dominio sensible con persistencia y UI extensa.

No se confirmó una fórmula rota concreta en esta pasada, pero sí la necesidad de validar runtime y snapshots de Firestore para datos clínicos.

## 18. Agenda/pagos

El dominio financiero sigue siendo sensible por casts numéricos y cálculo de totales.

El archivo crítico es [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart).

## 19. Tests

### Inventario de tests por tipo

| Tipo | Ejemplos encontrados | Cobertura | Comentario |
| --- | --- | --- | --- |
| unit | `*_test.dart` en core, domain, data | alta | núcleo fuerte de reglas y serializers |
| integration | `test/integration/*`, `test/domain/*/integration*` | alta | hay bastante cobertura funcional |
| manual | `test/manual/*` | media | no entra en CI |
| canary | `test/security/firebase_app_check_static_contract_test.dart` | alta | contrato estático útil |
| regression | `test/domain/training_v3/regression/*` | alta | congela comportamiento del motor |
| verification | `test/domain/training_v3/verification/*` | alta | buen cierre científico |
| smoke | `test/manual/firestore_smoke_test.dart` | baja/operativa | requiere sesión real |

### Cobertura y huecos

- Cubre bien Motor V3, validadores y regressions.
- Cubre parcialmente persistencia local/remota.
- Cubre de forma manual las rutas reales de Firebase.
- No cubre con igual fuerza UI runtime ni plataforma nativa completa.

## 20. Assets

Inventario de assets encontrado:

- `assets/data/training_v3/catalog/` con catálogo, esquema, queue y archivos relacionados.
- `assets/data/exercises/` con catálogos de ejercicios.
- `assets/data/` con equivalentes, alimentos y cooking yields.
- `assets/media/exercises/gifs/` con miles de GIFs.
- `assets/Logos/` con branding.
- `assets/entrenamiento/` con material gráfico por semana.

Estado:

- Hay assets declarados en `pubspec.yaml`.
- Hay carpetas y binarios grandes que no se inspeccionaron visualmente uno por uno.
- No se confirmó ruptura de rutas declaradas en esta pasada.

## 21. APIs deprecadas / riesgosas

| API/patrón | Archivo | Evidencia | Severidad | Acción |
| --- | --- | --- | --- | --- |
| `@Deprecated` legacy wrapper | [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart) | wrapper de compatibilidad | P3 | aislar o retirar |
| `debugPrint` abundante | [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart), [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart) | trazas en rutas productivas | P3/P2 | reducir o estructurar |
| cast directo `as num` | [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart) | totales financieros | P1 | decoder tolerante |
| cast directo `as Map<String, dynamic>` | [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart) | fetch remoto | P1 | validar payload |
| `Timer.periodic` singleton | [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart) | cola periódica | P2 | monitoreo y límites |

## 22. Código muerto/no usado

Confirmado o muy probable:

- bloque legacy inalcanzable después de `throw` en `TrainingPlanProvider`.
- wrapper legacy del loader de ejercicios.

No confirmado:

- código UI muerto en pantallas no navegadas runtime.

## 23. Código duplicado

Confirmado:

- helper legacy y helper productivo con lógica muy parecida en `clients_provider.dart`.
- varias rutas de pruebas y validación repiten serialización/mapeo, pero eso es aceptable en tests de regresión.

## 24. Dependencias y configuración

`pubspec.yaml` declara dependencias relevantes para Firebase, Riverpod, SQLite, PDF, HTTP, shared_preferences, google_fonts y otras utilidades.

Configuración presente y revisada:

- `analysis_options.yaml`
- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`
- `pubspec.lock`

Observación:

- no se encontró un archivo de reglas de Storage en el workspace.

## 25. Revalidación de hallazgos V1

| Hallazgo V1 | Estado V2 | Cambio | Acción |
| --- | --- | --- | --- |
| P1-01 `TransactionRepository.calculateMonthlyIncome/calculateMonthlyExpenses` | Vigente | se confirmó con snippet directo | plan de hardening |
| P1-02 `RecordFirestoreDataSource.fetchRecords` | Vigente | se confirmó con snippet directo | plan de hardening |
| P2-01 `SyncService` traga errores | Vigente | se confirmó con snippet directo | refactor de observabilidad |
| P2-02 `TrainingPlanProvider` mezcla orquestación/legacy/logging | Vigente | se confirmó con snippet directo | separación de responsabilidades |
| P2-03 `ClientsNotifier` conserva ruta legacy wide merge | Vigente | se confirmó con snippet directo | retirar compatibilidad temporal |
| P2-04 smoke tests manuales fuera de CI | Vigente | se confirmó por diseño | mover parte a CI-friendly |
| P3-01 `ExerciseCatalogLoader` legacy | Vigente | se confirmó como wrapper | aislar o retirar |
| P3-02 logging excesivo | Vigente | se confirmó en varias rutas | bajar verbosidad |

## 26. Plan de sprints recomendado

| Orden | Sprint | Objetivo | Severidad | Archivos | Tests |
| --- | --- | --- | --- | --- | --- |
| 1 | P1-Firestore contracts | blindar decoders y casts | P1 | [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart), [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart) | contract tests de payload |
| 2 | P2-sync observability | endurecer cola y fallos | P2 | [lib/core/services/sync_service.dart](lib/core/services/sync_service.dart) | outbox y failure path tests |
| 3 | P2-provider split | separar legacy de orquestación | P2 | [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart), [lib/features/main_shell/providers/clients_provider.dart](lib/features/main_shell/providers/clients_provider.dart) | tests de ruta productiva |
| 4 | P2-smoke to CI | llevar parte de smoke a automatización | P2 | `test/manual/*` | emulator/fixture tests |
| 5 | P3-legacy cleanup | retirar wrappers y ruido | P3 | [lib/data/datasources/local/exercise_catalog_loader.dart](lib/data/datasources/local/exercise_catalog_loader.dart) | búsqueda de consumidores |

## 27. Quick wins seguros

- Añadir tests de contrato para `amount` no numérico en transacciones.
- Añadir tests de snapshot corrupto para `fetchRecords`.
- Reducir `debugPrint` en rutas de sync y provider.
- Mantener el canary de App Check como guardia de regresión.
- Documentar que los smoke tests manuales no sustituyen CI.

## 28. Limitaciones restantes

Las limitaciones que siguen siendo reales después de esta V2 son concretas:

- no se ejecutó navegación manual de UI;
- no se validó Firebase Console;
- no se ejecutó suite completa;
- no se inspeccionó visualmente cada asset binario;
- no se validó hardware/plataforma nativa real;
- no hubo lectura línea por línea de todos los archivos Dart versionados.

## 29. Veredicto final

FULL-REPO-AUDIT-P2: INCOMPLETO POR LIMITACIONES REALES