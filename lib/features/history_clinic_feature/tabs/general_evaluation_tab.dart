import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hcs_app_lap/core/constants/history_extra_keys.dart";
import "package:hcs_app_lap/core/constants/nutrition_extra_keys.dart";
import "package:hcs_app_lap/domain/entities/client.dart";
import "package:hcs_app_lap/domain/entities/client_profile.dart";
import "package:hcs_app_lap/domain/entities/clinical_history.dart";
import "package:hcs_app_lap/domain/entities/nutrition_settings.dart";
import "package:hcs_app_lap/domain/entities/training_profile.dart";
import "package:hcs_app_lap/features/main_shell/providers/clients_provider.dart";
import "package:hcs_app_lap/ui/clinic_section_surface.dart";
import "package:hcs_app_lap/utils/widgets/shared_form_widgets.dart";
import "package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart";

class GeneralEvaluationTab extends ConsumerStatefulWidget {
  const GeneralEvaluationTab({super.key});

  @override
  GeneralEvaluationTabState createState() => GeneralEvaluationTabState();
}

class _BinaryDetailField extends StatelessWidget {
  final String label;
  final bool value;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onDetailChanged;

  const _BinaryDetailField({
    required this.label,
    required this.value,
    required this.controller,
    required this.hintText,
    required this.onToggle,
    required this.onDetailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      label: label,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onChanged: onDetailChanged,
    );
  }
}

class _MealEntryControllers {
  _MealEntryControllers({
    required this.timeController,
    required this.descController,
  });

  final TextEditingController timeController;
  final TextEditingController descController;

  void dispose() {
    timeController.dispose();
    descController.dispose();
  }
}

class _TypicalDayMealsTable extends StatelessWidget {
  const _TypicalDayMealsTable({
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_MealEntryControllers> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...entries.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: controllers.timeController,
                    label: 'Hora',
                    hintText: '08:00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: CustomTextFormField(
                    controller: controllers.descController,
                    label: 'Descripción',
                    hintText: 'Ej: avena con fruta, café',
                    maxLines: 2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Añadir comida'),
          ),
        ),
      ],
    );
  }
}

