import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macros_content.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class MacrosWeekScreen extends StatelessWidget {
  final Client client;
  final Function(Client) onClientUpdated;

  const MacrosWeekScreen({
    super.key,
    required this.client,
    required this.onClientUpdated,
  });

  Future<void> _saveTabIfNeeded(int tabIndex) async {
    final _ = tabIndex;
    final result = onClientUpdated(client);
    if (result is Future) {
      await result;
    }
  }

  void _handlePop(
    BuildContext context,
    TabController? tabController,
    Object? result,
  ) {
    final navigator = Navigator.of(context);
    final currentIndex = tabController?.index ?? 0;
    _saveTabIfNeeded(currentIndex).whenComplete(() {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    TabController? tabController;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handlePop(context, tabController, result);
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Macros de la Semana'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: DefaultTabController(
          length: 7,
          child: Builder(
            builder: (context) {
              tabController = DefaultTabController.of(context);
              return Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Lunes'),
                      Tab(text: 'Martes'),
                      Tab(text: 'MiǸrcoles'),
                      Tab(text: 'Jueves'),
                      Tab(text: 'Viernes'),
                      Tab(text: 'Sǭbado'),
                      Tab(text: 'Domingo'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children:
                          [
                            'Lunes',
                            'Martes',
                            'MiǸrcoles',
                            'Jueves',
                            'Viernes',
                            'Sǭbado',
                            'Domingo',
                          ].map((day) {
                            return const MacrosContent();
                          }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

