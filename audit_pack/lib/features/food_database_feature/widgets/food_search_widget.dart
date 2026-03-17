import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class FoodSearchWidget extends StatelessWidget {
  final void Function(String) onQuery;
  const FoodSearchWidget({super.key, required this.onQuery});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: hcsDecoration(
              context,
              hintText: 'Buscar alimento…',
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: onQuery,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => onQuery(controller.text),
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}
