# AUDIT SECURITY FIREBASE P1A - App Check / Firebase Init

## 1. Resumen ejecutivo

Se encontro un riesgo productivo real en `lib/main.dart`: Firebase App Check activaba `AndroidDebugProvider` y `AppleDebugProvider` sin guard de debug. Se aplico una correccion minima: debug providers solo bajo `kDebugMode`; release usa providers reales soportados por `firebase_app_check 0.4.1+4`.

La validacion Flutter no quedo cerrada: `flutter analyze --no-pub` no imprimio salida durante 90 segundos y no pudo cancelarse desde este backend sin usar comandos prohibidos.

## 2. Riesgo original

Antes del cambio, un build release podia ejecutar providers debug de App Check:

- `lib/main.dart:51-54`: `FirebaseAppCheck.instance.activate(...)`.
- `lib/main.dart:52`: `providerAndroid: const AndroidDebugProvider()`.
- `lib/main.dart:53`: `providerApple: const AppleDebugProvider()`.

Esto debilitaba App Check en produccion porque el bootstrap no distinguia debug/local de release/produccion.

## 3. Archivos inspeccionados

- `lib/main.dart`.
- `lib/firebase_options.dart`.
- `lib/core/**` por busqueda estatica.
- `lib/data/**` por busqueda estatica.
- `pubspec.lock` solo lectura, para confirmar `firebase_app_check 0.4.1+4`.
- Cache local de `firebase_app_check 0.4.1+4` solo lectura, para confirmar providers disponibles.

## 4. Estado anterior de Firebase init

