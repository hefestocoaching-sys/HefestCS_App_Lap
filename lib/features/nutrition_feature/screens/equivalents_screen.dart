import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';

/// Pantalla única con 2 tabs: Equivalentes Generales + Distribución por Comidas
class EquivalentsScreen extends ConsumerStatefulWidget {
  const EquivalentsScreen({super.key});

  @override
  ConsumerState<EquivalentsScreen> createState() => _EquivalentsScreenState();
}

class _EquivalentsScreenState extends ConsumerState<EquivalentsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin
    implements SaveableModule {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  // Tab 1: Equivalentes Generales
  late Map<String, double> _equivalentsByGroup;
  bool _isGeneralDirty = false;

  // Tab 2: Distribución por Comidas
  late Map<String, Map<int, double>> _equivalentsByMealAndGroup;
  bool _isMealsDirty = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _equivalentsByGroup = {};
    _equivalentsByMealAndGroup = {};

    final planResult = ref.read(nutritionPlanResultProvider);
    if (planResult == null) return;

    // Tab 1: Agregar equivalentes generales
    if (planResult.mealEquivalents != null) {
      final aggregated = <String, double>{};
      for (final mealEq in planResult.mealEquivalents!) {
        for (final entry in mealEq.equivalents.entries) {
          aggregated[entry.key] = (aggregated[entry.key] ?? 0) + entry.value;
        }
      }
      _equivalentsByGroup = aggregated;
    }

    // Tab 2: Inicializar matriz por comidas
    int mealsPerDay = planResult.mealsPerDay ?? 3;
    for (var def in EquivalentCatalog.v1Definitions) {
      _equivalentsByMealAndGroup[def.id] = {};
      for (int mealIdx = 0; mealIdx < mealsPerDay; mealIdx++) {
        _equivalentsByMealAndGroup[def.id]![mealIdx] = 0.0;
      }
    }

    // Cargar desde nutritionPlan.mealEquivalents
    if (planResult.mealEquivalents != null) {
      for (
        int mealIdx = 0;
        mealIdx < planResult.mealEquivalents!.length;
        mealIdx++
      ) {
        final mealEq = planResult.mealEquivalents![mealIdx];
        for (var def in EquivalentCatalog.v1Definitions) {
          if (mealEq.equivalents.containsKey(def.id)) {
            _equivalentsByMealAndGroup[def.id]![mealIdx] =
                (mealEq.equivalents[def.id] ?? 0.0).toDouble();
          }
        }
      }
    }
  }

  @override
  Future<void> saveIfDirty() async {
    if (!_isGeneralDirty && !_isMealsDirty) return;

    setState(() {
      _isGeneralDirty = false;
      _isMealsDirty = false;
    });
  }

  @override
  void resetDrafts() {
    _initializeData();
    setState(() {
      _isGeneralDirty = false;
      _isMealsDirty = false;
    });
  }

  Map<String, double> _calculateGeneralTotals() {
    double kcal = 0, protein = 0, fat = 0, carbs = 0;
    for (final def in EquivalentCatalog.v1Definitions) {
      final count = _equivalentsByGroup[def.id] ?? 0.0;
      kcal += def.kcal * count;
      protein += def.proteinG * count;
      fat += def.fatG * count;
      carbs += def.carbG * count;
    }
    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carbs': carbs};
  }

  Map<String, double> _calculateMealMacros(int mealIdx) {
    double kcal = 0, protein = 0, fat = 0, carbs = 0;
    for (var def in EquivalentCatalog.v1Definitions) {
      final count = _equivalentsByMealAndGroup[def.id]?[mealIdx] ?? 0.0;
      kcal += def.kcal * count;
      protein += def.proteinG * count;
      fat += def.fatG * count;
      carbs += def.carbG * count;
    }
    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carbs': carbs};
  }

  Color _getGroupColor(String groupId) {
    final groupColors = {
      'aoa_bajo_grasa': Colors.purple.withValues(alpha: 0.15),
      'aoa_medio_grasa': Colors.purple.withValues(alpha: 0.25),
      'aoa_alto_grasa': Colors.purple.withValues(alpha: 0.35),
      'cereal_sin_grasa': Colors.amber.withValues(alpha: 0.15),
      'cereal_con_grasa': Colors.amber.withValues(alpha: 0.25),
      'fruta_standard': Colors.yellow.withValues(alpha: 0.15),
      'verdura_standard': Colors.green.withValues(alpha: 0.15),
      'leguminosa_standard': Colors.red.withValues(alpha: 0.15),
      'grasa_standard': Colors.orange.withValues(alpha: 0.15),
    };
    return groupColors[groupId] ?? Colors.grey.withValues(alpha: 0.1);
  }

  String _getGroupLabel(String groupId) {
    final groupLabels = {
      'aoa_bajo_grasa': 'AOA Bajo Grasa',
      'aoa_medio_grasa': 'AOA Medio Grasa',
      'aoa_alto_grasa': 'AOA Alto Grasa',
      'cereal_sin_grasa': 'Cereal Sin Grasa',
      'cereal_con_grasa': 'Cereal Con Grasa',
      'fruta_standard': 'Frutas',
      'verdura_standard': 'Verduras',
      'leguminosa_standard': 'Leguminosas',
      'grasa_standard': 'Grasas',
    };
    return groupLabels[groupId] ?? groupId;
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: EQUIVALENTES GENERALES
  // ─────────────────────────────────────────────────────────────
  Widget _buildGeneralTab() {
    final planResult = ref.watch(nutritionPlanResultProvider);
    final totals = _calculateGeneralTotals();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header: Targets
          Container(
            color: Colors.red.shade900,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAN DE ALIMENTACIÓN - EQUIVALENTES DIARIOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTargetCard(
                      'KCAL',
                      '${planResult?.kcalTargetDay?.toStringAsFixed(0) ?? '—'}',
                      Colors.white,
                    ),
                    _buildTargetCard(
                      'PROTEÍNA',
                      '${planResult?.proteinTargetDay?.toStringAsFixed(1) ?? '—'}g',
                      Colors.white,
                    ),
                    _buildTargetCard(
                      'GRASAS',
                      '${planResult?.fatTargetDay?.toStringAsFixed(1) ?? '—'}g',
                      Colors.white,
                    ),
                    _buildTargetCard(
                      'CARBOS',
                      '${planResult?.carbTargetDay?.toStringAsFixed(1) ?? '—'}g',
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabla de grupos SMAE
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FractionColumnWidth(0.4),
                1: FractionColumnWidth(0.15),
                2: FractionColumnWidth(0.15),
                3: FractionColumnWidth(0.15),
                4: FractionColumnWidth(0.15),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Grupo SMAE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          'Equiv.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: null,
                        ),
                      ),
                    ),
                    const SizedBox(),
                  ],
                ),
                // Rows
                ...EquivalentCatalog.v1Definitions.map((def) {
                  final count = _equivalentsByGroup[def.id] ?? 0.0;
                  return TableRow(
                    decoration: BoxDecoration(color: _getGroupColor(def.id)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_getGroupLabel(def.id)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            count.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _equivalentsByGroup[def.id] =
                                  (_equivalentsByGroup[def.id] ?? 0) - 1;
                              if (_equivalentsByGroup[def.id]! < 0) {
                                _equivalentsByGroup[def.id] = 0;
                              }
                              _isGeneralDirty = true;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          onPressed: () {
                            setState(() {
                              _equivalentsByGroup[def.id] =
                                  (_equivalentsByGroup[def.id] ?? 0) + 1;
                              _isGeneralDirty = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          // Totales
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTALES DIARIOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTotalCard(
                        'KCAL',
                        totals['kcal']?.toStringAsFixed(0) ?? '0',
                        planResult?.kcalTargetDay,
                      ),
                      _buildTotalCard(
                        'PROT',
                        totals['protein']?.toStringAsFixed(1) ?? '0',
                        planResult?.proteinTargetDay,
                      ),
                      _buildTotalCard(
                        'GRASAS',
                        totals['fat']?.toStringAsFixed(1) ?? '0',
                        planResult?.fatTargetDay,
                      ),
                      _buildTotalCard(
                        'CARBOS',
                        totals['carbs']?.toStringAsFixed(1) ?? '0',
                        planResult?.carbTargetDay,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 2: DISTRIBUCIÓN POR COMIDAS
  // ─────────────────────────────────────────────────────────────
  Widget _buildMealsDistributionTab() {
    final planResult = ref.watch(nutritionPlanResultProvider);
    final mealsPerDay = planResult?.mealsPerDay ?? 3;

    final mealNames = ['Desayuno', 'Almuerzo', 'Comida', 'Merienda', 'Cena'];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header: Targets
          Container(
            color: Colors.green.shade900,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISTRIBUCIÓN POR COMIDAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Macro-objetivo por comida: ${(planResult?.kcalTargetDay ?? 0 / mealsPerDay).toStringAsFixed(0)} kcal',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),

          // Tabla matriz
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  // Header con nombres de comidas
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Grupo SMAE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...List.generate(
                        mealsPerDay,
                        (i) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              mealNames[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Rows de grupos
                  ...EquivalentCatalog.v1Definitions.map((def) {
                    return TableRow(
                      decoration: BoxDecoration(color: _getGroupColor(def.id)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: 100,
                            child: Text(
                              _getGroupLabel(def.id),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        ...List.generate(mealsPerDay, (mealIdx) {
                          final count =
                              _equivalentsByMealAndGroup[def.id]?[mealIdx] ??
                              0.0;
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: SizedBox(
                              width: 70,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 14,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              final newValue =
                                                  (_equivalentsByMealAndGroup[def
                                                          .id]![mealIdx] ??
                                                      0) -
                                                  1;
                                              _equivalentsByMealAndGroup[def
                                                  .id]![mealIdx] = newValue < 0
                                                  ? 0
                                                  : newValue;
                                              _isMealsDirty = true;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          count.toStringAsFixed(1),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 14,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              _equivalentsByMealAndGroup[def
                                                      .id]![mealIdx] =
                                                  (_equivalentsByMealAndGroup[def
                                                          .id]![mealIdx] ??
                                                      0) +
                                                  1;
                                              _isMealsDirty = true;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                  // Row de totales por comida
                  TableRow(
                    decoration: BoxDecoration(color: Colors.yellow.shade100),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'TOTAL COMIDA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      ...List.generate(mealsPerDay, (mealIdx) {
                        final macros = _calculateMealMacros(mealIdx);
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${macros['kcal']?.toStringAsFixed(0) ?? '0'} kcal',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${macros['protein']?.toStringAsFixed(1) ?? '0'}g P',
                                style: const TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widgets auxiliares
  Widget _buildTargetCard(String label, String value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(String label, String value, double? target) {
    final diff = (double.tryParse(value) ?? 0) - (target ?? 0);
    final color = diff < -10 ? Colors.orange : Colors.green;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (target != null)
          Text(
            '(${target.toStringAsFixed(0)})',
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Equivalentes SMAE'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'GENERALES'),
            Tab(text: 'POR COMIDAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGeneralTab(), _buildMealsDistributionTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Restablecer'),
              onPressed: resetDrafts,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: saveIfDirty,
            ),
          ],
        ),
      ),
    );
  }
}

typedef EquivalentsScreenState = _EquivalentsScreenState;
