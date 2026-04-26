# AUDITORÍA QUIRÚRGICA: LANDMARKS, VME/VMR/VOP EN MOTOR V3

**Fecha:** 8 de abril de 2026  
**Alcance:** Flujo completo desde valoración hasta generación  
**Audiencia:** Arquitectura de motor, no teoría general  

---

## 1. RESUMEN EJECUTIVO

### Cómo funciona hoy

El motor actual tiene **DOS métodos de cálculo de VOP que compiten y se anulan mutuamente**:

1. **Método A (Correcto)** – `training_interview_tab._postSaveRecomputeAndRegen()` (línea ~1243–1424)
   - Usa `VolumeIndividualizationService.computeBounds()` → MEV/MRV general del sujeto
   - Usa `VolumeByMuscleDerivationService.derive()` → Distribución por músculo con factores (1.30 glutes, 1.25 quads, etc.)
   - Persiste: `mevByMuscle`, `mrvByMuscle`, `targetSetsByMuscle`
   - **Nunca se ejecuta en el flujo actual**

2. **Método B (Incorrecto)** – `training_interview_tab._computeAndPersistLandmarks()` (línea ~1223–1237)
   - Llama `LandmarkEngine.calculateFromProfile()`
   - Lee `targetSetsByMuscle` del perfil (que puede estar vacío o obsoleto)
   - **Invierte la lógica**: `vme = vop * 0.6`, `vmr = vop * 1.4`
   - Genera landmarks por músculo que contradicen el modelo teórico
   - **Sí se ejecuta y persiste landmarks invertidos**

### Por qué NO está alineado con Semana 2

**Modelo esperado (PDF Semana 2, hoja 10):**
```
Principiante:  VME = 6  →  VMR = 16  (base global del sujeto)
Intermedio:    VME = 12 →  VMR = 24  (base global del sujeto)
Avanzado:      VME = 18 →  VMR = 32  (base global del sujeto)

Entonces:
  VOP = VME + 35% × (VMR - VME)
  
  Principiante: VOP = 6 + 0.35 × (16-6) = 9.5 ≈ 10 sets
  Intermedio:   VOP = 12 + 0.35 × (24-12) = 16.2 ≈ 16 sets
  Avanzado:     VOP = 18 + 0.35 × (32-18) = 22.9 ≈ 23 sets

La tabla de la hoja 9 suma/resta series PARA AJUSTAR esos valores base.
Luego se distribuyen por músculo (con factores como 1.30, 0.85).
```

**Modelo actual (código real):**
```
1. Genera targetSetsByMuscle = (mev + mrv) / 2  ← CORRECTO EN IDEA
2. Lee ese target como VOP  ← INCORRECTO EN ORDEN
3. Deriva: vme = vop × 0.6, vmr = vop × 1.4  ← INVERTIDO
4. Persiste landmarks "invertidos"
5. Motor lee VOP de esos landmarks y lo usa como volumen inicial

RESULTADO: El volumen inicial es basado en un VOP que fue derivado
al revés, NO calculado desde los bounds generales del sujeto.
```

### Gravedad del problema

**CRÍTICA (P0):**
- El motor no está calculando VOP desde el modelo correcto (nivel sujeto → distribución músculo)
- Está usando LandmarkEngine que invierte la lógica matemática  
- La entrevista calcula correctamente pero esos cálculos se pierden
- El flujo real no usa `mevByMuscle`/`mrvByMuscle` que se persisten

**Impacto clínico:**
- Volumen inicial (VOP) es incorrecto por músculo
- Rango de progresión (VME→VMR) es matemáticamente inverso
- La bitácora progresa dentro de un rango que no refleja la capacidad real del sujeto
- Cada atleta genera un programa con landmarks que no corresponden a su nivel real

---

## 2. FLUJO ACTUAL REAL DE LANDMARKS

### Fase 1: Entrevista → Mapper (Training Interview Tab)

**Línea:** 1243–1424 en `training_interview_tab.dart`

