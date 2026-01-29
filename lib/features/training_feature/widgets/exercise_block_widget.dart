import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/training_feature/services/training_plan_builder.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class ExerciseBlockWidget extends StatelessWidget {
  final ExerciseBlock block;
  const ExerciseBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              block.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              block.exercise.nameEs,
              style: const TextStyle(fontSize: 13, color: kTextColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${block.sets}×${block.repRange}',
            style: const TextStyle(fontSize: 12, color: kTextColorSecondary),
          ),
          const SizedBox(width: 8),
          _colorDot(block.color),
        ],
      ),
    );
  }

  Widget _colorDot(String colorCode) {
    final color = colorCode == 'blue' ? Colors.blueAccent : Colors.white;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.4),
        border: Border.all(color: color, width: 1.2),
      ),
    );
  }
}
