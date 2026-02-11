import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeatureFlagKey { useUnifiedNutritionPlan }

class FeatureFlagService {
  final Map<FeatureFlagKey, bool> _overrides;

  FeatureFlagService({Map<FeatureFlagKey, bool>? overrides})
    : _overrides = overrides ?? {};

  bool isEnabled(FeatureFlagKey key) {
    final override = _overrides[key];
    if (override != null) return override;

    switch (key) {
      case FeatureFlagKey.useUnifiedNutritionPlan:
        return false;
    }
  }

  FeatureFlagService copyWithOverrides(Map<FeatureFlagKey, bool> overrides) {
    final merged = Map<FeatureFlagKey, bool>.from(_overrides);
    merged.addAll(overrides);
    return FeatureFlagService(overrides: merged);
  }
}

final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService();
});
