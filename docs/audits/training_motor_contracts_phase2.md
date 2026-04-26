# Formalizacion de contratos y SSOT del motor de entrenamiento - Phase 2 (controlada)

Fecha: 2026-04-17
Scope: pipeline real V3 y politicas auxiliares directas (intensidad, normalizacion muscular, ordering, pairing).

## 1) Objetivo de esta fase

Esta fase formaliza contratos funcionales criticos sin rehacer arquitectura ni crear pipeline paralelo.

Incluye:
- cierre de reglas criticas de negocio
- unificacion de SSOTs
- eliminacion de ambiguedad operativa
- base contractual para refactor posterior

No incluye:
- motor V4
- refactor masivo
- catalogo nuevo
- cambios UI estructurales

## 2) Reglas funcionales formalizadas

### 2.1 Frecuencia por volumen (contrato formal)
Archivo contrato: `lib/domain/constants/volume_to_frequency_rule.dart`

Regla cerrada:
- 6-12 series -> frecuencia 1
- 13-22 series -> frecuencia 2
- 23-34 series -> frecuencia 3

Integracion:
- `lib/domain/constants/frequency_by_volume.dart` delega en `VolumeToFrequencyRule`.
- `lib/domain/training_v3/services/cycle_template_builder.dart` usa el contrato para calcular frecuencia por musculo.

Legacy:
- `FrequencyByVolume.volumeThresholdFor3x` queda marcado como `@Deprecated`.

### 2.2 Intensidad por tamano muscular (contrato formal)
Archivo contrato: `lib/domain/policies/muscle_size_intensity_policy.dart`

Regla declarada:
- small -> medium + light
- large -> heavy + medium + light

Estado de aplicacion:
- Contrato formalizado y reusable.
- No se modifica `intensity_engine.dart` en esta fase (restriccion explicita).

### 2.3 Inicio de semana (contrato formal)
Archivo contrato: `lib/domain/policies/week_start_policy.dart`

Regla cerrada:
- predominio torso -> inicia torso
- predominio pierna -> inicia pierna
- empate -> torso (deterministico)

Integracion:
- `CycleTemplateBuilder._distributeUpperLower` aplica el contrato para definir si el dia 1 inicia en torso o pierna.

### 2.4 Inicio del dia (contrato formal)
Archivo contrato: `lib/domain/policies/day_start_policy.dart`

Regla cerrada:
- dia inicia con musculo primario dominante

Integracion:
- `CycleTemplateBuilder._findPrimaryMuscleForDay` delega al contrato.

### 2.5 Orden estructural base (contrato formal)
Archivo contrato: `lib/domain/policies/structural_exercise_order_contract.dart`

Regla base declarada:
1. prioridad
2. heavy
3. estructura 1-12
4. tamano muscular

Integracion:
- `lib/domain/training_v3/engines/ordering_engine.dart` usa el contrato estructural (matriz 1-12 centralizada).
- `lib/domain/training_v3/data/exercise_ordering_rules.dart` elimina heuristica duplicada y delega al contrato.
- `lib/domain/policies/day_exercise_ordering_policy.dart` se alinea al mismo contrato.

Nota:
- la prioridad del dia se sigue resolviendo en el builder (bloque A y musculo primario dominante) sin extender heuristicas legacy.

### 2.6 Pairing (contrato formal)
Archivo contrato: `lib/domain/policies/pairing_contract.dart`

Tipos formales:
- antagonist
- lowInterference
- synergy
- forbiddenSamePrimary
- none

Reglas:
- permitido: antagonist, lowInterference, synergy
- prohibido: mismo musculo primario en biserie

Integracion:
- `lib/domain/training_v3/engines/session_structure_engine.dart` usa `PairingContract` para validar pairing permitido y bloquear same_primary.
- `lib/domain/training_v3/services/cycle_template_builder.dart` utiliza el contrato en seleccion de candidatos de bloque B.

## 3) Unificacion SSOT muscular

### 3.1 SSOT activo
SSOT muscular unico activo:
- `lib/core/registry/muscle_registry.dart`

### 3.2 Adaptador de compatibilidad
- `lib/core/utils/muscle_key_normalizer.dart` se mantiene como adaptador legacy que delega al registry.

### 3.3 Pseudo-SSOTs eliminados/encapsulados

Eliminados de flujo directo:
- normalizador local con `labelToKeyMap` en `training_workspace_screen.dart`
- mapping UI no canonico (`chest`, `deltoide_*`) en `training_profile_form_mapper.dart`

Estado final:
- normalizacion de prioridades musculares en UI/providers pasa por `muscle_registry.normalize/expandGroup`
- salida persistida para prioridades usa claves canonicicas

## 4) Archivos modificados en esta fase

- `lib/domain/constants/frequency_by_volume.dart`
- `lib/domain/constants/volume_to_frequency_rule.dart` (nuevo)
- `lib/domain/policies/muscle_size_intensity_policy.dart` (nuevo)
- `lib/domain/policies/week_start_policy.dart` (nuevo)
- `lib/domain/policies/day_start_policy.dart` (nuevo)
- `lib/domain/policies/pairing_contract.dart` (nuevo)
- `lib/domain/policies/structural_exercise_order_contract.dart` (nuevo)
- `lib/domain/policies/day_exercise_ordering_policy.dart`
- `lib/domain/training_v3/engines/ordering_engine.dart`
- `lib/domain/training_v3/data/exercise_ordering_rules.dart`
- `lib/domain/training_v3/engines/session_structure_engine.dart`
- `lib/domain/training_v3/services/cycle_template_builder.dart`
- `lib/features/training_feature/screens/training_workspace_screen.dart`
- `lib/features/training_feature/services/training_profile_form_mapper.dart`

## 5) Elementos fuera de alcance y no modificados

Por restriccion explicita de fase, solo documentados como deuda tecnica para fases posteriores:

- `lib/domain/services/training_program_engine.dart`
- `lib/domain/services/deterministic_session_composer.dart`
- `lib/domain/training_v3/services/phase_1_data_ingestion_service.dart`
- `lib/domain/training_v3/services/phase_2_readiness_evaluation_service.dart`
- `lib/domain/training_v3/services/phase_3_volume_capacity_model_service.dart`
- `lib/domain/training_v3/services/phase_4_split_distribution_service.dart`
- `lib/domain/training_v3/services/phase_5_periodization_service.dart`
- `lib/domain/training_v3/services/phase_6_exercise_selection_service.dart`
- `lib/domain/training_v3/services/phase_7_prescription_service.dart`
- `lib/domain/training_v3/services/phase_8_adaptation_service.dart`

Razon:
- fase controlada sin motor paralelo ni refactor completo
- objetivo contractual/SSOT, no reimplementacion de etapas legacy

## 6) Conexion con la siguiente fase

La siguiente fase puede concentrarse en migracion/refactor interno de engines con bajo riesgo porque ya existe:
- contrato unico de frecuencia
- contrato unico de normalizacion muscular
- contrato de inicio de semana/dia
- contrato formal de pairing permitido/prohibido
- contrato estructural base de ordering

Con estos contratos, las migraciones futuras pueden ser verificables contra reglas cerradas y sin ambiguedad funcional.
