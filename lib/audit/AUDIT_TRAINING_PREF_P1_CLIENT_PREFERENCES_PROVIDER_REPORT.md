# AUDIT TRAINING-PREF-P1 CLIENT PREFERENCES PROVIDER REPORT

## 1. Resumen ejecutivo

Se corrigio `clientPreferencesEffectProvider` para que lea el cliente activo desde
`clientsProvider` y resuelva preferencias reales desde
`Client.training.extra[TrainingExtraKeys.exercisePreferencesByMuscle]`.

El provider ya no devuelve siempre preferencias vacias cuando existe cliente
activo. La lectura es defensiva, no escribe estado, no toca Firestore, no toca
SQLite y no dispara sync.

Estado de validacion:

- `clients_provider_hardening_test.dart`: PASA.
- `client_repository_outbox_test.dart`: PASA.
- `flutter analyze --no-pub`: PASA, `No issues found!`.
- `client_preferences_effect_provider_test.dart`: creado y estructuralmente
  aislado, pero su ejecucion se colgo dos veces sin salida y fue cancelada segun
  protocolo. Despues del segundo cancelado se agrego inicializacion explicita
  de `TestWidgetsFlutterBinding`; no se reejecuto por el limite de un reintento.

Veredicto: `TRAINING-PREF-P1 PARCIAL`.

## 2. Riesgo P1 original

La auditoria global habia detectado que:

`lib/features/training_feature/providers/client_preferences_effect_provider.dart`

retornaba:

```dart
return const ExercisePreferencesByMuscle();
```

aunque hubiera cliente activo. Eso podia hacer que las preferencias reales del
cliente no afectaran la seleccion/personalizacion de ejercicios.

## 3. Flujo anterior

Archivo anterior:

`lib/features/training_feature/providers/client_preferences_effect_provider.dart`

Comportamiento:

- Observaba `clientsProvider`.
- Si no habia cliente activo retornaba `null`.
- Si habia cliente activo retornaba siempre `const ExercisePreferencesByMuscle()`.
- No leia `client.training.extra`.
- No usaba `TrainingExtraKeys.exercisePreferencesByMuscle`.

## 4. Flujo nuevo

Nuevo flujo:

1. `clientPreferencesEffectProvider` observa `clientsProvider`.
2. En `data`, toma `state.activeClient`.
3. Llama `resolveClientExercisePreferences(state.activeClient)`.
4. La funcion lee:
   `client.training.extra[TrainingExtraKeys.exercisePreferencesByMuscle]`.
5. Parsea con `ExercisePreferencesByMuscle.fromDynamic(raw)`.
6. Si no hay cliente, no hay key o el payload esta mal formado, devuelve
   `const ExercisePreferencesByMuscle()`.

## 5. Fuente canonica real de preferencias

Fuente canonica encontrada:

```dart
Client.training.extra[TrainingExtraKeys.exercisePreferencesByMuscle]
```

Key exacta:

```dart
TrainingExtraKeys.exercisePreferencesByMuscle
```

Valor real de la key:

```dart
'exercisePreferencesByMuscle'
```

## 6. Key exacta usada

Definida en:

`lib/core/constants/training_extra_keys.dart`

```dart
static const exercisePreferencesByMuscle = 'exercisePreferencesByMuscle';
```

## 7. Modelo/parser usado

Modelo:

`lib/features/training_feature/domain/exercise_preferences_models.dart`

Parser existente:

```dart
static ExercisePreferencesByMuscle fromDynamic(dynamic raw)
```

Comportamiento del parser:

- Si `raw is! Map`, devuelve `const ExercisePreferencesByMuscle()`.
- Normaliza cada key a `String.trim()`.
- Cada bucket usa `ExercisePreferenceBucket.fromDynamic`.
- Solo conserva buckets con `hasAny == true`.

No se modifico el modelo porque ya tenia parser defensivo y `toJson()`.

## 8. Comportamiento sin cliente activo

Devuelve:

