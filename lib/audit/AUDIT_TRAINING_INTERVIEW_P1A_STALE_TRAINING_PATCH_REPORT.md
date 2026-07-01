# AUDIT TRAINING-INTERVIEW-P1A STALE TRAINING PATCH REPORT

## 1. Resumen ejecutivo

Se corrigio el guardado de `TrainingInterviewTab` para eliminar el patron inseguro que copiaba una seccion completa de `training` desde un snapshot local.

Antes el save construia `updatedClient` desde `_client/currentClient` y luego copiaba:

```dart
training: updatedClient.training
```

Ahora el save usa el helper granular:

```dart
updateActiveClientTraining(applyInterviewPatch)
```

El patch se aplica contra `previous`, que viene del cliente fresco rehidratado por `ClientsNotifier`.

## 2. Riesgo P1 original

El riesgo P1 estaba en:

`lib/features/training_feature/tabs/training_interview_tab.dart`

Patron original:

```dart
final updatedClient = currentClient.copyWith(training: updatedTraining);

await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
  return prev.copyWith(training: updatedClient.training);
});
```

Riesgo:

- `_client/currentClient` puede estar stale;
- `updatedClient.training` representa una seccion completa de `TrainingProfile`;
- si otro flujo modifico `training` entre lectura y save, se podian perder subramas;
- violaba la estrategia de helpers granulares de `clientsProvider`.

## 3. Flujo anterior

Metodo que guarda:

`saveIfDirty()`

Flujo anterior:

1. Validaba `_isDirty` y `_client`.
2. Ejecutaba `_formState.validateLocal()`.
3. Construia `values` con `_formState.toValues(...)`.
4. Derivaba `derivedLevel`.
5. Calculaba `volume` con `computeTrainingVolume(...)`.
6. Construia `updatedTraining` con:

```dart
TrainingProfileFormMapper.apply(
  base: currentClient.training,
  input: values,
  volume: volume,
)
```

7. Construia `updatedClient = currentClient.copyWith(training: updatedTraining)`.
8. Validaba `evaluateTrainingInterview(updatedTraining.extra)`.
9. Guardaba copiando `updatedClient.training` dentro de `updateActiveClient`.
10. Ejecutaba `_computeAndPersistLandmarks()`.

Habia otro save en la tab:

- `_computeAndPersistLandmarks()` usa `updateActiveClient` para patch de `prev.training.extra`.
- Ese uso esta basado en `prev.training` y no copia `updatedClient.training`, por lo que no era el P1 de este sprint.

## 4. Flujo nuevo

`saveIfDirty()` ahora declara:

```dart
TrainingProfile applyInterviewPatch(TrainingProfile previous) {
  return TrainingProfileFormMapper.apply(
    base: previous,
    input: values,
    volume: volume,
  );
}
```

Despues:

1. Calcula `updatedTraining = applyInterviewPatch(currentClient.training)` solo para validacion local y fallback de retorno.
2. Valida `evaluateTrainingInterview(updatedTraining.extra)`.
3. Guarda con:

```dart
final savedClient = await ref
    .read(clientsProvider.notifier)
    .updateActiveClientTraining(applyInterviewPatch);
```

4. Retorna `savedClient` si existe, o fallback local si el helper no devolvio cliente.

## 5. Campos reales de TrainingProfile modificados por la entrevista

El mapper real es:

`TrainingProfileFormMapper.apply`

Campos top-level de `TrainingProfile` que modifica:

- `gender`
- `age`
- `bodyWeight`
- `usesAnabolics`
- `trainingLevel`
- `yearsTrainingContinuous`
- `priorityMusclesPrimary`
- `priorityMusclesSecondary`
- `priorityMusclesTertiary`
- `extra`
- `date`

Claves principales de `extra` que escribe o actualiza:

