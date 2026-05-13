# Auditoría de Fórmulas Antropométricas — HefestoCS

## Alcance
Auditoría de fórmulas en:
- lib/domain/services/anthropometry_analyzer.dart
- lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart
- lib/domain/entities/anthropometry_record.dart

## Fórmulas detectadas

### Yuhasz SUM6
Código detectado:
- sumOfSkinfolds()
- _yuhaszBodyFat()

Estado:
- Implementada.
- Usa 6 pliegues.
- Requiere validación posterior contra el protocolo exacto definido como “ISAK 1” en el negocio.

### Jackson-Pollock 4 sitios
Código detectado:
- _jacksonPollock4()

Estado:
- Implementada como fallback.
- No debe confundirse con ISAK.
- Requiere etiquetado claro en UI si se usa.

### RFM
Código detectado:
- _calculateRfm()

Estado:
- Implementada.
- Requiere cintura y estatura; sexo ajusta fórmula.

### Deurenberg básico
Código detectado:
- _calculateBasicBodyFat()

Estado:
- Estimación básica por IMC.
- Menos precisa que ISAK/RFM.
- Correctamente marcada como aproximada en UI.

### Masa ósea Rocha
Código detectado:
- _boneMassKgRocha()

Estado:
- Usa estatura, muñeca y rodilla/fémur.
- Húmero agregado como dato antropométrico, pero no integrado a esta fórmula sin validación.

### Masa muscular Lee
Código detectado:
- _muscleMassLeeModel()

Estado:
- Usa perímetros corregidos y pliegues.
- No depende de húmero.

## Hallazgos

### F-001 — Falta húmero en diámetros
Se agregó humerusDiameter al modelo y UI.

### F-002 — Read-only no mostraba M1/M2/M3
Se debe mostrar cada toma individual y método de finalización.

### F-003 — Fórmulas requieren definición de estándar ISAK 1 de negocio
Antes de declarar “ISAK 1 preciso”, se debe definir qué ecuación oficial se usará para:
- % grasa
- masa grasa
- masa ósea
- masa muscular
- residual

## Recomendación
No cambiar fórmulas sin documento técnico de referencia. Primero cerrar definición científica del protocolo.
