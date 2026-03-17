import 'dart:math';

import 'package:hcs_app_lap/domain/entities/smae_food.dart';

class SmaeFoodSelector {
  final Random _random = Random();

  List<SmaeFood> byGroup(List<SmaeFood> foods, String? group, {int limit = 5}) {
    final pool = (group == null || group.trim().isEmpty)
        ? foods
        : foods
              .where((f) => f.smaeGroup.toLowerCase() == group.toLowerCase())
              .toList();
    final effectivePool = pool.isNotEmpty ? pool : foods;
    final shuffled = List<SmaeFood>.from(effectivePool)..shuffle(_random);
    return shuffled.take(limit).toList();
  }
}

final smaeFoodSelector = SmaeFoodSelector();
