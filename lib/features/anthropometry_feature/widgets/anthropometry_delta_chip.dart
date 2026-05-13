import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

enum AnthropometryDeltaChipMode {
  previousOnly,
  deltaOnly,
  full,
}

class AnthropometryDeltaChip extends StatelessWidget {
  final double? currentValue;
  final double? previousValue;
  final String unit;
  final String metricKey;
  final int decimals;
  final AnthropometryDeltaChipMode mode;

  const AnthropometryDeltaChip({
    super.key,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
    required this.metricKey,
    this.decimals = 1,
    this.mode = AnthropometryDeltaChipMode.full,
  });

  @override
  Widget build(BuildContext context) {
    if (previousValue == null) {
      return const Text(
        '—',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kTextColorSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (mode == AnthropometryDeltaChipMode.previousOnly) {
      return Text(
        '${previousValue!.toStringAsFixed(decimals)} $unit',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kTextColorSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (currentValue == null) {
      return const Text(
        '—',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kTextColorSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final diff = currentValue! - previousValue!;
    final color = _colorFor(metricKey, diff);
    final sign = diff > 0 ? '+' : '';
    final arrow = diff > 0
        ? '↑'
        : diff < 0
            ? '↓'
            : '→';

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$sign${diff.toStringAsFixed(decimals)} $unit $arrow',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (mode == AnthropometryDeltaChipMode.deltaOnly) {
      return Center(child: chip);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Anterior: ${previousValue!.toStringAsFixed(decimals)} $unit',
          style: const TextStyle(
            color: kTextColorSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        chip,
      ],
    );
  }

  Color _colorFor(String metricKey, double diff) {
    if (diff.abs() < 0.0001) return kTextColorSecondary;

    final key = metricKey.toLowerCase();

    final isFatRelated = key.contains('waist') ||
        key.contains('cintura') ||
        key.contains('abdomen') ||
        key.contains('fold') ||
        key.contains('pliegue') ||
        key.contains('rfm') ||
        key.contains('bodyfat');

    if (isFatRelated) {
      if (diff < 0) return kSuccessColor;
      if (diff > 0) return kWarningColor;
    }

    return kInfoColor;
  }
}
