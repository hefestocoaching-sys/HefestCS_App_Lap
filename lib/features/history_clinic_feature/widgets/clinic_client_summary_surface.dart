import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ClinicClientSummarySurface extends StatelessWidget {
  final Widget child;
  final List<Widget> tabs;
  final Widget? leading;
  final String clientName;
  final String clientObjective;

  const ClinicClientSummarySurface({
    super.key,
    required this.child,
    required this.tabs,
    required this.clientName,
    required this.clientObjective,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER CLIENTE (foto + nombre + objetivo)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (leading != null) leading!,
                if (leading != null) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clientObjective,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kTextColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TABS DENTRO DEL SUMMARY (CLAVE)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(children: tabs),
          ),

          // CONTENIDO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
