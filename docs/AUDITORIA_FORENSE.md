# AUDITORÍA FORENSE - HCS APP LAP
**Fecha:** 28 de diciembre de 2025  
**Auditor:** Arquitecto Senior + Auditor Técnico  
**Estado:** BLOQUEANTE PARA PRODUCCIÓN

---

## RESUMEN EJECUTIVO

**VEREDICTO: ❌ NO PUEDE USARSE EN PRODUCCIÓN EN 10-11 DÍAS SIN FIXES CRÍTICOS**

**Hallazgos P0 (BLOQUEANTES):** 2  
**Hallazgos P1 (CRÍTICOS):** 4  
**Hallazgos P2 (IMPORTANTES):** 3  

---

## HALLAZGOS P0 - BLOQUEANTES DE PRODUCCIÓN

### 🔴 P0-001: PÉRDIDA DE DATOS EN `.last` SIN ORDEN GARANTIZADO

**📁 Archivo:** `lib/utils/client_extensions.dart`  
**📍 Líneas:** 20-26

```dart
AnthropometryRecord? get latestAnthropometryRecord {
  if (anthropometry.isEmpty) return null;
  return anthropometry.last;  // ❌ PELIGRO
}

BioChemistryRecord? get latestBiochemistryRecord {
  if (biochemistry.isEmpty) return null;
  return biochemistry.last;  // ❌ PELIGRO
}
```

**⚠️ Síntoma observable:**  
- El sistema muestra un registro antiguo como "el más reciente".
- El nutriólogo ajusta macros basándose en datos obsoletos.
- Las decisiones clínicas están basadas en información incorrecta.

**💣 Riesgo real en producción:**  
- **CRÍTICO DE SALUD:** Un cliente puede recibir recomendaciones nutricionales basadas en peso/composición corporal de hace 6 meses.
- **PÉRDIDA DE CONFIANZA:** El cliente ve que la app no refleja sus últimos registros.
- **RESPONSABILIDAD LEGAL:** Recomendaciones clínicas incorrectas por datos desactualizados.

**🧠 Causa raíz técnica:**  
Las listas `anthropometry` y `biochemistry` no tienen orden garantizado. El método `.last` devuelve el último **insertado en la lista**, NO el más reciente por fecha.

**🛠️ Fix mínimo recomendado:**

```dart
AnthropometryRecord? get latestAnthropometryRecord {
  if (anthropometry.isEmpty) return null;
  return anthropometry.reduce((a, b) => 
    a.dateIso.compareTo(b.dateIso) > 0 ? a : b
  );
}

BioChemistryRecord? get latestBiochemistryRecord {
  if (biochemistry.isEmpty) return null;
  return biochemistry.reduce((a, b) => 
    a.dateIso.compareTo(b.dateIso) > 0 ? a : b
  );
}
```

**✅ Criterio de aceptación:**  
- Agregar 3 registros con fechas desordenadas.
- Verificar que `latestAnthropometryRecord` devuelve el de fecha más reciente.
- Agregar test unitario que lo valide.

---

### 🔴 P0-002: `DateTime.now()` FALSEA TIMESTAMPS EN ENTIDADES

**📁 Archivos afectados:**  
- `lib/domain/entities/movement_pattern_assessment.dart:50`
- `lib/features/training_feature/services/training_profile_form_mapper.dart:106`
- **Y otros 25+ lugares**

**📍 Ejemplo crítico:**

```dart
// movement_pattern_assessment.dart
map['date'] as String? ?? DateTime.now().toIso8601String(),
```

**⚠️ Síntoma observable:**  
- Un registro histórico de hace 3 meses aparece con fecha de hoy.
- El ordenamiento por fecha muestra registros viejos como recientes.
- Los grafos temporales están distorsionados.

**💣 Riesgo real en producción:**  
- **CORRUPCIÓN DE DATOS HISTÓRICOS:** Al deserializar un JSON sin fecha, se le asigna "hoy", destruyendo la cronología real.
- **ANÁLISIS EVOLUTIVO INVÁLIDO:** Las tendencias y progreso del cliente no son confiables.
- **PÉRDIDA DE TRAZABILIDAD:** No se puede saber cuándo se tomó realmente una medición.

