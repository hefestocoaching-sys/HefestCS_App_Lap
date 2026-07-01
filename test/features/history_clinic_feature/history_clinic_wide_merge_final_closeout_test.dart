import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('history clinic wide merge final closeout', () {
    test('history screen and main shell do not wide-merge clinical snapshots', () {
      final historyScreen = _read(
        'lib/features/history_clinic_feature/screen/history_clinic_screen.dart',
      );
      final mainShell = _read(
        'lib/features/main_shell/screen/main_shell_screen.dart',
      );

      expect(historyScreen, isNot(contains(_wideMerge('updated', 'profile'))));
      expect(historyScreen, isNot(contains(_wideMerge('updated', 'history'))));
      expect(
        historyScreen,
        isNot(contains(_wideMerge('updatedClient', 'profile'))),
      );
      expect(
        historyScreen,
        isNot(contains(_wideMerge('updatedClient', 'history'))),
      );

      expect(mainShell, isNot(contains(_wideMerge('client', 'profile'))));
      expect(mainShell, isNot(contains(_wideMerge('client', 'history'))));
      expect(mainShell, isNot(contains(_historyVmProviderSymbol)));
    });

    test('history clinic viewmodel no longer exposes wide saveClient', () {
      final viewModel = _read(
        'lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart',
      );

      expect(
        viewModel,
        isNot(contains(_legacySaveClientSignature)),
      );
      expect(viewModel, isNot(contains(_wideMerge('updated', 'profile'))));
      expect(viewModel, isNot(contains(_wideMerge('updated', 'history'))));
    });

    test('meal plan does not use history clinic viewmodel for nutrition saves', () {
      final mealPlan = _read(
        'lib/features/meal_plan_feature/screen/meal_plan_screen.dart',
      );

      expect(mealPlan, isNot(contains(_historyVmProviderSymbol)));
      expect(mealPlan, isNot(contains('.saveClient' '(updated)')));
    });

    test('migrated clinical tabs keep void save contract and provider patches', () {
      const tabPaths = <String>[
        'lib/features/history_clinic_feature/tabs/personal_data_tab.dart',
        'lib/features/history_clinic_feature/tabs/background_tab.dart',
        'lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart',
        'lib/features/history_clinic_feature/tabs/gyneco_tab.dart',
      ];

      for (final path in tabPaths) {
        final source = _read(path);
        expect(source, contains('Future<void> saveIfDirty()'));
        expect(source, isNot(contains('Future<Client?> saveIfDirty()')));
        expect(source, contains('updateActiveClient((prev)'));
      }
    });
  });
}

String _read(String path) => File(path).readAsStringSync();

String _wideMerge(String object, String field) => '$field: $object.$field';

String get _historyVmProviderSymbol =>
    ['history', 'Clinic', 'Vm', 'Provider'].join();

String get _legacySaveClientSignature =>
    'Future<void> '
    'saveClient'
    '(Client updated)';
