# GUÍA DE TESTING: Adaptación por Bitácora en AA (Tab 3)

**Fecha:** 18 de enero de 2026  
**Status:** Implementación completada, listo para validación runtime

---

## INSTRUCCIONES PARA TESTING

### 1. Verificar Compilación

```bash
cd c:\Users\pedro\StudioProjects\hcs_app_lap
flutter analyze
# Esperado: No issues found!

flutter clean
flutter pub get
# Esperado: Sin errores
```

### 2. Ejecutar la Aplicación

```bash
flutter run -d <device_id>
# Esperado: App lanza sin crashes
```

### 3. Navegar a Tab 3

```
Dashboard → Training → Macrocycle Overview (Tab 3)
```

Deberías ver:
- Selector de grupo muscular (Pecho, Espalda, etc.)
- Leyenda con "Fuentes" y "Patrones"
- Bloque activo con 4 semanas (columnas)

---

## CASOS DE TEST

### CASO 1: Semana 1 (PLAN) — Baseline Fijo

**Propósito:** Verificar que S1 nunca se adapta

**Setup:**
1. Selecciona un grupo muscular (ej. Pecho)
2. Asegúrate que hay VOP en Tab 2 (ej. 12 series)
3. Verifica que existe bitácora para S1

**Test:**
```
En Tab 3, semana 1 del bloque activo (AA):
├─ Series totales = VOP de Tab 2
├─ Badge = PLAN (gris, tenue)
├─ Color = Gris con opacidad 0.5
└─ Tooltip = "Baseline sin adaptación (S1)"
```

**Esperado:**
- ✅ Total = 12 (sin cambios, incluso si bitácora es 15)
- ✅ Badge PLAN visible
- ✅ Color gris distinguible

**Fallo:**
- ❌ Total no es VOP
- ❌ Badge no es PLAN
- ❌ Color no es gris

---

### CASO 2: Semana 2+ con Bitácora (AUTO-Adaptado)

**Propósito:** Verificar adaptación conservadora (±1)

**Setup:**
1. Selecciona grupo muscular con bitácora en S1 y S2
2. VOP = 12 series
3. Bitácora S1 = 12 series (buena)
4. Bitácora S2 = 13 series (excelente, >= 110%)

**Test:**
```
S1:
├─ Total = 12 (PLAN, baseline)
└─ Badge = PLAN

S2:
├─ Adherencia S1 = 12/12 = 100% (buena)
├─ Esperado = 12 series (mantener)
├─ Total = 12 [AUTO]
├─ Badge = AUTO (azul)
└─ Color = Azul con opacidad 0.6
```

**Esperado:**
- ✅ S2 total = 12 (adaptación conservadora)
- ✅ Badge AUTO visible (azul)
- ✅ Tooltip menciona "Adaptado por bitácora"

**Variantes:**
```
Si bitácora S1 = 10 (pobre, < 85%):
└─ S2 debe = 11 (base 12 - 1)

Si bitácora S1 = 14 (excelente, >= 110%):
└─ S2 debe = 13 (base 12 + 1)
```

---

### CASO 3: Semana 2+ sin Bitácora (AUTO-Fallback)

**Propósito:** Verificar fallback motor sin bitácora

**Setup:**
1. Selecciona grupo muscular sin bitácora en S1
2. VOP = 14 series
3. Sin registros en bitácora

**Test:**
```
S1:
├─ Total = 14 (PLAN, baseline)
└─ Badge = PLAN

S2:
├─ Sin datos previos
├─ Fallback motor = 14 + (2-1) = 15 series
├─ Total = 15 [AUTO]
├─ Badge = AUTO (azul)
└─ Tooltip = "Sin datos, se mantiene progresión motor"
```

**Esperado:**
- ✅ S2 total = 15 (fallback, no adaptado)
- ✅ Badge AUTO (azul, mismo que adaptado)
- ✅ Tooltip diferencia "Sin datos" vs "Adaptado"

---

### CASO 4: Semana 4 (Descarga Motor)

**Propósito:** Verificar que patrón deload se aplica

**Setup:**
1. Selecciona grupo muscular
2. VOP = 12 series
3. Sin bitácora en S4

**Test:**
```
S4:
├─ Patrón = DESCARGA (deload, semana 4)
├─ Total = 12 * 0.8 = ~10 series (reducción 20%)
├─ Badge = AUTO o PLAN
└─ Icon/Tooltip = "Descarga"
```

**Esperado:**
- ✅ S4 muestra reducción por patrón
- ✅ Total < S3 (progresión visible)
- ✅ Patrón descarga en tooltip

---

### CASO 5: Diferenciación Visual (Colores)

**Propósito:** Verificar que REAL/AUTO/PLAN son visualmente distintos

**Setup:**
1. En el bloque activo, debería haber:
   - Al menos 1 REAL (si hay bitácora)
   - Al menos 1 AUTO (fallback o adaptado)
   - Al menos 1 PLAN (S1)

**Test Visual:**
```
Mirando 4 columnas:
├─ REAL (si existe): Teal sólido (opaco 1.0)
├─ AUTO: Azul intermedio (opaco 0.6)
├─ PLAN: Gris tenue (opaco 0.5)

Badget:
├─ REAL = texto "REAL"
├─ AUTO = texto "AUTO"
└─ PLAN = texto "PLAN"

Bordes:
├─ REAL: Teal 0.4 opacidad
├─ AUTO: Azul 0.24 opacidad
└─ PLAN: Gris 0.2 opacidad
```