```dart
const ExercisePreferencesByMuscle()
```

No lanza excepcion.

## 9. Comportamiento sin preferencias guardadas

Si `training.extra` no contiene la key
`TrainingExtraKeys.exercisePreferencesByMuscle`, el raw es `null` y
`ExercisePreferencesByMuscle.fromDynamic(null)` devuelve preferencias vacias.

## 10. Comportamiento con payload mal formado

Si el payload existe pero no es `Map`, `fromDynamic` devuelve preferencias
vacias.

Ejemplo cubierto por test:

```dart
TrainingExtraKeys.exercisePreferencesByMuscle: 'invalid-payload'
```

Resultado esperado:

```dart
preferences.byMuscle.isEmpty
preferences.hasMinimumData == false
```

## 11. Cambios en provider

Archivo modificado:

`lib/features/training_feature/providers/client_preferences_effect_provider.dart`

Cambios:

- Se importo `TrainingExtraKeys`.
- Se importo `Client`.
- `clientPreferencesEffectProvider` paso a devolver
  `FutureProvider<ExercisePreferencesByMuscle>`.
- El provider ya no retorna `null`.
- El provider resuelve preferencias reales desde el cliente activo.
- Se agrego helper puro:

```dart
ExercisePreferencesByMuscle resolveClientExercisePreferences(Client? client)
```

Ese helper permite testear el contrato sin `ProviderContainer`, DB, Firebase,
debounce ni sync.

## 12. Cambios en modelo/helper

No se modifico `ExercisePreferencesByMuscle`.

Se reutilizo el helper existente:

```dart
ExercisePreferencesByMuscle.fromDynamic(raw)
```

## 13. Tests creados/ajustados

Archivo creado:

`test/features/training_feature/client_preferences_effect_provider_test.dart`

Casos incluidos:

1. Sin cliente activo devuelve preferencias vacias.
2. Cliente activo con payload valido devuelve preferencias reales.
3. Payload mal formado no crashea y devuelve vacio.
4. Canary: el provider no escribe estado ni dispara persistencia.
5. Canary: el provider lee `clientsProvider`, `state.activeClient`,
   `TrainingExtraKeys.exercisePreferencesByMuscle` y
   `ExercisePreferencesByMuscle.fromDynamic`.

El test final no usa:

- `ProviderContainer`.
- DB real.
- Firestore.
- FirebaseAuth.
- Background sync.
- Timers.
- Debounce.
- `Future.delayed`.
- `Completer`.
- `runAsync`.

## 14. Comandos ejecutados

### Mapeo

```powershell
rg -n "clientPreferencesEffectProvider" lib test
```

Salida relevante:

```text
lib\features\training_feature\providers\client_preferences_effect_provider.dart:7:final clientPreferencesEffectProvider = FutureProvider<ExercisePreferencesByMuscle?>(
lib\features\training_feature\providers\training_workspace_provider.dart:44:  ref.watch(clientPreferencesEffectProvider);
```

```powershell
rg -n "ExercisePreferencesByMuscle" lib test
```

Salida relevante:

```text
lib\features\training_feature\screens\gym_exercises_stage_screen.dart:89:      final persisted = ExercisePreferencesByMuscle.fromDynamic(raw);
lib\features\training_feature\screens\gym_exercises_stage_screen.dart:135:      final payload = ExercisePreferencesByMuscle(byMuscle: byMuscle).toJson();
lib\features\training_feature\providers\client_preferences_effect_provider.dart:17:      return const ExercisePreferencesByMuscle();
lib\features\training_feature\domain\exercise_preferences_models.dart:160:class ExercisePreferencesByMuscle {
lib\features\training_feature\domain\exercise_preferences_models.dart:169:  static ExercisePreferencesByMuscle fromDynamic(dynamic raw) {
lib\features\training_feature\domain\training_pipeline_guard.dart:81:    final parsed = ExercisePreferencesByMuscle.fromDynamic(raw);
```

