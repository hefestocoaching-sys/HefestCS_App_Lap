# AUDIT TRAINING-PREF-P1B PURE RESOLVER REPORT

## 1. Resumen ejecutivo

TRAINING-PREF-P1B extrajo `resolveClientExercisePreferences` a un archivo puro de dominio:

- `lib/features/training_feature/domain/client_exercise_preferences_resolver.dart`

El provider quedo como adaptador Riverpod que lee `clientsProvider` y delega en el resolver puro. El test dejo de importar el provider y no contiene referencias directas a `ProviderContainer`, Riverpod, Firebase, Firestore, `DatabaseHelper` ni `ClientRepository`.

Veredicto operativo: la extraccion esta aplicada y los canaries estaticos pasan, pero el test puro sigue colgandose bajo `flutter test` sin output util. Por eso el sprint queda parcial, no cerrado.

## 2. Por que TRAINING-PREF-P1 estaba parcial

Antes de este cambio, `resolveClientExercisePreferences(Client? client)` vivia en:

- `lib/features/training_feature/providers/client_preferences_effect_provider.dart`

Ese archivo tambien importaba:

- `flutter_riverpod`
- `clients_provider.dart`
- `TrainingExtraKeys`
- `Client`
- `ExercisePreferencesByMuscle`

El test `test/features/training_feature/client_preferences_effect_provider_test.dart` importaba el archivo del provider para alcanzar el helper. Aunque no usara `ProviderContainer`, el import seguia pudiendo arrastrar Riverpod, `clientsProvider` y el arbol pesado del provider.

## 3. Causa probable del cuelgue anterior

La causa probable del cuelgue anterior era el import del provider desde el test: el helper puro estaba mezclado con Riverpod y `clientsProvider`. Ese acoplamiento fue eliminado.

Resultado actual importante: aun despues de aislar el helper, el comando focalizado del test puro sigue sin imprimir salida durante 90 segundos. Los imports minimos restantes del test son:

- `dart:io`
- `flutter_test`
- `TrainingExtraKeys`
- `Client`
- `client_exercise_preferences_resolver.dart`
- `exercise_preferences_models.dart`

Esto sugiere que queda un problema del runner/compilacion del grafo Flutter o del grafo de `Client`, no del import del provider.

## 4. Archivo puro creado

Creado:

- `lib/features/training_feature/domain/client_exercise_preferences_resolver.dart`

Contenido funcional:

```dart
ExercisePreferencesByMuscle resolveClientExercisePreferences(Client? client) {
  final raw =
      client?.training.extra[TrainingExtraKeys.exercisePreferencesByMuscle];
  return ExercisePreferencesByMuscle.fromDynamic(raw);
}
```

## 5. Imports permitidos del resolver

El resolver importa solo:

- `package:hcs_app_lap/core/constants/training_extra_keys.dart`
- `package:hcs_app_lap/domain/entities/client.dart`
- `package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart`

## 6. Imports prohibidos ausentes

Canary ejecutado contra el resolver:

```powershell
rg -n "flutter_riverpod|clientsProvider|DatabaseHelper|ClientRepository|Firebase|Firestore|BackgroundSyncService|SyncService" lib\features\training_feature\domain\client_exercise_preferences_resolver.dart
```

Resultado: sin coincidencias.

El resolver no importa:

- Riverpod
- provider de clientes
- DB
- repositorios
- Firebase/Firestore
- sync/background sync

## 7. Cambios en provider

Archivo actualizado:

- `lib/features/training_feature/providers/client_preferences_effect_provider.dart`

Cambios:

- Removida la definicion local de `resolveClientExercisePreferences`.
- Removidos imports directos de `TrainingExtraKeys` y `Client`.
- Agregado import del resolver puro.
- `clientPreferencesEffectProvider` sigue leyendo `clientsProvider`.
- En `data`, llama `resolveClientExercisePreferences(state.activeClient)`.
- En `loading/error`, devuelve `const ExercisePreferencesByMuscle()`.
- No escribe estado.
- No invoca sync.
- No toca Firestore/SQLite.

