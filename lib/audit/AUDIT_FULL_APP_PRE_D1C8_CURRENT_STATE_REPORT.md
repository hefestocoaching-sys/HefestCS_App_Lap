# AUDIT FULL APP PRE D1-C8 CURRENT STATE REPORT

Fecha local de auditoria: 2026-05-28  
Repo: `c:\Users\pedro\StudioProjects\hcs_app_lap`  
Modo: auditoria local read-only. Unica escritura realizada: este reporte en `lib/audit/`.

## 1. Resumen ejecutivo

El repo esta alineado en codigo productivo para MUSCLE SSOT desde D1-A hasta D1R8 en las superficies ya cerradas. Los helpers principales usan `tryNormalizeMuscleKey` / `expandMuscleGroupStrict` y los unknowns ya no pasan en `PairingContract`, `AntagonistPairingEngine`, `SessionStructureEngine`, `ExerciseSelectionEngine`, `WeeklyVolumePlanner`, validators y adapters auditados.

No es seguro entrar directo a D1-C8. `CycleTemplateBuilder` sigue usando normalizacion legacy:

```dart
return muscle_registry.normalize(k) ?? k.trim().toLowerCase();
```

Ese builder puede convertir `glute -> glutes` y conservar `unknown_muscle`, `back_mid_upper` y `mysterychest` como raw en rutas de bloques/pairing. Los fixtures D1R8 son proxy, no harness real de `buildBaseWeek`.

Hay un P1 runtime/UI mas urgente que seguir MUSCLE SSOT: `TrainingWorkspaceScreen` declara `TabController(length: 6)` pero ejecuta `_v3TabController.animateTo(6)`. Indices validos: 0-5.

La validacion automatica quedo bloqueada por Flutter tool lock/timeout: `flutter test`, `flutter --version` y `flutter analyze --no-pub` no devolvieron resultado dentro del timeout. No se borraron lockfiles por la regla de no borrar archivos.

## 2. Estado final A/B/C/D/E/F

**ESTADO F**.

Motivo principal: existe P1 runtime/UI mas urgente que continuar D1-C8 (`TrainingWorkspaceScreen:81` vs `TrainingWorkspaceScreen:1791`). Ademas, la validacion queda en estado D-operativo porque Flutter no respondio y no se pudo confirmar tests/analyze verdes en esta corrida.

## 3. Evidencia corta

- `lib/domain/training_v3/services/cycle_template_builder.dart:1084-1085`: normalizador legacy con `muscle_registry.normalize(...) ?? ...toLowerCase()`.
- `lib/domain/training_v3/services/cycle_template_builder.dart:2285-2288`: `_isLowInterference` consulta `InterferenceMatrix` sin expansion strict.
- `lib/domain/training_v3/services/cycle_template_builder.dart:2312-2387`: orden y plan A/B/C/D usan helpers strict mezclados con normalizador local legacy.
- `lib/features/training_feature/screens/training_workspace_screen.dart:81`: `TabController(length: 6)`.
- `lib/features/training_feature/screens/training_workspace_screen.dart:1791`: `_v3TabController.animateTo(6)`.
- `lib/data/datasources/local/database_helper.dart` importa `sync_queue_helper.dart`; `sync_queue_helper.dart` importa `database_helper.dart`: ciclo real.
- `flutter test ...pairing_callsites...` timeout 180s; `flutter analyze --no-pub` timeout 180s.

## 4. Alcance auditado

Auditado desde raiz: carpetas, archivos raiz, `pubspec.yaml`, `analysis_options.yaml`, Firebase/Firestore, assets, `lib/`, `test/`, `integration_test/`, `docs/`, `tool/`, plataformas, worktree, estructura Dart, MUSCLE SSOT D1-A a D1R8, `CycleTemplateBuilder`, Motor V3 pipeline, modelos criticos, UI, DB/sync, tests/reportes.

No se modifico codigo productivo, UI, DB, modelos, tests, assets, docs existentes ni reportes previos.

