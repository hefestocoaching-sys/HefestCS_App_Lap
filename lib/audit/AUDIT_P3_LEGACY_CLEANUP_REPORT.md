# AUDIT P3 LEGACY CLEANUP REPORT

## 1. Resumen ejecutivo

El sprint `P3-LEGACY-CLEANUP` quedó cerrado con limpieza real de deuda legacy inerte y con excepciones justificadas donde todavía existen consumidores reales. Se eliminó `FeatureFlags.useLegacyClientUpdate`, se borraron artefactos `.bak` muertos, se añadió un canary de cleanup CI-friendly y se verificó que los providers con `flutter_riverpod/legacy.dart` siguen dependiendo de APIs legacy reales, por lo que se mantuvieron sin cambiar lógica.

## 2. Hallazgos abordados

- `FeatureFlags.useLegacyClientUpdate` era inerte y ya no gobernaba `ClientsNotifier.updateActiveClient`.
- `ExerciseCatalogLoader` sigue deprecated, pero conserva consumidores reales en producción y en test.
- Persistían imports `flutter_riverpod/legacy.dart` en providers específicos; se auditaron y se documentó la excepción real.
- Había artefactos backup muertos versionados en el árbol; se eliminaron.

## 3. Estado anterior

Antes del cleanup, la deuda visible era esta:

```dart
// lib/core/config/feature_flags.dart
static const bool useLegacyClientUpdate = false;
```

```dart
// lib/features/training_feature/providers/weekly_feedback_provider.dart
import 'package:flutter_riverpod/legacy.dart' as legacy;
```

```dart
// lib/features/training_feature/providers/weekly_progression_provider.dart
import 'package:flutter_riverpod/legacy.dart' as legacy;
```

```dart
// lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart
import 'package:flutter_riverpod/legacy.dart';
```

```dart
// lib/features/training_feature/providers/muscle_progression_tracker_provider.dart
import 'package:flutter_riverpod/legacy.dart' as legacy;
```

```dart
// lib/data/datasources/local/exercise_catalog_loader.dart
class ExerciseCatalogLoader {
  @Deprecated(
    'Legacy wrapper kept for compatibility; runtime SSOT is ExerciseCatalogV3.',
  )
  static List<Exercise>? _cache;
}
```

Artefactos backup detectados antes del cleanup:

- `firebase.json.bak`
- `test/training_v3/motor_v3_orchestrator_test.dart.bak`
- `test/training_v3/engines/volume_engine_test.dart.bak`
- `test/training_v3/engines/periodization_engine_test.dart.bak`
- `test/training_v3/engines/intensity_engine_test.dart.bak`
- `test/training_v3/engines/exercise_selection_engine_test.dart.bak`

## 4. Búsquedas realizadas

| Patrón | Resultado | Decisión |
| --- | --- | --- |
| `useLegacyClientUpdate`, `FeatureFlags.useLegacyClientUpdate`, `_updateActiveClientLegacy` | Solo quedó en reportes/audits; no en flujo productivo | Eliminar el flag inerte y dejar el historial en auditorías |
| `ExerciseCatalogLoader`, `exercise_catalog_loader.dart` | Sigue vivo en `lib/features/training_feature/providers/training_plan_provider.dart` y en `test/verify_fixes.dart`; el loader también sigue su propio archivo | Mantener como wrapper deprecated con excepción documentada |
| `flutter_riverpod/legacy.dart` | Sigue en cuatro providers concretos: `nutrition_blocked_provider.dart`, `muscle_progression_tracker_provider.dart`, `weekly_feedback_provider.dart`, `weekly_progression_provider.dart` | Mantener con excepción documentada; migración no segura porque `flutter_riverpod.dart` no expone esas APIs aquí |
| `.bak`, `.dart.bak`, `backup` | Ya no quedan `.bak` versionados tras eliminar los backups muertos | Borrar artefactos muertos |
| `generateTrainingPlan`, `No se pudo materializar TrainingPlan legacy`, `[TrainingPlanProvider] Generating plan for client` | Sigue en `training_plan_provider.dart` y en contratos/ auditorías relacionadas | No tocar: es legado ya cerrado en su sprint anterior; solo se usó como control |
| `TODO`, `FIXME`, `HACK` | Mucho ruido en reportes, tests y comentarios no accionables | No usar como criterio de borrado sin contexto |
| `@Deprecated`, `Deprecated` | Presente en APIs viejas, wrappers y tests de compatibilidad; mezcla de deprecaciones intencionales y documentación | No borrar por coincidencia textual; revisar contexto por símbolo |

## 5. Decisiones técnicas

| Deuda | Decisión | Justificación | Opciones |
| --- | --- | --- | --- |
| `FeatureFlags.useLegacyClientUpdate` | Eliminado | No tenía consumidores productivos y solo duplicaba mantenimiento | eliminado |
| `_updateActiveClientLegacy` | Mantenido fuera del flujo normal, sin reintroducción | Ya no aparece en `clients_provider.dart`; solo quedó historial documental | mantenido con excepción histórica en reportes |
| `ExerciseCatalogLoader` | Mantenido | Tiene consumidor real en `training_plan_provider.dart` y uso test-only en `test/verify_fixes.dart` | mantenido con excepción |
| `flutter_riverpod/legacy.dart` en cuatro providers | Mantenido | La validación mostró que esas providers dependen de APIs legacy reales; la migración a `flutter_riverpod.dart` falló en análisis | mantenido con excepción |
| `.bak` versionados | Eliminados | Eran copias muertas sin consumidores | eliminado |

