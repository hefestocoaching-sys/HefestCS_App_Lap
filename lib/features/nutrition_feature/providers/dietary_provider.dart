import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/services/anthropometry_analyzer.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/dietary_state_models.dart';
import 'package:hcs_app_lap/utils/dietary_calculator.dart';
import 'package:hcs_app_lap/utils/mets_data.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

part 'dietary_provider.freezed.dart';

/// Estado inmutable para la pestaña de dieta.
@freezed
abstract class DietaryState with _$DietaryState {
  const factory DietaryState({
    @Default('Mifflin-St. Jeor') String selectedTMBFormulaKey,
    @Default({}) Map<String, TMBFormulaInfo> tmbCalculations,
    @Default(0.0) double calculatedAverageTMB,
    @Default({}) Map<String, List<UserActivity>> dailyActivities,
    @Default({}) Map<String, double> dailyNafFactors,
    @Default(0.0) double finalKcal,
    @Default(0.0) double leanBodyMass,
    @Default(0.0) double bodyFatPercentage,
    @Default(false) bool isObese,
    @Default(false) bool hasLBM,
  }) = _DietaryState;
}

class DietaryNotifier extends Notifier<DietaryState> {
  final AnthropometryAnalyzer _analyzer = AnthropometryAnalyzer();

  @override
  DietaryState build() {
    return const DietaryState();
  }

  // ============================================
  // NORMALIZADORES — FUENTES ÚNICAS (P0)
  // ============================================

  /// Normaliza edad desde fuente única y estable
  /// REGLA:
  ///   1. Si age > 0 → usarla (explícita)
  ///   2. Si no, calcular desde birthDate correctamente
  ///   3. Si no hay ambas → retornar 0 (bloquea cálculos)
  int _resolveFinalAge(int? explicitAge, DateTime? birthDate) {
    // Regla 1: Si hay edad explícita y válida, usarla
    if (explicitAge != null && explicitAge > 0) {
      if (kDebugMode) {
        debugPrint('[DietaryProvider] Edad usada (explícita): $explicitAge');
      }
      return explicitAge;
    }

    // Regla 2: Si hay fecha de nacimiento, calcular con precisión
    if (birthDate != null) {
      final today = DateTime.now();
      int calculatedAge = today.year - birthDate.year;
      // Ajustar si el cumpleaños aún no ha ocurrido este año
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        calculatedAge--;
      }
      // Validar que la edad calculada sea razonable (3-130 años)
      if (calculatedAge > 0 && calculatedAge < 130) {
        if (kDebugMode) {
          debugPrint(
            '[DietaryProvider] Edad calculada desde birthDate: $calculatedAge '
            '(dob: ${birthDate.toString().split(' ')[0]})',
          );
        }
        return calculatedAge;
      }
    }

