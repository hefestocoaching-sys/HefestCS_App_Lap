import 'package:flutter_riverpod/legacy.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/nutrition_blocked_state.dart';

final nutritionBlockedProvider = StateProvider<NutritionBlockedState>(
  (ref) => const NutritionBlockedState.unblocked(),
);
