import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class FoodSearchDelegate extends StatefulWidget {
  final Function(String) onSearchSubmitted;

  const FoodSearchDelegate({super.key, required this.onSearchSubmitted});

  @override
  State<FoodSearchDelegate> createState() => _FoodSearchDelegateState();
}

class _FoodSearchDelegateState extends State<FoodSearchDelegate> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: kAppBarColor,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: kTextColor),
        decoration: hcsDecoration(
          context,
          hintText: 'Buscar alimento...',
          prefixIcon: const Icon(Icons.search, color: kTextColorSecondary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: kTextColorSecondary),
            onPressed: () {
              _searchController.clear();
              widget.onSearchSubmitted('');
            },
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        onSubmitted: widget.onSearchSubmitted,
      ),
    );
  }
}