    // Regla 3: Fallback seguro (bloquea cálculos)
    if (kDebugMode) {
      debugPrint(
        '[DietaryProvider] ⚠️ ADVERTENCIA: No hay edad explícita ni birthDate válida. '
        'Bloqueando cálculo TMB.',
      );
    }
    return 0;
  }

  /// Normaliza género desde múltiples formatos a string seguro normalizado
  /// Retorna: 'Hombre' o 'Mujer' (compatibilidad con parseGender)
  String _normalizeGenderString(String? rawGender) {
    if (rawGender == null || rawGender.isEmpty) {
      return 'Mujer'; // Fallback conservador
    }
    final normalized = rawGender.toLowerCase().trim();
    // Variantes masculinas
    if (normalized == 'hombre' ||
        normalized == 'masculino' ||
        normalized == 'male' ||
        normalized == 'm') {
      return 'Hombre';
    }
    // Variantes femeninas (incluyendo fallback)
    return 'Mujer';
  }

  void initialize(
    Client client, {
    bool forceReset = false,
    String? activeDateIso,
  }) {
    // 1. Analizar Antropometría
    final record = _anthropometryForDate(client, activeDateIso);

    // ✅ FASE 2: UNIFICAR EDAD (P0)
    // Regla: si existe age > 0 → usarla; si no → calcular desde birthDate
    final int age = _resolveFinalAge(client.age, client.profile.birthDate);
    if (age <= 0) {
      debugPrint(
        '[DietaryProvider.initialize] ❌ EDAD NO RESUELTA. No se pueden calcular TMBs.',
      );
      return; // Bloquea cálculos si edad es inválida
    }

    // ✅ FASE 1: NORMALIZAR GÉNERO (P0)
    final String genderNormalized = _normalizeGenderString(client.gender);

    double leanMass = 0.0;
    double bodyFat = 0.0;
    bool isObese = false;

    final hasMeasuredComp =
        record != null && _hasMeasuredBodyComposition(record);
    if (record != null) {
      final analysis = _analyzer.analyze(
        record: record,
        age: age,
        gender: genderNormalized,
      );
      leanMass = analysis.leanMassKg ?? 0.0;
      bodyFat = analysis.bodyFatPercentage ?? 0.0;

      final isMale = parseGender(genderNormalized) == Gender.male;
      final weight = record.weightKg;
      final height = record.heightCm;
      final bmi = (weight != null && height != null && height > 0)
          ? weight / ((height / 100) * (height / 100))
          : null;

      // Obesidad basada en dato disponible
      isObese = hasMeasuredComp
          ? ((isMale && bodyFat > 30) || (!isMale && bodyFat > 35))
          : ((bmi ?? 0) >= 30);
    }

    // 2. Inicializar Actividades y NAF
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final evalRecord = activeDateIso == null
        ? latestNutritionRecordByDate(records)
        : (nutritionRecordForDate(records, activeDateIso) ??
              latestNutritionRecordByDate(records));

    final recordActivities = _parseDailyActivities(
      evalRecord?['dailyActivities'],
    );
    final recordNafFactors = _parseDailyNafFactors(
      evalRecord?['dailyNafFactors'],
    );
    final defaultActivities = {for (var day in days) day: <UserActivity>[]};
    final defaultNafValue = nafRanges.first.factors.first;
    final defaultNafFactors = {for (var day in days) day: defaultNafValue};

    final Map<String, List<UserActivity>> activities =
        recordActivities.isNotEmpty
        ? _ensureActivitiesForDays(recordActivities, days)
        : (forceReset || state.dailyActivities.isEmpty
              ? defaultActivities
              : _ensureActivitiesForDays(state.dailyActivities, days));
    final Map<String, double> nafFactors = recordNafFactors.isNotEmpty
        ? _ensureNafForDays(recordNafFactors, days, defaultNafValue)
        : (forceReset || state.dailyNafFactors.isEmpty
              ? defaultNafFactors
              : _ensureNafForDays(
                  state.dailyNafFactors,
                  days,
                  defaultNafValue,
                ));

    // 3. Calcular TMBs iniciales
    // Usamos valores seguros por defecto si no hay registro antropométrico
    final double weight = record?.weightKg ?? 70.0;
    final double height = record?.heightCm ?? 170.0;

    debugPrint(
      '[DietaryProvider.initialize] Datos antropométricos (NORMALIZADOS):',
    );
    debugPrint('  - age: $age (normalizado desde birthDate o explícito)');
    debugPrint('  - gender: $genderNormalized (normalizado)');
    debugPrint('  - weight: $weight kg (record: ${record?.weightKg})');
    debugPrint('  - height: $height cm (record: ${record?.heightCm})');
    debugPrint('  - leanMass: $leanMass kg');
    debugPrint('  - bodyFat: $bodyFat%');

    final bool hasValidLBM = hasMeasuredComp && leanMass > 0;

    final tmbState = _calculateTMBs(
      weight: weight,
      height: height,
      age: age,
      gender: genderNormalized,
      leanMass: leanMass,
      bodyFat: bodyFat,
      isObese: isObese,
      hasValidLBM: hasValidLBM,
    );

    // Si no forzamos reset, intentamos mantener la fórmula seleccionada actual
    // si existe en los nuevos cálculos. Si no, usamos la default.
    final currentSelection = state.selectedTMBFormulaKey;
    final newSelection =
        (!forceReset && tmbState.calculations.containsKey(currentSelection))
        ? currentSelection
        : 'Mifflin-St. Jeor';

    final recordSelection = evalRecord?['selectedTmbFormulaKey']?.toString();
    final recordKcalRaw = evalRecord?['kcalTarget'] ?? evalRecord?['kcal'];
    final recordKcal = recordKcalRaw is num
        ? recordKcalRaw.toDouble()
        : double.tryParse(recordKcalRaw?.toString() ?? '');

    state = state.copyWith(
      selectedTMBFormulaKey:
          recordSelection != null &&
              tmbState.calculations.containsKey(recordSelection)
          ? recordSelection
          : newSelection,
      leanBodyMass: leanMass,
      bodyFatPercentage: bodyFat,
      isObese: isObese,
      hasLBM: hasValidLBM,
      dailyActivities: activities,
      dailyNafFactors: nafFactors,
      tmbCalculations: tmbState.calculations,
      calculatedAverageTMB: tmbState.average,
      finalKcal: recordKcal ?? client.nutrition.kcal?.toDouble() ?? 0.0,
    );
  }

  void updateTMBFormula(String key) {
    state = state.copyWith(selectedTMBFormulaKey: key);
  }

  void updateFinalKcal(double kcal) {
    state = state.copyWith(finalKcal: kcal);
  }

  void setNafFactor(String day, double factor) {
    final updated = Map<String, double>.from(state.dailyNafFactors);
    updated[day] = factor;
    state = state.copyWith(dailyNafFactors: updated);
  }

  void addActivity(String day, UserActivity activity) {
    final updated = _copyActivities();
    final dayList = List<UserActivity>.from(updated[day] ?? const []);
    dayList.add(activity);
    updated[day] = dayList;
    state = state.copyWith(dailyActivities: updated);
  }

  void removeActivity(String day, UserActivity activity) {
    final updated = _copyActivities();
    final dayList = List<UserActivity>.from(updated[day] ?? const []);
    dayList.remove(activity);
    updated[day] = dayList;
    state = state.copyWith(dailyActivities: updated);
  }

  void copyActivities({required String fromDay, required List<String> toDays}) {
    final source = List<UserActivity>.from(
      state.dailyActivities[fromDay] ?? const [],
    );
    final updated = _copyActivities();
    for (final day in toDays) {
      updated[day] = source
          .map(
            (activity) => UserActivity(
              day: day,
              metActivity: activity.metActivity,
              metValue: activity.metValue,
              durationMinutes: activity.durationMinutes,
            ),
          )
          .toList();
    }
    state = state.copyWith(dailyActivities: updated);
  }

  void copyNaf({required String fromDay, required List<String> toDays}) {
    final naf = state.dailyNafFactors[fromDay];
    if (naf == null) return;
    final updated = Map<String, double>.from(state.dailyNafFactors);
    for (final day in toDays) {
      updated[day] = naf;
    }
    state = state.copyWith(dailyNafFactors: updated);
  }

  Map<String, List<UserActivity>> _copyActivities() {
    final updated = <String, List<UserActivity>>{};
    for (final entry in state.dailyActivities.entries) {
      updated[entry.key] = List<UserActivity>.from(entry.value);
    }
    return updated;
  }

  Map<String, List<UserActivity>> _parseDailyActivities(dynamic raw) {
    if (raw is! Map) return {};
    final parsed = <String, List<UserActivity>>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is List) {
        final activities = <UserActivity>[];
        for (final item in value) {
          if (item is Map) {
            try {
              activities.add(
                UserActivity.fromJson(item.cast<String, dynamic>()),
              );
            } catch (_) {
              // Ignorar actividades con formato inválido
            }
          }
        }
        parsed[key] = activities;
      }
    }
    return parsed;
  }

  Map<String, double> _parseDailyNafFactors(dynamic raw) {
    if (raw is! Map) return {};
    final parsed = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final doubleValue = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      parsed[key] = doubleValue ?? nafRanges.first.factors.first;
    }
    return parsed;
  }

  Map<String, List<UserActivity>> _ensureActivitiesForDays(
    Map<String, List<UserActivity>> source,
    List<String> days,
  ) {
    final ensured = <String, List<UserActivity>>{};
    for (final day in days) {
      ensured[day] = List<UserActivity>.from(source[day] ?? const []);
    }
    return ensured;
  }

  Map<String, double> _ensureNafForDays(
    Map<String, double> source,
    List<String> days,
    double defaultValue,
  ) {
    final ensured = <String, double>{};
    for (final day in days) {
      ensured[day] = source[day] ?? defaultValue;
    }
    return ensured;
  }

  AnthropometryRecord? _anthropometryForDate(
    Client client,
    String? activeDateIso,
  ) {
    if (activeDateIso == null) return client.latestAnthropometryRecord;

    // Convertir activeDateIso a DateTime para usar el helper
    final parts = activeDateIso.split('-');
    if (parts.length != 3) return client.latestAnthropometryRecord;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return client.latestAnthropometryRecord;
    }

    final targetDate = DateTime(year, month, day);
    return client.latestAnthropometryAtOrBefore(targetDate) ??
        client.latestAnthropometryRecord;
  }

  // Composición corporal medida (ISAK / pliegues reales)
  bool _hasMeasuredBodyComposition(AnthropometryRecord r) {
    final folds = [
      r.tricipitalFold,
      r.subscapularFold,
      r.suprailiacFold,
      r.supraspinalFold,
      r.abdominalFold,
      r.thighFold,
      r.calfFold,
    ];

    return folds.where((v) => v != null && v > 0).length >= 4;
  }

  // ignore: unused_element
  bool _hasBasicEstimatedBodyFat(AnthropometryRecord r) {
    final dynamic v = r.individualMeasurements?['basicBodyFat'];
    if (v is List && v.isNotEmpty) {
      final first = v.first;
      return first is num && first > 0;
    }
    return false;
  }
  // --- Lógica Interna de Cálculo ---

  ({Map<String, TMBFormulaInfo> calculations, double average}) _calculateTMBs({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double leanMass,
    required double bodyFat,
    required bool isObese,
    required bool hasValidLBM,
  }) {
    debugPrint(
      '[DietaryProvider._calculateTMBs] weight=$weight, height=$height, age=$age, gender=$gender',
    );
    if (weight <= 0 || height <= 0 || age <= 0) {
      debugPrint(
        '[DietaryProvider._calculateTMBs] ❌ DATOS INSUFICIENTES - No se pueden calcular TMBs',
      );
      return (calculations: <String, TMBFormulaInfo>{}, average: 0.0);
    }

    final Map<String, TMBFormulaInfo> calcs = {};

    // Fórmulas estándar
    calcs['Mifflin-St. Jeor'] = TMBFormulaInfo(
      key: 'Mifflin-St. Jeor',
      population: 'Estándar de oro actual.',
      requires: 'Peso, Estatura, Edad',
      equation: gender == 'Hombre'
          ? 'TMB = (10 × peso) + (6.25 × altura) - (5 × edad) + 5'
          : 'TMB = (10 × peso) + (6.25 × altura) - (5 × edad) - 161',
      value: DietaryCalculator.calculateMifflin(weight, height, age, gender),
    );
    calcs['Harris-Benedict'] = TMBFormulaInfo(
      key: 'Harris-Benedict',
      population: 'Fórmula histórica.',
      requires: 'Peso, Estatura, Edad',
      equation: gender == 'Hombre'
          ? 'TMB = 66.5 + (13.75 × peso) + (5.003 × altura) - (6.755 × edad)'
          : 'TMB = 655.1 + (9.563 × peso) + (1.850 × altura) - (4.676 × edad)',
      value: DietaryCalculator.calculateHarrisBenedict(
        weight,
        height,
        age,
        gender,
      ),
    );

    if (hasValidLBM) {
      calcs['Katch-McArdle'] = TMBFormulaInfo(
        key: 'Katch-McArdle',
        population:
            'Ideal para individuos activos y atletas, ya que basa el cálculo únicamente en la Masa Libre de Grasa (MLG), el tejido metabólicamente activo.',
        requires: 'MLG',
        equation: 'TMB = 370 + (21.6 × MLG)',
        value: DietaryCalculator.calculateKatchMcArdle(leanMass),
        requiresLBM: true,
      );

      calcs['Cunningham'] = TMBFormulaInfo(
        key: 'Cunningham',
        population:
            'Variación de Katch-McArdle, también basada en MLG. Produce resultados muy similares y es una excelente alternativa para validar el cálculo en atletas.',
        requires: 'MLG',
        equation: 'TMB = 500 + (22 × MLG)',
        value: DietaryCalculator.calculateCunningham(leanMass),
        requiresLBM: true,
      );

      calcs['Tinsley'] = TMBFormulaInfo(
        key: 'Tinsley',
        population:
            'Específicamente desarrollada y validada en atletas de fuerza (culturistas, powerlifters). Considerada de alta precisión para este perfil demográfico.',
        requires: 'MLG',
        equation: gender == 'Hombre'
            ? 'TMB = (24.6 × MLG) + 466'
            : 'TMB = (25.1 × MLG) + 514',
        value: DietaryCalculator.calculateTinsley(leanMass, gender),
        requiresLBM: true,
      );
    }

    if (isObese) {
      calcs['Mifflin (Ajustado)'] = TMBFormulaInfo(
        key: 'Mifflin (Ajustado)',
        population:
            'Para obesidad sin MLG. Utiliza un "peso ajustado" para reducir el impacto del tejido adiposo (menos activo) y evitar sobreestimar el gasto.',
        requires: 'Peso, Estatura, Edad, %Grasa',
        equation:
            'Peso ajustado = PIB + 0.4 × (Peso - PIB)\nTMB = Mifflin-St. Jeor con peso ajustado',
        value: DietaryCalculator.calculateMifflinAdjusted(
          weight,
          height,
          age,
          gender,
          bodyFat,
        ),
        isObesityFormula: true,
      );

      if (hasValidLBM) {
        calcs['Müller (Obesidad)'] = TMBFormulaInfo(
          key: 'Müller (Obesidad)',
          population:
              'Fórmula avanzada para obesidad con datos de MLG. Calcula el gasto considerando la contribución metabólica separada de la masa grasa y la masa magra.',
          requires: 'MG + MLG',
          equation: gender == 'Hombre'
              ? 'TMB = (13.587 × MLG) + (9.613 × MG) + 198 - (3.351 × edad) + 674'
              : 'TMB = (13.587 × MLG) + (9.613 × MG) - (3.351 × edad) + 674',
          value: DietaryCalculator.calculateMullerObesity(
            weight,
            leanMass,
            age,
            gender,
          ),
          requiresLBM: true,
          isObesityFormula: true,
        );
      }
    }

    final values = calcs.values.where((e) => e.value > 0).toList();
    final avg = values.isEmpty
        ? 0.0
        : values.map((e) => e.value).reduce((a, b) => a + b) / values.length;

    return (calculations: calcs, average: avg);
  }
}

final dietaryProvider = NotifierProvider<DietaryNotifier, DietaryState>(
  DietaryNotifier.new,
);
