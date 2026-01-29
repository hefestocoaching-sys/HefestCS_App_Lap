import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ClinicSectionSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const ClinicSectionSurface({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER BAND (igual al mockup)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: kCardColor.withValues(alpha: 0.38),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: kPrimaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}
