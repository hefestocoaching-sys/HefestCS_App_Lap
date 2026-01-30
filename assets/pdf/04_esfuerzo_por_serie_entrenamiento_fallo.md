# Esfuerzo por serie y entrenamiento al fallo  
## Rol del esfuerzo dentro del sistema de hipertrofia (documento normativo del motor)

> **Propósito**: Este documento define qué es el **esfuerzo** en una serie, cómo se operacionaliza mediante **RIR**, cuál es el rol real del **fallo muscular**, y bajo qué condiciones su uso es válido o contraproducente.  
> **Regla central**: El esfuerzo es un **regulador de efectividad y fatiga**, no un objetivo en sí mismo.

---

## 0) Dependencias y alcance

Este documento depende explícitamente de:
- Documento 01: Sistema teórico del volumen.
- Documento 02: Distribución, frecuencia y acumulación.
- Documento 03: Intensidad como modulador del volumen.

Asume como no negociable:
- Volumen = series efectivas/semana/músculo.
- Serie efectiva definida por proximidad al fallo (RIR).
- MRV dinámico afectado por intensidad, volumen y esfuerzo.

Este documento **no** define:
- progresión temporal completa (doc 07),
- técnicas avanzadas específicas (doc 08).

---

## 1) Definición operativa de esfuerzo

En el motor, el **esfuerzo** se define como:

> **La proximidad de una serie al fallo muscular**, medida operativamente mediante **RIR (Repeticiones en Reserva)**.

Donde:
- RIR 0 = fallo muscular concéntrico.
- RIR 1–2 = muy cercano al fallo.
- RIR 3–4 = esfuerzo alto, pero controlado.
- RIR ≥5 = esfuerzo bajo a moderado.

El esfuerzo **no equivale** a intensidad:
- Puede existir alta intensidad con bajo esfuerzo (series cortas lejos del fallo).
- Puede existir baja intensidad con alto esfuerzo (series largas cerca del fallo).

---

## 2) Por qué el esfuerzo es crítico para la hipertrofia

La hipertrofia depende de:
- tensión mecánica suficiente,
- reclutamiento de unidades motoras de alto umbral,
- repetición sostenida de ese estímulo a lo largo del tiempo.

El esfuerzo es el factor que:
- fuerza el reclutamiento de alto umbral cuando la carga no lo hace por sí sola,
- determina qué fracción de una serie es realmente estimulante.

**Conclusión clave**:
> Sin esfuerzo suficiente, el volumen “planeado” no se convierte en volumen efectivo.

---

## 3) Interpretación fisiológica del RIR

### 3.1 Reclutamiento progresivo
Durante una serie:
- las primeras repeticiones reclutan unidades de bajo umbral,
- conforme aumenta la fatiga, se reclutan unidades de mayor umbral,
- las repeticiones cercanas al fallo concentran la mayor parte del estímulo hipertrófico.

### 3.2 Implicación operativa
Esto explica por qué:
- series muy largas y cómodas aportan poco estímulo,
- y por qué el RIR es una métrica más útil que el número total de repeticiones.

---

## 4) Fallo muscular: definición y contexto real

### 4.1 Qué es el fallo
El fallo muscular concéntrico ocurre cuando:
- no es posible completar otra repetición con técnica aceptable,
- a pesar de esfuerzo máximo voluntario.

### 4.2 Qué NO es el fallo
- No es sinónimo de hipertrofia garantizada.
- No es necesario en todas las series.
- No es neutro en términos de fatiga.

---

## 5) Interpretación del material sobre fallo vs RIR

El análisis del material y de la evidencia aplicada muestra que:
- Series muy cercanas al fallo (RIR 0–1) y series con RIR moderado (2–3) producen hipertrofia similar.
- El fallo sistemático incrementa la fatiga de forma desproporcionada.
- El uso crónico del fallo reduce el volumen recuperable semanal.

**Conclusión aplicada**:
> El fallo **no añade hipertrofia proporcional**, pero sí añade fatiga.

