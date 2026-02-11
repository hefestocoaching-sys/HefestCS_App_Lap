import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Screen 1: SMAE general equivalents summary.
class EquivalentsGeneralScreen extends ConsumerStatefulWidget {
  const EquivalentsGeneralScreen({super.key});

  @override
  ConsumerState<EquivalentsGeneralScreen> createState() =>
      _EquivalentsGeneralScreenState();
}

class _EquivalentsGeneralScreenState
    extends ConsumerState<EquivalentsGeneralScreen>
    with AutomaticKeepAliveClientMixin
    implements SaveableModule {
  @override
  bool get wantKeepAlive => true;

  Map<String, double> _equivalentsByGroup = {};
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromPlan();
    });
  }

  void _initializeFromPlan() {
    final planResult = ref.read(nutritionPlanResultProvider);
    if (planResult == null || planResult.mealEquivalents == null) return;

    final aggregated = <String, double>{};
    for (final mealEq in planResult.mealEquivalents!) {
      for (final entry in mealEq.equivalents.entries) {
        aggregated[entry.key] = (aggregated[entry.key] ?? 0) + entry.value;
      }
    }
    setState(() {
      _equivalentsByGroup = aggregated;
    });
  }

  @override
  Future<void> saveIfDirty() async {
    if (!_isDirty) return;
    setState(() => _isDirty = false);
  }

  @override
  void resetDrafts() {
    _initializeFromPlan();
    setState(() => _isDirty = false);
  }

  void _updateEquivalent(String groupId, double delta) {
    setState(() {
      _equivalentsByGroup[groupId] =
          (_equivalentsByGroup[groupId] ?? 0) + delta;
      if (_equivalentsByGroup[groupId]! <= 0) {
        _equivalentsByGroup.remove(groupId);
      }
      _isDirty = true;
    });
  }

  void _addNewGroup(String groupId) {
    setState(() {
      _equivalentsByGroup[groupId] = 1.0;
      _isDirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final client = ref.watch(clientsProvider).value?.activeClient;
    final planResult = ref.watch(nutritionPlanResultProvider);

    if (client == null || planResult == null) {
      return _buildEmptyState();
    }

    final totals = _calculateTotals();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(planResult),
            const SizedBox(height: 24),
            _buildSMAETable(planResult, totals),
            const SizedBox(height: 16),
            _buildTotalsSection(planResult, totals),
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
            Icons.table_chart_outlined,
            size: 80,
            color: kTextColorSecondary.withValues(alpha: 0.5),
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
            'Ve a "Gasto Energetico" y "Macronutrientes"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kTextColorSecondary),
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
            const Color(0xFFD32F2F).withValues(alpha: 0.15),
            kCardColor.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart, color: Color(0xFFD32F2F), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIETOCALCULO DEL PLAN DE ALIMENTACION',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sistema Mexicano de Alimentos Equivalentes',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextColorSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildTargetChip(
                'Objetivo',
                '${planResult.kcalTargetDay.toStringAsFixed(0)} kcal',
                Colors.orange,
              ),
              _buildTargetChip(
                'Proteina',
                '${planResult.proteinTargetDay.toStringAsFixed(0)}g',
                Colors.blue,
              ),
              _buildTargetChip(
                'Lipidos',
                '${planResult.fatTargetDay.toStringAsFixed(0)}g',
                Colors.purple,
              ),
              _buildTargetChip(
                'H. Carbono',
                '${planResult.carbTargetDay.toStringAsFixed(0)}g',
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSMAETable(planResult, Map<String, double> totals) {
    final sortedGroups = _equivalentsByGroup.keys.toList()
      ..sort((a, b) => _getGroupOrder(a).compareTo(_getGroupOrder(b)));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          if (sortedGroups.isEmpty)
            _buildEmptyTableState()
          else
            ...sortedGroups.map((groupId) => _buildGroupRow(groupId)),
          _buildAddGroupButton(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: _HeaderCell('Grupo en el Sistema de Equivalentes'),
          ),
          Expanded(flex: 2, child: _HeaderCell('Subgrupos')),
          Expanded(child: _HeaderCell('Equiv.')),
          Expanded(child: _HeaderCell('Energia\n(kcal)')),
          Expanded(child: _HeaderCell('Proteina\n(g)')),
          Expanded(child: _HeaderCell('Lipidos\n(g)')),
          Expanded(child: _HeaderCell('H.C.\n(g)')),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyTableState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          'Sin grupos agregados. Presiona el boton de abajo para agregar.',
          style: TextStyle(
            color: kTextColorSecondary.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGroupRow(String groupId) {
    final def = EquivalentCatalog.v1Definitions.firstWhere(
      (d) => d.id == groupId,
      orElse: () => EquivalentCatalog.v1Definitions.first,
    );
    final qty = _equivalentsByGroup[groupId] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _getGroupBackgroundColor(def.group),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _getGroupMainLabel(def.group),
              style: const TextStyle(
                fontSize: 13,
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getSubgroupLabel(def.subgroup),
              style: const TextStyle(fontSize: 12, color: kTextColorSecondary),
            ),
          ),
          Expanded(
            child: _buildEquivalentCounter(groupId, qty),
          ),
          Expanded(
            child: _buildValueCell((def.kcal * qty).toStringAsFixed(0)),
          ),
          Expanded(
            child: _buildValueCell((def.proteinG * qty).toStringAsFixed(1)),
          ),
          Expanded(
            child: _buildValueCell((def.fatG * qty).toStringAsFixed(1)),
          ),
          Expanded(
            child: _buildValueCell((def.carbG * qty).toStringAsFixed(1)),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red.withValues(alpha: 0.7),
              onPressed: () {
                setState(() {
                  _equivalentsByGroup.remove(groupId);
                  _isDirty = true;
                });
              },
              tooltip: 'Eliminar grupo',
            ),
          ),
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
          onTap: current > 0.5 ? () => _updateEquivalent(groupId, -0.5) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: current > 0.5
                  ? kPrimaryColor
                  : kTextColorSecondary.withValues(alpha: 0.3),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 45),
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
        InkWell(
          onTap: () => _updateEquivalent(groupId, 0.5),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueCell(String value) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: kTextColor),
    );
  }

  Widget _buildAddGroupButton() {
    return InkWell(
      onTap: _showAddGroupDialog,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.1),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 18, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              'Agregar Grupo de Alimentos',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection(planResult, Map<String, double> totals) {
    final kcalDiff = totals['kcal']! - planResult.kcalTargetDay;
    final protDiff = totals['protein']! - planResult.proteinTargetDay;
    final fatDiff = totals['fat']! - planResult.fatTargetDay;
    final carbDiff = totals['carb']! - planResult.carbTargetDay;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9800).withValues(alpha: 0.15),
            kCardColor.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 5,
                child: Text(
                  'Suma de los gramos totales y Energia total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF9800),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: _buildTotalCell(totals['kcal']!.toStringAsFixed(0)),
              ),
              Expanded(
                child: _buildTotalCell(totals['protein']!.toStringAsFixed(1)),
              ),
              Expanded(
                child: _buildTotalCell(totals['fat']!.toStringAsFixed(1)),
              ),
              Expanded(
                child: _buildTotalCell(totals['carb']!.toStringAsFixed(1)),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                flex: 5,
                child: Text(
                  'Energia y gramos faltantes para el Plan Alimenticio',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: _buildDiffCell(kcalDiff)),
              Expanded(child: _buildDiffCell(protDiff)),
              Expanded(child: _buildDiffCell(fatDiff)),
              Expanded(child: _buildDiffCell(carbDiff)),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCell(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: kTextColor,
        ),
      ),
    );
  }

  Widget _buildDiffCell(double diff) {
    final color = diff.abs() < 10
        ? Colors.green
        : diff > 0
            ? Colors.orange
            : Colors.red;
    return Text(
      diff > 0 ? '+${diff.toStringAsFixed(0)}' : diff.toStringAsFixed(0),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasEquivalents = _equivalentsByGroup.isNotEmpty;

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
            onPressed: hasEquivalents
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Guardado. Proximo: Distribucion por Comidas',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Guardar y Distribuir por Comidas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              disabledBackgroundColor: kTextColorSecondary.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddGroupDialog() {
    final available = EquivalentCatalog.v1Definitions
        .where((def) => !_equivalentsByGroup.containsKey(def.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya agregaste todos los grupos disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: kPrimaryColor),
              SizedBox(width: 8),
              Text(
                'Agregar Grupo',
                style: TextStyle(color: kTextColor),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (context, index) {
                final def = available[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getGroupColor(def.group).withValues(alpha: 0.2),
                    child: Icon(
                      _getGroupIcon(def.group),
                      color: _getGroupColor(def.group),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _getGroupMainLabel(def.group),
                    style: const TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${_getSubgroupLabel(def.subgroup)} • '
                    'P:${def.proteinG}g C:${def.carbG}g G:${def.fatG}g • ${def.kcal}kcal',
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    _addNewGroup(def.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Map<String, double> _calculateTotals() {
    double kcal = 0;
    double protein = 0;
    double fat = 0;
    double carb = 0;
    for (final entry in _equivalentsByGroup.entries) {
      final def = EquivalentCatalog.v1Definitions.firstWhere(
        (d) => d.id == entry.key,
        orElse: () => EquivalentCatalog.v1Definitions.first,
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
      'verdura': 0,
      'verdura_standard': 0,
      'fruta': 1,
      'fruta_standard': 1,
      'cereal_sin_grasa': 2,
      'cereales_sin_grasa': 2,
      'cereal_con_grasa': 3,
      'cereales_con_grasa': 3,
      'leguminosa': 4,
      'aoa_bajo_grasa': 5,
      'aoa_medio_grasa': 6,
      'aoa_alto_grasa': 7,
      'leche_descremada': 8,
      'leche_semidescremada': 9,
      'leche_entera': 10,
      'lacteo_descremado': 8,
      'lacteo_completo': 10,
      'aceite_sin_proteina': 11,
      'aceite_con_proteina': 12,
      'grasa_standard': 11,
      'azucar_sin_grasa': 13,
    };
    return order[groupId] ?? 99;
  }

  Color _getGroupBackgroundColor(String group) {
    const colors = {
      'verduras': Color(0xFF4CAF50),
      'frutas': Color(0xFFFFC107),
      'cereales': Color(0xFF795548),
      'leguminosas': Color(0xFF8BC34A),
      'alimentos_origen_animal': Color(0xFF90CAF9),
      'leche': Color(0xFFE0E0E0),
      'lacteos': Color(0xFFE0E0E0),
      'grasas': Color(0xFFFFC107),
      'azucares': Color(0xFF90CAF9),
    };
    return (colors[group] ?? kCardColor).withValues(alpha: 0.12);
  }

  Color _getGroupColor(String group) {
    const colors = {
      'verduras': Color(0xFF4CAF50),
      'frutas': Color(0xFFFFC107),
      'cereales': Color(0xFF795548),
      'leguminosas': Color(0xFF8BC34A),
      'alimentos_origen_animal': Color(0xFF90CAF9),
      'leche': Color(0xFFE0E0E0),
      'lacteos': Color(0xFFE0E0E0),
      'grasas': Color(0xFFFFC107),
      'azucares': Color(0xFF90CAF9),
    };
    return colors[group] ?? kPrimaryColor;
  }

  IconData _getGroupIcon(String group) {
    const icons = {
      'verduras': Icons.spa,
      'frutas': Icons.apple,
      'cereales': Icons.rice_bowl,
      'leguminosas': Icons.grain,
      'alimentos_origen_animal': Icons.egg,
      'leche': Icons.local_drink,
      'lacteos': Icons.local_drink,
      'grasas': Icons.water_drop,
      'azucares': Icons.cookie,
    };
    return icons[group] ?? Icons.restaurant;
  }

  String _getGroupMainLabel(String group) {
    const labels = {
      'verduras': 'Verduras',
      'frutas': 'Frutas',
      'cereales': 'Cereales y tuberculos',
      'leguminosas': 'Leguminosas',
      'alimentos_origen_animal': 'Alimentos de origen animal',
      'leche': 'Leche',
      'lacteos': 'Lacteos',
      'grasas': 'Aceites y Grasas',
      'azucares': 'Azucares',
    };
    return labels[group] ?? group;
  }

  String _getSubgroupLabel(String subgroup) {
    const labels = {
      'sin_grasa': 'Sin grasa',
      'con_grasa': 'Con grasa',
      'bajo_aporte_grasa': 'Muy bajo aporte de grasa',
      'medio_aporte_grasa': 'Bajo aporte de grasa',
      'alto_aporte_grasa': 'Moderado aporte de grasa',
      'descremado': 'Descremado',
      'semidescremado': 'Semidescremado',
      'completo': 'Entero',
      '': '',
    };
    return labels[subgroup] ?? subgroup;
  }
}

typedef EquivalentsGeneralScreenState = _EquivalentsGeneralScreenState;

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: kTextColor,
      ),
    );
  }
}
