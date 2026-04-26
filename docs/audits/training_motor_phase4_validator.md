# Training Motor Phase 4 - Forensic Validator and Pipeline Closure

## Executive Summary
Phase 4 introduces a single forensic, centralized and blocking validator for final plan validation.

Main outcomes:
- Final validator implemented in one place.
- Blocking gate integrated after plan build in motor orchestrator.
- Blocking gate integrated before persistence in provider.
- Structured forensic logging added (rule, week, day, muscle, exercise).
- Legacy-route scan documented.

## Central Validator
File:
- lib/domain/training_v3/validators/training_plan_forensic_validator.dart

Result contract:
- isValid: bool
- blockingErrors: List<String>
- warnings: List<String>
- diagnostics: Map<String, dynamic>

Additional utility:
- logStructured(result): emits structured forensic logs for traceability.

## Validated Rules
### 2.1 Coverage
- Confirms expected muscles with target volume appear in the week.
- Blocks when expected target > 0 and actual sets == 0.

### 2.2 Frequency
- Enforces:
  - 6-12 sets -> f1
  - 13-22 sets -> f2
  - 23-34+ sets -> f3
- Blocks when observed weekly frequency differs from expected.

### 2.3 Intensity Correctness
- Detects mixed zones inside the same exercise instance.
- Blocks invalid intensity assignment semantics.

### 2.4 Rep Ranges by Zone
- Enforces valid zone ranges:
  - heavy -> 6-8
  - medium -> 8-12
  - light -> 15-20
- Blocks if reps cannot be mapped to a valid zone.

### 2.5 Structural Order
- Warns when low/moderate load appears before heavy in same session.

### 2.6 Pairing Validity
- Blocks same-primary pairing in biseries.
- Blocks pairing outside allowed set:
  - antagonist
  - lowInterference
  - synergy

### 2.7 Daily Feasibility
- Blocks hard session set overload.
- Blocks daily per-muscle cap overflow.
- Warns for soft overload/suboptimal concentration.

### 2.8 Redundancy
- Warns excessive same-exercise repetition.
- Warns excessive same-equivalenceGroup usage.

### 2.9 Zone Valid by Exercise
- Blocks when exercise is assigned to non-allowed zone per catalog metadata.

### 2.10 Selector Coherence
- Blocks unknown exercises outside catalog (invalid fallback signal).
- Warns when generation strategy is not recognized as V3 deterministic.

## Blocking vs Warning Classification
### Blocking errors
- intensidad inválida
- ejercicio incompatible con zona
- falta de cobertura
- frecuencia incorrecta
- pairing prohibido
- sobrecap diario crítico
- ejercicio fuera de catálogo (fallback inválido)

### Warnings
- redundancia leve
- distribución subóptima de sesión
- uso repetido de equivalentes
- orden estructural subóptimo
- estrategia no identificada como V3 determinística

## Pipeline Integration
## Motor integration
File:
- lib/domain/training_v3/services/motor_v3_orchestrator.dart

Flow:
1. Build plan.
2. Run TrainingPlanForensicValidator.validate(...).
3. If invalid -> return success=false with blocking errors and forensic payload.
4. If valid -> append warnings and continue.

## Provider integration
File:
- lib/features/training_feature/providers/training_plan_provider.dart

Flow:
1. Receive generated plan (before persistence).
2. Run TrainingPlanForensicValidator.validate(...).
3. If blocking errors -> abort save and return clear blocked state.
4. If only warnings -> continue persistence and log warnings.

## Legacy Route Validation Report
### Legacy selector usage detected
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:1573
  - ExerciseSelectionEngine.selectExercises(...) still used in legacy _buildSessions path.
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:1592
  - legacy day key marker found: "legacy_day_*".

### Paths with intensity-zone risk
- Legacy _buildSessions path in motor orchestrator does not prove explicit zone-materialized assignment contract equivalent to CycleTemplateBuilder strict path.
- Deterministic strict zone path remains in:
  - lib/domain/training_v3/services/cycle_template_builder.dart

### Paths bypassing forensic validator
- Main provider generation path now guarded before persistence.
- Main MotorV3Orchestrator.generateProgram path now guarded after build.
- Other persistence/update flows in provider that do not generate a new plan remain out of scope by design.

## Examples
Blocking example:
- [FORENSIC][BLOCKING][2.9_zone_valid_by_exercise] week=1 day=3 muscle=lats exercise=row_barbell Ejercicio row_barbell incompatible con zona light.

Warning example:
- [FORENSIC][WARNING][2.8_redundancy] week=1 exercise=bench_press Ejercicio repetido en exceso en semana 1: bench_press x3.

## Impact
- Validation is now centralized and final.
- Critical structural errors no longer pass as warnings into persistence.
- Forensic diagnostics are available for incident analysis and debugging.
