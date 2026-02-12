import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';

class EquivalentsByDayState {
  final Map<String, Map<String, double>> dayEquivalents;
  final Map<String, Map<String, Map<int, double>>> dayMealEquivalents;
  final bool isDirty;

  const EquivalentsByDayState({
    this.dayEquivalents = const {},
    this.dayMealEquivalents = const {},
    this.isDirty = false,
  });

  EquivalentsByDayState copyWith({
    Map<String, Map<String, double>>? dayEquivalents,
    Map<String, Map<String, Map<int, double>>>? dayMealEquivalents,
    bool? isDirty,
  }) {
    return EquivalentsByDayState(
      dayEquivalents: dayEquivalents ?? this.dayEquivalents,
      dayMealEquivalents: dayMealEquivalents ?? this.dayMealEquivalents,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

final equivalentsByDayProvider =
    NotifierProvider<EquivalentsByDayNotifier, EquivalentsByDayState>(
  EquivalentsByDayNotifier.new,
);

class EquivalentsByDayNotifier extends Notifier<EquivalentsByDayState> {
  String? _loadedClientId;

  @override
  EquivalentsByDayState build() {
    return const EquivalentsByDayState();
  }

  void loadFromClient(Client? client, {bool force = false}) {
    if (client == null) return;
    if (!force && _loadedClientId == client.id && !state.isDirty) {
      return;
    }

    final extra = client.nutrition.extra;
    final raw = extra[NutritionExtraKeys.equivalentsByDay];
    final parsed = _parseEquivalents(raw);

    state = state.copyWith(
      dayEquivalents: parsed.dayEquivalents,
      dayMealEquivalents: parsed.dayMealEquivalents,
      isDirty: false,
    );
    _loadedClientId = client.id;
  }

  void loadFromPayload(dynamic raw, {bool markDirty = false}) {
    final parsed = _parseEquivalents(raw);
    state = state.copyWith(
      dayEquivalents: parsed.dayEquivalents,
      dayMealEquivalents: parsed.dayMealEquivalents,
      isDirty: markDirty,
    );
  }

  void ensureDay(String dayKey, int mealsPerDay, Iterable<String> groupIds) {
    final dayEquivalents = Map<String, Map<String, double>>.from(
      state.dayEquivalents,
    );
    final dayMeals = Map<String, Map<String, Map<int, double>>>.from(
      state.dayMealEquivalents,
    );

    final dayMap = Map<String, double>.from(dayEquivalents[dayKey] ?? {});
    for (final groupId in groupIds) {
      dayMap.putIfAbsent(groupId, () => 0.0);
    }
    dayEquivalents[dayKey] = dayMap;

    final dayMealMap = Map<String, Map<int, double>>.from(
      dayMeals[dayKey] ?? {},
    );
    for (final groupId in groupIds) {
      final mealsMap = Map<int, double>.from(dayMealMap[groupId] ?? {});
      for (int mealIdx = 0; mealIdx < mealsPerDay; mealIdx++) {
        mealsMap.putIfAbsent(mealIdx, () => 0.0);
      }
      dayMealMap[groupId] = mealsMap;
    }
    dayMeals[dayKey] = dayMealMap;

    state = state.copyWith(
      dayEquivalents: dayEquivalents,
      dayMealEquivalents: dayMeals,
    );
  }

  void updateEquivalent(String dayKey, String groupId, double delta) {
    final dayEquivalents = Map<String, Map<String, double>>.from(
      state.dayEquivalents,
    );
    final dayMap = Map<String, double>.from(dayEquivalents[dayKey] ?? {});
    final nextValue = (dayMap[groupId] ?? 0) + delta;
    dayMap[groupId] = nextValue < 0 ? 0 : nextValue;
    dayEquivalents[dayKey] = dayMap;

    state = state.copyWith(dayEquivalents: dayEquivalents, isDirty: true);
  }

  void updateMealEquivalent(
    String dayKey,
    String groupId,
    int mealIdx,
    double delta,
  ) {
    final dayMeals = Map<String, Map<String, Map<int, double>>>.from(
      state.dayMealEquivalents,
    );
    final dayMealMap = Map<String, Map<int, double>>.from(
      dayMeals[dayKey] ?? {},
    );
    final mealsMap = Map<int, double>.from(dayMealMap[groupId] ?? {});
    final nextValue = (mealsMap[mealIdx] ?? 0) + delta;
    mealsMap[mealIdx] = nextValue < 0 ? 0 : nextValue;
    dayMealMap[groupId] = mealsMap;
    dayMeals[dayKey] = dayMealMap;

    state = state.copyWith(dayMealEquivalents: dayMeals, isDirty: true);
  }

  void copyDay(String sourceDay, String targetDay) {
    if (sourceDay == targetDay) return;

    final dayEquivalents = Map<String, Map<String, double>>.from(
      state.dayEquivalents,
    );
    final sourceEquivalents = dayEquivalents[sourceDay];
    if (sourceEquivalents != null) {
      dayEquivalents[targetDay] = Map<String, double>.from(sourceEquivalents);
    }

    final dayMeals = Map<String, Map<String, Map<int, double>>>.from(
      state.dayMealEquivalents,
    );
    final sourceMeals = dayMeals[sourceDay];
    if (sourceMeals != null) {
      final copiedMeals = <String, Map<int, double>>{};
      for (final entry in sourceMeals.entries) {
        copiedMeals[entry.key] = Map<int, double>.from(entry.value);
      }
      dayMeals[targetDay] = copiedMeals;
    }

    state = state.copyWith(
      dayEquivalents: dayEquivalents,
      dayMealEquivalents: dayMeals,
      isDirty: true,
    );
  }

  Map<String, dynamic> toJson() {
    final dayEquivalents = state.dayEquivalents.map(
      (day, groups) => MapEntry(day, Map<String, dynamic>.from(groups)),
    );

    final dayMealEquivalents = state.dayMealEquivalents.map((day, groups) {
      final groupsMap = <String, dynamic>{};
      for (final entry in groups.entries) {
        final mealMap = <String, dynamic>{};
        for (final mealEntry in entry.value.entries) {
          mealMap[mealEntry.key.toString()] = mealEntry.value;
        }
        groupsMap[entry.key] = mealMap;
      }
      return MapEntry(day, groupsMap);
    });

    return {
      'version': 1,
      'dayEquivalents': dayEquivalents,
      'dayMealEquivalents': dayMealEquivalents,
    };
  }

  void markSaved() {
    state = state.copyWith(isDirty: false);
  }

  _ParsedEquivalents _parseEquivalents(dynamic raw) {
    if (raw is! Map) {
      return const _ParsedEquivalents();
    }

    final dayEquivalentsRaw = raw['dayEquivalents'];
    final dayMealsRaw = raw['dayMealEquivalents'];

    final parsedDayEquivalents = <String, Map<String, double>>{};
    if (dayEquivalentsRaw is Map) {
      for (final entry in dayEquivalentsRaw.entries) {
        final dayKey = entry.key.toString();
        final groupMap = <String, double>{};
        if (entry.value is Map) {
          for (final groupEntry in (entry.value as Map).entries) {
            final groupId = groupEntry.key.toString();
            final value = (groupEntry.value as num?)?.toDouble() ?? 0.0;
            groupMap[groupId] = value;
          }
        }
        parsedDayEquivalents[dayKey] = groupMap;
      }
    }

    final parsedDayMeals = <String, Map<String, Map<int, double>>>{};
    if (dayMealsRaw is Map) {
      for (final entry in dayMealsRaw.entries) {
        final dayKey = entry.key.toString();
        final groupMap = <String, Map<int, double>>{};
        if (entry.value is Map) {
          for (final groupEntry in (entry.value as Map).entries) {
            final groupId = groupEntry.key.toString();
            final mealsMap = <int, double>{};
            if (groupEntry.value is Map) {
              for (final mealEntry in (groupEntry.value as Map).entries) {
                final mealIdx = int.tryParse(mealEntry.key.toString());
                if (mealIdx == null) continue;
                final value = (mealEntry.value as num?)?.toDouble() ?? 0.0;
                mealsMap[mealIdx] = value;
              }
            }
            groupMap[groupId] = mealsMap;
          }
        }
        parsedDayMeals[dayKey] = groupMap;
      }
    }

    return _ParsedEquivalents(
      dayEquivalents: parsedDayEquivalents,
      dayMealEquivalents: parsedDayMeals,
    );
  }
}

class _ParsedEquivalents {
  final Map<String, Map<String, double>> dayEquivalents;
  final Map<String, Map<String, Map<int, double>>> dayMealEquivalents;

  const _ParsedEquivalents({
    this.dayEquivalents = const {},
    this.dayMealEquivalents = const {},
  });
}
