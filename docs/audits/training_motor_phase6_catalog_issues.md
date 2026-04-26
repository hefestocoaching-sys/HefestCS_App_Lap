# Training Motor Phase 6 - Catalog Issues (Críticos)

## Fuente auditada
- assets/data/exercises/exercise_catalog_gym.json

## Criterio
Se reportan solo inconsistencias que impactan selección por zona en la ruta real del Motor V3.

## Hallazgos críticos
### 1) Inconsistencia loadCategory vs allowedIntensityZones
- Conteo: 1 caso crítico.
- Caso detectado:
  - id: pullover_con_barra
  - nombre: Pullover con barra
  - loadCategory normalizada: heavy
  - allowedIntensityZones: { heavy: false, medium: true, light: true }

Impacto:
- El ejercicio queda vetado para heavy aunque su categoría de carga sea heavy.
- Puede reducir cobertura efectiva para algunos músculos/patrones en slots heavy.

### 2) Huecos de cobertura por músculo y zona
Músculos con al menos una zona sin cobertura en catálogo (según regla de allowsZone actual):
- abs: heavy=0, medium=0, light=7
- lats: heavy=0, medium=2, light=3
- traps: heavy=0, medium=2, light=6
- deltoide_posterior: heavy=0, medium=3, light=6
- deltoide_lateral: heavy=0, medium=5, light=6
- calves: heavy=0, medium=9, light=9
- biceps: heavy=0, medium=11, light=24
- upper_back: heavy=6, medium=11, light=0

Impacto:
- Si la distribución de intensidad exige una zona sin cobertura para un músculo dado, ahora fallará explícitamente (correcto por contrato estricto) en vez de degradar con selección inválida.

### 3) Equivalence groups de ejercicios históricamente fallidos
Ejercicios que detonaban ZONE_VALIDATION_FAIL en auditoría previa y cobertura observada en su equivalenceGroup:
- press_banca_inclinado_con_mancuernas
  - eq: horizontal_press_dumbbell (size=3)
  - cobertura eq: heavy=0, medium=3, light=0
- curl_de_biceps_en_banco_scott_con_barra_z_cerrado
  - eq: biceps_scott (size=4)
  - cobertura eq: heavy=0, medium=4, light=4
- rear_del_fly_en_polea_media_a_single_arm
  - eq: rear_delt_other (size=1)
  - cobertura eq: heavy=0, medium=0, light=1

Impacto:
- El fallback por equivalenceGroup funciona solo si existe alternativa compatible de zona; en heavy para estos grupos no existe cobertura.

## Recomendaciones de datos (no de código)
1. Corregir metadatos inconsistentes `loadCategory` vs `allowedIntensityZones`.
2. Completar cobertura por zona en músculos con huecos críticos (especialmente heavy en lats/biceps/deltoides posteriores cuando se requiera).
3. Revisar equivalenceGroups de baja cardinalidad (size=1) para evitar callejones sin salida.

## Estado
No se modificó el catálogo en esta fase; solo se documentaron inconsistencias críticas para priorización de data fixes.