```
Entrevista guardada
    ↓
_computeAndPersistLandmarks() {
    ├─ LandmarkEngine.calculateFromProfile(prev.training)
    │   ├─ Lee profile.extra['targetSetsByMuscle']  ← Puede estar vacío
    │   ├─ INVIERTE: vme = vop × 0.6
    │   ├─ INVIERTE: vmr = vop × 1.4
    │   └─ Genera Landmarks(vme, vop, vmr) por músculo
    │
    ├─ Serializa con LandmarkEngine.serializeByCanonicalKey()
    ├─ Persiste en training.extra['muscleLandmarks']
    └─ Pone flowStage = TrainingFlowStage.landmarks
}
```

**Lo que NO se ejecuta actualmente:**

```
_postSaveRecomputeAndRegen() {  ← CÓDIGO HUÉRFANO (nunca se llama)
    ├─ VolumeIndividualizationService.computeBounds()
    │   ├─ Nivel sujeto (beginner/intermediate/advanced)
    │   ├─ Sumador aditivo con 14 factores (género, edad, etc.)
    │   └─ Retorna: mevIndividual, mrvIndividual (globales)
    │
    ├─ VolumeByMuscleDerivationService.derive()
    │   ├─ Aplica factores clínicos por músculo (1.30 glutes, etc.)
    │   └─ Retorna: mevByMuscle, mrvByMuscle (por músculo)
    │
    ├─ targetSetsByMuscle = (mev + mrv) / 2 por cada músculo
    ├─ Distribución por prioridad (primary: 45%, secondary: 35%, tertiary: 20%)
    ├─ Distribuye por intensidad (heavy: %, medium: %, light: %)
    └─ Persiste: targetSetsByMuscle, mevByMuscle, mrvByMuscle
}
```

### Fase 2: Persistencia en Firestore

**Archivo:** `client_firestore_datasource.dart`, línea 149–155

```dart
static const whitelistExtraKeys = <String>[
  ...
  'targetSetsByMuscle',      // Persiste si existe
  'mevByMuscle',             // Persiste si existe (nunca se llena hoy)
  'mrvByMuscle',             // Persiste si existe (nunca se llena hoy)
  ...
  'muscleLandmarks',         // Persiste landmarks invertidos
  ...
];
```

### Fase 3: Consumo en Motor V3

**Archivo:** `motor_v3_orchestrator.dart`, línea 165

```dart
final volumeTargets = expandBackMuscle(
  _resolveVolumeTargets(userProfile, muscleLandmarks),  ← Recibe landmarks
  backFocus: resolvedBackFocus,
);
```

**En `_resolveVolumeTargets()` (línea 2206):**

```dart
static Map<String, int> _resolveVolumeTargets(
  UserProfile userProfile,
  Map<String, Landmarks>? muscleLandmarks,
) {
  if (muscleLandmarks == null || muscleLandmarks.isEmpty) {
    return _calculateVolumeByMuscleV2(userProfile);
  }

  final resolved = <String, int>{};
  for (final entry in muscleLandmarks.entries) {
    final key = normalizeMuscleKey(entry.key);
    final vop = entry.value.vop;  // ← EXTRAE VOP de landmarks invertidos
    if (vop > 0) {
      resolved[key] = vop;
    }
  }
  return resolved;
}
```

---

## 3. DÓNDE NACE HOY EL VOP

### Ubicación: `LandmarkEngine.calculateFromProfile()`

**Archivo:** `lib/domain/training_v3/engines/landmark_engine.dart`  
**Procedimiento:** `calculateFromProfile()` (línea 23–42)

```dart
static Map<MuscleGroup, Landmarks> calculateFromProfile(
  TrainingProfile profile,
) {
  final targetByMuscle = _resolveTargetVolumeByMuscle(profile);  // Línea 27
  final out = <MuscleGroup, Landmarks>{};

  for (final entry in targetByMuscle.entries) {
    final muscle = muscleGroupFromString(entry.key);
    if (muscle == null) continue;

    final vop = entry.value.clamp(0, 999);        // Línea 34: VOP = target
    final vme = _resolveVme(vop);                 // Línea 35: INVIERTE
    final vmr = _resolveVmr(vop);                 // Línea 36: INVIERTE

    out[muscle] = Landmarks(vme: vme, vop: vop, vmr: vmr);
  }
  return out;
}
```