- `heightCm`
- `weightKg`
- `ageYears`
- `trainingMonths`
- `trainingYears`
- `effectiveTrainingLevel`
- `trainingLevelDerived`
- `trainingLevel`
- `strengthLevelClass`
- `workCapacityScore`
- `recoveryHistoryScore`
- `externalRecoverySupport`
- `programNoveltyClass`
- `externalPhysicalStressLevel`
- `nonPhysicalStressLevel2`
- `restQuality2`
- `dietHabitsClass`
- `usesAnabolics`
- `activeInjuries`
- `injuries`
- `detailedInjuryHistory`
- `injurySeverity`
- `injuryStatus`
- `backFocus`
- `priorityMusclesPrimary`
- `priorityMusclesSecondary`
- `priorityMusclesTertiary`
- `vmeBase`
- `vmrBase`
- `vmeAdjustTotal`
- `vmrAdjustTotal`
- `deltaVmeGlobal`
- `deltaVmrGlobal`
- `vmeCalculated`
- `vmrCalculated`
- `vopCalculated`
- `mevIndividual`
- `mrvIndividual`

Tambien limpia payload legacy de entrevista y remueve `mevByMuscle`/`mrvByMuscle` porque el mapper ya lo hacia antes.

## 6. Por que el nuevo patch preserva ramas no editadas

Antes, el guardado copiaba una seccion `TrainingProfile` completa desde `currentClient`.

Ahora `TrainingProfileFormMapper.apply` recibe `base: previous`, donde `previous` es el `TrainingProfile` fresco que `ClientsNotifier.updateActiveClientTraining` obtiene desde la ruta hardenizada de `updateActiveClient`.

Esto conserva:

- subramas top-level de `TrainingProfile` no tocadas por el mapper;
- `extra` fresco de `previous`, porque el mapper inicia con `Map<String, dynamic>.from(base.extra)`;
- el deep merge de `TrainingProfile.copyWith(extra: ...)`;
- el merge adicional de `ClientsNotifier.updateActiveClient` para `training.extra`.

## 7. Cambios en TrainingInterviewTab

Archivo:

`lib/features/training_feature/tabs/training_interview_tab.dart`

Cambios:

- agregado import de `TrainingProfile`;
- agregado helper local `applyInterviewPatch(TrainingProfile previous)`;
- eliminado `updatedClient = currentClient.copyWith(training: updatedTraining)`;
- eliminado `prev.copyWith(training: updatedClient.training)`;
- reemplazado save por `updateActiveClientTraining(applyInterviewPatch)`;
- preservada la validacion local y el snack visible existente;
- no se cambiaron labels, layout ni flujo visual.

## 8. Uso de updateActiveClientTraining

Si. El guardado de entrevista usa:

```dart
updateActiveClientTraining(applyInterviewPatch)
```

No se pasa un `Client updatedClient` completo desde la tab.

## 9. Tests creados/ajustados

Se intento crear:

`test/features/training_feature/training_interview_patch_contract_test.dart`

El test era un canary estatico simple, pero `flutter test` se colgo dos veces sin imprimir salida. Para no dejar un archivo nuevo colgante en el repo, se elimino el archivo creado en este sprint y se movio el canary a un test existente estable:

`test/features/main_shell/providers/clients_provider_hardening_test.dart`

Canary agregado:

- falla si `training_interview_tab.dart` contiene `training: updatedClient.training`;
- falla si contiene `prev.copyWith(training: updatedClient.training)`;
- exige `updateActiveClientTraining(applyInterviewPatch)`;
- exige `base: previous`.

## 10. Comandos ejecutados

Lecturas minimas autorizadas por el usuario despues de aclaracion:

