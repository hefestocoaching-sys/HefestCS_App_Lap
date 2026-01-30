# Técnicas de intensificación  
## Uso excepcional y controlado dentro del sistema de hipertrofia (documento normativo del motor)

> **Propósito**: Este documento define **qué son**, **para qué sirven** y **cuándo pueden usarse** las técnicas de intensificación dentro del motor de hipertrofia, así como **cuándo deben prohibirse**.  
> **Regla central**: Las técnicas de intensificación **no sustituyen** al volumen efectivo ni a la progresión; son **herramientas excepcionales** para contextos específicos.

---

## 0) Dependencias y alcance

Depende explícitamente de:
- Doc 01: Sistema teórico del volumen (MV/MEV/MAV/MRV).
- Doc 02: Distribución y frecuencia.
- Doc 03: Intensidad (modulador del MRV).
- Doc 04: Esfuerzo/RIR/fallo.
- Doc 05: Selección de ejercicios.
- Doc 06: Configuración y splits.
- Doc 07: Progresión y variación.

Asume como no negociable:
- El volumen efectivo es la base del estímulo.
- El MRV es dinámico y sensible al esfuerzo.
- La calidad de las series y la recuperación gobiernan el progreso.

---

## 1) Definición operativa de técnicas de intensificación

Se consideran **técnicas de intensificación** aquellas estrategias que:
- aumentan el **estrés por serie**,
- incrementan la **proximidad al fallo**,
- o extienden una serie más allá de su punto “normal” de terminación,

**sin aumentar proporcionalmente el volumen base**.

Ejemplos comunes:
- Drop sets
- Rest-pause
- Series extendidas
- Clusters (uso específico y acotado)

---

## 2) Problema que intentan resolver (y el que crean)

### 2.1 Problema que intentan resolver
- Falta de estímulo local cuando el volumen no puede aumentarse.
- Estancamiento puntual en músculos rezagados.
- Limitaciones logísticas (tiempo/sesión).

### 2.2 Problemas que crean si se usan mal
- Incremento desproporcionado de fatiga.
- Reducción del MRV efectivo.
- Dificultad para cuantificar volumen real.
- Compromiso de la recuperación sistémica.

**Conclusión**:
> Las técnicas intensifican el **costo**, no el **valor base** del estímulo.

---

## 3) Interpretación fisiológica del uso de técnicas

Las técnicas de intensificación:
- aumentan la fatiga periférica y central,
- prolongan el tiempo bajo alta activación,
- pueden incrementar el estrés metabólico.

Sin embargo:
- no aumentan linealmente la hipertrofia,
- no reemplazan la necesidad de series efectivas repetidas en el tiempo.

**Implicación**:
> Su beneficio es marginal y contextual; su costo es alto y acumulativo.

---

## 4) Relación con volumen y MRV

### 4.1 Impacto directo
El uso de técnicas:
- reduce el número de series recuperables posteriores,
- desplaza el MRV a la baja,
- exige recortes de volumen en otros lugares.

### 4.2 Regla causal
> Si se usan técnicas, **algo más debe bajar** (volumen, intensidad o frecuencia).

---

## 5) Contextos donde el motor puede permitirlas

Las técnicas **solo** pueden habilitarse cuando **todas** las condiciones se cumplen:

1. El músculo está cerca de MAV, pero no progresa.
2. El volumen no puede aumentarse sin violar MRV.
3. La selección de ejercicios es de **bajo costo** (aislamientos).
4. La fase del ciclo **no** es acumulación temprana.
5. La técnica del atleta es consistente.

---

## 6) Contextos donde el motor las prohíbe

Las técnicas están **prohibidas** cuando:
- se usan como base del programa,
- se aplican a ejercicios multiarticulares complejos,
- el volumen semanal ya está alto,
- hay señales de fatiga acumulada,
- se intenta “compensar” mala programación previa.

---

## 7) Reglas duras del motor (técnicas de intensificación)

Estas reglas no pueden violarse:

1. Las técnicas **no se usan** en fases de acumulación base.
2. Las técnicas **no sustituyen** volumen efectivo.
3. Solo se aplican a ejercicios de bajo costo biomecánico.
4. El uso de técnicas **reduce automáticamente el MRV estimado**.
5. No se permiten múltiples técnicas simultáneas para el mismo músculo.

---

## 8) Reglas blandas del motor

1. Uso ocasional puede mejorar adherencia.
2. Músculos pequeños toleran mejor técnicas aisladas.
3. Atletas avanzados pueden tolerar mayor densidad puntual.
4. La duración del uso debe ser limitada y explícita.

---

## 9) Funcionamiento del motor (técnicas): lógica interna

### 9.1 Entradas
- Estado del músculo (cercanía a MAV/MRV).
- Historial de respuesta.
- Tipo de ejercicio.
- Fase del ciclo.

### 9.2 Estado interno
- tecnicas_activas[músculo]
- impacto_MRV_estimado[músculo]
- fatiga_agregada[músculo]

### 9.3 Decisiones
El motor decide:
- habilitar o no técnicas,
- en qué ejercicio aplicarlas,
- cuánto volumen debe reducirse en compensación,
- cuándo retirarlas.

### 9.4 Salidas
- Indicaciones claras de uso.
- Alertas de riesgo si se excede frecuencia o duración.

---

## 10) Errores comunes que el motor debe evitar

- Usar técnicas como “atajo”.
- Acumular técnicas semana tras semana.
- Aplicarlas en ejercicios de alto riesgo.
- Ignorar su impacto acumulativo.

---

## 11) Integración con otros módulos

- Con Doc 01: las técnicas no cambian qué es volumen efectivo.
- Con Doc 02: afectan la distribución viable por sesión.
- Con Doc 03 y 04: amplifican el costo de intensidad y esfuerzo.
- Con Doc 07: son una herramienta de último recurso, no de progresión base.

---

## 12) Resumen operativo

- Las técnicas intensifican el costo, no el estímulo base.
- Su beneficio es marginal y contextual.
- Su uso reduce MRV y exige compensaciones.
- El motor las usa como excepción, no como norma.
- Retirarlas a tiempo es tan importante como aplicarlas.

---

## 13) Checklist de implementación

Antes de marcar este módulo completo:
- [ ] Las técnicas no están disponibles por defecto.
- [ ] Su activación depende del estado del músculo.
- [ ] El MRV se ajusta automáticamente al usarlas.
- [ ] La UI advierte su costo y duración limitada.
- [ ] El motor fuerza su retirada tras el periodo definido.

