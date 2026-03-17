import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/general_equivalents_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/general_equivalents_tab.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

// We get meals count from the client.

class EquivalentsScreen extends ConsumerStatefulWidget {
  const EquivalentsScreen({super.key});

  @override
  ConsumerState<EquivalentsScreen> createState() => _EquivalentsScreenState();
}

class _EquivalentsScreenState extends ConsumerState<EquivalentsScreen>
    with AutomaticKeepAliveClientMixin
    implements SaveableModule {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client != null) {
        ref.read(generalEquivalentsProvider.notifier).loadFromClient(client);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final client = ref.watch(clientsProvider).value?.activeClient;

    // Fallback if client not loaded
    if (client == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get meals count from extra or default to 3
    final mealsCount =
        int.tryParse(
          client.nutrition.extra[NutritionExtraKeys.preferredMealsPerDay]
                  ?.toString() ??
              '3',
        ) ??
        3;

    // Calculate Targets from Client Records
    Map<String, double>? targets;
    try {
      final records = readNutritionRecordList(
        client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
      );
      final latest = latestNutritionRecordByDate(records);
      if (latest != null) {
        targets = {
          'kcal': (latest['kcalTarget'] as num?)?.toDouble() ?? 0.0,
          'protein': (latest['proteinG'] as num?)?.toDouble() ?? 0.0,
          'fat': (latest['fatG'] as num?)?.toDouble() ?? 0.0,
          'carbs': (latest['carbG'] as num?)?.toDouble() ?? 0.0,
        };
      }
    } catch (e) {
      debugPrint('Error calculating targets for Equivalents: $e');
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Equivalentes Generales (Base)'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GeneralEquivalentsTab(
        mealsPerDay: mealsCount,
        targets: targets,
        onSave: saveIfDirty,
      ),
    );
  }

  @override
  Future<void> saveIfDirty() async {
    final state = ref.read(generalEquivalentsProvider);
    if (!state.isDirty) return;

    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final updatedExtra = Map<String, dynamic>.from(client.nutrition.extra);
    updatedExtra[NutritionExtraKeys.generalEquivalents] = ref
        .read(generalEquivalentsProvider.notifier)
        .toJson();

    await ref.read(clientsProvider.notifier).updateActiveClient((c) {
      return c.copyWith(nutrition: c.nutrition.copyWith(extra: updatedExtra));
    });
    ref.read(generalEquivalentsProvider.notifier).markSaved();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración General Guardada')),
      );
    }
  }

  @override
  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      ref
          .read(generalEquivalentsProvider.notifier)
          .loadFromClient(client, force: true);
    }
  }
}