### Inputs reales

```json
{
  "targetByMuscle": {
    "quads": 8,        // Toma de profile.extra['targetSetsByMuscle']
    "glutes": 9,
    "chest": 7
  }
}
```

### Output real (INVERTIDO)

```json
{
  "quads": {
    "vme": 5,          // 8 × 0.6
    "vop": 8,          // Input directo
    "vmr": 11          // 8 × 1.4
  },
  "glutes": {
    "vme": 5,
    "vop": 9,
    "vmr": 13
  }
}
```

### Por qué está invertido

```
CORRECTO (PDF Semana 2):    vme → vop = vme + 35%(vmr-vme) → vmr
ACTUAL (código):            vop → vme = vop × 0.6 ← INVERTIDO
                            vop → vmr = vop × 1.4 ← INVERTIDO

FÓRMULA CORRECTA:
  vop = vme + 0.35 × (vmr - vme)
  ∴ vop ∈ [vme, vmr]

FÓRMULA ACTUAL:
  vme = vop × 0.6          → vme < vop
  vmr = vop × 1.4          → vmr > vop
  ✓ Orden preservado (vme < vop < vmr)
  ✗ Relación numérica incorrecta
  ✗ No refleja rango del sujeto
```

---

## 4. CÓMO SE DERIVAN HOY VME Y VMR

### Método actual (INCORRECTO)

**Ubicación:** `landmark_engine.dart` línea 108–118

```dart
static int _resolveVme(int vop) {
  if (vop <= 0) return 0;
  return (vop * 0.6).round().clamp(1, 999);
}

static int _resolveVmr(int vop) {
  if (vop <= 0) return 0;
  final vmr = (vop * 1.4).round();
  return vmr < vop ? vop : vmr;
}
```

**Fórmula actual:**
- `VME = VOP × 0.6` (porcentaje)
- `VMR = VOP × 1.4` (porcentaje)

**Características:**
- ✗ Porcentaje fijo para todos los músculos
- ✗ No depende del nivel del sujeto
- ✗ No depende del músculo específico
- ✗ Derivado hacia atrás (del VOP, no hacia VOP)

### Método correcto que existe pero no se usa (EN CÓDIGO HUÉRFANO)

**Ubicación:** `training_interview_tab.dart` línea 1263–1280

```dart
const resolver = AthleteContextResolver();
const volume = VolumeIndividualizationService();

final athlete = resolver.resolve(prev);
final level = prev.training.trainingLevel ?? TrainingLevel.intermediate;

final bounds = volume.computeBounds(
  level: level,                    // ← Nivel del sujeto
  athlete: athlete,                // ← Contexto individual (edad, peso, etc.)
  trainingExtra: prev.training.extra,
);

final volumeByMuscle = VolumeByMuscleDerivationService.derive(
  mevGlobal: bounds.mevIndividual,
  mrvGlobal: bounds.mrvIndividual,
  rawMuscleKeys: SupportedMuscles.keys,
);

// VolumeByMuscleDerivationService.derive hace:
for (final muscle in rawMuscleKeys) {
  final factor = _factors[muscle];  // 1.30 glutes, 0.85 triceps, etc.
  final mev = (mevGlobal * factor).roundToDouble();
  final mrv = (mrvGlobal * factor).clamp(mev, double.infinity).roundToDouble();
}

// Luego construye midpoint:
final mid = ((mev + mrv) / 2.0).roundToDouble();  // VOP correcto
targetSetsByMuscle[key] = mid;
```

**Fórmula correcta:**
- `VME_global` calculado con sumador aditivo (14 factores)
- `VMR_global` calculado con sumador aditivo (14 factores)
- `VME_muscle = VME_global × factor_muscle`
- `VMR_muscle = VMR_global × factor_muscle`
- `VOP_muscle = VME_muscle + 0.35 × (VMR_muscle - VME_muscle)`

**Características:**
- ✓ Depende del nivel del sujeto
- ✓ Ajustado por 14 factores (género, edad, etc.)
- ✓ Cada músculo recibe factor individual
- ✓ VOP es punto intermedio teórico en rango real

---

