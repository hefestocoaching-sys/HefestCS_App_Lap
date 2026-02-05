import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Mapeo de keys canónicas Motor V3 → Labels UI en español
class MuscleOption {
  final String key; // Key canónica para el motor (p.ej. 'lats', 'upper_back')
  final String label; // Label en español para UI

  const MuscleOption(this.key, this.label);
}

/// Lista completa de músculos con keys canónicas V3 (14 músculos SSOT)
const List<MuscleOption> allMuscles = [
  MuscleOption('chest', 'Pecho'),
  MuscleOption('lats', 'Dorsal ancho (Lats)'),
  MuscleOption('upper_back', 'Espalda alta / Escápulas (Upper back)'),
  MuscleOption('traps', 'Trapecios'),
  MuscleOption('deltoide_anterior', 'Deltoide Anterior'),
  MuscleOption('deltoide_lateral', 'Deltoide Lateral'),
  MuscleOption('deltoide_posterior', 'Deltoide Posterior'),
  MuscleOption('biceps', 'Bíceps'),
  MuscleOption('triceps', 'Tríceps'),
  MuscleOption('quads', 'Cuádriceps'),
  MuscleOption('hamstrings', 'Isquiotibiales'),
  MuscleOption('glutes', 'Glúteos'),
  MuscleOption('calves', 'Pantorrillas'),
  MuscleOption('abs', 'Abdominales'),
];

/// Helper: Expand legacy 'back' → ['lats', 'upper_back', 'traps']
/// Mantiene backward compatibility con datos viejos de entrevista.
List<String> _expandLegacyKeys(List<String> keys) {
  final expanded = <String>[];
  for (final k in keys) {
    if (k == 'back') {
      // COMPAT LEGACY: back → lats/upper_back/traps
      // Split científico por defecto:
      // - lats: 45% (volumen principal)
      // - upper_back: 35% (romboides, redondo menor)
      // - traps: 20% (estabilización)
      // Nota: UI no maneja % aún, solo expande a 3 keys.
      expanded.addAll(['lats', 'upper_back', 'traps']);
    } else {
      expanded.add(k);
    }
  }
  return expanded.toSet().toList(); // elimina duplicados
}

class MuscleSelectionGroup extends StatefulWidget {
  final List<String> primarySelection;
  final List<String> secondarySelection;
  final List<String> tertiarySelection;
  final Function(
    List<String> primary,
    List<String> secondary,
    List<String> tertiary,
  )
  onUpdate;

  const MuscleSelectionGroup({
    super.key,
    required this.primarySelection,
    required this.secondarySelection,
    required this.tertiarySelection,
    required this.onUpdate,
  });

  @override
  MuscleSelectionGroupState createState() => MuscleSelectionGroupState();
}

class MuscleSelectionGroupState extends State<MuscleSelectionGroup> {
  late List<String> _primary;
  late List<String> _secondary;
  late List<String> _tertiary;

  @override
  void initState() {
    super.initState();
    // Expandir legacy keys si existen (p.ej. 'back' -> ['lats', 'upper_back', 'traps'])
    _primary = _expandLegacyKeys(widget.primarySelection);
    _secondary = _expandLegacyKeys(widget.secondarySelection);
    _tertiary = _expandLegacyKeys(widget.tertiarySelection);
  }

  void _updateSelections(
    String muscleKey,
    bool isSelected,
    List<String> currentList,
  ) {
    setState(() {
      if (isSelected) {
        // Remove from other lists first to ensure exclusivity.
        if (currentList != _primary) {
          _primary.remove(muscleKey);
        }
        if (currentList != _secondary) {
          _secondary.remove(muscleKey);
        }
        if (currentList != _tertiary) {
          _tertiary.remove(muscleKey);
        }

        // Then, add to the current list if it's not already there.
        if (!currentList.contains(muscleKey)) {
          currentList.add(muscleKey);
        }
      } else {
        // If deselected, just remove it from its current list.
        currentList.remove(muscleKey);
      }
      widget.onUpdate(_primary, _secondary, _tertiary);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Músculos (keys) que no están seleccionados en NINGUNA lista.
    final unselectedMuscleKeys = allMuscles.map((m) => m.key).where((k) {
      return !_primary.contains(k) &&
          !_secondary.contains(k) &&
          !_tertiary.contains(k);
    }).toList();

    // Las opciones para cada lista son sus propios elementos seleccionados MÁS los no seleccionados.
    final primaryOptions = [..._primary, ...unselectedMuscleKeys];
    final secondaryOptions = [..._secondary, ...unselectedMuscleKeys];
    final tertiaryOptions = [..._tertiary, ...unselectedMuscleKeys];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MuscleChecklist(
          title: 'Músculos Primarios',
          allOptionKeys: primaryOptions,
          selectedKeys: _primary,
          onChanged: (muscleKey, isSelected) =>
              _updateSelections(muscleKey, isSelected, _primary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Secundarios',
          allOptionKeys: secondaryOptions,
          selectedKeys: _secondary,
          onChanged: (muscleKey, isSelected) =>
              _updateSelections(muscleKey, isSelected, _secondary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Terciarios',
          allOptionKeys: tertiaryOptions,
          selectedKeys: _tertiary,
          onChanged: (muscleKey, isSelected) =>
              _updateSelections(muscleKey, isSelected, _tertiary),
        ),
      ],
    );
  }
}

class _MuscleChecklist extends StatelessWidget {
  final String title;
  final List<String> allOptionKeys; // Keys canónicas
  final List<String> selectedKeys; // Keys seleccionadas
  final Function(String, bool) onChanged; // (key, isSelected)

  const _MuscleChecklist({
    required this.title,
    required this.allOptionKeys,
    required this.selectedKeys,
    required this.onChanged,
  });

  /// Helper: Obtiene el label en español para una key canónica
  String _getLabelForKey(String key) {
    final option = allMuscles.firstWhere(
      (m) => m.key == key,
      orElse: () => MuscleOption(key, key), // fallback: usa la key como label
    );
    return option.label;
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar alfabéticamente por label (español)
    final sortedKeys = List<String>.from(allOptionKeys)
      ..sort((a, b) => _getLabelForKey(a).compareTo(_getLabelForKey(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sortedKeys.map((key) {
            final isSelected = selectedKeys.contains(key);
            final label = _getLabelForKey(key);
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) => onChanged(key, selected),
              backgroundColor: kInputFillColor,
              selectedColor: kPrimaryColor.withAlpha(100),
              checkmarkColor: kTextColor,
              labelStyle: const TextStyle(color: kTextColor),
            );
          }).toList(),
        ),
      ],
    );
  }
}
