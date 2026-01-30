# Sistema teórico del volumen para la hipertrofia (documento normativo del motor)
> **Propósito**: Este documento es la **fuente canónica** del módulo de **volumen** del motor de hipertrofia.  
> **Regla**: Nada de lo aquí definido puede “suponerse” en código; todo debe implementarse explícitamente y auditarse.

---

## 0) Alcance, definiciones y garantías

### 0.1 Alcance
Este documento define:
- Qué significa **volumen** en hipertrofia (unidad primaria).
- Qué es una **serie efectiva**.
- La relación **volumen → hipertrofia** (con rendimientos decrecientes).
- El sistema de umbrales **MV / MEV / MAV / MRV**.
- Factores que desplazan esos umbrales.
- La **división muscular** obligatoria (incluida espalda desagregada).
- Reglas duras/blandas para prescripción.
- **Cómo debe operar el motor** (entradas, estados, decisiones, salidas).

Este documento **no** define aún:
- selección detallada de ejercicios (eso vive en el documento 05),
- técnicas avanzadas (doc 08),
- progresión completa (doc 07).

### 0.2 Definiciones rápidas (para consistencia semántica)
- **Volumen**: series efectivas por músculo por semana.
- **Serie efectiva**: serie con proximidad suficiente al fallo para reclutar alto umbral y generar tensión mecánica relevante.
- **RIR**: repeticiones en reserva (proxy de proximidad al fallo).
- **Fatiga**: costo acumulado que reduce rendimiento/recuperación.

### 0.3 Garantías del proyecto (normas de trabajo)
- No asumir nada que no esté en la fuente/documento/código.
- No “mejorar” sin mostrar el estado actual y justificar la decisión.
- Toda regla debe ser implementable y verificable (auditable).
- Nada se rompe en UI mientras auditamos (cambios compatibles y testeables).

---

## 1) Rol del volumen dentro del sistema

En un sistema de prescripción de entrenamiento orientado a hipertrofia, el **volumen** es la **variable primaria** que determina si ocurre o no hipertrofia muscular de forma consistente.  
Todas las demás variables (intensidad, frecuencia, esfuerzo, técnicas avanzadas) **operan dentro de los límites impuestos por el volumen**.

Desde la perspectiva del motor, esto implica:

1. **Definir límites fisiológicos del estímulo**: cuánto volumen puede ser productivo antes de transformarse en fatiga no productiva.  
2. **Definir el espacio válido de decisión**: qué combinaciones de volumen/frecuencia/intensidad son viables.  
3. **Definir condiciones de viabilidad**: cuándo una prescripción debe ajustarse o detenerse por recuperación insuficiente.

**Regla madre**:
> Ninguna decisión posterior puede violar los principios de volumen: si el volumen está fuera de rango, cualquier optimización de intensidad/frecuencia es cosmética y no rescata el programa.

---

## 2) Definición operativa de volumen

Para fines de hipertrofia, el volumen se define como:

> **Número de series efectivas realizadas por músculo a lo largo de una semana.**

El material y el consenso práctico en programación de hipertrofia sostienen que métricas como:
- tonelaje total,
- tiempo bajo tensión como métrica aislada,
- número total de repeticiones (sin esfuerzo),
no predicen la hipertrofia de forma fiable si no se considera:
- **proximidad al fallo**,  
- **calidad técnica**,  
- y **tensión mecánica efectiva**.

Por ello, el sistema adopta **series efectivas** como unidad central.

### 2.1 Por qué “series efectivas” es la unidad del motor
Para que el motor sea:
- **estable** (no sensible a cambios pequeños de tempo),
- **portable** (aplicable a múltiples ejercicios),
- **auditable** (fácil de revisar por coach),
se requiere una unidad simple pero fisiológicamente relevante.  
Series efectivas cumple con eso.

---

## 3) Serie efectiva: interpretación fisiológica

Una serie se considera efectiva cuando simultáneamente:
1. **Genera tensión mecánica suficiente** (carga y control).
2. **Recluta unidades motoras de alto umbral** (necesita esfuerzo).
3. **Se ejecuta con proximidad suficiente al fallo** (RIR bajo/moderado).

El análisis fisiológico clave:
- En una serie muy lejos del fallo, las primeras repeticiones pueden producir poco reclutamiento de alto umbral.
- El estímulo hipertrófico tiende a concentrarse en las repeticiones finales, donde el esfuerzo y el reclutamiento aumentan.

Por esta razón, el sistema define como criterio operativo principal:

> **Series ejecutadas aproximadamente entre 0 y 4 RIR constituyen el núcleo del volumen efectivo.**

**Nota importante**:
- Esto **no obliga** a entrenar al fallo siempre.
- Pero sí descarta como “volumen principal” series demasiado cómodas (RIR alto), salvo fases específicas.

### 3.1 Clasificación operativa de series (para motor)
Para decidir qué cuenta como volumen efectivo:

