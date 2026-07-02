# SECURITY-FIREBASE-P1B Production Readiness Report

## 1. Resumen ejecutivo

Este sprint cierro la parte profesional de Firebase/App Check que quedaba parcial en P1A. El repo ahora tiene un bootstrap explicito en [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L8), `main.dart` deja de contener la logica de App Check en linea y `firebase_options.dart` deja de simular soporte Android/Web usando opciones Windows.

Resultado tecnico: `flutter analyze --no-pub` paso sin issues y el canary estatico paso. Resultado de producto: la configuracion queda cerrada para el subconjunto real que hoy existe en el repo, pero Android, iOS y Web siguen bloqueados porque no hay FirebaseOptions reales ni configuracion web real en el material entregado.

## 2. Veredicto P1A heredado

P1A quedaba parcial porque `main.dart` activaba App Check con debug providers sin guard y `firebase_options.dart` reutilizaba Windows para Android y Web.

Evidencia historica visible en el snapshot de trabajo anterior y en los zip entregados:
- `main.dart` tenia el flujo de App Check inline antes de la refactorizacion.
- `firebase_options.dart` devolvia `windows` para Android y Web.
- El canary statico existia, pero no estaba alineado con una politica real por plataforma.

## 3. Evidencia leida de GitHub main

Archivos leidos en el repo local sincronizado con main:
- [lib/main.dart](lib/main.dart#L6) y [lib/main.dart](lib/main.dart#L32) muestran el bootstrap actual.
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L8) concentra la inicializacion Firebase/App Check.
- [lib/firebase_options.dart](lib/firebase_options.dart#L5) define la politica de opciones por plataforma; este archivo existia en disco pero no estaba versionado en HEAD antes de la correccion.
- .gitignore lo excluía explicitamente, asi que hubo que versionarlo a proposito porque solo contiene FirebaseOptions cliente y no secretos.
- [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart#L12) contiene el canary actualizado.
- [firebase.json](firebase.json#L1) solo aporta reglas e indexes de Firestore; no define App Check ni opciones Firebase por plataforma.
- [pubspec.yaml](pubspec.yaml#L1) sigue declarando firebase_core y firebase_app_check como dependencias directas.
- [pubspec.lock](pubspec.lock#L340) fija firebase_app_check 0.4.1+4; [pubspec.lock](pubspec.lock#L388) fija firebase_core 4.4.0.
- [analysis_options.yaml](analysis_options.yaml#L1) no agrega ninguna regla especial de Firebase; solo lint general.

## 4. Evidencia leida de lib.zip

El contenido descomprimido de lib.zip reflejaba el estado previo al fix:
- main.dart todavia inicializaba Firebase/App Check en linea.
- firebase_options.dart devolvia Windows para Android y Web.
- No existia el bootstrap separado en lib/core/firebase.
- El reporte P1A estaba presente como evidencia documental del riesgo previo.

Importante: `git show HEAD:lib/firebase_options.dart` devolvio error porque el archivo no estaba en HEAD, asi que la version nueva tuvo que introducirse explicitamente para que el repo quede coherente con main.dart.

Ademas, `git check-ignore -v lib/firebase_options.dart` mostro que `.gitignore` lo excluia en la linea 48, por lo que el archivo debio forzarse al indice para poder dejarlo versionado.

Para test.zip el estado era equivalente en el canary: el test de seguridad existia, pero no estaba alineado con la nueva politica de unsupported platforms ni con el bootstrap extraido.

## 5. Diferencias GitHub vs lib.zip

Antes del cambio, no habia divergencia relevante entre el repo y los zip para las piezas auditadas: ambos mostraban el mismo estado parcial P1A.

Despues del cambio, el repo ya diverge intencionalmente del zip:
- se agrego [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L8) porque no existia en HEAD ni en los zip;
- [lib/main.dart](lib/main.dart#L43) deja de contener la activacion inline de App Check;
- [lib/firebase_options.dart](lib/firebase_options.dart#L7) deja de reutilizar Windows para Android/Web y ahora si queda versionado en la rama de trabajo;
- [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart#L123) ahora valida la politica real por plataforma.

## 6. Estado anterior exacto

Antes de la correccion:
- [lib/main.dart](lib/main.dart#L32) llamaba a Firebase y App Check en el mismo metodo main.
- App Check quedaba atado a Platform.isAndroid o Platform.isIOS.
- Android y Apple usaban providers debug/release dentro del mismo bloque.
- [lib/firebase_options.dart](lib/firebase_options.dart#L13) devolvia Windows para Android.
- [lib/firebase_options.dart](lib/firebase_options.dart#L7) devolvia Windows para Web.
- iOS lanzaba UnsupportedError, pero el mensaje era minimo y no dejaba una politica profesional clara.

## 7. Cambios aplicados

- [lib/main.dart](lib/main.dart#L6) ahora importa un bootstrap dedicado.
- [lib/main.dart](lib/main.dart#L43) llama a bootstrapFirebase() y no contiene ya la configuracion App Check inline.
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L8) centraliza Firebase.initializeApp y la politica App Check.
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L22) activa Android App Check con guard kDebugMode y Play Integrity en release.
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L30) activa Apple App Check con guard kDebugMode y Device Check en release.
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L38) documenta el skip de Windows por ausencia de provider.
- [lib/firebase_options.dart](lib/firebase_options.dart#L7) ahora bloquea Web con UnsupportedError explicito.
- [lib/firebase_options.dart](lib/firebase_options.dart#L17) bloquea Android con UnsupportedError explicito.
- [lib/firebase_options.dart](lib/firebase_options.dart#L21) bloquea iOS con UnsupportedError explicito.
- [lib/firebase_options.dart](lib/firebase_options.dart#L25) bloquea Linux con UnsupportedError explicito.
- [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart#L12) valida existencia del bootstrap y que main ya no aloja Firebase initialize/App Check.

## 8. Matriz profesional por plataforma

| Plataforma | FirebaseOptions | App Check | Estado permitido | Observacion |
| --- | --- | --- | --- | --- |
| Windows | real, [lib/firebase_options.dart](lib/firebase_options.dart#L13) | skip, [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L38) | interno / produccion parcial | Hay opciones reales de Firebase, pero el paquete actual no ofrece provider Windows de App Check. |
| macOS | real, [lib/firebase_options.dart](lib/firebase_options.dart#L15) y [lib/firebase_options.dart](lib/firebase_options.dart#L44) | activo con Apple provider, [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L30) | produccion | Esta es la unica plataforma desktop con App Check real en el bootstrap actual. |
| Android | no real, [lib/firebase_options.dart](lib/firebase_options.dart#L17) | bloqueado por falta de opciones reales | bloqueado | No se inventaron credenciales ni se reutilizo Windows. |
| iOS | no real, [lib/firebase_options.dart](lib/firebase_options.dart#L21) | bloqueado por falta de opciones reales | bloqueado | El mensaje explicito obliga a `flutterfire configure`. |
| Web | no real, [lib/firebase_options.dart](lib/firebase_options.dart#L7) | bloqueado por falta de opciones reales y site key | bloqueado | No existe configuracion real de reCAPTCHA ni providerWeb en el repo. |
| Linux | no real, [lib/firebase_options.dart](lib/firebase_options.dart#L25) | bloqueado | bloqueado | La politica deja claro que no hay soporte productivo. |

## 9. Politica FirebaseOptions por plataforma

- Windows y macOS tienen FirebaseOptions reales en [lib/firebase_options.dart](lib/firebase_options.dart#L34) y [lib/firebase_options.dart](lib/firebase_options.dart#L44).
- Android, iOS, Web y Linux no tienen opciones reales y devuelven UnsupportedError explicito.
- No se inventaron appId, projectId, apiKey, authDomain, reCAPTCHA ni credenciales para plataformas no configuradas.
- El comando externo requerido para generar opciones reales sigue siendo flutterfire configure.

## 10. Politica App Check por plataforma

- Android: la rama de bootstrap existe, pero hoy queda bloqueada por la falta de FirebaseOptions reales.
- iOS: igual que Android; no hay configuracion real y por eso no llega a un estado productivo.
- macOS: App Check se activa con AppleDebugProvider en debug y AppleDeviceCheckProvider en release.
- Windows: se omite App Check con log explicito porque firebase_app_check no expone provider Windows.
- Linux: se omite con log explicito y la plataforma queda no productiva.
- Web: se bloquea de forma explicita hasta tener opciones reales y site key.

## 11. Politica debug vs release

- Los providers debug solo aparecen dentro de guard kDebugMode en [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L22) y [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L30).
- Release usa Play Integrity en Android y Device Check en Apple cuando la plataforma llegue a estar configurada de forma real.
- No hay debugToken hardcodeado en lib.

## 12. Politica desktop

- Windows tiene FirebaseOptions reales, pero App Check se salta por ausencia de provider en el paquete actual.
- macOS si queda cubierto por App Check real.
- Esto se documenta como produccion parcial para desktop: Firebase core funciona, App Check solo esta cubierto en macOS.

## 13. Politica web

- Web no se presenta como productiva.
- [lib/firebase_options.dart](lib/firebase_options.dart#L7) bloquea Web con UnsupportedError explicito.
- No existe providerWeb configurado con site key real.
- El bootstrap de App Check en [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L14) tambien defiende la misma politica.
- [lib/main.dart](lib/main.dart#L1) sigue importando dart:io, asi que Web tampoco puede reclamarse como target compilable en el bootstrap actual.

## 14. Emuladores

La auditoria estatica sobre lib no encontro llamadas runtime a useFirestoreEmulator, useAuthEmulator ni useStorageEmulator.

firebase.json solo define Firestore rules/indexes y emuladores de auth/firestore a nivel de tooling, no bootstrap runtime desde main.dart.

## 15. Tokens y debug

- No se encontro debugToken hardcodeado en lib.
- No se encontro localhost Firebase sin guard en lib.
- El canary sigue vigilando estas dos condiciones.

## 16. Firebase initializeApp duplicado o no

- El conteo estatico en lib da una sola llamada a Firebase.initializeApp, ahora concentrada en [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart#L9).
- [lib/main.dart](lib/main.dart#L43) ya no vuelve a llamar Firebase.initializeApp.

## 17. Tests y canaries actualizados

El canary en [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart#L12) ahora valida:
- existencia de lib/main.dart, lib/firebase_options.dart y lib/core/firebase/firebase_bootstrap.dart;
- que main importa el bootstrap;
- que main ya no contiene Firebase.initializeApp ni FirebaseAppCheck.instance.activate;
- que firebase_options.dart bloquea Web, Android, iOS y Linux con mensajes explicitamente citables;
- que no hay inicializacion Firebase duplicada;
- que los providers debug siguen estando bajo guard.

## 18. Comandos ejecutados

Inspeccion y comparacion:
- Expand-Archive lib.zip a carpeta temporal para leer el snapshot real.
- Expand-Archive test.zip a carpeta temporal para leer el snapshot real.
- Lectura directa de [lib/main.dart](lib/main.dart#L32), [lib/firebase_options.dart](lib/firebase_options.dart#L5) y [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart#L12).
- Busquedas sobre pubspec.lock para firebase_app_check, firebase_core, cloud_firestore, firebase_auth, firebase_storage y firebase_analytics.

Validacion del sprint:
- flutter analyze --no-pub
- flutter test test/security/firebase_app_check_static_contract_test.dart

Validacion auxiliar del codigo tocado:
- get_errors sobre lib/main.dart, lib/core/firebase/firebase_bootstrap.dart, lib/firebase_options.dart y test/security/firebase_app_check_static_contract_test.dart

## 19. Resultados

- flutter analyze --no-pub: paso en 18.9 s, sin issues.
- flutter test test/security/firebase_app_check_static_contract_test.dart: paso, todas las pruebas en verde.
- get_errors: sin errores en los archivos tocados.

## 20. Comandos colgados o cancelados

No hubo comandos colgados ni cancelados en esta iteracion.

## 21. Riesgos cerrados

- Android ya no reutiliza Windows FirebaseOptions.
- Web ya no reutiliza Windows FirebaseOptions.
- main.dart ya no contiene la activacion inline de App Check.
- Debug providers ya no pueden escaparse a release en el bootstrap actual.
- Hay un mensaje explicito para cada plataforma no configurada.
- El canary ahora cubre bootstrap, opciones y politica por plataforma.

## 22. Riesgos pendientes

- Android no tiene FirebaseOptions reales en el material entregado.
- iOS no tiene FirebaseOptions reales en el material entregado.
- Web no tiene FirebaseOptions reales ni site key de reCAPTCHA.
- Windows sigue sin provider de App Check en el paquete actual.
- El estado productivo completo de Android/iOS/Web depende de flutterfire configure y de configuracion real externa en Firebase Console.

## 23. Que no se pudo cerrar y por que

No se pudo cerrar Android, iOS ni Web como plataformas productivas porque el repo y el zip no contienen opciones reales para ellas. No se inventaron credenciales ni claves de reCAPTCHA.

Windows tampoco se puede cerrar como App Check productivo porque el paquete instalado no expone provider Windows.

## 24. Archivos modificados

- [lib/main.dart](lib/main.dart)
- [lib/core/firebase/firebase_bootstrap.dart](lib/core/firebase/firebase_bootstrap.dart)
- [lib/firebase_options.dart](lib/firebase_options.dart)
- [test/security/firebase_app_check_static_contract_test.dart](test/security/firebase_app_check_static_contract_test.dart)
- [lib/audit/AUDIT_SECURITY_FIREBASE_P1B_PRODUCTION_READINESS_REPORT.md](lib/audit/AUDIT_SECURITY_FIREBASE_P1B_PRODUCTION_READINESS_REPORT.md)

## 25. Archivos no tocados

- [pubspec.yaml](pubspec.yaml)
- [pubspec.lock](pubspec.lock)
- [analysis_options.yaml](analysis_options.yaml)
- [firebase.json](firebase.json)
- Firestore rules e indexes
- UI visual, layout y labels visibles
- Motor V3
- Entrenamiento, nutricion, macros, antropometria, bioquimica, agenda, pagos y SAVE-P0E

## 26. Veredicto final

SECURITY-FIREBASE-P1B PARCIAL

Motivo: la capa desktop/macOS quedo profesionalmente declarada y validada, y el bootstrap ya no miente sobre Android/Web. Pero Android, iOS y Web siguen bloqueados por falta de FirebaseOptions reales y de configuracion externa real, y Windows no tiene App Check soportado por el paquete actual.