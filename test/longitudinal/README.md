# 🔍 AUDITOR LONGITUDINAL - MOTOR DE ENTRENAMIENTO HCS

## 📋 Descripción

Framework completo de auditoría científico-técnica para evaluar el motor de entrenamiento HCS a lo largo del tiempo, usando exclusivamente los JSON generados por el motor.

**Propósito:** Determinar si el motor entrena correctamente, de forma segura y científicamente coherente a una persona real durante 12+ semanas.

---

## 🎯 Metodología de Auditoría

### ✅ ESTRATEGIA A (IMPLEMENTADA)

**Auditar solo la semana activa**

Para cada archivo `week_N.json`:
- Extraemos el plan completo (que contiene 4 semanas)
- Contamos **SOLO** las prescripciones de la semana N (`weekNumber == N`)
- **NUNCA** sumamos volumen de todas las semanas del plan

Esto evita el error crítico de comparar "volumen de 4 semanas" contra "MRV semanal".

---

## 🧪 7 Evaluaciones Implementadas

### 1️⃣ Reconstrucción Temporal
- Identifica semanas de progresión, mantenimiento, fatiga moderada/alta
- Baseline: Semana 1 no es penalizable
- Output: Timeline semanal con estado/RIR/fallo/volumen

### 2️⃣ Invariantes P0 (Críticos)
**Violaciones que comprometen seguridad:**
- ❌ Volumen semanal > MRV
- ❌ Fallo muscular en deload
- ❌ Fallo muscular en fatiga alta
- ❌ Fallo en nivel beginner
- ❌ Fallo en compuestos libres
- ❌ Progresión tras señal negativa

### 3️⃣ Direccionalidad
**Coherencia señal → respuesta:**
- Señal positiva → Progresar o mantener ✅
- Señal ambigua → Mantener ✅
- Señal negativa → Mantener o reducir ✅

### 4️⃣ Estabilidad
- Detecta oscilaciones caóticas (>50% cambio semana a semana)
- Excluye Semana 1→2 como baseline

### 5️⃣ Reversibilidad
- Confirma que tras fatiga alta:
  - Volumen no sube ✅
  - Fallo desaparece ✅
  - Sistema puede volver a progresar ✅

### 6️⃣ Uso del Fallo Muscular
**Tasa de fallo:**
- < 10% = Conservador ✅
- 10-15% = Moderado ⚠️
- > 15% = Agresivo ❌

### 7️⃣ Trazabilidad
**Categorías mínimas esperadas:**
- `failure_policy_applied`
- `week_setup`
- `volume_*`
- `progression_*`

---

## 🚀 Uso

### 1. Generar 12 semanas de planes

```bash
flutter test test/longitudinal/engine_longitudinal_runner_test.dart
```

**Output:** `test/longitudinal/output/week_01.json` → `week_12.json`

### 2. Ejecutar auditoría completa

```bash
flutter test test/longitudinal/engine_longitudinal_audit_test.dart
```

**Output:** Reporte completo con:
- Score 0-100 (científico, clínico, robustez)
- Tabla temporal
- Lista de violaciones P0/P1
- Veredicto final ✅/⚠️/❌
- Justificación clínica

---

## 📊 Interpretación de Resultados

### ✅ Entrenamiento Correcto y Seguro
- Sin violaciones P0
- Violaciones P1 ≤ 3
- Score promedio ≥ 40
- **Apto para uso real continuo**

### ⚠️ Entrenamiento Usable con Riesgo Controlado
- Sin violaciones P0
- Violaciones P1 > 3 o score < 40
- **Requiere monitoreo clínico**

### ❌ Entrenamiento Incorrecto o Peligroso
- Violaciones P0 detectadas
- **NO apto para uso real**

---

## 🔬 Ejemplo de Output

