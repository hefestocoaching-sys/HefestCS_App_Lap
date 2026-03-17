// lib/features/training_feature/providers/weekly_progression_provider.dart

import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:hcs_app_lap/features/main_shell/providers/client_derived_providers.dart';
import 'package:hcs_app_lap/features/training_feature/providers/muscle_progression_tracker_provider.dart';
import 'package:hcs_app_lap/features/training_feature/viewmodels/weekly_progression_viewmodel.dart';

final weeklyProgressionViewModelProvider = legacy
    .ChangeNotifierProvider.autoDispose<WeeklyProgressionViewModel>((ref) {
  final client = ref.watch(activeClientProvider);
  final userId = client?.id ?? '';

  return WeeklyProgressionViewModel(
    service: ref.watch(weeklyProgressionServiceProvider),
    userId: userId,
  );
});
