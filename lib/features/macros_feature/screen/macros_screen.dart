import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macros_content.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

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
      data: (state) {
        if (state.activeClient == null) {
          return const Scaffold(
            backgroundColor: kBackgroundColor,
            body: Center(
              child: Text(
                'Selecciona un cliente para trabajar macros.',
                style: TextStyle(color: kTextColorSecondary),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: kBackgroundColor,
          body: SafeArea(child: MacrosContent(key: _macrosKey)),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Text(
            'Error al cargar macros: $error',
            style: const TextStyle(color: kErrorColor),
          ),
        ),
      ),
    );
  }
}
