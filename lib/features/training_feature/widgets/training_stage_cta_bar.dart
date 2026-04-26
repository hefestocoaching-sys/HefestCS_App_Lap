import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Barra de CTA por etapa
///
/// Cada etapa del pipeline tiene un botón claro para continuar a la siguiente.
class TrainingStageCTABar extends StatelessWidget {
  final String stagelabel;
  final String ctaLabel;
  final VoidCallback onCTA;
  final bool isEnabled;
  final String? disabledReason;

  const TrainingStageCTABar({
    required this.stagelabel,
    required this.ctaLabel,
    required this.onCTA,
    this.isEnabled = true,
    this.disabledReason,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isEnabled && disabledReason != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              border: Border(
                left: BorderSide(color: Colors.orange.shade400, width: 4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade400,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    disabledReason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? onCTA : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: isEnabled ? kPrimaryColor : kTextColorSecondary,
              disabledBackgroundColor: kTextColorSecondary.withAlpha(100),
            ),
            child: Text(
              ctaLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
