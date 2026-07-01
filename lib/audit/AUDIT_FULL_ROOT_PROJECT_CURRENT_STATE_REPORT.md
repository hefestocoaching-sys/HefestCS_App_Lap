# AUDIT FULL ROOT PROJECT CURRENT STATE REPORT

Fecha local de auditoria: 2026-05-25
Repo: `c:\Users\pedro\StudioProjects\hcs_app_lap`
Modo: auditoria read-only. Unica escritura realizada: creacion de `lib/audit/` y este reporte.

## 1. Resumen ejecutivo

El proyecto esta en un estado funcionalmente avanzado para la linea MUSCLE SSOT. Las fases D1-A a D1-C4-C3 estan implementadas en los archivos objetivo y los tests focalizados solicitados pasan. `flutter analyze --no-pub` finalizo limpio con `No issues found!`.

El siguiente paso correcto es D1R5: fixtures/goldens observacionales para `ExerciseSelectionEngine`, sin migrar todavia. Motivo: `ExerciseSelectionEngine` y varias rutas de pipeline V3 aun usan normalizacion legacy permisiva (`muscle_registry.normalize(...) ?? key/raw`) y deben congelarse antes de migrarse.

Riesgos principales:

- El worktree esta sucio antes de esta auditoria: hay muchos archivos `M`/`D`/`??` en git status. No se revirtio nada.
- `flutter test --reporter expanded` completo no termino en 600 segundos; no hay baseline global verde.
- Hay un bug UI probable: `TrainingWorkspaceScreen` crea `TabController(length: 6)` y luego llama `_v3TabController.animateTo(6)`, indice fuera de rango.
- Existe un ciclo real de imports: `database_helper.dart` <-> `sync_queue_helper.dart`.
- Android, iOS y web no existen en la raiz actual; solo estan `windows`, `macos` y `linux`.

## 2. Estado final: A/B/C/D/E

Estado final: **ESTADO A, con reservas operativas**.

Criterio cumplido para A:

- Repo alineado hasta D1-C4-C3 en los archivos/fases auditadas.
- Tests focalizados SSOT/regresion pasan.
- `flutter analyze --no-pub` limpio.
- Siguiente sprint recomendado: D1R5 fixtures/goldens observacionales para `ExerciseSelectionEngine`.

Reservas:

- `flutter test` completo dio timeout, no exito global.
- El worktree no esta limpio.
- Hay deuda raw passthrough fuera del alcance D1-C4-C3, especialmente `ExerciseSelectionEngine`, `CycleTemplateBuilder`, `SessionStructureEngine`, `MotorV3Orchestrator` y helpers legacy.

## 3. Evidencia corta del estado

- `lib/core/registry/muscle_registry.dart:5-20`: define los 14 musculos canonicos esperados.
- `lib/core/registry/muscle_registry.dart:268-304`: API estricta `tryNormalizeMuscleKey`, `normalizeMuscleKeyOrThrow`, `expandMuscleGroupStrict`.
- `lib/domain/training_v3/engines/weekly_volume_planner.dart:22-25`: normaliza `baseVop`, `mevByMuscle`, `mrvByMuscle`, `priorities`.
- `lib/domain/training_v3/engines/weekly_volume_planner.dart:177-184`: descarta unknowns si `tryNormalizeMuscleKey` retorna null.
- Tests focalizados: todos verdes.
- Analyze final: `No issues found! (ran in 23.9s)`.

## 4. Alcance auditado

Se audito:

- Raiz del proyecto.
- `pubspec.yaml`.
- `analysis_options.yaml`.
- Config Firebase/Firestore local.
- Assets declarados y fisicos.
- `lib/` completo a nivel estructural.
- `test/` completo a nivel estructural.
- Fases MUSCLE SSOT D1-A a D1-C4-C3.
- Pipeline Motor V3.
- Modelos criticos.
- UI principal bajo `lib/`.
- DB/sync/local/remote repositories.
- Reportes existentes.
- Tests focalizados solicitados.
- `flutter analyze --no-pub`.

No se modifico codigo productivo, UI, DB, modelos ni tests.

## 5. Archivos/carpetas raiz detectados

Carpetas raiz existentes:

- `.dart_tool`, `.git`, `.idea`, `.venv`, `.vs`, `.vscode`
- `assets`
- `build`
- `coverage`
- `docs`
- `integration_test`
- `lib`
- `linux`
- `macos`
- `test`
- `tool`
- `windows`

Carpetas plataforma:

- `windows`: existe.
- `macos`: existe.
- `linux`: existe.
- `android`: no existe.
- `ios`: no existe.
- `web`: no existe.

Archivos raiz importantes:

- `.firebaserc`
- `.flutter-plugins-dependencies`
- `.gitattributes`
- `.gitignore`
- `.liveui.json`
- `.metadata`
- `analysis_options.yaml`
- `build.yaml`
- `firebase.json`
- `firebase.json.bak`
- `firestore.indexes.json`
- `firestore.rules`
- `pubspec.lock`
- `pubspec.yaml`
- `lib.zip`
- logs: `build_output.log`, `debug_build.log`, `error_log.txt`, `final_analysis.txt`, `flutter_analyze.txt`, `run_output.log`
- script raiz: `fix_utf8_encoding.py`

Firebase:

- `.firebaserc`: default project `hcseco-55882`.
- `firebase.json`: Firestore rules/indexes, emulators auth/firestore/ui, Flutter Windows config en `lib/firebase_options.dart`.
- `lib/firebase_options.dart`: existe.

Assets declarados en `pubspec.yaml`:

- `assets/Logos/`: existe.
- `assets/data/`: existe.
- `assets/data/exercises/exercise_catalog_gym.json`: existe.
- `assets/data/training_v3/catalog/`: existe.
- `assets/media/exercises/gifs/`: existe.

Assets fisicos:

- Total archivos bajo `assets/`: 1480.
- `assets/Logos`: 1.
- `assets/data`: 15.
- `assets/data/training_v3/catalog`: 8.
- `assets/media/exercises/gifs`: 1324.
- `assets/entrenamiento`: 140 archivos fisicos no declarados por `pubspec.yaml`.

## 6. Auditoria estructural Dart

Totales:

- Dart files en `lib/`: 684.
- Dart files en `test/`: 72.
- Directivas Dart auditadas: 2890.
- Imports internos relativos tipo `import '../'`: 0.
- Exports relativos tipo `export '../'`: 0.
- `part`/`part of` relativos: 0.
- Imports package internos rotos: 0.
- Imports a archivos inexistentes: 0.
- Archivos Dart vacios: 0.

Ciclo de imports real:

- `lib/data/datasources/local/database_helper.dart -> lib/data/datasources/local/sync_queue_helper.dart -> lib/data/datasources/local/database_helper.dart`

Duplicados nominales relevantes:

- `database_helper.dart`: `lib/data/datasources/local/database_helper.dart`, `lib/services/database_helper.dart`.
- `training_plan_config.dart`: entity y modelo V3.
- `training_plan.dart`: entity y modelo V3.
- `training_week.dart`: entity y modelo V3.
- `training_session.dart`: entity y modelo V3.
- `exercise_prescription.dart`: entity y modelo V3.
- `client_profile.dart`: entity y modelo V3.
- `volume_landmarks.dart`: constants/modelos duplicados.
- `muscle_keys.dart`: `core/constants` y `core/utils`.
- `biochemistry_tab.dart`: feature biochemistry e history clinic.
- `macrocycle_week.dart`: entity y training.

Archivos legacy/deprecated detectados:

- `lib/core/constants/training_interview_legacy_keys.dart`
- `lib/core/utils/muscle_key_normalizer.dart`
- `lib/data/datasources/local/exercise_catalog_loader.dart` marcado `@Deprecated`.
- `lib/domain/training_v3/ml_integration/hybrid_orchestrator_v3.dart` marcado deprecated.
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart` contiene `_buildSessions` deprecated.
- Tests `.bak`: 5 archivos bajo `test/training_v3/`.

## 7. Auditoria pubspec

Paquete:

- Nombre: `hcs_app_lap`
- Version: `2.0.0+8`
- `publish_to: none`
- Dart SDK: `^3.9.2`
- Version minima Flutter: no aparece declarada como constraint separado.

Dependencies directas:

- Flutter SDK: `flutter`, `flutter_localizations`
- HTTP/localizacion/UI: `http`, `intl`, `cupertino_icons`, `fl_chart`, `google_fonts`, `url_launcher`
- Estado: `provider`, `riverpod`, `flutter_riverpod`, `riverpod_annotation`
- Firebase: `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_analytics`, `firebase_app_check`
- SQLite/files: `sqflite_common_ffi`, `sqflite`, `path_provider`, `path`
- PDF/CSV: `pdf`, `printing`, `csv`
- Modelado/utilidades: `collection`, `equatable`, `freezed_annotation`, `json_annotation`, `uuid`, `synchronized`, `shared_preferences`, `meta`
- Forms/env: `flutter_form_builder`, `form_builder_validators`, `flutter_dotenv`

Dev dependencies:

- `flutter_test`, `integration_test`
- `flutter_lints`
- `build_runner`
- `riverpod_generator`
- `freezed`
- `json_serializable`
- `mocktail`
- `fake_async`
- `mockito`

Dependency overrides:

- No se encontraron `dependency_overrides`.

Riesgos:

- Se usan `provider`, `riverpod` y `flutter_riverpod` a la vez; riesgo de multiples patrones de estado.
- Se usan `mocktail` y `mockito` a la vez; riesgo de doble estilo de mocks.
- `assets/entrenamiento` existe fisicamente pero no esta declarado en assets.
- No se ejecuto consulta externa a pub.dev por restriccion de auditoria local; no se afirma obsolescencia real de versiones.

## 8. Auditoria analysis_options

Config:

- Incluye `package:flutter_lints/flutter.yaml`.
- Eleva a error:
  - `use_build_context_synchronously`
  - `avoid_print`

Reglas custom activas:

- `avoid_print`
- `use_build_context_synchronously`
- `prefer_const_constructors`
- `prefer_const_constructors_in_immutables`
- `prefer_const_declarations`
- `prefer_const_literals_to_create_immutables`
- `avoid_unnecessary_containers`
- `sized_box_for_whitespace`
- `use_key_in_widget_constructors`
- `avoid_redundant_argument_values`
- `unnecessary_string_interpolations`
- `unnecessary_this`
- `public_member_api_docs: false`

Excludes:

- `**/*.g.dart`
- `**/*.freezed.dart`

Riesgo:

- Los excludes de generados son normales.
- `public_member_api_docs: false` es permisivo pero razonable para app interna.
- No se ocultan carpetas productivas completas.

## 9. Auditoria Muscle SSOT por fase

Archivos minimos revisados:

- `lib/core/registry/muscle_registry.dart`
- `lib/features/training_feature/domain/exercise_preferences_muscle_key_mapper.dart`
- `lib/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart`
- `lib/domain/training_v3/utils/muscle_key_adapter_v3.dart`
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart`
- `lib/domain/training/models/mev_table.dart`
- `lib/domain/training/validation/vop_validator.dart`
- `lib/domain/training_v3/validators/volume_validator.dart`
- `lib/domain/training_v3/engines/landmark_engine.dart`
- `lib/domain/training_v3/engines/muscle_priority_engine.dart`
- `lib/domain/training_v3/engines/weekly_volume_planner.dart`

Hallazgos por archivo:

| Archivo | tryNormalize | expandStrict | legacy normalize | raw passthrough | Estado |
|---|---:|---:|---:|---:|---|
| `muscle_registry.dart` | si | si | mantiene wrapper legacy | no en API estricta | aplicado |
| `exercise_preferences_muscle_key_mapper.dart` | si | no requerido | no | no | aplicado |
| `muscle_to_catalog_resolver.dart` | si | si | no | no | aplicado |
| `muscle_key_adapter_v3.dart` | si | si | no | no | aplicado |
| `training_plan_forensic_validator.dart` | si | no requerido | no para mapas auditados | no en mapas normalizados | aplicado |
| `mev_table.dart` | si | no requerido | no | no | aplicado |
| `vop_validator.dart` | si | no requerido | no | no | aplicado |
| `volume_validator.dart` | si | si | no | no para unknowns | aplicado con excepcion legacy de grupos agregados |
| `landmark_engine.dart` | si | no requerido | no | no | aplicado |
| `muscle_priority_engine.dart` | si | no requerido | no | no | aplicado |
| `weekly_volume_planner.dart` | si | no requerido | no | no | aplicado |

Evidencia puntual:

- `muscle_registry.dart:268-283`: unknowns retornan null.
- `exercise_preferences_muscle_key_mapper.dart:34-49`: `tryNormalizeMuscleKey`, warning y null.
- `muscle_to_catalog_resolver.dart:40-41`: `expandMuscleGroupStrict(...) ?? []`.
- `muscle_to_catalog_resolver.dart:57-64`: wrapper legacy retorna `''`, strict retorna `String?`.
- `muscle_key_adapter_v3.dart:43-44`: strict expansion o lista vacia.
- `training_plan_forensic_validator.dart:1320-1330`: unknown agrega issue y retorna null.
- `mev_table.dart:10-20`: seed descarta unknown y `getMev` unknown retorna `0.0`.
- `vop_validator.dart:54-70`: planned/base unknowns se ignoran.
- `volume_validator.dart:47-64`: canonico, legacy group o expand; unknown retorna.
- `landmark_engine.dart:117-152`: serialize/parse/extract usan canonical keys.
- `muscle_priority_engine.dart:88-103`: normaliza mapas y descarta null.
- `weekly_volume_planner.dart:22-25`, `177-184`: normaliza mapas y descarta null.

Nota SSOT:

- `glute` no esta en `_strictMuscleAliases`; los tests lo tratan como unknown.
- `gluteos` normaliza a `glutes`.
- Registry mantiene aliases legacy mas amplios para `normalize`, pero la API estricta usa allowlist separada.

## 10. Tabla D1-A a D1-C4-C3

| Fase | Estado | Archivos | Evidencia | Riesgo |
|---|---|---|---|---|
| D1-A | aplicado | `muscle_registry.dart`, `muscle_registry_strict_test.dart` | API estricta y tests verdes | bajo |
| D1-C1 | aplicado | `exercise_preferences_muscle_key_mapper.dart` | unknowns retornan null; suite verde | bajo |
| D1-C2 | aplicado | resolver + adapter V3 | `tryNormalizeMuscleKey`, `expandMuscleGroupStrict`, sin raw fallback | bajo |
| D1-C3 | aplicado | `training_plan_forensic_validator.dart` | warnings forenses no bloqueantes; unknowns fuera de mapas | bajo |
| D1-C4-A1 | aplicado | `mev_table.dart` | seed descarta unknown; unknown getMev 0.0 | bajo |
| D1-C4-A2 | aplicado | `vop_validator.dart` | unknowns no entran a stimulus/uncovered | bajo |
| D1-C4-B | aplicado con excepcion | `volume_validator.dart` | unknowns descartados; grupos agregados `back/shoulders/arms/legs` preservados por test | medio |
| D1-C4-C1 | aplicado | `landmark_engine.dart` | parse/extract/serialize strict; tests verdes | bajo |
| D1R3 | aplicado | fixtures/tests muscle priority | 6 tests regression actuales | bajo |
| D1-C4-C2 | aplicado | `muscle_priority_engine.dart` | no raw passthrough; orden/rotacion preservados | bajo |
| D1R4 | aplicado | `test/fixtures/training_v3/weekly_volume/` | 5 fixtures presentes | bajo |
| D1-C4-C3 | aplicado | `weekly_volume_planner.dart` | normaliza 4 mapas, trace canonico, tests verdes | bajo |

## 11. Raw passthrough restante

Seguro / permitido:

- `training_plan_forensic_validator.dart:1301`, `1308`: `tryNormalizeMuscleKey(...) ?? ''`; contrato evita raw.
- `muscle_to_catalog_resolver.dart:57-64`: unknown retorna `''`/null.
- `muscle_key_adapter_v3.dart:49-76`: unknown retorna `''`/null.

Legacy permitido pero no contrato nuevo:

- `lib/core/registry/muscle_registry.dart:308+`: `normalize` legacy.
- `lib/core/registry/muscle_registry.dart:465+`: `expandGroup` legacy.
- `lib/core/utils/muscle_key_normalizer.dart`: wrapper legacy.

Riesgo / requiere migracion futura:

- `lib/core/utils/muscle_key_normalizer.dart:50`: `return raw.toLowerCase();`.
- `lib/domain/training_v3/engines/exercise_selection_engine.dart:50-53`: `muscle_registry.normalize(key) ?? key`.
- `lib/domain/training_v3/engines/session_structure_engine.dart:433-437`: fallback a `raw.trim().toLowerCase()`.
- `lib/domain/training_v3/services/cycle_template_builder.dart:1084-1085`: `normalize(k) ?? k.trim().toLowerCase()`.
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart:6`: importa legacy `muscle_key_normalizer.dart`.
- `motor_v3_orchestrator.dart:2286-2296`: `_canonicalMuscleKey` puede retornar `raw.trim().toLowerCase()`.
- `motor_v3_orchestrator.dart:2786`: `muscle_registry.normalize(muscle) ?? muscle`.
- `lib/domain/training_v3/services/weekly_progression_service_impl.dart:449`: `normalize(muscle) ?? muscle`.
- `lib/domain/training_v3/data/exercise_catalog_v3.dart:45-47`: fallback a raw lower.
- `lib/domain/training/services/active_cycle_bootstrapper.dart:157`: `normalize(raw) ?? raw`.

Clasificacion:

- D1-C4-C3 no esta bloqueado.
- D1R5 debe congelar `ExerciseSelectionEngine` antes de corregir ese raw passthrough.
- Una fase posterior deberia migrar `CycleTemplateBuilder`/`MotorV3Orchestrator` con fixtures previos.

## 12. Estado de WeeklyVolumePlanner

Estado: aplicado D1-C4-C3.

Evidencia:

- `buildWeekVolume` normaliza `baseVop`, `mevByMuscle`, `mrvByMuscle`, `priorities`.
- Unknowns se descartan en `_normalizeMuscleIntMap`.
- Alias canonico + alias usa last-write-wins por orden de entrada del map.
- `buildDecisionTrace` devuelve trace con keys ya normalizadas.
- Tests:
  - `weekly_volume_planner_fixtures_regression_test.dart`: 8 tests verdes.
  - `weekly_volume_planner_current_behavior_test.dart`: 4 tests verdes.

Formulas preservadas:

- Accumulation usa `VolumeProgression.getIncrement` y `getWeeksInterval`.
- Intensification usa `0.90`.
- Deload usa `0.50`.
- MEV/MRV clamping sigue dentro de la logica existente.

## 13. Estado de ExerciseSelectionEngine

Estado: no migrado a SSOT estricto; candidato directo para D1R5 observacional.

Evidencia:

- `lib/domain/training_v3/engines/exercise_selection_engine.dart:50-53`: normaliza con `muscle_registry.normalize(key) ?? key`.
- Ese fallback permite raw passthrough.
- `toCatalogKeys` sigue vivo via adapter/resolver, pero `ExerciseSelectionEngine` tiene normalizador propio.

Siguiente correcto:

- D1R5: crear fixtures/goldens observacionales para `ExerciseSelectionEngine`.
- No migrar todavia.
- No tocar Motor V3, UI ni DB en ese sprint.

## 14. Estado del pipeline Motor V3

Pipeline real:

- `TrainingProfile.extra`: fuente de entradas historicas y actuales; contiene `activePlanId`, `muscleLandmarks`, `vopSnapshot` via `TrainingExtraKeys`.
- `TrainingExtraKeys.activePlanId`: `lib/core/constants/training_extra_keys.dart:63`.
- `TrainingExtraKeys.muscleLandmarks`: `training_extra_keys.dart:150-151`.
- `TrainingExtraKeys.vopSnapshot`: `training_extra_keys.dart:159`.
- `TrainingPlanConfig` tipado principal para UI: `lib/domain/entities/training_plan_config.dart`.
- Modelo V3 alterno: `lib/domain/training_v3/models/training_plan_config.dart` es mas liviano y sin from/to JSON.
- `TrainingPlanProvider.loadPersistedActivePlanIfAny`: carga plan persistido por `activePlanId` o mas reciente sin generar.
- `TrainingPlanProvider.generatePlanFromActiveCycle`: genera y persiste plan nuevo.
- `TrainingOrchestratorV3` delega a `MotorV3Orchestrator`.
- `MotorV3Orchestrator.generateProgram`: calcula volumen, split, sesiones, validaciones y plan.
- `CycleTemplateBuilder.buildBaseWeek`: construye base week y usa `ExerciseSelectionEngine`.
- `ExerciseSelectionEngine`: selecciona ejercicios.
- `SessionStructureEngine`: estructura/refina sesion.
- `TrainingPlanForensicValidator`: valida target vs assigned y warnings.

Respuestas puntuales:

- Donde se calcula VME/VOP/VMR: `LandmarkEngine`, `VolumeLandmarksCalculator`, `VolumeEngine` y `TrainingPlanProvider` al derivar `vopSnapshot`/landmarks.
- Donde se guarda `vopSnapshot`: `TrainingExtraKeys.vopSnapshot` y `features/training_feature/context/vop_context.dart`.
- Donde se calcula volumen semanal: `WeeklyVolumePlanner`; Motor V3 consume mapas de volumen y aplica normalizacion/feasibility.
- Donde se seleccionan ejercicios: `ExerciseSelectionEngine`, llamado por `CycleTemplateBuilder`.
- Donde se estructura sesion: `SessionStructureEngine` y `CycleTemplateBuilder`.
- Donde se valida target vs assigned: `TrainingPlanForensicValidator`, `VopValidator`, checks internos de `MotorV3Orchestrator`.
- Donde se persiste `TrainingPlanConfig`: `TrainingPlanProvider.generatePlanFromActiveCycle`, guardando en `client.trainingPlans`.
- Donde se actualiza `activePlanId`: `TrainingPlanProvider` lineas 1339-1344 y `updateActivePlanId`.
- Donde la UI lee el plan: `TrainingWorkspaceScreen`, `TrainingDashboardScreen`, `training_workspace_provider.dart`, `training_plan_provider.dart`.
- Riesgo de regeneracion al abrir pantalla: bajo. La carga persistida no genera; la generacion ocurre por acciones explicitas. Hay logs que dicen "Regenerando" dentro del flujo de accion.
- Multiples fuentes de verdad para volumen: si, `volumePerMuscle`, `extra.volume_targets`, `muscleLandmarks`, `vopSnapshot`, legacy `baseExercisesByMuscle`.
- Lectura legacy que compite con V3: si, fallback de `vopSnapshot` a `baseExercisesByMuscle`, modelos V2/V3 duplicados y conversion `TrainingPlanMapper.toGeneratedPlan`.

## 15. Estado modelos criticos

| Modelo | Archivo | Serializacion | copyWith | Riesgo |
|---|---|---|---|---|
| Client | `lib/domain/entities/client.dart` | from/to Map y JSON | si | modelo grande con muchos imports, alto blast radius |
| AnthropometryRecord | `anthropometry_record.dart` | from/to JSON | si | sin fromMap/toMap nominal |
| BioChemistryRecord | `biochemistry_record.dart` | from/to JSON | no | copyWith ausente |
| NutritionPlan | no existe como clase exacta | usa `DailyNutritionPlan` | si | naming pedido no coincide con entidad real |
| DailyNutritionPlan | `daily_nutrition_plan.dart` | from/to Map y JSON | si | ok |
| TrainingProfile | `training_profile.dart` | from/to JSON | si | extra legacy amplio, normaliza musculos por helper legacy |
| TrainingPlanConfig entity | `domain/entities/training_plan_config.dart` | from/to Map y JSON | si | fuente principal UI |
| TrainingPlanConfig V3 | `domain/training_v3/models/training_plan_config.dart` | no from/to JSON | no | duplicado liviano, requiere conversion |
| TrainingWeek entity | `domain/entities/training_week.dart` | from/to Map y JSON | si | duplicado V3 |
| TrainingWeek V3 | `domain/training_v3/models/training_week.dart` | no from/to JSON | no | depende de conversion externa |
| TrainingSession entity | `domain/entities/training_session.dart` | from/to JSON | si | alias `exercises => prescriptions` |
| TrainingSession V3 | `domain/training_v3/models/training_session.dart` | from/to Map y JSON | si | ok |
| TrainingExercise | clase exacta no encontrada | usa `ExercisePrescription`/`PlannedExercise` | n/a | naming mismatch |
| Appointment | `appointment.dart` | from/to JSON | si | ok |
| Payment | clase exacta no encontrada | usa `Transaction` | n/a | naming mismatch |
| Transaction | `transaction.dart` | from/to JSON | si | ok |
| FoodDetails/FoodSearchResult | `food_models.dart` | fromJson parcial | no | sin toJson/copyWith |

Riesgo principal de modelos:

- Duplicidad entity/V3 en training.
- V3 model `TrainingPlanConfig` no serializa; la entidad si.
- Varias UI/repos dependen de conversiones V3->V2 para compatibilidad.

## 16. Estado UI

Navegacion principal:

- `MainShellScreen` monta `WorkspaceHomeScreen` como Home activo en index 0.
- `DashboardScreen` existe como legacy/alterno.
- `TrainingScreen` monta `TrainingWorkspaceRoot`.
- Navegacion lateral usa `GlobalSideNavigationRail`.

Tabs entrenamiento:

- `TrainingWorkspaceScreen`: `TabController(length: 6)`.
- `TrainingDashboardScreen`: TabController propio para dashboard/plan.
- `MotorV3DashboardScreen` en `presentation/screens/training` tiene 8 tabs, parece pantalla alternativa.

Riesgos UI:

- Critico: `TrainingWorkspaceScreen:1791` llama `_v3TabController.animateTo(6)` con length 6. Indices validos: 0-5. Probable runtime assertion al pulsar CTA de landmarks.
- `TrainingWorkspaceScreen` y `TrainingDashboardScreen` son grandes y con muchas responsabilidades.
- Hay muchas tablas/listas; algunas tienen scroll horizontal (`weekly_history_tab` usa `SingleChildScrollView` horizontal para `DataTable`), pero otras deben revisarse visualmente con viewport real.
- `workspace_home_screen.dart` usa heights fijos para cards principales; mitigado con `LayoutBuilder`, pero requiere screenshot/manual QA para desktop/tablet.
- `dietary_activity_section.dart` tiene comentarios de overflow mitigado con altura fija 325px; riesgo de contenido largo/localizacion.

Deprecated APIs:

- No se detectaron APIs Flutter antiguas como `RaisedButton`, `FlatButton`, `OutlineButton`.
- Hay uso de `DropdownButton`/`DropdownButtonFormField`, valido pero no Material 3 estricto.

## 17. Estado DB/sync

DB local:

- `DatabaseHelper`: `lib/data/datasources/local/database_helper.dart`.
- DB: `hcs_app_lap_v4.db`.
- Version: 6.
- Tablas:
  - `clients`
  - `workout_logs`
  - `app_state`
  - `training_interviews`
  - `sync_queue`

SQLite:

- `clients` guarda JSON completo en columna `json`.
- Indices para synced/deleted/updated.
- `training_interviews` tiene `is_synced` y FK a clients.
- Upgrade es no destructivo y agrega columnas si faltan.
- WAL, foreign_keys y busy_timeout activados.

Sync:

- `getUnsyncedClients`: existe en `DatabaseHelper` y datasource local.
- `markClientAsSynced`: existe.
- `markAsSynced`: no existe con ese nombre exacto.
- `SyncQueueHelper.markSuccess` borra item de cola.
- `SyncQueueHelper.markFailure` incrementa retry_count.

Ciclo:

- `database_helper.dart` importa `sync_queue_helper.dart`.
- `sync_queue_helper.dart` importa `database_helper.dart`.
- Riesgo: acoplamiento local fuerte, inicializacion circular potencial y dificultad de test.

Firebase/offline-first:

- `ClientRepository` guarda local primero y hace push remoto silencioso.
- `ClientFirestoreDataSource` sanitiza payload y audita limite de documento.
- Repositorios clinicos empujan subcolecciones por dominio y no bloquean si Firestore falla.

Riesgos:

- Cliente completo como JSON blob puede crecer demasiado para Firestore/documentos.
- Hay doble camino remote datasource (`remote_client_datasource_impl` y `client_firestore_datasource`).
- Sync granular y sync de cliente completo pueden competir si no hay orden claro.

## 18. Estado tests

Inventario:

- 72 archivos `.dart` bajo `test/`.
- 6 regression tests bajo `test/domain/training_v3/regression`.
- 5 fixtures weekly volume bajo `test/fixtures/training_v3/weekly_volume`.
- 5 archivos `.bak` bajo `test/training_v3/`.

Resultados ejecutados:

1. `flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded`
   - Resultado: verde.
   - `00:00 +8: All tests passed!`

2. `flutter test test/domain/training_v3/regression/weekly_volume_planner_current_behavior_test.dart --reporter expanded`
   - Resultado: verde.
   - `00:00 +4: All tests passed!`

3. Regression combinado Landmark/MusclePriority/WeeklyVolume:
   - Resultado: verde.
   - `00:00 +23: All tests passed!`

4. Suite estricta registry/mapper/resolver/adapter/validator/MEV/VOP/VolumeValidator:
   - Resultado: verde.
   - `00:01 +55: All tests passed!`

5. `flutter test --reporter expanded`
   - Resultado: timeout.
   - Corte: `command timed out after 600236 milliseconds`.
   - No se afirma exito ni fallo funcional global.

## 19. Resultado flutter analyze

Primer intento:

- `flutter analyze --no-pub`
- Timeout: `command timed out after 184041 milliseconds`.

Segundo intento:

- `flutter analyze --no-pub`
- Resultado exacto: `No issues found! (ran in 23.9s)`

Conclusion analyze:

- Baseline analyzer actual limpio.

## 20. Reportes existentes

Raiz actual:

- No hay archivos `.md` en la raiz actual.

Git status muestra reportes raiz trackeados como borrados antes de esta auditoria:

- `AUDITORIA_LANDMARKS_VME_VMR_VOP.md`
- `DATA_PERSISTENCE_AUDIT.md`
- `OPTIMIZATION_SUMMARY.md`
- `PERFORMANCE_AUDIT_SAVE.md`
- `REAUDITORIA_ESTADO_ACTUAL_BLOQUE_1_ENTREVISTA.md`

`lib/audit/`:

- No existia al iniciar esta auditoria.
- Se creo para este reporte.

`lib/_audit/`:

- `CODE_DEAD_INVENTORY.md`
- `CORE_ENUMS_CONSTANTS_INVENTORY.md`

`docs/audits/`:

- 42 reportes `.md`.
- Mas recientes:
  - `isak_anthropometry_formula_audit.md`
  - `forensic_global_app_audit.md`
  - varios reportes Motor V3 del 2026-04-19.

Secuencia:

- Hay reportes historicos en `docs/audits` y `lib/_audit`.
- La regla nueva de esta auditoria queda aplicada: reportes nuevos en `lib/audit/`.

## 21. Riesgos criticos

1. Worktree sucio antes del reporte:
   - Muchos archivos `M`, `D`, `??`.
   - Riesgo de auditar un estado no consolidado.

2. `flutter test` completo no termina en 600 segundos:
   - No hay evidencia de suite global verde.

3. Bug UI probable:
   - `TrainingWorkspaceScreen` usa `TabController(length: 6)` y `animateTo(6)`.
   - Puede fallar en runtime al confirmar landmarks.

4. Raw passthrough fuera de fases cerradas:
   - Especialmente `ExerciseSelectionEngine`, `CycleTemplateBuilder`, `SessionStructureEngine`, `MotorV3Orchestrator`.

## 22. Riesgos medios

- Ciclo DB/sync: `database_helper.dart` <-> `sync_queue_helper.dart`.
- Multiples fuentes de verdad de volumen (`volumePerMuscle`, `vopSnapshot`, `muscleLandmarks`, `extra.volume_targets`).
- Duplicidad entity/V3 para modelos de entrenamiento.
- `VolumeValidator` preserva grupos agregados legacy por test; compatible, pero no 100% canonico.
- `assets/entrenamiento` no declarado.
- Android/iOS/web ausentes si se espera app multiplataforma movil/web.

## 23. Riesgos menores

- `.bak` tests bajo `test/training_v3`.
- Logs y zips en raiz (`lib.zip`, logs varios).
- `firebase.json.bak` en raiz.
- `public_member_api_docs: false`.
- Doble stack de estado (`provider` y Riverpod).
- Doble stack de mocks (`mocktail` y `mockito`).

## 24. Siguiente sprint recomendado

Recomendacion: **D1R5**.

Alcance D1R5:

- Fixtures/goldens observacionales para `ExerciseSelectionEngine`.
- Congelar comportamiento actual antes de migrar.
- Cubrir canonical, aliases validos, unknowns, mixed, `glute`, grupos, catalog runtime y decision/order behavior.
- No tocar formulas, Motor V3, UI, DB ni persistencia.
- No corregir todavia raw passthrough.

## 25. Que NO debe tocarse todavia

No tocar en D1R5:

- Motor V3 completo.
- `CycleTemplateBuilder`.
- `SessionStructureEngine`.
- `MotorV3Orchestrator`.
- UI.
- DB/sync.
- Modelos.
- Repositorios.
- Persistencia de `TrainingPlanConfig`.
- `activePlanId`.
- Limpieza de reportes historicos.
- Assets no declarados.
- Android/iOS/web scaffolding.

## 26. Comandos ejecutados

Comandos de auditoria read-only usados, en forma resumida:

```powershell
Get-ChildItem -Force
Get-Content pubspec.yaml
Get-Content analysis_options.yaml
Get-Content firebase.json
Get-Content .firebaserc
rg -n "tryNormalizeMuscleKey|expandMuscleGroupStrict|normalizeMuscleKey|raw.toLowerCase|..."
git -c safe.directory=C:/Users/pedro/StudioProjects/hcs_app_lap status --short
```

Tests ejecutados:

```powershell
& C:\src\flutter\bin\flutter.bat test test\domain\training_v3\regression\weekly_volume_planner_fixtures_regression_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\domain\training_v3\regression\weekly_volume_planner_current_behavior_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\domain\training_v3\regression\landmark_engine_current_behavior_test.dart test\domain\training_v3\regression\landmark_engine_profile_extra_regression_test.dart test\domain\training_v3\regression\muscle_priority_engine_current_behavior_test.dart test\domain\training_v3\regression\muscle_priority_engine_priority_fixtures_regression_test.dart test\domain\training_v3\regression\weekly_volume_planner_current_behavior_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\core\registry\muscle_registry_strict_test.dart test\features\training_feature\domain\exercise_preferences_muscle_key_mapper_strict_test.dart test\domain\training_v3\resolvers\muscle_to_catalog_resolver_strict_test.dart test\domain\training_v3\utils\muscle_key_adapter_v3_strict_test.dart test\domain\training_v3\validators\training_plan_forensic_validator_muscle_ssot_test.dart test\domain\training\models\mev_table_strict_muscle_test.dart test\domain\training\validation\vop_validator_strict_muscle_test.dart test\domain\training_v3\validators\volume_validator_strict_muscle_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test --reporter expanded
```

Analyze:

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Escritura permitida por la tarea:

```powershell
New-Item -ItemType Directory -Force lib\audit
```

## 27. Conclusion operativa

El repo esta listo para avanzar a D1R5, no para migrar directamente `ExerciseSelectionEngine`.

La linea D1-A a D1-C4-C3 esta cerrada en comportamiento focalizado: API estricta, registry, mapper, resolver, adapter, forensic validator, MEV/VOP/VolumeValidator, LandmarkEngine, MusclePriorityEngine y WeeklyVolumePlanner pasan sus tests. `flutter analyze --no-pub` esta limpio.

La accion correcta es congelar `ExerciseSelectionEngine` con fixtures/goldens observacionales y despues decidir su migracion strict. Antes de trabajo visual o DB, conviene resolver el bug de `animateTo(6)` y obtener un baseline manejable del `flutter test` completo o dividirlo en suites.
