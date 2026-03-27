# A05 - MODELOS Y ESTRUCTURAS DE DATOS

## 1) Modelo raiz de dominio
- Archivo: lib/domain/entities/client.dart
- Observacion: Cliente concentra profile/history/nutrition/training + listas historicas.
- Riesgo P1: objeto aggregate muy grande; alto costo de serializacion y riesgo de sobreescritura por merge parcial.

## 2) Modelo antropometria
- Archivo: lib/domain/entities/anthropometry_record.dart
- Uso real: persistencia por fecha y push granular.
- Riesgo: coexistencia de historico local en cliente + subcoleccion remota por fecha.

## 3) Modelo bioquimica
- Archivo: lib/domain/entities/biochemistry_record.dart
- Uso real: filtros por fecha en UI y push remoto por dateKey.
- Riesgo: registros vacios filtrados en repo; semantica de dato ausente vs cero depende de parse UI.

## 4) Modelo nutricion
- Archivo: lib/domain/entities/daily_nutrition_plan.dart
- Uso real: snapshots versionados en nutrition.extra[nutritionPlansV3].
- Riesgo P1: dependencia fuerte de claves dinamicas en Map<String,dynamic> (extra).

## 5) Modelo entrenamiento
- Archivos: training_plan_provider + domain/training_v3/*
- Uso real: plan/ciclo/estado repartido en trainingPlans y training.extra.
- Riesgo P0/P1: dualidad de representacion (listas + extra map) incrementa riesgo de inconsistencia entre UI y motor.

## 6) Campos dinamicos de alto riesgo
- nutrition.extra
- training.extra
- meta payloads en Firestore
- Riesgo transversal: falta de tipado fuerte para claves criticas; errores semanticos no detectables en compile-time.
