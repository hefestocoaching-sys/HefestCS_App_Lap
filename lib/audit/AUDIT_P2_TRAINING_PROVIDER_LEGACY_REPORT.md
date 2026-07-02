# AUDIT P2 TRAINING PROVIDER LEGACY REPORT

## 1. Resumen ejecutivo

Se eliminó el bloque legacy y dead code de `TrainingPlanNotifier.generateTrainingPlan` sin tocar Motor V3 ni las reglas científicas. La ruta productiva queda en `generatePlanFromActiveCycle`, y el método deprecated restante se redujo a una falla explícita corta para compatibilidad, sin lógica duplicada ni logging masivo.

## 2. Hallazgo corregido

`P2-02 — TrainingPlanProvider mezcla orquestación, persistencia, compatibilidad legacy y logging masivo`

## 3. Estado anterior

Antes del cambio, `generateTrainingPlan` contenía un `throw StateError` seguido de código inalcanzable y logging legacy:

```dart
throw StateError(
  'No se pudo materializar TrainingPlan legacy. Usa generatePlanFromActiveCycle.',
);

try {
  debugPrint(
    '[TrainingPlanProvider] Generating plan for client: $clientId',
  );
```

Ese bloque seguía con más lógica legacy, persistencia y llamadas a Motor V3, aunque no podía ejecutarse después del `throw`.

## 4. Decisión técnica

Se mantuvo la API deprecated como stub corto y explícito para compatibilidad, pero se eliminó el bloque muerto posterior al `throw`.

Motivo:

- no había consumidores productivos en `lib/**` de `generateTrainingPlan`;
- la ruta activa ya es `generatePlanFromActiveCycle`;
- el bloque legacy era inalcanzable y mezclaba responsabilidades;
- dejar un stub claro reduce riesgo y evita duplicar lógica.

## 5. Cambios aplicados

- `lib/features/training_feature/providers/training_plan_provider.dart`: `generateTrainingPlan` quedó como stub deprecated corto; se eliminó el bloque legacy/dead code y los `debugPrint` asociados.
- `test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`: canary estático y contrato mínimo para la ruta productiva.
- `lib/audit/AUDIT_P2_TRAINING_PROVIDER_LEGACY_REPORT.md`: reporte de auditoría del sprint.

## 6. Política nueva

| Flujo | Antes | Ahora | Riesgo cerrado |
| --- | --- | --- | --- |
| `generateTrainingPlan` | Stub con bloque muerto y logging legacy | Stub deprecated corto con `StateError` explícito | Sí |
| `generatePlanFromActiveCycle` | Ruta activa pero coexistía con legacy muerto | Ruta productiva única | Sí |
| Motor V3 | Presente en el bloque legacy y en la ruta activa | Se preserva solo en la ruta productiva | Sí |
| Bloque dead code | Existía después del `throw` | Eliminado | Sí |
| Logging legacy | `debugPrint` masivo dentro del bloque muerto | Eliminado del flujo legacy | Sí |

Casos mínimos:

- `generateTrainingPlan`;
- `generatePlanFromActiveCycle`;
- Motor V3;
- bloque dead code;
- logging legacy.

## 7. Tests agregados

- `generatePlanFromActiveCycle remains the product path`
- `generateTrainingPlan is a short legacy stub without dead code`
- `generatePlanFromActiveCycle does not delegate back to legacy`

## 8. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`

## 9. Resultados

- `flutter analyze --no-pub`: OK, sin issues.
- `flutter test test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`: OK, 3 tests aprobados.

## 10. Comandos colgados/cancelados

No hubo comandos colgados ni cancelados.

## 11. Archivos modificados

- `lib/features/training_feature/providers/training_plan_provider.dart`
- `test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`
- `lib/audit/AUDIT_P2_TRAINING_PROVIDER_LEGACY_REPORT.md`

## 12. Archivos no tocados

No se tocó UI, Motor V3, reglas científicas, reglas Firestore, Firebase bootstrap, `pubspec.yaml`, sync/outbox, nutrición, antropometría ni contratos de payload.

## 13. Riesgos pendientes

- El provider sigue siendo grande; la limpieza fue quirúrgica y no una refactorización estructural.
- Logging productivo restante fuera del bloque legacy no fue parte de este sprint.
- No se ejecutó navegación runtime ni pruebas end-to-end.

## 14. Veredicto final

P2-TRAINING-PROVIDER-LEGACY CERRADO# AUDIT P2 TRAINING PROVIDER LEGACY REPORT

