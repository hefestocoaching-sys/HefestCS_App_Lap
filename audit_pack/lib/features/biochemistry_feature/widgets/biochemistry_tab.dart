import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';
import 'package:hcs_app_lap/utils/widgets/analyzed_text_field.dart';
import 'package:hcs_app_lap/utils/ui_helpers.dart';
import 'package:hcs_app_lap/utils/save_messages.dart';
import 'package:hcs_app_lap/utils/widgets/record_history_panel.dart';
import 'package:hcs_app_lap/utils/record_helpers.dart';
import 'package:hcs_app_lap/utils/widgets/clinical_context_bar.dart';
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';
// Importante para las extensiones

import '../../../domain/entities/biochemistry_record.dart';

// Enum para los tres estados del formulario
enum _TabMode {
  idle, // Estado inicial - solo vista general
  view, // Viendo registro existente (sin editar)
  editing, // Editando registro existente
  creating, // Creando nuevo registro
}

class BiochemistryTab extends ConsumerStatefulWidget {
  const BiochemistryTab({super.key});

  @override
  ConsumerState<BiochemistryTab> createState() => BiochemistryTabState();
}

class BiochemistryTabState extends ConsumerState<BiochemistryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;

  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _formKey = GlobalKey<FormState>();

  // Mapa de controladores para manejar la UI dinámicamente
  final Map<String, TextEditingController> _controllers = {};

  // Estado del formulario basado en modo
  DateTime? _selectedRecordDate;
  late _TabMode _mode;

  // Lista de claves para inicializar controladores (mantiene el orden)
  final List<String> _allKeys = [
    'glucose',
    'hba1c',
    'fastingInsulin',
    'cholesterolTotal',
    'ldl',
    'hdl',
    'cholesterolNoHDL',
    'triglycerides',
    'apoA1',
    'apoB',
    'ast',
    'alt',
    'ggt',
    'alkalinePhosphatase',
    'bilirubinTotal',
    'albumin',
    'totalProteins',
    'creatinine',
    'ureaBUN',
    'bunCreatinineRatio',
    'egfr',
    'sodium',
    'potassium',
    'chloride',
    'bicarbonate',
    'serumOsmolality',
    'urineDensity',
    'uricAcid',
    'hemoglobin',
    'hematocrit',
    'leukocytes',
    'platelets',
    'mcv',
    'mch',
    'rdw',
    'ferritin',
    'serumIron',
    'transferrinTIBC',
    'transferrinSaturation',
    'uibc',
    'vitaminD',
    'vitaminB12',
    'vitaminB6',
    'vitaminB1',
    'vitaminE',
    'vitaminA',
    'vitaminK',
    'magnesium',
    'zinc',
    'copper',
    'selenium',
    'folate',
    'pcrUs',
    'homocysteine',
    'fibrinogen',
    'tsh',
    't4Total',
    't3Total',
    't4Free',
    't3Free',
    'ck',
    'ldh',
    'restingLactate',
    'testosteroneTotal',
    'testosteroneFree',
    'shbg',
    'estradiol',
    'progesteroneLuteal',
    'lh',
    'fsh',
    'prolactin',
    'dheaS',
    'morningCortisol',
    'apoBRatio',
  ];

  @override
  void initState() {
    super.initState();
    _client = ref.read(clientsProvider).value?.activeClient;
    // Siempre iniciar en idle: solo botón, sin formulario
    _mode = _TabMode.idle;

    for (var key in _allKeys) {
      _controllers[key] = TextEditingController();
    }
    _loadLatestRecord();
  }

  @override
  void didUpdateWidget(covariant BiochemistryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newClient = ref.read(clientsProvider).value?.activeClient;
    if (newClient != null && newClient.id != _client?.id) {
      _client = newClient;
      _clearFields();
      _selectedRecordDate = null;
      _mode = _TabMode.idle;
      _loadLatestRecord();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- CORRECCIÓN 1: Mapeo Manual de Lectura ---
  void _loadLatestRecord() {
    final client = _client;
    if (client == null) {
      return;
    }
    final globalDate = ref.read(globalDateProvider);
    final record = client.latestBiochemistryAtOrBefore(globalDate);

    if (record != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(record.date);

      // Función auxiliar para asignar texto seguro
      void set(String key, double? val) {
        _controllers[key]?.text = val?.toString() ?? '';
      }

      // Panel 1: Glucosa
      set('glucose', record.glucose);
      set('hba1c', record.hba1c);
      set('fastingInsulin', record.fastingInsulin);

      // Panel 2: Lípidos
      set(
        'cholesterolTotal',
        record.cholesterolTotal,
      ); // Ajusta si se llama 'cholesterol'
      set('ldl', record.ldl); // Ajusta si se llama 'ldlCholesterol'
      set('hdl', record.hdl); // Ajusta si se llama 'hdlCholesterol'
      set('triglycerides', record.triglycerides);
      set('apoB', record.apoB);
      set('apoA1', record.apoA1);
      // Nota: Si apoBRatio no se guarda en DB y es calculado, calcular aquí:
      if (record.apoB != null && record.apoA1 != null && record.apoA1 != 0) {
        _controllers['apoBRatio']?.text = (record.apoB! / record.apoA1!)
            .toStringAsFixed(2);
      }

      // Panel 3: Hepático
      set('ast', record.ast);
      set('alt', record.alt);
      set('ggt', record.ggt);
      set('alkalinePhosphatase', record.alkalinePhosphatase);
      set('bilirubinTotal', record.bilirubinTotal);
      set('albumin', record.albumin);
      set('totalProteins', record.totalProteins);

      // Panel 4: Renal
      set('creatinine', record.creatinine);
      set('ureaBUN', record.ureaBUN); // Ajusta si se llama 'urea'
      set('bunCreatinineRatio', record.bunCreatinineRatio);
      set('egfr', record.egfr);
      set('sodium', record.sodium);
      set('potassium', record.potassium);
      set('chloride', record.chloride);
      set('bicarbonate', record.bicarbonate);
      set('uricAcid', record.uricAcid);

      // Panel 5: Hematología
      set('hemoglobin', record.hemoglobin);
      set('hematocrit', record.hematocrit);
      set('leukocytes', record.leukocytes);
      set('platelets', record.platelets);
      set('mcv', record.mcv);
      set('mch', record.mch);
      set('rdw', record.rdw);
      set('ferritin', record.ferritin);
      set('serumIron', record.serumIron);
      set('transferrinTIBC', record.transferrinTIBC);
      set('transferrinSaturation', record.transferrinSaturation);

      // Panel 6: Vitaminas
      set('vitaminD', record.vitaminD);
      set('vitaminB12', record.vitaminB12);
      set('folate', record.folate);
      set('magnesium', record.magnesium);
      set('zinc', record.zinc);

      // Panel 7: Inflamación
      set('pcrUs', record.pcrUs);
      set('homocysteine', record.homocysteine);
      set('fibrinogen', record.fibrinogen);

      // Panel 8: Tiroides
      set('tsh', record.tsh);
      set('t4Total', record.t4Total);
      set('t3Total', record.t3Total);
      set('t4Free', record.t4Free);
      set('t3Free', record.t3Free);

      // Panel 9: Hormonal
      set('testosteroneTotal', record.testosteroneTotal);
      set('testosteroneFree', record.testosteroneFree);
      set('shbg', record.shbg);
      set('estradiol', record.estradiol);
      set('progesteroneLuteal', record.progesteroneLuteal);
      set('lh', record.lh);
      set('fsh', record.fsh);
      set('prolactin', record.prolactin);
      set('dheaS', record.dheaS);
      set('morningCortisol', record.morningCortisol);

      // Panel 10: Entrenamiento
      set('ck', record.ck);
      set('ldh', record.ldh);
      set('restingLactate', record.restingLactate);
    } else {
      _clearFields();
    }
  }

  void _clearFields() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _controllers.forEach((_, controller) => controller.clear());
  }

  void _loadRecordInViewMode(BioChemistryRecord record) {
    setState(() {
      _selectedRecordDate = record.date;
      _mode = _TabMode.view;

      // Cargar fecha
      _dateController.text = DateFormat('yyyy-MM-dd').format(record.date);

      // Cargar todos los valores
      void set(String key, double? val) {
        _controllers[key]?.text = val?.toString() ?? '';
      }

      set('glucose', record.glucose);
      set('hba1c', record.hba1c);
      set('fastingInsulin', record.fastingInsulin);
      set('cholesterolTotal', record.cholesterolTotal);
      set('ldl', record.ldl);
      set('hdl', record.hdl);
      set('triglycerides', record.triglycerides);
      set('apoB', record.apoB);
      set('apoA1', record.apoA1);
      set('ast', record.ast);
      set('alt', record.alt);
      set('ggt', record.ggt);
      set('alkalinePhosphatase', record.alkalinePhosphatase);
      set('bilirubinTotal', record.bilirubinTotal);
      set('albumin', record.albumin);
      set('totalProteins', record.totalProteins);
      set('creatinine', record.creatinine);
      set('ureaBUN', record.ureaBUN);
      set('bunCreatinineRatio', record.bunCreatinineRatio);
      set('egfr', record.egfr);
      set('sodium', record.sodium);
      set('potassium', record.potassium);
      set('chloride', record.chloride);
      set('bicarbonate', record.bicarbonate);
      set('uricAcid', record.uricAcid);
      set('hemoglobin', record.hemoglobin);
      set('hematocrit', record.hematocrit);
      set('leukocytes', record.leukocytes);
      set('platelets', record.platelets);
      set('mcv', record.mcv);
      set('mch', record.mch);
      set('rdw', record.rdw);
      set('ferritin', record.ferritin);
      set('serumIron', record.serumIron);
      set('transferrinTIBC', record.transferrinTIBC);
      set('transferrinSaturation', record.transferrinSaturation);
      set('vitaminD', record.vitaminD);
      set('vitaminB12', record.vitaminB12);
      set('folate', record.folate);
      set('magnesium', record.magnesium);
      set('zinc', record.zinc);
      set('pcrUs', record.pcrUs);
      set('homocysteine', record.homocysteine);
      set('fibrinogen', record.fibrinogen);
      set('tsh', record.tsh);
      set('t4Total', record.t4Total);
      set('t3Total', record.t3Total);
      set('t4Free', record.t4Free);
      set('t3Free', record.t3Free);
      set('testosteroneTotal', record.testosteroneTotal);
      set('testosteroneFree', record.testosteroneFree);
      set('shbg', record.shbg);
      set('estradiol', record.estradiol);
      set('progesteroneLuteal', record.progesteroneLuteal);
      set('lh', record.lh);
      set('fsh', record.fsh);
      set('prolactin', record.prolactin);
      set('dheaS', record.dheaS);
      set('morningCortisol', record.morningCortisol);
      set('ck', record.ck);
      set('ldh', record.ldh);
      set('restingLactate', record.restingLactate);
    });
  }

  void _enableEditMode() {
    setState(() {
      _mode = _TabMode.editing;
    });
  }

  void _cancelEdit() {
    if (_selectedRecordDate != null) {
      // Volver a VIEW mode
      final record = _client?.biochemistry.firstWhere(
        (r) => DateUtils.isSameDay(r.date, _selectedRecordDate!),
      );
      if (record != null) {
        _loadRecordInViewMode(record);
      }
    } else {
      // Volver a modo idle (sin formulario)
      _resetToIdle();
    }
  }

  void _resetToIdle() {
    setState(() {
      _selectedRecordDate = null;
      _mode = _TabMode.idle;
      _clearFields();
    });
  }

  void _resetToCreating() {
    setState(() {
      _selectedRecordDate = null;
      _mode = _TabMode.creating;
      _clearFields();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialCandidate =
        DateTime.tryParse(_dateController.text) ?? DateTime.now();

    final DateTime? picked = await showCustomDatePicker(
      context,
      initialDate: initialCandidate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- CORRECCIÓN 2: Guardado Manual ---
  Future<void> _saveRecord({bool showSnackbar = true}) async {
    if (!_formKey.currentState!.validate()) {
      if (showSnackbar) {
        showErrorSnackbar(context, SaveMessages.errorValidation);
      }
      return;
    }

    final date = DateTime.tryParse(_dateController.text);
    if (date == null) {
      if (showSnackbar) {
        showErrorSnackbar(context, SaveMessages.errorInvalidDate);
      }
      return;
    }

    // Helper para obtener double de los controladores
    double? getVal(String key) {
      final text = _controllers[key]?.text.trim();
      if (text == null || text.isEmpty) return null;
      return double.tryParse(text);
    }

    // Construimos el objeto pasando los parámetros nombrados
    // NOTA: Si alguna variable se llama diferente en tu entity, corrígela aquí.
    final newRecord = BioChemistryRecord(
      date: date,
      glucose: getVal('glucose'),
      hba1c: getVal('hba1c'),
      fastingInsulin: getVal('fastingInsulin'),

      cholesterolTotal: getVal('cholesterolTotal'),
      ldl: getVal('ldl'),
      hdl: getVal('hdl'),
      triglycerides: getVal('triglycerides'),
      apoA1: getVal('apoA1'),
      apoB: getVal('apoB'),

      ast: getVal('ast'),
      alt: getVal('alt'),
      ggt: getVal('ggt'),
      alkalinePhosphatase: getVal('alkalinePhosphatase'),
      bilirubinTotal: getVal('bilirubinTotal'),
      albumin: getVal('albumin'),
      totalProteins: getVal('totalProteins'),

      creatinine: getVal('creatinine'),
      ureaBUN: getVal('ureaBUN'),
      bunCreatinineRatio: getVal('bunCreatinineRatio'),
      egfr: getVal('egfr'),
      sodium: getVal('sodium'),
      potassium: getVal('potassium'),
      chloride: getVal('chloride'),
      bicarbonate: getVal('bicarbonate'),
      uricAcid: getVal('uricAcid'),

      hemoglobin: getVal('hemoglobin'),
      hematocrit: getVal('hematocrit'),
      leukocytes: getVal('leukocytes'),
      platelets: getVal('platelets'),
      mcv: getVal('mcv'),
      mch: getVal('mch'),
      rdw: getVal('rdw'),

      ferritin: getVal('ferritin'),
      serumIron: getVal('serumIron'),
      transferrinTIBC: getVal('transferrinTIBC'),
      transferrinSaturation: getVal('transferrinSaturation'),

      vitaminD: getVal('vitaminD'),
      vitaminB12: getVal('vitaminB12'),
      folate: getVal('folate'),
      magnesium: getVal('magnesium'),
      zinc: getVal('zinc'),

      pcrUs: getVal('pcrUs'),
      homocysteine: getVal('homocysteine'),
      fibrinogen: getVal('fibrinogen'),

      tsh: getVal('tsh'),
      t4Total: getVal('t4Total'),
      t3Total: getVal('t3Total'),
      t4Free: getVal('t4Free'),
      t3Free: getVal('t3Free'),

      testosteroneTotal: getVal('testosteroneTotal'),
      testosteroneFree: getVal('testosteroneFree'),
      shbg: getVal('shbg'),
      estradiol: getVal('estradiol'),
      progesteroneLuteal: getVal('progesteroneLuteal'),
      lh: getVal('lh'),
      fsh: getVal('fsh'),
      prolactin: getVal('prolactin'),
      dheaS: getVal('dheaS'),
      morningCortisol: getVal('morningCortisol'),

      ck: getVal('ck'),
      ldh: getVal('ldh'),
      restingLactate: getVal('restingLactate'),
    );

    final client = _client;
    if (client == null) {
      return;
    }

    // Detectar si es edición o nuevo registro
    // ignore: unused_local_variable
    final isEditing = SaveActionDetector.isEditingExistingDate(
      client.biochemistry,
      date,
      (record) => record.date,
    );

    // GUARD: Verificar que el widget siga montado antes de usar ref
    if (!mounted) return;

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final updatedRecords = upsertRecordByDate<BioChemistryRecord>(
        existingRecords: current.biochemistry,
        newRecord: newRecord,
        dateExtractor: (record) => record.date,
      );
      return current.copyWith(biochemistry: updatedRecords);
    });

    // GUARD: Verificar de nuevo después del await
    if (!mounted) return;

    // Push granular a Firestore (FIRE-AND-FORGET - no espera)
    final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
    // No await - permite que se ejecute en segundo plano sin bloquear UI
    recordsRepo.pushBiochemistryRecord(client.id, newRecord);

    // GUARD: Verificar mounted antes de setState
    if (!mounted) return;

    // Volver a modo idle después de guardar exitosamente
    setState(() {
      _selectedRecordDate = null;
      _mode = _TabMode.idle;
      _clearFields();
    });

    if (showSnackbar) {
      if (!mounted) {
        return;
      }
      final feedback = SaveActionDetector.getFeedback(
        client.biochemistry,
        date,
        (record) => record.date,
      );
      showErrorSnackbar(context, feedback, isError: false);
    }
  }

  Future<void> saveIfDirty() async {
    await _saveRecord(showSnackbar: false);
  }

  void resetDrafts() {
    final activeClient = ref.read(clientsProvider).value?.activeClient;
    if (activeClient != null) {
      _client = activeClient;
    }
    _clearFields();
    _loadLatestRecord();
    if (mounted) {
      setState(() {});
    }
  }

  // --- UI WIDGETS (Plantilla Clínica-Minimalista) ---

  /// 1. Context Bar: Barra superior compacta mostrando el modo actual
  Widget _buildContextBar(BioChemistryRecord? currentRecord) {
    switch (_mode) {
      case _TabMode.idle:
        return ClinicalContextBar.view(selectedDate: currentRecord?.date);
      case _TabMode.view:
        return ClinicalContextBar.view(selectedDate: currentRecord?.date);
      case _TabMode.editing:
        return ClinicalContextBar.editing(selectedDate: currentRecord?.date);
      case _TabMode.creating:
        return ClinicalContextBar.creating();
    }
  }

  /// 2. Estado Actual Card: Muestra el registro actual/seleccionado (modo dominante)
  Widget _buildCurrentStateCard(BioChemistryRecord? currentRecord) {
    final bool hasRecord = currentRecord != null;
    final String title = _mode == _TabMode.view || _mode == _TabMode.editing
        ? 'Estado Actual'
        : 'Último Registro';

    return Card(
      elevation: _mode == _TabMode.creating ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _mode == _TabMode.creating
              ? Colors.grey.shade300
              : kPrimaryColor.withValues(alpha: 0.2),
          width: _mode == _TabMode.creating ? 0.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: kPrimaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasRecord) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('d MMM yyyy', 'es').format(currentRecord.date),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (!hasRecord)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        SaveMessages.emptyStateDefault,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildKPIGrid(currentRecord),
            if (hasRecord && _mode == _TabMode.view) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _enableEditMode,
                  icon: const Icon(Icons.edit),
                  label: const Text(SaveMessages.buttonEditRecord),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 44),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Grid de KPIs principales para el card de Estado Actual
  Widget _buildKPIGrid(BioChemistryRecord record) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKPI('Glucosa', record.glucose, 'mg/dL', Icons.bloodtype),
            _buildKPI('HbA1c', record.hba1c, '%', Icons.timeline),
            _buildKPI(
              'Colesterol',
              record.cholesterolTotal,
              'mg/dL',
              Icons.favorite,
            ),
            _buildKPI('LDL', record.ldl, 'mg/dL', Icons.warning_amber),
            _buildKPI('HDL', record.hdl, 'mg/dL', Icons.shield),
            _buildKPI(
              'Creatinina',
              record.creatinine,
              'mg/dL',
              Icons.filter_alt,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPI(String label, double? value, String unit, IconData icon) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value != null ? '${value.toStringAsFixed(1)} $unit' : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Nuevo Registro Card: Solo visible en modo CREATING
  Widget? _buildNewRecordCard() {
    if (_mode != _TabMode.creating) return null;

    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Al guardar, se agregará un nuevo registro. Los registros existentes no se modificarán.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI WIDGETS (Identicos a los tuyos) ---

  Widget _buildPanel1Glucose(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Glucosa',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Glucosa Ayunas (mg/dL) *',
                controller: _controllers['glucose']!,
                biomarkerKey: 'glucose',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'HbA1c (%)',
                controller: _controllers['hba1c']!,
                biomarkerKey: 'hba1c',
                hintText: 'Hemoglobina Glicosilada',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Insulina Ayunas (µU/mL)',
                controller: _controllers['fastingInsulin']!,
                biomarkerKey: 'fastingInsulin',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel2Lipids(double itemWidth, String? gender) {
    // Calculamos ratio visualmente porque puede no estar en DB
    String ratioText = 'N/A';
    double? apoB = double.tryParse(_controllers['apoB']?.text ?? '');
    double? apoA1 = double.tryParse(_controllers['apoA1']?.text ?? '');
    if (apoB != null && apoA1 != null && apoA1 > 0) {
      ratioText = (apoB / apoA1).toStringAsFixed(2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil Lipídico',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Colesterol Total (mg/dL)',
                controller: _controllers['cholesterolTotal']!,
                biomarkerKey: 'cholesterolTotal',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'LDL-c (mg/dL)',
                controller: _controllers['ldl']!,
                biomarkerKey: 'ldl',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'HDL-c (mg/dL)',
                controller: _controllers['hdl']!,
                biomarkerKey: 'hdl',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Triglicéridos (mg/dL)',
                controller: _controllers['triglycerides']!,
                biomarkerKey: 'triglycerides',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'ApoB (mg/dL)',
                controller: _controllers['apoB']!,
                biomarkerKey: 'apoB',
                hintText: 'Apolipoproteína B',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'ApoA-1 (mg/dL)',
                controller: _controllers['apoA1']!,
                biomarkerKey: 'apoA1',
                hintText: 'Apolipoproteína A-1',
                gender: gender,
              ),
            ),
            // Este campo es solo visual
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Ratio ApoB/ApoA-1',
                controller: TextEditingController(text: ratioText),
                biomarkerKey: 'apoBRatio',
                hintText: 'Calculado',
                keyboardType: TextInputType.text,
                readOnly: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Colesterol No-HDL (mg/dL)',
                controller: _controllers['cholesterolNoHDL']!,
                biomarkerKey: 'cholesterolNoHDL',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel3Hepatic(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Función Hepática',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'AST (U/L)',
                controller: _controllers['ast']!,
                biomarkerKey: 'ast',
                hintText: 'TGO',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'ALT (U/L)',
                controller: _controllers['alt']!,
                biomarkerKey: 'alt',
                hintText: 'TGP',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'GGT (U/L)',
                controller: _controllers['ggt']!,
                biomarkerKey: 'ggt',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Fosfatasa Alcalina (U/L)',
                controller: _controllers['alkalinePhosphatase']!,
                biomarkerKey: 'alkalinePhosphatase',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Bilirrubina Total (mg/dL)',
                controller: _controllers['bilirubinTotal']!,
                biomarkerKey: 'bilirubinTotal',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Albumina (g/dL)',
                controller: _controllers['albumin']!,
                biomarkerKey: 'albumin',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Proteínas Totales (g/dL)',
                controller: _controllers['totalProteins']!,
                biomarkerKey: 'totalProteins',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel4Renal(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renal / Electrolitos',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Creatinina (mg/dL)',
                controller: _controllers['creatinine']!,
                biomarkerKey: 'creatinine',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Urea (BUN) (mg/dL)',
                controller: _controllers['ureaBUN']!,
                biomarkerKey: 'ureaBUN',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Ratio BUN/Creat.',
                controller: _controllers['bunCreatinineRatio']!,
                biomarkerKey: 'bunCreatinineRatio',
                hintText: 'Ratio',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'eGFR (mL/min/1.73m²)',
                controller: _controllers['egfr']!,
                biomarkerKey: 'egfr',
                hintText: 'Filtración Glomerular',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Sodio (mEq/L)',
                controller: _controllers['sodium']!,
                biomarkerKey: 'sodium',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Potasio (mEq/L)',
                controller: _controllers['potassium']!,
                biomarkerKey: 'potassium',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Cloro (mEq/L)',
                controller: _controllers['chloride']!,
                biomarkerKey: 'chloride',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Bicarbonato (mEq/L)',
                controller: _controllers['bicarbonate']!,
                biomarkerKey: 'bicarbonate',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Osmolaridad Sérica (mOsm/Kg)',
                controller: _controllers['serumOsmolality']!,
                biomarkerKey: 'serumOsmolality',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Densidad Urinaria',
                controller: _controllers['urineDensity']!,
                biomarkerKey: 'urineDensity',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Ácido Úrico (mg/dL)',
                controller: _controllers['uricAcid']!,
                biomarkerKey: 'uricAcid',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel5Hematology(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hematología / Hierro',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kAccentColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Hemoglobina (g/dL)',
                controller: _controllers['hemoglobin']!,
                biomarkerKey: 'hemoglobin',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Hematocrito (%)',
                controller: _controllers['hematocrit']!,
                biomarkerKey: 'hematocrit',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Leucocitos (x10^3/µL)',
                controller: _controllers['leukocytes']!,
                biomarkerKey: 'leukocytes',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Plaquetas (x10^3/µL)',
                controller: _controllers['platelets']!,
                biomarkerKey: 'platelets',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'VCM (fL)',
                controller: _controllers['mcv']!,
                biomarkerKey: 'mcv',
                hintText: 'Vol. Corpuscular Medio',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'HCM (pg)',
                controller: _controllers['mch']!,
                biomarkerKey: 'mch',
                hintText: 'Hb. Corpuscular Media',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'RDW (%)',
                controller: _controllers['rdw']!,
                biomarkerKey: 'rdw',
                hintText: 'Ancho Dist. Eritrocitaria',
                gender: gender,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Metabolismo del Hierro',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: kAccentColor.withAlpha(200)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Ferritina (ng/mL)',
                controller: _controllers['ferritin']!,
                biomarkerKey: 'ferritin',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Hierro Sérico (mcg/dL)',
                controller: _controllers['serumIron']!,
                biomarkerKey: 'serumIron',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'TIBC (mcg/dL)',
                controller: _controllers['transferrinTIBC']!,
                biomarkerKey: 'transferrinTIBC',
                hintText: 'Cap. Fijación del Hierro',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: '% Saturación Transferrina',
                controller: _controllers['transferrinSaturation']!,
                biomarkerKey: 'transferrinSaturation',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'UIBC (mcg/dL)',
                controller: _controllers['uibc']!,
                biomarkerKey: 'uibc',
                hintText: 'Cap. Insaturada Fij. Hierro',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel6Vitamins(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vitaminas y Minerales',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kAccentColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Vitamina D (ng/mL)',
                controller: _controllers['vitaminD']!,
                biomarkerKey: 'vitaminD',
                hintText: '25-OH Vit.D',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Vitamina B12 (pg/mL)',
                controller: _controllers['vitaminB12']!,
                biomarkerKey: 'vitaminB12',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Folato (ng/mL)',
                controller: _controllers['folate']!,
                biomarkerKey: 'folate',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Magnesio (mg/dL)',
                controller: _controllers['magnesium']!,
                biomarkerKey: 'magnesium',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Zinc (mcg/dL)',
                controller: _controllers['zinc']!,
                biomarkerKey: 'zinc',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Cobre (mcg/dL)',
                controller: _controllers['copper']!,
                biomarkerKey: 'copper',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Selenio (mcg/L)',
                controller: _controllers['selenium']!,
                biomarkerKey: 'selenium',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel7Inflammation(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inflamación / Cardiovascular',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'PCR-us (mg/L)',
                controller: _controllers['pcrUs']!,
                biomarkerKey: 'pcrUs',
                hintText: 'Proteína C Reactiva ultrasensible',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Homocisteína (µmol/L)',
                controller: _controllers['homocysteine']!,
                biomarkerKey: 'homocysteine',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Fibrinógeno (mg/dL)',
                controller: _controllers['fibrinogen']!,
                biomarkerKey: 'fibrinogen',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel8Thyroid(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil Tiroideo',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kAccentColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'TSH (µUI/mL)',
                controller: _controllers['tsh']!,
                biomarkerKey: 'tsh',
                hintText: 'Hormona Estimulante de Tiroides',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'T4 Total (µg/dL)',
                controller: _controllers['t4Total']!,
                biomarkerKey: 't4Total',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'T3 Total (ng/dL)',
                controller: _controllers['t3Total']!,
                biomarkerKey: 't3Total',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'T4 Libre (ng/dL)',
                controller: _controllers['t4Free']!,
                biomarkerKey: 't4Free',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'T3 Libre (pg/mL)',
                controller: _controllers['t3Free']!,
                biomarkerKey: 't3Free',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel9Hormonal(double itemWidth, String? gender) {
    bool isMale = parseGender(gender) == Gender.male;
    bool isFemale = parseGender(gender) == Gender.female;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil Hormonal',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kAccentColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            if (isMale) ...[
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'Testosterona Total (ng/dL)',
                  controller: _controllers['testosteroneTotal']!,
                  biomarkerKey: 'testosteroneTotal',
                  hintText: 'Valor...',
                  gender: gender,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'Testosterona Libre (pg/mL)',
                  controller: _controllers['testosteroneFree']!,
                  biomarkerKey: 'testosteroneFree',
                  hintText: 'Valor...',
                  gender: gender,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'SHBG (nmol/L)',
                  controller: _controllers['shbg']!,
                  biomarkerKey: 'shbg',
                  hintText: 'Globulina Fijadora de Hormonas Sexuales',
                  gender: gender,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'Estradiol (E2) (pg/mL)',
                  controller: _controllers['estradiol']!,
                  biomarkerKey: 'estradiol',
                  hintText: 'Valor...',
                  gender: gender,
                ),
              ),
            ],
            if (isFemale) ...[
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'Estradiol (E2) (pg/mL)',
                  controller: _controllers['estradiol']!,
                  biomarkerKey: 'estradiol',
                  hintText: 'Valor...',
                  gender: gender,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'Progesterona (Fase Lútea) (ng/mL)',
                  controller: _controllers['progesteroneLuteal']!,
                  biomarkerKey: 'progesteroneLuteal',
                  hintText: 'Valor...',
                  gender: gender,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalyzedTextField(
                  label: 'Testosterona Total (ng/dL)',
                  controller: _controllers['testosteroneTotal']!,
                  biomarkerKey: 'testosteroneTotal',
                  hintText: 'Valor...',
                  gender: gender,
                ),
              ),
            ],
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'LH (mUI/mL)',
                controller: _controllers['lh']!,
                biomarkerKey: 'lh',
                hintText: 'Hormona Luteinizante',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'FSH (mUI/mL)',
                controller: _controllers['fsh']!,
                biomarkerKey: 'fsh',
                hintText: 'Hormona Folículo Estimulante',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Prolactina (ng/mL)',
                controller: _controllers['prolactin']!,
                biomarkerKey: 'prolactin',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'DHEA-S (µg/dL)',
                controller: _controllers['dheaS']!,
                biomarkerKey: 'dheaS',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Cortisol AM (µg/dL)',
                controller: _controllers['morningCortisol']!,
                biomarkerKey: 'morningCortisol',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel10Training(double itemWidth, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marcadores de Entrenamiento',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'CK (Creatina Kinasa) (U/L)',
                controller: _controllers['ck']!,
                biomarkerKey: 'ck',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'LDH (Lactato Deshidrogenasa) (U/L)',
                controller: _controllers['ldh']!,
                biomarkerKey: 'ldh',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AnalyzedTextField(
                label: 'Lactato en Reposo (mmol/L)',
                controller: _controllers['restingLactate']!,
                biomarkerKey: 'restingLactate',
                hintText: 'Valor...',
                gender: gender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _buildActionButtons() {
    // En modo idle no mostramos acciones (solo botón principal arriba)
    if (_mode == _TabMode.idle) return null;

    Widget primaryButton;
    late final Widget secondaryButton;

    switch (_mode) {
      case _TabMode.view:
        primaryButton = FloatingActionButton.extended(
          heroTag: 'bio_edit',
          onPressed: _enableEditMode,
          label: const Text(SaveMessages.buttonEditRecord),
          icon: const Icon(Icons.edit),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        );
        secondaryButton = FloatingActionButton.extended(
          heroTag: 'bio_cancel_view',
          onPressed: () {
            setState(() {
              _selectedRecordDate = null;
              _mode = _TabMode.idle;
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
        );
        break;
      case _TabMode.editing:
        primaryButton = FloatingActionButton.extended(
          heroTag: 'bio_save_edit',
          onPressed: _saveRecord,
          label: const Text(SaveMessages.buttonSaveChanges),
          icon: const Icon(Icons.save),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        );
        secondaryButton = FloatingActionButton.extended(
          heroTag: 'bio_cancel_edit',
          onPressed: _cancelEdit,
          label: const Text('Cancelar'),
          icon: const Icon(Icons.close),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        );
        break;
      case _TabMode.creating:
        primaryButton = FloatingActionButton.extended(
          heroTag: 'bio_save_new',
          onPressed: _saveRecord,
          label: const Text(SaveMessages.buttonCreateNew),
          icon: const Icon(Icons.save),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        );
        secondaryButton = FloatingActionButton.extended(
          heroTag: 'bio_cancel_new',
          onPressed: _cancelEdit,
          label: const Text('Cancelar'),
          icon: const Icon(Icons.close),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        );
        break;
      case _TabMode.idle:
        return null;
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
    if (_client != client && client != null) {
      _client = client;
      _clearFields();
      _loadLatestRecord();
    }

    final gender = client?.profile.gender?.label;

    // Obtener el registro actual (el que se está viendo/editando o el más reciente)
    BioChemistryRecord? currentRecord;
    if (_selectedRecordDate != null) {
      currentRecord = client?.biochemistry.firstWhere(
        (r) => DateUtils.isSameDay(r.date, _selectedRecordDate!),
        orElse: () => client.biochemistry.first,
      );
    } else {
      final globalDate = ref.read(globalDateProvider);
      currentRecord = client?.latestBiochemistryAtOrBefore(globalDate);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth > 1200
            ? 1200.0
            : constraints.maxWidth;
        final double itemWidth =
            (maxWidth - 72) / 4; // 24*2 padding + 16*2 spacing

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _buildActionButtons(),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // En modo idle, mostrar el grid con tile de nuevo registro
                      if (_mode == _TabMode.idle) ...[
                        _buildHistoryGrid(client?.biochemistry ?? []),
                      ],

                      // CONTEXT BAR y ESTADO ACTUAL (solo en modos no-idle)
                      if (_mode != _TabMode.idle) ...[
                        _buildContextBar(currentRecord),
                        const SizedBox(height: 16),
                        _buildCurrentStateCard(currentRecord),
                        const SizedBox(height: 16),
                      ],

                      // 3. NUEVO REGISTRO CARD (solo en modo CREATING)
                      if (_buildNewRecordCard() != null) ...[
                        _buildNewRecordCard()!,
                        const SizedBox(height: 16),
                      ],

                      // 4. FORMULARIO (solo visible en EDIT o CREATING)
                      if (_mode == _TabMode.editing ||
                          _mode == _TabMode.creating)
                        _buildFormSection(itemWidth, gender),

                      // 5. HISTORIAL (colapsable - solo visible cuando NO está en idle)
                      if (_mode != _TabMode.idle &&
                          (client?.biochemistry.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 24),
                        RecordHistoryPanel<BioChemistryRecord>(
                          records: client!.biochemistry,
                          selectedDate: _selectedRecordDate,
                          onSelectDate: (date) {
                            final record = client.biochemistry.firstWhere(
                              (r) => DateUtils.isSameDay(r.date, date),
                              orElse: () => client.biochemistry.first,
                            );
                            _loadRecordInViewMode(record);
                          },
                          primaryLabel: (record) {
                            final glucose =
                                record.glucose?.toStringAsFixed(0) ?? '—';
                            final cholesterol =
                                record.cholesterolTotal?.toStringAsFixed(0) ??
                                '—';
                            return 'Glucosa: $glucose mg/dL • Colesterol: $cholesterol mg/dL';
                          },
                          dateOf: (record) => record.date,
                          title: 'Historial de Análisis',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sección de formulario completo (solo visible en EDITING o CREATING)
  Widget _buildFormSection(double itemWidth, String? gender) {
    return AbsorbPointer(
      absorbing: _mode == _TabMode.view,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kCardColor.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de fecha + botones de acción
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _dateController,
                      label: 'Fecha del Análisis',
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ],
              ),
              const Divider(height: 48),

              // Todos los paneles de biomarcadores
              _buildPanel1Glucose(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel2Lipids(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel3Hepatic(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel4Renal(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel5Hematology(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel6Vitamins(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel7Inflammation(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel8Thyroid(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel9Hormonal(itemWidth, gender),
              const Divider(height: 48),
              _buildPanel10Training(itemWidth, gender),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // HISTORIAL EN GRID (para modo idle)
  // =====================================================================
  Widget _buildHistoryGrid(List<BioChemistryRecord> records) {
    final sortedRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    List<Widget> tiles = [
      InkWell(
        onTap: _resetToCreating,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPrimaryColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor.withAlpha(80), width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 36, color: kPrimaryColor),
              SizedBox(height: 8),
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
      ),
    ];

    tiles.addAll(
      sortedRecords.map((record) {
        final isSelected =
            _selectedRecordDate != null &&
            DateUtils.isSameDay(_selectedRecordDate, record.date);
        final day = DateFormat('d').format(record.date);
        final monthYear = DateFormat(
          'MMM yyyy',
          'es',
        ).format(record.date).toUpperCase();

        return InkWell(
          onTap: () => _loadRecordInViewMode(record),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimaryColor.withAlpha(51)
                  : kCardColor.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kPrimaryColor : Colors.white.withAlpha(20),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isSelected ? kPrimaryColor : kTextColorSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? kPrimaryColor : kTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  monthYear,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: Colors.white10, height: 16),
                _buildBiochemMetric(
                  'Glucosa',
                  record.glucose != null
                      ? '${record.glucose!.toStringAsFixed(1)} mg/dL'
                      : '—',
                ),
                const SizedBox(height: 4),
                _buildBiochemMetric(
                  'Colesterol',
                  record.cholesterolTotal != null
                      ? '${record.cholesterolTotal!.toStringAsFixed(1)} mg/dL'
                      : '—',
                ),
              ],
            ),
          ),
        );
      }),
    );

    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }

  Widget _buildBiochemMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: kTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