```powershell
rg -n "TrainingExtraKeys|exercisePreferencesByMuscle|preferencesByMuscle|exercisePreferences|training\.extra|extra\[|extra\]" lib\features\training_feature lib\domain test
```

Salida: el comando produjo salida extensa y fue truncado por terminal. Lineas
relevantes visibles:

```text
lib\features\training_feature\screens\gym_exercises_stage_screen.dart:88:          .extra[TrainingExtraKeys.exercisePreferencesByMuscle];
lib\features\training_feature\screens\gym_exercises_stage_screen.dart:139:        extra[TrainingExtraKeys.exercisePreferencesByMuscle] = payload;
lib\features\training_feature\providers\training_workspace_provider.dart:44:  ref.watch(clientPreferencesEffectProvider);
lib\domain\entities\training_profile.dart:135:    TrainingExtraKeys.heightCm,
```

```powershell
rg -n "class TrainingExtraKeys|exercisePreferencesByMuscle" lib test
```

Salida relevante:

```text
lib\core\constants\training_extra_keys.dart:1:class TrainingExtraKeys {
lib\core\constants\training_extra_keys.dart:20:  static const exercisePreferencesByMuscle = 'exercisePreferencesByMuscle';
lib\features\training_feature\screens\gym_exercises_stage_screen.dart:88:          .extra[TrainingExtraKeys.exercisePreferencesByMuscle];
lib\features\training_feature\screens\gym_exercises_stage_screen.dart:139:        extra[TrainingExtraKeys.exercisePreferencesByMuscle] = payload;
lib\features\training_feature\domain\training_pipeline_guard.dart:80:    final raw = extra[TrainingExtraKeys.exercisePreferencesByMuscle];
```

### Lecturas

```powershell
Get-Content lib\features\training_feature\providers\client_preferences_effect_provider.dart | Select-Object -First 200
```

Salida relevante anterior al fix:

```text
return const ExercisePreferencesByMuscle();
```

```powershell
Get-Content lib\features\training_feature\domain\exercise_preferences_models.dart | Select-Object -First 260
```

Salida relevante:

```text
class ExercisePreferencesByMuscle {
  final Map<String, ExercisePreferenceBucket> byMuscle;
  static ExercisePreferencesByMuscle fromDynamic(dynamic raw) {
    if (raw is! Map) return const ExercisePreferencesByMuscle();
```

```powershell
Get-Content lib\core\constants\training_extra_keys.dart | Select-Object -First 80
```

Salida relevante:

```text
static const exercisePreferencesByMuscle = 'exercisePreferencesByMuscle';
```

```powershell
Get-Content lib\features\training_feature\screens\gym_exercises_stage_screen.dart | Select-Object -First 180
```

Salida relevante:

```text
final raw = activeClient?.training.extra[TrainingExtraKeys.exercisePreferencesByMuscle];
final persisted = ExercisePreferencesByMuscle.fromDynamic(raw);
extra[TrainingExtraKeys.exercisePreferencesByMuscle] = payload;
```

```powershell
Get-Content lib\features\training_feature\domain\training_pipeline_guard.dart | Select-Object -First 130
```

Salida relevante:

```text
final raw = extra[TrainingExtraKeys.exercisePreferencesByMuscle];
final parsed = ExercisePreferencesByMuscle.fromDynamic(raw);
```

```powershell
Get-Content lib\features\training_feature\providers\training_workspace_provider.dart | Select-Object -First 110
```

Salida relevante:

```text
ref.watch(clientPreferencesEffectProvider);
final client = ref.watch(clientsProvider).value?.activeClient;
```

```powershell
Get-Content lib\features\training_feature\services\client_preferences_monitor.dart | Select-Object -First 100
```

Salida relevante:

```text
final rawPrefs = extra['exercisePreferencesByMuscle'] as Map<String, dynamic>?;
return rawPrefs != null
    ? ExercisePreferencesByMuscle.fromDynamic(rawPrefs)
    : const ExercisePreferencesByMuscle();
```

