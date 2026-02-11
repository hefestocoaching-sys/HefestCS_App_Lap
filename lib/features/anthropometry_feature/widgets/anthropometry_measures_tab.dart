import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/ui_helpers.dart';
import 'package:hcs_app_lap/utils/save_messages.dart';
import 'package:hcs_app_lap/utils/widgets/record_history_panel.dart';
import 'package:hcs_app_lap/utils/record_helpers.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';
import 'package:hcs_app_lap/data/repositories/client_repository_provider.dart';
import 'package:hcs_app_lap/domain/services/record_deletion_service_provider.dart';
import 'package:hcs_app_lap/features/common_widgets/record_deletion_dialogs.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';

// Estados de vista del flujo
enum AnthropometryViewState {
  idle,
  creatingInitial,
  creatingNew,
  viewingHistory,
  editingHistory,
}

enum MeasurementMethod { isak, rfm, basic }

class AnthropometryMeasuresTab extends ConsumerStatefulWidget {
  final VoidCallback? onStateChanged;
  final Function(AnthropometryViewState)? onViewStateChanged;

  const AnthropometryMeasuresTab({
    super.key,
    this.onStateChanged,
    this.onViewStateChanged,
  });

  @override
  ConsumerState<AnthropometryMeasuresTab> createState() =>
      AnthropometryMeasuresTabState();
}