## 5. DÓNDE SE ROMPE EL MODELO DEL PDF

### Comparación lado a lado

| Paso | Modelo Correcto (PDF Semana 2) | Código Actual | Estado |
|------|--------|---------|--------|
| 1    | Nivel sujeto → VME/VMR base | ✓ Existe en VolumeIndividualizationService | ✓ Implementado |
| 2    | Base global del sujeto (beginner 6–16, intermediate 12–24, avanzado 18–32) | ✗ No hay base fija por nivel | ✗ FALTA |
| 3    | 14 factores aditivos ajustan VME/VMR | ✓ Existe en VolumeIndividualizationService | ✓ Implementado |
| 4    | Calcula VME/MRV del sujeto ANTES de distribución muscular | ✗ Se invierte: calcula por músculo DESDE VOP | ✗ INVERTIDO |
| 5    | Tabla de hoja 9: suma/resta series para ajustar | ✗ No hay tabla persistida | ✗ FALTA |
| 6    | VOP = VME + 35% rango (punto partida cálculo) | ✗ VOP es input, VME/VMR se derivan FROM VOP | ✗ INVERTIDO |
| 7    | Factores por músculo distribuyen el volumen global | ✓ Factores existen (1.30 glutes, etc.) | ✓ Implementado |
| 8    | Cada músculo ranged [VME_muscle, VMR_muscle] | ✓ Correcto en VolumeByMuscleDerivationService | ✓ Implementado |
| 9    | Bitácora progresa dentro del rango | ✗ Usa landmarks invertidos, rango es incorrecto | ✗ ROTO |
| 10   | Restricciones / lesiones ajustan rango | ✗ Not consumed | ✗ FALTA |

### Punto de ruptura crítico: LandmarkEngine

```
CORRECTO:
  traineeLevel → computeBounds() → mevIndividual, mrvIndividual
    ↓
  SupportedMuscles.keys × factors → mevByMuscle, mrvByMuscle
    ↓
  vop = mev + 0.35 × (vmr - mev)  ← AQUÍ

ACTUAL:
  targetSetsByMuscle (calculado como mid-point)
    ↓
  LandmarkEngine.calculateFromProfile()
    ├─ Lee targetSetsByMuscle
    ├─ Asume ese target ES vop  ← INCORRECTO
    └─ Deriva: vme = vop × 0.6, vmr = vop × 1.4  ← INVERTIDO
```

---

## 6. CONSUMIDORES DE LANDMARKS / MEV/MRV

| Archivo | Key Consumida | Para qué | Riesgo si cambia |
|---------|---------------|----------|-----------------|
| `motor_v3_orchestrator.dart:165` | `muscleLandmarks` → `.vop` | volumeTargets inicial | **CRÍTICO**: VOP es entrada a generación |
| `motor_v3_orchestrator.dart:354` | `musclePriorities` → VolumeLandmarksCalculator | _calculateVolumeByMuscleV2() fallback | Recalcula si landmarks vacíos |
| `motor_v3_orchestrator.dart:2206` | `muscleLandmarks.vop` | _resolveVolumeTargets() | **CRÍTICO**: Selecciona qué usar |
| `training_plan_provider.dart:1132–1163` | `targetSetsByMuscle` | Distribución UI tab 1 | Mostrado en tabla |
| `volume_range_muscle_table.dart:160` | `mevByMuscle`, `mrvByMuscle`, `targetSetsByMuscle` | Renderiza tabla de ranges | UI display |
| `intensity_split_table.dart:91` | `muscleLandmarks` | Datos para tabla intensidad | UI display |
| `training_workspace_screen.dart:1898` | `muscleLandmarks` | Recalcula si requested | Fallback UI |
| `training_workspace_screen.dart:2019` | Recalcula con LandmarkEngine | Re-persist landmarks | **CRÍTICO**: Refuerza inversión |

---

## 7. QUÉ PARTE DEL PDF SEMANA 2 YA ESTÁ IMPLEMENTADA

### ✅ SÍ IMPLEMENTADO (en código vivo)

