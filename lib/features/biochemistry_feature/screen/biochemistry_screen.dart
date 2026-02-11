import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/module_header.dart';

import '../widgets/biochemistry_tab.dart';
import '../widgets/biochemistry_comparison_screen.dart';

class BiochemistryScreen extends ConsumerStatefulWidget {
  const BiochemistryScreen({super.key});

  @override
  ConsumerState<BiochemistryScreen> createState() => BiochemistryScreenState();
}

class BiochemistryScreenState extends ConsumerState<BiochemistryScreen>
    implements SaveableModule {
  static const List<Tab> _tabs = <Tab>[
    Tab(text: 'Registro de Datos'),
    Tab(text: 'ComparaciИn Avanzada'),
  ];
  final GlobalKey<BiochemistryTabState> _bioTabKey =
      GlobalKey<BiochemistryTabState>();
  TabController? _tabController;
  int _currentTabIndex = 0;
  VoidCallback? _tabListener;

  @override
  Future<void> saveIfDirty() async {
    await _bioTabKey.currentState?.saveIfDirty();
  }

  @override
  void resetDrafts() {
    _bioTabKey.currentState?.resetDrafts();
  }

  void _handlePop(BuildContext context, Object? result) {
    final navigator = Navigator.of(context);
    final state = DefaultTabController.of(context);
    final currentIndex = state.index;
    if (currentIndex != 0) {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
      return;
    }
    final saveFuture = _bioTabKey.currentState?.saveIfDirty();
    if (saveFuture == null) {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
      return;
    }
    saveFuture.whenComplete(() {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
    });
  }

  void _ensureTabListener(TabController controller) {
    if (_tabController == controller) {
      return;
    }
    if (_tabController != null && _tabListener != null) {
      _tabController!.removeListener(_tabListener!);
    }
    _tabController = controller;
    _currentTabIndex = controller.index;
    _tabListener = () {
      if (!_tabController!.indexIsChanging &&
          _tabController!.index != _currentTabIndex) {
        final prevIndex = _currentTabIndex;
        _currentTabIndex = _tabController!.index;
        if (prevIndex == 0) {
          _bioTabKey.currentState?.saveIfDirty();
        }
      }
    };
    _tabController!.addListener(_tabListener!);
  }

  @override
  void dispose() {
    if (_tabController != null && _tabListener != null) {
      _tabController!.removeListener(_tabListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handlePop(context, result);
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DefaultTabController(
              length: _tabs.length,
              child: Builder(
                builder: (context) {
                  final controller = DefaultTabController.of(context);
                  _ensureTabListener(controller);
                  return Column(
                    children: [
                      const ModuleHeader(
                        title: 'Bioquímica',
                        subtitle: 'Análisis de laboratorio y marcadores',
                        icon: Icons.science_outlined,
                      ),
                      const TabBar(
                        tabs: _tabs,
                        labelColor: kTextColor,
                        unselectedLabelColor: kTextColorSecondary,
                        indicatorColor: kPrimaryColor,
                        indicatorWeight: 3.0,
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: kAppBarColor,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            BiochemistryTab(key: _bioTabKey),
                            const BiochemistryComparisonScreen(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