class AnthropometryMeasuresTabState
    extends ConsumerState<AnthropometryMeasuresTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Estado del flujo
  late AnthropometryViewState _viewState;
  DateTime? _selectedRecordDate;

  // Controladores
  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _rfmWaistController = TextEditingController();
  final _rfmNeckController = TextEditingController();
  final _rfmTricipitalController = TextEditingController();
  final _rfmSupraspinalController = TextEditingController();
  final Map<String, List<TextEditingController>> _measurementControllers = {};
  final Map<String, double?> _finalValues = {};
  final Map<String, bool> _showThirdMeasurement = {};
  final Map<String, String?> _errorMessages = {};
  MeasurementMethod _measurementMethod = MeasurementMethod.isak;
  double? _rfmValue;

  Client? _client;
  bool _isHistoryExpanded = false;

  final List<Map<String, dynamic>> _measurementSites = [
    {
      'key': 'tricipitalFold',
      'label': 'Tricipital',
      'unit': 'mm',
      'threshold': 5.0,
    },
    {
      'key': 'subscapularFold',
      'label': 'Subescapular',
      'unit': 'mm',
      'threshold': 5.0,
    },
    {
      'key': 'suprailiacFold',
      'label': 'Suprailíaco',
      'unit': 'mm',
      'threshold': 5.0,
    },
    {
      'key': 'supraspinalFold',
      'label': 'Supraespinal',
      'unit': 'mm',
      'threshold': 5.0,
    },
    {
      'key': 'abdominalFold',
      'label': 'Abdominal',
      'unit': 'mm',
      'threshold': 5.0,
    },
    {'key': 'thighFold', 'label': 'Muslo Ant.', 'unit': 'mm', 'threshold': 5.0},
    {'key': 'calfFold', 'label': 'Pantorrilla', 'unit': 'mm', 'threshold': 5.0},
    {
      'key': 'armRelaxedCirc',
      'label': 'Brazo Relajado',
      'unit': 'cm',
      'threshold': 1.0,
    },
    {
      'key': 'armFlexedCirc',
      'label': 'Brazo Contraído',
      'unit': 'cm',
      'threshold': 1.0,
    },
    {
      'key': 'waistCircNarrowest',
      'label': 'Cintura Mínima',
      'unit': 'cm',
      'threshold': 1.0,
    },
    {
      'key': 'hipCircMax',
      'label': 'Cadera Máxima',
      'unit': 'cm',
      'threshold': 1.0,
    },
    {
      'key': 'midThighCirc',
      'label': 'Muslo Medio',
      'unit': 'cm',
      'threshold': 1.0,
    },
    {
      'key': 'maxCalfCirc',
      'label': 'Pantorrilla Máx',
      'unit': 'cm',
      'threshold': 1.0,
    },
    {'key': 'wristDiameter', 'label': 'Muñeca', 'unit': 'cm', 'threshold': 1.0},
    {'key': 'kneeDiameter', 'label': 'Rodilla', 'unit': 'cm', 'threshold': 1.0},
  ];

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _heightController.text = client.initialHeightCm?.toString() ?? '';
    }

    // Siempre iniciar en idle primero
    _viewState = AnthropometryViewState.idle;
    widget.onViewStateChanged?.call(_viewState);

    // Si hay registros previos, cargarlos después de que el widget se construya
    if (client?.anthropometry.isNotEmpty ?? false) {
      final latestRecord = client!.latestAnthropometryRecord;
      if (latestRecord != null) {
        // Usar addPostFrameCallback para evitar setState() en initState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadRecordInViewMode(latestRecord);
        });
      }
    }

    // Inicializar controladores
    for (var site in _measurementSites) {
      final String key = site['key'];
      _measurementControllers[key] = List.generate(
        3,
        (_) => TextEditingController(),
      );
      _finalValues[key] = null;
      _showThirdMeasurement[key] = false;
      _errorMessages[key] = null;

      void listener() {
        if (_measurementControllers[key]![2].text.isNotEmpty) {
          _calculateFinalValue(key);
        } else {
          _calculateDifference(key);
        }
      }

      _measurementControllers[key]![0].addListener(listener);
      _measurementControllers[key]![1].addListener(listener);
      _measurementControllers[key]![2].addListener(listener);
    }

    _rfmWaistController.addListener(() {
      if (_measurementMethod == MeasurementMethod.rfm) {
        _updateRfmValue();
      }
    });
    _heightController.addListener(() {
      if (_measurementMethod == MeasurementMethod.rfm) {
        _updateRfmValue();
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _rfmWaistController.dispose();
    _rfmNeckController.dispose();
    _rfmTricipitalController.dispose();
    _rfmSupraspinalController.dispose();
    _measurementControllers.forEach((_, controllers) {
      for (var c in controllers) {
        c.dispose();
      }
    });
    super.dispose();
  }

  void _calculateDifference(String key) {
    final m1Text = _measurementControllers[key]![0].text;
    final m2Text = _measurementControllers[key]![1].text;
    final site = _measurementSites.firstWhere((site) => site['key'] == key);
    final double thresholdPercent = site['threshold'];
    final m1 = double.tryParse(m1Text);
    final m2 = double.tryParse(m2Text);
    bool shouldShowThird = false;
    String? error;

    if ((m1 != null && m1 <= 0) || (m2 != null && m2 <= 0)) {
      error = "!";
    } else if (m1 != null && m2 != null) {
      final mean = (m1 + m2) / 2;
      if (mean > 0) {
        final diffPercent = ((m1 - m2).abs() / mean) * 100;
        shouldShowThird = diffPercent > thresholdPercent;
        if (shouldShowThird) {
          error = ">${thresholdPercent.toInt()}%";
        }
      }
    }

    setState(() {
      _showThirdMeasurement[key] = shouldShowThird;
      _errorMessages[key] = error;
      _finalValues[key] = (m1 != null && m2 != null && !shouldShowThird)
          ? ((m1 + m2) / 2)
          : null;
    });
  }

  void _calculateFinalValue(String key) {
    final controllers = _measurementControllers[key]!;
    final values = controllers
        .map((c) => double.tryParse(c.text))
        .whereType<double>()
        .where((v) => v > 0)
        .toList();

    if (values.length < 2) {
      setState(() {
        _finalValues[key] = null;
      });
      return;
    }

    values.sort();
    double finalValue;

    if (values.length == 3) {
      // Mediana: el valor del medio
      finalValue = values[1];
    } else {
      // Para 2 valores: promedio
      finalValue = (values[0] + values[1]) / 2;
    }

    setState(() {
      // NO deshabilitar m3 una vez que está habilitado, solo actualizar el valor final
      _errorMessages[key] = null;
      _finalValues[key] = finalValue;
    });
  }

  double? _calculateRfm(double heightCm, double waistCm, Gender? gender) {
    if (waistCm <= 0) return null;
    final heightM = heightCm / 100;
    final waistM = waistCm / 100;
    if (waistM <= 0) return null;
    final sexFactor = gender == Gender.female ? 1 : 0;
    return 64 - (20 * (heightM / waistM)) + (12 * sexFactor);
  }

  /// Estimación BÁSICA de % grasa corporal usando solo IMC
  /// Basado en ecuaciones de Deurenberg et al. (1991)
  /// NO es clínico/profesional, pero permite generar plan nutricional sin mediciones
  double? _calculateBasicBodyFat(
    double weightKg,
    double heightCm,
    int? age,
    Gender? gender,
  ) {
    if (weightKg <= 0 || heightCm <= 0) return null;

    // Calcular IMC
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    // Edad por defecto si no está disponible
    final ageValue = age ?? 30;

    // Ecuación de Deurenberg: %Grasa = (1.20 × IMC) + (0.23 × Edad) - (10.8 × Sexo) - 5.4
    // Sexo: 1 = hombre, 0 = mujer
    final sexFactor = gender == Gender.male ? 1.0 : 0.0;
    final bodyFat = (1.20 * bmi) + (0.23 * ageValue) - (10.8 * sexFactor) - 5.4;

    // Limitar a rangos razonables (5% - 50%)
    return bodyFat.clamp(5.0, 50.0);
  }

  double? _extractRfm(AnthropometryRecord record) {
    final stored = record.individualMeasurements?['rfm'];
    if (stored is List) {
      final val = stored?.cast<double?>().firstWhere(
        (v) => v != null,
        orElse: () => null,
      );
      if (val != null) return val;
    }
    if (record.heightCm != null && record.waistCircNarrowest != null) {
      return _calculateRfm(
        record.heightCm!,
        record.waistCircNarrowest!,
        _client?.profile.gender,
      );
    }
    return null;
  }

  void _setMeasurementMethod(MeasurementMethod method) {
    setState(() {
      _measurementMethod = method;
      _rfmWaistController.clear();
      _rfmNeckController.clear();
      _rfmTricipitalController.clear();
      _rfmSupraspinalController.clear();
      _rfmValue = null;
      for (final entry in _measurementControllers.entries) {
        for (final controller in entry.value) {
          controller.clear();
        }
      }
      _finalValues.updateAll((_, __) => null);
      _showThirdMeasurement.updateAll((_, __) => false);
      _errorMessages.updateAll((_, __) => null);
    });
  }

  void _updateRfmValue() {
    final height = double.tryParse(_heightController.text);
    final waist = double.tryParse(_rfmWaistController.text);
    if (height == null || waist == null) {
      setState(() => _rfmValue = null);
      return;
    }
    final value = _calculateRfm(height, waist, _client?.profile.gender);
    setState(() => _rfmValue = value);
  }

  Future<void> _selectDate(BuildContext context) async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final client = _client;

    final highlightedDates =
        client?.anthropometry.map((r) => r.date).toList() ?? [];

    final picked = await showCustomDatePicker(
      context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      highlightedDates: highlightedDates,
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(
        () => _dateController.text = DateFormat('yyyy-MM-dd').format(picked),
      );
    }
  }

  Future<void> _saveRecord() async {
    try {
      final activeClient = ref.read(clientsProvider).value?.activeClient;
      if (activeClient != null && _client?.id != activeClient.id) {
        setState(() => _client = activeClient);
      }

      final date = DateTime.tryParse(_dateController.text);
      if (date == null) {
        showErrorSnackbar(context, SaveMessages.errorInvalidDate);
        return;
      }
      final weight = double.tryParse(_weightController.text);
      final height = double.tryParse(_heightController.text);

      if (weight == null || weight <= 0) {
        showErrorSnackbar(context, 'Peso inválido.');
        return;
      }
      if (height == null || height <= 0) {
        showErrorSnackbar(context, 'Estatura inválida.');
        return;
      }

      final isRfm = _measurementMethod == MeasurementMethod.rfm;
      final isBasic = _measurementMethod == MeasurementMethod.basic;
      double? rfmValue;
      double? basicBodyFat;

      if (isRfm) {
        final waist = double.tryParse(_rfmWaistController.text);
        if (waist == null || waist <= 0) {
          showErrorSnackbar(context, 'Cintura inválida para RFM.');
          return;
        }
      } else if (isBasic) {
        // Modo básico: solo requiere peso y estatura (ya validados arriba)
        // Calcular estimación de % grasa corporal
        basicBodyFat = _calculateBasicBodyFat(
          weight,
          height,
          _client?.age,
          _client?.profile.gender,
        );
      } else {
        // Modo ISAK: requiere todas las mediciones
        for (var site in _measurementSites) {
          if (_finalValues[site['key']] == null) {
            showErrorSnackbar(context, 'Falta ${site['label']}.');
            return;
          }
        }
      }

      // Guardar las tres mediciones individuales [m1, m2, m3]
      final individualMeasurements = <String, List<double?>>{};
      if (isRfm) {
        final waist = double.tryParse(_rfmWaistController.text);
        final neck = double.tryParse(_rfmNeckController.text);
        final tri = double.tryParse(_rfmTricipitalController.text);
        final supra = double.tryParse(_rfmSupraspinalController.text);
        individualMeasurements['waistCircNarrowest'] = [waist, null, null];
        if (neck != null) {
          individualMeasurements['neckCirc'] = [neck, null, null];
        }
        if (tri != null) {
          individualMeasurements['tricipitalFold'] = [tri, null, null];
        }
        if (supra != null) {
          individualMeasurements['supraspinalFold'] = [supra, null, null];
        }
      } else if (isBasic) {
        // Modo básico: guardar estimación de % grasa corporal
        if (basicBodyFat != null) {
          individualMeasurements['basicBodyFat'] = [basicBodyFat];
        }
      } else {
        // Modo ISAK: guardar mediciones completas
        for (final entry in _measurementControllers.entries) {
          final key = entry.key;
          final m1 = double.tryParse(entry.value[0].text);
          final m2 = double.tryParse(entry.value[1].text);
          final m3 = double.tryParse(entry.value[2].text);
          individualMeasurements[key] = [m1, m2, m3];
        }
      }

      final waistValue = isRfm
          ? double.tryParse(_rfmWaistController.text)
          : _finalValues['waistCircNarrowest'];

      final recordMeasurements = individualMeasurements.isEmpty
          ? <String, List<double?>>{}
          : Map<String, List<double?>>.from(individualMeasurements);

      if (isRfm && waistValue != null && waistValue > 0) {
        rfmValue = _calculateRfm(height, waistValue, _client?.profile.gender);
        if (rfmValue != null) {
          recordMeasurements['rfm'] = [rfmValue];
        }
      }

      final newRecord = AnthropometryRecord(
        date: date,
        weightKg: weight,
        heightCm: height,
        tricipitalFold: isRfm
            ? double.tryParse(_rfmTricipitalController.text)
            : _finalValues['tricipitalFold'],
        subscapularFold: _finalValues['subscapularFold'],
        suprailiacFold: _finalValues['suprailiacFold'],
        supraspinalFold: isRfm
            ? double.tryParse(_rfmSupraspinalController.text)
            : _finalValues['supraspinalFold'],
        abdominalFold: _finalValues['abdominalFold'],
        thighFold: _finalValues['thighFold'],
        calfFold: _finalValues['calfFold'],
        armRelaxedCirc: _finalValues['armRelaxedCirc'],
        armFlexedCirc: _finalValues['armFlexedCirc'],
        waistCircNarrowest: waistValue,
        hipCircMax: _finalValues['hipCircMax'],
        midThighCirc: _finalValues['midThighCirc'],
        maxCalfCirc: _finalValues['maxCalfCirc'],
        neckCirc: isRfm ? double.tryParse(_rfmNeckController.text) : null,
        wristDiameter: _finalValues['wristDiameter'],
        kneeDiameter: _finalValues['kneeDiameter'],
        individualMeasurements: recordMeasurements.isEmpty
            ? null
            : recordMeasurements,
      );

      final client = _client;
      if (client == null) {
        showErrorSnackbar(context, 'Error: Cliente no cargado');
        return;
      }

      final isEditing = SaveActionDetector.isEditingExistingDate(
        client.anthropometry,
        date,
        (record) => record.date,
      );

      // Actualizar lista de registros localmente
      final updated = upsertRecordByDate<AnthropometryRecord>(
        existingRecords: client.anthropometry,
        newRecord: newRecord,
        dateExtractor: (record) => record.date,
      );

      // Actualizar cliente con nueva lista
      final updatedClient = client.copyWith(anthropometry: updated);

      // Guardar en BD local (y Firestore de fondo)
      final repository = ref.read(clientRepositoryProvider);
      await repository.saveClient(updatedClient);

      // Actualizar estado global
      await ref.read(clientsProvider.notifier).updateActiveClient((current) {
        return current.copyWith(anthropometry: updated);
      });

      // Actualizar referencia local del cliente y volver a idle
      if (!mounted) return;
      setState(() {
        _client = updatedClient;
        _selectedRecordDate = null;
        _viewState = AnthropometryViewState.idle;
        _isHistoryExpanded = false;
      });

      // Push granular a Firestore (fire-and-forget)
      final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
      recordsRepo.pushAnthropometryRecord(client.id, newRecord);

      if (!mounted) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final message = isEditing
          ? 'Registro de $dateStr actualizado'
          : 'Registro guardado para $dateStr';
      final rfmInfo = rfmValue != null
          ? ' (RFM ${rfmValue.toStringAsFixed(1)}%)'
          : '';
      setState(() => _rfmValue = rfmValue);
      showErrorSnackbar(context, '$message$rfmInfo', isError: false);
    } catch (e) {
      debugPrint('Error al guardar mediciones: $e');
      if (mounted) {
        showErrorSnackbar(
          context,
          'Error al guardar: ${e.toString()}',
        );
      }
    }
  }

  Future<void> saveIfDirty() async {
    if (_viewState == AnthropometryViewState.creatingInitial ||
        _viewState == AnthropometryViewState.creatingNew) {
      await _saveRecord();
    }
  }

  void resetDrafts() {
    _resetToIdle();
  }

  /// Retorna el estado actual de la vista de Antropometría
  AnthropometryViewState getCurrentViewState() {
    return _viewState;
  }

  void _loadRecordInViewMode(AnthropometryRecord record) {
    // Detectar qué método se usó en este registro
    final hasBasicBodyFat =
        record.individualMeasurements?['basicBodyFat']?.any((v) => v != null) ??
        false;
    final isRfmRecord =
        record.individualMeasurements?['rfm']?.any((v) => v != null) ?? false;

    // Determinar el método usado
    MeasurementMethod detectedMethod;
    if (hasBasicBodyFat) {
      detectedMethod = MeasurementMethod.basic;
    } else if (isRfmRecord) {
      detectedMethod = MeasurementMethod.rfm;
    } else {
      detectedMethod = MeasurementMethod.isak;
    }

    setState(() {
      _selectedRecordDate = record.date;
      _viewState = AnthropometryViewState.viewingHistory;
      _isHistoryExpanded = true;

      _measurementMethod = detectedMethod;

      _dateController.text = DateFormat('yyyy-MM-dd').format(record.date);
      _weightController.text = record.weightKg?.toString() ?? '';
      _heightController.text = record.heightCm?.toString() ?? '';

      if (detectedMethod == MeasurementMethod.rfm) {
        _rfmWaistController.text =
            record.waistCircNarrowest?.toStringAsFixed(1) ?? '';
        _rfmNeckController.text = record.neckCirc?.toStringAsFixed(1) ?? '';
        _rfmTricipitalController.text =
            record.tricipitalFold?.toStringAsFixed(1) ?? '';
        _rfmSupraspinalController.text =
            record.supraspinalFold?.toStringAsFixed(1) ?? '';
        _rfmValue = _extractRfm(record);
      } else {
        _rfmWaistController.clear();
        _rfmNeckController.clear();
        _rfmTricipitalController.clear();
        _rfmSupraspinalController.clear();
        _rfmValue = null;
      }

      // Solo cargar mediciones ISAK si NO es básico
      if (detectedMethod != MeasurementMethod.basic) {
        for (var site in _measurementSites) {
          final key = site['key'] as String;
          final value = _getRecordValue(record, key);
          _finalValues[key] = value;

          // Limpiar inputs en VIEW
          _measurementControllers[key]![0].clear();
          _measurementControllers[key]![1].clear();
          _measurementControllers[key]![2].clear();
        }
      }
    });
    widget.onStateChanged?.call();
    widget.onViewStateChanged?.call(_viewState);
  }

  void _cancelEdit() {
    _resetToIdle();
  }

  void _clearFormFields() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _weightController.clear();
    _heightController.text = _client?.initialHeightCm?.toString() ?? '';
    _measurementMethod = MeasurementMethod.isak;
    _rfmWaistController.clear();
    _rfmNeckController.clear();
    _rfmTricipitalController.clear();
    _rfmSupraspinalController.clear();
    _rfmValue = null;

    for (final entry in _measurementControllers.entries) {
      for (final controller in entry.value) {
        controller.clear();
      }
      _finalValues[entry.key] = null;
      _showThirdMeasurement[entry.key] = false;
      _errorMessages[entry.key] = null;
    }

    // Notify about the state change
    widget.onViewStateChanged?.call(_viewState);
  }

  void _resetToIdle() {
    setState(() {
      _selectedRecordDate = null;
      _viewState = AnthropometryViewState.idle;
      _clearFormFields();
    });
    widget.onStateChanged?.call();
    widget.onViewStateChanged?.call(_viewState);
  }

  void _startCreatingNew({AnthropometryRecord? reference}) {
    setState(() {
      _selectedRecordDate = reference?.date;
      _viewState = AnthropometryViewState.creatingNew;
      _clearFormFields();
    });
    widget.onViewStateChanged?.call(_viewState);
    widget.onStateChanged?.call();
  }

  void _startEditingRecord(AnthropometryRecord record) {
    setState(() {
      _selectedRecordDate = record.date;
      _viewState = AnthropometryViewState.editingHistory;
      _clearFormFields();

      final isRfmRecord =
          record.individualMeasurements?['rfm']?.any((v) => v != null) ?? false;
      _measurementMethod = isRfmRecord
          ? MeasurementMethod.rfm
          : MeasurementMethod.isak;

      // Cargar los datos del registro en los controladores
      _dateController.text = DateFormat('yyyy-MM-dd').format(record.date);
      _weightController.text = record.weightKg?.toStringAsFixed(1) ?? '';
      _heightController.text = record.heightCm?.toStringAsFixed(1) ?? '';

      if (isRfmRecord) {
        _rfmWaistController.text =
            record.waistCircNarrowest?.toStringAsFixed(1) ?? '';
        _rfmNeckController.text = record.neckCirc?.toStringAsFixed(1) ?? '';
        _rfmTricipitalController.text =
            record.tricipitalFold?.toStringAsFixed(1) ?? '';
        _rfmSupraspinalController.text =
            record.supraspinalFold?.toStringAsFixed(1) ?? '';
        final storedRfm = record.individualMeasurements?['rfm']
            ?.cast<double?>()
            .firstWhere((v) => v != null, orElse: () => null);
        _rfmValue =
            storedRfm ??
            _calculateRfm(
              record.heightCm ?? 0,
              record.waistCircNarrowest ?? 0,
              _client?.profile.gender,
            );
      }

      // Cargar los valores finales y las tres mediciones
      for (final entry in _measurementControllers.entries) {
        final key = entry.key;
        final value = _getRecordValue(record, key);

        if (value != null && value > 0) {
          // Intentar cargar las tres mediciones guardadas
          final savedMeasurements = record.individualMeasurements?[key];

          if (savedMeasurements != null && savedMeasurements.length >= 3) {
            // Cargar las mediciones guardadas
            entry.value[0].text =
                savedMeasurements[0]?.toStringAsFixed(1) ?? '';
            entry.value[1].text =
                savedMeasurements[1]?.toStringAsFixed(1) ?? '';
            entry.value[2].text =
                savedMeasurements[2]?.toStringAsFixed(1) ?? '';
            _showThirdMeasurement[key] = true;
          } else {
            // Si no hay mediciones guardadas, mostrar el valor final en m1
            entry.value[0].text = value.toStringAsFixed(1);
            entry.value[1].text = '';
            entry.value[2].text = '';
          }

          _finalValues[key] = value;
        }
      }
    });
  }

  double? _getRecordValue(AnthropometryRecord record, String key) {
    return (record.toJson()[key] as num?)?.toDouble();
  }

  Future<void> _deleteSelectedRecord() async {
    if (_selectedRecordDate == null || _client == null) return;

    final targetDate = _selectedRecordDate!;

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      date: targetDate,
      recordType: 'Medidas de Antropometría',
    );

    if (!confirmed || !mounted) return;

    try {
      final deletionService = ref.read(recordDeletionServiceProvider);
      await deletionService.deleteAnthropometryByDate(
        clientId: _client!.id,
        date: targetDate,
        onError: (e) {
          // Log error pero no bloquea UI (fire-and-forget)
          debugPrint('Error al borrar antropometria: $e');
        },
      );

      if (!mounted) return;

      // Actualizar lista local removiendo el registro borrado
      final filtered = _client!.anthropometry
          .where((r) => !DateUtils.isSameDay(r.date, targetDate))
          .toList();

      // Actualizar cliente
      final updatedClient = _client!.copyWith(anthropometry: filtered);
      final repository = ref.read(clientRepositoryProvider);
      await repository.saveClient(updatedClient);

      // Actualizar estado global
      await ref.read(clientsProvider.notifier).updateActiveClient((current) {
        return current.copyWith(anthropometry: filtered);
      });

      if (!mounted) return;

      // Limpiar UI y volver a idle
      setState(() {
        _client = updatedClient;
        _selectedRecordDate = null;
        _viewState = AnthropometryViewState.idle;
        _clearFormFields();
        _isHistoryExpanded = false;
      });

      // Mostrar confirmación
      showDeleteSuccessSnackbar(context, targetDate, 'Antropometría');
    } catch (e) {
      if (mounted) {
        showDeleteErrorSnackbar(context, Exception('Error: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final activeClient = ref.watch(clientsProvider).value?.activeClient;
    if (_client?.id != activeClient?.id && activeClient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _client = activeClient;
        final latestRecord = activeClient.latestAnthropometryRecord;
        if (latestRecord != null) {
          _loadRecordInViewMode(latestRecord);
        } else {
          setState(() {
            _selectedRecordDate = null;
            _viewState = AnthropometryViewState.idle;
            _clearFormFields();
          });
        }
      });
    }

    final client = _client;
    final latestRecord = client?.latestAnthropometryRecord;

    switch (_viewState) {
      case AnthropometryViewState.idle:
        return _buildOverviewOnly(latestRecord);

      case AnthropometryViewState.creatingInitial:
        return _buildForm();

      case AnthropometryViewState.creatingNew:
        return _buildForm(referenceRecord: latestRecord);

      case AnthropometryViewState.viewingHistory:
        // Mostrar el formulario completo en modo visualización
        return _buildFormReadOnly();

      case AnthropometryViewState.editingHistory:
        // Mostrar el formulario completo en modo edición
        return _buildForm(referenceRecord: latestRecord);
    }
  }

  // =====================================================================
  // OVERVIEW (sin formulario)
  // =====================================================================
  Widget _buildOverviewOnly(AnthropometryRecord? latestRecord) {
    final records = _client?.anthropometry ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildHistorySectionGrid(records)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // FORM (con formulario completo)
  // =====================================================================
  Widget _buildForm({AnthropometryRecord? referenceRecord}) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vista limpia: solo el formulario ISAK/RFM
                  _buildFormSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildActionButtons(),
    );
  }

  // =====================================================================
  // FORM READ-ONLY (ver registro guardado)
  // =====================================================================
  Widget _buildFormReadOnly() {
    final client = _client;
    final latestRecord = client?.latestAnthropometryRecord;
    final selectedRecord = _selectedRecordDate != null
        ? client?.anthropometry.firstWhere(
                (r) => DateUtils.isSameDay(r.date, _selectedRecordDate!),
                orElse: () => latestRecord!,
              ) ??
              latestRecord
        : latestRecord;

    if (selectedRecord == null) {
      return const Center(
        child: Text(
          'No hay registro seleccionado',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vista limpia: solo lectura del formulario ISAK/RFM
                  _buildFormSectionReadOnly(selectedRecord),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetToIdle,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver al resumen'),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _startEditingRecord(selectedRecord),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _viewState =
                                    AnthropometryViewState.viewingHistory;
                              });
                            },
                            icon: const Icon(Icons.history),
                            label: const Text('Ver historial'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSectionReadOnly(AnthropometryRecord record) {
    // Detectar qué método se usó en este registro
    final hasBasicBodyFat =
        record.individualMeasurements?['basicBodyFat']?.any((v) => v != null) ??
        false;
    final isRfmRecord =
        record.individualMeasurements?['rfm']?.any((v) => v != null) ?? false;

    return ClinicSectionSurface(
      icon: Icons.straighten,
      title: 'Detalles del Registro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildReadOnlyField(
                  'Fecha',
                  DateFormat('yyyy-MM-dd').format(record.date),
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReadOnlyField(
                  'Peso (kg)',
                  record.weightKg?.toStringAsFixed(1) ?? '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReadOnlyField(
                  'Estatura (cm)',
                  record.heightCm?.toStringAsFixed(1) ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasBasicBodyFat) ...[
            _buildReadOnlyBasicSection(record),
          ] else if (isRfmRecord) ...[
            _buildReadOnlyField(
              'Método de Evaluación',
              'RFM (Relative Fat Mass)',
              icon: Icons.science,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    'RFM (%)',
                    _extractRfm(record)?.toStringAsFixed(1) ?? '—',
                    icon: Icons.percent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 12),
            _buildMeasurementGroupReadOnly('Mediciones RFM', 'mm/cm', [
              {'key': 'neckCirc', 'label': 'Cuello', 'value': record.neckCirc},
              {
                'key': 'waistCircNarrowest',
                'label': 'Cintura',
                'value': record.waistCircNarrowest,
              },
              {
                'key': 'tricipitalFold',
                'label': 'Pliegue Tricipital',
                'value': record.tricipitalFold,
              },
              {
                'key': 'supraspinalFold',
                'label': 'Pliegue Supraespinal',
                'value': record.supraspinalFold,
              },
            ]),
          ] else ...[
            _buildReadOnlyField(
              'Método de Evaluación',
              'ISAK (Protocolo Internacional)',
              icon: Icons.science,
            ),
            const SizedBox(height: 12),
            _buildMeasurementGroupReadOnly('Pliegues Cutáneos', 'mm', [
              {
                'key': 'tricipitalFold',
                'label': 'Tríceps',
                'value': record.tricipitalFold,
              },
              {
                'key': 'subscapularFold',
                'label': 'Subescapular',
                'value': record.subscapularFold,
              },
              {
                'key': 'suprailiacFold',
                'label': 'Cresta Ilíaca',
                'value': record.suprailiacFold,
              },
              {
                'key': 'supraspinalFold',
                'label': 'Supraespinal',
                'value': record.supraspinalFold,
              },
              {
                'key': 'abdominalFold',
                'label': 'Abdominal',
                'value': record.abdominalFold,
              },
              {'key': 'thighFold', 'label': 'Muslo', 'value': record.thighFold},
              {
                'key': 'calfFold',
                'label': 'Pantorrilla',
                'value': record.calfFold,
              },
            ]),
            const SizedBox(height: 12),
            _buildMeasurementGroupReadOnly('Perímetros', 'cm', [
              {
                'key': 'armRelaxedCirc',
                'label': 'Brazo Relajado',
                'value': record.armRelaxedCirc,
              },
              {
                'key': 'armFlexedCirc',
                'label': 'Brazo Flexionado',
                'value': record.armFlexedCirc,
              },
              {'key': 'neckCirc', 'label': 'Cuello', 'value': record.neckCirc},
              {
                'key': 'waistCircNarrowest',
                'label': 'Cintura',
                'value': record.waistCircNarrowest,
              },
              {
                'key': 'hipCircMax',
                'label': 'Cadera',
                'value': record.hipCircMax,
              },
              {
                'key': 'midThighCirc',
                'label': 'Muslo',
                'value': record.midThighCirc,
              },
              {
                'key': 'maxCalfCirc',
                'label': 'Pantorrilla',
                'value': record.maxCalfCirc,
              },
            ]),
            const SizedBox(height: 12),
            _buildMeasurementGroupReadOnly('Diámetros', 'cm', [
              {
                'key': 'wristDiameter',
                'label': 'Muñeca',
                'value': record.wristDiameter,
              },
              {
                'key': 'kneeDiameter',
                'label': 'Rodilla',
                'value': record.kneeDiameter,
              },
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyBasicSection(AnthropometryRecord record) {
    // Extraer estimación básica
    final basicBodyFatList = record.individualMeasurements?['basicBodyFat'];
    final bodyFat = (basicBodyFatList != null && basicBodyFatList.isNotEmpty)
        ? basicBodyFatList.first
        : null;

    // Calcular IMC
    final weight = record.weightKg;
    final height = record.heightCm;
    final bmi = (weight != null && height != null && height > 0)
        ? weight / ((height / 100) * (height / 100))
        : null;

    String bmiCategory = '—';
    if (bmi != null) {
      if (bmi < 18.5) {
        bmiCategory = 'Bajo peso';
      } else if (bmi < 25) {
        bmiCategory = 'Normal';
      } else if (bmi < 30) {
        bmiCategory = 'Sobrepeso';
      } else {
        bmiCategory = 'Obesidad';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReadOnlyField(
          'Método de Evaluación',
          'Básico (Solo Peso y Estatura)',
          icon: Icons.science,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReadOnlyField(
                'IMC',
                bmi != null ? bmi.toStringAsFixed(1) : '—',
                icon: Icons.monitor_weight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReadOnlyField(
                'Categoría IMC',
                bmiCategory,
                icon: Icons.category,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReadOnlyField(
                '% Grasa Estimado (Deurenberg)',
                bodyFat is double ? '${bodyFat.toStringAsFixed(1)}%' : '—',
                icon: Icons.percent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.info, color: Colors.orange, size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Estimación simplificada basada en IMC. Menos precisa que ISAK o RFM.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, size: 16, color: Colors.white38),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementGroupReadOnly(
    String title,
    String unit,
    List<Map<String, dynamic>> sites,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              color: kPrimaryColor,
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              unit,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sites.map((site) {
          final value = site['value'] as double?;
          final displayValue = value != null && value > 0
              ? value.toStringAsFixed(1)
              : '—';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    site['label'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(51),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      displayValue,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =====================================================================
  // 4) FORMULARIO
  // =====================================================================
  Widget _buildFormSection() {
    return ClinicSectionSurface(
      icon: Icons.straighten,
      title: 'Detalles del Registro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFormField(
                  _dateController,
                  'Fecha',
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  _weightController,
                  'Peso (kg)',
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  _heightController,
                  'Estatura (cm)',
                  isNumber: true,
                  onChanged: _measurementMethod == MeasurementMethod.rfm
                      ? (_) => _updateRfmValue()
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMeasurementMethodSelector(),
          const SizedBox(height: 12),
          if (_measurementMethod == MeasurementMethod.rfm) ...[
            _buildRfmSection(),
          ] else if (_measurementMethod == MeasurementMethod.basic) ...[
            _buildBasicSection(),
          ] else ...[
            _buildMeasurementGroup(
              'Pliegues Cutáneos',
              'mm',
              _measurementSites
                  .where((s) => (s['key'] as String).contains('Fold'))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _buildMeasurementGroup(
              'Perímetros',
              'cm',
              _measurementSites
                  .where((s) => (s['key'] as String).contains('Circ'))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _buildMeasurementGroup(
              'Diámetros',
              'cm',
              _measurementSites
                  .where((s) => (s['key'] as String).contains('Diameter'))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController ctrl,
    String label, {
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: hcsDecoration(
            context,
            suffixIcon: icon != null
                ? Icon(icon, size: 16, color: Colors.white38)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de medición',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('ISAK (3 mediciones)'),
              selected: _measurementMethod == MeasurementMethod.isak,
              onSelected: (_) => _setMeasurementMethod(MeasurementMethod.isak),
            ),
            ChoiceChip(
              label: const Text('RFM (1 medición)'),
              selected: _measurementMethod == MeasurementMethod.rfm,
              onSelected: (_) => _setMeasurementMethod(MeasurementMethod.rfm),
            ),
            ChoiceChip(
              label: const Text('Básico (solo peso/estatura)'),
              selected: _measurementMethod == MeasurementMethod.basic,
              onSelected: (_) => _setMeasurementMethod(MeasurementMethod.basic),
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              selectedColor: Colors.orange.withValues(alpha: 0.3),
            ),
          ],
        ),
        if (_measurementMethod == MeasurementMethod.basic)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo simplificado para coaches sin capacitación en mediciones. '
                    'Solo requiere peso y estatura. La estimación de composición corporal '
                    'es aproximada (basada en IMC).',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRfmSection() {
    final rfmText = _rfmValue != null
        ? '${_rfmValue!.toStringAsFixed(1)}%'
        : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              color: kPrimaryColor,
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text(
              'RFM: 64 - (20 × altura/cintura) + (12 × sexo)',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Sexo: 0 hombres, 1 mujeres. Usa altura y cintura en metros (ingresa cintura en cm, convertimos automáticamente).',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                _rfmWaistController,
                'Cintura (cm, 1 medición)',
                isNumber: true,
                onChanged: (_) => _updateRfmValue(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReadOnlyField(
                'RFM estimado',
                rfmText,
                icon: Icons.percent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                _rfmNeckController,
                'Cuello (cm, 1 medición)',
                isNumber: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField(
                _rfmTricipitalController,
                'Pliegue Tricipital (mm, 1 medición)',
                isNumber: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField(
                _rfmSupraspinalController,
                'Pliegue Supraespinal (mm, 1 medición)',
                isNumber: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicSection() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final estimatedBodyFat = (weight != null && height != null)
        ? _calculateBasicBodyFat(
            weight,
            height,
            _client?.age,
            _client?.profile.gender,
          )
        : null;

    final bmi = (weight != null && height != null && height > 0)
        ? weight / ((height / 100) * (height / 100))
        : null;

    String bmiCategory = '—';
    if (bmi != null) {
      if (bmi < 18.5) {
        bmiCategory = 'Bajo peso';
      } else if (bmi < 25) {
        bmiCategory = 'Normal';
      } else if (bmi < 30) {
        bmiCategory = 'Sobrepeso';
      } else {
        bmiCategory = 'Obesidad';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              color: Colors.orange,
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text(
              'ESTIMACIÓN BÁSICA (Solo Peso y Estatura)',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReadOnlyField(
                'IMC',
                bmi != null ? bmi.toStringAsFixed(1) : '—',
                icon: Icons.monitor_weight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReadOnlyField(
                'Categoría IMC',
                bmiCategory,
                icon: Icons.category,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReadOnlyField(
                '% Grasa Estimado (Deurenberg)',
                estimatedBodyFat != null
                    ? '${estimatedBodyFat.toStringAsFixed(1)}%'
                    : '—',
                icon: Icons.percent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.orange, size: 18),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Esta estimación es aproximada y menos precisa que ISAK o RFM. '
                  'Es útil cuando no se dispone de herramientas de medición, pero '
                  'se recomienda usar métodos más precisos cuando sea posible.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementGroup(
    String title,
    String unit,
    List<Map<String, dynamic>> sites,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              color: kPrimaryColor,
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              unit,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Header de columnas
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'SITIO',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'MED. 1',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'MED. 2',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'MED. 3',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'FINAL',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 8),

        ...sites.map((site) {
          final key = site['key'];
          final showThird = _showThirdMeasurement[key] ?? false;
          final error = _errorMessages[key];
          final finalValue = _finalValues[key];

          return _buildMeasurementRow(
            site['label'],
            _measurementControllers[key]!,
            showThird: showThird,
            error: error,
            finalValue: finalValue,
          );
        }),
      ],
    );
  }

  Widget _buildMeasurementRow(
    String label,
    List<TextEditingController> controllers, {
    required bool showThird,
    required String? error,
    required double? finalValue,
  }) {
    final m1 = double.tryParse(controllers[0].text);
    final m2 = double.tryParse(controllers[1].text);
    final m3 = double.tryParse(controllers[2].text);

    Color? color1 = m1 != null && m1 > 0 ? const Color(0xFF81C784) : null;
    Color? color2;
    if (error != null && error.contains('%')) {
      color2 = const Color(0xFFFFB74D);
    } else if (m2 != null && m2 > 0) {
      color2 = const Color(0xFF81C784);
    }
    Color? color3;
    if (showThird) {
      color3 = m3 != null && m3 > 0
          ? const Color(0xFF81C784)
          : const Color(0xFFE57373);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildMeasurementInput(controllers[0], color1),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildMeasurementInput(controllers[1], color2),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildMeasurementInput(controllers[2], color3, !showThird),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: finalValue != null
                    ? kPrimaryColor.withAlpha(25)
                    : Colors.black.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: finalValue != null
                      ? kPrimaryColor.withAlpha(77)
                      : Colors.white.withAlpha(26),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  finalValue?.toStringAsFixed(1) ?? '-',
                  style: TextStyle(
                    color: finalValue != null ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementInput(
    TextEditingController controller,
    Color? borderColor, [
    bool disabled = false,
  ]) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        enabled: !disabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (_) {
          // Callback para permitir actualización de estado sin bloquear
          setState(() {});
        },
        style: TextStyle(
          color: disabled ? Colors.white24 : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: hcsDecoration(
          context,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),

        // No hint/label: estilos provienen del tema
      ),
    );
  }

  // =====================================================================
  // 4) HISTORIAL (colapsable)
  // =====================================================================
  // ignore: unused_element
  Widget _buildHistorySection() {
    final records = _client?.anthropometry ?? [];

    return Container(
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _isHistoryExpanded = !_isHistoryExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    color: kPrimaryColor,
                    margin: const EdgeInsets.only(right: 10),
                  ),
                  const Text(
                    'HISTORIAL DE MEDICIONES',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${records.length} ${records.length == 1 ? "registro" : "registros"}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_isHistoryExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            RecordHistoryPanel<AnthropometryRecord>(
              records: records,
              selectedDate: _selectedRecordDate,
              onSelectDate: (date) {
                final record = records.firstWhere(
                  (r) => DateUtils.isSameDay(r.date, date),
                  orElse: () => records.first,
                );
                _loadRecordInViewMode(record);
              },
              primaryLabel: (record) {
                return 'Peso: ${record.weightKg?.toStringAsFixed(1) ?? '—'} kg • Abd: ${record.abdominalFold?.toStringAsFixed(1) ?? '—'} mm';
              },
              dateOf: (record) => record.date,
              title: '',
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================================
  // HISTORIAL EN GRID (para modo idle)
  // =====================================================================
  Widget _buildHistorySectionGrid(List<AnthropometryRecord> records) {
    final sortedRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: sortedRecords.length + 1, // +1 para botón de nuevo
        itemBuilder: (context, index) {
          // Primer item: botón de nuevo registro
          if (index == 0) {
            return InkWell(
              onTap: _startCreatingNew,
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
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 48, color: kPrimaryColor),
                    SizedBox(height: 12),
                    Text(
                      'Nuevo registro',
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

          // Items de registros existentes
          final record = sortedRecords[index - 1];
          final isSelected =
              _selectedRecordDate != null &&
              DateUtils.isSameDay(_selectedRecordDate, record.date);
          final day = DateFormat('d').format(record.date);
          final monthYear = DateFormat(
            'MMM yyyy',
            'es',
          ).format(record.date).toUpperCase();
          final weight = record.weightKg?.toStringAsFixed(1) ?? '—';

          return _AnthropometryRecordCard(
            day: day,
            monthYear: monthYear,
            weight: weight,
            isSelected: isSelected,
            onTap: () => _loadRecordInViewMode(record),
          );
        },
      ),
    );
  }

  // =====================================================================
  // ACTION BUTTONS
  // =====================================================================
  Widget? _buildActionButtons() {
    // En modo "viewing history", mostrar botón de borrado y volver
    if (_viewState == AnthropometryViewState.viewingHistory &&
        _selectedRecordDate != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'delete_record',
            onPressed: _deleteSelectedRecord,
            label: const Text('Borrar'),
            icon: const Icon(Icons.delete_outline),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'back_to_list',
            onPressed: () {
              setState(() {
                _selectedRecordDate = null;
                _viewState = AnthropometryViewState.idle;
              });
              showErrorSnackbar(
                context,
                'Volviendo a listado de registros',
                isError: false,
              );
            },
            label: const Text('Volver'),
            icon: const Icon(Icons.arrow_back),
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white,
          ),
        ],
      );
    }

    if (_viewState == AnthropometryViewState.idle) {
      return null;
    }
    final saveLabel = _viewState == AnthropometryViewState.creatingInitial
        ? SaveMessages.buttonCreateFirst
        : SaveMessages.buttonCreateNew;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'cancel_record',
          onPressed: _cancelEdit,
          label: const Text(SaveMessages.buttonCancel),
          icon: const Icon(Icons.close),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
        const SizedBox(width: 8),
        FloatingActionButton.extended(
          heroTag: 'save_record',
          onPressed: _saveRecord,
          label: Text(saveLabel),
          icon: const Icon(Icons.save),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }
}

// =====================================================================
// WIDGET CARD DE REGISTRO DE ANTROPOMETRÍA
// =====================================================================
class _AnthropometryRecordCard extends StatefulWidget {
  final String day;
  final String monthYear;
  final String weight;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnthropometryRecordCard({
    required this.day,
    required this.monthYear,
    required this.weight,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnthropometryRecordCard> createState() =>
      _AnthropometryRecordCardState();
}

class _AnthropometryRecordCardState extends State<_AnthropometryRecordCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _elevationController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _elevationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 2, end: 8).animate(
      CurvedAnimation(parent: _elevationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _elevationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (isHovering) {
      _elevationController.forward();
    } else {
      _elevationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withAlpha(
                    (10 * (_elevationAnimation.value / 8)).toInt(),
                  ),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1F2E).withAlpha(240),
                      const Color(0xFF1A1F2E).withAlpha(235),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? kPrimaryColor.withAlpha(200)
                        : Colors.white.withAlpha(15),
                    width: widget.isSelected ? 2 : 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fecha
                    Column(
                      children: [
                        Text(
                          widget.day,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected
                                ? kPrimaryColor
                                : Colors.white,
                          ),
                        ),
                        Text(
                          widget.monthYear,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextColorSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withAlpha(20),
                      margin: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    // Peso
                    Column(
                      children: [
                        const Text(
                          'Peso',
                          style: TextStyle(
                            fontSize: 11,
                            color: kTextColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.weight,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