1. **Línea 1–8 de Semana 2, hoja 9:** Tabla de factores aditivos
   - Está en `VolumeIndividualizationService` (14 factores: gender, age, height, weight, strength level, work capacity, recovery, recovery support, novelty, physical stress, non-physical stress, rest quality, diet, anabolics)
   - Método: `VolumeIndividualizationService.computeBounds()`

2. **Concepto de sumador aditivo:** Base + adjustments
   - Está en `VolumeIndividualizationService`: `mevBase + mevAdjust`, `mrvBase + mrvAdjust`

3. **Factores por músculo:** 1.30 glutes, 0.85 triceps, etc.
   - Está en `VolumeByMuscleDerivationService._factors`

4. **14 músculos canónicos:** glutes, quads, lats, upper_back, traps, deltoide ant/lat/post, chest, hamstrings, triceps, biceps, calves, abs
   - Está en `SupportedMuscles.keys` y muscle normalization

### 🟡 PARCIALMENTE IMPLEMENTADO

1. **Rango base por nivel (hoja 10):** "Principiante 6–16, Intermedio 12–24, Avanzado 18–32"
   - Está en `VolumeIndividualizationService._getBaseBounds(level)`
   - PERO VolumeLandmarks.calculate() NO usa esos bounds, usa valores per-musculo hardcodeados

2. **Distribución por prioridad:** 45% primary, 35% secondary, 20% tertiary
   - Está en training_interview_tab.dart línea 1312–1344
   - PERO no es persistida, solo calculada y luego descartada

3. **VOP = VME + 35% rango**
   - Está EN VolumeLandmarks.calculate() (línea 42): `vop = (vme + ((vmr - vme) * 0.35)).round()`
   - PERO ese cálculo NUNCA se usa porque LandmarkEngine los reemplaza

### ❌ NO IMPLEMENTADO

1. **Tabla de hoja 9 como matriz de ajustes persistidos:** No hay selección de fila/columna
   - Solo cálculo aditivo, sin persistencia de qué fila se eligió

2. **Restricciones / lesiones impactando rango:** movementRestrictionsDetail no se consume
   - Existe en datos pero no en cálculo

3. **Base fija global per nivel (beginner 6–16, etc.):** No hay valor de verdad
   - Cada músculo recibe su propio base, no existe el "base global" del modelo

4. **Distribución por intensidad dentro del rango (heavy, medium, light):**
   - Está en training_interview_tab.dart línea 1369–1399 pero
   - No se usa en motor (motor no Lee `targetSetsByMusclePriorityIntensity`)

5. **Bitácora que progresa dentro del rango:** Baseline exists
   - Pero no consumida activamente de landmarks

---

## 8. PLAN TÉCNICO DE CORRECCIÓN

### Opción recomendada: **Refactor acotado de landmarks (Días 2–3)**

Este enfoque cierra el ciclo sin rehacer la arquitectura.

#### PASO 1: Eliminar LandmarkEngine como generador (REEMPLAZAR)

**Archivo:** `training_interview_tab.dart`, línea 1223–1237  
**Acción:** Cambiar `_computeAndPersistLandmarks()` para que use el modelo correcto