## 8. Cambios en test

Archivo actualizado:

- `test/features/training_feature/client_preferences_effect_provider_test.dart`

Cambios:

- Removido import de `client_preferences_effect_provider.dart`.
- No usa `ProviderContainer`.
- No importa Riverpod.
- No importa Firebase/Firestore/DB/repositorio.
- Importa el resolver puro.
- Agrega caso de cliente sin key.
- Mantiene payload mal formado y payload valido.
- Agrega canary textual sobre su propio source.

Canary ejecutado:

```powershell
rg -n "flutter_riverpod|ProviderContainer|client_preferences_effect_provider|clientsProvider|DatabaseHelper|ClientRepository|Firebase|Firestore|Timer\(|Future\.delayed|Completer\(|runAsync" test\features\training_feature\client_preferences_effect_provider_test.dart
```

Resultado: sin coincidencias.

## 9. Comportamiento validado por codigo

- Cliente `null`: `client?.training.extra[...]` produce `null`; `ExercisePreferencesByMuscle.fromDynamic(null)` devuelve vacio.
- Cliente sin key: `extra[...]` produce `null`; parser devuelve vacio.
- Payload mal formado: `fromDynamic` retorna `const ExercisePreferencesByMuscle()` si `raw is! Map`.
- Payload valido: `fromDynamic` recorre el mapa, parsea buckets y conserva preferencias reales con datos.

## 10. Comandos ejecutados

Mapeo inicial:

```powershell
Get-Content lib\features\training_feature\providers\client_preferences_effect_provider.dart | Select-Object -First 200
Get-Content test\features\training_feature\client_preferences_effect_provider_test.dart | Select-Object -First 240
rg -n "resolveClientExercisePreferences|clientPreferencesEffectProvider|ExercisePreferencesByMuscle|TrainingExtraKeys.exercisePreferencesByMuscle|ProviderContainer|clientsProvider|DatabaseHelper|ClientRepository|Firebase|Firestore|Timer|Future.delayed|Completer|runAsync" lib\features\training_feature test\features\training_feature lib\core lib\domain
```

Inspeccion focalizada:

```powershell
Get-Content lib\features\training_feature\domain\exercise_preferences_models.dart | Select-Object -First 260
Get-Content lib\core\constants\training_extra_keys.dart | Select-Object -First 200
Get-Content lib\domain\entities\client.dart | Select-Object -First 220
Get-Content lib\domain\entities\training_profile.dart | Select-Object -First 140
Select-String -Path pubspec.yaml -Pattern "flutter_test|test:" -Context 2,2
```

Canaries estaticos:

```powershell
rg -n "flutter_riverpod|ProviderContainer|client_preferences_effect_provider|clientsProvider|DatabaseHelper|ClientRepository|Firebase|Firestore|Timer\(|Future\.delayed|Completer\(|runAsync" test\features\training_feature\client_preferences_effect_provider_test.dart
rg -n "flutter_riverpod|clientsProvider|DatabaseHelper|ClientRepository|Firebase|Firestore|BackgroundSyncService|SyncService" lib\features\training_feature\domain\client_exercise_preferences_resolver.dart
rg -n "resolveClientExercisePreferences|TrainingExtraKeys\.exercisePreferencesByMuscle|ExercisePreferencesByMuscle\.fromDynamic" lib\features\training_feature\domain\client_exercise_preferences_resolver.dart lib\features\training_feature\providers\client_preferences_effect_provider.dart
```

Validaciones Flutter:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\clients_provider_hardening_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Empaquetado:

```powershell
Compress-Archive -Path lib -DestinationPath lib.zip -Force
Compress-Archive -Path test -DestinationPath test.zip -Force
Get-Item lib.zip,test.zip,pubspec.yaml,analysis_options.yaml | Select-Object Name,Length
```

