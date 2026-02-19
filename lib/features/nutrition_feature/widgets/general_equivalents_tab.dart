import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/general_equivalents_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/general_equivalents_table.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class GeneralEquivalentsTab extends ConsumerStatefulWidget {
  final int mealsPerDay;
  final Map<String, double>? targets;
  final Future<void> Function()? onSave;

  const GeneralEquivalentsTab({
    super.key,
    required this.mealsPerDay,
    this.targets,
    this.onSave,
  });

  @override
  ConsumerState<GeneralEquivalentsTab> createState() =>
      _GeneralEquivalentsTabState();
}

class _GeneralEquivalentsTabState extends ConsumerState<GeneralEquivalentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
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
          color: kCardColor.withValues(alpha: 0.3),
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
            children: [_buildGeneralTab(context), _buildMealsTab(context)],
          ),
        ),
      ],
    );
  }

  // ===========================================
  // GENERAL TAB (Master Table)
  // ===========================================

  Widget _buildGeneralTab(BuildContext context) {
    return Column(
      children: [
        Expanded(child: GeneralEquivalentsTable(targets: widget.targets)),
        // Save Button Area
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: widget.onSave == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await widget.onSave?.call();
                    ref.read(generalEquivalentsProvider.notifier).markSaved();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Plan General Guardado')),
                    );
                  },
            icon: const Icon(Icons.save),
            label: const Text('Guardar Plan General'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================
  // MEALS TAB (Accordion)
  // ===========================================

  Widget _buildMealsTab(BuildContext context) {
    final state = ref.watch(generalEquivalentsProvider);
    final allGroups = EquivalentCatalog.v1Definitions
        .where((d) => (state.equivalents[d.id] ?? 0) > 0)
        .toList();

    if (allGroups.isEmpty) {
      return const Center(
        child: Text('Agrega equivalentes en la pestaña General primero.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.mealsPerDay,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMealTile(index, allGroups, state),
        );
      },
    );
  }

  Widget _buildMealTile(
    int mealIdx,
    List<EquivalentDefinition> activeGroups,
    GeneralEquivalentsState state,
  ) {
    final mealKcal = activeGroups.fold<double>(0, (sum, def) {
      final qty = state.mealEquivalents[def.id]?[mealIdx] ?? 0;
      return sum + (def.kcal * qty);
    });

    return ExpansionTile(
      collapsedBackgroundColor: kCardColor.withValues(alpha: 0.2),
      backgroundColor: kCardColor.withValues(alpha: 0.25),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text('Comida ${mealIdx + 1}'),
      subtitle: Text(
        '${mealKcal.toStringAsFixed(0)} kcal',
        style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: activeGroups.map((def) {
              final currentInMeal =
                  state.mealEquivalents[def.id]?[mealIdx] ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatGroupId(def.id),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: currentInMeal >= 0.5
                        ? () => ref
                              .read(generalEquivalentsProvider.notifier)
                              .updateMealEquivalent(def.id, mealIdx, -0.5)
                        : null,
                  ),
                  Text(
                    currentInMeal.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    // Allow adding only? Typically we should let them go crazy and warn later, or cap it.
                    // Let's uncap for flexibility, user requested smart logic but manual override is key.
                    onPressed: () => ref
                        .read(generalEquivalentsProvider.notifier)
                        .updateMealEquivalent(def.id, mealIdx, 0.5),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helpers

  String _formatGroupId(String id) {
    return id.replaceAll('_', ' ').toUpperCase();
  }
}
