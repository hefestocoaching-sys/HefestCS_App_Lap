import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/dietary_state_models.dart';
import 'package:hcs_app_lap/features/nutrition_feature/models/nutrition_blocked_state.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/dietary_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_blocked_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/dietary_activity_section.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/dietary_adjustment_section.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/dietary_tmb_section.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/utils/dietary_calculator.dart';
import 'package:hcs_app_lap/utils/save_messages.dart';
import 'package:hcs_app_lap/domain/entities/tmb_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/domain/services/record_deletion_service_provider.dart';
import 'package:hcs_app_lap/features/common_widgets/record_deletion_dialogs.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/nutrition_plan_result.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';

// -------------------------------------------------------------
// INICIO DE DietaryTab (CLASE COMPLETA)
// -------------------------------------------------------------

/// Enum para los tres estados del formulario
enum _TabMode {
  idle, // Estado inicial - solo vista general
  view, // Viendo registro existente (sin editar)
  editing, // Editando registro existente
  creating, // Creando nuevo registro
}

/// Constantes locales para evitar "magic strings/numbers"
const double _defaultNaf = 1.2;
const int _daysInWeek = 7;

class DietaryTab extends ConsumerStatefulWidget {
  final String activeDateIso;
  final Function(bool)?
  onViewStateChanged; // true = overview/idle, false = viewing/editing
  final Function(String)?
  onRecordSelected; // Notifica cuando se selecciona un registro (dateIso)

  const DietaryTab({
    super.key,
    required this.activeDateIso,
    this.onViewStateChanged,
    this.onRecordSelected,
  });

  @override
  ConsumerState<DietaryTab> createState() => DietaryTabState();
}

