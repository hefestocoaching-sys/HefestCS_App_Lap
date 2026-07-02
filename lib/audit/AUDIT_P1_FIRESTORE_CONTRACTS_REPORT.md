# AUDIT P1 FIRESTORE CONTRACTS REPORT

## 1. Resumen ejecutivo

Se corrigieron los dos hallazgos P1 confirmados sobre contratos remotos de Firestore.

Resultado:
- `TransactionRepository` ya no rompe los totales del mes cuando `amount` llega mal tipado o no finito.
- `RecordFirestoreDataSource.fetchRecords` ya no rompe lectura/sync cuando un snapshot o sus campos remotos llegan corruptos o con tipo inválido.

El hardening fue pequeño y localizado:
- no se tocó UI;
- no se tocó Motor V3;
- no se tocó entrenamiento;
- no se tocó nutrición;
- no se tocó antropometría;
- no se tocó Firebase bootstrap;
- no se tocaron reglas Firestore.

Veredicto: `P1-FIRESTORE-CONTRACTS CERRADO`

## 2. Hallazgos corregidos

### P1-01 transaction amount unsafe cast

Antes, el cálculo mensual hacía esto:

```dart
return snapshot.docs.fold<double>(
  0.0,
  (total, doc) => total + (doc.data()['amount'] as num).toDouble(),
);
```

Eso rompía el total completo si un documento traía `amount` como `null`, `String`, `bool`, `Map`, `List` o un número no finito.

Ahora, el cálculo usa un parser tolerante y omite solo el documento inválido.

### P1-02 record datasource unsafe casts

Antes, la lectura remota hacía casts directos:

```dart
final data = d.data() as Map<String, dynamic>;
final ts = data['updatedAt'] as Timestamp?;

return RemoteRecordSnapshot(
  dateKey: d.id,
  payload: Map<String, dynamic>.from(data['payload'] ?? {}),
  deleted: data['deleted'] == true,
  schemaVersion: data['schemaVersion'] as int? ?? 1,
  updatedAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
);
```

Eso podía tumbar toda la lectura si el snapshot o algún campo venía mal formado.

Ahora, la lectura usa helpers tolerantes y degrada a valores seguros.

## 3. Estado anterior

### TransactionRepository

Antes:

```dart
(doc.data()['amount'] as num).toDouble()
```

Después:

```dart
final rawAmount = doc.data()['amount'];
final amount = readFiniteAmount(rawAmount);
if (amount == null) {
  return total;
}
return total + amount;
```

### RecordFirestoreDataSource

Antes:

```dart
final data = d.data() as Map<String, dynamic>;
final ts = data['updatedAt'] as Timestamp?;
```

Después:

```dart
final data = asStringDynamicMap(d.data());

return RemoteRecordSnapshot(
  dateKey: d.id,
  payload: readPayload(data['payload']),
  deleted: readDeleted(data['deleted']),
  schemaVersion: readSchemaVersion(data['schemaVersion']),
  updatedAt: readUpdatedAt(data['updatedAt']),
);
```

## 4. Cambios aplicados

### [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart)

- Se añadió `readFiniteAmount(Object? raw)`.
- Se reemplazó el cast directo en `calculateMonthlyIncome`.
- Se reemplazó el cast directo en `calculateMonthlyExpenses`.
- Se descartan documentos inválidos sin tumbar el total.
- Se añadió trazabilidad mínima con `developer.log` cuando se ignora un amount corrupto.

### [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart)

- Se añadió `asStringDynamicMap(Object? value)`.
- Se añadió `readPayload(Object? value)`.
- Se añadió `readUpdatedAt(Object? value)`.
- Se añadió `readSchemaVersion(Object? value)`.
- Se añadió `readDeleted(Object? value)`.
- `fetchRecords` ahora tolera snapshot no tipado, payload inválido, schema viejo y timestamp ausente.

### [test/data/repositories/transaction_repository_contract_test.dart](test/data/repositories/transaction_repository_contract_test.dart)

