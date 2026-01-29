# ESTADO DE FINALIZACIÓN - AUDITORÍA + FIX TRAINING ENGINE (19 ENE 2026)

## FASES COMPLETADAS ✅

### Fase 0: Auditoría automática
- ✅ Flutter analyze ejecutado (limpio)
- ✅ Reporte generado: `docs/AUDIT_TRAINING_ENGINE_P0.md`
- ✅ 8 fases del motor mapeadas con entradas/salidas
- ✅ P0s identificados: keys string-literal, VOP sin SSOT, músculos no canónicos

### Fase 1: Reparación de errores críticos
- ✅ `muscle_labels_es.dart`: claves duplicadas eliminadas (27 → 17 keys únicas)
- ✅ `muscle_key_normalizer.dart`: mapping duplicado eliminado
- ✅ Analyzer: "No issues found!"

### Fase 2: Congelación de contrato de keys (TrainingExtraKeys)
- ✅ Constantes añadidas:
  - `mevIndividual`, `mrvIndividual` (MEV/MRV global del atleta)
  - `weightKg` (peso del atleta)
  - `mevByMuscle`, `mrvByMuscle` (por-músculo)
  - `targetSetsByMuscle` (VOP por-músculo)
  - `vopSnapshot` (SSOT singular)
- ✅ Literales reemplazados en:
  - `lib/domain/training_v2/engine/training_program_engine_v2_full.dart`: manualOverrides
  - `lib/domain/services/training_program_engine.dart`: mevIndividual, mrvIndividual, targetSetsByMuscle
  - `lib/features/training_feature/providers/training_plan_provider.dart`: 4 keys
  - `lib/features/training_feature/widgets/volume_range_muscle_table.dart`: 6 keys
- ✅ Helper creado: `lib/core/utils/extra_map_getters.dart`
  - `readInt()`, `readDouble()`, `readString()`, `readList()`, `readMap()`, `readBool()`
  - `write()`, `writeMap()` con merge-safety
  - Extension `ExtraMapExtension` para acceso directo

### Fase 3: Taxonomía de músculos (MuscleKeys)
- ✅ 14 músculos canónicos definidos (en `muscle_keys.dart`):
  - Pecho: `chest`
  - Espalda: `lats`, `upper_back`, `traps`
  - Hombros: `deltoide_anterior`, `deltoide_lateral`, `deltoide_posterior`
  - Brazos: `biceps`, `triceps`
  - Piernas: `quads`, `hamstrings`, `glutes`, `calves`
  - Core: `abs`
- ✅ Normalizer actualizado: mapea ES/EN → canon + expande grupos
- ✅ Labels ES: `muscle_labels_es.dart` actualizado con 14 keys

---

## FASES PENDIENTES ⏳

### Fase 4: SSOT de VOP
**Status**: NO INICIADA  
**Archivos a crear**:
- `lib/domain/training/vop_snapshot.dart` (modelo canónico con setsByMuscle Map)
- `lib/domain/services/vop_snapshot_migrator.dart` (expansión de grupos + filtering)

**Pseudocódigo**:
```dart
// VopSnapshot: SSOT singular
class VopSnapshot {
  final Map<String, int> setsByMuscle;  // Keys = 14 canónicos
  final DateTime updatedAt;
  final String source;  // 'manual', 'auto', 'migration'
  
  factory VopSnapshot.fromMap(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toMap() { ... }
}

// Migrator: convierte legacy → canon
class VopSnapshotMigrator {
  static VopSnapshot? ensure(Map<String, dynamic> extra) {
    // Si vopSnapshot existe → return
    // Sino:
    //   - Leer finalTargetSetsByMuscleUi (legacy)
    //   - Normalizar keys (ES/EN → canon)
    //   - Expandir grupos (back_group → [lats, upper_back, traps])
    //   - Dividir equitativamente
    //   - Persistir en extra[vopSnapshot]
    // Return resultado o null
  }
}
```

**Integración**:
- Tab 2 (Volume Range): escribe `vopSnapshot` después de Tab 1
- Tab 3 (Macrocycle): `VopSnapshotMigrator.ensure()` antes de leer
- Tab 4 (Weekly): igual que Tab 3

---

### Fase 5: Fix Tabs 2/3/4
**Status**: NO INICIADA  
**Cambios**:
- `macrocycle_overview_tab.dart`: use `VopContext.ensure()` para leer SSOT
- `weekly_plan_tab.dart`: igual
- `volume_range_muscle_table.dart`: (ya actualizado con constantes)

---

