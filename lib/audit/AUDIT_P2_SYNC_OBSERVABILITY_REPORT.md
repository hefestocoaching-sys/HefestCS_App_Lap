# AUDIT P2 SYNC OBSERVABILITY REPORT

## 1. Resumen ejecutivo

Se corrigió la observabilidad de `SyncService` sin cambiar la semántica de sincronización, la cola, los payloads, la UI, Motor V3 ni las reglas de Firebase. Los errores de item y globales ahora se registran con contexto estructurado usando `AppLogger`, y se añadió cobertura unitaria pura para validar que el contexto no expone payloads completos ni datos sensibles.

## 2. Hallazgo corregido

`P2-01 — SyncService traga errores y degrada observabilidad de la cola`

## 3. Estado anterior

Antes del cambio, `SyncService` degradaba los fallos a `debugPrint`:

```dart
} catch (e) {
  debugPrint('Sync failed for ${item['id']}: $e');
  await SyncQueueHelper.markFailure(item['id'] as String, e.toString());
}
...
} catch (e) {
  debugPrint('Error processing sync queue: $e');
} finally {
  _isProcessing = false;
}
```

También había un `debugPrint` para dominios de cola no soportados.

## 4. Cambios aplicados

- `lib/core/services/sync_service.dart`: reemplazo de `debugPrint` por `AppLogger`, separación de contexto de item y global, y helpers puros para clasificar dominio, operación y tipo de entidad.
- `test/core/services/sync_service_observability_test.dart`: cobertura pura del contexto de observabilidad para item, global, campos faltantes, tipos raros y exclusión de payloads.

## 5. Política nueva de observabilidad

| Caso | Antes | Ahora | Datos incluidos | Datos excluidos |
| --- | --- | --- | --- | --- |
| Error por item | `debugPrint` sin estructura | `logger.warning` con contexto de item | `itemId`, `operation`, `entityType`, `domain`, `error`, `stackTrace` cuando existe | payload completo, campos clínicos completos, campos financieros completos |
| Error global | `debugPrint` sin trazabilidad | `logger.error` con error y stack trace | `scope=global`, `error`, `stackTrace` | payload completo, contexto de item innecesario |
| Item con campos faltantes | Podía fallar o quedar poco claro | Helper tolerante a tipos raros | valores de fallback como `unknown` | payload completo |
| Payload sensible | No había política explícita | No se loggea | solo metadatos mínimos | payload completo y contenido sensible |

Casos mínimos cubiertos:

- error por item;
- error global;
- item con campos faltantes;
- payload sensible.

## 6. Tests agregados

- `builds item context with minimum metadata only`
- `builds item context safely when fields are missing or odd types`
- `builds global context distinct from item context`
- `builds unsupported domain context without payload data`

## 7. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/core/services/sync_service_observability_test.dart`

## 8. Resultados

- `flutter analyze --no-pub`: OK, sin issues.
- `flutter test test/core/services/sync_service_observability_test.dart`: OK, 4 tests aprobados.

## 9. Comandos colgados/cancelados

No hubo comandos colgados ni cancelados.

## 10. Archivos modificados

- `lib/core/services/sync_service.dart`
- `test/core/services/sync_service_observability_test.dart`
- `lib/audit/AUDIT_P2_SYNC_OBSERVABILITY_REPORT.md`

## 11. Archivos no tocados

No se tocó UI, Motor V3, reglas Firestore, Firebase bootstrap, `pubspec.yaml` ni contratos de payload.

## 12. Riesgos pendientes

- No se agregó telemetría remota; la observabilidad queda en logger local si `AppLogger` no reenvía eventos.
- No se añadió contador nuevo de retries ni migración de schema.
- No se validó sincronización real contra Firebase por instrucción.

## 13. Veredicto final

P2-SYNC-OBSERVABILITY CERRADO