## 5. Carpetas/archivos raiz

Carpetas raiz existentes: `.dart_tool`, `.git`, `.idea`, `.venv`, `.vs`, `.vscode`, `assets`, `build`, `coverage`, `docs`, `integration_test`, `lib`, `linux`, `macos`, `test`, `tool`, `windows`.

Plataformas: `windows`, `macos`, `linux` existen. `android`, `ios`, `web` no existen.

Archivos raiz importantes: `.firebaserc`, `.flutter-plugins-dependencies`, `.gitattributes`, `.gitignore`, `.liveui.json`, `.metadata`, `analysis_options.yaml`, `build.yaml`, `devtools_options.yaml`, `firebase.json`, `firebase.json.bak`, `firestore.indexes.json`, `firestore.rules`, `pubspec.lock`, `pubspec.yaml`, `hcs_app_lap.iml`.

Logs/zips/reportes sueltos: `build_output.log`, `debug_build.log`, `error_log.txt`, `final_analysis.txt`, `flutter_analyze.txt`, `run_output.log`, `lib.zip`. No hay `.md` fisicos en raiz, pero `git status --short` muestra reportes raiz borrados.

Firebase: `.firebaserc` apunta a `hcseco-55882`. `firebase.json` declara Firestore rules/indexes, emulators auth/firestore/ui y config Flutter Windows en `lib/firebase_options.dart`.

Assets declarados: `assets/Logos/`, `assets/data/`, `assets/data/exercises/exercise_catalog_gym.json`, `assets/data/training_v3/catalog/`, `assets/media/exercises/gifs/`.

Assets fisicos: 1480 archivos bajo `assets/`. Faltantes declarados: 0. No declarados: 140 bajo `assets/entrenamiento/`.

`integration_test/`: 2 archivos (`repository_integration_test.dart`, `weekly_progression_integration_test.dart`). `tool/`: existe sin archivos detectados.

Worktree: `git status --short` requirio `-c safe.directory=...`. Hay muchos `M`, varios `D` raiz y `??` incluyendo `lib/audit/`, tests/fixtures nuevos y archivos productivos modificados previos. No se revirtio nada.

## 6. Auditoria estructural Dart

- Dart files en `lib/`: 684.
- Dart files en `test/`: 76.
- Directivas auditadas: 2889.
- Imports relativos internos: 0.
- Exports relativos: 0.
- `part`/`part of` relativos: 0.
- Imports package internos rotos: 0.
- Imports a archivos inexistentes: 0.
- Archivos vacios: 0.

Ciclo real:

- `lib/data/datasources/local/database_helper.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`

Duplicados nominales relevantes:

- `database_helper.dart`: `lib/data/datasources/local/`, `lib/services/`.
- `training_plan_config.dart`: entity y V3 model.
- `training_plan.dart`: entity y V3 model.
- `training_week.dart`: entity y V3 model.
- `training_session.dart`: entity y V3 model.
- `exercise_prescription.dart`: entity y V3 model.
- `muscle_keys.dart`: `core/constants` y `core/utils`.
- `volume_landmarks.dart`: constants/modelos duplicados.
- `muscle_key_normalizer.dart`: helper legacy activo.

Legacy/deprecated por nombre/anotacion: `training_interview_legacy_keys.dart`, `muscle_key_normalizer.dart`, `exercise_catalog_loader.dart` deprecated, `hybrid_orchestrator_v3.dart` deprecated, `_buildSessions` deprecated en `motor_v3_orchestrator.dart`, servicios `phase_*` legacy.

## 7. Pubspec

Paquete: `hcs_app_lap`. Version: `2.0.0+8`. Dart SDK: `^3.9.2`. `dependency_overrides`: no.

Dependencias: Flutter, localizations, http, intl, fl_chart, provider, riverpod, flutter_riverpod, Firebase core/firestore/auth/storage/analytics/app_check, sqflite/sqflite_common_ffi, path_provider/path, pdf/printing/csv, freezed/json annotations, form builder, dotenv, equatable, uuid, synchronized, shared_preferences, meta.