## 11. Comandos cancelados

Cancelados por 90 segundos sin salida util:

- Test puro, primer intento:
  - `& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded`
  - Sin salida durante 90 segundos.
  - PID confirmado: `14628`.

- Test puro, unico reintento:
  - `& C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded`
  - Sin salida durante 90 segundos.
  - PID confirmado: `8704`.

- Analyze:
  - `& C:\src\flutter\bin\flutter.bat analyze --no-pub`
  - Imprimio `Analyzing hcs_app_lap...` y luego no produjo nueva salida durante 90 segundos.
  - PID confirmado: `20240`.

## 12. Resultado del test puro

No completado.

Detalles:

- Primer intento: colgado sin output durante 90 segundos.
- Reintento permitido: colgado sin output durante 90 segundos.
- No se hicieron mas reintentos.

El test ya no importa el provider ni los simbolos prohibidos, pero sigue sin completar bajo el runner Flutter en este entorno.

## 13. Resultado de tests de no regresion

Hardening:

```text
test/features/main_shell/providers/clients_provider_hardening_test.dart
00:00 +6: All tests passed!
```

Client outbox:

```text
test/data/repositories/client_repository_outbox_test.dart
00:00 +5: All tests passed!
```

## 14. Resultado de flutter analyze --no-pub

No completado.

El comando inicio y emitio:

```text
Analyzing hcs_app_lap...
```

Luego no produjo nueva salida durante 90 segundos y fue cerrado segun protocolo.

## 14.1 Resultado de empaquetado

Generados:

- `lib.zip`
- `test.zip`

Verificados junto con:

- `pubspec.yaml`
- `analysis_options.yaml`

## 15. Procesos cerrados

- PID `14628`
  - `CommandLine`: `C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded`
  - Motivo: test puro primer intento sin salida durante 90 segundos.
  - Nota: `Stop-Process -Id 14628` devolvio una excepcion interna de PowerShell; `Stop-Process -Id 14628 -Force` cerro el proceso.

- PID `8704`
  - `CommandLine`: `C:\src\flutter\bin\flutter.bat test test\features\training_feature\client_preferences_effect_provider_test.dart --reporter expanded`
  - Motivo: test puro reintento sin salida durante 90 segundos.

- PID `20240`
  - `CommandLine`: `C:\src\flutter\bin\flutter.bat analyze --no-pub`
  - Motivo: analyze sin nueva salida durante 90 segundos despues del mensaje inicial.

## 16. Archivos modificados

- `lib/features/training_feature/domain/client_exercise_preferences_resolver.dart`
- `lib/features/training_feature/providers/client_preferences_effect_provider.dart`
- `test/features/training_feature/client_preferences_effect_provider_test.dart`
- `lib/audit/AUDIT_TRAINING_PREF_P1B_PURE_RESOLVER_REPORT.md`

## 17. Archivos no tocados

No se tocaron:

- UI visual
- layout
- labels visibles
- Motor V3
- logica cientifica
- periodizacion
- catalogo de ejercicios
- Firebase rules
- dependencias
- `pubspec.yaml`
- `analysis_options.yaml`
- agenda/pagos/auth/App Check/observabilidad
- SAVE-P0E
- outbox clinico
- historia clinica
- nutricion/macros/antropometria/bioquimica
- CLIENT-STATUS-P1A productivo
- TRAINING-INTERVIEW-P1A productivo

## 18. Riesgos pendientes reales

- El test puro sigue colgandose aun sin import del provider.
- `flutter analyze --no-pub` no completo bajo el limite de silencio definido.
- No hay evidencia de que el cuelgue actual venga de Riverpod o `clientsProvider`; los canaries estaticos indican que ese acoplamiento ya fue removido.
- El siguiente punto tecnico real es aislar si el cuelgue viene del runner Flutter en este entorno o del grafo de dominio importado por `Client`.

## 19. Veredicto

TRAINING-PREF-P1B PARCIAL
