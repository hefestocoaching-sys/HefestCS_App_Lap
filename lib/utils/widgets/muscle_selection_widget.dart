import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

const List<String> allMuscles = [
  'Pecho',
  'Espalda',
  'Trapecios',
  'Deltoide Lateral',
  'Deltoide Frontal',
  'Deltoide Posterior',
  'Bíceps',
  'Tríceps',
  'Abdominales',
  'Cuádriceps',
  'Isquiotibiales',
  'Glúteos',
  'Pantorrillas',
];

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
    _primary = List.from(widget.primarySelection);
    _secondary = List.from(widget.secondarySelection);
    _tertiary = List.from(widget.tertiarySelection);
  }

  void _updateSelections(
    String muscle,
    bool isSelected,
    List<String> currentList,
  ) {
    setState(() {
      if (isSelected) {
        // Remove from other lists first to ensure exclusivity.
        if (currentList != _primary) {
          _primary.remove(muscle);
        }
        if (currentList != _secondary) {
          _secondary.remove(muscle);
        }
        if (currentList != _tertiary) {
          _tertiary.remove(muscle);
        }

        // Then, add to the current list if it's not already there.
        if (!currentList.contains(muscle)) {
          currentList.add(muscle);
        }
      } else {
        // If deselected, just remove it from its current list.
        currentList.remove(muscle);
      }
      widget.onUpdate(_primary, _secondary, _tertiary);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Músculos que no están seleccionados en NINGUNA lista.
    final unselectedMuscles = allMuscles.where((m) {
      return !_primary.contains(m) &&
          !_secondary.contains(m) &&
          !_tertiary.contains(m);
    }).toList();

    // Las opciones para cada lista son sus propios elementos seleccionados MÁS los no seleccionados.
    final primaryOptions = [..._primary, ...unselectedMuscles]..sort();
    final secondaryOptions = [..._secondary, ...unselectedMuscles]..sort();
    final tertiaryOptions = [..._tertiary, ...unselectedMuscles]..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MuscleChecklist(
          title: 'Músculos Primarios',
          allOptions: primaryOptions,
          selectedOptions: _primary,
          onChanged: (muscle, isSelected) =>
              _updateSelections(muscle, isSelected, _primary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Secundarios',
          allOptions: secondaryOptions,
          selectedOptions: _secondary,
          onChanged: (muscle, isSelected) =>
              _updateSelections(muscle, isSelected, _secondary),
        ),
        const SizedBox(height: 24),
        _MuscleChecklist(
          title: 'Músculos Terciarios',
          allOptions: tertiaryOptions,
          selectedOptions: _tertiary,
          onChanged: (muscle, isSelected) =>
              _updateSelections(muscle, isSelected, _tertiary),
        ),
      ],
    );
  }
}

class _MuscleChecklist extends StatelessWidget {
  final String title;
  final List<String> allOptions;
  final List<String> selectedOptions;
  final Function(String, bool) onChanged;

  const _MuscleChecklist({
    required this.title,
    required this.allOptions,
    required this.selectedOptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          children: allOptions.map((muscle) {
            final isSelected = selectedOptions.contains(muscle);
            return FilterChip(
              label: Text(muscle),
              selected: isSelected,
              onSelected: (selected) => onChanged(muscle, selected),
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
