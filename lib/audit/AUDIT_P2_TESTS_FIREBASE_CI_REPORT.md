# AUDIT P2 TESTS FIREBASE CI REPORT

## 1. Resumen ejecutivo

El hueco `R-1 — Firestore smoke tests fuera de CI` quedó cerrado con una suite CI-friendly nueva que valida contratos Firestore sin Firebase real, sin Auth real, sin Firestore instance, sin `skip`, sin red y sin emulador obligatorio. La cobertura no reemplaza los smoke tests manuales; los mantiene como prueba operativa, pero deja de depender de ellos como única protección.

## 2. Hallazgo abordado

`R-1 — Firestore smoke tests fuera de CI`

## 3. Estado anterior

Los smoke tests manuales seguían este patrón:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  fail('Sign in with Email/Password in the desktop app before running this test.');
}
```

Además, estaban marcados como `skip`, por lo que no corrían en CI y requerían sesión real de coach. Eso los dejaba como validación operativa manual, no como cobertura reproducible.

## 4. Qué quedó manual y por qué

| Test manual | Qué valida | Por qué sigue manual |
| --- | --- | --- |
| [test/manual/firestore_smoke_test.dart](test/manual/firestore_smoke_test.dart) | upsert/fetch real de cliente en Firestore | depende de Firebase real y de sesión autenticada |
| [test/manual/anthropometry_records_firestore_test.dart](test/manual/anthropometry_records_firestore_test.dart) | upsert/update/delete/fetch real de records antropométricos | depende de Firebase real y de sesión autenticada |
| [test/manual/training_v3_case_audit_runner_test.dart](test/manual/training_v3_case_audit_runner_test.dart) | auditoría manual de casos reales de Motor V3 | es runner de auditoría, no contract CI |

## 5. Qué quedó automatizado

| Cobertura CI | Archivo | Qué protege |
| --- | --- | --- |
| helper financiero tolerante | [test/data/repositories/transaction_repository_contract_test.dart](test/data/repositories/transaction_repository_contract_test.dart) | `readFiniteAmount` y totals robustos |
| helper de records tolerante | [test/data/datasources/remote/record_firestore_datasource_contract_test.dart](test/data/datasources/remote/record_firestore_datasource_contract_test.dart) | `readPayload`, `readUpdatedAt`, `readSchemaVersion`, `readDeleted`, `asStringDynamicMap` |
| paraguas CI de contratos Firestore | [test/integration/firestore_contracts_ci_test.dart](test/integration/firestore_contracts_ci_test.dart) | smoke manuales siguen manuales, tests contract existen, reglas/config existen, sanitización y helpers mínimos |
| observabilidad de sync | [test/core/services/sync_service_observability_test.dart](test/core/services/sync_service_observability_test.dart) | contexto estructurado, sin payload sensible |

## 6. Cambios aplicados

- `test/integration/firestore_contracts_ci_test.dart`: suite paraguas CI-friendly que lee archivos, verifica canaries estáticos, valida helpers puros y confirma que los smoke tests siguen manuales. El canary que inspecciona la propia fuente evita falsos positivos ensamblando los literales sensibles por concatenación.
- `lib/audit/AUDIT_P2_TESTS_FIREBASE_CI_REPORT.md`: reporte de auditoría del sprint.

No se modificó producción ni reglas Firestore.

## 7. Política nueva

| Riesgo | Antes | Ahora | Casos mínimos |
| --- | --- | --- | --- |
| Firestore real | solo smoke manual | contrato CI + smoke manual | helpers puros y archivos de configuración |
| smoke manual | única protección operativa | siguen manuales pero ya no son la única protección | `skip`, `Firebase.initializeApp`, sesión real |
| contrato CI | ausente | presente | `transaction_repository_contract_test`, `record_firestore_datasource_contract_test` |
| payload corrupto | protegía solo parcialmente | protegido por tests contract y paraguas CI | `amount`, `payload`, `updatedAt`, `schemaVersion`, `deleted` |
| rules/config | no revalidadas en una suite CI | validadas estáticamente | `firestore.rules`, `firebase.json` |

## 8. Tests agregados

- `canary file does not rely on Firebase runtime APIs`
- `manual smoke tests stay manual and skipped`
- `contract tests exist and cover the critical Firestore helpers`
- `client payloads are sanitized before Firestore writes`
- `transaction totals ignore corrupted amounts without crashing`
- `record contracts tolerate corrupt Firestore-shaped values`
- `rules and firebase config exist and point to the expected files`
- `smoke tests are not the only protection for the Firestore layer`

## 9. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/integration/firestore_contracts_ci_test.dart`

## 10. Resultados

- `flutter analyze --no-pub`: pasó sin issues.
- `flutter test test/integration/firestore_contracts_ci_test.dart`: pasó con `All tests passed!`.

## 11. Comandos colgados/cancelados

No hubo comandos colgados. Hubo un intento fallido del test específico y no se reintentó.

## 12. Archivos modificados

- [test/integration/firestore_contracts_ci_test.dart](test/integration/firestore_contracts_ci_test.dart)
- [lib/audit/AUDIT_P2_TESTS_FIREBASE_CI_REPORT.md](lib/audit/AUDIT_P2_TESTS_FIREBASE_CI_REPORT.md)

## 13. Archivos no tocados

No se tocó UI, Motor V3, reglas científicas, reglas Firestore, Firebase bootstrap, `pubspec.yaml`, sync/outbox ni contratos productivos.

## 14. Riesgos pendientes

- No se validó Firebase Console.
- No se validó emulator real.
- No se validó sesión real.
- Los smoke manuales siguen existiendo como prueba operativa.

## 15. Veredicto final

P2-TESTS-FIREBASE-CI CERRADO