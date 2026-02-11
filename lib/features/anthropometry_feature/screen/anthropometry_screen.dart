import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/widgets/clinic_client_header_with_tabs.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/client_feature/models/client_summary_data.dart';

import '../widgets/anthropometry_measures_tab.dart';
import '../widgets/anthropometry_graphs_tab.dart';
import '../widgets/anthropometry_interpretation_tab.dart';

class AnthropometryScreen extends ConsumerStatefulWidget {
  const AnthropometryScreen({super.key});

  @override
  ConsumerState<AnthropometryScreen> createState() =>
      AnthropometryScreenState();
}

class AnthropometryScreenState extends ConsumerState<AnthropometryScreen>
    with SingleTickerProviderStateMixin
    implements SaveableModule {
  TabController? _tabController;
  int _currentTabIndex = 0;
  final _measuresTabKey = GlobalKey<AnthropometryMeasuresTabState>();
  bool _showHeader = true; // Track if we should show the header

  final List<String> _tabLabels = const <String>[
    'Medidas',
    'Interpretación',
    'Gráficas',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController?.addListener(_onTabChange);
  }

  void _onTabChange() {
    final controller = _tabController;
    if (controller == null) return;

    if (!controller.indexIsChanging && controller.index != _currentTabIndex) {
      final prevIndex = _currentTabIndex;
      _currentTabIndex = controller.index;
      if (prevIndex == 0) {
        _measuresTabKey.currentState?.saveIfDirty();
      }
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChange);
    _tabController?.dispose();
    _tabController = null;
    super.dispose();
  }

  @override
  Future<void> saveIfDirty() async {
    await _measuresTabKey.currentState?.saveIfDirty();
  }

  @override
  void resetDrafts() {
    _measuresTabKey.currentState?.resetDrafts();
  }

  void _handlePop(Object? result) {
    final navigator = Navigator.of(context);
    _saveTabIfNeeded(_tabController?.index ?? 0).whenComplete(() {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
    });
  }

  Future<void> _saveTabIfNeeded(int tabIndex) async {
    if (tabIndex == 0) {
      await _measuresTabKey.currentState?.saveIfDirty();
    }
  }

  void _onMeasuresViewStateChanged(AnthropometryViewState viewState) {
    // Defer setState to after the frame to avoid "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showHeader = viewState != AnthropometryViewState.idle;
        });
      }
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
        if (tabController == null) {
          return const Center(child: Text("Loading..."));
        }

        final globalDate = ref.watch(globalDateProvider);
        final summary = ClientSummaryData.fromClient(client, globalDate);

        final List<Widget> tabViews = <Widget>[
          AnthropometryMeasuresTab(
            key: _measuresTabKey,
            onStateChanged: () => setState(() {}),
            onViewStateChanged: _onMeasuresViewStateChanged,
          ),
          const AnthropometryInterpretationTab(),
          const AnthropometryGraphsTab(),
        ];

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
                // Header con tabs integrados (solo cuando NO está en overview)
                if (_showHeader)
                  ClinicClientHeaderWithTabs(
                    avatar: const Icon(
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
                      Tab(text: 'Medidas'),
                      Tab(text: 'Interpretación'),
                      Tab(text: 'Gráficas'),
                    ],
                  ),
                // Contenido de las tabs
                Expanded(
                  child: TabBarView(
                    controller: tabController,
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
