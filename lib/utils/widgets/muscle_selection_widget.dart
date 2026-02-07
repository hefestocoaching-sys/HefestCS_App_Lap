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

/// Helper: Normalizar keys entrada → canon  ónicos
/// Si entrada es label, mapearlo a key. Si es ya key, devolver.
String _normalizeToCanonicalKey(String raw) {
  const labelToKeyMap = {
    'Pecho': 'chest',
    'Dorsal ancho': 'lats',
    'Dorsal ancho (Lats)': 'lats',
    'Espalda alta': 'upper_back',
    'Espalda alta / Escápulas': 'upper_back',
    'Espalda alta / Escápulas (Upper back)': 'upper_back',
    'Upper back': 'upper_back',
    'Trapecios': 'traps',
    'Deltoide Anterior': 'deltoide_anterior',
    'Deltoide anterior': 'deltoide_anterior',
    'Deltoide Lateral': 'deltoide_lateral',
    'Deltoide lateral': 'deltoide_lateral',
    'Deltoide Posterior': 'deltoide_posterior',
    'Deltoide posterior': 'deltoide_posterior',
    'Bíceps': 'biceps',
    'Tríceps': 'triceps',
    'Cuádriceps': 'quads',
    'Isquiotibiales': 'hamstrings',
    'Glúteos': 'glutes',
    'Pantorrillas': 'calves',
    'Abdominales': 'abs',
  };

  final trimmed = raw.trim();
  return labelToKeyMap[trimmed] ?? trimmed;
}

/// Helper: Expand legacy 'back' → ['lats', 'upper_back', 'traps']
/// Mantiene backward compatibility con datos viejos de entrevista.
List<String> _expandLegacyKeys(List<String> keys) {
  final expanded = <String>[];
  for (final k in keys) {
    final normalized = _normalizeToCanonicalKey(k);
    if (normalized == 'back') {
      // COMPAT LEGACY: back → lats/upper_back/traps
      expanded.addAll(['lats', 'upper_back', 'traps']);
    } else {
      expanded.add(normalized);
    }
  }
  // Filtrar contra keys canónicas SOLO (14 músculos)
  final canonicalKeys = allMuscles.map((m) => m.key).toSet();
  return expanded
      .where((k) => canonicalKeys.contains(k))
      .toSet()
      .toList(); // elimina duplicados
}

class MuscleSelectionGroup extends StatefulWidget {
  final Set<String> selectedPrimary;
  final Set<String> selectedSecondary;
  final Set<String> selectedTertiary;
  final void Function(String tier, Set<String> newSet) onChanged;

  const MuscleSelectionGroup({
    super.key,
    required this.selectedPrimary,
    required this.selectedSecondary,
    required this.selectedTertiary,
    required this.onChanged,
  });

  @override
  MuscleSelectionGroupState createState() => MuscleSelectionGroupState();
}

class MuscleSelectionGroupState extends State<MuscleSelectionGroup> {
  late Set<String> _primary;
  late Set<String> _secondary;
  late Set<String> _tertiary;

  @override
  void initState() {
    super.initState();
    // Expandir legacy keys si existen (p.ej. 'back' -> ['lats', 'upper_back', 'traps'])
    _primary = _expandLegacyKeys(widget.selectedPrimary.toList()).toSet();
    _secondary = _expandLegacyKeys(widget.selectedSecondary.toList()).toSet();
    _tertiary = _expandLegacyKeys(widget.selectedTertiary.toList()).toSet();
  }

  @override
  void didUpdateWidget(MuscleSelectionGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Resincronizar estado si cambiaron las props (al cargar cliente, guardar, etc.)
    // Esto previene "chips fantasma" duplicados
    if (widget.selectedPrimary != oldWidget.selectedPrimary ||
      widget.selectedSecondary != oldWidget.selectedSecondary ||
      widget.selectedTertiary != oldWidget.selectedTertiary) {
      final newPrimary =
        _expandLegacyKeys(widget.selectedPrimary.toList()).toSet();
      final newSecondary =
        _expandLegacyKeys(widget.selectedSecondary.toList()).toSet();
      final newTertiary =
        _expandLegacyKeys(widget.selectedTertiary.toList()).toSet();

      // Solo setState si realmente cambió
      if (_setsDiffer(_primary, newPrimary) ||
          _setsDiffer(_secondary, newSecondary) ||
          _setsDiffer(_tertiary, newTertiary)) {
        setState(() {
          _primary = newPrimary;
          _secondary = newSecondary;
          _tertiary = newTertiary;
        });
      }
    }
  }

  bool _setsDiffer(Set<String> a, Set<String> b) {
    if (a.length != b.length) return true;
    for (final entry in a) {
      if (!b.contains(entry)) return true;
    }
    return false;
  }

  void _updateSelections(
    String muscleKey,
    bool isSelected,
    Set<String> currentSet,
  ) {
    setState(() {
      if (isSelected) {
        if (!currentSet.contains(muscleKey) && currentSet.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Máximo 3 músculos por categoría.'),
            ),
          );
          return;
        }
        if (currentSet != _primary) {
          _primary.remove(muscleKey);
        }
        if (currentSet != _secondary) {
          _secondary.remove(muscleKey);
        }
        if (currentSet != _tertiary) {
          _tertiary.remove(muscleKey);
        }
        currentSet.add(muscleKey);
      } else {
        currentSet.remove(muscleKey);
      }
      widget.onChanged('primary', _primary);
      widget.onChanged('secondary', _secondary);
      widget.onChanged('tertiary', _tertiary);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = allMuscles.map((m) => m.key).toSet();
    final primaryOptions = allKeys;
    final secondaryOptions = allKeys.difference(_primary);
    final tertiaryOptions = allKeys.difference(_primary).difference(_secondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MuscleChecklist(
          title: 'Músculos Primarios',
          allOptionKeys: primaryOptions.toList(),
          selectedKeys: _primary.toList(),
          onChanged: (muscleKey, isSelected) =>
              _updateSelections(muscleKey, isSelected, _primary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Secundarios',
          allOptionKeys: secondaryOptions.toList(),
          selectedKeys: _secondary.toList(),
          onChanged: (muscleKey, isSelected) =>
              _updateSelections(muscleKey, isSelected, _secondary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Terciarios',
          allOptionKeys: tertiaryOptions.toList(),
          selectedKeys: _tertiary.toList(),
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