---

## 6) Impacto del fallo sobre MRV y calidad del estímulo

### 6.1 Efecto sobre MRV
Entrenar frecuentemente al fallo:
- reduce el número de series recuperables,
- acelera la acumulación de fatiga central y periférica,
- incrementa el riesgo de estancamiento.

### 6.2 Efecto sobre la calidad
- Aumenta la degradación técnica.
- Eleva el riesgo articular, especialmente en multiarticulares.
- Reduce la consistencia del estímulo semana a semana.

---

## 7) Uso estratégico del fallo dentro del motor

El fallo **no está prohibido**, pero su uso es **contextual y limitado**.

### 7.1 Contextos donde puede ser aceptable
- Ejercicios de aislamiento.
- Fases finales del ciclo.
- Volumen total controlado.
- Atletas con buena técnica y recuperación.

### 7.2 Contextos donde debe evitarse
- Ejercicios multiarticulares complejos.
- Fases de acumulación de volumen.
- Cuando el volumen ya está cerca de MRV.
- Cuando hay señales de fatiga acumulada.

---

## 8) Reglas duras del motor (esfuerzo y fallo)

Estas reglas no pueden violarse:

1. El motor **evita el fallo sistemático** como estrategia base.
2. El fallo reduce automáticamente el MRV estimado.
3. No se prescribe fallo en fases de acumulación de volumen.
4. Multiarticulares no se llevan sistemáticamente a RIR 0.
5. Si el rendimiento cae, se reduce esfuerzo antes que aumentar estímulo.

---

## 9) Reglas blandas del motor

1. El fallo ocasional puede usarse como herramienta diagnóstica.
2. La tolerancia al fallo varía entre individuos.
3. El RIR objetivo puede variar por ejercicio.
4. Preferencias individuales pueden considerarse si no violan reglas duras.

---

## 10) Funcionamiento del motor (esfuerzo): lógica interna

### 10.1 Entradas
- RIR objetivo por fase.
- Tipo de ejercicio.
- Volumen semanal por músculo.
- Intensidad promedio.
- Señales de fatiga y rendimiento.

### 10.2 Estado interno
- RIR_real_promedio[músculo]
- frecuencia_fallo[músculo]
- fatiga_estimada[músculo]
- MRV_estimado[músculo]

### 10.3 Decisiones
El motor decide:
- mantener RIR objetivo,
- alejar RIR del fallo para sostener volumen,
- permitir fallo puntual en contextos válidos.

### 10.4 Salidas
- RIR recomendado por ejercicio.
- Alertas si el esfuerzo compromete MRV o calidad.

---

## 11) Errores comunes que el motor debe evitar

- “Entrenar al fallo siempre es mejor”.
- Confundir intensidad con esfuerzo.
- Usar fallo para compensar mala programación de volumen.
- Ignorar señales tempranas de fatiga.

---

## 12) Integración con otros módulos

- Con Documento 01: el esfuerzo define qué series cuentan como efectivas.
- Con Documento 02: el esfuerzo afecta cuántas series pueden concentrarse por sesión.
- Con Documento 03: la intensidad amplifica el costo del esfuerzo.
- Con Documento 08: técnicas avanzadas no sustituyen el control del esfuerzo.

---

## 13) Resumen operativo

- El esfuerzo convierte volumen planeado en volumen efectivo.
- El fallo no es obligatorio ni óptimo de forma crónica.
- RIR es la métrica central para regular esfuerzo.
- El motor prioriza consistencia y recuperación.
- El esfuerzo se ajusta para sostener el progreso, no para forzarlo.

---

## 14) Checklist de implementación

Antes de marcar este módulo como completo:
- [ ] El motor registra RIR real por ejercicio.
- [ ] Existe límite explícito de frecuencia de fallo.
- [ ] El MRV se ajusta según esfuerzo real.
- [ ] La UI diferencia claramente RIR, carga y volumen.
- [ ] El sistema reduce esfuerzo ante caída de rendimiento.