- **Efectiva (full credit)**: RIR 0–4  
- **Parcialmente efectiva (partial credit)**: RIR 5–6 *(si se usa, debe definirse ponderación explícita; por defecto el motor puede ignorarlas o contarlas como 0.5, pero esa decisión debe ser global y consistente)*  
- **No efectiva (no credit)**: RIR ≥7

> Recomendación de implementación: para evitar ambigüedad, iniciar con **binario** (cuenta / no cuenta). La ponderación puede introducirse en versiones futuras si se justifica.

---

## 4) Relación volumen–hipertrofia (interpretación teórica)

La relación observada en la literatura y representada en material pedagógico suele tener forma de:
- **aumento inicial pronunciado** (más volumen, más adaptación),
- **rendimientos decrecientes** (cada serie extra aporta menos),
- y un punto donde el exceso de volumen incrementa fatiga y reduce adaptación neta.

Interpretación aplicada:
- Incrementar el volumen produce mayor hipertrofia **hasta cierto punto**.
- Más allá de un umbral, el exceso de volumen:
  - incrementa fatiga,
  - reduce calidad de series,
  - aumenta riesgo de sobreuso,
  - puede disminuir la adaptación neta.

**Implicación**:
> Existe un rango óptimo de volumen por músculo (no universal) y el motor debe buscar ese rango, no “maximizar”.

---

## 5) Umbrales teóricos de volumen (MV / MEV / MAV / MRV)

El sistema conceptualiza el volumen mediante cuatro umbrales:

### 5.1 MV — Volumen de mantenimiento
Volumen mínimo necesario para **no perder masa muscular**.  
Útil para fases donde el músculo no es prioridad o cuando se reasigna recuperación.

### 5.2 MEV — Volumen mínimo efectivo
Volumen a partir del cual **comienza** la hipertrofia.  
Por debajo de MEV el estímulo es insuficiente o demasiado intermitente.

### 5.3 MAV — Volumen máximo adaptativo
Rango donde la hipertrofia progresa de forma **más eficiente** (mejor retorno por fatiga).  
Normalmente es el “sweet spot” que el motor prioriza durante acumulación.

### 5.4 MRV — Volumen máximo recuperable
Límite superior a partir del cual la fatiga supera la capacidad de recuperación.  
Entrar sostenidamente en MRV sin estrategia (deload / redistribución) conduce a estancamiento o regresión.

### 5.5 Propiedad crítica: umbrales dinámicos
Estos umbrales:
- varían entre individuos,
- cambian a lo largo del tiempo,
- dependen del contexto del programa.

**Regla del motor**:
> El motor no asume valores fijos; trabaja con rangos dinámicos que se recalibran con desempeño y fatiga.

---

## 6) Factores que modifican el volumen tolerable

### 6.1 Factores del individuo
- **Nivel de entrenamiento**: más experiencia suele elevar tolerancia y capacidad de trabajo.
- **Técnica**: mejor técnica permite series efectivas con menor costo articular y mayor especificidad.
- **Edad**: puede reducir capacidad de recuperación o requerir mayor control de fatiga.
- **Capacidad de recuperación**: sueño, estrés, nutrición, vida laboral.
- **Estado nutricional**: déficit energético reduce tolerancia y recuperación.

### 6.2 Factores del programa
- **Intensidad utilizada**: cargas altas elevan fatiga por serie, reducen MRV.
- **Proximidad al fallo**: entrenar muy cerca del fallo de manera sistemática reduce MRV.
- **Selección de ejercicios**: ejercicios de alto costo (axial/estabilidad) consumen recuperación.
- **Frecuencia semanal**: mayor frecuencia permite mejor distribución y puede elevar tolerancia al volumen.

Ejemplos interpretativos (reglas causales):
- Alta intensidad + fallo frecuente → **MRV más bajo** (menos series recuperables).
- Mayor frecuencia (bien distribuida) → **mejor tolerancia** y mantenimiento de calidad por sesión.

---

## 7) División muscular aplicada al volumen (decisión estructural)

Para evitar errores de cálculo, el sistema **prohíbe** agrupar musculatura de forma genérica.  
Se trabaja con **entidades musculares** que el motor puede contabilizar y ajustar.

### 7.1 Espalda — división oficial (congelada)
- **Lats (dorsal ancho)**  
  Jalones/dominadas; extensión/aducción de hombro.  
  *No se infiere desde remos.*

- **Espalda media y alta**  
  Romboides + trapecio medio/inferior + erectores torácicos (en la práctica de remos y control escapular).  
  *No se infiere desde jalones.*

- **Trapecio superior**  
  Entidad independiente; elevación escapular (encogimientos/carries).  
  *Nunca se infiere; se prescribe.*

### 7.2 Regla dura de contabilidad (anti-doble conteo)
- Remos → **espalda media/alta** (principal)  
- Jalones/dominadas → **lats** (principal)  
- Encogimientos/carries → **trapecio superior** (principal)

> Nota: Un ejercicio puede tener sinergistas, pero el motor, por consistencia, contabiliza volumen primario a una entidad principal salvo decisión explícita distinta (y auditada).