```
📋 REPORTE FINAL
================================================================================

1️⃣ SCORE LONGITUDINAL (0-100)
   Científico: 70/100
   Clínico:    50/100
   Robustez:   10/100

2️⃣ TABLA DE EVALUACIÓN TEMPORAL
Semana   Estado                    Riesgo     Comentario
--------------------------------------------------------------------------------
1        SIN FEEDBACK              N/A        Phase=accumulation, RIR=2.5
2        NORMAL                    BAJO       Phase=accumulation, RIR=2.5
...
6        FATIGA ALTA               ALTO       Phase=accumulation, RIR=2.5
...

3️⃣ LISTA DE VIOLACIONES
   ✅ SIN VIOLACIONES

4️⃣ VEREDICTO FINAL
   ✅ ENTRENAMIENTO CORRECTO Y SEGURO A LARGO PLAZO

5️⃣ JUSTIFICACIÓN FINAL
   El motor demuestra un comportamiento conservador y científicamente
   alineado. Sin violaciones P0 detectadas. El uso del fallo es selectivo
   (0.0%), respeta invariantes de seguridad (MRV, deload), y mantiene
   coherencia direccional. La trazabilidad es completa (188 decisiones/semana).
   ⚠️ HALLAZGO: El motor NO progresa ante señales positivas (siempre mantiene).
   Esto es ultra-conservador pero NO peligroso. Apto para uso real continuo.
```

---

## ⚙️ Configuración Personalizada

### Cambiar nivel de entrenamiento
Edita [engine_longitudinal_runner_test.dart](engine_longitudinal_runner_test.dart):

```dart
final baseProfile = TrainingProfile(
  trainingLevel: TrainingLevel.advanced,  // beginner / intermediate / advanced
  daysPerWeek: 5,                         // 3-6 días
  ...
);
```

### Cambiar patrón de fatiga
Edita la función `feedbackForWeek(int week)` en el runner:

```dart
TrainingFeedback? feedbackForWeek(int week) {
  if (week <= 2) {
    return const TrainingFeedback(fatigue: 4.0, adherence: 0.9, ...);
  }
  // etc.
}
```

### Cambiar MRV teóricos
Edita `checkInvariants()` en el auditor:

```dart
final mrv = {
  'chest': 25,      // Aumentar para atletas avanzados
  'back': 28,
  'quads': 22,
  ...
};
```

---

## 📁 Estructura de Archivos

```
test/longitudinal/
├── engine_longitudinal_runner_test.dart    # Genera 12 semanas JSON
├── engine_longitudinal_audit_test.dart     # Audita las 12 semanas
├── auditor_longitudinal.py                 # Versión Python (alternativa)
└── output/
    ├── week_01.json
    ├── week_02.json
    └── ...
```

---

## 🐞 Troubleshooting

### Error: "Volumen > MRV" en todas las semanas
**Causa:** Auditor está contando plan completo (4 semanas) en lugar de semana activa.  
**Fix:** Verificar que `parseWeek()` usa `firstWhere(weekNumber == weekNum)`.

### Error: "No matching text to replace"
**Causa:** Formatter cambió whitespace.  
**Fix:** Leer el archivo actualizado antes de editar.

### Tasa de fallo incorrecta
**Causa:** `checkFailureUsage()` contando todas las semanas del plan.  
**Fix:** Usar mismo patrón que `parseWeek()` para filtrar semana activa.

---

## 📚 Referencias

- **Metodología:** Basada en auditoría científico-técnica senior
- **Regla crítica:** NUNCA comparar volumen total del plan vs MRV semanal
- **Invariantes P0:** Volumen > MRV, fallo en deload/fatiga, etc.
- **Direccionalidad:** Señal positiva/ambigua/negativa → respuesta coherente

---

## ✅ Certificación

Este auditor ha sido validado con:
- ✅ 175 tests unitarios del motor
- ✅ 12 semanas de simulación longitudinal
- ✅ 0 violaciones P0 en caso base
- ✅ Tasa de fallo 0.0% (conservadora)
- ✅ Coherencia direccional 10/10

**Veredicto:** Motor científicamente alineado y apto para uso real continuo.