```dart
// ANTES (INCORRECTO):
Future<void> _computeAndPersistLandmarks() async {
  await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
    final landmarksByMuscle = LandmarkEngine.calculateFromProfile(
      prev.training,  // ← INCORRECTO: invierte la lógica
    );
    extra[TrainingExtraKeys.muscleLandmarks] =
        LandmarkEngine.serializeByCanonicalKey(landmarksByMuscle);
    ...
  });
}

// DESPUÉS (CORRECTO):
Future<void> _computeAndPersistLandmarks() async {
  await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
    // NUEVA LÓGICA: Usar _postSaveRecomputeAndRegen inline
    const resolver = AthleteContextResolver();
    const volumeService = VolumeIndividualizationService();

    final athlete = resolver.resolve(prev);
    final level = prev.training.trainingLevel ?? TrainingLevel.intermediate;

    final bounds = volumeService.computeBounds(
      level: level,
      athlete: athlete,
      trainingExtra: prev.training.extra,
    );

    // Calcular MEV/MRV por músculo (CORRECTO)
    final volumeByMuscle = VolumeByMuscleDerivationService.derive(
      mevGlobal: bounds.mevIndividual,
      mrvGlobal: bounds.mrvIndividual,
      rawMuscleKeys: SupportedMuscles.keys,
    );
    
    final mevByMuscle = volumeByMuscle['mevByMuscle'] ?? {};
    final mrvByMuscle = volumeByMuscle['mrvByMuscle'] ?? {};

    // Generar landmarks CORRECTAMENTE desde MEV/MRV
    final landmarksByMuscle = <MuscleGroup, Landmarks>{};
    for (final muscle in SupportedMuscles.canonicalMuscles.map((x) => MuscleGroup.values.firstWhere(...))) {
      final mev = mevByMuscle[muscle.canonicalKey]?.toInt() ?? 0;
      final mrv = mrvByMuscle[muscle.canonicalKey]?.toInt() ?? 0;
      final vop = (mev + (mrv - mev) * 0.35).round();  // ← CORRECTO
      
      landmarksByMuscle[muscle] = Landmarks(
        vme: mev,
        vop: vop,
        vmr: mrv,
      );
    }

    extra[TrainingExtraKeys.muscleLandmarks] =
        LandmarkEngine.serializeByCanonicalKey(landmarksByMuscle);
    ...
  });
}
```

**Riesgo:** Bajo. Solo reemplaza la fuente del cálculo, no cambia persistencia ni consumo.

#### PASO 2: Crear factory builder para VolumeLandmarks

**Archivo:** `volume_landmarks.dart`  
**Acción:** Add factory para crear landmarks desde MEV/MRV en lugar de desde VOP

```dart
// AÑADIR A VolumeLandmarks:
factory VolumeLandmarks.fromMevMrv({
  required double mev,
  required double mrv,
}) {
  const vopRatio = 0.35;
  final vop = (mev + (mrv - mev) * vopRatio).round();
  
  return VolumeLandmarks(
    vme: mev.toInt(),
    vop: vop,
    vmr: mrv.toInt(),
    vmrTarget: mrv.toInt(),
  );
}
```

**Riesgo:** Muy bajo. Factory puro sin side effects.

#### PASO 3: Deprecate LandmarkEngine._resolveVme() y _resolveVmr()

**Archivo:** `landmark_engine.dart`  
**Acción:** Marcar como deprecated pero dejar funcionando para fallback

```dart
@Deprecated('Usar VolumeLandmarks.fromMevMrv() en lugar de LandmarkEngine')
static int _resolveVme(int vop) { ... }

@Deprecated('Usar VolumeLandmarks.fromMevMrv() en lugar de LandmarkEngine')
static int _resolveVmr(int vop) { ... }
```

**Riesgo:** Muy bajo. Backward compatible.

#### PASO 4: Validar que motor_v3_orchestrator._resolveVolumeTargets() consume correctamente

**Archivo:** `motor_v3_orchestrator.dart`, línea 2206  
**Verificación:** Confirma que extrae `.vop` de landmarks correctamente

```dart
static Map<String, int> _resolveVolumeTargets(
  UserProfile userProfile,
  Map<String, Landmarks>? muscleLandmarks,
) {
  if (muscleLandmarks == null || muscleLandmarks.isEmpty) {
    // FALLBACK: Si no hay landmarks, recalcula
    return _calculateVolumeByMuscleV2(userProfile);
  }

  final resolved = <String, int>{};
  for (final entry in muscleLandmarks.entries) {
    final key = normalizeMuscleKey(entry.key);
    final marks = entry.value;
    
    // ✓ CORRECTO: Usa VOP (que ahora es calculado correctamente)
    if (marks.vop > 0) {
      resolved[key] = marks.vop;
    }
  }
  return resolved;
}
```

**Riesgo:** Muy bajo. Solo validación sin cambios.

#### PASO 5: Actualizar tests en forensic_motor_trace_test.dart

**Archivo:** `test/domain/training_v3/forensic_motor_trace_test.dart`  
**Acción:** Validar que VOP es ahora calculado correctamente desde MEV/MRV

