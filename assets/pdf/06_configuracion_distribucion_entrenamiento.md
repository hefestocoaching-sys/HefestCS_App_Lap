# Configuración y distribución del entrenamiento  
## Splits, orden y compatibilidad muscular (documento normativo del motor)

> **Propósito**: Este documento define **cómo se organiza** el entrenamiento en el tiempo (splits, días, orden) para **materializar el volumen** definido en los Documentos 01–05 sin degradar la calidad de las series ni violar límites de recuperación.  
> **Regla central**: La configuración **no crea estímulo**; solo **lo hace viable**. Un buen volumen mal configurado es un mal programa.

---

## 0) Dependencias y alcance

Depende explícitamente de:
- Doc 01: Sistema teórico del volumen.
- Doc 02: Distribución y frecuencia.
- Doc 03: Intensidad (modulador).
- Doc 04: Esfuerzo/fallo.
- Doc 05: Selección de ejercicios.

Asume como no negociable:
- Contabilidad por **entidad muscular**.
- MRV dinámico.
- Volumen efectivo por semana y por sesión.

Este documento **no** define:
- progresión temporal (doc 07),
- técnicas de intensificación (doc 08).

---

## 1) Problema que resuelve la configuración

La configuración responde a **cómo** se:
- agrupan músculos por sesión,
- ordenan ejercicios dentro del día,
- distribuyen días de estímulo y descanso,

para que:
- el volumen planificado **pueda ejecutarse**,
- la fatiga no invalide series posteriores,
- el rendimiento sea consistente semana a semana.

**Regla**:
> Si la configuración obliga a violar límites por sesión (Doc 02), debe corregirse la configuración, no “forzar” al atleta.

---

## 2) Splits: definición operativa

Un **split** es la estructura que define:
- qué músculos se entrenan cada día,
- cuántos días se entrena a la semana,
- cómo se repite el estímulo.

El motor **congela el split** al inicio del ciclo para:
- permitir adaptación,
- hacer auditable el volumen,
- evitar ruido de programación.

---

## 3) Splits permitidos por el motor

El motor solo permite splits que **respetan** distribución y recuperación.

### 3.1 Full Body
- Todos (o casi todos) los músculos en cada sesión.
- Frecuencia alta, volumen por sesión bajo.
- Útil para:
  - volúmenes bajos a moderados,
  - fases iniciales,
  - sujetos con tiempo limitado.

### 3.2 Upper / Lower
- Separación tren superior / inferior.
- Frecuencia 2x por músculo (típica).
- Buen balance entre volumen por sesión y recuperación.

### 3.3 Torso / Pierna
- Similar a Upper/Lower, pero con mayor granularidad.
- Permite priorizar torso o pierna según orden y volumen.

### 3.4 Push / Pull / Legs (PPL)
- Alta especificidad.
- Mayor volumen por sesión para grupos afines.
- Requiere control estricto de fatiga y volumen por sesión.

**Regla dura**:
> Splits no listados no se habilitan sin justificación explícita y pruebas.

---

## 4) Orden de ejercicios dentro de la sesión

### 4.1 Principio general
El orden afecta:
- calidad técnica,
- carga manejable,
- número de series efectivas reales.

**Regla base**:
> Lo más prioritario y demandante va primero.

### 4.2 Criterios de orden
1. Músculos prioritarios del ciclo.
2. Ejercicios multiarticulares antes que aislamientos.
3. Ejercicios de alto costo antes que bajo costo.
4. Aislamientos al final para completar volumen.

---

## 5) Compatibilidad muscular (interferencia)

### 5.1 Concepto
La compatibilidad se refiere a:
- cuánto interfieren dos músculos o patrones cuando se entrenan juntos,
- cómo la fatiga de uno afecta al otro.

### 5.2 Ejemplos de interferencia
- Bisagras pesadas + sentadillas el mismo día → alta interferencia.
- Remos + jalones en exceso → degradación escapular.
- Hombro anterior fatigado antes de presses → reducción de rendimiento.

**Regla**:
> El motor evita agrupar músculos/patrones de alta interferencia cuando el volumen es moderado–alto.

---

## 6) Distribución diaria y límites por sesión

La configuración debe respetar:
- límites de volumen por sesión (Doc 02),
- costo de ejercicios (Doc 05),
- esfuerzo objetivo (Doc 04).

**Regla dura**:
> Si una sesión se satura, se redistribuye el volumen o se ajusta el split.

---

## 7) Reglas duras del motor (configuración)

1. El split no cambia dentro del ciclo salvo deload/transición.
2. No se agrupan excesivos músculos de alta demanda el mismo día.
3. El orden no se altera sin justificación fisiológica.
4. La configuración debe permitir cumplir volumen sin degradar series.
5. El descanso es parte de la configuración (no opcional).

---

## 8) Reglas blandas del motor

1. Atletas avanzados toleran configuraciones más densas.
2. Preferencias logísticas pueden considerarse.
3. Se permiten asimetrías leves entre días si no violan reglas duras.
4. La prioridad del ciclo puede modificar el orden.

---

## 9) Funcionamiento del motor (configuración): lógica interna

### 9.1 Entradas
- Split seleccionado.
- Días disponibles.
- Volumen semanal por músculo.
- Selección de ejercicios.
- Prioridades del ciclo.

### 9.2 Estado interno
- sesiones[día]
- volumen_por_sesion[músculo][día]
- costo_sesion[día]

### 9.3 Decisiones
El motor decide:
- qué músculos van en cada día,
- el orden de ejercicios,
- si la sesión es viable o debe redistribuirse.

### 9.4 Salidas
- Calendario semanal.
- Orden de ejercicios por sesión.
- Alertas de saturación/interferencia.

---

## 10) Errores comunes que el motor debe evitar

- Cambiar split “para variar”.
- Ignorar interferencias por conveniencia.
- Meter todo el volumen prioritario en un solo día.
- Subestimar el impacto del orden.

---

## 11) Integración con otros módulos

- Con Doc 02: la configuración materializa la distribución.
- Con Doc 05: el costo del ejercicio condiciona la sesión.
- Con Doc 07: la progresión se apoya en una estructura estable.

---

## 12) Resumen operativo

- La configuración hace **ejecutable** el estímulo.
- El split se congela para permitir adaptación.
- El orden protege la calidad de las series.
- La compatibilidad evita interferencias.
- El motor reorganiza antes de forzar.

---

## 13) Checklist de implementación

Antes de marcar este módulo completo:
- [ ] El split está congelado por ciclo.
- [ ] Existe validación de saturación por sesión.
- [ ] El orden de ejercicios es explícito.
- [ ] La UI muestra estructura semanal clara.
- [ ] El motor puede redistribuir volumen automáticamente.

