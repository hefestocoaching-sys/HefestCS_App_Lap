// lib/features/training_feature/providers/muscle_progression_tracker_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_impl.dart';
import 'package:hcs_app_lap/features/main_shell/providers/client_derived_providers.dart';
import 'package:hcs_app_lap/features/training_feature/viewmodels/muscle_progression_dashboard_viewmodel.dart';

final muscleProgressionRepositoryProvider =
  riverpod.Provider<MuscleProgressionRepository>((ref) {
      return MuscleProgressionRepositoryImpl();
    });

final weeklyMuscleAnalysisRepositoryProvider =
  riverpod.Provider<WeeklyMuscleAnalysisRepository>((ref) {
      return WeeklyMuscleAnalysisRepositoryImpl();
    });

final weeklyProgressionServiceProvider =
    riverpod.Provider<WeeklyProgressionService>((
  ref,
) {
  return WeeklyProgressionServiceImpl(
    progressionRepo: ref.watch(muscleProgressionRepositoryProvider),
    analysisRepo: ref.watch(weeklyMuscleAnalysisRepositoryProvider),
  );
});

final muscleProgressionDashboardViewModelProvider = legacy
    .ChangeNotifierProvider.autoDispose<MuscleProgressionDashboardViewModel>((
  ref,
) {
      final client = ref.watch(activeClientProvider);
      final userId = client?.id ?? '';

  return MuscleProgressionDashboardViewModel(
    service: ref.watch(weeklyProgressionServiceProvider),
    repository: ref.watch(muscleProgressionRepositoryProvider),
    userId: userId,
  );
});
