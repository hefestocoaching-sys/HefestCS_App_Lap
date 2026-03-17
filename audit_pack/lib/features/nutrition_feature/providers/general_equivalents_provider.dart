import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

class GeneralEquivalentsState {
  final Map<String, double> equivalents; // GroupId -> Quantity
  final Map<String, Map<int, double>>
  mealEquivalents; // GroupId -> {MealIdx -> Quantity}
  final bool isDirty;

  const GeneralEquivalentsState({
    this.equivalents = const {},
    this.mealEquivalents = const {},
    this.isDirty = false,
  });

  GeneralEquivalentsState copyWith({
    Map<String, double>? equivalents,
    Map<String, Map<int, double>>? mealEquivalents,
    bool? isDirty,
  }) {
    return GeneralEquivalentsState(
      equivalents: equivalents ?? this.equivalents,
      mealEquivalents: mealEquivalents ?? this.mealEquivalents,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  double get totalEquivalents =>
      equivalents.values.fold(0.0, (sum, val) => sum + val);
}

final generalEquivalentsProvider =
    NotifierProvider<GeneralEquivalentsNotifier, GeneralEquivalentsState>(
      GeneralEquivalentsNotifier.new,
    );

class GeneralEquivalentsNotifier extends Notifier<GeneralEquivalentsState> {
  String? _loadedClientId;

  @override
  GeneralEquivalentsState build() {
    return const GeneralEquivalentsState();
  }

  void loadFromClient(Client? client, {bool force = false}) {
    if (client == null) return;
    if (!force && _loadedClientId == client.id && !state.isDirty) {
      return;
    }

    final extra = client.nutrition.extra;
    final raw = extra[NutritionExtraKeys.generalEquivalents];
    final parsed = _parseGeneralEquivalents(raw);

    state = state.copyWith(
      equivalents: parsed.equivalents,
      mealEquivalents: parsed.mealEquivalents,
      isDirty: false,
    );
    _loadedClientId = client.id;
  }

  /// Carga la tabla general desde el día con más calorías de la semana (día pico).
  /// Este método reemplaza el cálculo por promedio que existía antes.
  ///
  /// Uso: llamar al abrir la pantalla de equivalentes generales, después de
  /// que el nutricionista haya completado los macros semanales del cliente.
  void loadFromPeakDay(Client client) {
    final extra = client.nutrition.extra;
    final macroRecords = readNutritionRecordList(
      extra[NutritionExtraKeys.macrosRecords],
    );
    final record = latestNutritionRecordByDate(macroRecords);
    final weeklyMacros = parseWeeklyMacroSettings(
      record?['weeklyMacroSettings'],
    );

    if (weeklyMacros == null || weeklyMacros.isEmpty) return;

    final w = client.lastWeight ?? 70.0;

    // Encontrar el día con más calorías (día pico)
    String? peakDayKey;
    double peakKcal = 0;

    weeklyMacros.forEach((dayKey, settings) {
      final kcal = settings.totalCalories > 0
          ? settings.totalCalories
          : (settings.proteinSelected * w * 4) +
                (settings.carbSelected * w * 4) +
                (settings.fatSelected * w * 9);
      if (kcal > peakKcal) {
        peakKcal = kcal;
        peakDayKey = dayKey;
      }
    });

    if (peakDayKey == null) return;

    // Obtener macros del día pico en gramos absolutos
    final peak = weeklyMacros[peakDayKey]!;
    final proteinG = peak.proteinSelected * w;
    final carbG = peak.carbSelected * w;
    final fatG = peak.fatSelected * w;

    // Convertir macros a equivalentes SMAE usando proporciones estándar:
    //   AOA bajo grasa   → proteína  (7g prot / equiv)
    //   Cereales sin grasa → carb    (15g carb / equiv)
    //   Grasas sin proteína → grasa  (5g grasa / equiv)
    //   Vegetales        → fijo 1.5 equiv (base mínima)
    //   Frutas           → ~15% del carb restante
    //
    // NOTA: estos valores son un punto de partida. El nutricionista los ajusta
    // manualmente en la tabla general antes de guardar.
    final aoaEquivs = _round1(proteinG / 7.0);
    final totalCarbEquivs = carbG / 15.0;
    final fruitEquivs = _round1(
      totalCarbEquivs * 0.15,
    ); // 15% de carb en frutas
    final cerealEquivs = _round1(totalCarbEquivs * 0.85); // 85% en cereales
    final fatEquivs = _round1(fatG / 5.0);

    final newEquivalents = <String, double>{
      if (aoaEquivs > 0) 'aoa_bajo': aoaEquivs,
      if (cerealEquivs > 0) 'cereales_sin_grasa': cerealEquivs,
      if (fruitEquivs > 0) 'frutas': fruitEquivs,
      if (fatEquivs > 0) 'grasas_sin_proteina': fatEquivs,
      'vegetales': 1.5, // mínimo base siempre presente
    };

    state = state.copyWith(
      equivalents: newEquivalents,
      mealEquivalents:
          const {}, // limpiar distribución por comida — el nutricionista la define
      isDirty: true,
    );
  }

  double _round1(double v) => double.parse(v.toStringAsFixed(1));

  void updateEquivalent(String groupId, double delta) {
    final equivalents = Map<String, double>.from(state.equivalents);
    final nextValue = (equivalents[groupId] ?? 0) + delta;
    equivalents[groupId] = nextValue < 0 ? 0 : nextValue;

    state = state.copyWith(equivalents: equivalents, isDirty: true);
  }

  void updateMealEquivalent(String groupId, int mealIdx, double delta) {
    final mealEquivalents = Map<String, Map<int, double>>.from(
      state.mealEquivalents,
    );
    final mealsMap = Map<int, double>.from(mealEquivalents[groupId] ?? {});

    final nextValue = (mealsMap[mealIdx] ?? 0) + delta;
    mealsMap[mealIdx] = nextValue < 0 ? 0 : nextValue;

    mealEquivalents[groupId] = mealsMap;

    // Auto-update total equivalent when meal distribution changes?
    // Or is Total the master and Meal is just distribution?
    // Usually Total is Master. If we change Meal, we should probably check if it exceeds Total.
    // For now, let's allow flexibility and maybe validate later or just update Total if requested.
    // User requested "Tabla general" and "Tabla por comida".
    // Usually: Total = Sum(Meals). If we change Meal, Total should update.

    final equivalents = Map<String, double>.from(state.equivalents);
    double newTotal = 0;
    mealsMap.forEach((_, v) => newTotal += v);

    // BUT wait, if we have a table for total, changing total should assume some default distribution?
    // Let's implement independent update for now, but usually they are linked.
    // Given the UI described ("General Tab", "Per Meal Distribution"),
    // usually editing Per Meal Updates Total.

    equivalents[groupId] = newTotal; // Sync Total to Sum of Meals?
    // Or maybe Total is the limit and Meals allocate it.
    // Let's stick to independent for a moment or check business logic.
    // Recommendation: Meals drive Total.

    state = state.copyWith(
      mealEquivalents: mealEquivalents,
      equivalents: equivalents,
      isDirty: true,
    );
  }

  void markSaved() {
    state = state.copyWith(isDirty: false);
  }

  Map<String, dynamic> toJson() {
    final mealEquivalentsJson = <String, dynamic>{};
    for (final entry in state.mealEquivalents.entries) {
      final mealMap = <String, double>{};
      entry.value.forEach((k, v) => mealMap[k.toString()] = v);
      mealEquivalentsJson[entry.key] = mealMap;
    }

    return {
      'version': 1,
      'equivalents': state.equivalents,
      'mealEquivalents': mealEquivalentsJson,
    };
  }

  _ParsedGeneral _parseGeneralEquivalents(dynamic raw) {
    if (raw is! Map) return const _ParsedGeneral();

    final equivalents = <String, double>{};
    if (raw['equivalents'] is Map) {
      (raw['equivalents'] as Map).forEach((k, v) {
        equivalents[k.toString()] = (v as num).toDouble();
      });
    }

    final mealEquivalents = <String, Map<int, double>>{};
    if (raw['mealEquivalents'] is Map) {
      (raw['mealEquivalents'] as Map).forEach((k, v) {
        if (v is Map) {
          final mealMap = <int, double>{};
          v.forEach((mk, mv) {
            final idx = int.tryParse(mk.toString());
            if (idx != null) mealMap[idx] = (mv as num).toDouble();
          });
          mealEquivalents[k.toString()] = mealMap;
        }
      });
    }

    return _ParsedGeneral(
      equivalents: equivalents,
      mealEquivalents: mealEquivalents,
    );
  }
}

class _ParsedGeneral {
  final Map<String, double> equivalents;
  final Map<String, Map<int, double>> mealEquivalents;

  const _ParsedGeneral({
    this.equivalents = const {},
    this.mealEquivalents = const {},
  });
}
