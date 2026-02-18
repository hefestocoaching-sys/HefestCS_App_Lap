# HCS App LAP

Sistema de entrenamiento científico con motor de adaptación bidireccional (8 fases).

## 🎯 Estado del Proyecto

- ✅ **Motor de Entrenamiento V1**: 100% funcional (Phases 1-8)
- 🔥 **Motor V3 Enhanced - FASE 1**: ✅ Completo (Modelos + Validadores + Servicios)
- ✅ **Contrato de Bitácora**: v1.0.0 congelado
- ✅ **Tests**: 222/222 pasando
- ✅ **Documentación**: Completa (incluyendo Motor V3 Enhanced)
- ⏳ **Motor V3 Enhanced - FASE 2**: En progreso (Repositories + Providers + UI)
- ⏸️ **App Móvil**: Pendiente de implementación

## � MOTOR V3 ENHANCED - NUEVO!

**✅ FASE 1 Completada** - Modelos + Validadores + Servicios  
Implementación de progresión individualizada por músculo y prioridad (P/S/T), ciclos científicos, historial auditable, validadores formales.

### 📖 Documentación Motor V3 Enhanced

**Si acabas de recibir el handoff:**  
→ **[MOTOR_V3_HANDOFF_SUMMARY.md](docs/MOTOR_V3_HANDOFF_SUMMARY.md)** ← Empieza aquí

**Para desarrollo:**  
→ **[Índice Completo](docs/MOTOR_V3_DOCUMENTATION_INDEX.md)** ⭐  
→ **[Quick Reference](docs/MOTOR_V3_QUICK_REFERENCE.md)** ⚡  
→ **[Continuation Guide (Phase 2)](docs/MOTOR_V3_CONTINUATION_GUIDE_PHASE2.md)**  
→ **[Phase 2 Checklist](docs/MOTOR_V3_PHASE2_QUICK_CHECKLIST.md)**

## 📚 Documentación Principal

### Para Desarrolladores
- **[Índice de Documentación](docs/TRAINING_LOG_INDEX.md)** ← Training Log (Legacy)
- **[Contrato de Bitácora (Resumen)](docs/TRAINING_LOG_CONTRACT_FROZEN.md)**
- **[Ejemplos de Uso](docs/training_log_usage_examples.dart)**

### Para Arquitectos
- **[Auditoría Técnica Completa](docs/TRAINING_LOG_CONTRACT_AUDIT.md)**
- **[Auditoría del Motor](docs/AUDITORIA_FORENSE.md)**

## 🚀 Quick Start

```bash
# Instalar dependencias
flutter pub get

# Ejecutar todos los tests
flutter test

# Ejecutar app (desktop)
flutter run -d windows
```

## 🔐 Contrato de Bitácora v1.0.0

El contrato `TrainingSessionLogV2` define la interfaz estable entre:
- 📱 App móvil (registro de sesiones)
- 💻 App desktop (motor de entrenamiento)
- 🧠 Phase 8 (adaptación bidireccional)

**Campos**: 15 (14 requeridos + 1 opcional)  
**Estado**: 🔒 Congelado para producción  
**Breaking changes**: Requieren v2.0.0

Ver: [TRAINING_LOG_CONTRACT_FROZEN.md](docs/TRAINING_LOG_CONTRACT_FROZEN.md)

## 🧪 Testing

```bash
# Tests completos
flutter test

# Tests específicos del contrato
flutter test test/domain/entities/training_session_log_test.dart

# Tests de Phase 8
flutter test test/phase_8_adaptation_wiring_test.dart

# Auditoría longitudinal
flutter test test/longitudinal/
```

## 🏗️ Arquitectura

```
Mobile App → TrainingSessionLogV2 → WeeklyTrainingFeedbackSummary → Phase 8
```

**Pipeline de datos**:
1. Usuario registra sesión en móvil
2. Se guarda como `TrainingSessionLogV2`
3. Desktop agrega logs semanales
4. `TrainingFeedbackAggregatorService` genera resumen
5. `Phase8AdaptationService` adapta plan
6. Usuario recibe plan personalizado

## 📦 Estructura del Proyecto

```
lib/
  domain/
    entities/
      training_session_log.dart       # Contrato v1.0.0 ⭐
      weekly_training_feedback_summary.dart
    services/
      training_feedback_aggregator_service.dart
      phase_8_adaptation_service.dart # Motor de adaptación
      training_program_engine.dart    # Pipeline completo (8 fases)

test/
  domain/entities/training_session_log_test.dart  # 23 tests ✅
  phase_8_adaptation_wiring_test.dart             # 6 tests ✅
  longitudinal/                                   # Auditoría ✅

docs/
  TRAINING_LOG_INDEX.md              # 📚 Índice maestro
  TRAINING_LOG_CONTRACT_FROZEN.md    # Resumen ejecutivo
  TRAINING_LOG_CONTRACT_AUDIT.md     # Auditoría técnica
  training_log_usage_examples.dart   # 10 ejemplos de código
```

## ⚙️ Configuración

Este proyecto requiere:
- Flutter SDK ≥ 3.9.2
- Dart ≥ 3.9.2

## 📄 Licencia

Proyecto interno HCS.

---

## Getting Started (Flutter Default)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