**Esperado:**
- ✅ 3 colores visualmente distinguibles
- ✅ REAL > AUTO > PLAN (en términos de saturación)
- ✅ Badges legibles

**Potencial Fallo:**
- ❌ REAL y AUTO indistinguibles
- ❌ Badges no visibles
- ❌ Colores muy similares

---

### CASO 6: Leyenda Actualizada

**Propósito:** Verificar que leyenda explica nuevos badgets

**Setup:**
1. Abre Tab 3
2. Busca sección "Leyenda"

**Test:**
```
Leyenda debe mostrar:

Fuentes:
├─ ■ REAL (bitácora)
├─ ■ AUTO (adaptado motor)
└─ ■ PLAN (baseline sin adaptar)

Patrones:
├─ ↗ Incremento
├─ → Estable
├─ ↘ Descarga
└─ ⚡ Intensificación
```

**Esperado:**
- ✅ Sección "Fuentes" visible
- ✅ 3 colores mostrados (teal, azul, gris)
- ✅ Patrones siguen visibles

---

### CASO 7: Tooltip Informativo

**Propósito:** Verificar que tooltip explica origen de datos

**Setup:**
1. Selecciona una semana en Tab 3
2. Hover sobre la columna (mouse o long-press)

**Test:**
```
Tooltip debe mostrar:
├─ "Semana N (Posición M en bloque)"
├─ "[REAL/AUTO/PLAN] ([descripción])"
├─ "Patrón: [incremento/estable/descarga/intensificación]"
├─ "Total: X series"
├─ "  Pesadas: X"
├─ "  Medias: X"
├─ "  Ligeras: X"
└─ "📌 [Nota sobre adaptación o S1]"

Ejemplo S1:
"Semana 1 (Posición 1 en bloque)
PLAN (Baseline sin adaptación)
Patrón: Incremento
Total: 12 series
  Pesadas: 2
  Medias: 7
  Ligeras: 3
📌 Semana 1: Baseline fijo, sin adaptación."

Ejemplo S2 con adaptación:
"Semana 2 (Posición 2 en bloque)
AUTO (Fallback Motor / Adaptado)
Patrón: Incremento
Total: 13 series
  Pesadas: 2
  Medias: 8
  Ligeras: 3
📌 Adaptado por bitácora previa o fallback motor."
```

**Esperado:**
- ✅ Tooltip muestra posición en bloque
- ✅ Fuente diferenciada (REAL vs AUTO vs PLAN)
- ✅ Total y H/M/L correctos
- ✅ Nota sobre adaptación o S1

---

## CHECKLIST FINAL

### Compilación
- [ ] `flutter analyze` → No issues
- [ ] App lanza sin crashes
- [ ] Tab 3 carga sin errores

### Lógica S1
- [ ] S1 siempre = VOP
- [ ] S1 badge = PLAN
- [ ] S1 color = gris

### Lógica S2+
- [ ] S2 adapta si bitácora S1 existe
- [ ] S2 fallback motor si no existe bitácora
- [ ] Máximo ±1 serie (verificar ejecución pobre vs excelente)
- [ ] S2+ badge = AUTO (adaptado o fallback)
- [ ] S2+ color = azul intermedio

### UI Visual
- [ ] 3 colores distinguibles (teal/azul/gris)
- [ ] Badges legibles (REAL/AUTO/PLAN)
- [ ] Leyenda expándida con "Fuentes"
- [ ] Tooltips informativos con posición en bloque

### Coherencia
- [ ] Tab 2 VOP = Tab 3 S1
- [ ] Tab 2 split = Tab 3 H/M/L distribución
- [ ] Sin saltos bruscos (±1/semana)
- [ ] Mínimo 6 series (nunca bajar más)

### Edge Cases
- [ ] Bitácora con totalSeries = 0 → -1 serie
- [ ] Músculos sin VOP → fallback baseline
- [ ] Músculos sin bitácora → motor fallback
- [ ] Cambio de grupo muscular → actualiza correctamente

---

## REPORTE DE DEFECTOS

Si encuentras algún problema, reporta:

```
📋 DEFECTO:
├─ Descripción: [qué está mal]
├─ Pasos: [cómo reproducir]
├─ Esperado: [qué debería pasar]
├─ Actual: [qué pasa]
├─ Captura: [screenshot/video]
└─ Severidad: CRÍTICA / ALTA / MEDIA / BAJA

Ejemplos:
- CRÍTICA: S1 adapta (violata R1)
- ALTA: Colores indistinguibles
- MEDIA: Tooltip no muestra posición en bloque
- BAJA: Leyenda fuentes mal alineada
```

---

## ARCHIVO DE ESPECIFICACIÓN

Para detalles técnicos completos, ver:
- `docs/AA_BITACORA_ADAPTATION_SPECIFICATION.md`
- `docs/IMPLEMENTACION_BITACORA_AA_RESUMEN.md`

---

**Testing completado cuando:**
- ✅ Todos los checklist Items marcados
- ✅ Ningún defecto CRÍTICA o ALTA
- ✅ Coach entiende PLAN/AUTO/REAL
- ✅ Colores visualmente claros

**Estado:** 🟢 LISTO PARA TESTING
