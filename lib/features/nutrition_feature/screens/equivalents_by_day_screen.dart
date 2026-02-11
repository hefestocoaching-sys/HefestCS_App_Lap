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
  late final ProviderSubscription _clientSubscription;

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
    // Load equivalents when active client changes, outside build.
    _clientSubscription = ref.listenManual(clientsProvider, (previous, next) {
      final client = next.value?.activeClient;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(equivalentsByDayProvider.notifier).loadFromClient(client);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(clientsProvider).value?.activeClient;
      ref.read(equivalentsByDayProvider.notifier).loadFromClient(client);
    });
  }

  @override
  void dispose() {
    _clientSubscription.close();
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

    if (client == null || planResult == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
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
                  onSave: saveIfDirty,
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
        ],
      ),
    );
  }

  
}

typedef EquivalentsByDayScreenState = _EquivalentsByDayScreenState;