## 1. Resumen ejecutivo

Se cerró la deuda legacy de `TrainingPlanNotifier` en `training_plan_provider.dart` eliminando el bloque muerto posterior al `throw StateError` y dejando `generateTrainingPlan` como stub deprecated corto y explícito. La ruta productiva queda en `generatePlanFromActiveCycle`, sin delegación de vuelta al método legacy, sin tocar Motor V3, reglas científicas, UI ni persistencia.

## 2. Hallazgo corregido

`P2-02 — TrainingPlanProvider mezcla orquestación, persistencia, compatibilidad legacy y logging masivo`

## 3. Estado anterior

Antes del cambio, `generateTrainingPlan` contenía una mezcla de compatibilidad legacy, persistencia y bloque muerto después del `throw`:

```dart
throw StateError(
  'No se pudo materializar TrainingPlan legacy. Usa generatePlanFromActiveCycle.',
);

try {
  debugPrint(
    '[TrainingPlanProvider] Generating plan for client: $clientId',
  );
```

Ese bloque era inalcanzable y mantenía logging legacy y lógica duplicada detrás de la excepción.

## 4. Decisión técnica

Se eligió el Caso A.

- No se encontraron consumidores productivos de `generateTrainingPlan` dentro del repo.
- La ruta productiva ya existe en `generatePlanFromActiveCycle`.
- `generateTrainingPlan` se conservó solo como stub deprecated corto para compatibilidad, con falla explícita y sin lógica duplicada.
- El bloque muerto después del `throw` fue eliminado.
- La ruta productiva no depende del método deprecated.

## 5. Cambios aplicados

- `lib/features/training_feature/providers/training_plan_provider.dart`: se eliminó el bloque legacy/dead code de `generateTrainingPlan`, se dejó un stub deprecated explícito y se retiraron imports huérfanos arrastrados por la rama legacy.
- `test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`: se agregó un canary estático que verifica la ruta productiva y la ausencia del bloque legacy.
- `lib/audit/AUDIT_P2_TRAINING_PROVIDER_LEGACY_REPORT.md`: reporte de auditoría del sprint.

## 6. Política nueva

| Flujo | Antes | Ahora | Riesgo cerrado |
| --- | --- | --- | --- |
| `generateTrainingPlan` | Mezclaba persistencia, compatibilidad y bloque muerto | Stub deprecated corto con falla explícita | Sí |
| `generatePlanFromActiveCycle` | Existía como ruta productiva, pero convivía con legacy ruidoso | Sigue siendo la ruta productiva única | Sí |
| Motor V3 | Quedaba mezclado con compatibilidad legacy en el provider | Se mantiene intacto, sin cambios | Sí |
| Bloque dead code | Existía después del `throw StateError` | Eliminado | Sí |
| Logging legacy | Presente en la ruta inalcanzable | Eliminado con el bloque muerto | Sí |

Casos mínimos:

- `generateTrainingPlan`;
- `generatePlanFromActiveCycle`;
- Motor V3;
- bloque dead code;
- logging legacy.

## 7. Tests agregados

- `generatePlanFromActiveCycle remains the product path`
- `generateTrainingPlan is a short legacy stub without dead code`
- `generatePlanFromActiveCycle does not delegate back to legacy`

## 8. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`

## 9. Resultados

- `flutter analyze --no-pub`: OK, sin issues.
- Validación del canary: OK, 3 tests aprobados.

## 10. Comandos colgados/cancelados

No hubo comandos colgados ni cancelados.

## 11. Archivos modificados

- `lib/features/training_feature/providers/training_plan_provider.dart`
- `test/features/training_feature/providers/training_plan_provider_legacy_contract_test.dart`
- `lib/audit/AUDIT_P2_TRAINING_PROVIDER_LEGACY_REPORT.md`

## 12. Archivos no tocados

No se tocó UI, Motor V3, reglas científicas, reglas Firestore, Firebase bootstrap, `pubspec.yaml`, sync/outbox, nutrición, antropometría ni contratos de payload.

## 13. Riesgos pendientes

- El provider sigue siendo grande; este sprint solo eliminó el bloque legacy/dead code.
- Persisten logs productivos del flujo de Motor V3, pero no eran parte de este sprint.
- No se ejecutó navegación runtime completa.
- La compatibilidad legacy se mantiene solo como stub explícito; si se desea, puede retirarse en un sprint posterior cuando no haya necesidad de API histórica.

## 14. Veredicto final

P2-TRAINING-PROVIDER-LEGACY CERRADO
