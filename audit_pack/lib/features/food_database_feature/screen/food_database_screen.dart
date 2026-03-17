import 'package:flutter/material.dart';
import 'package:hcs_app_lap/services/food_database_service.dart';
import 'package:hcs_app_lap/features/food_database_feature/widgets/food_search_delegate.dart';

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  // ignore: unused_field
  String _query = '';
  List<FoodItem> _results = [];

  void _onSearch(String query) {
    setState(() {
      _query = query;
      _results = query.isEmpty ? [] : foodDB.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FoodSearchDelegate(onSearchSubmitted: _onSearch),

        Expanded(
          child: _results.isEmpty
              ? const Center(child: Text("No hay resultados"))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final f = _results[i];
                    return ListTile(
                      title: Text(f.name ?? f.id),
                      subtitle: Text(f.group),
                      trailing: Text(
                        "${f.nutrients['kcal']?.toStringAsFixed(0)} kcal",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