```powershell
Get-Content lib\features\training_feature\tabs\training_interview_tab.dart | Select-Object -First 260
Get-Content lib\features\main_shell\providers\clients_provider.dart | Select-Object -First 320
Get-Content lib\features\main_shell\providers\clients_provider.dart | Select-Object -Last 220
Get-Content lib\domain\entities\training_profile.dart | Select-Object -First 260
Get-Content lib\domain\entities\training_profile.dart | Select-Object -Last 260
Get-Content lib\domain\entities\client.dart | Select-Object -Last 160
Get-Content lib\features\training_feature\services\training_profile_form_mapper.dart | Select-Object -First 260
Get-Content lib\features\training_feature\services\training_profile_form_mapper.dart | Select-Object -Last 240
Get-Content lib\features\training_feature\services\training_profile_form_mapper.dart | Select-Object -Skip 180 -First 180
Get-Content test\features\main_shell\providers\clients_provider_hardening_test.dart | Select-Object -First 240
Get-Content test\data\repositories\client_repository_outbox_test.dart | Select-Object -First 140
Get-Content test\data\repositories\client_repository_sync_test.dart | Select-Object -First 230
```

Validacion:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\training_interview_patch_contract_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat analyze --no-pub
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\clients_provider_hardening_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
```

Empaquetado final:

```powershell
Compress-Archive -Path lib -DestinationPath lib.zip -Force
Compress-Archive -Path test -DestinationPath test.zip -Force
```

Salida:

```text
Sin salida. Exit code 0.
```

## 11. Comandos cancelados

Comando cancelado 1:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\training_interview_patch_contract_test.dart --reporter expanded
```

Estado:

```text
Sin salida durante ~90 s.
Ctrl+C no soportado por el backend.
Con autorizacion explicita del usuario se identifico y cerro el PID 4220.
```

Comando cancelado 2:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\training_feature\training_interview_patch_contract_test.dart --reporter expanded
```

Estado:

```text
Sin salida durante ~90 s.
Ctrl+C no soportado por el backend.
Con autorizacion explicita del usuario se identifico y cerro el PID 20028.
No se hicieron mas reintentos.
```

Decision:

- El test nuevo no quedo en el repo.
- El canary se movio al hardening existente y paso.

## 12. Resultado de flutter analyze --no-pub

```text
Analyzing hcs_app_lap...
No issues found! (ran in 3.0s)
```

## 13. Resultado de tests especificos ejecutados

### training_interview_patch_contract_test.dart

```text
Cancelado dos veces por cuelgue sin salida.
Archivo eliminado por no ser viable en este entorno.
```

### clients_provider_hardening_test.dart

```text
00:00 +6: All tests passed!
```

Incluye el canary nuevo:

```text
ClientsProvider hardening training interview saves with granular previous-based patch
```

### client_repository_outbox_test.dart

```text
00:00 +5: All tests passed!
```

Los warnings de permission-denied/payload invalid son escenarios esperados del test.

### client_repository_sync_test.dart

```text
00:00 +8: All tests passed!
```

Los errores/warnings impresos son escenarios simulados esperados del test.

## 14. Archivos modificados

- `lib/features/training_feature/tabs/training_interview_tab.dart`
- `test/features/main_shell/providers/clients_provider_hardening_test.dart`
- `lib/audit/AUDIT_TRAINING_INTERVIEW_P1A_STALE_TRAINING_PATCH_REPORT.md`

Archivo creado y eliminado durante el sprint por no ser viable:

- `test/features/training_feature/training_interview_patch_contract_test.dart`

## 15. Archivos no tocados

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
- agenda/pagos
- auth
- App Check
- observabilidad
- SAVE-P0E
- outbox clinico
- Historia Clinica
- Nutricion
- Macros
- Antropometria
- Bioquimica
- CLIENT-STATUS-P1A productivo

## 16. Riesgos pendientes reales

1. El canary nuevo independiente se colgo antes de cargar en este entorno, aunque era estatico. Para evitar deuda, no quedo en el repo.
2. La cobertura final del patron prohibido vive en `clients_provider_hardening_test.dart`, que paso.
3. `_computeAndPersistLandmarks()` sigue usando `updateActiveClient`, pero su transform se basa en `prev.training` y no copia `updatedClient.training`; no fue cambiado por estar fuera del P1 detectado.

## 17. Veredicto

TRAINING-INTERVIEW-P1A CERRADO