## 6. Cambios aplicados

- [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart): se eliminó `useLegacyClientUpdate`.
- [lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart](lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart): se mantuvo el import legacy real.
- [lib/features/training_feature/providers/muscle_progression_tracker_provider.dart](lib/features/training_feature/providers/muscle_progression_tracker_provider.dart): se mantuvo el import legacy real.
- [lib/features/training_feature/providers/weekly_feedback_provider.dart](lib/features/training_feature/providers/weekly_feedback_provider.dart): se mantuvo el import legacy real.
- [lib/features/training_feature/providers/weekly_progression_provider.dart](lib/features/training_feature/providers/weekly_progression_provider.dart): se mantuvo el import legacy real.
- [test/core/config/legacy_cleanup_contract_test.dart](test/core/config/legacy_cleanup_contract_test.dart): se añadió el canary de cleanup.
- [lib/audit/AUDIT_P3_LEGACY_CLEANUP_REPORT.md](lib/audit/AUDIT_P3_LEGACY_CLEANUP_REPORT.md): reporte de cierre del sprint.

## 7. Política nueva

| Legacy | Antes | Ahora | Canary | Casos mínimos |
| --- | --- | --- | --- | --- |
| `useLegacyClientUpdate` | Constante inerte visible | Eliminada | Verifica que no reaparece en `clients_provider.dart` ni en `feature_flags.dart` | ninguna ruta productiva |
| `_updateActiveClientLegacy` | Ruta legacy histórica | No vive en el flujo normal | Verifica ausencia en `clients_provider.dart` | no se reintroduce wide merge |
| `ExerciseCatalogLoader` | Wrapper deprecated | Sigue vivo por consumidores reales | Verifica que sus usos quedan confinados a los consumidores conocidos | `training_plan_provider.dart` y `test/verify_fixes.dart` |
| `flutter_riverpod/legacy.dart` | Import legado disperso | Se mantiene solo donde la API lo exige | Verifica que no se expanda a nuevos archivos | four providers excepcionados |
| `.bak` | Backups muertos | Eliminados | Verifica que no quedan artefactos versionados | ninguno |
| textos legacy de training provider | Stub legacy ya cerrado | Se conservan como control histórico | Verifica que no reaparecen en el path productivo | `generateTrainingPlan` sigue cerrado en su sprint |

## 8. Tests agregados

- `clients provider no longer exposes the legacy wide merge path`
- `feature flags no longer keep the inert legacy client update flag`
- `lib no longer imports flutter_riverpod legacy entrypoints`
- `exercise catalog loader usage stays confined to known consumers`
- `training plan provider keeps legacy training strings out of the path`

## 9. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/core/config/legacy_cleanup_contract_test.dart`

## 10. Resultados

- `flutter analyze --no-pub`: pasó sin issues.
- `flutter test test/core/config/legacy_cleanup_contract_test.dart`: pasó con `All tests passed!`.

## 11. Comandos colgados/cancelados

No hubo comandos colgados ni cancelados en este sprint.

## 12. Archivos modificados

- [lib/core/config/feature_flags.dart](lib/core/config/feature_flags.dart)
- [lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart](lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart)
- [lib/features/training_feature/providers/muscle_progression_tracker_provider.dart](lib/features/training_feature/providers/muscle_progression_tracker_provider.dart)
- [lib/features/training_feature/providers/weekly_feedback_provider.dart](lib/features/training_feature/providers/weekly_feedback_provider.dart)
- [lib/features/training_feature/providers/weekly_progression_provider.dart](lib/features/training_feature/providers/weekly_progression_provider.dart)
- [test/core/config/legacy_cleanup_contract_test.dart](test/core/config/legacy_cleanup_contract_test.dart)
- [lib/audit/AUDIT_P3_LEGACY_CLEANUP_REPORT.md](lib/audit/AUDIT_P3_LEGACY_CLEANUP_REPORT.md)

## 13. Archivos eliminados

- `firebase.json.bak`
- `test/training_v3/motor_v3_orchestrator_test.dart.bak`
- `test/training_v3/engines/volume_engine_test.dart.bak`
- `test/training_v3/engines/periodization_engine_test.dart.bak`
- `test/training_v3/engines/intensity_engine_test.dart.bak`
- `test/training_v3/engines/exercise_selection_engine_test.dart.bak`

## 14. Archivos no tocados

No se tocó UI, Motor V3, reglas científicas, Firebase bootstrap, reglas Firestore, `pubspec.yaml`, sync/outbox, contratos Firestore, nutrición lógica, antropometría ni agenda/pagos.

## 15. Riesgos pendientes

- `ExerciseCatalogLoader` sigue vivo porque tiene consumidores reales; no se retiró.
- `flutter_riverpod/legacy.dart` sigue vivo en cuatro providers porque la migración directa no fue segura.
- `training_plan_provider.dart` sigue usando `ExerciseCatalogLoader`; ese cambio requeriría un sprint aparte con validación funcional más amplia.

## 16. Veredicto final

P3-LEGACY-CLEANUP CERRADO
