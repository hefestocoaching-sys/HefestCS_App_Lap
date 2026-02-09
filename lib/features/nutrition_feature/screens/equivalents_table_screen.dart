import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/core/models/equivalent_definition.dart';
import 'package:hcs_app_lap/core/models/meal_equivalent.dart';
import 'package:hcs_app_lap/features/clients/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/nutrition_plan_result.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_provider.dart';
import 'package:hcs_app_lap/shared/widgets/saveable_module.dart';

class EquivalentsTableScreen extends ConsumerStatefulWidget {
  const EquivalentsTableScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EquivalentsTableScreen> createState() =>
      _EquivalentsTableScreenState();
}

class _EquivalentsTableScreenState extends ConsumerState<EquivalentsTableScreen>
    with TickerProviderStateMixin
    implements SaveableModule {
  late TabController _tabController;

  // Tab 1: General equivalents (aggregate daily totals)
  late Map<String, double> _generalEquivalents;

  // Tab 2: Distribution by meals (matrix: groups × meal times)
  late Map<String, Map<int, double>> _equivalentsByMealAndGroup;

  // Track dirty state for each tab
  bool _isGeneralDirty = false;
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
    // Initialize from current nutrition plan
    _generalEquivalents = {};
    _equivalentsByMealAndGroup = {};

    // Initialize with zeros for all groups
    for (var def in EquivalentCatalog.v1Definitions) {
      _generalEquivalents[def.groupId] = 0.0;
    }

    final nutritionPlan = ref.read(nutritionPlanResultProvider);
    if (nutritionPlan != null) {
      // Load general equivalents from extra data
      final clientId = ref.read(clientsProvider).activeClientId;
      if (clientId != null) {
        final client = ref.read(clientsProvider).clients[clientId];
        if (client != null) {
          final extraData = client.nutrition?.extra ?? {};
          final savedEquivalents =
              extraData[NutritionExtraKeys.equivalentsByDay] as Map?;
          if (savedEquivalents != null) {
            for (var entry in savedEquivalents.entries) {
              _generalEquivalents[entry.key] = (entry.value as num).toDouble();
            }
          }
        }
      }

      // Initialize meals matrix from nutritionPlan.mealEquivalents if available
      int mealsPerDay = nutritionPlan.mealsPerDay ?? 3;
      for (var def in EquivalentCatalog.v1Definitions) {
        _equivalentsByMealAndGroup[def.groupId] = {};
        for (int mealIdx = 0; mealIdx < mealsPerDay; mealIdx++) {
          _equivalentsByMealAndGroup[def.groupId]![mealIdx] = 0.0;
        }
      }

      // Load from nutritionPlan.mealEquivalents if available
      if (nutritionPlan.mealEquivalents != null) {
        for (int mealIdx = 0;
            mealIdx < nutritionPlan.mealEquivalents!.length;
            mealIdx++) {
          final mealEquiv = nutritionPlan.mealEquivalents![mealIdx];
          for (var def in EquivalentCatalog.v1Definitions) {
            if (mealEquiv.equivalentsByGroup.containsKey(def.groupId)) {
              _equivalentsByMealAndGroup[def.groupId]![mealIdx] =
                  (mealEquiv.equivalentsByGroup[def.groupId] ?? 0.0)
                      .toDouble();
            }
          }
        }
      }
    }
  }

  // Save current state to client
  @override
  Future<void> saveIfDirty() async {
    if (!_isGeneralDirty && !_isMealsDirty) return;

    final clientId = ref.read(clientsProvider).activeClientId;
    if (clientId == null) return;

    final clientsNotifier = ref.read(clientsProvider.notifier);
    final currentClient = ref.read(clientsProvider).clients[clientId];
    if (currentClient == null) return;

    // Prepare extra data updates
    final extraUpdates = <String, dynamic>{
      NutritionExtraKeys.equivalentsByDay: _generalEquivalents,
    };

    await clientsNotifier.updateActiveClient(
      nutrition: (currentClient.nutrition ?? NutritionProfile()).copyWith(
        extra: {...?currentClient.nutrition?.extra, ...extraUpdates},
      ),
    );

    _isGeneralDirty = false;
    _isMealsDirty = false;
  }

  // Reset drafts
  @override
  Future<void> resetDrafts() async {
    _initializeData();
    _isGeneralDirty = false;
    _isMealsDirty = false;
    if (mounted) {
      setState(() {});
    }
  }

  // Calculate daily totals from general equivalents
  Map<String, double> _calculateGeneralTotals() {
    Map<String, double> totals = {
      'kcal': 0.0,
      'protein': 0.0,
      'fat': 0.0,
      'carbs': 0.0,
    };

    for (var def in EquivalentCatalog.v1Definitions) {
      final count = _generalEquivalents[def.groupId] ?? 0.0;
      totals['kcal'] = (totals['kcal'] ?? 0.0) + (def.kcalPerEquivalent * count);
      totals['protein'] =
          (totals['protein'] ?? 0.0) + (def.proteinPerEquivalent * count);
      totals['fat'] = (totals['fat'] ?? 0.0) + (def.fatPerEquivalent * count);
      totals['carbs'] =
          (totals['carbs'] ?? 0.0) + (def.carbsPerEquivalent * count);
    }

    return totals;
  }

  // Calculate meal macros for a specific meal
  Map<String, double> _calculateMealMacros(int mealIdx) {
    Map<String, double> totals = {
      'kcal': 0.0,
      'protein': 0.0,
      'fat': 0.0,
      'carbs': 0.0,
    };

    for (var def in EquivalentCatalog.v1Definitions) {
      final count = _equivalentsByMealAndGroup[def.groupId]?[mealIdx] ?? 0.0;
      totals['kcal'] = (totals['kcal'] ?? 0.0) + (def.kcalPerEquivalent * count);
      totals['protein'] =
          (totals['protein'] ?? 0.0) + (def.proteinPerEquivalent * count);
      totals['fat'] = (totals['fat'] ?? 0.0) + (def.fatPerEquivalent * count);
      totals['carbs'] =
          (totals['carbs'] ?? 0.0) + (def.carbsPerEquivalent * count);
    }

    return totals;
  }

  // Get color for SMAE group
  Color _getGroupColor(String groupId) {
    final groupColors = {
      'verduras': Colors.green.shade100,
      'frutas': Colors.yellow.shade100,
      'cereales': Colors.amber.shade100,
      'leguminosas': Colors.red.shade100,
      'alimentos_origen_animal': Colors.purple.shade100,
      'grasas': Colors.orange.shade100,
      'azucares': Colors.pink.shade100,
      'bebidas': Colors.blue.shade100,
      'productos_lacteos': Colors.indigo.shade100,
      'preparados': Colors.teal.shade100,
      'alimentos_preparados': Colors.cyan.shade100,
      'condimentos': Colors.brown.shade100,
      'alimentos_libres': Colors.grey.shade100,
      'suplementos': Colors.blueGrey.shade100,
    };
    return groupColors[groupId] ?? Colors.grey.shade100;
  }

  // Build Tab 1: General Equivalents
  Widget _buildGeneralTab() {
    final nutritionPlan = ref.watch(nutritionPlanResultProvider);
    final targets = nutritionPlan;

    final totals = _calculateGeneralTotals();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with targets
          Container(
            color: Colors.red.shade900,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIETOCALCULO DEL PLAN DE ALIMENTACION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTargetInfo(
                        'KCAL',
                        '${targets?.kcalTargetDay?.toStringAsFixed(0) ?? 'N/A'}',
                        Colors.white),
                    _buildTargetInfo(
                        'PROT',
                        '${targets?.proteinTargetDay?.toStringAsFixed(1) ?? 'N/A'}g',
                        Colors.white),
                    _buildTargetInfo(
                        'GRASAS',
                        '${targets?.fatTargetDay?.toStringAsFixed(1) ?? 'N/A'}g',
                        Colors.white),
                    _buildTargetInfo(
                        'CARBS',
                        '${targets?.carbsTargetDay?.toStringAsFixed(1) ?? 'N/A'}g',
                        Colors.white),
                  ],
                ),
              ],
            ),
          ),
          // SMAE Table
          Padding(
            padding: EdgeInsets.all(16),
            child: Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FractionColumnWidth(0.35),
                1: FractionColumnWidth(0.15),
                2: FractionColumnWidth(0.15),
                3: FractionColumnWidth(0.15),
                4: FractionColumnWidth(0.2),
              },
              children: [
                // Table header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade300),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Grupo SMAE',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text('Equiv',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text('−',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text('+',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text('Acciones',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                // Table rows for each SMAE group
                ...EquivalentCatalog.v1Definitions.map((def) {
                  final count = _generalEquivalents[def.groupId] ?? 0.0;
                  return TableRow(
                    decoration:
                        BoxDecoration(color: _getGroupColor(def.groupId)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(def.groupLabel ?? 'Grupo ${def.groupId}'),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(count.toStringAsFixed(1)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          iconSize: 20,
                          onPressed: () {
                            setState(() {
                              _generalEquivalents[def.groupId] =
                                  (_generalEquivalents[def.groupId] ?? 0.0) - 1;
                              if (_generalEquivalents[def.groupId]! < 0) {
                                _generalEquivalents[def.groupId] = 0.0;
                              }
                              _isGeneralDirty = true;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          iconSize: 20,
                          onPressed: () {
                            setState(() {
                              _generalEquivalents[def.groupId] =
                                  (_generalEquivalents[def.groupId] ?? 0.0) + 1;
                              _isGeneralDirty = true;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(4),
                        child: Center(
                          child: Icon(Icons.more_vert, size: 16),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          // Totals Section
          Container(
            color: Colors.blue.shade50,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('TOTALES GENERALES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTotalInfo('KCAL', totals['kcal']?.toStringAsFixed(0),
                        targets?.kcalTargetDay),
                    _buildTotalInfo('PROT', totals['protein']?.toStringAsFixed(1),
                        targets?.proteinTargetDay),
                    _buildTotalInfo('GRASAS', totals['fat']?.toStringAsFixed(1),
                        targets?.fatTargetDay),
                    _buildTotalInfo('CARBS', totals['carbs']?.toStringAsFixed(1),
                        targets?.carbsTargetDay),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Tab 2: Distribution by Meals
  Widget _buildMealsTab() {
    final nutritionPlan = ref.watch(nutritionPlanResultProvider);
    final mealsPerDay = nutritionPlan?.mealsPerDay ?? 3;
    final targets = nutritionPlan;

    // Calculate meal names
    List<String> mealNames = [
      'Desayuno',
      'Almuerzo',
      'Comida',
      'Merienda',
      'Cena',
      'Postres',
      'Bebidas',
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with targets
          Container(
            color: Colors.red.shade900,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIETOCALCULO DEL PLAN DE ALIMENTACION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTargetInfo(
                        'KCAL',
                        '${targets?.kcalTargetDay?.toStringAsFixed(0) ?? 'N/A'}',
                        Colors.white),
                    _buildTargetInfo(
                        'PROT',
                        '${targets?.proteinTargetDay?.toStringAsFixed(1) ?? 'N/A'}g',
                        Colors.white),
                    _buildTargetInfo(
                        'GRASAS',
                        '${targets?.fatTargetDay?.toStringAsFixed(1) ?? 'N/A'}g',
                        Colors.white),
                    _buildTargetInfo(
                        'CARBS',
                        '${targets?.carbsTargetDay?.toStringAsFixed(1) ?? 'N/A'}g',
                        Colors.white),
                  ],
                ),
              ],
            ),
          ),
          // Meals Matrix
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(),
                children: [
                  // Header row with meal names
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade300),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Grupo SMAE',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...List.generate(
                        mealsPerDay,
                        (idx) => Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: Text(mealNames[idx],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Group rows
                  ...EquivalentCatalog.v1Definitions.map((def) {
                    return TableRow(
                      decoration:
                          BoxDecoration(color: _getGroupColor(def.groupId)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(def.groupLabel ?? 'Grupo ${def.groupId}'),
                        ),
                        ...List.generate(
                          mealsPerDay,
                          (mealIdx) {
                            final count =
                                _equivalentsByMealAndGroup[def.groupId]
                                    ?[mealIdx] ??
                                0.0;
                            return Padding(
                              padding: EdgeInsets.all(4),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          child: IconButton(
                                            icon:
                                                Icon(Icons.remove_circle_outline),
                                            iconSize: 16,
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setState(() {
                                                _equivalentsByMealAndGroup[def
                                                        .groupId]![mealIdx] =
                                                    (_equivalentsByMealAndGroup[
                                                                def.groupId]![
                                                            mealIdx] ??
                                                        0.0) -
                                                    1;
                                                if (_equivalentsByMealAndGroup[
                                                        def.groupId]![mealIdx] <
                                                    0) {
                                                  _equivalentsByMealAndGroup[def
                                                      .groupId]![mealIdx] = 0.0;
                                                }
                                                _isMealsDirty = true;
                                              });
                                            },
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            count.toStringAsFixed(1),
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 24,
                                          child: IconButton(
                                            icon:
                                                Icon(Icons.add_circle_outline),
                                            iconSize: 16,
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setState(() {
                                                _equivalentsByMealAndGroup[def
                                                        .groupId]![mealIdx] =
                                                    (_equivalentsByMealAndGroup[
                                                                def.groupId]![
                                                            mealIdx] ??
                                                        0.0) +
                                                    1;
                                                _isMealsDirty = true;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  // Total row per meal
                  TableRow(
                    decoration: BoxDecoration(color: Colors.yellow.shade100),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('TOTAL',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...List.generate(
                        mealsPerDay,
                        (mealIdx) {
                          final mealMacros = _calculateMealMacros(mealIdx);
                          return Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    '${mealMacros['kcal']?.toStringAsFixed(0) ?? '0'} kcal',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                  ),
                                  Text(
                                    '${mealMacros['protein']?.toStringAsFixed(1) ?? '0'}g P',
                                    style: TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInfo(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildTotalInfo(String label, String? value, double? target) {
    final isDifference = (double.tryParse(value ?? '0') ?? 0) <
        (target ?? 0); // Simplified logic for color
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(value ?? '0',
            style: TextStyle(
              fontSize: 12,
              color: isDifference ? Colors.orange : Colors.green,
            )),
        if (target != null)
          Text('(t: ${target.toStringAsFixed(0)})',
              style: TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equivalentes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'EQUIVALENTES GENERALES'),
            Tab(text: 'DISTRIBUCION POR COMIDAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildMealsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Restablecer'),
              onPressed: () async {
                await resetDrafts();
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                await saveIfDirty();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Equivalentes guardados')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

typedef EquivalentsTableScreenState = _EquivalentsTableScreenState;