**🧠 Causa raíz técnica:**  
Uso de `DateTime.now()` como fallback en parsing. Debería usar epoch o lanzar error.

**🛠️ Fix mínimo recomendado:**

```dart
// Usar epoch como indicador de "fecha inválida"
map['date'] as String? ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
```

O mejor: validar y rechazar el registro si no tiene fecha válida.

**✅ Criterio de aceptación:**  
- Deserializar un JSON sin `date`.
- Verificar que la fecha NO es `DateTime.now()`, sino epoch o se lanza excepción.
- Test: `fromJson({'foo': 'bar'})` NO debe tener fecha de hoy.

---

## HALLAZGOS P1 - CRÍTICOS (NO BLOQUEANTES PERO GRAVES)

### 🟠 P1-001: MOTOR DE ENTRENAMIENTO NO EXISTE - ES PLACEHOLDER

**📁 Archivos:**  
- `lib/domain/services/training_plan_generator.dart` (marcado como Placeholder en audit)
- `lib/features/training_feature/domain/volume_intelligence/services/distribution_balancing_service.dart` (marcado como Código Fantasma)

**⚠️ Síntoma observable:**  
- El botón "Generar plan de entrenamiento" está en la UI.
- Al presionarlo, no se genera nada científico/inteligente.
- Los planes son estáticos o placeholders.

**💣 Riesgo real en producción:**  
- **FRAUDE PERCIBIDO:** El cliente paga por un "motor inteligente" que no existe.
- **EXPECTATIVA vs REALIDAD:** La app promete ciencia, entrega templates.
- **REPUTACIÓN:** Pérdida de credibilidad como herramienta profesional.

**🧠 Causa raíz técnica:**  
Según el inventario de archivos (audit), varios servicios críticos están marcados como "Código Fantasma" o "Placeholder". La lógica de generación de planes NO está implementada.

**🛠️ Fix mínimo recomendado:**

**OPCIÓN A (Conservadora):**  
- Deshabilitar el botón "Generar plan" en UI.
- Agregar mensaje: "Función en desarrollo - próximamente".
- Permitir solo creación manual de planes.

**OPCIÓN B (Rápida):**  
- Implementar un motor básico que:
  - Use las reglas de series/volumen ya definidas.
  - Genere un plan simple basado en perfil del cliente.
  - Documente claramente que es v1.0 básica.

**✅ Criterio de aceptación:**  
- Si se elige A: El botón está deshabilitado con tooltip claro.
- Si se elige B: El plan generado cumple reglas básicas de volumen y es reproducible.

---

### 🟠 P1-002: SINCRONIZACIÓN FIREBASE NO IMPLEMENTADA

**📁 Archivos:**  
- `lib/services/firebase_service.dart` (marcado como Código Fantasma)
- `lib/data/repositories/client_repository_impl.dart` (marcado como Código Fantasma)

**⚠️ Síntoma observable:**  
- Los datos se guardan solo localmente (SQLite).
- No hay respaldo en la nube.
- Si el usuario cambia de dispositivo o pierde la laptop, pierde TODO.

**💣 Riesgo real en producción:**  
- **PÉRDIDA CATASTRÓFICA DE DATOS:** Un disco dañado = pérdida de todos los clientes.
- **NO ES OFFLINE-FIRST, ES OFFLINE-ONLY:** La promesa de sincronización es falsa.
- **IMPOSIBILIDAD DE COLABORACIÓN:** No se puede acceder desde múltiples dispositivos.

**🧠 Causa raíz técnica:**  
El repositorio está stubbed. Firebase está configurado (firebase.json existe), pero la capa de datos no lo usa.

**🛠️ Fix mínimo recomendado:**

**OPCIÓN A (Conservadora):**  
- Documentar claramente que v1.0 es solo local.
- Implementar backup manual (export/import JSON).
- Agregar advertencia en UI: "Datos solo locales - haz backups manuales".

