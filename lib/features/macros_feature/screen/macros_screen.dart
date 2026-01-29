import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

import 'package:hcs_app_lap/features/macros_feature/widgets/macros_content.dart';

class MacrosScreen extends ConsumerStatefulWidget {
  const MacrosScreen({super.key});

  @override
  ConsumerState<MacrosScreen> createState() => MacrosScreenState();
}

class MacrosScreenState extends ConsumerState<MacrosScreen>
    implements SaveableModule {
  final GlobalKey<MacrosContentState> _macrosKey =
      GlobalKey<MacrosContentState>();

  @override
  Future<void> saveIfDirty() async {
    await _macrosKey.currentState?.saveIfDirty();
  }

  @override
  void resetDrafts() {
    _macrosKey.currentState?.resetDrafts();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      data: (state) => state.activeClient != null
          ? MacrosContent(key: _macrosKey)
          : const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text(
                  "Selecciona un cliente",
                  style: TextStyle(color: kTextColorSecondary),
                ),
              ),
            ),
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
