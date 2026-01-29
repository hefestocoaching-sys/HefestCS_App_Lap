import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Widget de dropdown tipado para enums que mantiene la apariencia Glass
/// pero asegura que siempre se trabaje con valores de enum internamente.
///
/// Uso:
/// ```dart
/// EnumGlassDropdown<TrainingLevel>(
///   label: 'Nivel',
///   value: _selectedLevel,
///   values: TrainingLevel.values,
///   labelBuilder: (level) => level.label,
///   onChanged: (level) => setState(() => _selectedLevel = level),
/// )
/// ```
class EnumGlassDropdown<T extends Enum> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const EnumGlassDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: DropdownButtonFormField<T>(
            initialValue: values.contains(value) ? value : null,
            isExpanded: true,
            dropdownColor: kAppBarColor,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            style: const TextStyle(color: Colors.white),
            items: values
                .map(
                  (enumValue) => DropdownMenuItem<T>(
                    value: enumValue,
                    child: Text(labelBuilder(enumValue)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration()
                .applyDefaults(Theme.of(context).inputDecorationTheme)
                .copyWith(
                  labelText: label,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
          ),
        ),
      ],
    );
  }
}

/// Helper para convertir de String legacy a Enum con fallback
/// Útil durante migración gradual
class EnumHelper {
  /// Convierte un label humano a TrainingLevel
  static T? fromLabel<T extends Enum>(
    String? label,
    List<T> values,
    String Function(T) labelGetter,
  ) {
    if (label == null) return null;
    try {
      return values.firstWhere(
        (e) =>
            labelGetter(e).toLowerCase() == label.toLowerCase() ||
            labelGetter(e).contains(label) ||
            label.contains(labelGetter(e)),
      );
    } catch (_) {
      return null;
    }
  }
}