**OPCIÓN B (Completa):**  
- Implementar sync básico con Firestore:
  - Escribir en local primero (offline-first).
  - Sync async a Firebase cuando haya conexión.
  - Detectar conflictos por `updatedAt`.

**✅ Criterio de aceptación:**  
- Si A: Botón "Exportar backup" funciona y restaura datos correctamente.
- Si B: Datos persisten en Firestore y se recuperan al reinstalar la app.

---

### 🟠 P1-003: GETTERS `kcal` INCONSISTENTES ENTRE ENTIDADES

**📁 Archivos:**  
- `lib/domain/entities/nutrition_settings.dart` (tiene `kcal` directo)
- `lib/domain/entities/client.dart` (getter `kcal` derivado)
- Múltiples features accediendo vía `client.kcal` o `client.nutrition.kcal`

**⚠️ Síntoma observable:**  
- En algunos lugares se usa `client.kcal`.
- En otros `client.nutrition.kcal`.
- No está claro cuál es la "fuente de verdad".

**💣 Riesgo real en producción:**  
- **CONFUSIÓN DE ESTADO:** Diferentes partes de la app pueden leer valores distintos.
- **BUGS SUTILES:** Al guardar, se puede sobrescribir el valor incorrecto.
- **MANTENIMIENTO PELIGROSO:** Un dev cambia `kcal` en un lugar, pero no se refleja en otro.

**🧠 Causa raíz técnica:**  
Violación de Single Source of Truth. `Client` tiene un getter `kcal` derivado, pero también existe `nutrition.kcal`. No está claro si son redundantes o diferentes.

**🛠️ Fix mínimo recomendado:**

1. Deprecar `client.kcal` si solo es un alias.
2. Usar SIEMPRE `client.nutrition.kcal`.
3. O convertir `client.kcal` en la única fuente y que `nutrition` no tenga ese campo.

**✅ Criterio de aceptación:**  
- Hacer grep de `client.kcal` y `client.nutrition.kcal`.
- Todas las referencias deben apuntar a la misma fuente.
- Test: cambiar kcal y verificar que se refleja en todos los lugares.

---

### 🟠 P1-004: CONDICIONES DE CARRERA EN `updateActiveClient` (PARCIALMENTE CORREGIDO)

**📁 Archivo:** `lib/features/main_shell/providers/clients_provider.dart`  
**📍 Línea:** 148

**⚠️ Síntoma observable:**  
- Se corrigió con merge-on-write y cola por cliente.
- PERO: No hay manejo de errores robusto si la cola falla.
- PERO: No hay logging para detectar cuando ocurren merges conflictivos.

**💣 Riesgo residual:**  
- Si dos módulos (nutrición + entrenamiento) guardan al mismo tiempo keys diferentes en `extra`, el merge funciona.
- Pero si uno FALLA y el otro SUCEDE, puede haber inconsistencia silenciosa.

**🧠 Causa raíz técnica:**  
El fix reciente (cola por cliente) soluciona la mayoría de casos, pero falta observabilidad y manejo de errores.

**🛠️ Fix mínimo recomendado:**

```dart
// Agregar logging cuando se detecta merge
if (mergedNutritionExtra.keys.length > updated.nutrition.extra.keys.length) {
  debugPrint('⚠️ MERGE: Se preservaron keys de versión previa');
}

// Agregar retry con límite
// (ya está implementado parcialmente)
```

**✅ Criterio de aceptación:**  
- Test concurrente con 2 saves simultáneos.
- Verificar que ambos cambios persisten.
- Verificar que se logea cuando ocurre un merge.

---

## HALLAZGOS P2 - IMPORTANTES (MEJORAS RECOMENDADAS)

### 🟡 P2-001: FALTA `copyWith` COMPLETO EN VARIOS MODELOS

**📁 Ejemplo:** Algunos modelos tienen `copyWith` incompleto o no nullable-aware.

**⚠️ Síntoma:** Dificulta actualizar entidades inmutables.

