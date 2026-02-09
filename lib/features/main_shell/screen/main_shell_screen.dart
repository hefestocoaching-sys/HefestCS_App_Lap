import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/features/anthropometry_feature/screen/anthropometry_screen.dart';
import 'package:hcs_app_lap/features/biochemistry_feature/screen/biochemistry_screen.dart';
import 'package:hcs_app_lap/features/client_feature/screen/client_overview_screen.dart';
import 'package:hcs_app_lap/features/dashboard_feature/workspace_home_screen.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/screen/history_clinic_screen.dart';
import 'package:hcs_app_lap/features/macros_feature/screen/macros_screen.dart';
import 'package:hcs_app_lap/features/meal_plan_feature/screen/meal_plan_screen.dart';
import 'package:hcs_app_lap/features/nutrition_feature/screen/nutrition_screen.dart';
import 'package:hcs_app_lap/features/nutrition_feature/screens/equivalents_by_day_screen.dart';
import 'package:hcs_app_lap/features/training_feature/training_screen.dart';
import 'package:hcs_app_lap/features/main_shell/screen/client_selection_screen.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/global_side_navigation_rail.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/save_indicator_widget.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/settings_screen.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart';
import 'package:hcs_app_lap/core/navigation/client_open_origin.dart';
import 'package:hcs_app_lap/features/main_shell/providers/save_indicator_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialClientId, this.openOrigin});

  final String? initialClientId;
  final ClientOpenOrigin? openOrigin;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  static const int _homeIndex = 0;
  static const int _historyIndex = 1;
  static const int _summaryIndex = 10;
  static const double _globalRailCollapsedWidth = 64.0;

  // Índices que corresponden a pantallas de cliente
  static const Set<int> _clientScreenIndices = {1, 2, 3, 4, 5, 6, 7, 8, 9};

  final _selectedIndexNotifier = ValueNotifier<int>(0);
  final _showClientsScreenNotifier = ValueNotifier<bool>(false);
  Timer? _saveDebounceTimer;

  bool get isHomeContext => _selectedIndexNotifier.value == _homeIndex;

  bool _isSaving = false;
  bool _lastHasActiveClient = false;

  // Global keys para módulos saveable
  final _historyClinicKey = GlobalKey<HistoryClinicScreenState>();
  final _anthropometryKey = GlobalKey<AnthropometryScreenState>();
  final _nutritionKey = GlobalKey<NutritionScreenState>();
  final _macrosKey = GlobalKey<MacrosScreenState>();
  final _equivalentsKey = GlobalKey<EquivalentsByDayScreenState>();
  final _mealPlanKey = GlobalKey<MealPlanScreenState>();
  final _biochemistryKey = GlobalKey<BiochemistryScreenState>();

  @override
  void initState() {
    super.initState();
    _ensureCoachRootSafe();
    _resetStartupState();
    _applyInitialClientSelection();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _selectedIndexNotifier.dispose();
    _showClientsScreenNotifier.dispose();
    super.dispose();
  }

  Future<void> _ensureCoachRootSafe() async {
    if (!mounted) return;
    try {
      await _ensureCoachRoot();
    } catch (_) {
      // Ignorar errores de conectividad
    }
  }

  void _applyInitialClientSelection() {
    final targetId = widget.initialClientId;
    if (targetId == null || targetId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(clientsProvider.notifier).setActiveClientById(targetId);
    });
  }

  void _resetStartupState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Si no se abrió con un cliente específico, limpiar selección previa y forzar HOME
      final hasInitial =
          widget.initialClientId != null && widget.initialClientId!.isNotEmpty;
      if (!hasInitial) {
        await _clearActiveClientSelection();
        if (_selectedIndexNotifier.value != _homeIndex) {
          _selectedIndexNotifier.value = _homeIndex;
        }
      }
    });
  }

  Future<void> _ensureCoachRoot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('coaches').doc(user.uid).set({
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _navigateToClientsScreen() {
    _showClientsScreenNotifier.value = true;
  }

  void _closeClientsScreen() {
    _showClientsScreenNotifier.value = false;
  }

  SaveableModule? _moduleFromIndex(int index) {
    switch (index) {
      case 0:
        return null; // Dashboard (no saveable)
      case 1:
        return _historyClinicKey.currentState;
      case 2:
        return _anthropometryKey.currentState;
      case 3:
        return _nutritionKey.currentState;
      case 4:
        return _macrosKey.currentState;
      case 5:
        return _equivalentsKey.currentState;
      case 6:
        return _mealPlanKey.currentState;
      case 8:
        return _biochemistryKey.currentState;
      default:
        return null;
    }
  }

  Iterable<SaveableModule> _allModules() sync* {
    final modules = <SaveableModule?>[
      _historyClinicKey.currentState,
      _anthropometryKey.currentState,
      _nutritionKey.currentState,
      _macrosKey.currentState,
      _equivalentsKey.currentState,
      _mealPlanKey.currentState,
      _biochemistryKey.currentState,
    ];
    for (final module in modules) {
      if (module != null) {
        yield module;
      }
    }
  }

  Future<void> _saveActiveModuleIfNeeded() async {
    if (_isSaving) return;
    _isSaving = true;

    if (!mounted) {
      _isSaving = false;
      return;
    }

    ref.read(saveIndicatorProvider.notifier).setSaving();

    try {
      final index = _selectedIndexNotifier.value;
      final module = _moduleFromIndex(index);
      if (module != null) {
        await module.saveIfDirty();
      }

      if (!mounted) return;
      ref.read(saveIndicatorProvider.notifier).setSaved();
    } catch (e) {
      if (!mounted) return;
      ref
          .read(saveIndicatorProvider.notifier)
          .setError('Error: ${e.toString()}');
    } finally {
      _isSaving = false;
    }
  }

  void _scheduleSaveActiveModuleIfNeeded() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_saveActiveModuleIfNeeded());
    });
  }

  void _resetAllDrafts() {
    for (final module in _allModules()) {
      module.resetDrafts();
    }
  }

  Future<void> _clearActiveClientSelection() async {
    await ref.read(clientsProvider.notifier).clearActiveClient();
  }

  Future<void> _handleClientSelected(Client selectedClient) async {
    await _saveActiveModuleIfNeeded();
    if (!mounted) return;
    await ref
        .read(clientsProvider.notifier)
        .setActiveClientById(selectedClient.id);
    _resetAllDrafts();
    // Al seleccionar cliente, ir a resumen del cliente
    if (_selectedIndexNotifier.value != _summaryIndex) {
      _selectedIndexNotifier.value = _summaryIndex;
    }
    // La pantalla de selección se cierra desde el callback en el build
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _selectedIndexNotifier,
          builder: (context, selectedIndex, _) {
            // Obtener estado actualizado del provider
            final currentClientsAsync = ref.watch(clientsProvider);
            final currentActiveClient = currentClientsAsync.value?.activeClient;
            final hasActiveClient = currentActiveClient?.id != null;
            final isHomeContext = this.isHomeContext;

            // Nota: NO sincronizamos automáticamente el índice cuando cambia el cliente.
            // El usuario permanece donde estaba y puede navegar libremente.
            // Solo sincronizamos cuando NO hay cliente activo (volver a HOME).
            if (!hasActiveClient && _lastHasActiveClient) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_selectedIndexNotifier.value != _homeIndex) {
                  _selectedIndexNotifier.value = _homeIndex;
                }
              });
            }
            _lastHasActiveClient = hasActiveClient;

            return Scaffold(
              backgroundColor: kBackgroundColor,
              floatingActionButton: selectedIndex == _historyIndex
                  ? FloatingActionButton.extended(
                      heroTag: null,
                      onPressed: () async {
                        await _saveActiveModuleIfNeeded();
                        final clientToSave = currentActiveClient;
                        if (clientToSave != null) {
                          final client = clientToSave;
                          await ref
                              .read(clientsProvider.notifier)
                              .updateActiveClient((prev) {
                                final mergedNutritionExtra =
                                    Map<String, dynamic>.from(
                                      prev.nutrition.extra,
                                    );
                                mergedNutritionExtra.addAll(
                                  client.nutrition.extra,
                                );

                                final mergedTrainingExtra =
                                    Map<String, dynamic>.from(
                                      prev.training.extra,
                                    );
                                mergedTrainingExtra.addAll(
                                  client.training.extra,
                                );

                                // ✅ CRITICAL FIX: Usar client.training como base
                                // Solo mergear extra para no perder cambios concurrentes
                                final mergedTraining = client.training.copyWith(
                                  extra: mergedTrainingExtra,
                                );

                                return prev.copyWith(
                                  profile: client.profile,
                                  history: client.history,
                                  training: mergedTraining,
                                  nutrition: prev.nutrition.copyWith(
                                    extra: mergedNutritionExtra,
                                    dailyMealPlans:
                                        client.nutrition.dailyMealPlans ??
                                        prev.nutrition.dailyMealPlans,
                                  ),
                                  trainingPlans: client.trainingPlans,
                                  trainingWeeks: client.trainingWeeks,
                                  trainingSessions: client.trainingSessions,
                                );
                              });
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Historia clinica guardada'),
                            ),
                          );
                        }
                      },
                      label: const Text('Guardar Cliente'),
                      icon: const Icon(Icons.save),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    )
                  : null,
              body: SafeArea(
                bottom: false,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _showClientsScreenNotifier,
                  builder: (context, showClientsScreen, _) {
                    return Stack(
                      children: [
                        // Contenido principal sin reducirse cuando se expande el menú global
                        Positioned.fill(
                          left: _globalRailCollapsedWidth,
                          child: showClientsScreen
                              ? ClientSelectionScreen(
                                  onClientSelected: (client) async {
                                    _closeClientsScreen();
                                    await _handleClientSelected(client);
                                  },
                                )
                              : currentClientsAsync.when(
                                  data: (state) {
                                    return Column(
                                      children: [
                                        // Contenido principal
                                        Expanded(
                                          child: IndexedStack(
                                            index: selectedIndex,
                                            children: [
                                              const WorkspaceHomeScreen(), // 0
                                              HistoryClinicScreen(
                                                key: _historyClinicKey,
                                              ), // 1
                                              AnthropometryScreen(
                                                key: _anthropometryKey,
                                              ), // 2
                                              NutritionScreen(
                                                key: _nutritionKey,
                                              ), // 3
                                              MacrosScreen(
                                                key: _macrosKey,
                                              ), // 4
                                              EquivalentsByDayScreen(
                                                key: _equivalentsKey,
                                              ), // 5
                                              currentActiveClient != null
                                                  ? MealPlanScreen(
                                                      key: _mealPlanKey,
                                                      client:
                                                          currentActiveClient,
                                                      onClientUpdated:
                                                          (updated) async {
                                                            await ref
                                                                .read(
                                                                  historyClinicVmProvider,
                                                                )
                                                                .saveClient(
                                                                  updated,
                                                                );
                                                          },
                                                    )
                                                  : const SizedBox.shrink(), // 6
                                              TrainingScreen(), // 7
                                              BiochemistryScreen(
                                                key: _biochemistryKey,
                                              ), // 8
                                              SettingsScreen(), // 9
                                              const ClientOverviewScreen(), // 10
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (err, stack) =>
                                      Center(child: Text('Error: $err')),
                                ),
                        ),
                        // Menú lateral global flotante sobre el contenido
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GlobalSideNavigationRail(
                            selectedIndex: selectedIndex,
                            hasActiveClient:
                                !isHomeContext && currentActiveClient != null,
                            clientName: currentActiveClient?.fullName ?? '',
                            onIndexChanged: (index) async {
                              // Cerrar pantalla de clientes al navegar
                              _closeClientsScreen();

                              if (index == _homeIndex) {
                                _selectedIndexNotifier.value = _homeIndex;
                                return;
                              }

                              _scheduleSaveActiveModuleIfNeeded();
                              if (!mounted) return;

                              // Cambiar índice y forzar rebuild
                              _selectedIndexNotifier.value = index;

                              // Forzar rebuild en el siguiente frame
                              if (!_clientScreenIndices.contains(index)) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                });
                              }
                            },
                            onClientsPressed: () async {
                              debugPrint(
                                'DEBUG: Shell onClientsPressed handler called',
                              );
                              await _clearActiveClientSelection();
                              _scheduleSaveActiveModuleIfNeeded();
                              if (!mounted) {
                                debugPrint(
                                  'DEBUG: Widget not mounted, returning',
                                );
                                return;
                              }
                              debugPrint(
                                'DEBUG: About to call _navigateToClientsScreen',
                              );
                              _navigateToClientsScreen();
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
        // Indicador de guardado
        const SaveIndicatorWidget(),
      ],
    );
  }
}
