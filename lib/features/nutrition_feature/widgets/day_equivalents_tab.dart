import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/equivalents_by_day_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Tab de equivalentes para un dia especifico
/// Contiene 2 sub-tabs: Equivalentes Generales | Distribucion por Comidas
class DayEquivalentsTab extends ConsumerStatefulWidget {
  final String dayKey; // 'lunes', 'martes', etc.
  final String dayLabel; // 'Lunes', 'Martes', etc.
  final dynamic planResult;

  const DayEquivalentsTab({
    super.key,
    required this.dayKey,
    required this.dayLabel,
    required this.planResult,
  });

  @override
  ConsumerState<DayEquivalentsTab> createState() => _DayEquivalentsTabState();
}

class _DayEquivalentsTabState extends ConsumerState<DayEquivalentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mealsCount = widget.planResult.mealsPerDay;
      final groupIds = EquivalentCatalog.v1Definitions
          .map((def) => def.id)
          .toList();
      ref
          .read(equivalentsByDayProvider.notifier)
          .ensureDay(widget.dayKey, mealsCount, groupIds);
    });
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: kCardColor.withOpacity(0.3),
          child: TabBar(
            controller: _subTabController,
            labelColor: kTextColor,
            unselectedLabelColor: kTextColorSecondary,
            indicatorColor: kPrimaryColor,
            tabs: const [
              Tab(text: 'Equivalentes Generales'),
              Tab(text: 'Distribucion por Comidas'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildGeneralEquivalentsTab(),
              _buildMealsDistributionTab(),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // TAB 1: EQUIVALENTES GENERALES
  // =====================================================================

  Widget _buildGeneralEquivalentsTab() {
    final allGroups = _getAllSMAEGroups();
    final state = ref.watch(equivalentsByDayProvider);
    final dayEquivalents = state.dayEquivalents[widget.dayKey] ?? {};
    final totals = _calculateTotals(dayEquivalents);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                ...allGroups.map(
                  (group) => _buildTableRow(group, dayEquivalents),
                ),
                _buildTotalsRow(totals),
                _buildFaltantesRow(totals),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: _HeaderCell('Grupo en el Sistema de Equivalentes'),
          ),
          Expanded(flex: 2, child: _HeaderCell('Subgrupos')),
          Expanded(flex: 2, child: _HeaderCell('Equivalentes')),
          Expanded(flex: 1, child: _HeaderCell('Energia\n(kcal)')),
          Expanded(flex: 1, child: _HeaderCell('Proteina\n(g)')),
          Expanded(flex: 1, child: _HeaderCell('Lipidos\n(g)')),
          Expanded(flex: 1, child: _HeaderCell('Hidratos\ncarbono (g)')),
          Expanded(flex: 1, child: _HeaderCell('Etanol\n(g)')),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    EquivalentDefinition group,
    Map<String, double> dayEquivalents,
  ) {
    final qty = dayEquivalents[group.id] ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: _getGroupBackgroundColor(group.group),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _getGroupMainLabel(group.group),
              style: const TextStyle(
                fontSize: 12,
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getSubgroupLabel(group.subgroup),
              style: const TextStyle(fontSize: 11, color: kTextColorSecondary),
            ),
          ),
          Expanded(flex: 2, child: _buildEquivalentCounter(group.id, qty)),
          Expanded(
            flex: 1,
            child: _buildValueCell(group.kcal * qty, decimals: 0),
          ),
          Expanded(
            flex: 1,
            child: _buildValueCell(group.proteinG * qty, decimals: 0),
          ),
          Expanded(
            flex: 1,
            child: _buildValueCell(group.fatG * qty, decimals: 0),
          ),
          Expanded(
            flex: 1,
            child: _buildValueCell(group.carbG * qty, decimals: 0),
          ),
          const Expanded(flex: 1, child: _ValueCell('0')),
        ],
      ),
    );
  }

  Widget _buildEquivalentCounter(String groupId, double current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: current >= 0.5
              ? () => ref
                    .read(equivalentsByDayProvider.notifier)
                    .updateEquivalent(widget.dayKey, groupId, -0.5)
              : null,
          child: Icon(
            Icons.remove_circle_outline,
            size: 16,
            color: current >= 0.5
                ? kPrimaryColor
                : kTextColorSecondary.withOpacity(0.3),
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            current.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
        ),
        InkWell(
          onTap: () => ref
              .read(equivalentsByDayProvider.notifier)
              .updateEquivalent(widget.dayKey, groupId, 0.5),
          child: const Icon(
            Icons.add_circle_outline,
            size: 16,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsRow(Map<String, double> totals) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withOpacity(0.2),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 7,
            child: Text(
              'Suma de los gramos totales y Energia total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
          Expanded(flex: 1, child: _buildTotalCell(totals['kcal']!)),
          Expanded(flex: 1, child: _buildTotalCell(totals['protein']!)),
          Expanded(flex: 1, child: _buildTotalCell(totals['fat']!)),
          Expanded(flex: 1, child: _buildTotalCell(totals['carb']!)),
          const Expanded(flex: 1, child: _ValueCell('0')),
        ],
      ),
    );
  }

  Widget _buildFaltantesRow(Map<String, double> totals) {
    final kcalDiff = totals['kcal']! - widget.planResult.kcalTargetDay;
    final protDiff = totals['protein']! - widget.planResult.proteinTargetDay;
    final fatDiff = totals['fat']! - widget.planResult.fatTargetDay;
    final carbDiff = totals['carb']! - widget.planResult.carbTargetDay;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 7,
            child: Text(
              'Energia y gramos faltantes para el Plan Alimenticio',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kTextColor,
              ),
            ),
          ),
          Expanded(flex: 1, child: _buildDiffCell(kcalDiff)),
          Expanded(flex: 1, child: _buildDiffCell(protDiff)),
          Expanded(flex: 1, child: _buildDiffCell(fatDiff)),
          Expanded(flex: 1, child: _buildDiffCell(carbDiff)),
          const Expanded(flex: 1, child: _ValueCell('0')),
        ],
      ),
    );
  }

  // =====================================================================
  // TAB 2: DISTRIBUCION POR COMIDAS
  // =====================================================================

  Widget _buildMealsDistributionTab() {
    final allGroups = _getAllSMAEGroups();
    final mealsCount = widget.planResult.mealsPerDay;
    final state = ref.watch(equivalentsByDayProvider);
    final dayMeals = state.dayMealEquivalents[widget.dayKey] ?? {};
    final dayEquivalents = state.dayEquivalents[widget.dayKey] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildMealsHeader(mealsCount),
                  ...allGroups.map(
                    (group) => _buildMealsRow(
                      group,
                      mealsCount,
                      dayMeals[group.id] ?? {},
                      dayEquivalents[group.id] ?? 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsHeader(int mealsCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEC407A).withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 200,
            child: _HeaderCell('Grupo en el Sistema de Equivalentes'),
          ),
          const SizedBox(width: 150, child: _HeaderCell('Subgrupos')),
          ...List.generate(
            mealsCount,
            (i) => SizedBox(width: 80, child: _HeaderCell('Comida ${i + 1}')),
          ),
          const SizedBox(width: 80, child: _HeaderCell('Totales')),
          const SizedBox(width: 80, child: _HeaderCell('Faltantes')),
        ],
      ),
    );
  }

  Widget _buildMealsRow(
    EquivalentDefinition group,
    int mealsCount,
    Map<int, double> mealValues,
    double dayTotal,
  ) {
    final totalByMeals = mealValues.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final faltante = dayTotal - totalByMeals;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: _getGroupBackgroundColor(group.group),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              _getGroupMainLabel(group.group),
              style: const TextStyle(
                fontSize: 12,
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              _getSubgroupLabel(group.subgroup),
              style: const TextStyle(fontSize: 11, color: kTextColorSecondary),
            ),
          ),
          ...List.generate(
            mealsCount,
            (i) => SizedBox(
              width: 80,
              child: _buildMealCell(group.id, i, mealValues[i] ?? 0.0),
            ),
          ),
          SizedBox(
            width: 80,
            child: _buildValueCell(totalByMeals, decimals: 1),
          ),
          SizedBox(
            width: 80,
            child: _buildValueCell(faltante, decimals: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCell(String groupId, int mealIndex, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: value >= 0.5
              ? () => ref
                    .read(equivalentsByDayProvider.notifier)
                    .updateMealEquivalent(
                      widget.dayKey,
                      groupId,
                      mealIndex,
                      -0.5,
                    )
              : null,
          child: Icon(
            Icons.remove_circle_outline,
            size: 14,
            color: value >= 0.5
                ? kPrimaryColor
                : kTextColorSecondary.withOpacity(0.3),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: kTextColor),
          ),
        ),
        InkWell(
          onTap: () => ref
              .read(equivalentsByDayProvider.notifier)
              .updateMealEquivalent(widget.dayKey, groupId, mealIndex, 0.5),
          child: const Icon(
            Icons.add_circle_outline,
            size: 14,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.copy),
            label: const Text('Copiar a Otro Dia'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueCell(double value, {int decimals = 1}) {
    return Text(
      value.toStringAsFixed(decimals),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: kTextColor),
    );
  }

  Widget _buildTotalCell(double value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value.toStringAsFixed(0),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kTextColor,
        ),
      ),
    );
  }

  Widget _buildDiffCell(double diff) {
    final color = diff.abs() < 50
        ? Colors.green
        : diff > 0
        ? Colors.orange
        : Colors.red;
    return Text(
      diff > 0 ? '+${diff.toStringAsFixed(0)}' : diff.toStringAsFixed(0),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    );
  }

  List<EquivalentDefinition> _getAllSMAEGroups() {
    final list = EquivalentCatalog.v1Definitions.toList();
    list.sort((a, b) => _getGroupOrder(a.id).compareTo(_getGroupOrder(b.id)));
    return list;
  }

  Map<String, double> _calculateTotals(Map<String, double> dayEquivalents) {
    double kcal = 0, protein = 0, fat = 0, carb = 0;
    for (final entry in dayEquivalents.entries) {
      final def = EquivalentCatalog.v1Definitions.firstWhere(
        (d) => d.id == entry.key,
      );
      kcal += def.kcal * entry.value;
      protein += def.proteinG * entry.value;
      fat += def.fatG * entry.value;
      carb += def.carbG * entry.value;
    }
    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carb': carb};
  }

  int _getGroupOrder(String groupId) {
    const order = {
      'vegetales': 0,
      'frutas': 1,
      'cereales_sin_grasa': 2,
      'cereales_con_grasa': 3,
      'leguminosas': 4,
      'aoa_muy_bajo': 5,
      'aoa_bajo': 6,
      'aoa_moderado': 7,
      'aoa_alto': 8,
      'leche_descremada': 9,
      'leche_semidescremada': 10,
      'leche_entera': 11,
      'grasas_sin_proteina': 12,
      'grasas_con_proteina': 13,
      'azucares_sin_grasa': 14,
      'azucares_con_grasa': 15,
      'libres_energia': 16,
      'alcohol': 17,
    };
    return order[groupId] ?? 99;
  }

  Color _getGroupBackgroundColor(String group) {
    const colors = {
      'vegetales': Color(0xFF4CAF50),
      'frutas': Color(0xFFFFC107),
      'cereales_tuberculos': Color(0xFF795548),
      'leguminosas': Color(0xFF8BC34A),
      'aoa': Color(0xFF90CAF9),
      'leches': Color(0xFFE0E0E0),
      'grasas': Color(0xFFFFC107),
      'azucares': Color(0xFF90CAF9),
      'libres': Color(0xFFBDBDBD),
      'alcohol': Color(0xFFD7CCC8),
    };
    return (colors[group] ?? kCardColor).withOpacity(0.12);
  }

  String _getGroupMainLabel(String group) {
    const labels = {
      'vegetales': 'Vegetales',
      'frutas': 'Frutas',
      'cereales_tuberculos': 'Cereales y tuberculos',
      'leguminosas': 'Leguminosas',
      'aoa': 'Alimentos de origen animal',
      'leches': 'Leches',
      'grasas': 'Aceites y Grasas',
      'azucares': 'Azucares',
      'libres': 'Libres de energia',
      'alcohol': 'Alcohol',
    };
    return labels[group] ?? group;
  }

  String _getSubgroupLabel(String subgroup) {
    const labels = {
      'general': '',
      'sin_grasa': 'Sin grasa',
      'con_grasa': 'Con grasa',
      'muy_bajo': 'Muy bajo',
      'bajo': 'Bajo',
      'moderado': 'Moderado',
      'alto': 'Alto',
      'descremado': 'Descremado',
      'semidescremada': 'Semidescremada',
      'entera': 'Entera',
      'sin_proteina': 'Sin proteina',
      'con_proteina': 'Con proteina',
      'energia': 'Energia',
      '': '',
    };
    return labels[subgroup] ?? subgroup;
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kTextColor,
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final String value;

  const _ValueCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: kTextColor),
    );
  }
}
