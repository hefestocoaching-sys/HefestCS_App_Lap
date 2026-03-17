# Código muerto (inventario)

| Archivo | Ubicación | Tipo | Evidencia de no uso |
| --- | --- | --- | --- |
| training_engine_v2.dart | lib/domain/services/v2/ | motor | No importado en ningún archivo (`rg "training_engine_v2.dart"` en lib no arroja resultados) |
| training_adaptation_service.dart | lib/domain/services/ | service | No importado en ningún archivo (`rg "training_adaptation_service.dart"` en lib no arroja resultados) |
| volume_individualization_service.dart | lib/domain/training/services/ | service | No importado en ningún archivo; existe versión activa en lib/domain/services/volume_individualization_service.dart que sí se importa |
