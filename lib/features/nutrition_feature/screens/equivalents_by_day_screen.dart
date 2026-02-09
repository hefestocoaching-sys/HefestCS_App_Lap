import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/equivalents_by_day_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/day_equivalents_tab.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Pantalla de Equivalentes por Dia (indice 5)
/// Tabs: Lunes-Domingo, cada uno con sub-tabs: Generales | Distribucion
class EquivalentsByDayScreen extends ConsumerStatefulWidget {
  const EquivalentsByDayScreen({super.key});

  @override
  ConsumerState<EquivalentsByDayScreen> createState() =>
      _EquivalentsByDayScreenState();
}

class _EquivalentsByDayScreenState extends ConsumerState<EquivalentsByDayScreen>
    with SingleTickerProviderStateMixin
    implements SaveableModule {
  late TabController _tabController;

  final days = const [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<void> saveIfDirty() async {
    final state = ref.read(equivalentsByDayProvider);
    if (!state.isDirty) return;

    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final notifier = ref.read(equivalentsByDayProvider.notifier);
    final payload = notifier.toJson();

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final mergedExtra = Map<String, dynamic>.from(current.nutrition.extra);
      mergedExtra[NutritionExtraKeys.equivalentsByDay] = payload;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(extra: mergedExtra),
      );
    });

    notifier.markSaved();
  }

  @override
  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient;
    ref
        .read(equivalentsByDayProvider.notifier)
        .loadFromClient(client, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientsProvider).value?.activeClient;
    final planResult = ref.watch(nutritionPlanResultProvider);

    if (client != null) {
      ref.read(equivalentsByDayProvider.notifier).loadFromClient(client);
    }

    if (client == null || planResult == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(planResult),
          TabBar(
            controller: _tabController,
            labelColor: kPrimaryColor,
            unselectedLabelColor: kTextColorSecondary,
            indicatorColor: kPrimaryColor,
            isScrollable: true,
            tabs: days.map((day) => Tab(text: day)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: days.map((day) {
                return DayEquivalentsTab(
                  dayKey: day.toLowerCase(),
                  dayLabel: day,
                  planResult: planResult,
                );
              }).toList(),
            ),
          ),
        ],
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
        ],
      ),
    );
  }

  Widget _buildHeader(planResult) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD32F2F).withOpacity(0.15),
            kCardColor.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD32F2F).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIETOCALCULO DEL PLAN DE ALIMENTACION',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistema Mexicano de Alimentos Equivalentes',
            style: TextStyle(
              fontSize: 13,
              color: kTextColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildChip(
                'Objetivo',
                '${planResult.kcalTargetDay.toStringAsFixed(0)} kcal/dia',
                Colors.orange,
              ),
              _buildChip(
                'Proteina',
                '${planResult.proteinTargetDay.toStringAsFixed(0)}g/dia',
                Colors.blue,
              ),
              _buildChip(
                'Lipidos',
                '${planResult.fatTargetDay.toStringAsFixed(0)}g/dia',
                Colors.purple,
              ),
              _buildChip(
                'H.C.',
                '${planResult.carbTargetDay.toStringAsFixed(0)}g/dia',
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
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
}

typedef EquivalentsByDayScreenState = _EquivalentsByDayScreenState;
