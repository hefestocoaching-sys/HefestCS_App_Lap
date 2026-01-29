import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Agrupa campos relacionados visualmente con header y borde de acento
class FieldGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> fields;
  final Color? accentColor;
  final bool showBorder;

  const FieldGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.fields,
    this.accentColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? kPrimaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(color: color.withAlpha(50), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compacto
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fields con spacing
          ...fields.map((field) {
            final isLast = fields.last == field;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: field,
            );
          }),
        ],
      ),
    );
  }
}
