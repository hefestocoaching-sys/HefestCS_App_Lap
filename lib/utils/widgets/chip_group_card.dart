import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Versión mejorada de MultiChipSection con header visual y contador
class ChipGroupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onUpdate;
  final Color? accentColor;

  const ChipGroupCard({
    super.key,
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedOptions,
    required this.onUpdate,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? kPrimaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kInputFillColor.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              // Badge con contador
              if (selectedOptions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedOptions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips mejorados
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                avatar: isSelected
                    ? Icon(Icons.check_circle, size: 16, color: color)
                    : null,
                onSelected: (selected) {
                  final newList = List<String>.from(selectedOptions);
                  if (selected) {
                    newList.add(option);
                  } else {
                    newList.remove(option);
                  }
                  onUpdate(newList);
                },
                backgroundColor: kInputFillColor,
                selectedColor: color.withAlpha(100),
                checkmarkColor: kTextColor,
                side: BorderSide(
                  color: isSelected
                      ? color.withAlpha(128)
                      : Colors.white.withAlpha(20),
                  width: 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? kTextColor : kTextColorSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
