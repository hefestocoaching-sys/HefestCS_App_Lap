# AUDIT_MUSCLE_SSOT_D1C8_CYCLE_TEMPLATE_BUILDER_STRICT_REPORT

Resumen:
- Objetivo: Migrar `CycleTemplateBuilder` a la API estricta (`muscle_registry.tryNormalizeMuscleKey` / `normalizeMuscleKeyOrThrow` / `expandMuscleGroupStrict`) para evitar devoluciones de claves "raw" y alinear la construcción de la plantilla semanal con el SSOT.
- Alcance: cambios únicamente en `lib/domain/training_v3/services/cycle_template_builder.dart` (normalización estricta), plus fixtures/tests correspondientes según plan D1-C8.

Cambios aplicados:
- `normalizeMuscleKey` ahora usa `muscle_registry.tryNormalizeMuscleKey` y lanza `StateError` con prefijo `[V3][MUSCLE_NORMALIZE_FAIL]` cuando la clave es desconocida. Esto evita que se devuelva el raw token en las rutas internas del builder.

Razonamiento:
- Contrato SSOT: el builder debe operar sólo sobre claves canónicas conocidas. Permitir fallback a raw genera comportamiento no determinístico y falsos positivos en emparejamientos/pairing.
- Falla temprana: lanzar un error claramente etiquetado permite localizar y corregir inputs/fixtures/UX que suministren claves inválidas.

Impacto esperado y mitigaciones:
- Tests/fixtures que antes asumían normalización lax deben actualizarse para reflejar reglas estrictas (p.ej. `glute` ya no se normaliza a `glutes`).
- En inputs externos (API/UX) se debe validar musculatura contra SSOT antes de llegar a este builder. Se recomienda un adapter en capa superior si se requiere comportamiento tolerante.

Siguientes pasos recomendados:
1. Actualizar los fixtures en `test/fixtures/training_v3/cycle_template_builder/` para eliminar tokens raw inválidos y reflejar claves canónicas.
2. Ajustar el harness y tests (regression harness) para esperar `StateError` con el prefijo `[V3][MUSCLE_NORMALIZE_FAIL]` cuando aplique, o corregir inputs a canónicos.
3. Ejecutar las pruebas focales y `flutter analyze --no-pub`.
4. Si se prefiere un comportamiento no-throw en algunos flujos, implementar un envoltorio que traduzca unknowns a una política explícita (`drop`, `warn`, `fallback-to-group`) fuera del builder.

Notas técnicas:
- Archivo modificado: `lib/domain/training_v3/services/cycle_template_builder.dart` (normalización estricta)
- Nueva señal de error: `StateError('[V3][MUSCLE_NORMALIZE_FAIL] unknown muscle key="<raw>"')`
- API usada: `muscle_registry.tryNormalizeMuscleKey(String): String?`

Registro de verificación:
- Cambios mínimos para mantener el scope del ticket D1-C8.
- Es crítico sincronizar fixtures y tests antes de ejecutar la suite completa.

Autor: Equipo de migración SSOT
Fecha: (automatizar al commitear)

Open issues (restantes):
- INTENSITY_PRECHECK_FAIL (biceps, day=1): durante la generación del programa el paso de pre-check de intensidad falla con
	"Bad state: [V3][P9][INTENSITY_PRECHECK_FAIL] muscle=biceps day=1 requiredZone=medium no compatible exercise in locked pool."
	- Afecta a: `test/domain/training_v3/services/motor_v3_cycle_state_regression_test.dart` (2 casos de prueba que esperan generación exitosa).
	- Contexto: ocurre tras reconstruir el pool desde el catálogo de test-injectado cuando el pool "locked" no contiene un candidato compatible para la zona requerida por la política.
	- Recomendación: (1) ampliar el catálogo de prueba para incluir ejercicios compatibles con `medium` para `biceps` en el pool locked, o (2) ajustar la política de pre-check para tolerar ausencia (degradado con warning), o (3) modificar el flujo de bloqueo de pool para no bloquear ejercicios necesarios para satisfacer zonas mínimas.

- Nota: el fallo previo sobre `glute` vs `glutes` fue abordado actualizando fixtures y el harness (se mantiene observado que `glute` queda como raw en casos strict y el proxy devuelve `pairingType: none`).

PR draft: ver `.changes/PR_D1-C8_description.md` con resumen y comandos para crear la rama/PR.