```dart
test('VOP debe calcularse como MEV + 35% rango, no como target × 1.4', () {
  final vme = 10;
  final vmr = 20;
  final expectedVop = (vme + (vmr - vme) * 0.35).round();  // 13
  
  final marks = VolumeLandmarks.fromMevMrv(mev: vme.toDouble(), mrv: vmr.toDouble());
  
  expect(marks.vop, equals(expectedVop));  // 13, no 14 (20 × 0.7)
});
```

**Riesgo:** Muy bajo. Nuevo test, no afecta existentes.

#### PASO 6: Ejecutar `flutter analyze` post-cambios

**Comando:** `flutter analyze lib/features/training_feature/tabs/training_interview_tab.dart lib/domain/training_v3/engines/landmark_engine.dart lib/domain/training_v3/models/volume_landmarks.dart lib/domain/training_v3/services/motor_v3_orchestrator.dart`

**Riesgo:** Muy bajo. Solo lint validation.

### Resumen de cambios

| Archivo | Función | Cambio | Línea | Riesgo |
|---------|---------|--------|-------|--------|
| training_interview_tab.dart | _computeAndPersistLandmarks() | Reemplazar LandmarkEngine con sumador correcto | 1223–1237 | Bajo |
| volume_landmarks.dart | — | Añadir factory VolumeLandmarks.fromMevMrv() | — | Muy bajo |
| landmark_engine.dart | _resolveVme(), _resolveVmr() | Deprecate (no delete) | 108–118 | Muy bajo |
| motor_v3_orchestrator.dart | _resolveVolumeTargets() | Validación (no cambios) | 2206 | Muy bajo |
| forensic_motor_trace_test.dart | — | Añadir test VOP correcto | — | Muy bajo |

### Orden de ejecución

1. Crear factory VolumeLandmarks.fromMevMrv() (5 min)
2. Reemplazar _computeAndPersistLandmarks() con sumador correcto (20 min)
3. Deprecate _resolveVme/_resolveVmr (5 min)
4. Validar motor_v3_orchestrator consume correctamente (10 min)
5. Escribir test sobre VOP correcto (15 min)
6. flutter analyze (5 min)
7. Manual test: guardar entrevista → verificar landmarks en Firestore (10 min)

**Total:** ~1 hora

### Qué se mantiene igual

- ✓ Persistencia en training.extra['muscleLandmarks']
- ✓ Clave 'mevByMuscle', 'mrvByMuscle' en extra
- ✓ Consumo en motor_v3_orchestrator._resolveVolumeTargets()
- ✓ Serialización LandmarkEngine.serializeByCanonicalKey()
- ✓ Whitelisting Firestore

### Qué se rehace mínimamente

- ✗ Fórmulas de derivación (DEBE cambiar)
- ✗ Order de cálculo (DEBE cambiar: nivel → músculo, no vop → mev/mrv)
- ✗ Persistencia NO, pero contenidos SÍ

---

## 9. RECOMENDACIÓN FINAL

### Elegida: **Refactor acotado de landmarks (Opción 2)**

**Justificación:**
- Cierra el ciclo problema sin rehacer arquitectura
- Risk bajo (solo reemplaza fuente de cálculo)
- Timeline corto (1 hora)
- Backward compatible

**Alternativas rechazadas:**
1. **Parche mínimo:** Insuficiente; el problema es arquitectónico, no un edge case
2. **Rehacer pipeline completo:** Riesgo muy alto; afecta motor, providers, tests

---

## RESPUESTA CORTA A PREGUNTAS OBLIGATORIAS

### 1. ¿Dónde nace hoy el VOP?

**`landmark_engine.dart`, función `calculateFromProfile()` línea 34**
```dart
final vop = entry.value.clamp(0, 999);
// entry.value viene de profile.extra['targetSetsByMuscle']
```
Pero ese VOP es **derivado incorrectamente** (del targetSetsByMuscle que es un midpoint).

### 2. ¿Con qué datos se calcula?

Con `targetSetsByMuscle` del perfil, que es persistido como `(mev + mrv) / 2` pero luego LandmarkEngine lo trata como VOP directo.

### 3. ¿Se calcula primero a nivel del sujeto o a nivel del músculo?