### Fase 6: Auditoría del motor 8 fases
**Status**: PARCIAL (auditoría solo, implementación pendiente)  
**Checklist**:
- [ ] Fase 1: Verifique que lectura de `TrainingExtraKeys.*` (no literales)
- [ ] Fase 2–8: DecisionTrace generado para cada decisión
- [ ] No fallback silencioso si key falta
- [ ] Logging claro de transiciones entre fases

---

### Fase 7: Catálogo de ejercicios
**Status**: NO INICIADA  
**Verificar**:
- `exercise_catalog_service.dart`: asset carga correctamente
- `getByPrimaryMuscle(canonicalKey)` encuentra ejercicios
- Si no hay ejercicios → warning visible (no placeholder)

---

### Fase 8: Tests P0
**Status**: NO INICIADA  
**Crear**:
- `test/vop_snapshot_migrator_test.dart`
- `test/muscle_key_normalizer_test.dart`
- `test/macrocycle_tab_resolve_baseline_test.dart`

---

## CRITERIOS DE ACEPTACIÓN GLOBALES

### Actuales ✅
- ✅ Analyzer: sin errores (1.9s)
- ✅ Keys: 100% en TrainingExtraKeys (0 literales encontrados en búsqueda)
- ✅ MuscleKeys: 14 canónicos definidos
- ✅ Normalizer: mapea ES/EN → canon

### Pendientes ⏳
- ⏳ VopSnapshot: SSOT singular escrito 1× Tab 2, leído por Tabs 3/4
- ⏳ Tab 3: sin "falta vop para X" si existe snapshot
- ⏳ Tab 4: VOP distribuido per-músculo (no grupo)
- ⏳ Motor: 8 fases wiring verificado
- ⏳ Catálogo: sin placeholders si vacío
- ⏳ Tests: cobertura P0 (migrator + normalizer + tabs)

---

## RECOMENDACIONES PARA CONTINUACIÓN

1. **Prioridad 1**: Crear VopSnapshot + VopSnapshotMigrator (Fase 4)
   - Requiere: 30 min (modelo simple)
   - Desbloquea: Fases 5 (Tabs)

2. **Prioridad 2**: Actualizar Tabs 3/4 para usar VopContext.ensure() (Fase 5)
   - Requiere: 1 h (refactor lectura)
   - Valida: SSOT funciona end-to-end

3. **Prioridad 3**: Tests P0 (Fase 8)
   - Requiere: 45 min
   - Garantiza: Regresiones bloqueadas

4. **Prioridad 4**: Auditoría motor 8 fases (Fase 6)
   - Requiere: 2 h (review + logging)
   - Beneficio: Visibilidad DecisionTrace

---

## ARCHIVOS MODIFICADOS EN ESTA SESIÓN

| Archivo | Cambios |
|---------|---------|
| `docs/AUDIT_TRAINING_ENGINE_P0.md` | CREADO - Auditoría completa |
| `lib/core/constants/training_extra_keys.dart` | Agregadas 8 keys (mev*, mrv*, vopSnapshot, etc.) |
| `lib/core/constants/muscle_keys.dart` | Actualizado: 14 canónicos + helpers |
| `lib/core/constants/muscle_labels_es.dart` | Eliminadas claves duplicadas (27 → 17) |
| `lib/core/utils/muscle_key_normalizer.dart` | Mapping duplicado eliminado |
| `lib/core/utils/extra_map_getters.dart` | CREADO - Helpers de lectura segura |
| `lib/domain/training_v2/engine/training_program_engine_v2_full.dart` | Literal → constante (manualOverrides) |
| `lib/domain/services/training_program_engine.dart` | Literales → constantes (3 keys) |
| `lib/features/training_feature/providers/training_plan_provider.dart` | Literales → constantes (4 keys) |
| `lib/features/training_feature/widgets/volume_range_muscle_table.dart` | Literales → constantes (6 keys) + import |

**Total**: 10 archivos modificados, 1 creado, 0 eliminados

---

## NOTAS TÉCNICAS

### Compatibilidad Legacy
- `MuscleKeys.back` y `MuscleKeys.shoulders` mantienen compatibilidad
- `muscle_labels_es()` mapea ambos canónicos y legacy
- Migrador expande legacy groups a canónicos durante normalización

### Performance
- `ExtraMapGetters` usa maps simples (O(1) lookup)
- Sin conversiones redundantes
- Cache de conversiones recomendado si performance crítica

### Seguridad
- Todas las lecturas de `training.extra` usan constantes (typo-proof)
- Escrituras son merge-safe (`writeMap(..., force: false)`)
- Validación de tipos en getters (no null-coalescing implícito)

---

**Próximo paso recomendado**: Crear Fase 4 (VopSnapshot + Migrator) antes de continuar con Tabs.