- Se cubren amounts válidos `int` y `double`.
- Se cubren amounts ausentes, `null`, string, bool, map, list y no finitos.
- Se verifica que el parser no lanza.

### [test/data/datasources/remote/record_firestore_datasource_contract_test.dart](test/data/datasources/remote/record_firestore_datasource_contract_test.dart)

- Se cubre payload válido.
- Se cubre payload ausente e inválido.
- Se cubre coerción de mapas con claves no string.
- Se cubre `schemaVersion` inválido.
- Se cubre `updatedAt` inválido.
- Se cubre `deleted` distinto de `true`.

## 5. Política nueva de parsing remoto

| Campo | Valor válido | Valor inválido | Comportamiento |
| --- | --- | --- | --- |
| `amount` | `num` finito | `null`, ausente, `String`, `bool`, `Map`, `List`, `NaN`, infinito | se ignora el documento para el total |
| `payload` | `Map` con claves string | `null`, ausente, `String`, `List`, `bool`, mapa con claves no string | se degrada a `{}` |
| `updatedAt` | `Timestamp` | ausente o cualquier otro tipo | se usa epoch |
| `schemaVersion` | `int` | cualquier otro tipo | se usa `1` |
| `deleted` | `true` | cualquier otro valor | se trata como `false` |

## 6. Tests agregados

### TransactionRepository

- acepta `int` y `double` válidos;
- ignora `null` y ausentes;
- ignora `String`, `bool`, `Map`, `List`;
- ignora `NaN` e infinitos;
- no lanza excepción.

### RecordFirestoreDataSource

- conserva payload válido;
- degrada payload ausente o inválido a `{}`;
- convierte mapas genéricos con claves string;
- ignora claves no string;
- `schemaVersion` inválido cae a `1`;
- `updatedAt` inválido cae a epoch;
- `deleted` distinto de `true` queda en `false`.

## 7. Comandos ejecutados

- `flutter analyze --no-pub`
- `flutter test test/data/repositories/transaction_repository_contract_test.dart`
- `flutter test test/data/datasources/remote/record_firestore_datasource_contract_test.dart`

## 8. Resultados

- `flutter analyze --no-pub`: pasó sin issues.
- `flutter test test/data/repositories/transaction_repository_contract_test.dart`: pasó.
- `flutter test test/data/datasources/remote/record_firestore_datasource_contract_test.dart`: pasó.

## 9. Comandos colgados/cancelados

No hubo comandos colgados ni cancelados en este sprint.

## 10. Archivos modificados

- [lib/data/repositories/transaction_repository.dart](lib/data/repositories/transaction_repository.dart)
- [lib/data/datasources/remote/record_firestore_datasource.dart](lib/data/datasources/remote/record_firestore_datasource.dart)
- [test/data/repositories/transaction_repository_contract_test.dart](test/data/repositories/transaction_repository_contract_test.dart)
- [test/data/datasources/remote/record_firestore_datasource_contract_test.dart](test/data/datasources/remote/record_firestore_datasource_contract_test.dart)
- [lib/audit/AUDIT_P1_FIRESTORE_CONTRACTS_REPORT.md](lib/audit/AUDIT_P1_FIRESTORE_CONTRACTS_REPORT.md)

## 11. Archivos no tocados

No se tocaron:
- UI;
- Motor V3;
- reglas Firestore;
- Firebase bootstrap;
- `pubspec.yaml`;
- lógica científica de entrenamiento;
- nutrición;
- antropometría;
- App Check;
- Firestore security rules.

## 12. Riesgos pendientes

- No se validó contra Firestore real ni emulator, por instrucción.
- La trazabilidad de documentos corruptos queda en logs ligeros, no en telemetría estructurada.
- Los helpers de parsing están concentrados en estos dos contratos; si aparecen nuevos consumidores remotos, deberán seguir la misma política tolerante.

## 13. Veredicto final

P1-FIRESTORE-CONTRACTS CERRADO