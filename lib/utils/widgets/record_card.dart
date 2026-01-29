import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Card de registro unificado para las listas de registros
class RecordCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const RecordCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withAlpha((255 * 0.12).round())
              : kCardColor.withAlpha((255 * 0.3).round()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Card para "Nuevo registro"
class NewRecordCard extends StatelessWidget {
  final VoidCallback onTap;

  const NewRecordCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPrimaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimaryColor.withAlpha(80), width: 1.5),
        ),
        child: Row(
          children: const [
            Icon(Icons.add, color: kPrimaryColor, size: 20),
            SizedBox(width: 12),
            Text(
              'Nuevo registro',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
