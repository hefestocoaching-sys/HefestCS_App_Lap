import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/muscle_volume_buckets.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class VolumeBreakdownTable extends StatelessWidget {
  final Map<String, MuscleVolumeBuckets> muscles;

  const VolumeBreakdownTable({super.key, required this.muscles});

  @override
  Widget build(BuildContext context) {
    // Ordenamos los músculos para que salgan siempre igual (ej. alfabético o por lógica corporal)
    final sortedMuscles = muscles.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(
          alpha: 0.43,
        ), // Estilo de vidrio unificado
        borderRadius: BorderRadius.circular(16), // Radio unificado
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                // Radio unificado
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Músculo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Total",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "P / M / L",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kPrimaryColor),
          // Rows
          ...sortedMuscles.map((muscle) {
            final buckets = muscles[muscle]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      muscle,
                      style: const TextStyle(
                        color: kTextColorSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "$buckets",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BucketBadge(
                          count: buckets.heavySets.round(),
                          color: Colors.redAccent,
                          label: "P",
                        ),
                        const SizedBox(width: 4),
                        _BucketBadge(
                          count: buckets.mediumSets.round(),
                          color: Colors.orangeAccent,
                          label: "M",
                        ),
                        const SizedBox(width: 4),
                        _BucketBadge(
                          count: buckets.lightSets.round(),
                          color: Colors.greenAccent,
                          label: "L",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BucketBadge extends StatelessWidget {
  final int count;
  final Color color;
  final String label;

  const _BucketBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox(width: 24); // Placeholder vacío para alineación
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$count",
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
