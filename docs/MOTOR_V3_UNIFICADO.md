# Motor V3 Unificado - Documentación Técnica

## 📋 Índice

- [Resumen Ejecutivo](#resumen-ejecutivo)
- [Arquitectura](#arquitectura)
- [Capa 0: Recolección Unificada](#capa-0-recolección-unificada)
- [Capa 1: Normalización y Enriquecimiento](#capa-1-normalización-y-enriquecimiento)
- [Ajustes Israetel](#ajustes-israetel)
- [Uso](#uso)
- [Tests](#tests)

## Resumen Ejecutivo

El **Motor V3 Unificado** es un sistema de dos capas que:

1. **Recolecta** datos de múltiples fuentes del cliente en un snapshot consolidado
2. **Normaliza y enriquece** estos datos aplicando clasificaciones y ajustes científicos

### Problema Resuelto

✅ **Altura NO sincronizada**: Ahora se lee de `AnthropometryRecord.heightCm` con prioridad  
✅ **Datos fragmentados**: Unificados en `ClientDataSnapshot`  
✅ **Ajustes Israetel**: Todos los factores implementados (altura, peso, sueño, experiencia, etc.)  
✅ **Clasificaciones**: Altura, peso, edad, sueño, experiencia  

### Versión

- **VERSION**: v1.0.0
- **FECHA**: 2 de febrero de 2026
- **ESTADO**: Implementación completa de Capas 0 y 1

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENTE                              │
│  - ClientProfile                                             │
│  - TrainingProfile                                           │
│  - AnthropometryRecord[]                                     │
│  - DailyTrackingRecord[]                                     │
│  - TrainingSessionLog[]                                      │
│  - StrengthAssessment[]                                      │
│  - VolumeToleranceProfile{}                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ UnifiedDataCollector.collectClientData()
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  CAPA 0: ClientDataSnapshot                  │
│  - Snapshot consolidado de todas las fuentes                │
│  - Filtrado por ventanas temporales                         │
│  - Selección de últimos registros                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ DataNormalizer.normalize()
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               CAPA 1: NormalizedClientData                   │
│  - Datos normalizados con prioridad de fuentes             │
│  - Clasificaciones (altura, peso, edad, etc.)               │
│  - Ajustes Israetel (altura, sueño, experiencia, etc.)     │
│  - Campos derivados (BMI, categorías, etc.)                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    Motor V3 / ML Engine
```

---

## Capa 0: Recolección Unificada

### ClientDataSnapshot

**Ubicación**: `lib/domain/training_v3/ml/client_data_snapshot.dart`

**Propósito**: Consolidar datos de múltiples fuentes en un solo objeto inmutable.

**Fuentes de datos**:

| Fuente | Campo en Snapshot | Descripción |
|--------|------------------|-------------|
| Client.profile | `clientProfile` | Perfil básico (nombre, email, fecha nacimiento) |
| Client.training | `trainingProfile` | Perfil completo de entrenamiento |
| Client.anthropometry | `latestAnthropometry` | Último registro antropométrico |
| Client.anthropometry | `anthropometryHistory` | Todos los registros (para tendencias) |
| Client.tracking | `recentDailyTracking` | Últimos 28 días (4 semanas) |
| Client.sessionLogs | `recentSessionLogs` | Últimos 56 días (8 semanas) |
| Client.strengthAssessments | `strengthAssessments` | Todas las evaluaciones de fuerza |
| Client.training.pastVolumeTolerance | `volumeToleranceByMuscle` | Perfiles de tolerancia por músculo |

**Helpers**:

```dart
snapshot.hasAnthropometry       // ¿Hay datos antropométricos?
snapshot.hasTracking            // ¿Hay datos de tracking?
snapshot.hasSessionLogs         // ¿Hay logs de sesiones?
snapshot.hasStrengthData        // ¿Hay evaluaciones de fuerza?
snapshot.trackingWeeksAvailable // Semanas de datos de tracking
snapshot.sessionLogsWeeksAvailable // Semanas de logs de sesiones
```

### UnifiedDataCollector

**Ubicación**: `lib/domain/training_v3/ml/unified_data_collector.dart`

**Método principal**:

```dart
static Future<ClientDataSnapshot> collectClientData(
  Client client, {
  DateTime? asOfDate,
});
```

**Lógica**:

1. Selecciona **último** registro antropométrico por fecha
2. Filtra tracking diario: últimos **28 días** (4 semanas)
3. Filtra session logs: últimos **56 días** (8 semanas)
4. Extrae evaluaciones de fuerza
5. Extrae perfiles de tolerancia al volumen

**Configuración**:

```dart
static const int trackingWindowDays = 28;      // 4 semanas
static const int sessionLogsWindowDays = 56;   // 8 semanas
```

---

## Capa 1: Normalización y Enriquecimiento

### NormalizedClientData

**Ubicación**: `lib/domain/training_v3/ml/normalized_client_data.dart`

**Propósito**: Representar datos normalizados y enriquecidos con todos los ajustes Israetel.

**Estructura**:

#### A) Demographics

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `age` | int? | TrainingProfile.age > calculado | Edad en años |
| `gender` | String? | TrainingProfile.gender | 'male', 'female', 'other' |
| `ageCategory` | String? | calculado | 'youth', 'adult', 'middle', 'senior' |

#### B) Anthropometrics ⭐⭐⭐

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `heightCm` | double? | **AnthropometryRecord.heightCm** > TrainingProfile.extra | ⭐ CRÍTICO: Altura sincronizada |
| `weightKg` | double? | AnthropometryRecord.weightKg > TrainingProfile.bodyWeight | Peso |
| `bmi` | double? | calculado | Índice de masa corporal |
| `heightClass` | String? | calculado | 'very_short', 'short', 'average', 'tall', 'very_tall' |
| `weightClass` | String? | calculado | 'underweight', 'normal', 'overweight', 'obese' |
| `heightAdjustmentVME` | double | calculado | Ajuste VME por altura (0.90-1.10) |
| `heightAdjustmentVMR` | double | calculado | Ajuste VMR por altura (0.90-1.10) |
| `weightAdjustmentVME` | double | calculado | Ajuste VME por peso (0.95-1.05) |
| `weightAdjustmentVMR` | double | calculado | Ajuste VMR por peso (0.95-1.05) |

#### C) Physical Capacity

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `strengthClass` | String? | calculado desde PRs | 'class_III', 'class_II', 'class_I', 'master', 'elite' |
| `workCapacity` | int? | TrainingProfile.extra | Capacidad de trabajo (1-5) |
| `recoveryCapacity` | int? | TrainingProfile.extra | Capacidad de recuperación (1-5) |

#### D) Recovery Profile

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `avgSleepHours` | double? | TrainingProfile.avgSleepHours | Promedio de horas de sueño |
| `sleepCategory` | String? | calculado | '<5h', '5-7h', '7-9h', '>9h' |
| `physicalStress` | int? | TrainingProfile.extra | Estrés físico (1-5) |
| `nonPhysicalStress` | int? | TrainingProfile.extra | Estrés no físico (1-5) |
| `avgHRV` | double? | promedio DailyTracking | Heart Rate Variability |
| `avgRHR` | double? | promedio DailyTracking | Resting Heart Rate |
| `sleepAdjustmentVME` | double | calculado | Ajuste VME por sueño (0.80-1.05) |
| `sleepAdjustmentVMR` | double | calculado | Ajuste VMR por sueño (0.80-1.05) |
| `stressAdjustmentVME` | double | calculado | Ajuste VME por estrés (0.85-1.0) |
| `stressAdjustmentVMR` | double | calculado | Ajuste VMR por estrés (0.85-1.0) |

#### E) Training Experience

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `effectiveLevel` | String? | calculado | 'beginner', 'intermediate', 'advanced', 'expert' |
| `subpopulation` | String? | calculado | 'novice', 'beginner', 'intermediate', 'advanced', 'elite', 'master' |
| `programNovelty` | double | calculado | Novedad del programa (0.0-1.0) |
| `experienceAdjustmentVME` | double | calculado | Ajuste VME por experiencia (0.80-1.15) |
| `experienceAdjustmentVMR` | double | calculado | Ajuste VMR por experiencia (0.80-1.15) |
| `noveltyAdjustmentVME` | double | calculado | Ajuste VME por novedad (0.85-1.0) |
| `noveltyAdjustmentVMR` | double | calculado | Ajuste VMR por novedad (0.85-1.0) |

#### F) Historical Volume (ML)

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `observedLimitsByMuscle` | Map<String, ObservedVolumeLimits> | calculado desde logs | Límites observados por músculo |

#### G) Pharmacology

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `usesAnabolics` | bool | TrainingProfile.usesAnabolics | ¿Usa anabólicos? |
| `anabolicsAdjustmentVMR` | double | calculado | Ajuste VMR por anabólicos (1.0 o 1.15) |

#### H) Rest & Recovery

| Campo | Tipo | Fuente | Descripción |
|-------|------|--------|-------------|
| `restBetweenSetsSeconds` | int? | TrainingProfile.restBetweenSetsSeconds | Descanso entre series |
| `restAdjustmentFatigue` | double | calculado | Ajuste de fatiga por descanso (1.0 o 1.8) |

**Helpers**:

```dart
normalized.totalVMEAdjustment    // Producto de todos los ajustes VME
normalized.totalVMRAdjustment    // Producto de todos los ajustes VMR
normalized.hasMinimalData        // ¿Hay datos mínimos para cálculos?
normalized.hasSleepData          // ¿Hay datos de sueño?
normalized.hasVolumeHistory      // ¿Hay historial de volumen?
```

### DataNormalizer

**Ubicación**: `lib/domain/training_v3/ml/data_normalizer.dart`

**Método principal**:

```dart
static NormalizedClientData normalize(ClientDataSnapshot snapshot);
```

**Proceso de normalización**:

1. **Extrae Demographics** (age, gender, ageCategory)
2. **Extrae Anthropometrics** con prioridad: AnthropometryRecord > TrainingProfile
3. **Calcula BMI** y clasifica altura/peso
4. **Aplica ajustes Israetel** por altura
5. **Extrae Physical Capacity** (fuerza, trabajo, recuperación)
6. **Extrae Recovery Profile** (sueño, estrés, HRV, RHR)
7. **Aplica ajustes Israetel** por sueño y estrés
8. **Extrae Training Experience** (años, nivel, subpoblación)
9. **Aplica ajustes Israetel** por experiencia y novedad
10. **Extrae Historical Volume** (límites observados por músculo - placeholder)
11. **Aplica ajustes** por anabólicos y descanso

---

## Ajustes Israetel

Todos los ajustes están basados en la investigación de Dr. Mike Israetel (Semanas 1-2 del PDF):

### Altura

| Altura | Clasificación | Ajuste VME/VMR |
|--------|--------------|----------------|
| < 160 cm | very_short | -10% (0.90) |
| 160-170 cm | short | -10% (0.90) |
| 170-180 cm | average | Normal (1.0) |
| 180-190 cm | tall | +10% (1.10) |
| > 190 cm | very_tall | +10% (1.10) |

**Razón**: Personas más altas tienen más masa muscular total → mayor capacidad de volumen.

### Peso (BMI)

| BMI | Clasificación | Ajuste VME/VMR |
|-----|--------------|----------------|
| < 18.5 | underweight | -5% (0.95) |
| 18.5-25 | normal | Normal (1.0) |
| 25-30 | overweight | +5% (1.05) |
| > 30 | obese | +5% (1.05) |

**Razón**: Mayor masa (muscular o grasa) → mayor capacidad de volumen.

### Sueño

| Horas | Categoría | Ajuste VME/VMR |
|-------|-----------|----------------|
| < 6h | <5h | -20% (0.80) |
| 6-7h | 5-7h | -10% (0.90) |
| 7-9h | 7-9h | Normal (1.0) |
| > 9h | >9h | +5% (1.05) |

**Razón**: Sueño insuficiente → menor recuperación → menor capacidad de volumen.

### Estrés

| Estrés Total | Ajuste VME/VMR |
|--------------|----------------|
| ≤ 7 | Normal (1.0) |
| > 7 | -15% (0.85) |

**Razón**: Estrés alto (físico + no físico) → menor capacidad de recuperación.

### Experiencia

| Años | Nivel | Subpoblación | Ajuste VME/VMR |
|------|-------|--------------|----------------|
| < 1 | beginner | novice | -20% (0.80) |
| 1-3 | intermediate | beginner | Normal (1.0) |
| 3-6 | advanced | intermediate | Normal (1.0) |
| 6-10 | advanced | advanced | +15% (1.15) |
| > 10 | expert | elite | +15% (1.15) |

**Razón**: Principiantes necesitan menos volumen para progresar; avanzados toleran más.

### Novedad del Programa

| Novedad | Ajuste VME/VMR |
|---------|----------------|
| ≤ 0.7 | Normal (1.0) |
| > 0.7 | -15% (0.85) |

**Razón**: Programas nuevos requieren adaptación → empezar conservador.

### Anabólicos

| Uso | Ajuste VMR |
|-----|------------|
| No | Normal (1.0) |
| Sí | +15% (1.15) |

**Razón**: Anabólicos aumentan capacidad de recuperación y síntesis proteica.

### Descanso entre Series

| Descanso | Ajuste Fatiga |
|----------|--------------|
| ≥ 120s | Normal (1.0) |
| < 120s | 1.8x (80% más fatiga) |

**Razón**: Descanso corto → mayor fatiga metabólica.

---

## Uso

### Ejemplo Básico

```dart
import 'package:hcs_app_lap/domain/training_v3/ml/unified_data_collector.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/data_normalizer.dart';

// 1. Recolectar datos del cliente
final snapshot = await UnifiedDataCollector.collectClientData(client);

// 2. Normalizar y enriquecer
final normalized = DataNormalizer.normalize(snapshot);

// 3. Usar datos normalizados
print('Altura: ${normalized.heightCm} cm');
print('Ajuste VME total: ${normalized.totalVMEAdjustment}');
print('Ajuste VMR total: ${normalized.totalVMRAdjustment}');
```

### Ejemplo con Verificación de Datos

```dart
final snapshot = await UnifiedDataCollector.collectClientData(client);
final normalized = DataNormalizer.normalize(snapshot);

// Verificar datos mínimos
if (!normalized.hasMinimalData) {
  print('⚠️ Faltan datos antropométricos básicos');
  return;
}

// Verificar datos de sueño
if (!normalized.hasSleepData) {
  print('⚠️ No hay datos de sueño, usando default');
}

// Verificar historial de volumen
if (normalized.hasVolumeHistory) {
  print('✅ Hay historial de volumen para ajuste ML');
} else {
  print('⚠️ No hay historial, usar valores teóricos');
}
```

### Ejemplo de Cálculo VME/VMR Ajustado

```dart
final normalized = DataNormalizer.normalize(snapshot);

// VME base teórico (por ejemplo, pecho: 10 sets/semana)
const double baseMEV = 10.0;

// VME ajustado
final adjustedMEV = baseMEV * normalized.totalVMEAdjustment;

print('VME base: $baseMEV sets/semana');
print('VME ajustado: ${adjustedMEV.toStringAsFixed(1)} sets/semana');
print('Factores aplicados:');
print('  - Altura: ${normalized.heightAdjustmentVME}');
print('  - Peso: ${normalized.weightAdjustmentVME}');
print('  - Sueño: ${normalized.sleepAdjustmentVME}');
print('  - Estrés: ${normalized.stressAdjustmentVME}');
print('  - Experiencia: ${normalized.experienceAdjustmentVME}');
print('  - Novedad: ${normalized.noveltyAdjustmentVME}');
```

---

## Tests

**Ubicación**: `test/motor_v3_unificado_test.dart`

### Cobertura de Tests

#### Layer 0: UnifiedDataCollector

- ✅ Creación de snapshot con todos los datos
- ✅ Selección del último registro antropométrico
- ✅ Filtrado de tracking por ventana temporal (28 días)
- ✅ Filtrado de logs de sesiones por ventana temporal (56 días)
- ✅ Helpers del snapshot (hasAnthropometry, hasTracking, etc.)
- ✅ Manejo de cliente sin datos

#### Layer 1: DataNormalizer

- ✅ Extracción de demographics (age, gender, ageCategory)
- ✅ Prioridad de fuentes (AnthropometryRecord > TrainingProfile)
- ✅ Cálculo de BMI
- ✅ Clasificación de altura (5 categorías)
- ✅ Clasificación de peso (4 categorías)
- ✅ Ajustes Israetel por altura (±10%)
- ✅ Ajustes Israetel por sueño (-20% a +5%)
- ✅ Ajustes Israetel por experiencia (-20% a +15%)
- ✅ Ajuste por anabólicos (+15% VMR)
- ✅ Ajuste por descanso entre series (1.8x fatiga)
- ✅ Cálculo de ajustes totales (VME y VMR)
- ✅ Manejo de datos faltantes

#### Integración

- ✅ Pipeline completo: Client → Snapshot → Normalized
- ✅ Verificación de todos los campos
- ✅ Verificación de helpers

### Ejecutar Tests

```bash
# Todos los tests del Motor V3
flutter test test/motor_v3_unificado_test.dart

# Todos los tests del proyecto
flutter test
```

---

## Pendientes (TODO)

### Implementación Futura

1. **Conversión SessionSummaryLog → TrainingSessionLogV2**
   - Actualmente `UnifiedDataCollector._filterRecentSessionLogsV2()` retorna lista vacía
   - Se necesita mapeo entre formatos

2. **Cálculo de límites históricos de volumen**
   - Implementar `DataNormalizer._extractHistoricalVolume()`
   - Calcular MEV/MAV/MRV observados desde logs
   - Calcular confianza basada en cantidad de datos

3. **Clasificación de fuerza desde PRs**
   - Implementar cálculo de Wilks/IPF
   - Clasificar en: 'class_III', 'class_II', 'class_I', 'master', 'elite'

4. **Cálculo de novedad del programa**
   - Comparar plan actual vs anteriores
   - Calcular similaridad (0.0-1.0)

5. **Campos adicionales en DailyTrackingRecord**
   - Agregar: sleep, HRV, RHR
   - Calcular promedios en DataNormalizer

6. **Integración con Motor V3**
   - Usar NormalizedClientData en lugar de TrainingContext
   - Aplicar ajustes totales a VME/VMR base

---

## Referencias

### Documentos del Proyecto

- [MOTOR_V3_COMPLETION.md](../MOTOR_V3_COMPLETION.md) - Especificación original
- [SESION_01_FEBRERO_2026.md](../SESION_01_FEBRERO_2026.md) - Requisitos del issue
- [ARCHITECTURE_SUMMARY.md](../ARCHITECTURE_SUMMARY.md) - Arquitectura general

### Archivos Relacionados

- `lib/domain/training_v2/models/training_context.dart` - TrainingContext (v2)
- `lib/domain/training_v3/ml/feature_vector.dart` - FeatureVector para ML
- `lib/domain/entities/anthropometry_record.dart` - AnthropometryRecord
- `lib/domain/entities/training_profile.dart` - TrainingProfile
- `lib/domain/entities/daily_tracking_record.dart` - DailyTrackingRecord
- `lib/domain/entities/training_session_log.dart` - TrainingSessionLogV2

### Investigación Científica

- **Israetel et al.** (2020-2024): MEV/MAV/MRV, volume landmarks
- **Schoenfeld et al.** (2017-2021): Dose-response, proximity to failure
- **Helms et al.** (2018-2023): RPE/RIR autoregulation, readiness markers
- **NSCA** (2022): Recovery, fatigue management

---

## Changelog

### v1.0.0 (2 de febrero de 2026)

**Added**:
- ✅ ClientDataSnapshot - Snapshot consolidado de datos del cliente
- ✅ UnifiedDataCollector - Recolector unificado de datos
- ✅ NormalizedClientData - Modelo de datos normalizados y enriquecidos
- ✅ DataNormalizer - Normalizador y enriquecedor de datos
- ✅ ObservedVolumeLimits - Límites de volumen observados por músculo
- ✅ Tests completos (15+ tests unitarios + 1 integración)

**Fixed**:
- ✅ Altura ahora se sincroniza desde AnthropometryRecord.heightCm
- ✅ Datos fragmentados ahora consolidados en un solo lugar
- ✅ Todos los ajustes Israetel implementados

**Changed**:
- ⚠️ SessionSummaryLog → TrainingSessionLogV2 pendiente de implementar

---

**Última actualización**: 2 de febrero de 2026  
**Autor**: Motor V3 Implementation Team  
**Estado**: ✅ Completo (Capas 0 y 1)
