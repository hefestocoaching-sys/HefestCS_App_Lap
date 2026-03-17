import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/general_equivalents_table.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/smae_distribution_engine.dart';
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

      final state = ref.read(equivalentsByDayProvider);
      final dayEquivs = state.dayEquivalents[widget.dayKey];

      // Si ya hay datos guardados para este día, no sobreescribir
      if (dayEquivs != null && dayEquivs.isNotEmpty) return;

      final dayMacros = _getDayMacros();
      final targetKcal =
          dayMacros?.kcal ??
          (widget.planResult?.kcalTargetDay as num?)?.toDouble() ??
          0.0;
      final targetProtein =
          dayMacros?.proteinG ??
          (widget.planResult?.proteinTargetDay as num?)?.toDouble() ??
          0.0;
      final targetCarb =
          dayMacros?.carbG ??
          (widget.planResult?.carbTargetDay as num?)?.toDouble() ??
          0.0;
      final targetFat =
          dayMacros?.fatG ??
          (widget.planResult?.fatTargetDay as num?)?.toDouble() ??
          0.0;

      final mealsCount = widget.planResult.mealsPerDay ?? 3;

      final initialSmae = widget.planResult?.smaeDistribution;
      if (dayMacros == null && initialSmae != null) {
        ref
            .read(equivalentsByDayProvider.notifier)
            .setDayData(
              widget.dayKey,
              initialSmae.totalsByGroup,
              initialSmae.mealsByGroup,
            );
        return;
      }

      if (targetKcal <= 0 ||
          targetProtein <= 0 ||
          targetCarb <= 0 ||
          targetFat <= 0) {
        _initializeEmptyDay();
        return;
      }

      final engine = SmaeDistributionEngine();
      final distribution = engine.distribute(
        kcalTarget: targetKcal,
        proteinTargetG: targetProtein,
        carbTargetG: targetCarb,
        fatTargetG: targetFat,
        mealsPerDay: mealsCount,
        mealTargets: widget.planResult?.mealTargets,
      );

      ref
          .read(equivalentsByDayProvider.notifier)
          .setDayData(
            widget.dayKey,
            distribution.totalsByGroup,
            distribution.mealsByGroup,
          );
    });
  }

  void _initializeEmptyDay() {
    final mealsCount = widget.planResult.mealsPerDay;
    final groupIds = EquivalentCatalog.v1Definitions
        .map((def) => def.id)
        .toList();
    ref
        .read(equivalentsByDayProvider.notifier)
        .ensureDay(widget.dayKey, mealsCount, groupIds);
  }

  /// Devuelve los macros en gramos absolutos del día según weeklyMacroSettings.
  /// Retorna null si no hay datos disponibles para ese día.
  _DayMacros? _getDayMacros() {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return null;

    final activeDateIso = dateIsoFrom(ref.read(globalDateProvider));
    final macroRecords = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.macrosRecords],
    );
    final macroRecord =
        nutritionRecordForDate(macroRecords, activeDateIso) ??
        latestNutritionRecordByDate(macroRecords);
    final activeMacros = parseWeeklyMacroSettings(
      macroRecord?['weeklyMacroSettings'],
    );

    final day = activeMacros?[widget.dayKey];
    if (day == null) return null;

    final w = client.lastWeight ?? 70.0;
    return _DayMacros(
      carbG: day.carbSelected * w,
      proteinG: day.proteinSelected * w,
      fatG: day.fatSelected * w,
      kcal: day.totalCalories > 0
          ? day.totalCalories
          : (day.proteinSelected * w * 4) +
                (day.carbSelected * w * 4) +
                (day.fatSelected * w * 9),
    );
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
    final state = ref.watch(equivalentsByDayProvider);
    final dayEquivalents = state.dayEquivalents[widget.dayKey] ?? {};

    // Calculate Targets
    double kcalTarget = 0.0;
    double proteinTarget = 0.0;
    double fatTarget = 0.0;
    double carbTarget = 0.0;

    final client = ref.watch(clientsProvider).value?.activeClient;

    if (client != null) {
      final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));

      final macroRecords = readNutritionRecordList(
        client.nutrition.extra[NutritionExtraKeys.macrosRecords],
      );

      final macroRecord =
          nutritionRecordForDate(macroRecords, activeDateIso) ??
          latestNutritionRecordByDate(macroRecords);

      final activeMacros = parseWeeklyMacroSettings(
        macroRecord?['weeklyMacroSettings'],
      );

      if (activeMacros != null) {
        final double weight = client.lastWeight ?? 70.0;
        final DailyMacroSettings? daySettings = activeMacros[widget.dayKey];

        if (daySettings != null) {
          proteinTarget = daySettings.proteinSelected * weight;
          fatTarget = daySettings.fatSelected * weight;
          carbTarget = daySettings.carbSelected * weight;

          kcalTarget = daySettings.totalCalories > 0
              ? daySettings.totalCalories
              : (proteinTarget * 4) + (carbTarget * 4) + (fatTarget * 9);
        }
      }
    }

    if (kcalTarget == 0 && widget.planResult != null) {
      kcalTarget = widget.planResult.kcalTargetDay ?? 0.0;
      proteinTarget = widget.planResult.proteinTargetDay ?? 0.0;
      fatTarget = widget.planResult.fatTargetDay ?? 0.0;
      carbTarget = widget.planResult.carbTargetDay ?? 0.0;
    }

    final targets = {
      'kcal': kcalTarget,
      'protein': proteinTarget,
      'fat': fatTarget,
      'carbs': carbTarget,
    };

    final dayWarnings = _currentSmaeWarnings(
      kcalTarget: kcalTarget,
      proteinTarget: proteinTarget,
      carbTarget: carbTarget,
      fatTarget: fatTarget,
      mealsPerDay: widget.planResult.mealsPerDay,
    );

    return Column(
      children: [
        if (dayWarnings.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Text(
              dayWarnings.join(' | '),
              style: const TextStyle(
                fontSize: 11,
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        // Table
        Expanded(
          child: GeneralEquivalentsTable(
            targets: targets,
            equivalentsOverride: dayEquivalents,
            onUpdateOverride: (id, delta) {
              ref
                  .read(equivalentsByDayProvider.notifier)
                  .updateEquivalent(widget.dayKey, id, delta);
            },
          ),
        ),
        // Action Buttons (Copy/Auto)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCopyDayDialog(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar Dia'),
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
                  label: const Text('Auto Dist'),
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
        ),
      ],
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

  void _autoDistribute(BuildContext context) {
    final dayMacros = _getDayMacros();
    final targetKcal =
        dayMacros?.kcal ??
        (widget.planResult?.kcalTargetDay as num?)?.toDouble() ??
        0.0;
    final targetProtein =
        dayMacros?.proteinG ??
        (widget.planResult?.proteinTargetDay as num?)?.toDouble() ??
        0.0;
    final targetCarb =
        dayMacros?.carbG ??
        (widget.planResult?.carbTargetDay as num?)?.toDouble() ??
        0.0;
    final targetFat =
        dayMacros?.fatG ??
        (widget.planResult?.fatTargetDay as num?)?.toDouble() ??
        0.0;

    if (targetKcal <= 0 ||
        targetProtein <= 0 ||
        targetCarb <= 0 ||
        targetFat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay macros válidos para distribuir equivalentes.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final engine = SmaeDistributionEngine();
    final mealsCount = widget.planResult.mealsPerDay ?? 3;
    final distribution = engine.distribute(
      kcalTarget: targetKcal,
      proteinTargetG: targetProtein,
      carbTargetG: targetCarb,
      fatTargetG: targetFat,
      mealsPerDay: mealsCount,
      mealTargets: widget.planResult?.mealTargets,
    );

    ref
        .read(equivalentsByDayProvider.notifier)
        .setDayData(
          widget.dayKey,
          distribution.totalsByGroup,
          distribution.mealsByGroup,
        );

    final coverageCount = distribution.coverage.values
        .where((value) => value)
        .length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'SMAE v2 aplicado · Δkcal ${(distribution.deltaKcalPct * 100).toStringAsFixed(1)}% · cobertura $coverageCount/${distribution.coverage.length}',
        ),
        backgroundColor: distribution.withinTolerance
            ? Colors.green
            : Colors.orange,
      ),
    );
  }

  List<String> _currentSmaeWarnings({
    required double kcalTarget,
    required double proteinTarget,
    required double carbTarget,
    required double fatTarget,
    required int mealsPerDay,
  }) {
    if (kcalTarget <= 0 ||
        proteinTarget <= 0 ||
        carbTarget <= 0 ||
        fatTarget <= 0) {
      return const <String>[];
    }

    final engine = SmaeDistributionEngine();
    final result = engine.distribute(
      kcalTarget: kcalTarget,
      proteinTargetG: proteinTarget,
      carbTargetG: carbTarget,
      fatTargetG: fatTarget,
      mealsPerDay: mealsPerDay,
      mealTargets: widget.planResult?.mealTargets,
    );

    return result.warnings;
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

/// Macros en gramos absolutos para un día específico.
class _DayMacros {
  final double carbG;
  final double proteinG;
  final double fatG;
  final double kcal;

  const _DayMacros({
    required this.carbG,
    required this.proteinG,
    required this.fatG,
    required this.kcal,
  });
}
