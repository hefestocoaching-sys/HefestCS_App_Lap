import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_calculator.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_targets.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';

/// Professional equivalents table screen inspired by SMAE, Nutrimind, Avena Team.
class EquivalentsTableScreen extends ConsumerStatefulWidget {
  const EquivalentsTableScreen({super.key});

  @override
  ConsumerState<EquivalentsTableScreen> createState() =>
      _EquivalentsTableScreenState();
}

class _EquivalentsTableScreenState
    extends ConsumerState<EquivalentsTableScreen>
    with AutomaticKeepAliveClientMixin
    implements SaveableModule {
  @override
  bool get wantKeepAlive => true;

  // Estado: Equivalentes ajustados por comida
  Map<int, Map<String, double>> _equivalentsByMeal = {};
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromPlan();
    });
  }

  /// Inicializar desde el plan calculado
  void _initializeFromPlan() {
    final planResult = ref.read(nutritionPlanResultProvider);
    if (planResult != null && planResult.mealEquivalents != null) {
      final newMap = <int, Map<String, double>>{};
      for (int i = 0; i < planResult.mealEquivalents!.length; i++) {
        newMap[i] = Map<String, double>.from(
          planResult.mealEquivalents![i].equivalents,
        );
      }
      setState(() {
        _equivalentsByMeal = newMap;
      });
    }
  }

  @override
  Future<void> saveIfDirty() async {
    if (!_isDirty) return;
    setState(() {
      _isDirty = false;
    });
  }

  @override
  void resetDrafts() {
    _initializeFromPlan();
    setState(() {
      _isDirty = false;
    });
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  void _addEquivalentGroup(int mealIndex, String groupId, double initialValue) {
    setState(() {
      _equivalentsByMeal[mealIndex] ??= {};
      _equivalentsByMeal[mealIndex]![groupId] = initialValue;
      _markDirty();
    });
  }

  void _updateEquivalentValue(int mealIndex, String groupId, double newValue) {
    setState(() {
      if (_equivalentsByMeal[mealIndex] != null) {
        _equivalentsByMeal[mealIndex]![groupId] = newValue;
        _markDirty();
      }
    });
  }

  void _removeEquivalentGroup(int mealIndex, String groupId) {
    setState(() {
      _equivalentsByMeal[mealIndex]?.remove(groupId);
      _markDirty();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final client = ref.watch(clientsProvider).value?.activeClient;
    final planResult = ref.watch(nutritionPlanResultProvider);

    if (client == null) {
      return const Center(
        child: Text(
          'Selecciona un cliente',
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    if (planResult == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(planResult),
            const SizedBox(height: 24),
            _buildMealsSection(planResult),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: kTextColorSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Primero calcula calorias y macros',
            style: TextStyle(
              fontSize: 18,
              color: kTextColorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ve a "Gasto Energetico" y "Macronutrientes"\npara generar el plan base',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: kTextColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(planResult) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.15),
            kCardColor.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: kPrimaryColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Tabla de Equivalentes (SMAE)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(planResult),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(planResult) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _buildSummaryChip(
          'Objetivo:',
          '${planResult.kcalTargetDay.toStringAsFixed(0)} kcal',
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildSummaryChip(
          'Proteinas:',
          '${planResult.proteinTargetDay.toStringAsFixed(0)}g',
          Icons.egg,
          Colors.blue,
        ),
        _buildSummaryChip(
          'Carbos:',
          '${planResult.carbTargetDay.toStringAsFixed(0)}g',
          Icons.rice_bowl,
          Colors.amber,
        ),
        _buildSummaryChip(
          'Grasas:',
          '${planResult.fatTargetDay.toStringAsFixed(0)}g',
          Icons.water_drop,
          Colors.purple,
        ),
        _buildSummaryChip(
          'Comidas:',
          '${planResult.mealsPerDay}',
          Icons.restaurant,
          kPrimaryColor,
        ),
      ],
    );
  }

  Widget _buildSummaryChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kTextColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: kTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection(planResult) {
    return Column(
      children: List.generate(
        planResult.mealTargets.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildMealCard(
            index,
            planResult.mealTargets[index],
            planResult.mealEquivalents?[index],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(
    int mealIndex,
    MealTargets mealTarget,
    MealEquivalents? mealEq,
  ) {
    final equivalents = _equivalentsByMeal[mealIndex] ?? {};

    return ClinicSectionSurface(
      icon: _getMealIcon(mealIndex),
      title: 'COMIDA ${mealIndex + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _buildMealSummary(mealTarget),
          ),
          const SizedBox(height: 12),
          _buildEquivalentsTable(mealIndex, equivalents, mealEq),
          const SizedBox(height: 12),
          _buildAddGroupButton(mealIndex, equivalents),
        ],
      ),
    );
  }

  IconData _getMealIcon(int index) {
    const icons = [
      Icons.wb_sunny_outlined,
      Icons.lunch_dining,
      Icons.dinner_dining,
      Icons.nightlight_outlined,
      Icons.fastfood_outlined,
      Icons.cookie_outlined,
    ];
    return icons[index % icons.length];
  }

  Widget _buildMealSummary(MealTargets meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${meal.kcal.toStringAsFixed(0)} kcal',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'P: ${meal.proteinG.toStringAsFixed(1)}g  '
          'C: ${meal.carbG.toStringAsFixed(1)}g  '
          'G: ${meal.fatG.toStringAsFixed(1)}g',
          style: const TextStyle(
            fontSize: 11,
            color: kTextColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEquivalentsTable(
    int mealIndex,
    Map<String, double> equivalents,
    MealEquivalents? mealEq,
  ) {
    if (equivalents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: kTextColorSecondary.withOpacity(0.2),
          ),
        ),
        child: const Center(
          child: Text(
            'Sin equivalentes asignados',
            style: TextStyle(
              color: kTextColorSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FixedColumnWidth(40),
      },
      border: TableBorder.all(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.15),
          ),
          children: const [
            _TableHeaderCell('Grupo de Alimentos'),
            _TableHeaderCell('Equivalentes'),
            _TableHeaderCell('Alimentos Ejemplo'),
            _TableHeaderCell(''),
          ],
        ),
        ...equivalents.entries.map((entry) {
          final def = EquivalentCatalog.v1Definitions.firstWhere(
            (d) => d.id == entry.key,
            orElse: () => EquivalentCatalog.v1Definitions.first,
          );

          final suggestedFood = _getSuggestedFood(def, entry.value);

          return TableRow(
            children: [
              _TableCell(_getGroupLabel(entry.key)),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: _buildEquivalentCounter(mealIndex, entry.key, entry.value),
              ),
              _TableCell(suggestedFood),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.withOpacity(0.7),
                  onPressed: () => _removeEquivalentGroup(mealIndex, entry.key),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEquivalentCounter(int mealIndex, String groupId, double current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: kPrimaryColor,
          onPressed: current > 0.5
              ? () => _updateEquivalentValue(mealIndex, groupId, current - 0.5)
              : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 50),
          child: Text(
            current.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: kPrimaryColor,
          onPressed: () =>
              _updateEquivalentValue(mealIndex, groupId, current + 0.5),
        ),
      ],
    );
  }

  Widget _buildAddGroupButton(int mealIndex, Map<String, double> current) {
    return ElevatedButton.icon(
      onPressed: () => _showAddGroupDialog(mealIndex, current),
      icon: const Icon(Icons.add),
      label: const Text('Agregar Grupo de Alimentos'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor.withOpacity(0.2),
        foregroundColor: kPrimaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showAddGroupDialog(int mealIndex, Map<String, double> currentGroups) {
    final availableGroups = EquivalentCatalog.v1Definitions
        .where((def) => !currentGroups.containsKey(def.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Row(
            children: [
              Icon(Icons.add_circle, color: kPrimaryColor),
              const SizedBox(width: 8),
              const Text(
                'Seleccionar Grupo',
                style: TextStyle(color: kTextColor),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableGroups.length,
              itemBuilder: (context, index) {
                final def = availableGroups[index];
                return _buildGroupOption(def, mealIndex);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupOption(EquivalentDefinition def, int mealIndex) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getGroupColor(def.group).withOpacity(0.2),
        child: Icon(
          _getGroupIcon(def.group),
          color: _getGroupColor(def.group),
          size: 20,
        ),
      ),
      title: Text(
        _getGroupLabel(def.id),
        style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'P: ${def.proteinG}g | C: ${def.carbG}g | G: ${def.fatG}g | ${def.kcal} kcal',
        style: TextStyle(
          fontSize: 11,
          color: kTextColorSecondary,
        ),
      ),
      onTap: () {
        _addEquivalentGroup(mealIndex, def.id, 1.0);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: resetDrafts,
            icon: const Icon(Icons.refresh),
            label: const Text('Restablecer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              // Usuario avanza al diseno de menu
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Equivalentes configurados. Ve a "Diseno de Menu"'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Guardar Configuracion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _getGroupLabel(String groupId) {
    const labels = {
      'aoa_bajo_grasa': 'AOA Bajo en Grasa',
      'aoa_medio_grasa': 'AOA Moderado en Grasa',
      'aoa_alto_grasa': 'AOA Alto en Grasa',
      'cereal_sin_grasa': 'Cereales Sin Grasa',
      'cereal_con_grasa': 'Cereales Con Grasa',
      'fruta': 'Frutas',
      'verdura': 'Verduras',
      'leguminosa': 'Leguminosas',
      'leche_descremada': 'Leche Descremada',
      'leche_semidescremada': 'Leche Semidescremada',
      'leche_entera': 'Leche Entera',
      'aceite_sin_proteina': 'Aceites y Grasas',
      'aceite_con_proteina': 'Grasas con Proteina',
      'azucar_sin_grasa': 'Azucares Sin Grasa',
    };
    return labels[groupId] ?? groupId;
  }

  Color _getGroupColor(String group) {
    const colors = {
      'alimentos_origen_animal': Colors.blue,
      'cereales': Colors.amber,
      'frutas': Colors.pink,
      'verduras': Colors.green,
      'leguminosas': Colors.brown,
      'leche': Colors.cyan,
      'grasas': Colors.purple,
      'azucares': Colors.red,
    };
    return colors[group] ?? kPrimaryColor;
  }

  IconData _getGroupIcon(String group) {
    const icons = {
      'alimentos_origen_animal': Icons.egg,
      'cereales': Icons.rice_bowl,
      'frutas': Icons.apple,
      'verduras': Icons.spa,
      'leguminosas': Icons.grain,
      'leche': Icons.local_drink,
      'grasas': Icons.water_drop,
      'azucares': Icons.cookie,
    };
    return icons[group] ?? Icons.restaurant;
  }

  String _getSuggestedFood(EquivalentDefinition def, double qty) {
    const examples = {
      'aoa_bajo_grasa': '~30g pechuga de pollo',
      'cereal_sin_grasa': '~30g arroz cocido',
      'fruta': '1 manzana mediana',
      'verdura': '1 taza cocida',
      'aceite_sin_proteina': '1 cucharadita',
    };

    final base = examples[def.id] ?? 'Ver catalogo';
    return '${qty.toStringAsFixed(1)}x ($base)';
  }
}

typedef EquivalentsTableScreenState = _EquivalentsTableScreenState;

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: kTextColor,
        ),
      ),
    );
  }
}