### Validacion de tests

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
```

Resultado:

```text
Sin salida durante ~90 segundos. Cancelado segun protocolo.
```

Identificacion:

```text
PID 17032 powershell.exe
CommandLine: & C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded

PID 20324 cmd.exe
CommandLine: "C:\src\flutter\bin\flutter.bat" test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
```

Decision:

```text
Se cerro PID 17032 con Stop-Process -Id 17032 -Force.
```

Despues de retirar `ProviderContainer` del test, se hizo un reintento:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
```

Resultado:

```text
Sin salida durante ~90 segundos. Cancelado segun protocolo. No hubo mas reintentos.
```

Identificacion:

```text
PID 5964 powershell.exe
CommandLine: & C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded

PID 22808 cmd.exe
CommandLine: "C:\src\flutter\bin\flutter.bat" test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
```

Decision:

```text
Se cerro PID 5964 con Stop-Process -Id 5964 -Force.
```

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\clients_provider_hardening_test.dart --reporter expanded
```

Salida:

```text
00:00 +0: loading C:/Users/pedro/StudioProjects/hcs_app_lap/test/features/main_shell/providers/clients_provider_hardening_test.dart
00:00 +0: (setUpAll)
00:00 +0: ClientsProvider hardening granular helpers preserve unrelated client sections
00:00 +1: ClientsProvider hardening history clinic viewmodel does not expose legacy wide saveClient
00:00 +2: ClientsProvider hardening main shell does not remerge history clinic snapshots
00:00 +3: ClientsProvider hardening training interview saves with granular previous-based patch
00:00 +4: ClientsProvider hardening meal plan does not use history clinic viewmodel
00:00 +5: ClientsProvider hardening migrated clinical tabs keep void save contract
00:00 +6: (tearDownAll)
00:00 +6: All tests passed!
```

```powershell
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
```

Salida:

```text
00:00 +0: loading C:/Users/pedro/StudioProjects/hcs_app_lap/test/data/repositories/client_repository_outbox_test.dart
00:00 +0: ClientRepository outbox contract (setUpAll)
00:00 +0: ClientRepository outbox contract saveClient enqueues durable outbox event
00:00 +1: ClientRepository outbox contract deleteClient enqueues tombstone outbox event
00:00 +2: ClientRepository outbox contract background success clears queue and marks synced
00:00 +3: ClientRepository outbox contract remote permission-denied keeps queue pending via retry path
00:00 +4: ClientRepository outbox contract remote invalid payload keeps queue pending via retry path
00:00 +5: ClientRepository outbox contract (tearDownAll)
00:00 +5: All tests passed!
```

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Salida:

```text
Analyzing hcs_app_lap...
No issues found! (ran in 104.4s)
```

### Canaries estaticos

```powershell
rg -n "clientsProvider|state\.activeClient|TrainingExtraKeys\.exercisePreferencesByMuscle|ExercisePreferencesByMuscle\.fromDynamic|return const ExercisePreferencesByMuscle" lib\features\training_feature\providers\client_preferences_effect_provider.dart test\features\training_feature\client_preferences_effect_provider_test.dart
```

Salida relevante:

```text
lib\features\training_feature\providers\client_preferences_effect_provider.dart:12:  final clientsState = ref.watch(clientsProvider);
lib\features\training_feature\providers\client_preferences_effect_provider.dart:14:    data: (state) => resolveClientExercisePreferences(state.activeClient),
lib\features\training_feature\providers\client_preferences_effect_provider.dart:23:      .extra[TrainingExtraKeys.exercisePreferencesByMuscle];
lib\features\training_feature\providers\client_preferences_effect_provider.dart:24:  return ExercisePreferencesByMuscle.fromDynamic(raw);
```

```powershell
rg -n "updateActiveClient|\.notifier|saveClient|ClientRepository|DatabaseHelper|Firestore|Firebase|Timer\(|Future\.delayed|Completer\(|await Future\.any|runAsync\(" lib\features\training_feature\providers\client_preferences_effect_provider.dart
```

Salida:

```text
Sin coincidencias.
```

### Empaquetado

```powershell
Compress-Archive -Path lib -DestinationPath lib.zip -Force
```

Salida:

```text
Sin salida. Exit code 0.
```

```powershell
Compress-Archive -Path test -DestinationPath test.zip -Force
```

Salida:

```text
Sin salida. Exit code 0.
```

```powershell
Get-Item lib.zip,test.zip,pubspec.yaml,analysis_options.yaml | Select-Object Name,Length
```

Salida:

```text
Name                   Length
----                   ------
lib.zip               1508239
test.zip               203934
pubspec.yaml             1837
analysis_options.yaml    1596
```

## 15. Comandos cancelados

Cancelado 1:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
```