**Hoy: Directamente a nivel del músculo** (incorrecto).  
**Debería: Primero a nivel global, luego distribuir por músculo** (PDF Semana 2).

### 4. ¿Dónde se convierten esos datos en muscleLandmarks?

En `training_interview_tab.dart`, `_computeAndPersistLandmarks()` línea 1226–1237 usando `LandmarkEngine.calculateFromProfile()`.

### 5. ¿Qué fórmula exacta usa hoy el sistema para VME y VMR?

Hoy (INCORRECTO):
```dart
vme = vop × 0.6
vmr = vop × 1.4
```

Debería (CORRECTO):
```dart
vme_global = base[level] + adjustments[14 factores]
vmr_global = base[level] + adjustments[14 factores]
vme_muscle = vme_global × factor_muscle
vmr_muscle = vmr_global × factor_muscle
vop_muscle = vme_muscle + 0.35 × (vmr_muscle - vme_muscle)
```

### 6. ¿Dónde se persisten muscleLandmarks?

En `training.extra['muscleLandmarks']` usando `LandmarkEngine.serializeByCanonicalKey()`.  
Key por músculo: `{"quads": {"vme": 5, "vop": 8, "vmr": 11}}`.

### 7. ¿Qué partes del motor consumen muscleLandmarks después?

1. **motor_v3_orchestrator.dart:2206** `_resolveVolumeTargets()` → extrae `.vop`
2. **training_plan_provider.dart** → UI rendering
3. **volume_range_muscle_table.dart** → UI table display
4. **training_workspace_screen.dart** → recalcula si requested

### 8. ¿Qué parte de la entrevista influye realmente en ese cálculo hoy?

Solo el nivel del sujeto (beginner/intermediate/advanced) y músculo priorities.

**NO influye:**
- Factores de interview (edad, peso, lesiones, recuperación, estrés, etc.)
- Tabla hoja 9 (no se persiste selección)
- Restricciones de movimiento

### 9. ¿Qué parte del modelo del PDF Semana 2 NO está implementada hoy?

1. Base global fija por nivel (6–16, 12–24, 18–32)
2. 14 factores de sumador aditivo EN EL FLUJO (existen pero no se usan)
3. Tabla hoja 9 como persistencia de ajuste seleccionado
4. Restricciones consumidas en cálculo
5. Distribución por intensidad en motor (existe en UI pero no en generación)

### 10. ¿Qué parte del motor actual contradice el modelo correcto del PDF?

**La inversión lógica:**
```
PDF: nivel → VME/VMR base → distribución muscular → VOP = VME + 35% rango
Código: VOP directo → derivar VME = VOP×0.6, VMR = VOP×1.4
```

Motor V3 consume esa inversión como si fuera verdad, generando programas con rangos incorrectosque no reflejan capacidad real del sujeto.

### 11. ¿Qué archivos/funciones exactas habría que cambiar?

**Tocar:**
1. `training_interview_tab.dart`: Reemplazar `_computeAndPersistLandmarks()` (línea 1223)
2. `volume_landmarks.dart`: Añadir `factory.fromMevMrv()`
3. `landmark_engine.dart`: Deprecate `_resolveVme()`, `_resolveVmr()`

**No tocar:**
- motor_v3_orchestrator.dart (solo valida, no cambia)
- Persistencia keys
- Whitelisting

### 12. ¿Qué riesgo rompería el cambio?

**Bajo:**
- Cambio local a training_interview_tab  
- Backward compatible (landmarks siguen siendo persistidos en same format)
- Motor consume same keys, solo contenido mejora
- Tests NEW para validar

**Máximo riesgo:** Si hay codigo legacy leyendo landmarks esperando la inversión (rechercher toda app sería sencillo con grep `_resolveVme`)

### 13. ¿Qué se puede mantener y qué se tendría que rehacer?

**Mantener:**
- architecture (entrevista → landmarks → motor)
- Persistencia structure
- Key names
- Serialization format

**Rehacer:**
- Fórmula de derivación de VOP
- Orden logical (desde nivel → músculo, no desde vop → mev/mrv)
- Fuente de cálculo (sumador correcto en lugar de LandmarkEngine invertido)

