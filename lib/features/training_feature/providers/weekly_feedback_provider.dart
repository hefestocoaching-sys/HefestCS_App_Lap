// lib/features/training_feature/providers/weekly_feedback_provider.dart

import 'package:flutter_riverpod/legacy.dart' as legacy;

final weeklyFeedbackProvider = legacy
    .StateProvider<Map<String, Map<String, dynamic>>>((ref) => {});
