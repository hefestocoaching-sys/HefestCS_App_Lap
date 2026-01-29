import 'package:flutter/material.dart';
import 'package:hcs_app_lap/services/food_database_service.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

// Modal principal con retorno del alimento seleccionado
Future<FoodItem?> showFoodSearchModal(BuildContext context) async {
  return await showModalBottomSheet<FoodItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const FoodSearchModal(),
  );
}

class FoodSearchModal extends StatefulWidget {
  const FoodSearchModal({super.key});

  @override
  State<FoodSearchModal> createState() => _FoodSearchModalState();
}

class _FoodSearchModalState extends State<FoodSearchModal> {
  final TextEditingController _controller = TextEditingController();
  List<FoodItem> _results = [];

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = [];
      } else {
        _results = foodDB.search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: kAppBarColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Buscar Alimento",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextColorSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // BUSCADOR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: kTextColor),
              decoration: hcsDecoration(
                context,
                hintText: "Buscar alimento...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: kTextColorSecondary,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: kTextColorSecondary),
                  onPressed: () {
                    _controller.clear();
                    _onSearch('');
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearch,
            ),
          ),

          // RESULTADOS
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      "Sin resultados",
                      style: TextStyle(color: kTextColorSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final f = _results[index];
                      return ListTile(
                        title: Text(
                          f.name ?? f.id,
                          style: const TextStyle(color: kTextColor),
                        ),
                        subtitle: Text(
                          f.group,
                          style: const TextStyle(color: kTextColorSecondary),
                        ),
                        trailing: Text(
                          "${f.nutrients['kcal']?.toStringAsFixed(0)} kcal",
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
