import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/entities/smae_food.dart';
import 'package:hcs_app_lap/data/datasources/local/smae_food_catalog_loader.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/meal_plan_feature/widgets/meal_card_widget.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class DailyMealPlanTab extends ConsumerStatefulWidget {
  final String dayKey;
  final DailyMealPlan? dailyMealPlan;
  final ValueChanged<List<Meal>> onMealsUpdated;

  const DailyMealPlanTab({
    super.key,
    required this.dayKey,
    this.dailyMealPlan,
    required this.onMealsUpdated,
  });

  @override
  ConsumerState<DailyMealPlanTab> createState() => _DailyMealPlanTabState();
}

class _DailyMealPlanTabState extends ConsumerState<DailyMealPlanTab> {
  late List<Meal> _meals;

  @override
  void initState() {
    super.initState();
    _meals = List<Meal>.from(widget.dailyMealPlan?.meals ?? []);
  }

  double _safeDouble(num? value) {
    if (value == null) return 0.0;
    final d = value.toDouble();
    if (d.isNaN || d.isInfinite) return 0.0;
    return d;
  }

  Future<void> _handleAddFood(int mealIndex) async {
    if (mealIndex < 0 || mealIndex >= _meals.length) return;
    final meal = _meals[mealIndex];
    final foods = await smaeFoodCatalogLoader.load();
    debugPrint('SMAE catalog loaded: ${foods.length} alimentos');

    if (!mounted) return;
    final SmaeFood? choice = await _showSmaeSearchModal(context, foods);
    if (choice == null) return;
    if (!mounted) return;

    final itemName = choice.portion.isNotEmpty
        ? '${choice.nameEs} (${choice.portion})'
        : choice.nameEs;
    final baseGrams = (choice.netWeightG ?? 0) > 0 ? choice.netWeightG! : 100.0;

    final newItem = FoodItem(
      name: itemName,
      grams: _safeDouble(baseGrams),
      kcal: _safeDouble(choice.kcal),
      protein: _safeDouble(choice.proteinG),
      fat: _safeDouble(choice.fatG),
      carbs: _safeDouble(choice.carbsG),
    );

    final updatedItems = List<FoodItem>.from(meal.items)..add(newItem);
    debugPrint('SMAE add -> ${choice.nameEs} en ${meal.name}');
    _updateMeal(mealIndex, meal.copyWith(items: updatedItems));
  }

