# E2E Testing Guide - Exercise Preferences Integration

## Flujo E2E: Cliente Cambia Preferencia → Coach Regenera Plan

### Fase 1: Setup (Pre-requisitos)

1. **Apps compiladas sin errores**
   ```bash
   # Coach App
   cd C:\Users\pedro\StudioProjects\hcs_app_lap
   flutter analyze
   
   # Client App
   cd C:\Users\pedro\StudioProjects\HefestoCS
   flutter analyze
   ```

2. **Firebase Firestore Rules Aplicadas**
   ```bash
   cd C:\Users\pedro\StudioProjects\hcs_app_lap
   firebase deploy --only firestore:rules
   ```

3. **Ambas apps conectadas al mismo Firebase project: `hcseco-55882`**

---

## Test Scenario 1: Cliente Guarda Preferencias

### Paso a Paso

1. **Abre Cliente App (HefestoCS_App)**
   - Login con cliente test: `cliente@test.com` / contraseña
   - Navega a Training → Preferencias

2. **Selecciona Preferencias**
   - Pectoral: Frecuente
   - Dorsal: Preferido
   - Cuádriceps: Evitar
   - Otros: Neutral (por defecto)
   - Botón: Guardar Preferencias

3. **Verifica Firebase Console**
   - URL: https://console.firebase.google.com/
   - Proyecto: hcseco-55882
   - Firestore: /clients/{clientId}/profile/training
   - Campo `extra.exercisePreferencesByMuscle` debe existir con:
     ```json
     {
       "pectorals": {
         "frequent": [],
         "preferred": [],
         "avoid": []
       },
       "lats": {
         "frequent": [],
         "preferred": [],
         "avoid": []
       },
       ...
     }
     ```

4. **Client App muestra confirmación**
   - "✓ Preferencias guardadas" (toast/snackbar)
   - Timestamp de guardado

### Validación ✅
```
[ ] Datos guardados en Firebase
[ ] Pantalla muestra confirmación
[ ] Timestamp es reciente
```

---

## Test Scenario 2: Coach App Detecta Cambio (Real-Time)

### Paso a Paso

1. **Abre Coach App (hcs_app_lap)**
   - Login con coach: `coach@test.com`
   - Navega a Training → Selecciona cliente

2. **Verifica que Workspace se Recomputa**
   - Monitor los logs de consola:
     ```
     [Flutter] ✅ [Preferencias Actualizado] Cliente: {clientId} | Músculos: pectorals, lats, quads
     ```

3. **Verifica que el Plan se Regenera**
   - El plan debe actualizar con ejercicios basados en preferencias
   - Log esperado:
     ```
     [Flutter] [VOP][Provider] VOP cargado: pectorals, lats, ...
     ```

4. **Revisa Firebase en Tiempo Real**
   - Abre Firestore console
   - Vé el cambio en `/clients/{clientId}/profile/training/extra/exercisePreferencesByMuscle`

### Validación ✅
```
[ ] Coach app recibe cambio en tiempo real (<2s)
[ ] Logs muestran ✅ [Preferencias Actualizado]
[ ] Workspace recomputa
[ ] Plan se regenera con ejercicios personalizados
```

---

## Test Scenario 3: E2E Completo (Manual)

### Tabla de Verificación

| Step | Client App | Coach App | Firebase | Status |
|------|-----------|-----------|----------|--------|
| 1. Login cliente | ✅ Conectado | - | ✅ Auth OK | [ ] |
| 2. Abre preferencias | ✅ Pantalla visible | - | - | [ ] |
| 3. Selecciona opciones | ✅ Radio buttons funcional | - | - | [ ] |
| 4. Guarda | ✅ Guardar clickeable | - | - | [ ] |
| 5. Confirmación | ✅ Toast mostrado | - | ✅ Datos en DB | [ ] |
| 6. Coach login | - | ✅ Conectado | ✅ Auth OK | [ ] |
| 7. Abre cliente | - | ✅ Workspace visible | - | [ ] |
| 8. Detecta cambio | - | ✅ Listener activo | ✅ Stream emite | [ ] |
| 9. Plan regenera | - | ✅ Ejercicios personalizados | ✅ Extra actualizado | [ ] |

---

## Test Scenario 4: Listener Persiste

### Paso a Paso

1. **Coach app abierta en Training Dashboard**

2. **Cliente cambia preferencias 3 veces**
   - Cada cambio debe trigger recompute

3. **Verifica logs 3 veces**
   ```
   [Flutter] ✅ [Preferencias Actualizado] Cliente: {clientId} | Músculos: X
   [Flutter] ✅ [Preferencias Actualizado] Cliente: {clientId} | Músculos: Y
   [Flutter] ✅ [Preferencias Actualizado] Cliente: {clientId} | Músculos: Z
   ```

### Validación ✅
```
[ ] Todos los cambios se detectan en tiempo real
[ ] No hay memory leaks (logs muestran gc normal)
[ ] Plan se regenera cada vez
```

---

## Debugging & Troubleshooting

### Problema: Cliente app no ve botón Preferencias

**Solución:**
```bash
# Verifica que main.dart tiene ExercisePreferencesProvider
grep -n "ExercisePreferencesProvider" lib/main.dart

# Verifica que training_screen.dart tiene el botón
grep -n "Preferencias" lib/screens/training_screen.dart
```

### Problema: Preferencias no se guardan en Firebase

**Solución:**
```bash
# Verifica Firestore rules
firebase firestore:inspect-rules

# Verifica que el usuario tiene permisos
# En Firebase Console → Firestore → Rules Tab
# Debe permitir: /clients/{clientId}/profile/training write if isOwner(clientId)
```

### Problema: Coach app no detecta cambios

**Solución:**
```bash
# Verifica que ClientPreferencesMonitor está importado
grep -n "clientPreferencesMonitorProvider" lib/features/training_feature/providers/*.dart

# Verifica que effect provider está siendo watched
grep -n "clientPreferencesEffectProvider" lib/features/training_feature/providers/training_workspace_provider.dart

# Revisa logs de Flutter
flutter logs
# Busca: "[Preferencias Actualizado]"
```

### Problema: Memory leaks o recomputes infinitos

**Solución:**
```dart
// En client_preferences_effect_provider.dart, 
// verifica que la función isActive no crea referencias circulares

// El provider debe ser:
// final clientPreferencesEffectProvider = FutureProvider<...>((ref) async {
//   ref.watch(clientsProvider)          // ✅ Seguro
//   ref.watch(clientPreferencesStreamProvider(id))  // ✅ Con parámetro
//   // NO hagas: ref.watch(trainingWorkspaceProvider)  // ❌ Circular
// })
```

---

## Automatización (Opcional - Fase 2)

Para testing automatizado, crear:

```dart
// test/integration/exercise_preferences_e2e_test.dart

void main() {
  group('Exercise Preferences E2E', () {
    
    testWidgets('Client saves preferences → Coach detects change', (tester) async {
      // 1. Setup: Login cliente
      // 2. Navigate to preferences
      // 3. Select options
      // 4. Save
      // 5. Verify toast
      // 6. Wait for Firebase write
      // 7. Switch to coach app
      // 8. Verify workspace recomputes
      // 9. Verify plan regenerates
    });
  });
}
```

---

## Sign-Off Checklist

- [ ] Firestore rules deployed
- [ ] Client app manual test passed
- [ ] Coach app manual test passed
- [ ] E2E flow verified (client → firebase → coach)
- [ ] No compilation errors
- [ ] No Firebase permission errors
- [ ] Both apps ready for production testing

---

**Ready for Production Testing** ✅