---

## 8) Reglas duras del motor (volumen)

Estas reglas son **inviolables**:

1. **No exceder MRV estimado** por músculo (y por semana) de forma sostenida.  
2. En fases de acumulación, **primero se incrementa volumen** antes que intensidad (si el objetivo es hipertrofia).  
3. **Series no efectivas no cuentan** como volumen primario (salvo un esquema de ponderación explícito y global).  
4. **No inferir volumen entre músculos** (ni por sinergias ni por “sensación”).  
5. **No concentrar volumen inviable por sesión**: si el volumen semanal supera cierto umbral, debe distribuirse (detallado en doc 02).

---

## 9) Reglas blandas del motor (volumen)

Estas reglas son adaptativas:

1. Si el rendimiento cae (a igualdad de condiciones), **ajustar volumen** antes de incrementar estímulo.  
2. Dos sujetos con mismo nivel pueden requerir volúmenes distintos (personalización).  
3. El volumen óptimo puede variar dentro de un ciclo (p. ej., semanas altas vs descarga).  
4. Músculos con alto costo articular o axial pueden requerir escalado más conservador.

---

## 10) Funcionamiento del motor (volumen): arquitectura y lógica

### 10.1 Entradas mínimas (inputs)
Por atleta y por músculo:
- Volumen actual (series efectivas/semana).
- Señales de desempeño: repeticiones, cargas, estabilidad técnica (tendencia).
- Señales de fatiga: DOMS prolongado, caída de rendimiento, estrés percibido, calidad de sueño (si existe).
- Fase actual del ciclo: acumulación / intensificación / descarga (si ya se implementa).
- Frecuencia disponible (días de entrenamiento) y split elegido (doc 06).

### 10.2 Estado interno (state)
- **volumen_semana[músculo]**
- **historial_volumen[músculo][semana]**
- **historial_rendimiento[ejercicio][semana]**
- **fatiga_estimada[músculo]** *(proxy; puede ser regla heurística)*  
- **umbral_ME V/MAV/MRV_est[músculo]** *(estimado dinámicamente)*

### 10.3 Salidas (outputs)
- Objetivo de volumen semanal por músculo.
- Distribución por sesión (doc 02).
- Reglas de ajuste para la siguiente semana (subir/mantener/bajar).

### 10.4 Decisión central (motor loop)
**Idea**: el motor no “adivina”, **reacciona** a señales.

Pseudológica (alto nivel):

1) Determinar si el músculo está en:
- **sub-MEV** → subir volumen (si hay recuperación)
- **MEV–MAV** → subir o mantener según respuesta
- **MAV–MRV** → mantener o microajustar, vigilar fatiga
- **>MRV** → bajar volumen y/o deload

2) Verificar señales:
- si rendimiento sube o estable y fatiga tolerable → permitir incremento
- si rendimiento cae o fatiga alta → reducir o redistribuir

### 10.5 Reglas de ajuste (operativas)
- **Incremento estándar**: +2 a +4 series/semana/músculo cuando hay respuesta positiva y espacio adaptativo.
- **Reducción estándar**: −2 a −6 series/semana/músculo cuando hay señales claras de exceso (según severidad).
- **Deload**: reducción global y/o por músculo cuando fatiga acumulada compromete desempeño (detallado en doc 07).

> Nota: Los números exactos deben alinearse con tu implementación y con el estándar de fases del motor; aquí se definen como reglas operativas iniciales.

---

## 11) Validación científica (criterio, no bibliografía exhaustiva)

Este marco es consistente con el consenso práctico y revisiones sobre:
- relación dosis–respuesta entre volumen y ganancia muscular,
- rendimientos decrecientes,
- influencia de proximidad al fallo en la efectividad de las series,
- variabilidad interindividual.

**Regla de validación**:
> Cada regla implementada debe mapearse a una justificación fisiológica explícita y una conducta observable (rendimiento/fatiga).

---

## 12) Resumen operativo (para UI / IA / auditoría)

- El volumen es la base del sistema.
- Se mide por series efectivas/semana/músculo.
- Existe un rango óptimo individual (MEV–MAV) y un límite (MRV).
- Más volumen no es siempre mejor.
- El motor regula volumen usando desempeño y fatiga, no intuición.
- La división muscular (especialmente espalda) es obligatoria para evitar doble conteo y errores de prescripción.

---

## 13) Checklist de implementación (para no “empobrecer” en código)

Antes de declarar este módulo “listo”:
- [ ] Existe una función `isEffectiveSet(RIR)` y una política explícita (binaria o ponderada).
- [ ] Existe contabilidad por músculo (incluye `lats`, `espalda_media_alta`, `trapecio_superior`).
- [ ] Existe histórico por semana y un comparador por tendencia.
- [ ] Existe regla de incremento/reducción y gatillos de fatiga.
- [ ] La UI muestra volumen por entidad y semana (no “espalda” genérica).
- [ ] Hay pruebas/validaciones mínimas para evitar sobreprescripción.

