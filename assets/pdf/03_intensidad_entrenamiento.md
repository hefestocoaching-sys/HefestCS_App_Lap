# Intensidad del entrenamiento  
## Rol modulador de la intensidad dentro del sistema de hipertrofia (documento normativo del motor)

> **Propósito**: Este documento define qué es la **intensidad** dentro del motor de hipertrofia, cómo se relaciona con el volumen, el esfuerzo y la fatiga, y bajo qué condiciones puede o no modificarse.  
> **Regla central**: La intensidad **no es una variable primaria** del sistema; actúa como **modulador del volumen efectivo y del MRV**.

---

## 0) Dependencias y alcance

Este documento depende explícitamente de:
- Documento 01: Sistema teórico del volumen.
- Documento 02: Distribución, frecuencia y acumulación.

Asume como **no negociable**:
- Volumen = series efectivas/semana/músculo.
- Series efectivas definidas por proximidad al fallo (RIR).
- Umbrales dinámicos MV / MEV / MAV / MRV.

Este documento **no** define:
- selección de ejercicios específica (doc 05),
- uso de técnicas avanzadas (doc 08),
- progresión temporal completa (doc 07).

---

## 1) Definición operativa de intensidad

Para fines del motor, la intensidad se define como:

> **La magnitud de la carga relativa utilizada en una serie**, usualmente expresada como %1RM o como rango de repeticiones posibles bajo condiciones normales.

La intensidad **no se evalúa de forma aislada**, sino siempre en conjunto con:
- RIR,
- tipo de ejercicio,
- y volumen total acumulado.

---

## 2) Por qué la intensidad no es variable primaria

El material y la evidencia práctica muestran que:
- La hipertrofia puede lograrse con un **rango amplio de intensidades**.
- No existe una intensidad única “óptima” para todos los contextos.
- Series con distintas intensidades pueden producir hipertrofia similar si se ejecutan con proximidad suficiente al fallo.

Por tanto:
- La intensidad **no determina por sí sola** si ocurre hipertrofia.
- El volumen efectivo acumulado es el determinante principal.
- La intensidad modifica **cómo de costoso** es acumular ese volumen.

**Regla conceptual**:
> La intensidad define el “precio” del volumen, no su valor adaptativo base.

---

## 3) Relación intensidad–repeticiones–RIR

### 3.1 Relación básica
- Intensidad alta → menos repeticiones posibles → fatiga neural y articular mayor por serie.
- Intensidad moderada/baja → más repeticiones posibles → mayor fatiga metabólica y local.

### 3.2 Interpretación fisiológica
A igual proximidad al fallo:
- Una serie pesada produce alta tensión mecánica por repetición.
- Una serie más ligera produce tensión suficiente pero requiere más repeticiones para alcanzar reclutamiento completo.

Ambas pueden ser efectivas, pero **no tienen el mismo costo de recuperación**.

---

## 4) Intensidad y volumen recuperable (MRV)

Uno de los roles clave de la intensidad en el motor es su impacto sobre el **MRV**.

### 4.1 Principio general
- A mayor intensidad promedio:
  - menor número de series recuperables,
  - mayor costo por serie,
  - mayor impacto articular y neural.

- A menor intensidad promedio:
  - mayor número de series tolerables,
  - mayor dependencia del control del RIR,
  - mayor fatiga metabólica.

### 4.2 Regla causal
> **La intensidad desplaza el MRV**: no cambia la necesidad de volumen, pero sí cuánto volumen puede tolerarse.

---

## 5) Rangos de intensidad funcionales para hipertrofia

El motor no trabaja con una intensidad “óptima” única, sino con **rangos funcionales**.

### 5.1 Principio de amplitud
Mientras:
- la serie sea efectiva (RIR adecuado),
- la técnica sea consistente,
- el volumen esté dentro de MAV,

la hipertrofia puede ocurrir en un rango amplio de intensidades.

### 5.2 Implicación para el motor
- El motor **no fija intensidades rígidas** por defecto.
- Ajusta la intensidad según:
  - fase del ciclo,
  - tolerancia individual,
  - costo de los ejercicios seleccionados.

---

## 6) Intensidad, ejercicio y costo de fatiga

La intensidad **no tiene el mismo efecto** en todos los ejercicios.

Factores que amplifican el costo de intensidad alta:
- ejercicios multiarticulares complejos,
- alta carga axial,
- alta demanda de estabilidad,
- proximidad frecuente al fallo.

Ejemplo interpretativo:
- Intensidad alta en aislamientos → costo manejable.
- Intensidad alta en bisagras o sentadillas → reducción marcada del MRV semanal.

**Regla del motor**:
> A mayor complejidad y costo del ejercicio, más conservadora debe ser la intensidad promedio.

---

## 7) Reglas duras del motor (intensidad)

Estas reglas no pueden violarse:

1. La intensidad **no se incrementa** si el volumen ya está cerca del MRV.
2. No se usa intensidad alta para compensar volumen insuficiente.
3. El motor no prescribe intensidad sin considerar RIR y volumen.
4. Ejercicios de alto costo no se llevan sistemáticamente a intensidades máximas.
5. La intensidad no se incrementa cuando el rendimiento cae.

---

## 8) Reglas blandas del motor

Estas reglas permiten adaptación:

1. Sujetos avanzados suelen tolerar mejor intensidades altas.
2. Aislamientos permiten intensidades mayores con menor impacto sistémico.
3. La intensidad puede variar entre sesiones dentro de la misma semana.
4. La preferencia individual puede influir si no viola reglas duras.

---

## 9) Funcionamiento del motor (intensidad): lógica interna

### 9.1 Entradas
- Volumen objetivo por músculo.
- Selección de ejercicios.
- RIR objetivo por fase.
- Historial de rendimiento (cargas/reps).
- Señales de fatiga.

### 9.2 Estado interno
- intensidad_promedio[músculo]
- costo_intensidad_estimado[músculo]
- MRV_estimado[músculo]

### 9.3 Decisiones
El motor decide:
- mantener intensidad,
- ajustar intensidad a la baja para permitir más volumen,
- ajustar intensidad al alza si hay margen adaptativo y buena recuperación.

### 9.4 Salidas
- Rangos de carga sugeridos.
- Advertencias si la intensidad compromete MRV o distribución.

---

## 10) Errores comunes que el motor debe evitar

- “Más peso siempre es mejor”.
- Subir intensidad cuando el problema es exceso de volumen.
- Ignorar el tipo de ejercicio al fijar cargas.
- Confundir intensidad con esfuerzo (fallo).

---

## 11) Integración con otros módulos

- Con Documento 01: la intensidad modula MRV, no sustituye volumen.
- Con Documento 02: la intensidad afecta cuánto volumen puede tolerarse por sesión.
- Con Documento 04: la intensidad debe interpretarse junto con RIR/fallo.
- Con Documento 07: la progresión de intensidad depende del estado del volumen.

---

## 12) Resumen operativo

- La intensidad es un **modulador**, no un driver principal.
- Afecta la cantidad de volumen recuperable.
- No existe intensidad única óptima.
- El motor prioriza volumen y calidad antes que carga absoluta.
- La intensidad se ajusta para sostener la progresión, no para forzarla.

---

## 13) Checklist de implementación

Antes de declarar este módulo completo:
- [ ] La intensidad nunca se ajusta sin referencia al volumen.
- [ ] Existe relación explícita intensidad ↔ MRV.
- [ ] El tipo de ejercicio modula la intensidad permitida.
- [ ] El motor detecta cuándo bajar intensidad para sostener volumen.
- [ ] La UI diferencia claramente carga, RIR y volumen.

