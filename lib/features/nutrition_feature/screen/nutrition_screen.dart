import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/client_feature/models/client_summary_data.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/widgets/clinic_client_header_with_tabs.dart';

import '../widgets/dietary_tab.dart';
import '../widgets/depletion_tab.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => NutritionScreenState();
}

class NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin
    implements SaveableModule {
  late TabController _tabController;
  final GlobalKey<DietaryTabState> _dietaryKey = GlobalKey<DietaryTabState>();
  int _lastTabIndex = 0;
  String _selectedRecordDateIso =
      ''; // Empty string = overview, non-empty = selected record

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == _lastTabIndex) return;
      if (_lastTabIndex == 0) {
        _dietaryKey.currentState?.commitChanges();
      }
      _lastTabIndex = _tabController.index;
    });
    // NO crear registros automáticamente
    // NO establecer _selectedRecordDateIso aquí
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<void> saveIfDirty() async {
    if (_tabController.index == 0) {
      _dietaryKey.currentState?.commitChanges();
    }
  }

  @override
  void resetDrafts() {
    _dietaryKey.currentState?.resetDrafts();
  }

  void _handlePop(Object? result) {
    if (_tabController.index == 0) {
      _dietaryKey.currentState?.commitChanges();
    }
    final navigator = Navigator.of(context);
    if (!navigator.mounted) {
      return;
    }
    navigator.pop(result);
  }

  void _onDietaryViewStateChanged(bool isOverview) {
    if (isOverview) {
      // Evitar setState durante el build del child
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedRecordDateIso = '';
        });
      });
    }
  }

  void _onRecordSelected(String recordDateIso) {
    setState(() {
      _selectedRecordDateIso = recordDateIso;
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

        final tabController = _tabController;

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
            // ✅ PATRÓN CLÍNICO: Header fuera del scroll, tabs manejan su propio scroll
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con tabs integrados (solo fuera de overview)
                if (_selectedRecordDateIso.isNotEmpty)
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
                    tabController: tabController,
                    tabs: const [
                      Tab(text: 'Cálculo de requerimientos'),
                      Tab(text: 'Depletación'),
                    ],
                  ),
                // Contenido de las tabs
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      DietaryTab(
                        key: _dietaryKey,
                        activeDateIso: _selectedRecordDateIso,
                        onViewStateChanged: _onDietaryViewStateChanged,
                        onRecordSelected: _onRecordSelected,
                      ),
                      const DepletionTab(),
                    ],
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
