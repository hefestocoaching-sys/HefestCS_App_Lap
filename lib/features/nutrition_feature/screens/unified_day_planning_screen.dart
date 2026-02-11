import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/daily_nutrition_plan_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/validation/nutrition_plan_validator.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class UnifiedDayPlanningScreen extends ConsumerStatefulWidget {
  final String? dateIso;

  const UnifiedDayPlanningScreen({super.key, this.dateIso});

  @override
  ConsumerState<UnifiedDayPlanningScreen> createState() =>
      UnifiedDayPlanningScreenState();
}

class UnifiedDayPlanningScreenState
    extends ConsumerState<UnifiedDayPlanningScreen>
    implements SaveableModule {
  @override
  Future<void> saveIfDirty() async {
    // Placeholder: no editable state yet.
  }

  @override
  void resetDrafts() {
    // Placeholder: no drafts yet.
  }

  @override
  Widget build(BuildContext context) {
    final activeDateIso =
        widget.dateIso ?? dateIsoFrom(ref.watch(globalDateProvider));
    final planAsync = ref.watch(dailyNutritionPlanProvider(activeDateIso));

    return planAsync.when(
      data: (plan) {
        if (plan == null) {
          return _buildEmptyState();
        }
        final validation = NutritionPlanValidator.validatePlan(plan);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlanSummaryCard(
                  planDate: activeDateIso,
                  kcalTarget: plan.kcalTarget,
                  proteinTarget: plan.proteinTargetG,
                  carbsTarget: plan.carbTargetG,
                  fatTarget: plan.fatTargetG,
                  coherenceScore: validation.coherenceScore,
                  warningsCount: validation.warnings.length,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    color: kCardColor.withValues(alpha: 0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Plan unificado disponible. Esta vista es un placeholder '
                        'para la interfaz completa de macros, equivalentes y menu.',
                        style: TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: kTextColorSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay plan diario disponible',
            style: TextStyle(fontSize: 16, color: kTextColorSecondary),
          ),
        ],
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  final String planDate;
  final double kcalTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final double coherenceScore;
  final int warningsCount;

  const _PlanSummaryCard({
    required this.planDate,
    required this.kcalTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.coherenceScore,
    required this.warningsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardColor.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan diario: $planDate',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: coherenceScore.clamp(0.0, 1.0),
              color: _scoreColor(coherenceScore),
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 8),
            Text(
              'Coherencia ${(coherenceScore * 100).toStringAsFixed(0)}% '
              '- Alertas: $warningsCount',
              style: TextStyle(color: kTextColorSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MacroChip(label: 'Kcal', value: kcalTarget),
                _MacroChip(label: 'Proteina', value: proteinTarget),
                _MacroChip(label: 'Carbos', value: carbsTarget),
                _MacroChip(label: 'Grasas', value: fatTarget),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.9) return Colors.greenAccent;
    if (score >= 0.75) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;

  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(0)}',
        style: const TextStyle(color: kTextColor),
      ),
    );
  }
}