- `lib/main.dart:47`: una sola llamada a `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- No se encontro otra llamada a `Firebase.initializeApp` en `lib/`.
- `lib/firebase_options.dart:8-27`: `currentPlatform` selecciona opciones por plataforma.
- `lib/firebase_options.dart:13-14`: Android devuelve `windows`.
- `lib/firebase_options.dart:15-16`: iOS lanza `UnsupportedError`.
- `lib/firebase_options.dart:30-47`: existen opciones `windows` y `macos`.

## 5. Estado anterior de App Check

- `lib/main.dart:49`: App Check se activaba solo para `Platform.isAndroid || Platform.isIOS`.
- `lib/main.dart:52-53`: Android y Apple usaban providers debug sin `kDebugMode`.
- No habia `providerWeb`.
- Desktop se saltaba con log informativo.

## 6. Providers encontrados

- Android anterior: `AndroidDebugProvider`.
- Android posterior: `kDebugMode ? AndroidDebugProvider : AndroidPlayIntegrityProvider`.
- Apple anterior: `AppleDebugProvider`.
- Apple posterior: `kDebugMode ? AppleDebugProvider : AppleDeviceCheckProvider`.
- Web: no hay provider Web configurado en el bootstrap; `lib/firebase_options.dart:9-10` devuelve opciones `windows` cuando `kIsWeb` es true.

## 7. Emuladores encontrados

No se encontraron llamadas runtime en `lib/` a:

- `useFirestoreEmulator`.
- `useAuthEmulator`.
- `useStorageEmulator`.

No se modifico `firebase.json` ni reglas Firebase.

## 8. Tokens/debug hardcodeados encontrados

No se encontro `debugToken` hardcodeado en Dart productivo bajo `lib/`.

## 9. Cambios aplicados

- `lib/main.dart`: se agrego import explicito de `kDebugMode`.
- `lib/main.dart`: se reemplazo activacion directa con debug providers por una rama explicita debug/release.
- `test/security/firebase_app_check_static_contract_test.dart`: se agrego canary estatico puro.
- `lib/audit/AUDIT_SECURITY_FIREBASE_P1A_APP_CHECK_FIREBASE_INIT_REPORT.md`: se agrego este reporte.

## 10. Justificacion tecnica

`firebase_app_check 0.4.1+4` soporta:

- `AndroidDebugProvider`.
- `AndroidPlayIntegrityProvider`.
- `AppleDebugProvider`.
- `AppleDeviceCheckProvider`.
- `AppleAppAttestProvider`.
- `AppleAppAttestWithDeviceCheckFallbackProvider`.

La correccion usa la API actual del paquete (`providerAndroid` / `providerApple`) y evita cambiar arquitectura, dependencias, flavors, UI o configuracion nativa.

## 11. Por que debug no puede llegar a release

En `lib/main.dart`, los providers debug quedaron detras de `kDebugMode`. En builds release, `kDebugMode` es false, por lo que la rama selecciona:

- Android: `AndroidPlayIntegrityProvider`.
- Apple: `AppleDeviceCheckProvider`.

## 12. Por que release no usa providers debug

La rama release no instancia `AndroidDebugProvider` ni `AppleDebugProvider`; ambos quedaron en la rama true de `kDebugMode`.

## 13. Tests/canaries creados

Se creo `test/security/firebase_app_check_static_contract_test.dart`.

El test:

- Lee archivos `.dart` bajo `lib/` como texto.
- No inicializa Firebase.
- No importa `firebase_core`.
- No importa `firebase_app_check`.
- No usa `ProviderContainer`.
- No usa `WidgetsFlutterBinding`.
- No usa DB, Firestore, Auth, Storage ni timers.
- Valida guard para debug providers.
- Valida providers reales de release.
- Valida ausencia de emuladores sin guard.
- Valida ausencia de `debugToken`.
- Valida ausencia de `localhost` Firebase sin guard.
- Valida que `Firebase.initializeApp` no este duplicado en `lib/`.

## 14. Comandos ejecutados

Busquedas estaticas ejecutadas con `rg`:

- `rg -n "Firebase.initializeApp" lib`
- `rg -n "FirebaseAppCheck|AndroidProvider|AppleProvider|ReCaptcha" lib`
- `rg -n "useFirestoreEmulator|useAuthEmulator|useStorageEmulator" lib`
- `rg -n "." lib/main.dart`
- `rg -n "currentPlatform|FirebaseOptions|android|ios|web|windows|macos|linux|unsupported|appId|projectId|storageBucket" lib/firebase_options.dart`
- `rg -n "debugToken|localhost|fromEnvironment|kDebugMode|kReleaseMode|APP_CHECK|FIREBASE" lib`
- `rg -n -C 10 "firebase_app_check:" pubspec.lock`
- `rg -n "DebugProvider|PlayIntegrity|DeviceCheck|AppAttest|Provider" C:\Users\pedro\AppData\Local\Pub\Cache\hosted\pub.dev\firebase_app_check-0.4.1+4\lib`
- `rg -n -C 8 "providerAndroid|providerApple|AndroidDebugProvider|AppleDebugProvider" C:\Users\pedro\AppData\Local\Pub\Cache\hosted\pub.dev\firebase_app_check-0.4.1+4\lib\src\firebase_app_check.dart`
- `rg -n "AndroidDebugProvider|AppleDebugProvider|AndroidProvider.debug|AppleProvider.debug" lib`
- `rg -n "debugToken|localhost|emulator|Emulator" lib`
- `rg -n "fromEnvironment|FIREBASE|APP_CHECK|kDebugMode|kReleaseMode|localhost|debugToken" lib/core lib/data lib/main.dart lib/firebase_options.dart`
- `rg -n "Firebase.initializeApp|FirebaseAppCheck|AndroidDebugProvider|AndroidPlayIntegrityProvider|AppleDebugProvider|AppleDeviceCheckProvider|useFirestoreEmulator|useAuthEmulator|useStorageEmulator|debugToken|localhost" lib/main.dart lib/firebase_options.dart lib/core lib/data`
- `rg -n "." test/security/firebase_app_check_static_contract_test.dart`

Validacion Flutter ejecutada:

- `flutter analyze --no-pub`

## 15. Comandos colgados/cancelados

- `flutter analyze --no-pub`: no imprimio salida durante 90 segundos.
- Se intento interrumpir desde la sesion de terminal, pero el backend no soporto interrupcion/stdin para ese proceso.
- No se uso `Get-CimInstance`.
- No se uso `Stop-Process`.
- No se mataron procesos.
- No se reintento el comando.

## 16. Resultado de flutter analyze --no-pub

No concluyente. El comando quedo colgado sin salida dentro del limite indicado.

## 17. Resultado de tests especificos

No se ejecuto `flutter test test/security/firebase_app_check_static_contract_test.dart` porque `flutter analyze --no-pub` quedo colgado y no se abrieron mas comandos Flutter para evitar cascada de bloqueos.

## 18. Archivos modificados

- `lib/main.dart`.
- `test/security/firebase_app_check_static_contract_test.dart`.
- `lib/audit/AUDIT_SECURITY_FIREBASE_P1A_APP_CHECK_FIREBASE_INIT_REPORT.md`.

## 19. Archivos no tocados

- UI visual, layout y labels visibles.
- Motor V3.
- Entrenamiento, periodizacion y catalogo de ejercicios.
- Nutricion y macros.
- Antropometria y bioquimica.
- Agenda y pagos.
- SAVE-P0E y outbox clinico.
- Historia Clinica.
- TRAINING-INTERVIEW-P1A.
- TRAINING-PREF-P1/P1B productivo.
- `pubspec.yaml`.
- `analysis_options.yaml`.
- Gradle/Xcode.
- Reglas Firestore/Storage.
- `.git`.

## 20. Riesgos pendientes reales

- Validacion Flutter no concluyo por hang de terminal.
- El canary estatico fue creado pero no ejecutado.
- `lib/firebase_options.dart:13-14` usa opciones `windows` para Android; no se cambio porque corregir FirebaseOptions por plataforma requiere configuracion Firebase real y esta fuera del cambio minimo.
- `lib/firebase_options.dart:9-10` usa opciones `windows` para Web y no hay `providerWeb`; no se invento reCAPTCHA sin configuracion existente.
- Desktop sigue saltando App Check (`lib/main.dart` solo activa Android/iOS). Si Windows/macOS son objetivos productivos con enforcement App Check, hace falta definicion de soporte por plataforma fuera de este sprint minimo.
- La configuracion de App Check en Firebase Console no se puede validar estaticamente desde el codigo.

## 21. Veredicto

SECURITY-FIREBASE-P1A PARCIAL
