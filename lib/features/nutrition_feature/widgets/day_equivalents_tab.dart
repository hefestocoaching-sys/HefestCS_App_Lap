import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/equivalents_by_day_provider.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Tab de equivalentes para un dia especifico
/// Contiene 2 sub-tabs: Equivalentes | Distribucion por Comidas
class DayEquivalentsTab extends ConsumerStatefulWidget {
  final String dayKey; // 'lunes', 'martes', etc.
  final String dayLabel; // 'Lunes', 'Martes', etc.
  final dynamic planResult;
  final Future<void> Function()? onSave;

  const DayEquivalentsTab({
    super.key,
    required this.dayKey,
    required this.dayLabel,
    required this.planResult,
    this.onSave,
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
    _ensureDaySetup();
  }

  @override
  void didUpdateWidget(covariant DayEquivalentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayKey != widget.dayKey ||
        oldWidget.planResult.mealsPerDay != widget.planResult.mealsPerDay) {
      _ensureDaySetup();
    }
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _ensureDaySetup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mealsCount = widget.planResult.mealsPerDay;
      final groupIds = EquivalentCatalog.v1Definitions
          .map((def) => def.id)
          .toList();
      final state = ref.read(equivalentsByDayProvider);
      final dayEquivalents = state.dayEquivalents[widget.dayKey];
      final dayMeals = state.dayMealEquivalents[widget.dayKey];
      final hasAllGroups = dayEquivalents != null &&
          groupIds.every(dayEquivalents.containsKey);
      final hasAllMeals = dayMeals != null &&
          groupIds.every((id) {
            final meals = dayMeals[id];
            if (meals == null) return false;
            for (var i = 0; i < mealsCount; i++) {
              if (!meals.containsKey(i)) return false;
            }
            return true;
          });
      if (hasAllGroups && hasAllMeals) return;
      ref
          .read(equivalentsByDayProvider.notifier)
          .ensureDay(widget.dayKey, mealsCount, groupIds);
    });
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
              Tab(text: 'Equivalentes'),
              Tab(text: 'Distribucion por Comidas'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildGeneralEquivalentsTab(context),
              _buildMealsDistributionTab(context),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // TAB 1: EQUIVALENTES GENERALES (COMPACTO + STICKY SUMMARY)
  // =====================================================================

  Widget _buildGeneralEquivalentsTab(BuildContext context) {
    final allGroups = _getAllSMAEGroups();
    final state = ref.watch(equivalentsByDayProvider);
    final dayEquivalents = state.dayEquivalents[widget.dayKey] ?? {};
    final totals = _calculateTotals(dayEquivalents);

    double kcalTarget = widget.planResult?.kcalTargetDay ?? 0.0;
    double proteinTarget = widget.planResult?.proteinTargetDay ?? 0.0;
    double fatTarget = widget.planResult?.fatTargetDay ?? 0.0;
    double carbTarget = widget.planResult?.carbTargetDay ?? 0.0;

    if (kcalTarget == 0 || proteinTarget == 0) {
      final client = ref.watch(clientsProvider).value?.activeClient;

      if (client != null) {
        final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));

        final macroRecords = readNutritionRecordList(
          client.nutrition.extra[NutritionExtraKeys.macrosRecords],
        );

        final macroRecord =
            nutritionRecordForDate(macroRecords, activeDateIso) ??
            latestNutritionRecordByDate(macroRecords);

        final activeMacros =
            parseWeeklyMacroSettings(macroRecord?['weeklyMacroSettings']);

        if (activeMacros != null) {
          final double weight = client.lastWeight ?? 70.0;

          final DailyMacroSettings? daySettings = activeMacros[widget.dayKey];

          if (daySettings != null) {
            proteinTarget = daySettings.proteinSelected * weight;
            fatTarget = daySettings.fatSelected * weight;
            carbTarget = daySettings.carbSelected * weight;

            kcalTarget = daySettings.totalCalories > 0
                ? daySettings.totalCalories
                : (proteinTarget * 4) +
                    (carbTarget * 4) +
                    (fatTarget * 9);
          }
        }
      }
    }

    if (kcalTarget == 0 && widget.planResult != null) {
      kcalTarget = widget.planResult.kcalTargetDay ?? 0.0;
      proteinTarget = widget.planResult.proteinTargetDay ?? 0.0;
      fatTarget = widget.planResult.fatTargetDay ?? 0.0;
      carbTarget = widget.planResult.carbTargetDay ?? 0.0;
    }

    final groupsWithValues = allGroups
        .where((group) => (dayEquivalents[group.id] ?? 0) > 0)
        .toList();
    final emptyGroups = allGroups
        .where((group) => (dayEquivalents[group.id] ?? 0) == 0)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SummaryHeaderDelegate(
            minHeight: 240,
            maxHeight: 240,
            child: _buildSummaryCard(
              context,
              totals,
              kcalTarget: kcalTarget,
              proteinTarget: proteinTarget,
              fatTarget: fatTarget,
              carbTarget: carbTarget,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (groupsWithValues.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'GRUPOS ASIGNADOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextColorSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        if (groupsWithValues.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final group = groupsWithValues[index];
              final qty = dayEquivalents[group.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildGroupCard(group, qty),
              );
            }, childCount: groupsWithValues.length),
          ),
        if (groupsWithValues.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEmptyGroupsCard(),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddGroupDialog(context, emptyGroups),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar Grupo de Alimentos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ),
        if (emptyGroups.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _buildEmptyGroupsExpansion(emptyGroups),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, double> totals, {
    required double kcalTarget,
    required double proteinTarget,
    required double fatTarget,
    required double carbTarget,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.14),
            kCardColor.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text(
                'RESUMEN DEL DIA: ${widget.dayLabel.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMacroProgressRow(
            label: 'Energia',
            current: totals['kcal'] ?? 0,
            target: kcalTarget,
            unit: 'kcal',
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressRow(
            label: 'Proteina',
            current: totals['protein'] ?? 0,
            target: proteinTarget,
            unit: 'g',
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressRow(
            label: 'Grasas',
            current: totals['fat'] ?? 0,
            target: fatTarget,
            unit: 'g',
            color: Colors.purple,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressRow(
            label: 'Carbos',
            current: totals['carb'] ?? 0,
            target: carbTarget,
            unit: 'g',
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCopyDayDialog(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar de otro dia'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _autoDistribute(context),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Distribucion auto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onSave == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await widget.onSave?.call();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Cambios guardados')),
                          );
                        },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressRow({
    required String label,
    required double current,
    required double target,
    required String unit,
    required Color color,
  }) {
    final progress = target <= 0 ? 0 : current / target;
    final percentage = (progress * 100).clamp(0, 200);
    final diff = current - target;
    final progressColor = percentage >= 90 && percentage <= 110
        ? Colors.green
        : percentage >= 80 && percentage <= 120
        ? Colors.orange
        : Colors.red;

    final diffText = diff.abs() < 1
        ? 'Objetivo alcanzado'
        : diff > 0
        ? 'Sobran ${diff.toStringAsFixed(0)}$unit'
        : 'Faltan ${diff.abs().toStringAsFixed(0)}$unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1).toDouble(),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          diffText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: progressColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(EquivalentDefinition def, double qty) {
    final kcal = def.kcal * qty;
    final protein = def.proteinG * qty;
    final fat = def.fatG * qty;
    final carb = def.carbG * qty;
    final groupColor = _getGroupColor(def.group);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _getGroupBackgroundColor(def.group),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: groupColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: groupColor.withValues(alpha: 0.2),
                child: Icon(Icons.restaurant, color: groupColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGroupMainLabel(def.group),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                      ),
                    ),
                    if (def.subgroup.isNotEmpty)
                      Text(
                        _getSubgroupLabel(def.subgroup),
                        style: const TextStyle(
                          fontSize: 11,
                          color: kTextColorSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: qty >= 0.5
                        ? () => ref
                              .read(equivalentsByDayProvider.notifier)
                              .updateEquivalent(widget.dayKey, def.id, -0.5)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.remove_circle_outline,
                        size: 22,
                        color: qty >= 0.5
                            ? kPrimaryColor
                            : kTextColorSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      qty.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => ref
                        .read(equivalentsByDayProvider.notifier)
                        .updateEquivalent(widget.dayKey, def.id, 0.5),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroChip('${kcal.toStringAsFixed(0)} kcal', Colors.orange),
              _buildMacroChip(
                '${protein.toStringAsFixed(1)}g prot',
                Colors.blue,
              ),
              _buildMacroChip('${carb.toStringAsFixed(1)}g HC', Colors.amber),
              _buildMacroChip(
                '${fat.toStringAsFixed(1)}g grasa',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyGroupsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kTextColorSecondary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: kTextColorSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay grupos asignados. Agrega grupos para empezar.',
              style: TextStyle(fontSize: 12, color: kTextColorSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupsExpansion(List<EquivalentDefinition> emptyGroups) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kTextColorSecondary.withValues(alpha: 0.15)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          'Grupos sin asignar (${emptyGroups.length})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextColorSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emptyGroups
                  .map(
                    (g) => Chip(
                      label: Text(
                        _getGroupMainLabel(g.group),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: kCardColor.withValues(alpha: 0.3),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // TAB 2: DISTRIBUCION POR COMIDAS (ACORDEON)
  // =====================================================================

  Widget _buildMealsDistributionTab(BuildContext context) {
    final allGroups = _getAllSMAEGroups();
    final mealsCount = widget.planResult.mealsPerDay;
    final state = ref.watch(equivalentsByDayProvider);
    final dayMeals = state.dayMealEquivalents[widget.dayKey] ?? {};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: mealsCount,
      itemBuilder: (context, index) {
        final mealTotals = _calculateMealTotals(allGroups, dayMeals, index);
        final targets = _mealTargets(mealsCount);
        final mealGroups = allGroups
            .map((def) => MapEntry(def, dayMeals[def.id]?[index] ?? 0))
            .where((entry) => entry.value > 0)
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMealAccordion(
            context: context,
            mealIndex: index,
            mealTotals: mealTotals,
            mealTargets: targets,
            mealGroups: mealGroups,
            allGroups: allGroups,
            dayMeals: dayMeals,
          ),
        );
      },
    );
  }

  Widget _buildMealAccordion({
    required BuildContext context,
    required int mealIndex,
    required Map<String, double> mealTotals,
    required Map<String, double> mealTargets,
    required List<MapEntry<EquivalentDefinition, double>> mealGroups,
    required List<EquivalentDefinition> allGroups,
    required Map<String, Map<int, double>> dayMeals,
  }) {
    final kcalCurrent = mealTotals['kcal'] ?? 0;
    final kcalTarget = mealTargets['kcal'] ?? 0;
    final progress = kcalTarget <= 0 ? 0 : kcalCurrent / kcalTarget;
    final percentage = (progress * 100).clamp(0, 200);

    return Container(
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kTextColorSecondary.withValues(alpha: 0.15)),
      ),
      child: ExpansionTile(
        initiallyExpanded: mealIndex == 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Row(
          children: [
            const Icon(Icons.sunny, size: 18, color: kPrimaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Comida ${mealIndex + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ),
            Text(
              '${kcalCurrent.toStringAsFixed(0)} / ${kcalTarget.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 11, color: kTextColorSecondary),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 90 && percentage <= 110
                  ? Colors.green
                  : percentage >= 80 && percentage <= 120
                  ? Colors.orange
                  : Colors.red,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                _buildMealMacroRow(
                  'Proteina',
                  mealTotals,
                  mealTargets,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildMealMacroRow(
                  'Carbos',
                  mealTotals,
                  mealTargets,
                  Colors.amber,
                ),
                const SizedBox(height: 8),
                _buildMealMacroRow(
                  'Grasas',
                  mealTotals,
                  mealTargets,
                  Colors.purple,
                ),
                const SizedBox(height: 12),
                if (mealGroups.isNotEmpty)
                  ...mealGroups.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMealGroupRow(
                        entry.key,
                        entry.value,
                        mealIndex,
                      ),
                    ),
                  ),
                if (mealGroups.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCardColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kTextColorSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: kTextColorSecondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin equivalentes asignados a esta comida.',
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextColorSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _copyMealToOthers(mealIndex, allGroups, dayMeals),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copiar a otras comidas'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealMacroRow(
    String label,
    Map<String, double> totals,
    Map<String, double> targets,
    Color color,
  ) {
    final key = label == 'Proteina'
        ? 'protein'
        : label == 'Carbos'
        ? 'carb'
        : 'fat';
    final current = totals[key] ?? 0;
    final target = targets[key] ?? 0;
    final progress = target <= 0 ? 0 : current / target;
    final percentage = (progress * 100).clamp(0, 200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
              style: const TextStyle(fontSize: 11, color: kTextColorSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0, 1).toDouble(),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 90 && percentage <= 110
                ? Colors.green
                : percentage >= 80 && percentage <= 120
                ? Colors.orange
                : Colors.red,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildMealGroupRow(
    EquivalentDefinition def,
    double value,
    int mealIndex,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGroupMainLabel(def.group),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
                if (def.subgroup.isNotEmpty)
                  Text(
                    _getSubgroupLabel(def.subgroup),
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextColorSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: value >= 0.5
                    ? () => ref
                          .read(equivalentsByDayProvider.notifier)
                          .updateMealEquivalent(
                            widget.dayKey,
                            def.id,
                            mealIndex,
                            -0.5,
                          )
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: value >= 0.5
                        ? kPrimaryColor
                        : kTextColorSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  value.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
              ),
              InkWell(
                onTap: () => ref
                    .read(equivalentsByDayProvider.notifier)
                    .updateMealEquivalent(
                      widget.dayKey,
                      def.id,
                      mealIndex,
                      0.5,
                    ),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // DIALOGS Y ACCIONES
  // =====================================================================

  void _showCopyDayDialog(BuildContext context) {
    final days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    final otherDays = days.where((d) => d != widget.dayKey).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: const Text(
            'Copiar equivalentes de otro dia',
            style: TextStyle(color: kTextColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: otherDays.map((day) {
              final label = day[0].toUpperCase() + day.substring(1);
              return ListTile(
                title: Text(label, style: const TextStyle(color: kTextColor)),
                trailing: const Icon(Icons.arrow_forward, color: kPrimaryColor),
                onTap: () {
                  ref
                      .read(equivalentsByDayProvider.notifier)
                      .copyDay(day, widget.dayKey);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Equivalentes copiados de $label'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAddGroupDialog(
    BuildContext context,
    List<EquivalentDefinition> emptyGroups,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: const Text(
            'Agregar Grupo',
            style: TextStyle(color: kTextColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: emptyGroups.length,
              itemBuilder: (context, index) {
                final def = emptyGroups[index];
                return ListTile(
                  leading: Icon(
                    Icons.restaurant,
                    color: _getGroupColor(def.group),
                  ),
                  title: Text(
                    _getGroupMainLabel(def.group),
                    style: const TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'P:${def.proteinG}g • C:${def.carbG}g • G:${def.fatG}g • ${def.kcal}kcal',
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(equivalentsByDayProvider.notifier)
                        .updateEquivalent(widget.dayKey, def.id, 1.0);
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

  void _autoDistribute(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Distribucion automatica en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _copyMealToOthers(
    int sourceIndex,
    List<EquivalentDefinition> allGroups,
    Map<String, Map<int, double>> dayMeals,
  ) {
    final notifier = ref.read(equivalentsByDayProvider.notifier);
    for (final def in allGroups) {
      final sourceValue = dayMeals[def.id]?[sourceIndex] ?? 0.0;
      for (var i = 0; i < widget.planResult.mealsPerDay; i++) {
        if (i == sourceIndex) continue;
        final currentValue = dayMeals[def.id]?[i] ?? 0.0;
        final delta = sourceValue - currentValue;
        if (delta.abs() < 0.01) continue;
        notifier.updateMealEquivalent(widget.dayKey, def.id, i, delta);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comida copiada a otras comidas')),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

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

  Map<String, double> _calculateMealTotals(
    List<EquivalentDefinition> allGroups,
    Map<String, Map<int, double>> dayMeals,
    int mealIndex,
  ) {
    double kcal = 0, protein = 0, fat = 0, carb = 0;
    for (final def in allGroups) {
      final value = dayMeals[def.id]?[mealIndex] ?? 0.0;
      kcal += def.kcal * value;
      protein += def.proteinG * value;
      fat += def.fatG * value;
      carb += def.carbG * value;
    }
    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carb': carb};
  }

  Map<String, double> _mealTargets(int mealsCount) {
    if (mealsCount <= 0) {
      return {'kcal': 0, 'protein': 0, 'fat': 0, 'carb': 0};
    }
    return {
      'kcal': (widget.planResult.kcalTargetDay ?? 0) / mealsCount,
      'protein': (widget.planResult.proteinTargetDay ?? 0) / mealsCount,
      'fat': (widget.planResult.fatTargetDay ?? 0) / mealsCount,
      'carb': (widget.planResult.carbTargetDay ?? 0) / mealsCount,
    };
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
    return (colors[group] ?? kCardColor).withValues(alpha: 0.12);
  }

  Color _getGroupColor(String group) {
    const colors = {
      'vegetales': Color(0xFF66BB6A),
      'frutas': Color(0xFFFFB300),
      'cereales_tuberculos': Color(0xFF8D6E63),
      'leguminosas': Color(0xFF7CB342),
      'aoa': Color(0xFF64B5F6),
      'leches': Color(0xFF90A4AE),
      'grasas': Color(0xFFFFA726),
      'azucares': Color(0xFF42A5F5),
      'libres': Color(0xFF9E9E9E),
      'alcohol': Color(0xFFBCAAA4),
    };
    return colors[group] ?? kPrimaryColor;
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

class _SummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SummaryHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SummaryHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
