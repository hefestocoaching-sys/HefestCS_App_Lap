# Forensic PST Volume Audit

## Contrato PST
- Primario: cap en `VMR` (o soft-overreach controlado por flag)
- Secundario: cap `75% VMR`
- Terciario: cap en `VOP`

## Evidencia
- Motor aplica cap temprano antes de materialización (`_enforcePriorityCapsBeforeMaterialization`).
- Validator revalida caps por músculo y severidad bloqueante cuando aplica.
- Validator también emite warning por debajo de `VME`.

Referencias:
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart` (cap temprano)
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart` (`_validatePriorityContract`)

## Hallazgos
1. El contrato PST está implementado en dos capas (prevención + auditoría).
2. La política `primaryOverVmrAllowed` está contemplada y auditada.
3. El sistema bloquea correctamente excesos de bandas prioritarias.

## Riesgos
- **P1**: Si prioridades llegan incompletas, defaults pueden empujar músculos a banda menos precisa.
- **P2**: Divergencias de normalización de muscle keys pueden desalinear lectura de landmarks si upstream falla.

## Veredicto
- **PST volume contract**: `FUERTE`.
