# AUDIT P2 CLIENTS PROVIDER LEGACY REPORT

## 1. Resumen ejecutivo

Se eliminó la bifurcación legacy del flujo productivo de `ClientsNotifier.updateActiveClient`. La ruta normal ya no depende de `FeatureFlags.useLegacyClientUpdate` y quedó restringida a la actualización granular vigente, preservando el comportamiento visible y la semántica de persistencia.

## 2. Hallazgo corregido

`P2-03 — ClientsNotifier conserva una ruta legacy de merge amplio detrás de feature flag`

## 3. Estado anterior

Antes del cambio, `updateActiveClient` elegía la ruta legacy por feature flag:

```dart
Future<void> updateActiveClient(Client Function(Client) transform) async {
  if (FeatureFlags.useLegacyClientUpdate) {
    return _updateActiveClientLegacy(transform);
  }
```

La clase también mantenía `_updateActiveClientLegacy`, que aplicaba un merge amplio de secciones clínicas y de entrenamiento antes de persistir el cliente.

## 4. Decisión técnica

Se eliminó la ruta legacy del flujo normal.

Motivo:

- no había consumidores legítimos del flag en código productivo;
- la rama legacy quedaba viva sin necesidad funcional;
- el método normal podía reabrir accidentalmente un merge amplio de snapshots viejos;
- la ruta granular ya existía y preserva el comportamiento esperado con menos riesgo.

`FeatureFlags.useLegacyClientUpdate` quedó como constante inerte en configuración, pero ya no gobierna el comportamiento de `updateActiveClient`.

## 5. Cambios aplicados

- `lib/features/main_shell/providers/clients_provider.dart`: se eliminó la bifurcación `FeatureFlags.useLegacyClientUpdate` del método productivo y se retiró `_updateActiveClientLegacy` del provider.
- `test/features/main_shell/providers/clients_provider_legacy_contract_test.dart`: se agregó un canary estático y una verificación funcional mínima de la ruta granular.
- `lib/audit/AUDIT_P2_CLIENTS_PROVIDER_LEGACY_REPORT.md`: reporte de auditoría del sprint.

## 6. Política nueva

| Flujo | Antes | Ahora | Riesgo cerrado |
| --- | --- | --- | --- |
| `updateActiveClient` | Dependía del flag legacy y podía derivar a wide merge | Siempre usa la ruta granular | Sí |
| `FeatureFlags.useLegacyClientUpdate` | Gobernaba el comportamiento productivo | Ya no afecta el flujo normal | Sí |
| `_updateActiveClientLegacy` | Existía como ruta activa detrás del flag | Eliminado del flujo productivo | Sí |
| Actualización granular | Disponible, pero no era la única ruta | Ruta única del método normal | Sí |

Casos mínimos:

- `updateActiveClient`;
- `FeatureFlags.useLegacyClientUpdate`;
- `_updateActiveClientLegacy`;
- actualización granular.

## 7. Tests agregados

- `updateActiveClient no longer depends on the legacy feature flag`
- `legacy wide merge helper is removed from the provider flow`
- `granular update preserves unrelated sections on active client`

## 8. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/features/main_shell/providers/clients_provider_legacy_contract_test.dart`

## 9. Resultados

- `flutter analyze --no-pub`: OK, sin issues.
- `flutter test test/features/main_shell/providers/clients_provider_legacy_contract_test.dart`: OK, 3 tests aprobados.

## 10. Comandos colgados/cancelados

No hubo comandos colgados ni cancelados.

## 11. Archivos modificados

- `lib/features/main_shell/providers/clients_provider.dart`
- `test/features/main_shell/providers/clients_provider_legacy_contract_test.dart`
- `lib/audit/AUDIT_P2_CLIENTS_PROVIDER_LEGACY_REPORT.md`

## 12. Archivos no tocados

No se tocó UI, Motor V3, reglas Firestore, Firebase bootstrap, `pubspec.yaml`, sync/outbox, lógica científica ni contratos de payload.

## 13. Riesgos pendientes

- Si existen rutas legacy clínicas fuera de este provider, no fueron parte de este sprint.
- La validación cubre contrato y comportamiento local, no navegación runtime completa.
- `FeatureFlags.useLegacyClientUpdate` sigue definido como constante inerte; no afecta el flujo normal, pero puede eliminarse más adelante si se desea limpiar deuda de configuración.

## 14. Veredicto final

P2-CLIENTS-PROVIDER-LEGACY CERRADO