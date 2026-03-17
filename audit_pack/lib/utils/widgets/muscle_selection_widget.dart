import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Mapeo de keys canónicas Motor V3 → Labels UI en español
class MuscleOption {
  final String key; // Key persistida por UI (p.ej. 'back', 'chest')
  final String label; // Label en español para UI

  const MuscleOption(this.key, this.label);
}

/// Lista completa de músculos visibles en UI de entrevista.
/// Nota: 'Espalda' se maneja como key unificada 'back'.
const List<MuscleOption> allMuscles = [
  MuscleOption('chest', 'Pecho'),
  MuscleOption('back', 'Espalda'),
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
    'Espalda': 'back',
    'Dorsal ancho': 'back',
    'Dorsal ancho (Lats)': 'back',
    'Espalda alta': 'back',
    'Espalda alta / Escápulas': 'back',
    'Espalda alta / Escápulas (Upper back)': 'back',
    'Upper back': 'back',
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

/// Helper: colapsa legacy ('lats'/'upper_back') y 'back' a la key UI 'back'.
/// Mantiene backward compatibility con datos viejos de entrevista.
List<String> _expandLegacyKeys(List<String> keys) {
  final expanded = <String>[];
  for (final k in keys) {
    final normalized = _normalizeToCanonicalKey(k);
    if (normalized == 'back' ||
        normalized == 'lats' ||
        normalized == 'upper_back') {
      // UI unificada: cualquier variante de espalda se representa como 'back'
      expanded.add('back');
    } else {
      expanded.add(normalized);
    }
  }
  // Filtrar contra keys visibles en UI
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
  static const int _maxPrimary = 4;
  static const int _maxSecondary = 3;

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
    _applyTierRules();
  }

  @override
  void didUpdateWidget(MuscleSelectionGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Resincronizar estado si cambiaron las props (al cargar cliente, guardar, etc.)
    // Esto previene "chips fantasma" duplicados
    if (widget.selectedPrimary != oldWidget.selectedPrimary ||
        widget.selectedSecondary != oldWidget.selectedSecondary ||
        widget.selectedTertiary != oldWidget.selectedTertiary) {
      final newPrimary = _expandLegacyKeys(
        widget.selectedPrimary.toList(),
      ).toSet();
      final newSecondary = _expandLegacyKeys(
        widget.selectedSecondary.toList(),
      ).toSet();
      final newTertiary = _expandLegacyKeys(
        widget.selectedTertiary.toList(),
      ).toSet();

      // Solo setState si realmente cambió
      if (_setsDiffer(_primary, newPrimary) ||
          _setsDiffer(_secondary, newSecondary) ||
          _setsDiffer(_tertiary, newTertiary)) {
        setState(() {
          _primary = newPrimary;
          _secondary = newSecondary;
          _tertiary = newTertiary;
          _applyTierRules();
        });
      }
    }
  }

  List<String> _ordered(List<String> keys) {
    final order = allMuscles.map((m) => m.key).toList();
    return order.where(keys.contains).toList();
  }

  /// Reglas globales:
  /// 1) Exclusión estricta entre tiers (Primary > Secondary > Tertiary)
  /// 2) Máximo 4 primarios y 3 secundarios
  /// 3) Overflow de primary/secondary se mueve a tertiary
  void _applyTierRules() {
    // Exclusión estricta
    _secondary.removeAll(_primary);
    _tertiary.removeAll(_primary);
    _tertiary.removeAll(_secondary);

    // Límite primarios (overflow -> tertiary)
    if (_primary.length > _maxPrimary) {
      final orderedPrimary = _ordered(_primary.toList());
      final keep = orderedPrimary.take(_maxPrimary).toSet();
      final overflow = orderedPrimary.skip(_maxPrimary).toSet();
      _primary = keep;
      _tertiary.addAll(overflow);
    }

    // Límite secundarios (overflow -> tertiary)
    if (_secondary.length > _maxSecondary) {
      final orderedSecondary = _ordered(_secondary.toList());
      final keep = orderedSecondary.take(_maxSecondary).toSet();
      final overflow = orderedSecondary.skip(_maxSecondary).toSet();
      _secondary = keep;
      _tertiary.addAll(overflow);
    }

    // Reaplicar exclusión por si hubo movimientos
    _secondary.removeAll(_primary);
    _tertiary.removeAll(_primary);
    _tertiary.removeAll(_secondary);
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
    final willAddPrimary =
        isSelected &&
        currentSet == _primary &&
        !_primary.contains(muscleKey) &&
        _primary.length >= _maxPrimary;

    final willAddSecondary =
        isSelected &&
        currentSet == _secondary &&
        !_secondary.contains(muscleKey) &&
        _secondary.length >= _maxSecondary;

    if (willAddPrimary || willAddSecondary) {
      return;
    }

    setState(() {
      if (isSelected) {
        // Remove from all OTHER tiers first (strict mutual exclusion)
        if (currentSet != _primary) _primary.remove(muscleKey);
        if (currentSet != _secondary) _secondary.remove(muscleKey);
        if (currentSet != _tertiary) _tertiary.remove(muscleKey);
        currentSet.add(muscleKey);
      } else {
        currentSet.remove(muscleKey);
      }

      _applyTierRules();
    });
    // Notify AFTER setState to avoid calling callbacks inside build cycle
    widget.onChanged('primary', Set<String>.from(_primary));
    widget.onChanged('secondary', Set<String>.from(_secondary));
    widget.onChanged('tertiary', Set<String>.from(_tertiary));
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = allMuscles.map((m) => m.key).toSet();
    final primaryOptions = allKeys.difference(_secondary).difference(_tertiary);
    final secondaryOptions = allKeys.difference(_primary).difference(_tertiary);
    final tertiaryOptions = allKeys.difference(_primary).difference(_secondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MuscleChecklist(
          title: 'Músculos Primarios (máx. 4)',
          allOptionKeys: primaryOptions.toList(),
          selectedKeys: _primary.toList(),
          onChanged: (muscleKey, isSelected) =>
              _updateSelections(muscleKey, isSelected, _primary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Secundarios (máx. 3)',
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
