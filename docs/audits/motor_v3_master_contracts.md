# Motor V3 Master Contracts

## 1) Contrato de pipeline
Entry oficial: `trainingPlanProvider.generatePlanFromActiveCycle`.
Cadena obligatoria: gate -> ciclo/catalogo -> orchestrator -> motor -> builder -> forensic validator -> persistencia.

## 2) Contrato de split
Split gobierna arquitectura del dia.
Frecuencia se deriva de arquitectura real, no de numero aislado.

## 3) Contrato de tipo de dia
Cada dia define dominancia y slots permitidos.
x3/x4/x5/x6 deben mapearse en matriz oficial por tipo de dia.

## 4) Contrato de slots
A individual obligatorio.
B/C/D permiten singles o biseries condicionadas.
E no existe en runtime actual (pendiente decision).

## 5) Contrato de patrones
Seleccion por familia/patron, no por musculo crudo directo.
Patrones torso/pierna oficiales mapeados a movementPattern del catalogo.

## 6) Contrato de biseries
Permitidas: antagonista, baja interferencia, synergy.
Prohibidas: mismo primario, doble demanda sistemica alta, doble dominante pesado.

## 7) Contrato de densidad
Cap diario por musculo vigente: 10.
Sesion >50 sets blocking.
Se recomienda endurecer absurdos >45 o concentracion extrema.

## 8) Contrato de frecuencia
Frecuencia efectiva por split+dia elegible.
Si target excede capacidad: normalizar volumen factible, frecuencia rigida.

## 9) Contrato de fases
Runtime hoy: accumulation/intensification/deload + cycle phases internas.
AA/HF1/HF2/APC/AT/T aun requiere mapeo funcional final.

## 10) Contrato de adaptacion por bitacora
Ajuste semanal diferido.
No reescritura macro inmediata.
Artefactos: weeklyVolumeHistory + weeklyDecisionArtifactsV1 + progression state.

## 11) Contrato de tabla 52 semanas
No competidor: historico longitudinal.
Competidor: timeline hacia objetivo competitivo.

## Estado de cierre contractual
### Cerrado por codigo actual
1. Pipeline real con gate+validator final.
2. Frecuencia rigida con normalizacion de volumen factible.
3. Slots A-D y pairing contractual base.
4. Bitacora semanal y vista de 52 semanas.

### Pendiente por decision funcional
1. Mapeo AA/HF1/HF2/APC/AT/T a parametros runtime.
2. Matriz x5/x6 por tipo de dia totalmente operacional en builder.
3. Definir si bloque E entra al runtime.
