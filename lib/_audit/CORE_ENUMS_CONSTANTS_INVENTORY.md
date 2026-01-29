# Inventario de enums/constantes core

| Símbolo | Tipo (enum/const) | Archivo | Uso actual | Observación |
| --- | --- | --- | --- | --- |
| MuscleKeys | const (clase estática) | core/constants/muscle_keys.dart | usado | Importado en features/training_feature/providers/training_plan_provider.dart y core/utils/muscle_key_normalizer.dart |
| MuscleLabelsEs | const (mapa etiquetas) | core/constants/muscle_labels_es.dart | usado | Importado en múltiples widgets de training_feature (p.ej. volume_range_muscle_table.dart) |
| TrainingExtraKeys | const (claves extra) | core/constants/training_extra_keys.dart | usado | Importado en domain/entities/training_profile.dart y widgets de training_feature |
| NutritionExtraKeys | const (claves extra) | core/constants/nutrition_extra_keys.dart | usado | Importado en providers de nutrition_feature y meal_plan_feature |
| TrainingInterviewKeys | const (claves entrevista) | core/constants/training_interview_keys.dart | usado | Importado en training_profile.dart y training_context_normalizer.dart |
| DbConstants | const (clase estática) | core/constants/db_constants.dart | no usado | `rg "DbConstants" lib/` solo encuentra la declaración; sin imports |
| NutrientIds | const (clase estática) | core/constants/nutrient_constants.dart | no usado | `rg "NutrientIds" lib/` solo encuentra la declaración; sin imports |
| MuscleTaxonomy | const (clase estática) | core/constants/muscle_taxonomy.dart | no usado | `rg "muscle_taxonomy" lib/ --include-ignored` no devuelve referencias |
| AvailableEquipmentType | enum | core/enums/available_equipment_type.dart | no usado | `rg "AvailableEquipmentType" lib/ --include-ignored` solo coincide en el archivo propio |
| IntensificationPolicy | enum | core/enums/intensification_policy.dart | no usado | `rg "IntensificationPolicy" lib/ --include-ignored` solo coincide en el archivo propio |