**🛠️ Fix:** Agregar `copyWith` completo a todos los value objects.

---

### 🟡 P2-002: ARCHIVOS DUPLICADOS Y PLACEHOLDERS

**📁 Ejemplos:**  
- `lib/features/nutrition_feature/widgets/emi2_questionnaire_screen.dart` (placeholder)
- `lib/domain/entities/emi2_questionnaire_screen.dart` (placeholder)
- Múltiples archivos marcados como "Código Fantasma"

**⚠️ Síntoma:** Confusión sobre qué código está en uso.

**🛠️ Fix:** Eliminar o comentar archivos no usados.

---

### 🟡 P2-003: NO HAY TESTS DE INTEGRACIÓN E2E

**📁 Carpeta:** `test/` solo tiene unit tests.

**⚠️ Síntoma:** No se valida el flujo completo usuario → DB → UI.

**🛠️ Fix:** Agregar al menos 3 tests E2E:
1. Crear cliente, agregar antropometría, verificar que aparece en gráficas.
2. Guardar plan de nutrición, cambiar fecha, verificar versionado.
3. Generar plan de entrenamiento (cuando esté implementado).

---

## ✅ QUÉ SÍ ESTÁ LISTO HOY

1. **Merge-on-write implementado** (corregido en esta sesión).
2. **Normalización de fechas en registros** (corregido).
3. **Suite de tests unitarios pasa** (13 tests green).
4. **UI renderiza correctamente** (no hay crashes aparentes).
5. **Base de datos local funciona** (SQLite operativo).
6. **Antropometría y bioquímica** (captura y muestra datos).

---

## ❌ QUÉ DEBE DESACTIVARSE TEMPORALMENTE

1. **Botón "Generar plan de entrenamiento"** → Mostrar "Próximamente" hasta que el motor esté implementado.
2. **Opciones de sincronización/Firebase** → Ocultar hasta que el repositorio remoto esté funcional.
3. **Features EMI-2 / Cuestionarios psicométricos** → Están como placeholders, remover de menú principal.

---

## 📊 RECOMENDACIÓN FINAL

### ¿Puede usarse en 10-11 días?

**SÍ, CON CONDICIONES:**

**Ruta crítica más corta a producción (7-9 días):**

**Día 1-2:** Fix P0-001 y P0-002 (`.last` y `DateTime.now()`).  
**Día 3-4:** Deshabilitar features placeholder (motor de entrenamiento, sync Firebase).  
**Día 5-6:** Implementar backup manual (export/import JSON).  
**Día 7-8:** Tests E2E básicos + QA manual.  
**Día 9:** Deploy con disclaimers claros ("v1.0 beta - solo local").

**Features utilizables en producción limitada:**
- ✅ Gestión de clientes (perfil, datos personales)
- ✅ Antropometría (mediciones, gráficas, análisis)
- ✅ Bioquímica (registro, comparación)
- ✅ Nutrición (cálculo TMB, macros, evaluación dietética)
- ✅ Planes de comidas (creación manual, adherencia)
- ❌ Generación automática de planes de entrenamiento (no funcional)
- ❌ Sincronización multi-dispositivo (no implementada)

**Disclaimers obligatorios para el usuario:**
- "Versión 1.0 - Datos almacenados solo localmente"
- "Realiza backups manuales periódicos"
- "Generación automática de planes en desarrollo"

---

## 🎯 CONCLUSIÓN

El proyecto tiene una base sólida pero NO está production-ready sin los fixes P0. La arquitectura es correcta, la UI es profesional, pero hay **2 bugs críticos de datos** que pueden causar decisiones clínicas incorrectas.

**Con los fixes propuestos y limitando el alcance inicial, PUEDE lanzarse en 10-11 días como beta limitada.**

**Sin los fixes P0, es IRRESPONSABLE usarlo con clientes reales.**

---

**Próximos pasos inmediatos:**
1. ¿Apruebas implementar fixes P0 ahora?
2. ¿Prefieres la ruta conservadora (deshabilitar features) o la ruta completa (implementar todo)?
