import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/design/workspace_scaffold.dart';

/// Shell compartido para pantallas de detalle de registro.
/// Proporciona estructura consistente: header fijo + tabs + scroll.
///
/// Uso:
/// ```dart
/// RecordDetailShell(
///   header: MyRecordHeader(...),
///   tabController: _tabController,
///   tabs: [Tab(text: 'Tab 1'), ...],
///   tabViews: [RecordTabScaffold(child: ...), ...],
/// )
/// ```
class RecordDetailShell extends StatelessWidget {
  final Widget header;
  final TabController tabController;
  final List<Tab> tabs;
  final List<Widget> tabViews;

  const RecordDetailShell({
    super.key,
    required this.header,
    required this.tabController,
    required this.tabs,
    required this.tabViews,
  });

  @override
  Widget build(BuildContext context) {
    return WorkspaceScaffold(
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header fijo
          header,

          // TabBar fija
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: tabController,
              tabs: tabs,
              isScrollable: false,
            ),
          ),

          // Content con scroll interno
          Expanded(
            child: TabBarView(controller: tabController, children: tabViews),
          ),
        ],
      ),
    );
  }
}
