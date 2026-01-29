import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onAdd;
  const FoodItemCard({super.key, required this.item, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('${item.grams} g • ${item.kcal.toStringAsFixed(0)} kcal'),
        trailing: IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
