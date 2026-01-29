import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class MealCardWidget extends StatefulWidget {
  final Meal meal;
  final VoidCallback onAddFood;
  final VoidCallback onAddPhoto;
  final Function(FoodItem) onDeleteItem;
  final Function(FoodItem oldItem, FoodItem newItem) onUpdateItem;
  final VoidCallback onDeleteMeal;
  final Function(String) onNameChanged;
  final VoidCallback onSaveMeal;

  const MealCardWidget({
    super.key,
    required this.meal,
    required this.onAddFood,
    required this.onAddPhoto,
    required this.onDeleteItem,
    required this.onUpdateItem,
    required this.onDeleteMeal,
    required this.onNameChanged,
    required this.onSaveMeal,
  });

  @override
  State<MealCardWidget> createState() => _MealCardWidgetState();
}

class _MealCardWidgetState extends State<MealCardWidget> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _notesController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant MealCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.meal.name != oldWidget.meal.name &&
        widget.meal.name != _nameController.text) {
      _nameController.text = widget.meal.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncModel(FoodItem item, double newGrams) {
    final clampedGrams = newGrams.clamp(5.0, double.infinity);
    if ((clampedGrams - item.grams).abs() <= 0.01) return;
    if (item.grams <= 0) return;

    final double ratio = clampedGrams / item.grams;

    widget.onUpdateItem(
      item,
      item.copyWith(
        grams: _safe(clampedGrams),
        kcal: _safe(item.kcal * ratio),
        protein: _safe(item.protein * ratio),
        fat: _safe(item.fat * ratio),
        carbs: _safe(item.carbs * ratio),
      ),
    );
  }

  void _safeDeleteItem(FoodItem item) {
    FocusScope.of(context).unfocus();
    widget.onDeleteItem(item);
  }

  void _showEditGramsDialog(BuildContext context, FoodItem item) {
    final gramsDialogController = TextEditingController(
      text: item.grams.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text(
            "Ajustar Porción: ${item.name}",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: TextField(
            controller: gramsDialogController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: hcsDecoration(context, labelText: "Gramos").copyWith(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: kTextColorSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newGrams =
                    double.tryParse(gramsDialogController.text) ?? 0.0;
                if (newGrams > 0) {
                  _syncModel(item, newGrams);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kTextColor,
              ),
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalKcal = widget.meal.items.fold(
      0,
      (sum, item) => sum + item.kcal,
    );
    final double totalProt = widget.meal.items.fold(
      0,
      (sum, item) => sum + item.protein,
    );
    final double totalCarbs = widget.meal.items.fold(
      0,
      (sum, item) => sum + item.carbs,
    );
    final double totalFat = widget.meal.items.fold(
      0,
      (sum, item) => sum + item.fat,
    );

    final double totalMacros = totalProt + totalCarbs + totalFat;
    final double pP = totalMacros > 0 ? totalProt / totalMacros : 0;
    final double pC = totalMacros > 0 ? totalCarbs / totalMacros : 0;
    final double pF = totalMacros > 0 ? totalFat / totalMacros : 0;

    return Container(
      decoration: BoxDecoration(
        color: kPrimaryColor.withAlpha(180), // Estilo Glass unificado
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: hcsDecoration(
                      context,
                      hintText: "Nombre de comida",
                      contentPadding: EdgeInsets.zero,
                    ).copyWith(border: InputBorder.none, isDense: true),
                    onSubmitted: widget.onNameChanged,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: kCardColor,
                  onSelected: (v) {
                    if (v == 'delete') widget.onDeleteMeal();
                    if (v == 'save') widget.onSaveMeal();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.save_alt, size: 18),
                          SizedBox(width: 8),
                          Text('Guardar Plantilla'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. DASHBOARD (Panel negro)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.black.withAlpha(51),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ENERGÍA",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalKcal.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "kcal",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactMacroBar(
                        "P",
                        totalProt,
                        pP,
                        Colors.greenAccent.shade400,
                      ),
                      const SizedBox(height: 6),
                      _buildCompactMacroBar(
                        "C",
                        totalCarbs,
                        pC,
                        Colors.orangeAccent,
                      ),
                      const SizedBox(height: 6),
                      _buildCompactMacroBar(
                        "G",
                        totalFat,
                        pF,
                        Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. LISTA DE ALIMENTOS
          if (widget.meal.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "Añade alimentos...",
                  style: TextStyle(
                    color: Colors.white.withAlpha(51),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.meal.items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.white.withAlpha(13),
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final item = widget.meal.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _showEditGramsDialog(context, item),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withAlpha(26),
                            ),
                          ),
                          child: Text(
                            "${item.grams.toStringAsFixed(0)}g",
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "P:${item.protein.round()} C:${item.carbs.round()} F:${item.fat.round()}",
                              style: TextStyle(
                                color: Colors.white.withAlpha(102),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${item.kcal.round()}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.redAccent.withAlpha(128),
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => _safeDeleteItem(item),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 4. FOOTER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddFood,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text("Añadir Alimento"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withAlpha(26)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: widget.onAddPhoto,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(26)),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMacroBar(
    String label,
    double value,
    double percent,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            "${value.toStringAsFixed(1)}g",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: percent.isNaN ? 0 : percent,
              backgroundColor: Colors.white.withAlpha(26),
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

double _safe(double value) {
  if (value.isNaN || value.isInfinite) return 0.0;
  return value;
}
