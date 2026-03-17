import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Un widget profesional para mostrar información resumida de un bloque de entrenamiento.
///
/// Muestra el nombre del bloque (ej: "AA1", "HF1"), su descripción y duración
/// en una tarjeta con el estilo "glass" característico de la aplicación.
class BlockLabel extends StatelessWidget {
  /// El nombre del bloque de entrenamiento.
  final String blockName;

  /// La duración del bloque en número de semanas.
  final int weeks;

  /// Una breve descripción del objetivo principal del bloque.
  final String description;

  const BlockLabel({
    super.key,
    required this.blockName,
    required this.weeks,
    required this.description,
  });

  /// Construye la decoración de "glassmorphism" estándar de la app.
  BoxDecoration _buildGlassDecoration() {
    return BoxDecoration(
      color: kAppBarColor.withAlpha(110),
      borderRadius: BorderRadius.circular(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String weeksLabel = weeks == 1 ? 'SEMANA' : 'SEMANAS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: _buildGlassDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título grande del bloque
                Text(
                  blockName,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Descripción del bloque
                Text(
                  description,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Indicador de duración
          Text(
            '$weeks $weeksLabel',
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