class DietaryTabState extends ConsumerState<DietaryTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Estado del formulario basado en modo
  late _TabMode _mode;
  String? _selectedRecordDateIso; // Fecha del registro siendo visto/editado

  // NEW: Déficit porcentual
  final TextEditingController _deficitPctController = TextEditingController(
    text: '0.15',
  );

  // Legacy (mantener para compatibilidad pero no usar)
  final TextEditingController _calorieAdjustmentController =
      TextEditingController(text: '0');
  final TextEditingController _weightGoalController = TextEditingController(
    text: '0',
  );

  final TextEditingController _tmbSelectedController = TextEditingController();
  final TextEditingController _getController = TextEditingController();
  final TextEditingController _metMinutesController = TextEditingController();
  final TextEditingController _kcalFinalController = TextEditingController();

  double _finalKcal = 0.0;

  // NEW: Variables de estado para déficit porcentual
  Map<String, int> _dailyTargetKcal = {};
  double _avgDailyDeficitKcal = 0.0;
  double _estimatedKgWeek = 0.0;
  double _estimatedKgMonth = 0.0;

  @override
  void initState() {
    super.initState();
    final initialClient = ref.read(clientsProvider).value?.activeClient;

    // Si activeDateIso está vacío, inicia en modo idle (overview)
    // Si no, inicia en modo view
    _mode = widget.activeDateIso.isEmpty ? _TabMode.idle : _TabMode.view;

    if (initialClient != null && widget.activeDateIso.isNotEmpty) {
      // Initialize the provider with the client's data first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(dietaryProvider.notifier)
            .initialize(
              initialClient,
              forceReset: true,
              activeDateIso: widget.activeDateIso,
            );
        // Now, load the local UI data (controllers) which depends on the provider's calculations.
        _loadClientData(initialClient);
      });
    }

    // Centralizamos la escucha de cambios del cliente aquí.
    ref.listenManual(clientsProvider, (previous, next) {
      final prevClient = previous?.value?.activeClient;
      final newClient = next.value?.activeClient;
      if (newClient != null && newClient != prevClient) {
        if (widget.activeDateIso.isNotEmpty) {
          // 1. Re-initialize the provider with the new client's data.
          // No forzamos reset para mantener la selección del usuario si es posible
          ref
              .read(dietaryProvider.notifier)
              .initialize(
                newClient,
                forceReset: false,
                activeDateIso: widget.activeDateIso,
              );
          // 2. Then, update the local state and controllers.
          setState(() {
            _loadClientData(newClient);
          });
        }
      }
    });

    _deficitPctController.addListener(_recalculateAll);
    _calorieAdjustmentController.addListener(_recalculateAll);
    _weightGoalController.addListener(_recalculateAll);
  }

  @override
  void dispose() {
    _deficitPctController.removeListener(_recalculateAll);
    _calorieAdjustmentController.removeListener(_recalculateAll);
    _weightGoalController.removeListener(_recalculateAll);
    _deficitPctController.dispose();
    _calorieAdjustmentController.dispose();
    _weightGoalController.dispose();
    _tmbSelectedController.dispose();
    _getController.dispose();
    _metMinutesController.dispose();
    _kcalFinalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DietaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeDateIso != oldWidget.activeDateIso) {
      debugPrint(
        '[DietaryTab.didUpdateWidget] activeDateIso cambió de ${oldWidget.activeDateIso} a ${widget.activeDateIso}',
      );
      // Usar addPostFrameCallback para evitar modificar state durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.activeDateIso.isEmpty) {
          // Si activeDateIso es vacío, volver a modo idle (overview)
          setState(() {
            _mode = _TabMode.idle;
            _selectedRecordDateIso = null;
          });
          widget.onViewStateChanged?.call(true);
        } else {
          final client = ref.read(clientsProvider).value?.activeClient;
          if (client != null && mounted) {
            ref
                .read(dietaryProvider.notifier)
                .initialize(
                  client,
                  forceReset: true,
                  activeDateIso: widget.activeDateIso,
                );
            setState(() {
              _loadClientData(client);
            });
          }
        }
      });
    }
  }

  // -------------------------------------------------------------
  // LOAD DATA
  // -------------------------------------------------------------
  void _loadClientData(Client? client) {
    if (client == null) return;
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final record =
        nutritionRecordForDate(records, widget.activeDateIso) ??
        latestNutritionRecordByDate(records);

    // Si no hay registro para esta fecha, iniciar en modo creating
    if (nutritionRecordForDate(records, widget.activeDateIso) == null) {
      _mode = _TabMode.creating;
    } else {
      _mode = _TabMode.view;
    }
    // Solo notificar si NO estamos en idle (overview)
    if (_mode != _TabMode.idle) {
      widget.onViewStateChanged?.call(false);
    }

    final double clientKcal =
        (record?['kcalTarget'] as num?)?.toDouble() ??
        (record?['kcal'] as num?)?.toDouble() ??
        client.nutrition.kcal?.toDouble() ??
        0.0;
    _finalKcal = clientKcal;

    // NEW: Cargar deficitPct con migración de legacy
    final savedDeficitPct = (record?['deficitPct'] as num?)?.toDouble();
    if (savedDeficitPct != null && savedDeficitPct > 0) {
      _deficitPctController.text = savedDeficitPct.toStringAsFixed(3);
    } else {
      // Legacy fallback
      final savedAdjustment =
          (record?['kcalAdjustment'] as num?)?.toDouble() ??
          double.tryParse(
            client.nutrition.extra[NutritionExtraKeys.kcalAdjustment]
                    ?.toString() ??
                '',
          );
      final avgGet =
          (record?['avgGet'] as num?)?.toDouble() ?? _calculateAverageGET();
      final migrated = DietaryCalculator.migrateDeficitPctFromLegacy(
        kcalAdjustment: savedAdjustment ?? 0.0,
        avgGet: avgGet,
      );
      _deficitPctController.text = migrated.toStringAsFixed(3);
    }

    // Legacy: mantener por compatibilidad lectura
    final savedAdjustment =
        (record?['kcalAdjustment'] as num?)?.toDouble() ??
        double.tryParse(
          client.nutrition.extra[NutritionExtraKeys.kcalAdjustment]
                  ?.toString() ??
              '',
        );
    _calorieAdjustmentController.text = savedAdjustment != null
        ? savedAdjustment.toStringAsFixed(0)
        : '0';

    final savedWeightGoal = (record?['weightGoal'] as num?)?.toDouble();
    _weightGoalController.text = savedWeightGoal != null
        ? savedWeightGoal.toStringAsFixed(2)
        : '0.00';

    _recalculateAll();
  }

  // -------------------------------------------------------------
  // RECOMENDACIÓN (para activar animación)
  // -------------------------------------------------------------
  String? get _recommendedFormula {
    final blockedState = ref.read(nutritionBlockedProvider);
    if (blockedState.isBlocked) return null;
    final client = ref.read(clientsProvider).value?.activeClient;
    return client != null
        ? DietaryCalculator.recommendTMBFormula(client).formulaKey
        : null;
  }

  // -------------------------------------------------------------
  // ALL CALCULATIONS
  // -------------------------------------------------------------
  void _recalculateAll() {
    if (!mounted) return;
    final blockedState = ref.read(nutritionBlockedProvider);
    if (blockedState.isBlocked) return;

    final baseTMB = _getBaseTMB();
    _tmbSelectedController.text = baseTMB.toStringAsFixed(0);

    final double avgMetMinutes = _calculateAvgMetMinutesPerDay();
    _metMinutesController.text = (avgMetMinutes * 7).toStringAsFixed(0);

    final double get = _calculateAverageGET();
    _getController.text = get.toStringAsFixed(0);

    // NEW v2: Calcular targets diarios con déficit porcentual
    final dietaryState = ref.read(dietaryProvider);
    final deficitPct = double.tryParse(_deficitPctController.text) ?? 0.15;
    const floorPct = 0.95;

    final Map<String, int> dailyTarget = {};
    for (final day in dietaryState.dailyActivities.keys) {
      final dailyGET = _calculateDailyGET(day);
      final target = DietaryCalculator.calculateTargetCaloriesPct(
        tmb: baseTMB,
        get: dailyGET,
        deficitPct: deficitPct,
        floorPct: floorPct,
      );
      dailyTarget[day] = target.round();
    }

    // Promedio para _finalKcal (compatibilidad UI/engine)
    if (dailyTarget.isNotEmpty) {
      final avg =
          dailyTarget.values.reduce((a, b) => a + b) / dailyTarget.length;
      _kcalFinalController.text = avg.toStringAsFixed(0);
      if (_finalKcal != avg) {
        setState(() {
          _finalKcal = avg;
          _dailyTargetKcal = dailyTarget;
        });
      }
      ref.read(dietaryProvider.notifier).updateFinalKcal(avg);
    }

    // Calcular déficit real promedio y estimaciones de kg
    final dailyGetMap = <String, double>{
      for (final day in dietaryState.dailyActivities.keys)
        day: _calculateDailyGET(day),
    };

    _avgDailyDeficitKcal = DietaryCalculator.calculateAverageDailyDeficitKcal(
      dailyGet: dailyGetMap,
      dailyTargetKcal: dailyTarget,
    );

    final est = DietaryCalculator.estimateWeightLossFromDeficit(
      avgDailyDeficitKcal: _avgDailyDeficitKcal,
    );

    setState(() {
      _estimatedKgWeek = est['kgWeek'] ?? 0.0;
      _estimatedKgMonth = est['kgMonth'] ?? 0.0;
    });
  }

  double _calculateDailyGET(String day) {
    final blockedState = ref.read(nutritionBlockedProvider);
    if (blockedState.isBlocked) return 0.0;
    final dietaryState = ref.read(dietaryProvider);
    final client = ref.read(clientsProvider).value?.activeClient;
    final baseTMB = _getBaseTMB();
    final naf = dietaryState.dailyNafFactors[day] ?? _defaultNaf;
    final metMinutes =
        dietaryState.dailyActivities[day]?.fold<double>(
          0.0,
          (sum, act) => sum + act.metMinutes,
        ) ??
        0.0;

    // Obtener peso corporal real del cliente (fallback conservador: 0)
    final bodyWeightKg = client?.latestAnthropometryRecord?.weightKg ?? 0.0;

    return DietaryCalculator.calculateTotalEnergyExpenditure(
      tmb: baseTMB,
      selectedNafFactor: naf,
      metMinutesPerDay: metMinutes,
      bodyWeightKg: bodyWeightKg,
    );
  }

  double _calculateAverageGET() {
    if (_getBaseTMB() <= 0) return 0.0;

    final dietaryState = ref.read(dietaryProvider);
    double weekly = 0;
    for (var day in dietaryState.dailyActivities.keys) {
      weekly += _calculateDailyGET(day);
    }
    return weekly / _daysInWeek;
  }

  double _getBaseTMB() {
    final dietaryState = ref.read(dietaryProvider);
    if (dietaryState.selectedTMBFormulaKey == 'Promedio') {
      return dietaryState.calculatedAverageTMB;
    }

    final entry =
        dietaryState.tmbCalculations[dietaryState.selectedTMBFormulaKey];
    if (entry == null || entry.value <= 0) return 0.0;

    return entry.value;
  }

  double _calculateAvgMetMinutesPerDay() {
    final dietaryState = ref.read(dietaryProvider);
    double sum = 0;
    for (var acts in dietaryState.dailyActivities.values) {
      for (var act in acts) {
        sum += act.metMinutes;
      }
    }
    return sum / _daysInWeek;
  }

  // -------------------------------------------------------------
  // WEIGHT GOAL (LEGACY - Mantener para compatibilidad pero no usar)
  // Deprecado: usar _setDeficitPct en su lugar
  // ignore: unused_element
  void _calculateAndSuggestDeficit(double weightGoal) {
    if (weightGoal == 0) {
      _calorieAdjustmentController.text = '0';
      return;
    }

    const days = 30;
    final required = DietaryCalculator.calculateDeficitForWeightGoal(
      weightGoal,
      days,
    );

    _calorieAdjustmentController.text = required.toStringAsFixed(0);
  }

  // NEW: Setter para deficitPct (v2)
  void _setDeficitPct(double pct) {
    _deficitPctController.text = pct.toStringAsFixed(3);
    _recalculateAll();
  }

  void _saveKcalToClient({bool showSnackbar = true}) {
    // GUARD: Validar que activeDateIso sea un formato ISO válido
    if (widget.activeDateIso.isEmpty) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Fecha no válida'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Intentar parsear la fecha para validar formato
    DateTime? targetDate;
    try {
      targetDate = DateTime.parse(widget.activeDateIso);
    } catch (e) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Formato de fecha inválido: ${widget.activeDateIso}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final blockedState = ref.read(nutritionBlockedProvider);
    if (blockedState.isBlocked) {
      if (showSnackbar && blockedState.userMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(blockedState.userMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }
    final dietaryState = ref.read(dietaryProvider);
    final baseTMB = _getBaseTMB();
    if (baseTMB <= 0) {
      String errorMsg = 'Error: TMB base seleccionado no es válido ';
      if (dietaryState.selectedTMBFormulaKey == 'Promedio') {
        errorMsg += '(el promedio es 0, verifica los datos base).';
      } else {
        final info =
            dietaryState.tmbCalculations[dietaryState.selectedTMBFormulaKey];
        if (info?.requiresLBM ?? false) {
          errorMsg += '(posiblemente falta MLG).';
        } else {
          errorMsg += '(datos insuficientes).';
        }
      }
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // Legacy: adjustmentKcal ya no se usa (calcs en _recalculateAll con déficit%)
    // final double adjustmentKcal =
    //     double.tryParse(_calorieAdjustmentController.text) ?? 0;
    // final double weightGoal =
    //     double.tryParse(_weightGoalController.text) ?? 0.0;

    // Recalcular dailyGet y dailyActivities para persistencia
    final Map<String, double> dailyGet = {};
    final Map<String, List<Map<String, dynamic>>> dailyActivities = {};
    for (var day in dietaryState.dailyActivities.keys) {
      dailyGet[day] = _calculateDailyGET(day);
      dailyActivities[day] =
          dietaryState.dailyActivities[day]
              ?.map((activity) => activity.toJson())
              .toList() ??
          const <Map<String, dynamic>>[];
    }

    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    // Merge records into persisted nutrition.extra to avoid overwriting other keys
    final recordsKey = NutritionExtraKeys.evaluationRecords;
    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(extra[recordsKey]);
      records.removeWhere(
        (record) => record['dateIso']?.toString() == widget.activeDateIso,
      );

      // NEW v2: Preparar datos de déficit porcentual
      final deficitPct = double.tryParse(_deficitPctController.text) ?? 0.15;
      const floorPct = 0.95;

      records.add({
        'dateIso': widget.activeDateIso,
        'selectedTmbFormulaKey': dietaryState.selectedTMBFormulaKey,
        'tmbValue': baseTMB,
        'avgGet': _calculateAverageGET(),
        'dailyGet': dailyGet,
        'dailyNafFactors': dietaryState.dailyNafFactors,
        'dailyActivities': dailyActivities,
        'kcalTarget': _finalKcal.toInt(),
        'kcal': _finalKcal.toInt(),
        'dailyKcal': _dailyTargetKcal, // NEW: targets diarios finales
        // NEW v2: Déficit porcentual y estimaciones
        'deficitPct': deficitPct,
        'floorPct': floorPct,
        'deficitKcalAvg': _avgDailyDeficitKcal,
        'estimatedKgWeek': _estimatedKgWeek,
        'estimatedKgMonth': _estimatedKgMonth,

        // Legacy: mantener para no romper lecturas viejas
        'kcalAdjustment': 0.0,
        'weightGoal': 0.0,

        'computedAtIso': DateTime.now().toIso8601String(),
      });
      sortNutritionRecordsByDate(records);
      final merged = Map<String, dynamic>.from(current.nutrition.extra);
      merged[recordsKey] = records;
      return current.copyWith(
        nutrition: current.nutrition.copyWith(extra: merged),
      );
    });

    if (showSnackbar) {
      final feedback = SaveActionDetector.getFeedback(
        readNutritionRecordList(
          client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
        ),
        targetDate,
        (record) {
          final dateIsoStr = record['dateIso'].toString();
          try {
            return DateTime.parse(dateIsoStr);
          } catch (e) {
            // Fallback a epoch si el formato es inválido
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedback),
          backgroundColor: kPrimaryColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void commitChanges() {
    // SOLO guardar si hay cambios pendientes (editing o creating)
    // NO guardar en idle (sin acción del usuario) ni en view (solo leyendo)
    if (_mode == _TabMode.editing || _mode == _TabMode.creating) {
      _saveKcalToClient(showSnackbar: false);
    }
  }

  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;
    ref
        .read(dietaryProvider.notifier)
        .initialize(
          client,
          forceReset: true,
          activeDateIso: widget.activeDateIso,
        );
    if (mounted) {
      setState(() {
        _loadClientData(client);
      });
    }
  }

  void _showTMBRecommendation() {
    final dietaryState = ref.read(dietaryProvider);
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;
    final TMBRecommendation recommendation =
        DietaryCalculator.recommendTMBFormula(client);
    final String recommendedKey = recommendation.formulaKey;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Text(
          recommendation.title,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecommendationSection(
                'Perfil Considerado',
                recommendation.clientProfileSummary,
              ),
              const Divider(height: 24, color: kAppBarColor),
              _buildRecommendationSection(
                'Fórmula Recomendada: $recommendedKey',
                recommendation.reasoning,
                isBold: true,
              ),
              if (recommendation.alternativeConsiderations != null) ...[
                const Divider(height: 24, color: kAppBarColor),
                _buildRecommendationSection(
                  'Otras Consideraciones',
                  recommendation.alternativeConsiderations!,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: kTextColorSecondary),
            ),
          ),
          if (recommendedKey != dietaryState.selectedTMBFormulaKey &&
              dietaryState.tmbCalculations.containsKey(recommendedKey) &&
              dietaryState.tmbCalculations[recommendedKey]!.value > 0)
            ElevatedButton(
              onPressed: () {
                ref
                    .read(dietaryProvider.notifier)
                    .updateTMBFormula(recommendedKey);
                _recalculateAll();
                Navigator.of(context).pop();
              },
              child: const Text('Usar recomendada'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(
    String title,
    String content, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isBold ? kTextColor : kTextColorSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: isBold
                ? kTextColor.withValues(alpha: 0.9)
                : kTextColorSecondary,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _onAddActivity(String day, UserActivity activity) {
    ref.read(dietaryProvider.notifier).addActivity(day, activity);
    _recalculateAll();
  }

  void _onRemoveActivity(String day, UserActivity activity) {
    ref.read(dietaryProvider.notifier).removeActivity(day, activity);
    _recalculateAll();
  }

  void _onCopyActivities(String fromDay, List<String> toDays) {
    ref
        .read(dietaryProvider.notifier)
        .copyActivities(fromDay: fromDay, toDays: toDays);
    _recalculateAll();
  }

  void _onSetNaf(String day, double naf) {
    ref.read(dietaryProvider.notifier).setNafFactor(day, naf);
    _recalculateAll();
  }

  void _onCopyNaf(String fromDay, List<String> toDays) {
    ref
        .read(dietaryProvider.notifier)
        .copyNaf(fromDay: fromDay, toDays: toDays);
    _recalculateAll();
  }

  // -------------------------------------------------------------
  // MÉTODOS DE NAVEGACIÓN DE MODOS (Plantilla Clínica)
  // -------------------------------------------------------------

  void _loadRecordInViewMode(dynamic recordOrDateIso) {
    final String recordDateIso;

    if (recordOrDateIso is String) {
      recordDateIso = recordOrDateIso;
    } else if (recordOrDateIso is Map<String, dynamic>) {
      recordDateIso =
          recordOrDateIso['dateIso']?.toString() ?? widget.activeDateIso;
    } else {
      recordDateIso = widget.activeDateIso;
    }

    debugPrint('\n========================================');
    debugPrint('[DietaryTab] Loading record in view mode: $recordDateIso');
    debugPrint('========================================\n');

    setState(() {
      _selectedRecordDateIso = recordDateIso;
      _mode = _TabMode.view;
      debugPrint(
        '[DietaryTab] setState: _selectedRecordDateIso=$_selectedRecordDateIso, _mode=$_mode',
      );
    });
    // Notificar al parent que se está viendo un registro
    widget.onViewStateChanged?.call(false);
    // Notificar al parent qué registro fue seleccionado
    widget.onRecordSelected?.call(recordDateIso);

    // Mostrar SnackBar para feedback visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registro cargado: ${DateFormat('d MMM yyyy', 'es').format(DateTime.parse(recordDateIso))}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: kPrimaryColor,
        ),
      );
    }

    // Cargar datos del registro seleccionado en la UI
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      ref
          .read(dietaryProvider.notifier)
          .initialize(client, forceReset: true, activeDateIso: recordDateIso);
      _loadClientData(client);
    }
  }

  void _enableEditMode() {
    setState(() {
      _mode = _TabMode.editing;
    });
    // Notificar al parent que se está editando
    widget.onViewStateChanged?.call(false);
  }

  void _cancelEdit() {
    if (_selectedRecordDateIso != null) {
      // Volver a VIEW mode
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client != null) {
        final records = readNutritionRecordList(
          client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
        );
        final record = nutritionRecordForDate(records, _selectedRecordDateIso!);
        if (record != null) {
          _loadRecordInViewMode(record);
        }
      }
    } else {
      // Resetear a modo CREATING
      _resetToCreating();
    }
  }

  void _resetToCreating() {
    debugPrint('\n========================================');
    debugPrint('[DietaryTab] Opening new calculation mode');
    debugPrint('========================================\n');

    setState(() {
      _selectedRecordDateIso = null;
      _mode = _TabMode.creating;
    });
    // Notificar al parent que se está creando nuevo registro
    widget.onViewStateChanged?.call(false);

    // Mostrar SnackBar para feedback visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo nuevo cálculo'),
          duration: Duration(seconds: 1),
          backgroundColor: kPrimaryColor,
        ),
      );
    }

    // Reinicializar con la fecha activa
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      ref
          .read(dietaryProvider.notifier)
          .initialize(
            client,
            forceReset: true,
            activeDateIso: widget.activeDateIso,
          );
      _loadClientData(client);
    }
  }

  void _resetToIdle() {
    debugPrint('\n========================================');
    debugPrint('[DietaryTab] Returning to overview');
    debugPrint('========================================\n');

    setState(() {
      _selectedRecordDateIso = null;
      _mode = _TabMode.idle;
    });
    // Notificar al padre que volvimos al overview.
    // El padre difiere su setState con addPostFrameCallback, evitando
    // "setState during build".
    widget.onViewStateChanged?.call(true);

    // Mostrar SnackBar para feedback visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volviendo a lista de cálculos'),
          duration: Duration(seconds: 1),
          backgroundColor: kPrimaryColor,
        ),
      );
    }
  }

  Future<void> _deleteSelectedRecord() async {
    final dateTime = DateTime.tryParse(widget.activeDateIso);
    if (dateTime == null) return;

    final targetIso = dateIsoFrom(dateTime);

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      date: dateTime,
      recordType: 'Requerimientos Nutricionales',
    );

    if (!confirmed || !mounted) return;

    try {
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client == null) return;

      final deletionService = ref.read(recordDeletionServiceProvider);
      await deletionService.deleteNutritionByDate(
        clientId: client.id,
        date: dateTime,
        onError: (e) {
          // Log error pero no bloquea UI (fire-and-forget)
          // ignore: avoid_print
          print('Error al borrar nutrición: $e');
        },
      );

      if (!mounted) return;

      final clientRef = client;
      // Remover registro localmente
      final extra = Map<String, dynamic>.from(clientRef.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.evaluationRecords],
      );
      final filtered = records.where((record) {
        final iso = record['dateIso']?.toString();
        if (iso == null) return true;
        final parsed = DateTime.tryParse(iso);
        if (parsed == null) return true;
        final normalized = dateIsoFrom(parsed);
        return normalized != targetIso;
      }).toList();
      extra[NutritionExtraKeys.evaluationRecords] = filtered;

      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        final merged = Map<String, dynamic>.from(prev.nutrition.extra);
        merged[NutritionExtraKeys.evaluationRecords] = filtered;
        return prev.copyWith(nutrition: prev.nutrition.copyWith(extra: merged));
      });

      // Re inicializar provider para refrescar UI
      ref
          .read(dietaryProvider.notifier)
          .initialize(
            client,
            forceReset: true,
            activeDateIso: widget.activeDateIso,
          );

      // Recargar datos después de borrar
      setState(() {
        _loadClientData(client);
      });

      // Mostrar confirmación
      if (mounted) {
        showDeleteSuccessSnackbar(context, dateTime, 'Nutrición');
      }
    } catch (e) {
      if (mounted) {
        showDeleteErrorSnackbar(context, Exception('Error: $e'));
      }
    }
  }

  /// Botones para modo view (cuando hay un registro seleccionado)
  Widget _buildViewModeButtons(NutritionBlockedState blockedState) {
    debugPrint(
      '[DietaryTab._buildViewModeButtons] 🔵 BUILDING 3 VIEW BUTTONS (Edit, Delete, Close)',
    );
    final returnButton = FloatingActionButton.extended(
      heroTag: 'diet_view_return',
      onPressed: _resetToIdle,
      label: const Text('Volver'),
      icon: const Icon(Icons.arrow_back),
    );
    final primaryButton = FloatingActionButton.extended(
      heroTag: 'diet_view_edit',
      onPressed: _enableEditMode,
      label: Text(SaveMessages.buttonEditRecord),
      icon: const Icon(Icons.edit),
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    );
    final secondaryButton = FloatingActionButton.extended(
      heroTag: 'diet_view_delete',
      onPressed: _deleteSelectedRecord,
      label: const Text('Borrar'),
      icon: const Icon(Icons.delete_outline),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        returnButton,
        const SizedBox(width: 8),
        secondaryButton,
        const SizedBox(width: 8),
        primaryButton,
      ],
    );
  }

  Widget? _buildActionButtons() {
    final blockedState = ref.watch(nutritionBlockedProvider);

    debugPrint(
      '[DietaryTab._buildActionButtons] CALLED - _selectedRecordDateIso=$_selectedRecordDateIso, _mode=$_mode',
    );

    Widget primaryButton;
    late final Widget secondaryButton;

    switch (_mode) {
      case _TabMode.view:
        return _buildViewModeButtons(blockedState);
      case _TabMode.editing:
        primaryButton = FloatingActionButton.extended(
          heroTag: 'diet_save_edit',
          onPressed: blockedState.isBlocked
              ? null
              : () {
                  _saveKcalToClient();
                  setState(() {
                    _mode = _TabMode.view;
                  });
                  // Notificar al parent que volvió a view
                  widget.onViewStateChanged?.call(false);
                },
          label: Text(SaveMessages.buttonSaveChanges),
          icon: const Icon(Icons.save),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        );
        secondaryButton = FloatingActionButton.extended(
          heroTag: 'diet_cancel_edit',
          onPressed: _cancelEdit,
          label: const Text('Cancelar'),
          icon: const Icon(Icons.close),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        );
        break;
      case _TabMode.creating:
        primaryButton = FloatingActionButton.extended(
          heroTag: 'diet_save_new',
          onPressed: blockedState.isBlocked
              ? null
              : () {
                  _saveKcalToClient();
                  setState(() {
                    _mode = _TabMode.view;
                  });
                },
          label: Text(SaveMessages.buttonCreateNew),
          icon: const Icon(Icons.save),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        );
        secondaryButton = FloatingActionButton.extended(
          heroTag: 'diet_cancel_new',
          onPressed: () {
            setState(() {
              _mode = _TabMode.view;
            });
            // Notificar al parent que volvió a view
            widget.onViewStateChanged?.call(false);
          },
          label: const Text('Cancelar'),
          icon: const Icon(Icons.close),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        );
        break;
      case _TabMode.idle:
        // Idle ya no se usa, redirigir a view
        return _buildViewModeButtons(blockedState);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [secondaryButton, const SizedBox(width: 8), primaryButton],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final client = ref.watch(clientsProvider).value?.activeClient;
    final dietaryState = ref.watch(dietaryProvider);
    final blockedState = ref.watch(nutritionBlockedProvider);

    if (client == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si activeDateIso está vacío, mostrar overview (grid de registros)
    if (widget.activeDateIso.isEmpty) {
      return _buildOverviewOnly(client);
    }

    // Obtener el registro actual
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );

    Map<String, dynamic>? currentRecord;
    if (_selectedRecordDateIso != null) {
      currentRecord = nutritionRecordForDate(records, _selectedRecordDateIso!);
    } else {
      currentRecord =
          nutritionRecordForDate(records, widget.activeDateIso) ??
          latestNutritionRecordByDate(records);
    }

    debugPrint(
      '[DietaryTab.build] Final state: _selectedRecordDateIso=$_selectedRecordDateIso, _mode=$_mode, currentRecord=${currentRecord != null}, totalRecords=${records.length}',
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 100.0),
              child: _buildFormSection(dietaryState, blockedState),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // OVERVIEW (sin formulario)
  // =====================================================================
  Widget _buildOverviewOnly(Client client) {
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final sortedRecords = [...records]
      ..sort((a, b) => (b['dateIso'] ?? '').compareTo(a['dateIso'] ?? ''));

    widget.onViewStateChanged?.call(true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: sortedRecords.length + 1, // +1 para "Nuevo cálculo"
                itemBuilder: (context, index) {
                  // Primer item: botón estilo tarjeta para nuevo cálculo
                  if (index == 0) {
                    return InkWell(
                      onTap: () {
                        final todayIso = dateIsoFrom(DateTime.now());
                        widget.onRecordSelected?.call(todayIso);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryColor.withAlpha(51),
                              kPrimaryColor.withAlpha(26),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryColor.withAlpha(128),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 48, color: kPrimaryColor),
                            const SizedBox(height: 12),
                            Text(
                              'Nuevo cálculo',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Tarjetas de registros existentes
                  final record = sortedRecords[index - 1];
                  final dateIsoRaw = record['dateIso']?.toString() ?? '';
                  final dateIso = dateIsoRaw.isNotEmpty
                      ? dateIsoRaw
                      : dateIsoFrom(DateTime.now());

                  DateTime date;
                  try {
                    date = DateTime.tryParse(dateIso) ?? DateTime.now();
                  } catch (_) {
                    date = DateTime.now();
                  }

                  final day = DateFormat('d').format(date);
                  final monthYear = DateFormat(
                    'MMM yyyy',
                    'es',
                  ).format(date).toUpperCase();
                  final kcal =
                      (record['kcalTarget'] as num?)?.toDouble() ??
                      (record['kcal'] as num?)?.toDouble() ??
                      0.0;

                  return InkWell(
                    onTap: () {
                      _loadRecordInViewMode(dateIso);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kCardColor.withAlpha((255 * 0.30).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade700,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthYear,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextColorSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${kcal.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    );
  }

  Widget _buildNutritionEngineValidation(NutritionPlanResult? result) {
    if (result == null) return const SizedBox.shrink();

    final minProtein = result.minProteinPerMeal;
    final statusIcon = result.needsReview
        ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
        : const Icon(Icons.check_circle, color: Colors.green);
    String formatEq(Map<String, double> eq) {
      const labels = {
        'aoa_bajo_grasa': 'AOA bajo',
        'cereales_sin_grasa': 'Cereal s/ grasa',
        'aceites_sin_proteina': 'Aceite/grasas',
      };
      return eq.entries
          .where((e) => e.value > 0)
          .map(
            (e) => '${labels[e.key] ?? e.key} ${e.value.toStringAsFixed(1)} eq',
          )
          .join(', ');
    }

    String formatGrams(Map<String, double> grams) {
      return grams.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.key}: ${e.value.toStringAsFixed(1)} g')
          .join(', ');
    }

    return ExpansionTile(
      title: const Text('Validación técnica del motor (solo lectura)'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildSummaryItem(
                'Kcal/día',
                result.kcalTargetDay.toStringAsFixed(0),
              ),
              _buildSummaryItem('Comidas/día', result.mealsPerDay.toString()),
              _buildSummaryItem(
                'Proteína mínima/meal',
                '${minProtein.toStringAsFixed(1)} g',
              ),
              _buildSummaryItem(
                'Umbral mTOR',
                '${result.proteinFactor.toStringAsFixed(1)} g/kg (mín. 25 g)',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cumple mTOR'),
                  const SizedBox(width: 6),
                  result.mtOrProteinThresholdMet
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('needsReview'),
                  const SizedBox(width: 6),
                  statusIcon,
                ],
              ),
              if (result.note != null && result.note!.isNotEmpty)
                _buildSummaryItem('note', result.note!),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: result.mealTargets.map((meal) {
              final warn = meal.proteinG < minProtein;
              final eqList = result.mealEquivalents;
              final mealEq = eqList != null && meal.mealIndex < eqList.length
                  ? eqList[meal.mealIndex]
                  : null;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('Comida ${meal.mealIndex + 1}')),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${meal.kcal.toStringAsFixed(0)} kcal'),
                            const SizedBox(width: 12),
                            Text(
                              'P ${meal.proteinG.toStringAsFixed(1)}g',
                              style: TextStyle(
                                color: warn ? Colors.orange.shade800 : null,
                                fontWeight: warn ? FontWeight.w600 : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('C ${meal.carbG.toStringAsFixed(1)}g'),
                            const SizedBox(width: 8),
                            Text('G ${meal.fatG.toStringAsFixed(1)}g'),
                            if (warn) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (mealEq != null) ...[
                      const SizedBox(height: 8),
                      Text('Equivalentes v1: ${formatEq(mealEq.equivalents)}'),
                      Text(
                        'Gramajes (cocido/listo): ${formatGrams(mealEq.gramsByFood)}',
                      ),
                      if (mealEq.warnings.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...mealEq.warnings.map(
                          (w) => Text(
                            '⚠️ $w',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Sección de formulario completo (solo visible en EDITING o CREATING)
  /// Patrón: Column con ClinicalSection (evita nested SingleChildScrollView)
  Widget _buildFormSection(
    DietaryState dietaryState,
    NutritionBlockedState blockedState,
  ) {
    final planResult = ref.watch(nutritionPlanResultProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ⚠️ Mensaje de bloqueo (si aplica)
        if (blockedState.isBlocked && blockedState.userMessage.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha((255 * 0.12).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withAlpha((255 * 0.35).round()),
              ),
            ),
            child: Text(
              blockedState.userMessage,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // ✅ Sección 1: TMB
        ClinicSectionSurface(
          icon: Icons.local_fire_department,
          title: 'Tasa Metabólica Basal (TMB)',
          child: Builder(
            builder: (context) {
              debugPrint('[DietaryTab] Rendering TMB section:');
              debugPrint(
                '  - selectedFormulaKey: ${dietaryState.selectedTMBFormulaKey}',
              );
              debugPrint(
                '  - tmbCalculations count: ${dietaryState.tmbCalculations.length}',
              );
              debugPrint(
                '  - calculatedAverageTMB: ${dietaryState.calculatedAverageTMB}',
              );
              debugPrint('  - currentTMBValue: ${_getBaseTMB()}');
              return DietaryTmbSection(
                selectedFormulaKey: dietaryState.selectedTMBFormulaKey,
                tmbCalculations: dietaryState.tmbCalculations,
                calculatedAverageTMB: dietaryState.calculatedAverageTMB,
                currentTMBValue: _getBaseTMB(),
                recommendedFormulaKey: _recommendedFormula,
                onFormulaSelected: (key) {
                  ref.read(dietaryProvider.notifier).updateTMBFormula(key);
                  _recalculateAll();
                },
                onShowRecommendation: _showTMBRecommendation,
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // ✅ Sección 2: Actividades + NAF
        ClinicSectionSurface(
          icon: Icons.fitness_center,
          title: 'Gasto por Ejercicio (EAT) y NAF Diario',
          child: DietaryActivitySection(
            dailyActivities: dietaryState.dailyActivities,
            dailyNafFactors: dietaryState.dailyNafFactors,
            calculateDailyGET: _calculateDailyGET,
            onAddActivity: _onAddActivity,
            onRemoveActivity: _onRemoveActivity,
            onCopyActivities: _onCopyActivities,
            onSetNaf: _onSetNaf,
            onCopyNaf: _onCopyNaf,
          ),
        ),

        const SizedBox(height: 32),

        // ✅ Sección 3: Ajuste Final
        ClinicSectionSurface(
          icon: Icons.scale,
          title: 'Ajuste Final y Objetivo',
          child: DietaryAdjustmentSection(
            deficitPctController: _deficitPctController,
            avgDailyDeficitKcal: _avgDailyDeficitKcal,
            estimatedKgWeek: _estimatedKgWeek,
            estimatedKgMonth: _estimatedKgMonth,
            days: dietaryState.dailyActivities.keys.toList(),
            calculateDailyGET: _calculateDailyGET,
            calculateDailyTargetKcal: (day) =>
                _dailyTargetKcal[day] ?? _calculateDailyGET(day).round(),
            onDeficitPctChanged: _setDeficitPct,
          ),
        ),

        const SizedBox(height: 32),

        // ✅ Validación del motor nutritivo
        _buildNutritionEngineValidation(planResult),
      ],
    );
  }
}