Dev dependencies: `flutter_test`, `integration_test`, `flutter_lints`, `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `mocktail`, `fake_async`, `mockito`.

Riesgos: mezcla `provider` + Riverpod; mezcla `mocktail` + `mockito`; assets fisicos no declarados en `assets/entrenamiento/`; no se actualizaron dependencias.

## 8. Analysis options

Incluye `package:flutter_lints/flutter.yaml`.

Elevado a error: `use_build_context_synchronously`, `avoid_print`.

Rules activas: `prefer_const_*`, `avoid_unnecessary_containers`, `sized_box_for_whitespace`, `use_key_in_widget_constructors`, `avoid_redundant_argument_values`, `unnecessary_string_interpolations`, `unnecessary_this`.

Excludes: `**/*.g.dart`, `**/*.freezed.dart`. No oculta carpetas productivas completas.

Regla permisiva: `public_member_api_docs: false`.

## 9. Muscle SSOT por fase D1-A a D1R8

API strict existe en `lib/core/registry/muscle_registry.dart`: `tryNormalizeMuscleKey` line 268, `normalizeMuscleKeyOrThrow` line 286, `expandMuscleGroupStrict` line 293, `isCanonicalMuscleKey` line 306, `UnknownMuscleKeyException` line 233.

La strict allowlist no incluye `glute`; la legacy map si incluye `glute -> glutes`. Eso es correcto para compatibilidad legacy, pero cualquier consumidor que use `muscle_registry.normalize` sigue siendo riesgoso.

Archivos objetivo:

| archivo | strict API | legacy/raw | estado |
| --- | --- | --- | --- |
| `muscle_registry.dart` | si | legacy API convive | seguro si consumidores usan strict |
| `exercise_preferences_muscle_key_mapper.dart` | `tryNormalizeMuscleKey` line 34 | doc `supportedAliases` aun lista `glute` | requiere limpieza documental, runtime strict |
| `muscle_to_catalog_resolver.dart` | lines 40, 63 | no raw passthrough | cerrado |
| `muscle_key_adapter_v3.dart` | lines 43, 76 | `traps_upper` legacy especial | legacy permitido |
| `training_plan_forensic_validator.dart` | multiples `tryNormalize...` | `return raw` no muscular en parser; unknown -> `''` | cerrado |
| `mev_table.dart` | lines 10, 18 | no raw | cerrado |
| `vop_validator.dart` | lines 54, 66, 114, 120 | no raw muscular | cerrado |
| `volume_validator.dart` | lines 47, 60, 419, 431 | grupos agregados legacy controlados | cerrado/legacy permitido |
| `landmark_engine.dart` | lines 123, 137 | no raw | cerrado |
| `muscle_priority_engine.dart` | line 95 | no raw | cerrado |
| `weekly_volume_planner.dart` | line 180 | no raw | cerrado |
| `exercise_selection_engine.dart` | line 51 | deprecated wrapper retorna `''` | cerrado |
| `session_structure_engine.dart` | lines 441, 445 | parsers numericos `return raw` no musculares | cerrado |
| `pairing_contract.dart` | lines 91, 96 | no raw | cerrado |
| `antagonist_pairing_engine.dart` | lines 35, 40 | no raw | cerrado |
| `cycle_template_builder.dart` | no strict | line 1085 legacy fallback | requiere migracion |

## 10. Tabla de fases

| fase | estado | archivos | evidencia | riesgo |
| --- | --- | --- | --- | --- |
| D1-A | cerrado | `muscle_registry.dart` | strict API lineas 233, 268, 286, 293, 306 | legacy API coexiste |
| D1-C1 | cerrado | `exercise_preferences_muscle_key_mapper.dart` | `tryNormalizeMuscleKey` line 34 | `supportedAliases` lista `glute` aunque strict no lo acepta |
| D1-C2 | cerrado | resolver/adapter | resolver lines 40/63, adapter lines 43/76 | `traps_upper` legacy especial permitido |
| D1-C3 | cerrado | forensic validator | unknowns devuelven `''` por contrato | parsers raw no musculares |
| D1-C4-A1 | cerrado | `mev_table.dart` | strict normalize lines 10/18 | bajo |
| D1-C4-A2 | cerrado | `vop_validator.dart` | strict normalize lines 54/66/114/120 | bajo |
| D1-C4-B | cerrado | `volume_validator.dart` | strict/group lines 47/60/419/431 | grupos agregados legacy controlados |
| D1-C4-C1 | cerrado | `landmark_engine.dart` | strict parse/serialize lines 123/137 | bajo |
| D1-C4-C2 | cerrado | `muscle_priority_engine.dart` | strict normalize line 95 | bajo |
| D1R4 | cerrado historico | fixtures WeeklyVolumePlanner | test existe en `test/domain/training_v3/regression/` | no revalidado por timeout |
| D1-C4-C3 | cerrado | `weekly_volume_planner.dart` | `_normalizeMuscleIntMap` descarta null line 180 | bajo |
| D1R5 | cerrado historico | fixtures ExerciseSelection | reporte en `lib/audit/` | no revalidado por timeout |
| D1-C5 | cerrado | `exercise_selection_engine.dart` | strict selection line 51 | catalogo V3 aun tiene normalizador legacy |
| D1R6 | cerrado historico | fixtures SessionStructure | reporte en `lib/audit/` | no revalidado por timeout |
| D1-C6 | cerrado | `session_structure_engine.dart` | strict primary lines 441/445 | bajo |
| D1R7 | cerrado historico | pairing fixtures | reporte en `lib/audit/` | no revalidado por timeout |
| D1-C7 | cerrado | `pairing_contract.dart`, `antagonist_pairing_engine.dart` | strict group lines 91/96 y 35/40 | bajo |
| D1R8 | cerrado como proxy | pairing call sites fixtures | reporte D1R8 confirma `CycleTemplateBuilder` legacy | proxy insuficiente para `buildBaseWeek` |

## 11. Raw passthrough restante

Requiere migracion:

- `cycle_template_builder.dart:1085`: `muscle_registry.normalize(k) ?? k.trim().toLowerCase()`.
- `cycle_template_builder.dart`: multiples llamadas a `normalizeMuscleKey` en volumen, pool, prioridades, bloques, planned exercises y replacement.
- `motor_v3_orchestrator.dart:2287-2296`: `_canonicalMuscleKey` usa `muscle_registry.normalize`, `expandGroup`, fallback raw lowercase.
- `motor_v3_orchestrator.dart:433/450/1995/2786`: legacy normalize/expand en rutas de pipeline.
- `exercise_catalog_v3.dart:44-47`: fallback `rawKey.trim().toLowerCase()`.
- `training_profile_form_mapper.dart:456-462`: combina `normalizeMuscleKey`, `muscle_registry.normalize`, `expandGroup`.
- `active_cycle_bootstrapper.dart:157`: `muscle_registry.normalize(raw) ?? raw`.

Legacy permitido o fuera de MUSCLE SSOT actual:

- `core/utils/muscle_key_normalizer.dart`: helper legacy global, todavia usado por UI/compat.
- `muscle_registry.normalize`: permitido solo como API legacy, no para nuevas rutas strict.
- Parsers `return raw` en nutricion/fechas/numeros no son passthrough muscular.

## 12. Estado de CycleTemplateBuilder

Metodos publicos: `buildBaseWeek`, `normalizeMuscleKey`.

Metodos privados relevantes: `_canonicalizeVolumeMap`, `_canonicalizeExercisePool`, `_canonicalizePriorityMap`, `_canonicalizeConfigMap`, `_exercisePrimaryMuscle`, `_findPrimaryMuscleForDay`, `_orderMusclesByBlockPriority`, `_buildDayBlockMusclePlan`, `_isValidPairingForBlock`, `_isLowInterference`, `_applyPreferredDayOrder`, `_buildStructuredSessionDataFromSeeds`, `_buildStructuredSessionFromSeeds`, `_allocateSetsByBlockAndMuscle`, `_selectExercisesForMuscleDay`.

Hallazgos:

- `buildBaseWeek` normaliza entrada con `_canonicalizeVolumeMap` / `_canonicalizeExercisePool`, pero ambas usan `normalizeMuscleKey` legacy.
- `userProfile.musclePriorities`, `dayAlloc`, `setsByAppearancePerMuscle`, `priorities`, `PlannedExercise.muscleKey` y replacement pasan por el mismo normalizador legacy.
- `_exercisePrimaryMuscle` toma `primaryMuscles.first` y cae a `exercise.muscleKey`, ambos legacy.
- `_isLowInterference` no expande grupos strict.
- `_orderMusclesByBlockPriority`, `_buildDayBlockMusclePlan` y `_isValidPairingForBlock` llaman helpers strict despues de normalizar legacy en varios paths.
- Llama a `PairingContract.isAllowedBiserie`, `AntagonistPairingEngine.areAntagonists`, `ExerciseSelectionEngine.selectDeterministicCandidates` y `SessionStructureEngine.refinePlannedExercises`.

## 13. Evaluacion pre D1-C8

D1-C8 directo no es seguro como primer paso.

Conviene **D1R9** con harness real de `CycleTemplateBuilder.buildBaseWeek` antes de migrar. D1R8 congelo proxies de call sites, pero no ejecuta el builder completo con catalogo/pool/volumen/sesiones.

Metodos que D1-C8 tocaria despues de D1R9: `normalizeMuscleKey`, `_canonicalizeVolumeMap`, `_canonicalizeExercisePool`, `_canonicalizePriorityMap`, `_canonicalizeConfigMap`, `_exercisePrimaryMuscle`, `_orderMusclesByBlockPriority`, `_buildDayBlockMusclePlan`, `_isValidPairingForBlock`, `_isLowInterference`, llamadas de `buildBaseWeek` que alimentan esas rutas.

Metodos que D1-C8 no debe tocar: formulas de volumen, `IntensityDistributionEngine`, `RepStructureEngine`, `ExerciseSelectionEngine`, `SessionStructureEngine`, `PairingContract`, `AntagonistPairingEngine`, `MotorV3Orchestrator`, UI, DB, modelos, repositorios, catalogo productivo.

Tests existentes utiles: pairing callsites/helpers fixtures, session structure fixtures, exercise selection fixtures, weekly volume fixtures, strict suite MuscleRegistry/validators. Falta: test nuevo con `buildBaseWeek` real que cubra canonical, valid aliases, unknowns (`unknown_muscle`, `back_mid_upper`, `mysterychest`, `glute`) y grupos (`back`, `shoulders`, `arms`, `legs`).

## 14. Estado Motor V3 pipeline

- `TrainingProfile.extra`: fuente de interview/progression/landmarks/VOP/activePlanId.
- `TrainingExtraKeys.activePlanId`: `lib/core/constants/training_extra_keys.dart:63`.
- `TrainingExtraKeys.vopSnapshot`: `lib/core/constants/training_extra_keys.dart:159`.
- VME/VOP/VMR: `LandmarkEngine.calculateFromProfile`, `VolumeLandmarks.calculate`, `VolumeLandmarksCalculator`, y fallback provider con `VolumeEngine.calculateOptimalVolume`.
- `vopSnapshot`: `features/training_feature/context/vop_context.dart` lee/escribe `training.extra['vopSnapshot']`.
- Volumen semanal: `WeeklyVolumePlanner.buildWeekVolume`.
- Seleccion de ejercicios: `ExerciseSelectionEngine`, llamado por `CycleTemplateBuilder`.
- Estructura de sesion: `CycleTemplateBuilder` y `SessionStructureEngine.refinePlannedExercises`.
- Validacion target vs assigned: `TrainingPlanForensicValidator`, `VopValidator.validate`, `VolumeValidator`.
- Persistencia `TrainingPlanConfig`: `TrainingPlanProvider.generatePlanFromActiveCycle` agrega a `client.trainingPlans`.
- `activePlanId`: actualizado en `generatePlanFromActiveCycle` y `updateActivePlanId`.
- UI lee plan: `TrainingWorkspaceScreen`, `TrainingDashboardScreen`, `TrainingWorkspaceProvider` usando `client.trainingPlans` + `TrainingExtraKeys.activePlanId`.

Regeneracion accidental: `loadPersistedActivePlanIfAny` carga sin generar. `generatePlanFromActiveCycle` no regenera si ciclo activo tiene `freezePlanSnapshot`; si no hay freeze, genera/bootstrap.

Multiples fuentes de volumen: si. Conviven `vopSnapshot`, `muscleLandmarks`, `volumePerMuscle`, `baseExercisesByMuscle`, `targetSetsByMuscle*`, `mevByMuscle`, `mrvByMuscle`.

Datos legacy compitiendo con V3: si. Hay entity/V3 duplicados, `TrainingPlanMapper.toGeneratedPlan`, fallback de `VopContext.migrateFromLegacy`, y normalizadores legacy en MotorV3/catalogo/UI.

## 15. Estado modelos criticos

| modelo | archivo | serializacion | riesgo |
| --- | --- | --- | --- |
| `Client` | `domain/entities/client.dart` | from/to JSON, copyWith, getters UI | blob grande; Firestore size guard a 900k |
| `AnthropometryRecord` | `domain/entities/anthropometry_record.dart` | from/to JSON, copyWith | sin fromMap dedicado; depende JSON |
| `BioChemistryRecord` | `domain/entities/biochemistry_record.dart` | from/to JSON | muchos campos nullable; riesgo de drift de UI |
| `DailyNutritionPlan` | `domain/entities/daily_nutrition_plan.dart` | from/to JSON/Map, copyWith | modelo grande con validacion interna |
| `NutritionPlan` | no encontrado | n/a | nombre no existe como clase |
| `TrainingProfile` | `domain/entities/training_profile.dart` | from/to JSON, copyWith | extra muy cargado; normaliza muscle maps con helper legacy |
| `TrainingPlanConfig` entity | `domain/entities/training_plan_config.dart` | from/to Map/JSON, copyWith | principal para UI/persistencia |
| `TrainingPlanConfig` V3 | `domain/training_v3/models/training_plan_config.dart` | sin from/to JSON | duplicado liviano; requiere conversion |
| `TrainingWeek` entity/V3 | dos archivos | entity serializa; V3 no | duplicidad |
| `TrainingSession` entity/V3 | dos archivos | ambos serializan | duplicidad de contratos |
| `ExercisePrescription` entity/V3 | dos archivos | ambos serializan | campos distintos |
| `PlannedExercise` | `domain/training_v3/models/planned_exercise.dart` | from/to Map, copyWith | estructura de bloques/pairing viva |
| `Appointment` | `domain/entities/appointment.dart` | from/to JSON, copyWith | enum parsing |
| `Transaction` | `domain/entities/transaction.dart` | from/to JSON, copyWith | enum parsing |
| `Payment` | no encontrado | n/a | usar `Transaction` |
| `FoodDetails`/`FoodSearchResult` | `food_database_feature/models/food_models.dart` | fromJson only | API-only, sin toJson/copyWith |

Compatibilidad SQLite: el cliente completo se guarda como JSON en tabla `clients`. Compatibilidad Firestore: `ClientFirestoreDataSource` sanitiza payload y whitelist de `training.extra`.

## 16. Estado UI

P1:

- `TrainingWorkspaceScreen`: `TabController(length: 6)` y `_v3TabController.animateTo(6)` en CTA de landmarks. Runtime probable.

P2:

- Tablas grandes existen pero las `DataTable` auditadas estan mayormente dentro de horizontal scroll (`series_distribution_screen`, `macrocycle_table`, `weekly_history_tab`).
- Muchas tablas `Table` usan columnas fijas/flex; riesgo de overflow en mobile en nutricion/training si el contenedor no da ancho suficiente.
- UI tiene pantallas legacy compitiendo: `TrainingWorkspaceScreen`, `TrainingDashboardScreen`, `presentation/screens/training/motor_v3_dashboard_screen.dart`, V2/V3 widgets.

P3:

- Hay mojibake visible en comentarios/textos de varios archivos.
- Busqueda rough encontro posibles usos de context alrededor de `await` en modales de nutricion/macros; no se clasifican P1 sin analyzer.

## 17. Estado DB/sync

SQLite:

- DB: `hcs_app_lap_v4.db`.
- Version: 6.
- Tablas: `clients`, `workout_logs`, `app_state`, `training_interviews`, `sync_queue`.
- `clients`: `id`, `json`, `isSynced`, `isDeleted`, `updatedAt`.
- `training_interviews`: versionado por cliente, `data` JSON, `is_synced`.
- Migraciones: no destructivas para `workout_logs`, `training_interviews`, indices y columnas.

Sync:

- `getUnsyncedClients`: `isSynced = 0 AND isDeleted = 0`.
- `markClientAsSynced`: setea `isSynced = 1`.
- `SyncQueueHelper`: tabla `sync_queue`, retries, `markSuccess` borra item, `markFailure` incrementa retry.

Riesgos:

- Ciclo import real `database_helper` <-> `sync_queue_helper`.
- `ClientRepository.saveClient` guarda local y hace push remoto fire-and-forget; fallos remotos no rompen local.
- Dos rutas remotas compiten: `ClientFirestoreDataSource` usa `coaches/{coachId}/clients/{clientId}`, `RemoteClientDataSourceImpl` usa top-level `clients/{id}`.
- Firestore guarda payload filtrado y protege limite 900k, pero datos de salud siguen concentrados en payload de cliente.

## 18. Estado tests

Tests Dart listados: 76 bajo `test/`, incluyendo strict suites de registry/mapper/resolver/adapter/validators y regresiones D1R4-D1R8.

Ejecucion actual:

- `flutter test test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart --reporter expanded`: timeout 180s, sin resultado.
- Reintento con `--no-pub`: timeout 180s, sin resultado.
- `flutter --version`: timeout 60s.

Por bloqueo de Flutter tool no se ejecutaron las demas suites focalizadas ni `flutter test` completo para evitar timeouts repetidos. No se corrigio nada.

## 19. Resultado flutter analyze

Comando:

```powershell
flutter analyze --no-pub
```

Resultado actual: timeout 180s. No se obtuvo numero de issues ni `No issues found`.

Observacion: tras los timeouts quedaron procesos Dart y lockfiles en `C:\src\flutter\bin\cache\lockfile` y `flutter.bat.lock`. Se terminaron procesos Dart iniciados por estos comandos, pero no se borraron lockfiles por la regla de no borrar archivos.

## 20. Reportes existentes

Raiz: no hay `.md` fisicos, pero git muestra `D` para `AUDITORIA_LANDMARKS_VME_VMR_VOP.md`, `DATA_PERSISTENCE_AUDIT.md`, `OPTIMIZATION_SUMMARY.md`, `PERFORMANCE_AUDIT_SAVE.md`, `REAUDITORIA_ESTADO_ACTUAL_BLOQUE_1_ENTREVISTA.md`.

`lib/audit/`: existe y contiene reportes D1R5, D1-C5, D1R6, D1-C6, D1R7, D1-C7, D1R8 y full root previo.

`lib/_audit/`: `CODE_DEAD_INVENTORY.md`, `CORE_ENUMS_CONSTANTS_INVENTORY.md`.

`docs/audits/`: muchos reportes historicos Motor V3/catalogo/training, mas `generated_cases/`.

Ultimo MUSCLE SSOT: `AUDIT_MUSCLE_SSOT_D1R8_PAIRING_CALLSITES_FIXTURES_REPORT.md`. La secuencia D1 es consistente hasta D1R8, con la salvedad de que D1R8 fue proxy.

## 21. Riesgos criticos

- P1 UI runtime: `animateTo(6)` con `TabController(length: 6)`.
- Flutter tool bloqueado: no hay validacion actual de tests/analyze.
- `CycleTemplateBuilder` puede reintroducir raw/legacy justo antes de D1-C8.
- Rutas remotas duplicadas (`coaches/.../clients` vs top-level `clients`) pueden provocar incoherencia de sync si ambas se usan.

## 22. Riesgos medios

- Multiples fuentes de verdad de volumen (`vopSnapshot`, landmarks, `volumePerMuscle`, legacy targets).
- Entity/V3 duplicados para plan/week/session/prescription.
- `TrainingProfile.extra` concentra contratos historicos y actuales.
- `ExerciseCatalogV3` y `MotorV3Orchestrator` aun tienen normalizadores legacy fuera del scope D1-C8.
- `supportedAliases` en mapper documenta `glute` como soportado aunque runtime strict lo descarta.

## 23. Riesgos menores

- Assets no declarados en `assets/entrenamiento/`.
- Logs/zips viejos en raiz.
- Mojibake en comentarios/textos.
- `tool/` existe vacio.

## 24. Siguiente sprint recomendado

Primero: **sprint P1 aislado** para corregir `TrainingWorkspaceScreen` tab index y desbloquear validacion Flutter sin borrar archivos del repo.

Despues: **D1R9** con harness real de `CycleTemplateBuilder.buildBaseWeek`.

Luego: **D1-C8** sobre `CycleTemplateBuilder` strict si D1R9 + tests focalizados + analyze quedan verdes.

## 25. Que NO debe tocarse todavia

No tocar en el sprint inmediato: formulas de volumen, `WeeklyVolumePlanner`, `ExerciseSelectionEngine`, `SessionStructureEngine`, `PairingContract`, `AntagonistPairingEngine`, `MotorV3Orchestrator`, DB, modelos, repositorios, Firebase rules, catalogo productivo, UI fuera del P1 puntual, limpieza de reportes raiz.

## 26. Comandos ejecutados

```powershell
Select-String C:\Users\pedro\.codex\memories\MEMORY.md ...
Get-ChildItem -Force
git status --short
git -c safe.directory=C:/Users/pedro/StudioProjects/hcs_app_lap status --short
Get-Content pubspec.yaml
Get-Content analysis_options.yaml
Get-ChildItem lib/audit, lib/_audit, docs/audits
rg --version
python read-only structural audit scripts
rg MUSCLE SSOT patterns
Get-Content target Dart files
Get-ChildItem -Recurse -File test -Filter *.dart
flutter test test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart --reporter expanded
flutter test test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart --reporter expanded --no-pub
flutter --version
flutter analyze --no-pub
Get-Process / Stop-Process for Dart processes spawned by timed-out commands
```

Timeouts:

- `flutter test ...pairing_callsites...`: 180s.
- `flutter test ...pairing_callsites... --no-pub`: 180s.
- `flutter --version`: 60s.
- `flutter analyze --no-pub`: 180s.

## 27. Conclusion operativa

No avanzar directo a D1-C8.

El repo esta semanticamente alineado hasta D1R8 en los archivos MUSCLE SSOT ya cerrados, pero el estado operativo actual es F por un P1 UI concreto y por validacion Flutter bloqueada. El orden correcto es: resolver P1/lock de validacion, correr tests/analyze, crear D1R9 con harness real de `buildBaseWeek`, y solo despues migrar `CycleTemplateBuilder` en D1-C8.