class GeneralEvaluationTabState extends ConsumerState<GeneralEvaluationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;
  late ClientProfile _draftProfile;
  late ClinicalHistory _draftHistory;
  late NutritionSettings _draftNutrition;
  late TrainingProfile _draftTraining;

  bool _isDirty = false;
  bool _justSaved = false;
  bool _controllersReady = false;

  bool _hasAllergies = false;
  bool _usesMedications = false;
  bool _usesSupplements = false;
  bool _usesSuppPre = false;
  bool _usesSuppIntra = false;
  bool _usesSuppPost = false;
  bool _usesSuppHealth = false;
  bool _isCompetitor = false;

  late TextEditingController _preferencesController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationController;
  late TextEditingController _supplementController;
  late TextEditingController _typicalDayEatingController;
  late TextEditingController _dietHistoryController;
  late TextEditingController _supplementsPreController;
  late TextEditingController _supplementsIntraController;
  late TextEditingController _supplementsPostController;
  late TextEditingController _supplementsHealthController;
  late TextEditingController _preferredMealsPerDayController;
  late TextEditingController _weekdayCookingTimeController;
  late TextEditingController _weekendCookingTimeController;
  late TextEditingController _foodAccessController;
  late TextEditingController _budgetLevelController;
  late TextEditingController _eatingBehaviorNotesController;
  late TextEditingController _competitionCategoryController;
  late TextEditingController _pharmacologyProtocolController;
  late TextEditingController _peakWeekHistoryController;

  List<String> _foodAccessSelected = [];
  String? _dietHistoryOption;
  String? _preferredMealsPerDayOption;
  String? _weekdayCookingTimeOption;
  String? _weekendCookingTimeOption;
  String? _budgetLevelOption;

  final List<_MealEntryControllers> _mealEntries = [];

  final List<String> _dietHistoryOptions = const [
    'Nunca he seguido una dieta',
    'Dieta hipocalórica',
    'Dieta cetogénica',
    'Ayuno intermitente',
    'Alto en proteína',
    'Otro / personalizado',
  ];

  final List<String> _mealsPerDayOptions = const ['3', '4', '5', '6'];

  final List<String> _cookingTimeOptions = const [
    'Muy limitado (<20 min)',
    'Moderado (20-40 min)',
    'Amplio (>40 min)',
  ];

  final List<String> _foodAccessOptions = const [
    'Supermercado grande',
    'Mercado local / fresco',
    'Tiendita / mini super cercano',
    'Comedor o servicio de comida',
    'Delivery / apps frecuente',
  ];

  final List<String> _budgetLevelOptions = const [
    'Bajo: canasta básica ajustada',
    'Medio: presupuesto estable',
    'Alto: productos premium/frescos',
  ];

  String _safeString(dynamic value) => value?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _initializeFromClient(client);
    }
  }

  void _initializeFromClient(Client client) {
    _draftProfile = client.profile;
    _draftHistory = client.history;
    _draftNutrition = client.nutrition;
    _draftTraining = client.training;
    _resetMealEntries();

    String? normalizeOption(String? value, List<String> options) {
      if (value == null) return null;
      return options.contains(value) ? value : null;
    }

    _allergiesController = TextEditingController(
      text: _draftHistory.allergies ?? '',
    );
    _hasAllergies = _allergiesController.text.isNotEmpty;
    _preferencesController = TextEditingController(
      text: _safeString(_draftHistory.extra[HistoryExtraKeys.foodPreferences]),
    );
    _medicationController = TextEditingController(
      text: _draftHistory.medications ?? '',
    );
    _usesMedications = _medicationController.text.isNotEmpty;
    _supplementController = TextEditingController(
      text: _safeString(_draftHistory.extra[HistoryExtraKeys.supplementUse]),
    );
    _usesSupplements = _supplementController.text.isNotEmpty;
    _typicalDayEatingController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.typicalDayEating],
      ),
    );
    _dietHistoryController = TextEditingController(
      text: _safeString(_draftNutrition.extra[NutritionExtraKeys.dietHistory]),
    );
    _dietHistoryOption = normalizeOption(
      _dietHistoryController.text,
      _dietHistoryOptions,
    );
    _supplementsPreController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.supplementsPre],
      ),
    );
    _supplementsIntraController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.supplementsIntra],
      ),
    );
    _supplementsPostController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.supplementsPost],
      ),
    );
    _supplementsHealthController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.supplementsHealth],
      ),
    );
    _preferredMealsPerDayController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.preferredMealsPerDay],
      ),
    );
    _preferredMealsPerDayOption = normalizeOption(
      _preferredMealsPerDayController.text,
      _mealsPerDayOptions,
    );
    _weekdayCookingTimeController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.weekdayCookingTime],
      ),
    );
    _weekdayCookingTimeOption = normalizeOption(
      _weekdayCookingTimeController.text,
      _cookingTimeOptions,
    );
    _weekendCookingTimeController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.weekendCookingTime],
      ),
    );
    _weekendCookingTimeOption = normalizeOption(
      _weekendCookingTimeController.text,
      _cookingTimeOptions,
    );
    _foodAccessController = TextEditingController(
      text: _safeString(_draftNutrition.extra[NutritionExtraKeys.foodAccess]),
    );
    final foodAccessValue =
        _draftNutrition.extra[NutritionExtraKeys.foodAccess];
    if (foodAccessValue is List) {
      _foodAccessSelected = foodAccessValue.map(_safeString).toList();
    } else if (_foodAccessController.text.isNotEmpty) {
      _foodAccessSelected = _foodAccessController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      _foodAccessSelected = [];
    }
    _foodAccessSelected = _foodAccessSelected
        .where((e) => _foodAccessOptions.contains(e))
        .toList();
    _budgetLevelController = TextEditingController(
      text: _safeString(_draftNutrition.extra[NutritionExtraKeys.budgetLevel]),
    );
    _budgetLevelOption = normalizeOption(
      _budgetLevelController.text,
      _budgetLevelOptions,
    );
    _eatingBehaviorNotesController = TextEditingController(
      text: _safeString(
        _draftNutrition.extra[NutritionExtraKeys.eatingBehaviorNotes],
      ),
    );
    _usesSuppPre = _supplementsPreController.text.isNotEmpty;
    _usesSuppIntra = _supplementsIntraController.text.isNotEmpty;
    _usesSuppPost = _supplementsPostController.text.isNotEmpty;
    _usesSuppHealth = _supplementsHealthController.text.isNotEmpty;
    _loadMealEntriesFromExtra();
    _competitionCategoryController = TextEditingController(
      text: _draftTraining.competitionCategory ?? '',
    );
    _pharmacologyProtocolController = TextEditingController(
      text: _draftTraining.pharmacologyProtocol ?? '',
    );
    _peakWeekHistoryController = TextEditingController(
      text: _draftTraining.peakWeekHistory ?? '',
    );
    _isCompetitor = _draftTraining.isCompetitor;
    _isDirty = false;
    _controllersReady = true;
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  Map<String, dynamic> _copyHistoryExtra() =>
      Map<String, dynamic>.from(_draftHistory.extra);
  Map<String, dynamic> _copyNutritionExtra() =>
      Map<String, dynamic>.from(_draftNutrition.extra);

  void _resetMealEntries() {
    for (final entry in _mealEntries) {
      entry.dispose();
    }
    _mealEntries.clear();
  }

  void _loadMealEntriesFromExtra() {
    final entries =
        _draftNutrition.extra[NutritionExtraKeys.typicalDayEatingEntries];
    if (entries is List) {
      for (final e in entries) {
        if (e is Map) {
          _addMealEntry(
            time: _safeString(e['time']),
            description: _safeString(e['description']),
          );
        }
      }
    }
    if (_mealEntries.isEmpty) {
      final legacy = _safeString(
        _draftNutrition.extra[NutritionExtraKeys.typicalDayEating],
      );
      if (legacy.isNotEmpty) {
        _addMealEntry(description: legacy);
      }
    }
  }

  void _addMealEntry({String time = '', String description = ''}) {
    final entry = _MealEntryControllers(
      timeController: TextEditingController(text: time),
      descController: TextEditingController(text: description),
    );
    entry.timeController.addListener(_onMealEntriesChanged);
    entry.descController.addListener(_onMealEntriesChanged);
    _mealEntries.add(entry);
  }

  void _removeMealEntry(int index) {
    if (index < 0 || index >= _mealEntries.length) return;
    final entry = _mealEntries.removeAt(index);
    entry.dispose();
    _onMealEntriesChanged();
    setState(() {});
  }

  void _onMealEntriesChanged() {
    final extra = _copyNutritionExtra();
    final list = _mealEntries
        .map(
          (e) => {
            'time': e.timeController.text,
            'description': e.descController.text,
          },
        )
        .where(
          (e) =>
              e['time']!.toString().isNotEmpty ||
              e['description']!.toString().isNotEmpty,
        )
        .toList();
    extra[NutritionExtraKeys.typicalDayEatingEntries] = list;
    extra[NutritionExtraKeys.typicalDayEating] = list
        .map((e) => '${e['time'] ?? ''} ${e['description'] ?? ''}'.trim())
        .join(' | ');
    _draftNutrition = _draftNutrition.copyWith(extra: extra);
    _markDirty();
  }

  Future<Client?> saveIfDirty() async {
    if (!_isDirty || _client == null) return null;
    final updatedClient = _client!.copyWith(
      profile: _draftProfile,
      history: _draftHistory,
      nutrition: _draftNutrition,
      training: _draftTraining,
    );
    _isDirty = false;
    return updatedClient;
  }

  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient ?? _client;
    if (client == null) return;
    _client = client;
    _initializeFromClient(client);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    if (_client == null) return;
    final mergedHistoryExtra = {
      ..._client!.history.extra,
      ..._draftHistory.extra,
    };
    final mergedNutritionExtra = {
      ..._client!.nutrition.extra,
      ..._draftNutrition.extra,
    };
    final updatedClient = _client!.copyWith(
      profile: _draftProfile,
      history: _draftHistory.copyWith(extra: mergedHistoryExtra),
      nutrition: _draftNutrition.copyWith(extra: mergedNutritionExtra),
      training: _draftTraining,
    );
    _justSaved = true;
    try {
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        final mergedHistoryExtraFromPrev = {
          ...prev.history.extra,
          ...updatedClient.history.extra,
        };
        final mergedNutritionExtraFromPrev = {
          ...prev.nutrition.extra,
          ...updatedClient.nutrition.extra,
        };
        return prev.copyWith(
          profile: updatedClient.profile,
          history: updatedClient.history.copyWith(
            extra: mergedHistoryExtraFromPrev,
          ),
          nutrition: updatedClient.nutrition.copyWith(
            extra: mergedNutritionExtraFromPrev,
          ),
          training: updatedClient.training,
        );
      });
    } finally {
      _justSaved = false;
    }
    if (!mounted) return;
    _client = updatedClient;
    _isDirty = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evaluación general guardada')),
    );
  }

  @override
  void dispose() {
    if (_controllersReady) {
      _allergiesController.dispose();
      _preferencesController.dispose();
      _medicationController.dispose();
      _supplementController.dispose();
      _typicalDayEatingController.dispose();
      _dietHistoryController.dispose();
      _supplementsPreController.dispose();
      _supplementsIntraController.dispose();
      _supplementsPostController.dispose();
      _supplementsHealthController.dispose();
      _preferredMealsPerDayController.dispose();
      _weekdayCookingTimeController.dispose();
      _weekendCookingTimeController.dispose();
      _foodAccessController.dispose();
      _budgetLevelController.dispose();
      _eatingBehaviorNotesController.dispose();
      _competitionCategoryController.dispose();
      _pharmacologyProtocolController.dispose();
      _peakWeekHistoryController.dispose();
      for (final entry in _mealEntries) {
        entry.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(clientsProvider, (previous, next) {
      final nextClient = next.value?.activeClient;
      if (nextClient == null) return;
      final isDifferentClient = _client?.id != nextClient.id;
      if (_justSaved) return;
      if (isDifferentClient || !_isDirty) {
        _client = nextClient;
        _initializeFromClient(nextClient);
        setState(() {});
      }
    });

    final client = ref.watch(clientsProvider).value?.activeClient;
    final isDifferentClient = _client?.id != client?.id;
    if (_client == null ||
        (isDifferentClient && client != null) ||
        (!_isDirty && _client != client && client != null)) {
      _client = client;
      if (client != null) {
        _initializeFromClient(client);
      }
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TARJETA 1: HÁBITOS NUTRICIONALES ---
                ClinicSectionSurface(
                  icon: Icons.restaurant_menu,
                  title: 'Historial y Hábitos Nutricionales',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 16.0;
                          final halfWidth =
                              (constraints.maxWidth - spacing) / 2;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: halfWidth,
                                child: CustomTextFormField(
                                  controller: _preferencesController,
                                  label: 'Preferencias y Aversiones',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  onChanged: (v) {
                                    final extra = _copyHistoryExtra();
                                    extra[HistoryExtraKeys.foodPreferences] = v;
                                    _draftHistory = _draftHistory.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Alergias e Intolerancias',
                                  value: _hasAllergies,
                                  controller: _allergiesController,
                                  hintText: 'Ej: gluten, lacteos',
                                  onToggle: (val) {
                                    setState(() {
                                      _hasAllergies = val;
                                      if (!val) {
                                        _allergiesController.clear();
                                        _draftHistory = _draftHistory.copyWith(
                                          allergies: '',
                                        );
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    _draftHistory = _draftHistory.copyWith(
                                      allergies: v,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Uso de Fármacos',
                                  value: _usesMedications,
                                  controller: _medicationController,
                                  hintText: 'Ej: antihipertensivos',
                                  onToggle: (val) {
                                    setState(() {
                                      _usesMedications = val;
                                      if (!val) {
                                        _medicationController.clear();
                                        _draftHistory = _draftHistory.copyWith(
                                          medications: '',
                                        );
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    _draftHistory = _draftHistory.copyWith(
                                      medications: v,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Uso de Suplementos (General)',
                                  value: _usesSupplements,
                                  controller: _supplementController,
                                  hintText: 'Ej: creatina, omega 3',
                                  onToggle: (val) {
                                    setState(() {
                                      _usesSupplements = val;
                                      if (!val) {
                                        _supplementController.clear();
                                        final extra = _copyHistoryExtra();
                                        extra[HistoryExtraKeys.supplementUse] =
                                            '';
                                        _draftHistory = _draftHistory.copyWith(
                                          extra: extra,
                                        );
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    final extra = _copyHistoryExtra();
                                    extra[HistoryExtraKeys.supplementUse] = v;
                                    _draftHistory = _draftHistory.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- TARJETA 2: DÍA TÍPICO Y HÁBITOS ---
                ClinicSectionSurface(
                  icon: Icons.calendar_today,
                  title: 'Alimentación Diaria y Logística',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InputDecorator(
                        isFocused: true,
                        decoration: hcsDecoration(
                          context,
                          labelText: 'Describe un día típico de alimentación',
                          contentPadding: EdgeInsets.zero,
                        ),
                        child: _TypicalDayMealsTable(
                          entries: _mealEntries,
                          onAdd: () {
                            setState(() => _addMealEntry());
                          },
                          onRemove: (index) => _removeMealEntry(index),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 16.0;
                          final halfWidth =
                              (constraints.maxWidth - spacing) / 2;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: halfWidth,
                                child: CustomDropdownButton<String>(
                                  label: 'Historial de dietas y resultados',
                                  value: _dietHistoryOption,
                                  items: _dietHistoryOptions,
                                  onChanged: (v) {
                                    setState(() => _dietHistoryOption = v);
                                    _dietHistoryController.text = v ?? '';
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys.dietHistory] =
                                        v ?? '';
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                  itemLabelBuilder: (item) => item,
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: CustomDropdownButton<String>(
                                  label: 'Comidas preferidas al día',
                                  value: _preferredMealsPerDayOption,
                                  items: _mealsPerDayOptions,
                                  onChanged: (v) {
                                    setState(
                                      () => _preferredMealsPerDayOption = v,
                                    );
                                    _preferredMealsPerDayController.text =
                                        v ?? '';
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys
                                            .preferredMealsPerDay] =
                                        v ?? '';
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                  itemLabelBuilder: (item) => '$item comidas',
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: CustomDropdownButton<String>(
                                  label: 'Tiempo para cocinar (entre semana)',
                                  value: _weekdayCookingTimeOption,
                                  items: _cookingTimeOptions,
                                  onChanged: (v) {
                                    setState(
                                      () => _weekdayCookingTimeOption = v,
                                    );
                                    _weekdayCookingTimeController.text =
                                        v ?? '';
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys
                                            .weekdayCookingTime] =
                                        v ?? '';
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                  itemLabelBuilder: (item) => item,
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: CustomDropdownButton<String>(
                                  label: 'Tiempo para cocinar (fin de semana)',
                                  value: _weekendCookingTimeOption,
                                  items: _cookingTimeOptions,
                                  onChanged: (v) {
                                    setState(
                                      () => _weekendCookingTimeOption = v,
                                    );
                                    _weekendCookingTimeController.text =
                                        v ?? '';
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys
                                            .weekendCookingTime] =
                                        v ?? '';
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                  itemLabelBuilder: (item) => item,
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: MultiChipSection(
                                    title:
                                        'Acceso a alimentos (elige las que aplican)',
                                    options: _foodAccessOptions,
                                    selectedOptions: _foodAccessSelected,
                                    onUpdate: (list) {
                                      setState(
                                        () => _foodAccessSelected = list,
                                      );
                                      _foodAccessController.text = list.join(
                                        ', ',
                                      );
                                      final extra = _copyNutritionExtra();
                                      extra[NutritionExtraKeys.foodAccess] =
                                          List<String>.from(list);
                                      _draftNutrition = _draftNutrition
                                          .copyWith(extra: extra);
                                      _markDirty();
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: CustomDropdownButton<String>(
                                  label:
                                      'Presupuesto estimado para alimentación',
                                  value: _budgetLevelOption,
                                  items: _budgetLevelOptions,
                                  onChanged: (v) {
                                    setState(() => _budgetLevelOption = v);
                                    _budgetLevelController.text = v ?? '';
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys.budgetLevel] =
                                        v ?? '';
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                  itemLabelBuilder: (item) => item,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      CustomTextFormField(
                        controller: _eatingBehaviorNotesController,
                        label:
                            'Notas sobre relación con la comida (atracones, ansiedad, etc.)',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        onChanged: (v) {
                          final extra = _copyNutritionExtra();
                          extra[NutritionExtraKeys.eatingBehaviorNotes] = v;
                          _draftNutrition = _draftNutrition.copyWith(
                            extra: extra,
                          );
                          _markDirty();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- TARJETA 3: SUPLEMENTACIÓN ---
                ClinicSectionSurface(
                  icon: Icons.medication_liquid,
                  title: 'Suplementación Actual (Detallada)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 16.0;
                          final halfWidth =
                              (constraints.maxWidth - spacing) / 2;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Pre-Entreno',
                                  value: _usesSuppPre,
                                  controller: _supplementsPreController,
                                  hintText: 'Ej: cafeina, beta alanina',
                                  onToggle: (val) {
                                    setState(() {
                                      _usesSuppPre = val;
                                      if (!val) {
                                        _supplementsPreController.clear();
                                        final extra = _copyNutritionExtra();
                                        extra[NutritionExtraKeys
                                                .supplementsPre] =
                                            '';
                                        _draftNutrition = _draftNutrition
                                            .copyWith(extra: extra);
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys.supplementsPre] =
                                        v;
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Intra-Entreno',
                                  value: _usesSuppIntra,
                                  controller: _supplementsIntraController,
                                  hintText: 'Ej: electrolitos, EAA',
                                  onToggle: (val) {
                                    setState(() {
                                      _usesSuppIntra = val;
                                      if (!val) {
                                        _supplementsIntraController.clear();
                                        final extra = _copyNutritionExtra();
                                        extra[NutritionExtraKeys
                                                .supplementsIntra] =
                                            '';
                                        _draftNutrition = _draftNutrition
                                            .copyWith(extra: extra);
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys.supplementsIntra] =
                                        v;
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Post-Entreno',
                                  value: _usesSuppPost,
                                  controller: _supplementsPostController,
                                  hintText: 'Ej: whey, creatina',
                                  onToggle: (val) {
                                    setState(() {
                                      _usesSuppPost = val;
                                      if (!val) {
                                        _supplementsPostController.clear();
                                        final extra = _copyNutritionExtra();
                                        extra[NutritionExtraKeys
                                                .supplementsPost] =
                                            '';
                                        _draftNutrition = _draftNutrition
                                            .copyWith(extra: extra);
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys.supplementsPost] =
                                        v;
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                              SizedBox(
                                width: halfWidth,
                                child: _BinaryDetailField(
                                  label: 'Salud General (Vitaminas, etc.)',
                                  value: _usesSuppHealth,
                                  controller: _supplementsHealthController,
                                  hintText: 'Ej: Multivitamínico, Omega 3',
                                  onToggle: (val) {
                                    setState(() {
                                      _usesSuppHealth = val;
                                      if (!val) {
                                        _supplementsHealthController.clear();
                                        final extra = _copyNutritionExtra();
                                        extra[NutritionExtraKeys
                                                .supplementsHealth] =
                                            '';
                                        _draftNutrition = _draftNutrition
                                            .copyWith(extra: extra);
                                        _markDirty();
                                      }
                                    });
                                  },
                                  onDetailChanged: (v) {
                                    final extra = _copyNutritionExtra();
                                    extra[NutritionExtraKeys
                                            .supplementsHealth] =
                                        v;
                                    _draftNutrition = _draftNutrition.copyWith(
                                      extra: extra,
                                    );
                                    _markDirty();
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- TARJETA 4: CONTEXTO COMPETITIVO ---
                ClinicSectionSurface(
                  icon: Icons.emoji_events,
                  title: 'Contexto Competitivo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¿Competidor?',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: _isCompetitor,
                            onChanged: (val) {
                              setState(() {
                                _isCompetitor = val;
                                if (!val) {
                                  _competitionCategoryController.clear();
                                  _pharmacologyProtocolController.clear();
                                  _peakWeekHistoryController.clear();
                                }
                              });
                              _draftTraining = _draftTraining.copyWith(
                                isCompetitor: val,
                                competitionCategory:
                                    _competitionCategoryController.text,
                                pharmacologyProtocol:
                                    _pharmacologyProtocolController.text,
                                peakWeekHistory:
                                    _peakWeekHistoryController.text,
                              );
                              _markDirty();
                            },
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: [
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _competitionCategoryController,
                              label: 'Categoría de Competición',
                              onChanged: (v) {
                                _draftTraining = _draftTraining.copyWith(
                                  competitionCategory: v,
                                );
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _pharmacologyProtocolController,
                              label: 'Protocolo Farmacológico (si aplica)',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              onChanged: (v) {
                                _draftTraining = _draftTraining.copyWith(
                                  pharmacologyProtocol: v,
                                );
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _peakWeekHistoryController,
                              label: 'Experiencia en Peak Week',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              onChanged: (v) {
                                _draftTraining = _draftTraining.copyWith(
                                  peakWeekHistory: v,
                                );
                                _markDirty();
                              },
                            ),
                          ],
                        ),
                        crossFadeState: _isCompetitor
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton(
                    onPressed: _saveDraft,
                    child: const Text('Guardar Evaluación General'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
