import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

import 'package:hcs_app_lap/features/history_clinic_feature/tabs/background_tab.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/tabs/general_evaluation_tab.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/tabs/training_evaluation_tab.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/tabs/personal_data_tab.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/tabs/gyneco_tab.dart';

import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/widgets/clinic_client_header_with_tabs.dart';
import 'package:hcs_app_lap/features/client_feature/models/client_summary_data.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';

class HistoryClinicScreen extends ConsumerStatefulWidget {
  const HistoryClinicScreen({super.key});

  @override
  ConsumerState<HistoryClinicScreen> createState() =>
      HistoryClinicScreenState();
}

class HistoryClinicScreenState extends ConsumerState<HistoryClinicScreen>
    with SingleTickerProviderStateMixin
    implements SaveableModule {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final _personalTabKey = GlobalKey<PersonalDataTabState>();
  final _backgroundTabKey = GlobalKey<BackgroundTabState>();
  final _generalTabKey = GlobalKey<GeneralEvaluationTabState>();
  final _trainingTabKey = GlobalKey<TrainingEvaluationTabState>();
  final _gynecoTabKey = GlobalKey<GynecoTabState>();
  late VoidCallback _tabListener;

  final List<String> _tabLabels = const <String>[
    'Datos Personales',
    'Antecedentes',
    'Evaluación/Nutrición',
    'Evaluación/Entrenamiento',
    'Ginecobstétricos',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabListener = () async {
      if (!_tabController.indexIsChanging &&
          _tabController.index != _currentTabIndex) {
        final prevIndex = _currentTabIndex;
        await _saveTabIfNeeded(prevIndex);
        _currentTabIndex = _tabController.index;
      }
    };
    _tabController.addListener(_tabListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<void> saveIfDirty() async {
    // Guardar siempre la pestaña visible primero
    await _saveTabIfNeeded(_tabController.index);
    // Luego intentar guardar las demás que puedan estar sucias
    for (final idx in [0, 1, 2, 3, 4]) {
      if (idx == _tabController.index) continue;
      await _saveTabIfNeeded(idx);
    }
  }

  @override
  void resetDrafts() {
    _personalTabKey.currentState?.resetDrafts();
    _backgroundTabKey.currentState?.resetDrafts();
    _generalTabKey.currentState?.resetDrafts();
    _trainingTabKey.currentState?.resetDrafts();
    _gynecoTabKey.currentState?.resetDrafts();
  }

  Future<void> _saveTabIfNeeded(int tabIndex) async {
    Client? updated;
    switch (tabIndex) {
      case 0:
        updated = await _personalTabKey.currentState?.saveIfDirty();
        break;
      case 1:
        updated = await _backgroundTabKey.currentState?.saveIfDirty();
        break;
      case 2:
        updated = await _generalTabKey.currentState?.saveIfDirty();
        break;
      case 3:
        updated = await _trainingTabKey.currentState?.saveIfDirty();
        break;
      case 4:
        updated = await _gynecoTabKey.currentState?.saveIfDirty();
        break;
      default:
        updated = null;
    }

    if (updated != null) {
      final updatedClient = updated;
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        final mergedNutritionExtra = Map<String, dynamic>.from(
          prev.nutrition.extra,
        );
        mergedNutritionExtra.addAll(updatedClient.nutrition.extra);

        final mergedTrainingExtra = Map<String, dynamic>.from(
          prev.training.extra,
        );
        mergedTrainingExtra.addAll(updatedClient.training.extra);

        return prev.copyWith(
          profile: updatedClient.profile,
          history: updatedClient.history,
          training: updatedClient.training.copyWith(extra: mergedTrainingExtra),
          nutrition: prev.nutrition.copyWith(
            extra: mergedNutritionExtra,
            dailyMealPlans:
                updatedClient.nutrition.dailyMealPlans ??
                prev.nutrition.dailyMealPlans,
          ),
        );
      });
    }
  }

  void _handlePop(Object? result) {
    final navigator = Navigator.of(context);
    _saveTabIfNeeded(_tabController.index).whenComplete(() {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
    });
  }

  List<Widget> _buildChipsRight(ClientSummaryData summary) {
    return [
      _buildMetricChip('Grasa ${summary.formattedBodyFat}', Colors.orange),
      const SizedBox(width: 10),
      _buildMetricChip('Músculo ${summary.formattedMuscle}', Colors.blue),
      const SizedBox(width: 10),
      _buildMetricChip(
        summary.planLabel,
        summary.isActivePlan ? Colors.green : Colors.grey,
      ),
    ];
  }

  Widget _buildMetricChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      data: (state) {
        final client = state.activeClient;
        if (client == null) {
          return const Center(child: Text("No client selected"));
        }
        final List<Widget> tabViews = <Widget>[
          PersonalDataTab(key: _personalTabKey),
          BackgroundTab(key: _backgroundTabKey),
          GeneralEvaluationTab(key: _generalTabKey),
          TrainingEvaluationTab(key: _trainingTabKey),
          GynecoTab(key: _gynecoTabKey),
        ];

        final globalDate = ref.watch(globalDateProvider);
        final summary = ClientSummaryData.fromClient(client, globalDate);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _handlePop(result);
          },
          child: WorkspaceScaffold(
            padding: EdgeInsets.zero,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con tabs integrados
                ClinicClientHeaderWithTabs(
                  avatar: Icon(
                    Icons.person,
                    color: kTextColorSecondary,
                    size: 40,
                  ),
                  name: client.fullName,
                  subtitle: client.profile.objective.isNotEmpty
                      ? client.profile.objective
                      : 'Sin objetivo',
                  chipsRight: _buildChipsRight(summary),
                  tabController: _tabController,
                  tabs: const [
                    Tab(text: 'Datos Personales'),
                    Tab(text: 'Antecedentes'),
                    Tab(text: 'Evaluación/Nutrición'),
                    Tab(text: 'Evaluación/Entrenamiento'),
                    Tab(text: 'Ginecobstétricos'),
                  ],
                ),
                // Contenido de las tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: tabViews,
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
}
