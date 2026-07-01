# AUDIT_GLOBAL_DART_PRODUCTION_READINESS_EXECUTIVE_SUMMARY

Fecha: 2026-06-29  
Alcance: auditoria Dart de `lib/`, `test/`, `integration_test/` y configuracion local visible.  
Resultado: `flutter analyze --no-pub` limpio.

## 1. Score global

Score global estimado: **56/100**  
Confianza: **media**

La app tiene buena base tecnica en dominio, Motor V3 y outbox de cliente/records clinicos upsert. No esta lista para produccion real por riesgos de persistencia, seguridad Firebase/App Check, observabilidad y algunos writers amplios de `Client`.

## 2. Top 10 riesgos

1. **P0**: deletes granulares de antropometria/bioquimica/nutricion/training no tienen outbox durable.
2. **P1**: agenda y pagos/transacciones son Firestore online-first sin persistencia local/outbox.
3. **P1**: `clientsProvider.updateActiveClient` sigue siendo API publica capaz de aceptar snapshots amplios.
4. **P1**: `InactiveClientsScreen` reactiva con `updateActiveClient((prev) => updatedClient)`.
5. **P1**: `TrainingInterviewTab` copia `updatedClient.training` desde snapshot local.
6. **P1**: App Check usa `AndroidDebugProvider` y `AppleDebugProvider`.
7. **P1**: Crashlytics/observabilidad remota no esta conectada.
8. **P1**: `clientPreferencesEffectProvider` devuelve preferencias vacias y no lee preferencias reales del cliente.
9. **P1**: uso extenso de `extra`/`Map<String,dynamic>` sin schema central por dominio.
10. **P2**: pantallas/providers monoliticos elevan el costo de cambio (`anthropometry_measures_tab.dart`, `biochemistry_tab.dart`, `training_plan_provider.dart`).

## 3. Top 5 bloqueadores para avanzar

1. Cerrar `SAVE-P0E`: deletes durables para records clinicos.
2. Corregir reactivacion/desactivacion de clientes sin snapshot amplio.
3. Cambiar App Check debug por configuracion productiva/flavors.
4. Activar observabilidad remota con redaccion de datos sensibles.
5. Definir contrato de agenda/pagos: online-only explicito o offline-first con outbox.

## 4. Siguiente sprint recomendado

**SAVE-P0E: deletes granulares antropometria/bioquimica/nutricion/training con outbox durable.**

Justificacion: es el unico P0 operativo confirmado. Los upserts clinicos ya tienen outbox, pero los deletes dependen de una escritura remota directa; si falla, puede quedar inconsistencia clinica dificil de detectar.

## 5. Se puede avanzar features o no

Veredicto:

```text
VEREDICTO: AVANZAR FEATURES DESPUES DE CERRAR BLOQUEADORES P0/P1
```

Se pueden avanzar features menores que no escriban datos criticos ni abran nuevas rutas de persistencia. No conviene avanzar features grandes de datos clinicos, agenda, pagos o entrenamiento hasta cerrar los P0/P1 listados.

## 6. Que falta para produccion real

- Outbox durable para deletes clinicos.
- Seguridad Firebase: rules auditadas, App Check productivo, ownership por coach/cliente.
- Observabilidad remota: Crashlytics/Sentry y logger con redaccion.
- CI/CD: `analyze` y canaries criticos automáticos.
- Tests de agenda/pagos/auth/error paths.
- Schema validado para `training.extra`, `nutrition.extra` e `history.extra`.
- Perfilado de pantallas grandes antes de beta con datos reales.