Motivo:

```text
Sin salida durante ~90 segundos.
```

Proceso:

```text
PID 17032 powershell.exe
PID 20324 cmd.exe
```

Decision:

```text
Cerrar PID 17032. No se identificaron otros procesos no relacionados.
```

Cancelado 2:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
```

Motivo:

```text
Sin salida durante ~90 segundos.
```

Proceso:

```text
PID 5964 powershell.exe
PID 22808 cmd.exe
```

Decision:

```text
Cerrar PID 5964. No hubo mas reintentos.
```

## 16. Resultado de tests especificos

- `client_preferences_effect_provider_test.dart`: NO CERRADO por ejecucion; se
  colgo dos veces sin salida. El ajuste final de inicializacion del binding
  quedo validado solo por `flutter analyze --no-pub`.
- `clients_provider_hardening_test.dart`: PASA.
- `client_repository_outbox_test.dart`: PASA.

No se identificaron tests de dominio existentes especificos para
`ExercisePreferencesByMuscle` fuera del nuevo archivo.

## 17. Resultado de flutter analyze --no-pub

Resultado:

```text
No issues found! (ran in 104.4s)
```

## 18. Procesos cerrados

Se cerraron procesos solo despues de confirmar `CommandLine`.

```text
PID 17032 powershell.exe
CommandLine: & C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
Decision: Stop-Process -Id 17032 -Force
```

```text
PID 5964 powershell.exe
CommandLine: & C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
Decision: Stop-Process -Id 5964 -Force
```

## 19. Archivos modificados

- `lib/features/training_feature/providers/client_preferences_effect_provider.dart`
- `test/features/training_feature/client_preferences_effect_provider_test.dart`
- `lib/audit/AUDIT_TRAINING_PREF_P1_CLIENT_PREFERENCES_PROVIDER_REPORT.md`

Artefactos generados:

- `lib.zip`
- `test.zip`

## 20. Archivos no tocados

No se modifico:

- UI visual.
- Layout.
- Labels visibles.
- Motor V3.
- Periodizacion.
- Catalogo de ejercicios.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- `analysis_options.yaml`.
- Agenda/pagos.
- Auth.
- App Check.
- Observabilidad.
- SAVE-P0E.
- Outbox clinico.
- Historia Clinica.
- Nutricion.
- Macros.
- Antropometria.
- Bioquimica.
- CLIENT-STATUS-P1A productivo.

## 21. Riesgos pendientes reales

1. El test nuevo no pudo ejecutarse exitosamente en terminal: se colgo dos veces
   sin salida. Aunque el archivo quedo sin timers, sin DB, sin ProviderContainer
   y `analyze` compila limpio, no hay resultado verde de ese test.
2. `ClientPreferencesMonitor` sigue usando la key literal
   `'exercisePreferencesByMuscle'` en su ruta Firestore directa. No se modifico
   por estar fuera del scope principal y porque el sprint pidio conectar el
   provider al cliente activo local.
3. No se toco Motor V3 ni la seleccion de ejercicios. Este sprint solo garantiza
   que el provider entregue preferencias reales al consumidor que lo observa.

## 22. Veredicto

TRAINING-PREF-P1 PARCIAL