  @override
  void didUpdateWidget(covariant DailyMealPlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dailyMealPlan != oldWidget.dailyMealPlan ||
        widget.dayKey != oldWidget.dayKey) {
      _meals = List<Meal>.from(widget.dailyMealPlan?.meals ?? []);
    }
  }

  void _addMeal() {
    setState(() {
      _meals.add(const Meal(name: "Nueva Comida", items: []));
    });
    widget.onMealsUpdated(List<Meal>.from(_meals));
  }

  void _removeMeal(int index) {
    if (index < 0 || index >= _meals.length) return;
    setState(() {
      _meals.removeAt(index);
    });
    widget.onMealsUpdated(List<Meal>.from(_meals));
  }

  Future<SmaeFood?> _showSmaeSearchModal(
    BuildContext context,
    List<SmaeFood> foods,
  ) async {
    return showModalBottomSheet<SmaeFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final TextEditingController controller = TextEditingController();
        List<SmaeFood> results = [];

        void runSearch(String query) {
          final q = query.trim().toLowerCase();
          results = q.isEmpty
              ? []
              : foods
                    .where((f) => f.nameEs.toLowerCase().contains(q))
                    .take(30)
                    .toList();
        }

        runSearch('');

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Buscar alimento SMAE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    onChanged: (q) => setSheetState(() {
                      runSearch(q);
                    }),
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        hcsDecoration(
                          context,
                          hintText: 'Escribe un nombre (ej. avena)',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                        ).copyWith(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final food = results[index];
                          final subtitle = food.portion.isNotEmpty
                              ? '${food.portion} • ${food.kcal.toStringAsFixed(0)} kcal'
                              : '${food.kcal.toStringAsFixed(0)} kcal';
                          return ListTile(
                            onTap: () => Navigator.of(context).pop(food),
                            title: Text(
                              food.nameEs,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              '${_safeDouble(food.netWeightG ?? 0) > 0 ? _safeDouble(food.netWeightG ?? 0).toStringAsFixed(0) : '100'} g',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateMeal(int index, Meal updatedMeal) {
    if (index < 0 || index >= _meals.length) return;
    setState(() {
      _meals[index] = updatedMeal;
    });
    widget.onMealsUpdated(List<Meal>.from(_meals));
  }

  @override
  Widget build(BuildContext context) {
    // 1. CALCULAR LO QUE LLEVA PUESTO (ACTUAL)
    double currentKcal = 0;
    double currentProt = 0;
    double currentCarbs = 0;
    double currentFat = 0;

    for (var meal in _meals) {
      for (var item in meal.items) {
        currentKcal += item.kcal;
        currentProt += item.protein;
        currentCarbs += item.carbs;
        currentFat += item.fat;
      }
    }

    // 2. CALCULAR LA META PARA ESTE DÍA ESPECÍFICO (TARGET)
    final client = ref.watch(clientsProvider).value?.activeClient;
    final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));
    Map<String, DailyMacroSettings>? activeMacros;
    double? maintenanceKcal;
    if (client != null) {
      final macroRecords = readNutritionRecordList(
        client.nutrition.extra[NutritionExtraKeys.macrosRecords],
      );
      final macroRecord =
          nutritionRecordForDate(macroRecords, activeDateIso) ??
          latestNutritionRecordByDate(macroRecords);
      activeMacros =
          parseWeeklyMacroSettings(macroRecord?['weeklyMacroSettings']) ??
          client.effectiveWeeklyMacros;

      final evalRecords = readNutritionRecordList(
        client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
      );
      final evalRecord =
          nutritionRecordForDate(evalRecords, activeDateIso) ??
          latestNutritionRecordByDate(evalRecords);
      maintenanceKcal =
          (evalRecord?['kcal'] as num?)?.toDouble() ?? client.kcal?.toDouble();
    }

    double targetProt = 0;
    double targetCarbs = 0;
    double targetFat = 0;
    double targetKcal = 0;
    bool hasTargets = false;

    if (client != null) {
      final double weight = client.lastWeight ?? 70.0;
      // Buscamos la configuración específica para "Lunes", "Martes", etc.
      final DailyMacroSettings? daySettings = activeMacros?[widget.dayKey];

      if (daySettings != null) {
        hasTargets = true;
        // Calculamos gramos objetivo basados en g/kg
        targetProt = daySettings.proteinSelected * weight;
        targetFat = daySettings.fatSelected * weight;
        // El carbSelected a veces se guarda, si no, lo inferimos por kcal restantes si fuera necesario
        // Asumimos que DailyMacroSettings tiene el carbSelected calculado correctamente en la pestaña anterior
        targetCarbs = daySettings.carbSelected * weight;

        // Kcal totales objetivo
        targetKcal = (targetProt * 4) + (targetCarbs * 4) + (targetFat * 9);
      } else {
        // Si no hay config específica, usamos generales o ceros
        targetKcal = maintenanceKcal ?? 0;
      }
    }

    if (_meals.isEmpty) {
      return _buildEmptyState(_addMeal);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 450).floor();
          if (crossAxisCount < 1) crossAxisCount = 1;
          if (crossAxisCount > 4) crossAxisCount = 4;

          List<List<int>> columns = List.generate(crossAxisCount, (_) => []);
          for (int i = 0; i < _meals.length; i++) {
            columns[i % crossAxisCount].add(i);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- RESUMEN DE OBJETIVOS (HEADER) ---
                _buildTargetSummary(
                  currentKcal,
                  targetKcal,
                  currentProt,
                  targetProt,
                  currentCarbs,
                  targetCarbs,
                  currentFat,
                  targetFat,
                  hasTargets,
                ),

                const SizedBox(height: 24),

                // TÍTULO SECCIÓN
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_view_day_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "MENÚ DE ${widget.dayKey.toUpperCase()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addMeal,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Añadir Comida"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GRID DE TARJETAS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(crossAxisCount, (colIndex) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: colIndex == crossAxisCount - 1 ? 0 : 24.0,
                        ),
                        child: Column(
                          children: columns[colIndex].map((index) {
                            final meal = _meals[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: MealCardWidget(
                                key: ValueKey(meal.hashCode),
                                meal: meal,
                                onNameChanged: (n) =>
                                    _updateMeal(index, meal.copyWith(name: n)),
                                onAddFood: () => _handleAddFood(index),
                                onAddPhoto: () {},
                                onDeleteItem: (item) {
                                  final updatedItems = List<FoodItem>.from(
                                    meal.items,
                                  )..remove(item);
                                  _updateMeal(
                                    index,
                                    meal.copyWith(items: updatedItems),
                                  );
                                },
                                onUpdateItem: (oldItem, newItem) {
                                  final updatedItems = List<FoodItem>.from(
                                    meal.items,
                                  );
                                  final i = updatedItems.indexOf(oldItem);
                                  if (i != -1) {
                                    updatedItems[i] = newItem;
                                    _updateMeal(
                                      index,
                                      meal.copyWith(items: updatedItems),
                                    );
                                  }
                                },
                                onDeleteMeal: () => _removeMeal(index),
                                onSaveMeal: () {},
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET DE RESUMEN DE METAS ---
  Widget _buildTargetSummary(
    double currKcal,
    double targetKcal,
    double currP,
    double targetP,
    double currC,
    double targetC,
    double currF,
    double targetF,
    bool hasTargets,
  ) {
    // Cálculos de diferencia
    double remKcal = targetKcal - currKcal;
    double remP = targetP - currP;
    double remC = targetC - currC;
    double remF = targetF - currF;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.1),
            const Color(0xFF1E1E2C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // FILA SUPERIOR: KCAL (META vs ACTUAL)
          Row(
            children: [
              // Círculo de Progreso
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: hasTargets && targetKcal > 0
                          ? (currKcal / targetKcal).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: Colors.white10,
                      color: remKcal < 0
                          ? Colors.redAccent
                          : kPrimaryColor, // Rojo si se pasa
                      strokeWidth: 6,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "KCAL",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currKcal.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Texto de Resumen
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "BALANCE ENERGÉTICO",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${currKcal.toStringAsFixed(0)} / ${targetKcal.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            "kcal",
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Indicador de Faltante/Exceso
                    if (hasTargets)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: remKcal < 0
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: remKcal < 0
                                ? Colors.redAccent.withValues(alpha: 0.5)
                                : Colors.green.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          remKcal < 0
                              ? "Exceso: ${remKcal.abs().toStringAsFixed(0)} kcal"
                              : "Faltan: ${remKcal.toStringAsFixed(0)} kcal",
                          style: TextStyle(
                            color: remKcal < 0
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const Text(
                        "Sin meta definida",
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),

          // FILA INFERIOR: MACROS DETALLADOS
          Row(
            children: [
              _buildTargetMacro(
                "Proteína",
                currP,
                targetP,
                remP,
                Colors.greenAccent.shade400,
              ),
              const SizedBox(width: 12), // Espaciado flexible
              Container(width: 1, height: 40, color: Colors.white10),
              const SizedBox(width: 12),
              _buildTargetMacro(
                "Carbohidratos",
                currC,
                targetC,
                remC,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 40, color: Colors.white10),
              const SizedBox(width: 12),
              _buildTargetMacro(
                "Grasas",
                currF,
                targetF,
                remF,
                Colors.lightBlueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetMacro(
    String label,
    double current,
    double target,
    double remaining,
    Color color,
  ) {
    bool isOver = remaining < 0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (target > 0)
                Text(
                  isOver
                      ? "+${remaining.abs().toStringAsFixed(0)}g"
                      : "-${remaining.toStringAsFixed(0)}g",
                  style: TextStyle(
                    color: isOver ? Colors.redAccent : Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra de Progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.white10,
              color: isOver
                  ? Colors.redAccent
                  : color, // Se pone roja si te pasas
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 13),
              children: [
                TextSpan(
                  text: current.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: " / ",
                  style: TextStyle(color: Colors.white24),
                ),
                TextSpan(
                  text: "${target.toStringAsFixed(0)}g",
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(VoidCallback onAdd) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_calendar_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 24),
          const Text(
            "Comienza tu planificación",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Añade las comidas para este día.",
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Crear Primera Comida"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
          ),
        ],
      ),
    );
  }
}
